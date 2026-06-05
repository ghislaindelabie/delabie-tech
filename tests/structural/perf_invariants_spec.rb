require_relative "spec_helper"

# Phase 6 performance invariants on the BUILT site. Guards the self-hosted
# font setup and CLS-critical image dimensions against silent regression
# (e.g. a Chirpy gem bump reintroducing the Google Fonts link).
describe "perf invariants (built site)" do
  PERF_SITE = ROOT / "_site"

  before(:all) do
    raise "Run `bundle exec jekyll build` first; _site/ missing." unless PERF_SITE.exist?
  end

  it "no built page references the Google Fonts origins" do
    violations = []
    Dir.glob(PERF_SITE / "**" / "*.html").each do |file|
      next unless File.read(file).match?(/fonts\.googleapis\.com|fonts\.gstatic\.com/)
      violations << Pathname.new(file).relative_path_from(PERF_SITE).to_s
    end
    expect(violations).to be_empty, "Google Fonts origin leaked into:\n#{violations.join("\n")}"
  end

  it "every content page preloads the above-the-fold self-hosted fonts" do
    # The four preloads live in head.html, so spot-checking both language
    # homes covers the template for all pages.
    %w[index.html fr/index.html].each do |path|
      html = File.read(PERF_SITE / path)
      preloads = html.scan(/<link rel="preload" href="([^"]+\.woff2)"[^>]*as="font"[^>]*crossorigin/).flatten
      expect(preloads.size).to be >= 4, "#{path}: expected ≥4 font preloads, got #{preloads.inspect}"
      preloads.each do |href|
        asset = PERF_SITE / href.sub(%r{\A/}, "")
        expect(asset.exist?).to be(true), "#{path}: preloaded font missing from build: #{href}"
      end
    end
  end

  it "the stylesheet bundle embeds the self-hosted faces with the no-shift policy" do
    css = File.read(PERF_SITE / "assets" / "css" / "jekyll-theme-chirpy.css")
    expect(css.scan("font-display:optional").size).to be >= 6,
      "expected ≥6 @font-face rules with font-display:optional in the bundle"
    expect(css).to include("/assets/fonts/"), "bundle does not reference self-hosted font files"
  end

  it "every case-study cover image reserves its box (width + height attributes)" do
    violations = []
    Dir.glob(PERF_SITE / "**" / "case-studies" / "*" / "index.html").each do |file|
      html = File.read(file)
      html.scan(%r{<figure class="case-study__cover">.*?<img([^>]*)>}m).flatten.each do |attrs|
        next if attrs.include?("width=") && attrs.include?("height=")
        violations << Pathname.new(file).relative_path_from(PERF_SITE).to_s
      end
    end
    expect(violations).to be_empty,
      "Cover images without reserved dimensions (CLS risk):\n#{violations.uniq.join("\n")}"
  end
end
