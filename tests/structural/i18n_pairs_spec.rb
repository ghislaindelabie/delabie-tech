require_relative "spec_helper"

# Invariants for the custom bilingual setup. Uses the shared library in
# scripts/lib/i18n_pairs.rb (same logic is in the CLI). See CHIRPY_MIGRATION_PLAN.md §2.

describe "i18n pair invariants" do
  let(:files) { I18nPairs.content_files }

  it "every content file declares a `lang` and a `ref`" do
    missing = []
    files.each do |file|
      fm = I18nPairs.frontmatter(file)
      rel = Pathname.new(file).relative_path_from(I18nPairs::ROOT).to_s
      missing << "#{rel}: missing lang" unless fm["lang"]
      missing << "#{rel}: missing ref"  unless fm["ref"]
    end
    expect(missing).to be_empty, "Content files without lang/ref:\n#{missing.join("\n")}"
  end

  it "every EN file has an FR sibling OR declares translated: false" do
    orphans = []
    files.each do |file|
      fm = I18nPairs.frontmatter(file)
      next unless fm["lang"] == "en"
      next if fm["translated"] == false
      sibling = I18nPairs.sibling_path(file)
      unless File.exist?(sibling)
        rel = Pathname.new(file).relative_path_from(I18nPairs::ROOT).to_s
        orphans << "#{rel} has no FR sibling (add #{File.basename(sibling)} or set translated: false)"
      end
    end
    expect(orphans).to be_empty, "EN files without translations:\n#{orphans.join("\n")}"
  end

  it "every FR file has an EN sibling OR declares translated: false" do
    orphans = []
    files.each do |file|
      fm = I18nPairs.frontmatter(file)
      next unless fm["lang"] == "fr"
      next if fm["translated"] == false
      sibling = I18nPairs.sibling_path(file)
      unless File.exist?(sibling)
        rel = Pathname.new(file).relative_path_from(I18nPairs::ROOT).to_s
        orphans << "#{rel} has no EN sibling (add #{File.basename(sibling)} or set translated: false)"
      end
    end
    expect(orphans).to be_empty, "FR files without translations:\n#{orphans.join("\n")}"
  end

  # Addresses [REVIEW-5]: split the old test into two precise checks.
  it "no two files for the same language share a `ref`" do
    conflicts = []
    by_lang_ref = Hash.new { |h, k| h[k] = [] }
    files.each do |file|
      fm = I18nPairs.frontmatter(file)
      next unless fm["ref"] && fm["lang"]
      by_lang_ref[[fm["lang"], fm["ref"]]] << file
    end
    by_lang_ref.each do |(lang, ref), fs|
      if fs.size > 1
        rels = fs.map { |f| Pathname.new(f).relative_path_from(I18nPairs::ROOT).to_s }
        conflicts << "lang=#{lang} ref=#{ref} claimed by: #{rels.join(', ')}"
      end
    end
    expect(conflicts).to be_empty, "Ref conflicts within a language:\n#{conflicts.join("\n")}"
  end

  # Addresses [REVIEW-5]: the genuinely symmetric invariant.
  it "paired EN/FR files on disk share the same `ref`" do
    mismatches = []
    I18nPairs.pairs_on_disk.each do |a, b|
      fm_a = I18nPairs.frontmatter(a)
      fm_b = I18nPairs.frontmatter(b)
      next unless fm_a["ref"] && fm_b["ref"]
      if fm_a["ref"] != fm_b["ref"]
        rel_a = Pathname.new(a).relative_path_from(I18nPairs::ROOT).to_s
        rel_b = Pathname.new(b).relative_path_from(I18nPairs::ROOT).to_s
        mismatches << "#{rel_a}(ref=#{fm_a["ref"]}) / #{rel_b}(ref=#{fm_b["ref"]}) disagree"
      end
    end
    expect(mismatches).to be_empty, "Paired files with different refs:\n#{mismatches.join("\n")}"
  end

  it "FR files have /fr/ in their permalink (explicit or via config default)" do
    violations = []
    files.each do |file|
      fm = I18nPairs.frontmatter(file)
      next unless fm["lang"] == "fr"
      next unless fm["permalink"]
      rel = Pathname.new(file).relative_path_from(I18nPairs::ROOT).to_s
      violations << "#{rel} has permalink #{fm["permalink"].inspect}" unless fm["permalink"].start_with?("/fr/")
    end
    expect(violations).to be_empty, "FR files with wrong permalinks:\n#{violations.join("\n")}"
  end

  it "EN files do NOT have /fr/ in their permalink" do
    violations = []
    files.each do |file|
      fm = I18nPairs.frontmatter(file)
      next unless fm["lang"] == "en"
      next unless fm["permalink"]
      rel = Pathname.new(file).relative_path_from(I18nPairs::ROOT).to_s
      if fm["permalink"].start_with?("/fr/")
        violations << "#{rel} is lang:en but permalink starts with /fr/"
      end
    end
    expect(violations).to be_empty, "EN files with /fr/ permalinks:\n#{violations.join("\n")}"
  end
end
