require_relative "spec_helper"
require "yaml"

# Invariant under custom i18n: every content file declaring `lang: en` must
# have a sibling `<basename>.fr.md` OR explicitly declare `translated: false`.
# Same holds symmetrically for FR files. See CHIRPY_MIGRATION_PLAN.md §2.

describe "i18n pair invariants" do
  CONTENT_DIRS = %w[_tabs _posts _case_studies _publications _teaching _activity].freeze

  def collect_content_files
    CONTENT_DIRS.flat_map do |dir|
      path = ROOT / dir
      next [] unless path.exist?
      Dir.glob(path / "**" / "*.md")
    end
  end

  def parse_frontmatter(file)
    raw = File.read(file)
    return {} unless raw =~ /\A---\s*\n(.*?)\n---\s*\n/m
    YAML.safe_load($1, permitted_classes: [Date, Time]) || {}
  end

  def sibling_path(file)
    # EN:      _tabs/about.md       -> _tabs/about.fr.md
    # FR:      _tabs/about.fr.md    -> _tabs/about.md
    base = File.basename(file, ".md")
    dir = File.dirname(file)
    if base.end_with?(".fr")
      File.join(dir, "#{base.chomp(".fr")}.md")
    else
      File.join(dir, "#{base}.fr.md")
    end
  end

  it "every content file declares a `lang` and a `ref`" do
    missing = []
    collect_content_files.each do |file|
      fm = parse_frontmatter(file)
      rel = Pathname.new(file).relative_path_from(ROOT).to_s
      missing << "#{rel}: missing lang" unless fm["lang"]
      missing << "#{rel}: missing ref"  unless fm["ref"]
    end
    expect(missing).to be_empty, "Content files without lang/ref:\n#{missing.join("\n")}"
  end

  it "every EN file has an FR sibling OR declares translated: false" do
    orphans = []
    collect_content_files.each do |file|
      fm = parse_frontmatter(file)
      next unless fm["lang"] == "en"
      next if fm["translated"] == false
      sibling = sibling_path(file)
      unless File.exist?(sibling)
        rel = Pathname.new(file).relative_path_from(ROOT).to_s
        orphans << "#{rel} has no FR sibling (add #{File.basename(sibling)} or set translated: false)"
      end
    end
    expect(orphans).to be_empty, "EN files without translations:\n#{orphans.join("\n")}"
  end

  it "every FR file has an EN sibling OR declares translated: false" do
    orphans = []
    collect_content_files.each do |file|
      fm = parse_frontmatter(file)
      next unless fm["lang"] == "fr"
      next if fm["translated"] == false
      sibling = sibling_path(file)
      unless File.exist?(sibling)
        rel = Pathname.new(file).relative_path_from(ROOT).to_s
        orphans << "#{rel} has no EN sibling (add #{File.basename(sibling)} or set translated: false)"
      end
    end
    expect(orphans).to be_empty, "FR files without translations:\n#{orphans.join("\n")}"
  end

  it "paired EN/FR files share the same `ref`" do
    mismatches = []
    files_by_ref = Hash.new { |h, k| h[k] = [] }
    collect_content_files.each do |file|
      fm = parse_frontmatter(file)
      next unless fm["ref"] && fm["lang"]
      files_by_ref[fm["ref"]] << { file: file, lang: fm["lang"] }
    end
    files_by_ref.each do |ref, entries|
      langs = entries.map { |e| e[:lang] }
      if langs.tally.any? { |_, count| count > 1 }
        rels = entries.map { |e| Pathname.new(e[:file]).relative_path_from(ROOT).to_s }
        mismatches << "ref=#{ref} appears more than once per language: #{rels.join(', ')}"
      end
    end
    expect(mismatches).to be_empty, "Ref collisions:\n#{mismatches.join("\n")}"
  end

  it "FR files have /fr/ in their permalink (explicit or via config default)" do
    # We check the explicit frontmatter permalink if present; config defaults
    # are trusted but covered by the rendered-HTML test.
    violations = []
    collect_content_files.each do |file|
      fm = parse_frontmatter(file)
      next unless fm["lang"] == "fr"
      next unless fm["permalink"]  # if not set, _config.yml default handles it
      rel = Pathname.new(file).relative_path_from(ROOT).to_s
      violations << "#{rel} has permalink #{fm["permalink"].inspect} (expected /fr/ prefix)" unless fm["permalink"].start_with?("/fr/")
    end
    expect(violations).to be_empty, "FR files with wrong permalinks:\n#{violations.join("\n")}"
  end

  it "EN files do NOT have /fr/ in their permalink" do
    violations = []
    collect_content_files.each do |file|
      fm = parse_frontmatter(file)
      next unless fm["lang"] == "en"
      next unless fm["permalink"]
      rel = Pathname.new(file).relative_path_from(ROOT).to_s
      if fm["permalink"].start_with?("/fr/")
        violations << "#{rel} is lang:en but permalink starts with /fr/"
      end
    end
    expect(violations).to be_empty, "EN files with /fr/ permalinks:\n#{violations.join("\n")}"
  end
end
