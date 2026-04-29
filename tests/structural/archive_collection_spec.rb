require_relative "spec_helper"

# Invariants for the _archive/ collection.
# Per CHIRPY_MIGRATION_PLAN Phase 4b + research/archive_design_options.md Scenario A':
#   `_archive/` is the surface where third parties cite Ghislain
#   (press, talks, podcasts, reports, citations). Items where he is the
#   signed author go elsewhere (the curated `_publications/` vitrine, or
#   the future dedicated Publications project).
#
# Strict bilingual policy: every item MUST have paired .md + .fr.md.
# No `translated: false` escape — this is stricter than the global i18n
# rule applied to other collections.

describe "archive collection invariants" do
  ARCHIVE_DIR = I18nPairs::ROOT / "_archive"
  ARCHIVE_REQUIRED = %w[title date type role source original_url lang ref tags projects excerpt].freeze
  ARCHIVE_ALLOWED_TYPES = %w[talk article oped interview report video podcast quoted].freeze
  ARCHIVE_ALLOWED_ROLES = %w[author co-author contributor speaker interviewee quoted facilitator moderator].freeze
  ARCHIVE_LANG_AGNOSTIC = %w[date type role source original_url wayback_url pdf cover ref tags projects detail].freeze

  it "directory exists with ≥ 1 entry" do
    expect(ARCHIVE_DIR.exist?).to be(true)
    expect(Dir.glob(ARCHIVE_DIR / "*.md")).not_to be_empty
  end

  it "every entry declares required fields" do
    missing = []
    Dir.glob(ARCHIVE_DIR / "*.md").each do |file|
      fm = I18nPairs.frontmatter(file)
      rel = Pathname.new(file).relative_path_from(I18nPairs::ROOT).to_s
      ARCHIVE_REQUIRED.each do |k|
        missing << "#{rel}: missing `#{k}`" if fm[k].nil? || fm[k].to_s.strip.empty?
      end
    end
    expect(missing).to be_empty, "Archive schema violations:\n#{missing.join("\n")}"
  end

  it "every `type` is in the allowed set" do
    violations = []
    Dir.glob(ARCHIVE_DIR / "*.md").each do |file|
      fm = I18nPairs.frontmatter(file)
      next unless fm["type"]
      unless ARCHIVE_ALLOWED_TYPES.include?(fm["type"].to_s)
        rel = Pathname.new(file).relative_path_from(I18nPairs::ROOT).to_s
        violations << "#{rel}: type=#{fm["type"].inspect} not in #{ARCHIVE_ALLOWED_TYPES}"
      end
    end
    expect(violations).to be_empty, "Bad types:\n#{violations.join("\n")}"
  end

  # The allow-list and `_data/archive_taxonomy.yml` must agree, otherwise
  # the type filter pills + per-row labels silently fall back to raw
  # enum keys ("talk" instead of "Talk" / "Conférence").
  it "every allowed type has an EN+FR label in archive_taxonomy.yml" do
    taxonomy_path = I18nPairs::ROOT / "_data" / "archive_taxonomy.yml"
    expect(taxonomy_path.exist?).to be(true)
    taxonomy = YAML.safe_load_file(taxonomy_path)
    types = taxonomy["types"] || {}
    missing = []
    ARCHIVE_ALLOWED_TYPES.each do |key|
      entry = types[key]
      missing << "#{key}: missing entry" if entry.nil?
      next if entry.nil?
      missing << "#{key}: missing EN label" if entry["en"].to_s.strip.empty?
      missing << "#{key}: missing FR label" if entry["fr"].to_s.strip.empty?
    end
    expect(missing).to be_empty, "Taxonomy gaps:\n#{missing.join("\n")}"
  end

  it "every `role` is in the allowed set" do
    violations = []
    Dir.glob(ARCHIVE_DIR / "*.md").each do |file|
      fm = I18nPairs.frontmatter(file)
      next unless fm["role"]
      unless ARCHIVE_ALLOWED_ROLES.include?(fm["role"].to_s)
        rel = Pathname.new(file).relative_path_from(I18nPairs::ROOT).to_s
        violations << "#{rel}: role=#{fm["role"].inspect} not in #{ARCHIVE_ALLOWED_ROLES}"
      end
    end
    expect(violations).to be_empty, "Bad roles:\n#{violations.join("\n")}"
  end

  it "`tags` is a non-empty array of strings" do
    violations = []
    Dir.glob(ARCHIVE_DIR / "*.md").each do |file|
      fm = I18nPairs.frontmatter(file)
      rel = Pathname.new(file).relative_path_from(I18nPairs::ROOT).to_s
      tags = fm["tags"]
      unless tags.is_a?(Array) && !tags.empty? && tags.all? { |t| t.is_a?(String) }
        violations << "#{rel}: tags=#{tags.inspect} must be a non-empty array of strings"
      end
    end
    expect(violations).to be_empty, "tags violations:\n#{violations.join("\n")}"
  end

  it "`projects` is an array (may be empty)" do
    violations = []
    Dir.glob(ARCHIVE_DIR / "*.md").each do |file|
      fm = I18nPairs.frontmatter(file)
      rel = Pathname.new(file).relative_path_from(I18nPairs::ROOT).to_s
      projects = fm["projects"]
      next if projects.nil?
      unless projects.is_a?(Array) && projects.all? { |p| p.is_a?(String) }
        violations << "#{rel}: projects=#{projects.inspect} must be an array of strings"
      end
    end
    expect(violations).to be_empty, "projects violations:\n#{violations.join("\n")}"
  end

  it "`detail` is a boolean" do
    violations = []
    Dir.glob(ARCHIVE_DIR / "*.md").each do |file|
      fm = I18nPairs.frontmatter(file)
      rel = Pathname.new(file).relative_path_from(I18nPairs::ROOT).to_s
      next unless fm.key?("detail")
      unless [true, false].include?(fm["detail"])
        violations << "#{rel}: detail=#{fm["detail"].inspect} must be true or false"
      end
    end
    expect(violations).to be_empty, "detail violations:\n#{violations.join("\n")}"
  end

  it "dates are parseable" do
    violations = []
    Dir.glob(ARCHIVE_DIR / "*.md").each do |file|
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

  # URL/path regexes deliberately forbid `"`, `<`, `>`, whitespace.
  # These bytes can't appear in a real URL — but if they slipped into
  # front matter (corrupted clipboard, manual edit), they would break
  # out of the surrounding `<a href="...">` attribute at render time.
  # Tightening the schema gate is cheaper than escaping at every call site.
  it "`original_url` is a well-formed http(s) URL with no attribute-breaking bytes" do
    violations = []
    Dir.glob(ARCHIVE_DIR / "*.md").each do |file|
      fm = I18nPairs.frontmatter(file)
      url = fm["original_url"].to_s
      next if url.empty?
      unless url.match?(%r{\Ahttps?://[^"\s<>]+\z})
        rel = Pathname.new(file).relative_path_from(I18nPairs::ROOT).to_s
        violations << "#{rel}: original_url=#{url.inspect} must be http(s) with no \" < > or whitespace"
      end
    end
    expect(violations).to be_empty, "URL violations:\n#{violations.join("\n")}"
  end

  it "`wayback_url` (if present) is a well-formed web.archive.org URL" do
    violations = []
    Dir.glob(ARCHIVE_DIR / "*.md").each do |file|
      fm = I18nPairs.frontmatter(file)
      url = fm["wayback_url"].to_s
      next if url.empty?
      unless url.match?(%r{\Ahttps?://web\.archive\.org/[^"\s<>]*\z})
        rel = Pathname.new(file).relative_path_from(I18nPairs::ROOT).to_s
        violations << "#{rel}: wayback_url=#{url.inspect} must point at web.archive.org with no \" < > or whitespace"
      end
    end
    expect(violations).to be_empty, "Wayback URL violations:\n#{violations.join("\n")}"
  end

  it "`pdf` (if present) is a strict site-relative path under /assets/pdf/archive/" do
    violations = []
    Dir.glob(ARCHIVE_DIR / "*.md").each do |file|
      fm = I18nPairs.frontmatter(file)
      pdf = fm["pdf"].to_s
      next if pdf.empty?
      unless pdf.match?(%r{\A/assets/pdf/archive/[A-Za-z0-9_./-]+\.pdf\z})
        rel = Pathname.new(file).relative_path_from(I18nPairs::ROOT).to_s
        violations << "#{rel}: pdf=#{pdf.inspect} must match /assets/pdf/archive/<safe-slug>.pdf"
      end
    end
    expect(violations).to be_empty, "PDF path violations:\n#{violations.join("\n")}"
  end

  # Strict bilingual rule for _archive/. Tighter than i18n_pairs_spec.rb,
  # which lets other collections opt out via `translated: false`.
  it "every entry has a paired .md + .fr.md (no `translated: false` escape)" do
    orphans = []
    Dir.glob(ARCHIVE_DIR / "*.md").each do |file|
      fm = I18nPairs.frontmatter(file)
      sibling = I18nPairs.sibling_path(file)
      rel = Pathname.new(file).relative_path_from(I18nPairs::ROOT).to_s
      if fm["translated"] == false
        orphans << "#{rel}: archive items must not opt out via translated: false"
        next
      end
      orphans << "#{rel}: missing sibling #{File.basename(sibling)}" unless File.exist?(sibling)
    end
    expect(orphans).to be_empty, "Pair violations:\n#{orphans.join("\n")}"
  end

  it "paired files agree on language-agnostic fields" do
    mismatches = []
    seen = {}
    Dir.glob(ARCHIVE_DIR / "*.md").each do |file|
      sibling = I18nPairs.sibling_path(file)
      next unless File.exist?(sibling)
      key = [file, sibling].sort
      next if seen[key]
      seen[key] = true
      fm_a = I18nPairs.frontmatter(key[0])
      fm_b = I18nPairs.frontmatter(key[1])
      ARCHIVE_LANG_AGNOSTIC.each do |k|
        next if fm_a[k].nil? && fm_b[k].nil?
        if fm_a[k] != fm_b[k]
          rel_a = Pathname.new(key[0]).relative_path_from(I18nPairs::ROOT).to_s
          rel_b = Pathname.new(key[1]).relative_path_from(I18nPairs::ROOT).to_s
          mismatches << "#{rel_a} vs #{rel_b}: `#{k}` differs (#{fm_a[k].inspect} vs #{fm_b[k].inspect})"
        end
      end
    end
    expect(mismatches).to be_empty, "Pair-disagreement on language-agnostic fields:\n#{mismatches.join("\n")}"
  end
end
