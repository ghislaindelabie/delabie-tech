require_relative "spec_helper"

# Invariants for the `_activity/` collection — short-form updates surfaced
# on the homepage. One file per update. Schema is deliberately small.

describe "activity collection invariants" do
  ACTIVITY_DIR = I18nPairs::ROOT / "_activity"
  ACTIVITY_REQUIRED = %w[date title lang ref].freeze

  it "directory exists with ≥ 1 entry" do
    expect(ACTIVITY_DIR.exist?).to be(true), "_activity/ directory missing"
    files = Dir.glob(ACTIVITY_DIR / "*.md")
    expect(files).not_to be_empty
  end

  it "every entry declares required fields" do
    missing = []
    Dir.glob(ACTIVITY_DIR / "*.md").each do |file|
      fm = I18nPairs.frontmatter(file)
      rel = Pathname.new(file).relative_path_from(I18nPairs::ROOT).to_s
      ACTIVITY_REQUIRED.each do |k|
        missing << "#{rel}: missing `#{k}`" if fm[k].nil? || fm[k].to_s.strip.empty?
      end
    end
    expect(missing).to be_empty, "Activity schema violations:\n#{missing.join("\n")}"
  end

  it "every entry has a body under 600 characters (short-form discipline)" do
    violations = []
    Dir.glob(ACTIVITY_DIR / "*.md").each do |file|
      raw = File.read(file)
      body = raw.sub(/\A---\s*\n.*?\n---\s*\n/m, "").strip
      if body.length > 600
        rel = Pathname.new(file).relative_path_from(I18nPairs::ROOT).to_s
        violations << "#{rel}: body is #{body.length} chars (cap 600)"
      end
    end
    expect(violations).to be_empty, "Activity entries too long:\n#{violations.join("\n")}"
  end

  it "dates are ISO-8601 parseable" do
    violations = []
    Dir.glob(ACTIVITY_DIR / "*.md").each do |file|
      fm = I18nPairs.frontmatter(file)
      next unless fm["date"]
      begin
        Date.parse(fm["date"].to_s)
      rescue ArgumentError
        rel = Pathname.new(file).relative_path_from(I18nPairs::ROOT).to_s
        violations << "#{rel}: unparseable date #{fm["date"].inspect}"
      end
    end
    expect(violations).to be_empty, "Bad dates:\n#{violations.join("\n")}"
  end

  # [REVIEW-12] Constrain lang values to the configured set. A typo like
  # `lang: en-US` or `lang: fr-FR` would silently disappear from the home
  # filter (which matches exactly "en" / "fr").
  it "every entry's lang is in the configured language set" do
    allowed = YAML.safe_load_file(I18nPairs::ROOT / "_data/i18n.yml")
      .dig("languages")&.map { |l| l["code"] } || %w[en fr]
    violations = []
    Dir.glob(ACTIVITY_DIR / "*.md").each do |file|
      fm = I18nPairs.frontmatter(file)
      next unless fm["lang"]
      unless allowed.include?(fm["lang"].to_s)
        rel = Pathname.new(file).relative_path_from(I18nPairs::ROOT).to_s
        violations << "#{rel}: lang=#{fm["lang"].inspect} not in #{allowed.inspect}"
      end
    end
    expect(violations).to be_empty, "Invalid lang values:\n#{violations.join("\n")}"
  end
end
