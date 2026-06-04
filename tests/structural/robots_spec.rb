require_relative "spec_helper"

# Invariants on the rendered robots.txt. The site's stance is open: all
# crawlers (regular search + AI training) are welcomed. Licensing handles
# the rules of engagement, not crawler blocking. See `assets/robots.txt`
# for the policy comment.

describe "robots.txt invariants (built site)" do
  ROBOTS_PATH = ROOT / "_site" / "robots.txt"

  before(:all) do
    raise "Run `bundle exec jekyll build` first; robots.txt missing." unless ROBOTS_PATH.exist?
  end

  let(:robots) { File.read(ROBOTS_PATH) }

  it "is served at /robots.txt" do
    expect(ROBOTS_PATH.exist?).to be(true)
  end

  it "points at the sitemap" do
    expect(robots).to match(%r{Sitemap:\s*\S+/sitemap\.xml})
  end

  # Regression guard for the open-crawler stance: catch any accidental
  # `Disallow: /` (blanket site-wide block). Specific path-blocks like
  # `Disallow: /norobots/` are fine — it's the global one we never want.
  it "does not contain a blanket site-wide block (`Disallow: /` on its own line)" do
    blanket_lines = robots.lines.map(&:strip).select { |line| line == "Disallow: /" }
    expect(blanket_lines).to be_empty,
      "Found #{blanket_lines.size} blanket `Disallow: /` line(s) — that would lock the whole site down"
  end

  it "permits the major search engines (no path-specific blocks against them)" do
    search_engines = %w[Googlebot Bingbot DuckDuckBot]
    blocked = []
    search_engines.each do |bot|
      if robots.match?(/User-agent:\s*#{Regexp.escape(bot)}\s*$.*?Disallow:\s*\/\s*$/m)
        blocked << bot
      end
    end
    expect(blocked).to be_empty, "Search engines blocked (regression):\n#{blocked.join(", ")}"
  end
end
