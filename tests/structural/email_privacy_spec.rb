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
  FR_PHONE_PATTERN = /(?:\+33[\s.-]?[1-9](?:[\s.-]?\d{2}){4}|0[6-7](?:[\s.-]?\d{2}){4})/

  # Files we scan. HTML, XML (sitemap, feed), JSON (resume.json etc.),
  # plus any text-y assets explicitly committed.
  SCAN_GLOBS = %w[
    **/*.html
    **/*.xml
    **/*.json
    **/*.txt
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

  def scan(pattern, label)
    violations = []
    SCAN_GLOBS.each do |glob|
      Dir.glob(SITE_DIR / glob).each do |file|
        contents = File.read(file)
        contents.scan(pattern) do |match|
          hit = Regexp.last_match[0]
          next if ALLOWED_HITS.any? { |allowed| allowed == hit }
          rel = Pathname.new(file).relative_path_from(SITE_DIR).to_s
          violations << "#{rel}: #{label} match #{hit.inspect}"
        end
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
