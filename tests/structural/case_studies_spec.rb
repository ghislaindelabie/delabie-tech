require_relative "spec_helper"

# Template-level invariants for the case-study collection.
# These checks are data-driven over the files in `_case_studies/` — adding a
# new case study does NOT require updating any test.

describe "case-study collection invariants" do
  CASE_STUDY_DIR = I18nPairs::ROOT / "_case_studies"

  REQUIRED_FIELDS_EN = %w[title lang ref slug date_start category summary].freeze
  # FR counterparts may carry translated:false and a minimal body; they still
  # need the linkage fields so the pair invariant and switcher behave.
  REQUIRED_FIELDS_FR = %w[title lang ref slug permalink].freeze

  # [code review 2026-06 #9]: the allowed set is DERIVED from
  # _data/case_study_categories.yml — that data file is the single source of
  # truth. The old hardcoded list included `science`, which has no entry in
  # the data file, so a `category: science` doc passed the suite yet rendered
  # a raw slug (case_study.html / archive_item.html fall back to the bare
  # category when the key is missing). Deriving the set means a category is
  # allowed only once it is actually mapped to a label + icon.
  CATEGORY_DATA = YAML.safe_load_file(I18nPairs::ROOT / "_data" / "case_study_categories.yml")
  ALLOWED_CATEGORIES = CATEGORY_DATA.keys.freeze

  it "directory exists with at least one EN + one FR file" do
    expect(CASE_STUDY_DIR.exist?).to be(true)
    en = Dir.glob(CASE_STUDY_DIR / "*.md").reject { |f| f.end_with?(".fr.md") }
    fr = Dir.glob(CASE_STUDY_DIR / "*.fr.md")
    expect(en).not_to be_empty
    expect(fr).not_to be_empty
  end

  it "every EN case study declares required fields" do
    missing = []
    Dir.glob(CASE_STUDY_DIR / "*.md").reject { |f| f.end_with?(".fr.md") }.each do |file|
      fm = I18nPairs.frontmatter(file)
      rel = Pathname.new(file).relative_path_from(I18nPairs::ROOT).to_s
      REQUIRED_FIELDS_EN.each do |field|
        missing << "#{rel}: missing `#{field}`" if fm[field].nil? || fm[field].to_s.strip.empty?
      end
    end
    expect(missing).to be_empty, "EN case-study schema violations:\n#{missing.join("\n")}"
  end

  it "every FR case study declares the linkage fields" do
    missing = []
    Dir.glob(CASE_STUDY_DIR / "*.fr.md").each do |file|
      fm = I18nPairs.frontmatter(file)
      rel = Pathname.new(file).relative_path_from(I18nPairs::ROOT).to_s
      REQUIRED_FIELDS_FR.each do |field|
        missing << "#{rel}: missing `#{field}`" if fm[field].nil? || fm[field].to_s.strip.empty?
      end
    end
    expect(missing).to be_empty, "FR case-study schema violations:\n#{missing.join("\n")}"
  end

  it "every `category` is in the allowed set" do
    violations = []
    Dir.glob(CASE_STUDY_DIR / "*.md").each do |file|
      fm = I18nPairs.frontmatter(file)
      next unless fm["category"]
      unless ALLOWED_CATEGORIES.include?(fm["category"].to_s)
        rel = Pathname.new(file).relative_path_from(I18nPairs::ROOT).to_s
        violations << "#{rel}: category=#{fm["category"].inspect} not in #{ALLOWED_CATEGORIES}"
      end
    end
    expect(violations).to be_empty, "Unknown categories:\n#{violations.join("\n")}"
  end

  # [code review 2026-06 #9]: every category key must map to a renderable
  # entry — label.en, label.fr and icon — so the allowed set can never admit
  # a slug that would surface raw on the page.
  it "every category in the data file has label.en + label.fr + icon" do
    violations = []
    CATEGORY_DATA.each do |key, entry|
      unless entry.is_a?(Hash)
        violations << "#{key}: not a mapping"
        next
      end
      violations << "#{key}: missing icon" if entry["icon"].to_s.strip.empty?
      label = entry["label"] || {}
      violations << "#{key}: missing label.en" if label["en"].to_s.strip.empty?
      violations << "#{key}: missing label.fr" if label["fr"].to_s.strip.empty?
    end
    expect(violations).to be_empty, "Incomplete category entries:\n#{violations.join("\n")}"
  end

  it "date_start is a 4-digit year" do
    violations = []
    Dir.glob(CASE_STUDY_DIR / "*.md").each do |file|
      fm = I18nPairs.frontmatter(file)
      next unless fm["date_start"]
      unless fm["date_start"].to_s =~ /^\d{4}$/
        rel = Pathname.new(file).relative_path_from(I18nPairs::ROOT).to_s
        violations << "#{rel}: date_start=#{fm["date_start"].inspect} not a 4-digit year"
      end
    end
    expect(violations).to be_empty, "Bad date_start values:\n#{violations.join("\n")}"
  end

  it "if date_end present, it is a 4-digit year ≥ date_start" do
    violations = []
    Dir.glob(CASE_STUDY_DIR / "*.md").each do |file|
      fm = I18nPairs.frontmatter(file)
      next unless fm["date_end"]
      rel = Pathname.new(file).relative_path_from(I18nPairs::ROOT).to_s
      if fm["date_end"].to_s !~ /^\d{4}$/
        violations << "#{rel}: date_end=#{fm["date_end"].inspect} not a 4-digit year"
      elsif fm["date_start"] && fm["date_end"].to_i < fm["date_start"].to_i
        violations << "#{rel}: date_end (#{fm["date_end"]}) < date_start (#{fm["date_start"]})"
      end
    end
    expect(violations).to be_empty, "Bad date_end values:\n#{violations.join("\n")}"
  end

  it "a case study has either date_end OR ongoing: true — never both, never neither" do
    violations = []
    Dir.glob(CASE_STUDY_DIR / "*.md").reject { |f| f.end_with?(".fr.md") }.each do |file|
      fm = I18nPairs.frontmatter(file)
      rel = Pathname.new(file).relative_path_from(I18nPairs::ROOT).to_s
      has_end = !fm["date_end"].nil? && fm["date_end"].to_s.strip != ""
      has_ongoing = fm["ongoing"] == true
      if has_end && has_ongoing
        violations << "#{rel}: both date_end and ongoing:true set"
      elsif !has_end && !has_ongoing
        violations << "#{rel}: neither date_end nor ongoing:true set"
      end
    end
    expect(violations).to be_empty, "date_end/ongoing violations:\n#{violations.join("\n")}"
  end

  it "related_case_studies values reference existing refs" do
    refs = Dir.glob(CASE_STUDY_DIR / "*.md").map { |f| I18nPairs.frontmatter(f)["ref"] }.compact.uniq
    violations = []
    Dir.glob(CASE_STUDY_DIR / "*.md").each do |file|
      fm = I18nPairs.frontmatter(file)
      related = fm["related_case_studies"] || []
      related.each do |r|
        unless refs.include?(r.to_s)
          rel = Pathname.new(file).relative_path_from(I18nPairs::ROOT).to_s
          violations << "#{rel}: related_case_studies includes #{r.inspect} but no case study has that ref"
        end
      end
    end
    expect(violations).to be_empty, "Dangling related_case_studies refs:\n#{violations.join("\n")}"
  end
end
