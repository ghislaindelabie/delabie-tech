require_relative "spec_helper"

# Structural checks against the BUILT site (_site/). Run after `jekyll build`.
# Invariants that are cheap to verify in HTML but don't need a browser.

describe "rendered HTML invariants" do
  SITE = ROOT / "_site"

  before(:all) do
    raise "Run `bundle exec jekyll build` first; _site/ missing." unless SITE.exist?
  end

  # [REVIEW-12] + [SEC-5]: when `robots_noindex: true`, every page must
  # emit the noindex meta EXACTLY once. Previously only checked "> 1";
  # tightened to "== 1" so a missing tag also fails (the preview could
  # otherwise leak to crawlers without any signal).
  it "emits <meta name=\"robots\" content=\"noindex\"> exactly once per page when robots_noindex is true" do
    config = YAML.safe_load_file(ROOT / "_config.yml", permitted_classes: [Date])
    skip "robots_noindex not enabled (post-cutover build)" unless config["robots_noindex"]

    violations = []
    Dir.glob(SITE / "**" / "index.html").each do |file|
      html = File.read(file)
      count = html.scan(/<meta\s+name=["']robots["']\s+content=["']noindex/i).size
      unless count == 1
        rel = Pathname.new(file).relative_path_from(SITE).to_s
        violations << "#{rel}: robots noindex meta count = #{count} (expected 1)"
      end
    end
    expect(violations).to be_empty, "robots noindex count violations:\n#{violations.join("\n")}"
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
  # Template-level: tab slugs are derived from the _tabs/ sources (every EN
  # tab with a FR sibling), so adding/removing a tab never touches this file.
  def paired_tab_slugs
    Dir.glob(ROOT / "_tabs" / "*.md").reject { |f| f.end_with?(".fr.md") }.filter_map do |src|
      fm = I18nPairs.frontmatter(src)
      next unless fm["permalink"] && File.exist?(src.sub(/\.md\z/, ".fr.md"))
      fm["permalink"].delete_prefix("/").delete_suffix("/")
    end
  end

  it "rendered EN tab URLs have no /fr/ prefix and no diacritics" do
    expect(paired_tab_slugs).not_to be_empty
    paired_tab_slugs.each do |tab|
      expect(tab).to match(/\A[a-z0-9-]+\z/), "EN tab slug #{tab.inspect} has diacritics or bad chars"
      expected = SITE / tab / "index.html"
      expect(expected.exist?).to be(true), "EN tab /#{tab}/ should exist as /#{tab}/index.html"
    end
  end

  it "rendered FR tab URLs use the /fr/ prefix" do
    paired_tab_slugs.each do |tab|
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

  # Addresses [REVIEW-1] + [REVIEW-16] + [REVIEW-3 @ 07:01]: checks are
  # scoped to the <aside id="sidebar"> block, not the full HTML, so page
  # body copy in the "other" language (expected in post content) does not
  # cause false positives.
  def sidebar_html(path)
    html = File.read(SITE / path)
    html[%r{<aside[^>]+id="sidebar".*?</aside>}m] || ""
  end

  it "EN home sidebar contains no /fr/ tab URLs" do
    nav = sidebar_html("index.html")
    fr_urls = nav.scan(%r{href="/fr/[^"]+"}).uniq
    expect(fr_urls).to be_empty, "EN sidebar leaked FR tab URLs: #{fr_urls}"
  end

  it "FR home sidebar contains only /fr/ tab URLs (no EN-only ones)" do
    nav = sidebar_html("fr/index.html")
    slugs = paired_tab_slugs
    skip "no paired tabs" if slugs.empty?
    en_shape = Regexp.union(slugs.map { |s| %r{href="/#{Regexp.escape(s)}/"} })
    en_only = nav.scan(en_shape).uniq
    expect(en_only).to be_empty, "FR sidebar leaked EN-only URLs: #{en_only}"
  end
end
