require_relative "spec_helper"

# Invariants for _data/repositories.yml — the source of truth for the
# /repositories/ tab. Enforces the three-section structure from the
# plan (§3.1) and guards against two concrete regressions flagged in
# WEBSITE_AUDIT.md:
#   - the legacy site surfaced a colleague's account (`TTalex`) alongside
#     Ghislain's own;
#   - the legacy site carried a self-deprecating intro line
#     ("Je débute encore dans le code — mes stats le montrent !").
# Neither should appear anywhere in the new data file or tab content.

describe "repositories data + page invariants" do
  REPOS_FILE = I18nPairs::ROOT / "_data/repositories.yml"
  # Fixed blacklist of known-regression strings. A paraphrase wouldn't be
  # caught; this is a named-regression guard, not a general tone detector.
  FORBIDDEN_STRINGS = [
    "TTalex",
    "je débute encore",
    "I'm a beginner",
  ].freeze

  it "data file exists" do
    expect(REPOS_FILE.exist?).to be(true), "_data/repositories.yml missing"
  end

  # [REVIEW-3] Data-driven: any ≥1 sections OK; no duplicate keys. Adding a
  # new section requires NO test change. The expected-keys lockdown was
  # removed in favor of structural invariants.
  it "has at least one section and no duplicate section keys" do
    data = YAML.safe_load_file(REPOS_FILE)
    sections = (data["sections"] || []).map { |s| s["key"] }.compact
    expect(sections).not_to be_empty
    expect(sections.size).to eq(sections.uniq.size), "Duplicate section keys: #{sections.tally.select { |_, c| c > 1 }.keys}"
  end

  it "every section declares a label (EN + FR) and at least one repo" do
    data = YAML.safe_load_file(REPOS_FILE)
    violations = []
    (data["sections"] || []).each do |section|
      key = section["key"] || "(no key)"
      violations << "#{key}: missing label.en" unless section.dig("label", "en")&.length&.> 0
      violations << "#{key}: missing label.fr" unless section.dig("label", "fr")&.length&.> 0
      repos = section["repos"] || []
      violations << "#{key}: no repos (sections with zero repos create empty UI blocks)" if repos.empty?
    end
    expect(violations).to be_empty, "Section shape violations:\n#{violations.join("\n")}"
  end

  # [REVIEW-14] If a section declares a blurb, it MUST have both EN and FR.
  # Silent EN-on-FR-page fallback otherwise.
  it "every section's blurb (when declared) has both EN and FR strings" do
    data = YAML.safe_load_file(REPOS_FILE)
    violations = []
    (data["sections"] || []).each do |section|
      blurb = section["blurb"]
      next if blurb.nil?
      key = section["key"] || "(no key)"
      %w[en fr].each do |l|
        violations << "#{key}: blurb.#{l} missing or empty" unless blurb.dig(l)&.length&.> 0
      end
    end
    expect(violations).to be_empty, "Blurb shape violations:\n#{violations.join("\n")}"
  end

  it "every repo has name + url + description" do
    data = YAML.safe_load_file(REPOS_FILE)
    violations = []
    (data["sections"] || []).each do |section|
      (section["repos"] || []).each_with_index do |r, i|
        loc = "section `#{section["key"]}` repo[#{i}]"
        %w[name url description].each do |k|
          violations << "#{loc}: missing `#{k}`" if r[k].nil? || r[k].to_s.strip.empty?
        end
      end
    end
    expect(violations).to be_empty, "Repo schema violations:\n#{violations.join("\n")}"
  end

  it "no forbidden strings anywhere in repositories data" do
    raw = File.read(REPOS_FILE).downcase
    hits = FORBIDDEN_STRINGS.select { |s| raw.include?(s.downcase) }
    expect(hits).to be_empty, "Forbidden strings in repositories.yml: #{hits.inspect}"
  end

  it "no forbidden strings in the repositories tab content (EN + FR)" do
    violations = []
    %w[_tabs/repositories.md _tabs/repositories.fr.md].each do |rel|
      path = I18nPairs::ROOT / rel
      next unless path.exist?
      raw = File.read(path).downcase
      FORBIDDEN_STRINGS.each do |s|
        violations << "#{rel}: contains forbidden string #{s.inspect}" if raw.include?(s.downcase)
      end
    end
    expect(violations).to be_empty, "Forbidden strings in tab content:\n#{violations.join("\n")}"
  end
end
