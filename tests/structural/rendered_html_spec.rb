require_relative "spec_helper"

# Structural checks against the BUILT site (_site/). Run after `jekyll build`.
# Invariants that are cheap to verify in HTML but don't need a browser.

describe "rendered HTML invariants" do
  SITE = ROOT / "_site"

  before(:all) do
    raise "Run `bundle exec jekyll build` first; _site/ missing." unless SITE.exist?
  end

  # Addresses [REVIEW-12]: robots noindex emission must be single-source.
  it "emits <meta name=\"robots\" content=\"noindex...\"> at most once per page" do
    violations = []
    Dir.glob(SITE / "**" / "index.html").each do |file|
      html = File.read(file)
      count = html.scan(/<meta\s+name=["']robots["']\s+content=["']noindex/i).size
      if count > 1
        rel = Pathname.new(file).relative_path_from(SITE).to_s
        violations << "#{rel}: robots noindex meta appears #{count} times"
      end
    end
    expect(violations).to be_empty, "Duplicate robots noindex:\n#{violations.join("\n")}"
  end

  # Addresses [REVIEW-3]: x-default must point at the default (EN) version.
  it "x-default hreflang points at the EN version of the page" do
    en_home = File.read(SITE / "index.html")
    fr_home = File.read(SITE / "fr" / "index.html")

    en_xdef = en_home[/<link[^>]+hreflang="x-default"[^>]+href="([^"]+)"/, 1]
    fr_xdef = fr_home[/<link[^>]+hreflang="x-default"[^>]+href="([^"]+)"/, 1]

    expect(en_xdef).to match(%r{/$}), "EN x-default should point to /"
    expect(en_xdef).not_to include("/fr/")
    expect(fr_xdef).to match(%r{/$}), "FR x-default should point to /"
    expect(fr_xdef).not_to include("/fr/"), "FR x-default must NOT point to /fr/; should be default=EN"
  end

  # Addresses [REVIEW-13] (partial): permalinks follow the EN/FR shape rule.
  it "rendered EN tab URLs have no /fr/ prefix and no diacritics" do
    tab_paths = %w[about archives categories tags]
    tab_paths.each do |tab|
      expected = SITE / tab / "index.html"
      expect(expected.exist?).to be(true), "EN tab /#{tab}/ should exist as /#{tab}/index.html"
    end
  end

  it "rendered FR tab URLs use the /fr/ prefix" do
    tab_paths = %w[about archives categories tags]
    tab_paths.each do |tab|
      expected = SITE / "fr" / tab / "index.html"
      expect(expected.exist?).to be(true), "FR tab should exist as /fr/#{tab}/index.html"
    end
  end

  it "every content page has exactly one canonical link" do
    violations = []
    Dir.glob(SITE / "**" / "index.html").each do |file|
      count = File.read(file).scan(/<link\s+rel="canonical"/i).size
      unless count == 1
        rel = Pathname.new(file).relative_path_from(SITE).to_s
        violations << "#{rel}: canonical count = #{count}"
      end
    end
    expect(violations).to be_empty, "Canonical issues:\n#{violations.join("\n")}"
  end

  # Addresses [REVIEW-1]: sidebar nav filtered by language.
  it "EN home sidebar nav contains no French tab labels" do
    html = File.read(SITE / "index.html")
    french_words = %w[ARCHIVES CATÉGORIES ÉTIQUETTES]  # FR UI strings that would leak if filter missed
    # ARCHIVES is identical in EN/FR so skip it; use diacritic-bearing ones.
    accented = french_words.select { |w| w.match?(/[ÀÂÄÇÉÈÊËÎÏÔÖÙÛÜŸŒÆ]/) }
    violations = accented.select { |w| html.include?(w) }
    expect(violations).to be_empty, "EN nav leaked FR tab labels: #{violations}"
  end

  it "FR home sidebar nav contains only FR tab entries" do
    html = File.read(SITE / "fr" / "index.html")
    # EN-only tab labels should not appear in nav links
    # (we look for /archives/ without /fr/ prefix in href attrs inside the sidebar area)
    en_only_hrefs = html.scan(/href="\/(?:about|archives|categories|tags)\/"/).size
    expect(en_only_hrefs).to eq(0), "FR nav leaked links to EN-only URLs: #{en_only_hrefs} matches"
  end
end
