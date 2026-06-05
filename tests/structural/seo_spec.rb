require_relative "spec_helper"
require "json"

# SEO invariants on the BUILT site. OG tags, JSON-LD, canonical, hreflang.
# These run after `jekyll build` — same gate as `rendered_html_spec.rb`.

describe "SEO invariants (built site)" do
  SEO_SITE = ROOT / "_site"

  before(:all) do
    raise "Run `bundle exec jekyll build` first; _site/ missing." unless SEO_SITE.exist?
  end

  # ---- Open Graph + Twitter card -------------------------------------

  # jekyll-seo-tag (shipped with Chirpy) emits OG + Twitter automatically.
  # Verify it actually fires on every content page, both languages.
  # jekyll-redirect-from stubs are bare meta-refresh pages, not content —
  # the OG / Twitter-card invariants don't apply to them.
  def redirect_stub?(html)
    html.include?('http-equiv="refresh"')
  end

  it "every content page emits og:title, og:description, og:type, og:url" do
    required = %w[og:title og:description og:type og:url]
    violations = []
    Dir.glob(SEO_SITE / "**" / "index.html").each do |file|
      html = File.read(file)
      next if redirect_stub?(html)
      missing = required.reject { |prop| html.include?(%(property="#{prop}")) }
      next if missing.empty?
      rel = Pathname.new(file).relative_path_from(SEO_SITE).to_s
      violations << "#{rel}: missing OG props #{missing.inspect}"
    end
    expect(violations).to be_empty, "OG-tag gaps:\n#{violations.join("\n")}"
  end

  it "every content page emits a Twitter card meta tag" do
    violations = []
    Dir.glob(SEO_SITE / "**" / "index.html").each do |file|
      html = File.read(file)
      next if redirect_stub?(html)
      next if html.match?(/<meta\s+name=["']twitter:card["']/i)
      rel = Pathname.new(file).relative_path_from(SEO_SITE).to_s
      violations << rel
    end
    expect(violations).to be_empty, "Pages without twitter:card:\n#{violations.join("\n")}"
  end

  # ---- Schema.org Person -----------------------------------------------

  # A single Person JSON-LD block identifies Ghislain; organisations are
  # inline relationships on the Person (worksFor / memberOf / affiliation),
  # never standalone Organization entities — see metadata-hook.html and
  # docs/phase-5-refinements.md §2. Search engines use these to consolidate
  # author / employer signals — but only when emitted on identity-rooted
  # pages (home + About). Emitting on every page is treated as spam.

  def jsonld_blocks(file)
    File.read(file).scan(%r{<script\s+type="application/ld\+json"[^>]*>(.*?)</script>}m).flatten
  end

  def jsonld_types(file)
    jsonld_blocks(file).map do |raw|
      JSON.parse(raw)["@type"]
    rescue JSON::ParserError
      nil
    end.compact
  end

  def person_block(file)
    jsonld_blocks(file).map { |b| JSON.parse(b) rescue nil }.compact.find { |b| b["@type"] == "Person" }
  end

  it "home page emits Person JSON-LD with a nested worksFor Organization (EN + FR)" do
    %w[index.html fr/index.html].each do |path|
      person = person_block(SEO_SITE / path)
      expect(person).not_to be_nil, "#{path}: no Person JSON-LD"
      expect(person.dig("worksFor", "@type")).to eq("Organization"),
        "#{path}: Person.worksFor is not a nested Organization (got #{person["worksFor"].inspect})"
    end
  end

  it "About page emits Person JSON-LD with a nested worksFor Organization (EN + FR)" do
    %w[about/index.html fr/about/index.html].each do |path|
      person = person_block(SEO_SITE / path)
      expect(person).not_to be_nil, "#{path}: no Person JSON-LD"
      expect(person.dig("worksFor", "@type")).to eq("Organization"),
        "#{path}: Person.worksFor is not a nested Organization (got #{person["worksFor"].inspect})"
    end
  end

  it "no page emits a standalone top-level Organization JSON-LD block" do
    # Design invariant (docs/phase-5-refinements.md §2): organisations are
    # declared inline on the Person, never as top-level entities.
    violations = []
    Dir.glob(SEO_SITE / "**" / "index.html").each do |file|
      next unless jsonld_types(file).include?("Organization")
      violations << Pathname.new(file).relative_path_from(SEO_SITE).to_s
    end
    expect(violations).to be_empty, "Standalone Organization JSON-LD:\n#{violations.join("\n")}"
  end

  it "non-identity pages do NOT emit Person JSON-LD" do
    # Identity blocks belong on home + About only. Repeating them on every
    # page is treated as duplicate-entity spam by Google.
    violations = []
    Dir.glob(SEO_SITE / "**" / "index.html").each do |file|
      rel = Pathname.new(file).relative_path_from(SEO_SITE).to_s
      next if rel == "index.html" || rel == "fr/index.html"
      next if rel == "about/index.html" || rel == "fr/about/index.html"
      types = jsonld_types(file)
      violations << "#{rel}: leaks Person JSON-LD" if types.include?("Person")
    end
    expect(violations).to be_empty, "Person JSON-LD leaks:\n#{violations.join("\n")}"
  end

  # ---- Person sameAs --------------------------------------------------

  it "home page Person.sameAs includes the strong-include profile URLs" do
    blocks = jsonld_blocks(SEO_SITE / "index.html")
    person = blocks.map { |b| JSON.parse(b) rescue nil }.compact.find { |b| b["@type"] == "Person" }
    expect(person).not_to be_nil, "no Person JSON-LD on home"
    expected = %w[
      https://www.linkedin.com/in/ghislaindelabie/
      https://github.com/ghislaindelabie
      https://medium.com/@ghislaindelabie
    ]
    missing = expected - (person["sameAs"] || [])
    expect(missing).to be_empty, "Person.sameAs missing: #{missing}"
  end

  # ---- Per-archive-item JSON-LD --------------------------------------

  # Mapping must match the case statement in `_includes/archive-jsonld.html`.
  ARCHIVE_TYPE_TO_JSONLD = {
    "article"   => "NewsArticle",
    "oped"      => "NewsArticle",
    "quoted"    => "NewsArticle",
    "interview" => "InterviewObject",
    "report"    => "ScholarlyArticle",
    "talk"      => "PresentationDigitalDocument",
    "video"     => "VideoObject",
    "podcast"   => "PodcastEpisode",
  }.freeze

  it "every archive item emits Schema.org JSON-LD typed per `type` field" do
    archive_dir = ROOT / "_archive"
    violations = []
    Dir.glob(archive_dir / "*.md").each do |src|
      fm = I18nPairs.frontmatter(src)
      slug = fm["slug"] || File.basename(src, ".md").chomp(".fr")
      year = Date.parse(fm["date"].to_s).year
      lang_prefix = fm["lang"] == "fr" ? "fr/" : ""
      built = SEO_SITE / "#{lang_prefix}archive" / year.to_s / slug / "index.html"
      unless built.exist?
        violations << "#{File.basename(src)}: expected #{built.relative_path_from(SEO_SITE)} to exist"
        next
      end
      types = jsonld_types(built)
      expected = ARCHIVE_TYPE_TO_JSONLD[fm["type"]]
      unless types.include?(expected)
        rel = built.relative_path_from(SEO_SITE).to_s
        violations << "#{rel}: expected JSON-LD @type=#{expected.inspect} (item type=#{fm["type"].inspect}), got #{types.inspect}"
      end
    end
    expect(violations).to be_empty, "Archive JSON-LD type mismatches:\n#{violations.join("\n")}"
  end

  it "archive items do not also emit jekyll-seo-tag's generic BlogPosting block" do
    # head.html strips seo-tag's JSON-LD on archive_item pages so each item
    # declares exactly one entity type — two competing @type declarations
    # for one URL confuse structured-data consumers.
    violations = []
    # Items render at [fr/]archive/:year/:slug/ — the two-level glob skips
    # the archive index tabs, which legitimately keep seo-tag's JSON-LD.
    Dir.glob(SEO_SITE / "**" / "archive" / "*" / "*" / "index.html").each do |file|
      types = jsonld_types(file)
      next unless types.include?("BlogPosting")
      violations << Pathname.new(file).relative_path_from(SEO_SITE).to_s
    end
    expect(violations).to be_empty, "Archive items leaking BlogPosting JSON-LD:\n#{violations.join("\n")}"
  end

  # ---- Person + Organization JSON-LD must be valid JSON --------------

  it "every JSON-LD block parses as valid JSON" do
    violations = []
    Dir.glob(SEO_SITE / "**" / "index.html").each do |file|
      jsonld_blocks(file).each_with_index do |raw, i|
        begin
          JSON.parse(raw)
        rescue JSON::ParserError => e
          rel = Pathname.new(file).relative_path_from(SEO_SITE).to_s
          violations << "#{rel}: block ##{i + 1} invalid JSON — #{e.message}"
        end
      end
    end
    expect(violations).to be_empty, "Invalid JSON-LD:\n#{violations.join("\n")}"
  end
end
