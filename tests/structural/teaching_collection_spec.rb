require_relative "spec_helper"

# Invariants for the _teaching/ collection. Per plan §3.5:
# default entry ships with short description only; some may have a detail page.

describe "teaching collection invariants" do
  TEACH_DIR = I18nPairs::ROOT / "_teaching"
  TEACH_REQUIRED = %w[title institution years year_end lang ref short_description themes format].freeze
  TEACH_ALLOWED_LEVELS = %w[undergrad grad pro exec].freeze
  TEACH_ALLOWED_ROLES = %w[lead co guest].freeze
  TEACH_ALLOWED_THEMES = %w[data-ai digital-services mobility].freeze
  TEACH_ALLOWED_FORMATS = %w[academic executive innovative].freeze

  it "directory exists with ≥ 1 entry" do
    expect(TEACH_DIR.exist?).to be(true)
    expect(Dir.glob(TEACH_DIR / "*.md")).not_to be_empty
  end

  it "every entry declares required fields" do
    missing = []
    Dir.glob(TEACH_DIR / "*.md").each do |file|
      fm = I18nPairs.frontmatter(file)
      rel = Pathname.new(file).relative_path_from(I18nPairs::ROOT).to_s
      TEACH_REQUIRED.each do |k|
        missing << "#{rel}: missing `#{k}`" if fm[k].nil? || fm[k].to_s.strip.empty?
      end
    end
    expect(missing).to be_empty, "Teaching schema violations:\n#{missing.join("\n")}"
  end

  it "every `level` (if declared) is in the allowed set" do
    violations = []
    Dir.glob(TEACH_DIR / "*.md").each do |file|
      fm = I18nPairs.frontmatter(file)
      next unless fm["level"]
      unless TEACH_ALLOWED_LEVELS.include?(fm["level"].to_s)
        rel = Pathname.new(file).relative_path_from(I18nPairs::ROOT).to_s
        violations << "#{rel}: level=#{fm["level"].inspect} not in #{TEACH_ALLOWED_LEVELS}"
      end
    end
    expect(violations).to be_empty, "Bad levels:\n#{violations.join("\n")}"
  end

  it "every `role` (if declared) is in the allowed set" do
    violations = []
    Dir.glob(TEACH_DIR / "*.md").each do |file|
      fm = I18nPairs.frontmatter(file)
      next unless fm["role"]
      unless TEACH_ALLOWED_ROLES.include?(fm["role"].to_s)
        rel = Pathname.new(file).relative_path_from(I18nPairs::ROOT).to_s
        violations << "#{rel}: role=#{fm["role"].inspect} not in #{TEACH_ALLOWED_ROLES}"
      end
    end
    expect(violations).to be_empty, "Bad roles:\n#{violations.join("\n")}"
  end

  it "years field is an array of 4-digit years" do
    violations = []
    Dir.glob(TEACH_DIR / "*.md").each do |file|
      fm = I18nPairs.frontmatter(file)
      next unless fm["years"]
      years = fm["years"]
      rel = Pathname.new(file).relative_path_from(I18nPairs::ROOT).to_s
      unless years.is_a?(Array) && years.all? { |y| y.to_s =~ /^\d{4}$/ }
        violations << "#{rel}: years=#{years.inspect} not an array of 4-digit years"
      end
    end
    expect(violations).to be_empty
  end

  it "every `themes` is a non-empty array of allowed values" do
    violations = []
    Dir.glob(TEACH_DIR / "*.md").each do |file|
      fm = I18nPairs.frontmatter(file)
      rel = Pathname.new(file).relative_path_from(I18nPairs::ROOT).to_s
      themes = fm["themes"]
      unless themes.is_a?(Array) && !themes.empty?
        violations << "#{rel}: themes=#{themes.inspect} must be a non-empty array"
        next
      end
      bad = themes.reject { |t| TEACH_ALLOWED_THEMES.include?(t.to_s) }
      violations << "#{rel}: themes=#{bad.inspect} not in #{TEACH_ALLOWED_THEMES}" unless bad.empty?
    end
    expect(violations).to be_empty, "theme violations:\n#{violations.join("\n")}"
  end

  it "every `format` is in the allowed set" do
    violations = []
    Dir.glob(TEACH_DIR / "*.md").each do |file|
      fm = I18nPairs.frontmatter(file)
      rel = Pathname.new(file).relative_path_from(I18nPairs::ROOT).to_s
      unless TEACH_ALLOWED_FORMATS.include?(fm["format"].to_s)
        violations << "#{rel}: format=#{fm["format"].inspect} not in #{TEACH_ALLOWED_FORMATS}"
      end
    end
    expect(violations).to be_empty, "format violations:\n#{violations.join("\n")}"
  end

  # year_end is the scalar we sort on (see _config.yml teaching collection).
  # Must be a bare 4-digit integer — strings or arrays break Jekyll's sort.
  it "year_end is a 4-digit integer matching the last year in `years`" do
    violations = []
    Dir.glob(TEACH_DIR / "*.md").each do |file|
      fm = I18nPairs.frontmatter(file)
      next unless fm["year_end"]
      rel = Pathname.new(file).relative_path_from(I18nPairs::ROOT).to_s
      unless fm["year_end"].is_a?(Integer) && fm["year_end"].to_s =~ /^\d{4}$/
        violations << "#{rel}: year_end=#{fm["year_end"].inspect} must be a 4-digit integer"
        next
      end
      if fm["years"].is_a?(Array) && fm["years"].last.to_i != fm["year_end"]
        violations << "#{rel}: year_end=#{fm["year_end"]} disagrees with years.last=#{fm["years"].last}"
      end
    end
    expect(violations).to be_empty, "year_end violations:\n#{violations.join("\n")}"
  end
end
