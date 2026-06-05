require_relative "spec_helper"

# Redirect-stub invariants (Phase 6 — legacy URL preservation).
#
# Template-level: the spec discovers every `redirect_from:` declared in
# source frontmatter (pages + output collections) and asserts the built
# stub exists and points at the declaring page. Adding or removing a
# redirect is a pure content operation — this file never changes.
describe "redirect stubs (built site)" do
  REDIRECTS_SITE = ROOT / "_site"

  # {legacy_path => destination_permalink} from source frontmatter.
  def declared_redirects
    pairs = {}
    sources = Dir.glob(ROOT / "_tabs" / "*.md") +
              Dir.glob(ROOT / "_case_studies" / "*.md") +
              Dir.glob(ROOT / "_archive" / "*.md") +
              Dir.glob(ROOT / "*" / "index.md")
    sources.each do |src|
      fm = I18nPairs.frontmatter(src)
      froms = Array(fm["redirect_from"])
      next if froms.empty?
      dest = fm["permalink"]
      dest ||= "/case-studies/#{fm["slug"]}/" if src.include?("_case_studies")
      raise "#{src}: redirect_from needs a resolvable destination" unless dest
      froms.each { |from| pairs[from] = dest }
    end
    pairs
  end

  before(:all) do
    raise "Run `bundle exec jekyll build` first; _site/ missing." unless REDIRECTS_SITE.exist?
  end

  it "declares at least one redirect (sanity: discovery is wired)" do
    expect(declared_redirects).not_to be_empty
  end

  it "every declared redirect_from produces a stub at the legacy path" do
    violations = []
    declared_redirects.each_key do |from|
      stub = REDIRECTS_SITE / from.sub(%r{\A/}, "") / "index.html"
      violations << "#{from}: no stub at #{stub}" unless stub.exist?
    end
    expect(violations).to be_empty, violations.join("\n")
  end

  it "every stub meta-refreshes AND canonicalises to its declared destination" do
    violations = []
    declared_redirects.each do |from, dest|
      stub = REDIRECTS_SITE / from.sub(%r{\A/}, "") / "index.html"
      next unless stub.exist? # covered by the previous example
      html = File.read(stub)
      unless html.match?(/http-equiv="refresh"[^>]*url=[^"]*#{Regexp.escape(dest)}/)
        violations << "#{from}: meta refresh does not target #{dest}"
      end
      unless html.match?(/rel="canonical"[^>]*href="[^"]*#{Regexp.escape(dest)}"/)
        violations << "#{from}: canonical does not target #{dest}"
      end
    end
    expect(violations).to be_empty, violations.join("\n")
  end

  it "no stub shadows a real content page (legacy path must not collide)" do
    violations = []
    declared_redirects.each_key do |from|
      stub = REDIRECTS_SITE / from.sub(%r{\A/}, "") / "index.html"
      next unless stub.exist?
      html = File.read(stub)
      violations << "#{from}: looks like a full page, not a stub" unless html.include?('http-equiv="refresh"')
    end
    expect(violations).to be_empty, violations.join("\n")
  end
end
