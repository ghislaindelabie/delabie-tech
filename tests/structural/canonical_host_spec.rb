require_relative "spec_helper"
require "uri"

# No non-canonical host may appear in served output (canonical / og / hreflang
# / sitemap / JSON-LD / redirect targets must all use site.url's host).
#
# This guards the SEO-correctness invariant the Phase 8 cutover depends on:
# a stray hardcoded host (e.g. a www or v2 URL in a _data file flowing into
# JSON-LD) would declare a canonical that redirects away from the serving
# origin. Template-level — it scans built output, never names a page.
describe "canonical host (built site)" do
  HOST_SITE = ROOT / "_site"

  before(:all) do
    raise "Run `bundle exec jekyll build` first; _site/ missing." unless HOST_SITE.exist?
  end

  # Hosts that must NEVER appear in served files: the non-canonical delabie.tech
  # variants and the preview/dev hosts. (Bare `delabie.tech` host comparison is
  # substring-safe here because the only forbidden form sharing it is the www
  # subdomain, which we match explicitly.)
  FORBIDDEN_HOSTS = %w[www.delabie.tech v2.delabie.tech 0.0.0.0 127.0.0.1 localhost:].freeze

  it "configured site.url uses the apex canonical host" do
    config = YAML.safe_load_file(ROOT / "_config.yml", permitted_classes: [Date])
    expect(URI(config["url"]).host).to eq("delabie.tech")
  end

  it "no served HTML/XML/TXT references a non-canonical host" do
    violations = []
    Dir.glob(HOST_SITE / "**" / "*.{html,xml,txt}").each do |file|
      body = File.read(file)
      hits = FORBIDDEN_HOSTS.select { |h| body.include?(h) }
      next if hits.empty?
      rel = Pathname.new(file).relative_path_from(HOST_SITE).to_s
      violations << "#{rel}: #{hits.join(', ')}"
    end
    expect(violations).to be_empty, "Non-canonical host in served output:\n#{violations.join("\n")}"
  end
end
