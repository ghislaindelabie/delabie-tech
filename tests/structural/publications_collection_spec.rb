require_relative "spec_helper"

# Invariants for the _publications/ collection. Replaces the BibTeX-backed
# /publications/ page from the legacy site.
#
# Regression guards (from WEBSITE_AUDIT.md §2.2): no Einstein placeholder.

describe "publications collection invariants" do
  PUB_DIR = I18nPairs::ROOT / "_publications"
  PUB_REQUIRED = %w[title date venue type lang ref short_description themes format].freeze
  PUB_ALLOWED_TYPES = %w[report talk webinar interview paper].freeze
  PUB_ALLOWED_THEMES = %w[data-ai digital-services mobility].freeze
  PUB_ALLOWED_FORMATS = %w[report talk].freeze

  it "directory exists with ≥ 1 entry" do
    expect(PUB_DIR.exist?).to be(true)
    expect(Dir.glob(PUB_DIR / "*.md")).not_to be_empty
  end

  it "every entry declares required fields" do
    missing = []
    Dir.glob(PUB_DIR / "*.md").each do |file|
      fm = I18nPairs.frontmatter(file)
      rel = Pathname.new(file).relative_path_from(I18nPairs::ROOT).to_s
      PUB_REQUIRED.each do |k|
        missing << "#{rel}: missing `#{k}`" if fm[k].nil? || fm[k].to_s.strip.empty?
      end
    end
    expect(missing).to be_empty, "Publication schema violations:\n#{missing.join("\n")}"
  end

  it "every entry's type is in the allowed set" do
    violations = []
    Dir.glob(PUB_DIR / "*.md").each do |file|
      fm = I18nPairs.frontmatter(file)
      next unless fm["type"]
      unless PUB_ALLOWED_TYPES.include?(fm["type"].to_s)
        rel = Pathname.new(file).relative_path_from(I18nPairs::ROOT).to_s
        violations << "#{rel}: type=#{fm["type"].inspect} not in #{PUB_ALLOWED_TYPES}"
      end
    end
    expect(violations).to be_empty, "Bad types:\n#{violations.join("\n")}"
  end

  it "every `themes` is a non-empty array of allowed values" do
    violations = []
    Dir.glob(PUB_DIR / "*.md").each do |file|
      fm = I18nPairs.frontmatter(file)
      rel = Pathname.new(file).relative_path_from(I18nPairs::ROOT).to_s
      themes = fm["themes"]
      unless themes.is_a?(Array) && !themes.empty?
        violations << "#{rel}: themes=#{themes.inspect} must be a non-empty array"
        next
      end
      bad = themes.reject { |t| PUB_ALLOWED_THEMES.include?(t.to_s) }
      violations << "#{rel}: themes=#{bad.inspect} not in #{PUB_ALLOWED_THEMES}" unless bad.empty?
    end
    expect(violations).to be_empty, "theme violations:\n#{violations.join("\n")}"
  end

  it "every `format` is in the allowed set" do
    violations = []
    Dir.glob(PUB_DIR / "*.md").each do |file|
      fm = I18nPairs.frontmatter(file)
      rel = Pathname.new(file).relative_path_from(I18nPairs::ROOT).to_s
      unless PUB_ALLOWED_FORMATS.include?(fm["format"].to_s)
        violations << "#{rel}: format=#{fm["format"].inspect} not in #{PUB_ALLOWED_FORMATS}"
      end
    end
    expect(violations).to be_empty, "format violations:\n#{violations.join("\n")}"
  end

  # Regression guard.
  it "no Einstein placeholder anywhere in publications" do
    violations = []
    Dir.glob(PUB_DIR / "*.md").each do |file|
      raw = File.read(file)
      if raw.downcase.include?("einstein")
        rel = Pathname.new(file).relative_path_from(I18nPairs::ROOT).to_s
        violations << rel
      end
    end
    expect(violations).to be_empty, "Einstein placeholder still present in: #{violations}"
  end

  it "dates are parseable" do
    violations = []
    Dir.glob(PUB_DIR / "*.md").each do |file|
      fm = I18nPairs.frontmatter(file)
      next unless fm["date"]
      begin
        Date.parse(fm["date"].to_s)
      rescue ArgumentError
        rel = Pathname.new(file).relative_path_from(I18nPairs::ROOT).to_s
        violations << "#{rel}: unparseable date #{fm["date"].inspect}"
      end
    end
    expect(violations).to be_empty
  end

  # YouTube videos: when present, youtube_id looks like an ID (not a URL).
  it "video.youtube_id (if present) is a bare id, not a URL" do
    violations = []
    Dir.glob(PUB_DIR / "*.md").each do |file|
      fm = I18nPairs.frontmatter(file)
      yt = fm.dig("video", "youtube_id")
      next if yt.nil?
      if yt.to_s.include?("/") || yt.to_s.include?("youtube.com") || yt.to_s.include?("://")
        rel = Pathname.new(file).relative_path_from(I18nPairs::ROOT).to_s
        violations << "#{rel}: youtube_id looks like a URL — strip to bare id"
      end
    end
    expect(violations).to be_empty, "youtube_id shape violations:\n#{violations.join("\n")}"
  end
end
