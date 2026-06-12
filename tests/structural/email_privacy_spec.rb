require_relative "spec_helper"

# Email + phone must NEVER appear in any web-served file.
# Backs the user-level invariant in `feedback_email_privacy.md` (memory):
#   no `mailto:` / `tel:` / plaintext email or phone in HTML, JSON,
#   sitemap, RSS, downloadable files, or anywhere a scraper or visitor
#   can pull them.
#
# This spec runs against the BUILT site (`_site/`) so it catches
# leaks regardless of which template, data file, or include emits them.

describe "email + phone privacy invariants (built site)" do
  SITE_DIR = ROOT / "_site"

  # Targeted patterns. The regex pool is intentionally narrow to avoid
  # false positives — e.g. we don't ban every `@` (that would catch CSS
  # `@media`, JS decorators, npm scope names) but we do ban an `@` flanked
  # by something that looks like an email.
  EMAIL_PATTERN = /[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}/
  MAILTO_PATTERN = /mailto:[^"'\s>]+/
  TEL_PATTERN = /tel:[^"'\s>]+/
  # French mobile shapes: 06/07 mobiles + +33 prefixes. Loose enough to
  # catch the formats Ghislain has actually used in past assets.
  # Digit-boundary lookarounds [sweep 2026-06 #2]: without them the pattern
  # matches inside longer digit runs (build timestamps, minified-JS number
  # literals) now that the scan covers JS bundles and sourcemaps — a false
  # "phone leak" with no privacy issue. Real phone formats keep matching.
  FR_PHONE_PATTERN = /(?<!\d)(?:\+33[\s.-]?[1-9](?:[\s.-]?\d{2}){4}|0[6-7](?:[\s.-]?\d{2}){4})(?!\d)/

  # We scan EVERY text-like served file, not a hand-picked allow-list of
  # extensions. The header invariant is "email/phone never in ANY
  # web-served file" — a narrow glob (html/xml/json/txt) silently exempted
  # JS bundles, CSS, SVG, the webmanifest, and sourcemaps, all of which a
  # scraper or visitor can fetch verbatim. Instead we walk the whole built
  # tree and skip only binaries (images, fonts, PDFs) by extension.
  #
  # Binary extensions are excluded because (a) they cannot leak a
  # plaintext email/phone the way a text file can and (b) reading them as
  # UTF-8 would raise or produce garbage. Everything else — including
  # extension-less files like `CNAME` — is treated as text and scanned.
  BINARY_EXTS = %w[
    .woff .woff2 .ttf .otf .eot
    .png .jpg .jpeg .gif .webp .ico .bmp .avif
    .pdf .zip .gz .mp4 .webm .mp3 .ogg
  ].freeze

  # Allow-list for known-safe substrings inside otherwise-flagged files.
  # Empty for now — we want zero leaks. If a future build legitimately
  # needs to surface an email (e.g. a contact-form action target with a
  # `noreply@` recipient hidden behind hashing), add the exact line + a
  # justification comment to this list.
  ALLOWED_HITS = [].freeze

  before(:all) do
    raise "Run `bundle exec jekyll build` first; _site/ missing." unless SITE_DIR.exist?
  end

  # Every served file except known binaries. Returns absolute paths.
  def served_text_files
    Dir.glob(SITE_DIR / "**/*").select do |path|
      File.file?(path) && !BINARY_EXTS.include?(File.extname(path).downcase)
    end
  end

  def scan(pattern, label)
    violations = []
    served_text_files.each do |file|
      contents = File.read(file, encoding: "UTF-8", invalid: :replace, undef: :replace)
      contents.scan(pattern) do |_match|
        hit = Regexp.last_match[0]
        next if ALLOWED_HITS.any? { |allowed| allowed == hit }
        rel = Pathname.new(file).relative_path_from(SITE_DIR).to_s
        violations << "#{rel}: #{label} match #{hit.inspect}"
      end
    end
    violations
  end

  it "no `mailto:` links in any served file" do
    violations = scan(MAILTO_PATTERN, "mailto:")
    expect(violations).to be_empty, "mailto: leaks:\n#{violations.join("\n")}"
  end

  it "no `tel:` links in any served file" do
    violations = scan(TEL_PATTERN, "tel:")
    expect(violations).to be_empty, "tel: leaks:\n#{violations.join("\n")}"
  end

  it "no email-shaped strings in any served file" do
    violations = scan(EMAIL_PATTERN, "email")
    expect(violations).to be_empty, "email-shaped leaks:\n#{violations.join("\n")}"
  end

  it "no French phone-shaped strings in any served file" do
    violations = scan(FR_PHONE_PATTERN, "FR phone")
    expect(violations).to be_empty, "FR phone-shaped leaks:\n#{violations.join("\n")}"
  end
end
