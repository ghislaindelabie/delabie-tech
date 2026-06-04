require_relative "spec_helper"

# Sitemap invariants on the BUILT site. The custom sitemap.xml at the
# repo root overrides jekyll-sitemap to add `<xhtml:link rel="alternate">`
# hreflang annotations per page.

describe "sitemap invariants (built site)" do
  SITEMAP_PATH = ROOT / "_site" / "sitemap.xml"

  before(:all) do
    raise "Run `bundle exec jekyll build` first; sitemap.xml missing." unless SITEMAP_PATH.exist?
  end

  let(:sitemap) { File.read(SITEMAP_PATH) }
  let(:locs) { sitemap.scan(%r{<loc>([^<]+)</loc>}).flatten }

  it "is well-formed XML" do
    require "rexml/document"
    doc = REXML::Document.new(sitemap)
    expect(doc.root.name).to eq("urlset")
  end

  it "declares the xhtml namespace for hreflang" do
    expect(sitemap).to include('xmlns:xhtml="http://www.w3.org/1999/xhtml"')
  end

  it "lists every bilingual content surface in both languages" do
    # We don't pin the exact URL list (content evolves) — but for any
    # `_archive/` item, both EN and /fr/ entries must be present so the
    # hreflang annotations are reciprocal.
    archive_dir = ROOT / "_archive"
    Dir.glob(archive_dir / "*.md").reject { |f| f.end_with?(".fr.md") }.each do |src|
      fm = I18nPairs.frontmatter(src)
      slug = fm["slug"] || File.basename(src, ".md")
      year = Date.parse(fm["date"].to_s).year
      en_url = "/archive/#{year}/#{slug}/"
      fr_url = "/fr/archive/#{year}/#{slug}/"
      expect(locs.any? { |l| l.end_with?(en_url) }).to be(true), "missing EN sitemap entry for #{en_url}"
      expect(locs.any? { |l| l.end_with?(fr_url) }).to be(true), "missing FR sitemap entry for #{fr_url}"
    end
  end

  it "every entry with a `ref:` carries hreflang en + fr + x-default" do
    # We can't easily map sitemap entries back to source frontmatter
    # without re-parsing every page, so we approximate: any `<url>` whose
    # `<loc>` is `/<year>/<slug>/`-shaped (collection content) MUST have
    # all three hreflang annotations. This catches the common regressions.
    blocks = sitemap.scan(%r{<url>(.*?)</url>}m).flatten
    violations = []
    blocks.each do |block|
      loc_match = block.match(%r{<loc>([^<]+)</loc>})
      next unless loc_match
      loc = loc_match[1]
      # Only check known-bilingual collections (skip /tags/, /categories/, etc.).
      next unless loc.match?(%r{/(case-studies|archive)/})
      %w[en fr x-default].each do |hreflang|
        unless block.include?(%(hreflang="#{hreflang}"))
          violations << "#{loc}: missing hreflang=#{hreflang.inspect}"
        end
      end
    end
    expect(violations).to be_empty, "Hreflang gaps:\n#{violations.join("\n")}"
  end

  it "asset URLs (CSS, JS, JSON, images, manifest) are excluded" do
    excluded_extensions = %w[.css .js .json .png .jpg .svg .ico .webmanifest]
    leaks = locs.select do |loc|
      excluded_extensions.any? { |ext| loc.end_with?(ext) }
    end
    expect(leaks).to be_empty, "Asset URL leaks in sitemap:\n#{leaks.join("\n")}"
  end

  it "every `<loc>` URL ends with a trailing slash (canonical content path)" do
    non_slashed = locs.reject { |l| l.end_with?("/") }
    expect(non_slashed).to be_empty, "Non-canonical sitemap entries:\n#{non_slashed.join("\n")}"
  end

  it "every `<loc>` is absolute (https://) and points at the configured site URL" do
    site_url = YAML.safe_load_file(ROOT / "_config.yml", permitted_classes: [Date])["url"]
    bad = locs.reject { |l| l.start_with?(site_url + "/") }
    expect(bad).to be_empty, "Non-absolute sitemap entries:\n#{bad.join("\n")}"
  end
end
