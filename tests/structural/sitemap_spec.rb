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

  # Site config, loaded once. `Date`/`Time` are permitted because frontmatter
  # and defaults blocks carry them.
  def self.config
    @config ||= YAML.safe_load_file(ROOT / "_config.yml", permitted_classes: [Date, Time])
  end

  def config
    self.class.config
  end

  # ----------------------------------------------------------------------
  # Generic expected-URL derivation. Code review 2026-06: the previous
  # "lists every bilingual content surface" example only iterated
  # `_archive/*.md`, so the `tabs` collection (every nav page) could —
  # and did — silently fall out of the sitemap. We now derive the expected
  # URL set from the SAME source of truth the build uses: every output:true
  # collection declared in _config.yml (names + flags read, never
  # hardcoded) plus on-disk pages that declare a `permalink:`. Adding a
  # future collection or content file must not require touching this spec.
  # ----------------------------------------------------------------------

  # Resolve a source document's permalink the way Jekyll does for the
  # collections this site uses: an explicit frontmatter `permalink:` wins
  # (FR siblings always set one); otherwise the collection's permalink
  # template is filled from `:slug` and `:year` (EN docs rely on this).
  def self.permalink_for(fm, template)
    explicit = fm["permalink"]
    return explicit if explicit && !explicit.to_s.strip.empty?
    raise "no permalink template and no explicit permalink" unless template

    slug = fm["slug"]
    year = fm["date"] ? Date.parse(fm["date"].to_s).year.to_s : nil
    template
      .gsub(":slug", slug.to_s)
      .gsub(":year", year.to_s)
  end

  # Expected canonical content URLs the sitemap must list, keyed for
  # readable failure messages: { permalink => source_file }.
  def self.expected_urls
    @expected_urls ||= begin
      urls = {}

      # Output:true collections only — output:false collections (activity,
      # publications, teaching) are aggregated into pages and never routed
      # individually, so they have no own URL to list.
      config.fetch("collections", {}).each do |name, settings|
        next unless settings.is_a?(Hash) && settings["output"] == true

        template = settings["permalink"]
        # tabs have no per-collection permalink; their template lives in the
        # `defaults` block (path-scoped `type: tabs`). Read it from there so
        # this stays config-driven rather than hardcoded to `/:title/`.
        if template.nil?
          tab_default = config.fetch("defaults", []).find do |d|
            d.dig("scope", "type") == name
          end
          template = tab_default&.dig("values", "permalink")
        end

        Dir.glob(ROOT / "_#{name}" / "**" / "*.md").each do |src|
          fm = I18nPairs.frontmatter(src)
          next if fm["sitemap"] == false # honor the opt-out

          urls[permalink_for(fm, template)] = src
        end
      end

      # On-disk pages that declare a `permalink:` (home `index.html`,
      # standalone section indexes like `ia-mobilite/index.md`, and their
      # `/fr/` twins). Redirect stubs are NOT on disk — they are synthesised
      # by jekyll-redirect-from with `sitemap: false` — so globbing source
      # files inherently excludes them.
      page_globs = Dir.glob(ROOT / "**" / "index.html") + Dir.glob(ROOT / "**" / "index.md")
      page_globs.each do |src|
        rel = Pathname.new(src).relative_path_from(ROOT).to_s
        # Skip vendored/build/tooling trees — only first-party site sources.
        next if rel.start_with?("_site/", "vendor/", "node_modules/", "_tabs/")

        fm = I18nPairs.frontmatter(src)
        permalink = fm["permalink"]
        next if permalink.nil? || permalink.to_s.strip.empty?
        next if fm["sitemap"] == false

        urls[permalink] = src
      end

      urls
    end
  end

  it "is well-formed XML" do
    require "rexml/document"
    doc = REXML::Document.new(sitemap)
    expect(doc.root.name).to eq("urlset")
  end

  it "declares the xhtml namespace for hreflang" do
    expect(sitemap).to include('xmlns:xhtml="http://www.w3.org/1999/xhtml"')
  end

  it "lists every output:true collection doc and permalinked page, in both languages where a sibling exists" do
    # Derived generically from _config.yml + on-disk frontmatter (see
    # `expected_urls`). Code review 2026-06: this replaces the archive-only
    # check that let the `tabs` collection drop out of the sitemap. The FR
    # sibling of any bilingual surface carries its own `/fr/...` permalink,
    # so both languages are covered by the same derivation with no
    # language-specific branching.
    site_url = config["url"]
    missing = self.class.expected_urls.reject do |permalink, _src|
      locs.include?(site_url + permalink)
    end
    detail = missing.map { |permalink, src| "#{permalink}  (from #{src})" }
    expect(missing).to be_empty, "Content surfaces absent from sitemap:\n#{detail.join("\n")}"
  end

  it "lists the bilingual nav tabs (/about/, /cv/, ...) in EN and FR" do
    # Explicit guard for the exact regression code review 2026-06 found:
    # the `tabs` collection was never concatenated into the sitemap's URL
    # set, so zero nav pages shipped. Kept alongside the generic check as a
    # named tripwire that names the surface it protects.
    site_url = config["url"]
    %w[about cv publications teaching contact case-studies archive repositories writing].each do |slug|
      expect(locs).to include("#{site_url}/#{slug}/"), "missing EN tab /#{slug}/"
      expect(locs).to include("#{site_url}/fr/#{slug}/"), "missing FR tab /fr/#{slug}/"
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

  it "no <lastmod> equals the build moment (site.time) — only explicit frontmatter dates" do
    # Code review 2026-06: Jekyll::Document#date defaults to site.time for
    # docs without a `date` key, so case studies (which carry `date_start`,
    # not `date`) were emitting a lastmod equal to the build moment —
    # rewritten every deploy, a meaningless freshness signal. A correct
    # sitemap emits lastmod ONLY from an explicit frontmatter date; no
    # lastmod may match the build's site.time.
    build_iso = config["time"] ? config["time"].to_s : nil
    lastmods = sitemap.scan(%r{<lastmod>([^<]+)</lastmod>}).flatten

    # The build moment isn't pinned in _config.yml, so derive the forbidden
    # value from jekyll-sitemap's default page (every page jekyll-sitemap
    # would stamp with site.time). The robust invariant: every lastmod must
    # parse to a real date AND fall on the calendar day of a frontmatter
    # `date` somewhere in the source — never the build's wall-clock instant.
    explicit_days = explicit_frontmatter_days
    offenders = lastmods.reject do |lm|
      day = Date.parse(lm).strftime("%Y-%m-%d")
      explicit_days.include?(day)
    end
    expect(offenders).to be_empty,
      "These <lastmod> values do not correspond to any explicit frontmatter date " \
      "(likely the build's site.time, the bug code review 2026-06 found):\n#{offenders.uniq.join("\n")}"
  end

  it "no case-study <loc> carries a <lastmod> (case studies have date_start, not date)" do
    # Direct assertion of the finding: case studies must omit lastmod
    # entirely (a bare `date_start` year is not a meaningful lastmod),
    # rather than inherit site.time.
    blocks = sitemap.scan(%r{<url>(.*?)</url>}m).flatten
    offenders = blocks.select do |block|
      loc = block[%r{<loc>([^<]+)</loc>}, 1]
      loc&.match?(%r{/case-studies/[^/]+/$}) && block.include?("<lastmod>")
    end.map { |b| b[%r{<loc>([^<]+)</loc>}, 1] }
    expect(offenders).to be_empty, "Case-study locs must not emit lastmod:\n#{offenders.join("\n")}"
  end

  it "asset URLs (CSS, JS, JSON, images, manifest) are excluded" do
    excluded_extensions = %w[.css .js .json .png .jpg .svg .ico .webmanifest]
    leaks = locs.select do |loc|
      excluded_extensions.any? { |ext| loc.end_with?(ext) }
    end
    expect(leaks).to be_empty, "Asset URL leaks in sitemap:\n#{leaks.join("\n")}"
  end

  it "redirect stubs are excluded (sitemap: false opt-out is honored)" do
    # jekyll-redirect-from stamps every stub with `sitemap: false`; the
    # custom sitemap skips those. Assert no known legacy path leaks in.
    %w[/blog/ /projects/ /projects/mob/ /ia-mobilite/guide-mistral-vibe/].each do |stub|
      expect(locs).not_to include(config["url"] + stub), "redirect stub #{stub} leaked into sitemap"
    end
  end

  it "every `<loc>` URL ends with a trailing slash (canonical content path)" do
    non_slashed = locs.reject { |l| l.end_with?("/") }
    expect(non_slashed).to be_empty, "Non-canonical sitemap entries:\n#{non_slashed.join("\n")}"
  end

  it "every `<loc>` is absolute (https://) and points at the configured site URL" do
    site_url = config["url"]
    bad = locs.reject { |l| l.start_with?(site_url + "/") }
    expect(bad).to be_empty, "Non-absolute sitemap entries:\n#{bad.join("\n")}"
  end

  # Collect every explicit `date:` value declared in source frontmatter,
  # as YYYY-MM-DD strings. A legitimate <lastmod> must fall on one of these
  # days; the build moment (site.time) will not.
  def explicit_frontmatter_days
    days = []
    %w[_posts _archive].each do |dir|
      Dir.glob(ROOT / dir / "**" / "*.md").each do |src|
        fm = I18nPairs.frontmatter(src)
        next unless fm["date"]
        days << Date.parse(fm["date"].to_s).strftime("%Y-%m-%d")
      end
    end
    days.uniq
  end
end
