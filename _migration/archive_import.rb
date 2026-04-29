#!/usr/bin/env ruby
# frozen_string_literal: true
#
# Phase 4b.2 — bulk import of archive items from a curated seed file.
#
#   bundle exec ruby _migration/archive_import.rb              # dry-run
#   bundle exec ruby _migration/archive_import.rb --commit     # actually write
#   bundle exec ruby _migration/archive_import.rb --commit --no-fetch-pdf
#                                                              # skip PDF fetches
#
# Reads `_migration/archive_seed.yml` (one block per item, bilingual
# content authored by hand). For each item:
#   1. Skip if `_archive/<slug>.md` already exists (idempotent).
#   2. Optionally fetch `original_url` and save the response as
#      `/assets/pdf/archive/<slug>.pdf` IF the response is a PDF.
#   3. Write `_archive/<slug>.md` (EN) and `_archive/<slug>.fr.md` (FR)
#      with the schema gate enforced by `tests/structural/archive_collection_spec.rb`.
#   4. Append a structured entry to `_migration/archive_import.report.md`.
#
# No LLM call. Bilingual content is authored in the seed YAML.

require "yaml"
require "pathname"
require "net/http"
require "uri"
require "fileutils"
require "optparse"
require "date"
require "json"

ROOT = Pathname.new(File.expand_path("..", __dir__))
SEED_PATH = ROOT / "_migration" / "archive_seed.yml"
ARCHIVE_DIR = ROOT / "_archive"
PDF_DIR = ROOT / "assets" / "pdf" / "archive"
REPORT_PATH = ROOT / "_migration" / "archive_import.report.md"

ALLOWED_TYPES = %w[talk article oped interview report video podcast quoted].freeze
ALLOWED_ROLES = %w[author co-author contributor speaker interviewee quoted facilitator moderator].freeze

# --- CLI ---------------------------------------------------------------

options = { commit: false, fetch_pdf: true, only: nil }
OptionParser.new do |opts|
  opts.banner = "Usage: ruby archive_import.rb [options]"
  opts.on("--commit", "Actually write files (default: dry-run)") { options[:commit] = true }
  opts.on("--no-fetch-pdf", "Skip the PDF fetch step") { options[:fetch_pdf] = false }
  opts.on("--only SLUG", "Only process the item with this slug") { |s| options[:only] = s }
end.parse!

# --- Helpers -----------------------------------------------------------

def report_lines
  @report_lines ||= []
end

def log(status, slug, message)
  report_lines << { status: status, slug: slug, message: message }
end

def slug_safe?(slug)
  slug.is_a?(String) && slug.match?(/\A[a-z0-9][a-z0-9-]*\z/)
end

def url_safe?(url)
  url.is_a?(String) && url.match?(%r{\Ahttps?://[^"\s<>]+\z})
end

def wayback_safe?(url)
  url.nil? || url.empty? || url.match?(%r{\Ahttps?://web\.archive\.org/[^"\s<>]*\z})
end

def fetch_pdf(url, dest, max_bytes: 30 * 1024 * 1024, timeout: 10)
  uri = URI.parse(url)
  Net::HTTP.start(uri.host, uri.port,
                  use_ssl: uri.scheme == "https",
                  open_timeout: timeout, read_timeout: timeout) do |http|
    response = http.request(Net::HTTP::Get.new(uri))
    return [:redirect, response["Location"]] if response.is_a?(Net::HTTPRedirection)
    return [:fail, "HTTP #{response.code}"] unless response.is_a?(Net::HTTPSuccess)
    ctype = response["Content-Type"].to_s
    return [:not_pdf, ctype] unless ctype.start_with?("application/pdf")
    body = response.body
    return [:too_large, body.bytesize] if body.bytesize > max_bytes
    FileUtils.mkdir_p(dest.dirname)
    dest.write(body, mode: "wb")
    [:ok, body.bytesize]
  end
rescue StandardError => e
  [:fail, e.message]
end

def front_matter(item, lang)
  fm = {
    "title"        => item.dig(lang, "title"),
    "date"         => item["date"].to_s,
    "type"         => item["type"],
    "role"         => item["role"],
    "source"       => item["source"],
    "original_url" => item["original_url"],
    "lang"         => lang,
    "ref"          => item["slug"],
    "slug"         => item["slug"],
    "tags"         => item["tags"] || [],
    "projects"     => item["projects"] || [],
    "excerpt"      => item.dig(lang, "excerpt"),
    "detail"       => item.fetch("detail", false),
  }
  fm["wayback_url"] = item["wayback_url"] if item["wayback_url"]
  fm["pdf"]         = item["__pdf_path"]   if item["__pdf_path"]
  fm["cover"]       = item["cover"]        if item["cover"]
  if lang == "fr"
    year = Date.parse(item["date"].to_s).year
    fm["permalink"] = "/fr/archive/#{year}/#{item["slug"]}/"
  end
  fm
end

def write_pair(item)
  %w[en fr].each do |lang|
    suffix = lang == "fr" ? ".fr.md" : ".md"
    path = ARCHIVE_DIR / "#{item["slug"]}#{suffix}"
    fm = front_matter(item, lang)
    body = item["body_#{lang}"].to_s.strip
    File.open(path, "w") do |f|
      f.puts "---"
      fm.each { |k, v| f.puts "#{k}: #{YAML.dump(v).sub(/\A---\s*/, '').chomp}" }
      f.puts "---"
      f.puts
      f.puts body unless body.empty?
    end
  end
end

# --- Validation --------------------------------------------------------

def validate(item)
  errors = []
  errors << "missing or invalid `slug`" unless slug_safe?(item["slug"])
  errors << "missing `date`" unless item["date"]
  errors << "type=#{item["type"].inspect} not in #{ALLOWED_TYPES}" unless ALLOWED_TYPES.include?(item["type"].to_s)
  errors << "role=#{item["role"].inspect} not in #{ALLOWED_ROLES}" unless ALLOWED_ROLES.include?(item["role"].to_s)
  errors << "missing `source`" if item["source"].to_s.strip.empty?
  errors << "original_url=#{item["original_url"].inspect} unsafe" unless url_safe?(item["original_url"])
  errors << "wayback_url=#{item["wayback_url"].inspect} unsafe" unless wayback_safe?(item["wayback_url"])
  %w[en fr].each do |lang|
    block = item[lang]
    if !block.is_a?(Hash) || block["title"].to_s.strip.empty? || block["excerpt"].to_s.strip.empty?
      errors << "missing #{lang}.title or #{lang}.excerpt"
    end
  end
  errors << "tags must be a non-empty array" unless item["tags"].is_a?(Array) && !item["tags"].empty?
  errors << "projects must be an array (may be empty)" unless item["projects"].is_a?(Array) || item["projects"].nil?
  errors
end

# --- Main --------------------------------------------------------------

raise "Seed file missing: #{SEED_PATH}" unless SEED_PATH.exist?
seed = YAML.safe_load_file(SEED_PATH, permitted_classes: [Date, Time])
items = (seed["items"] || []).reject { |i| options[:only] && i["slug"] != options[:only] }

puts "Mode: #{options[:commit] ? "COMMIT" : "DRY-RUN"} (#{items.size} item(s))"

items.each do |item|
  errors = validate(item)
  unless errors.empty?
    log(:invalid, item["slug"] || "<unknown>", errors.join("; "))
    next
  end

  en_path = ARCHIVE_DIR / "#{item["slug"]}.md"
  if en_path.exist?
    log(:skip_existing, item["slug"], "_archive/#{item["slug"]}.md already present")
    next
  end

  if options[:fetch_pdf]
    pdf_dest = PDF_DIR / "#{item["slug"]}.pdf"
    if pdf_dest.exist?
      item["__pdf_path"] = "/assets/pdf/archive/#{item["slug"]}.pdf"
      log(:pdf_already, item["slug"], "PDF already at #{pdf_dest.relative_path_from(ROOT)}")
    elsif options[:commit]
      status, info = fetch_pdf(item["original_url"], pdf_dest)
      case status
      when :ok
        item["__pdf_path"] = "/assets/pdf/archive/#{item["slug"]}.pdf"
        log(:pdf_fetched, item["slug"], "saved #{info} bytes")
      when :not_pdf
        log(:warn_link_only, item["slug"], "Content-Type=#{info.inspect} (no PDF saved)")
      when :redirect
        log(:warn_redirect, item["slug"], "redirected to #{info.inspect}; manual follow-up")
      when :too_large
        log(:warn_too_large, item["slug"], "PDF #{info} bytes exceeds limit (manual download)")
      when :fail
        log(:fail_fetch, item["slug"], info)
      end
    else
      log(:dry_pdf_skipped, item["slug"], "would attempt fetch on commit")
    end
  end

  if options[:commit]
    write_pair(item)
    log(:written, item["slug"], "EN+FR pair created")
  else
    log(:dry_would_write, item["slug"], "EN+FR pair would be created")
  end
end

# --- Report ------------------------------------------------------------

groups = report_lines.group_by { |r| r[:status] }
order = %i[invalid fail_fetch warn_redirect warn_too_large warn_link_only
           pdf_fetched pdf_already written dry_would_write dry_pdf_skipped skip_existing]

REPORT_PATH.write(<<~MD)
  # Archive import report

  Generated #{Time.now.strftime("%Y-%m-%d %H:%M:%S %Z")} — mode: #{options[:commit] ? "COMMIT" : "DRY-RUN"}

  ## Summary

  | Status | Count |
  |---|---|
  #{order.map { |s| "| `#{s}` | #{(groups[s] || []).size} |" }.join("\n")}

  ## Per-item log

  #{order.flat_map { |status|
    next [] unless groups[status]
    ["### #{status} (#{groups[status].size})", "",
     *groups[status].map { |r| "- **#{r[:slug]}** — #{r[:message]}" },
     ""]
  }.join("\n")}
MD

puts "Report written to: #{REPORT_PATH.relative_path_from(ROOT)}"
groups.each { |s, lines| puts "  #{s}: #{lines.size}" }
