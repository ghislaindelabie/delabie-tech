require_relative "spec_helper"
require "nokogiri"

# Template-level invariants for the filtered list pages (/publications/,
# /teaching/, /archive/) in both languages. Operates over the BUILT site so
# the assertions exercise the real rendered Liquid, not the source. Adding or
# retagging content must never require editing this file — every expectation
# is derived from the live DOM (and, for teaching links, from the content
# files), never hardcoded.

describe "rendered list-page invariants" do
  # `SITE` is defined once at top-level by rendered_html_spec.rb; reuse it when
  # present so the constant isn't redefined (avoids a load-order warning).
  SITE = ROOT / "_site" unless defined?(SITE)

  before(:all) do
    raise "Run `bundle exec jekyll build` first; _site/ missing." unless SITE.exist?
  end

  # Page → which item attribute each filter axis reads. The DOM contract
  # (assets/js/filter-list.js): a pill in `[data-group=X]` filters on the
  # item's `data-X` attribute; `themes`/`type`/`tags` hold space-separated
  # lists, `format` a single token.
  LIST_PAGES = {
    "publications" => { en: "publications", fr: "fr/publications" },
    "teaching"     => { en: "teaching",     fr: "fr/teaching" },
    "archive"      => { en: "archive",      fr: "fr/archive" },
  }.freeze

  def doc_for(rel_dir)
    path = SITE / rel_dir / "index.html"
    return nil unless path.exist?
    Nokogiri::HTML(File.read(path))
  end

  # [code review 2026-06 #8]: a filter pill must never be "dead" — clicking it
  # must narrow to ≥1 item, never an empty list. For every pill rendered on a
  # built page, at least one rendered item on that same page must carry the
  # pill's value under the axis the pill belongs to.
  describe "no dead filter pills (#8)" do
    LIST_PAGES.each do |label, langs|
      langs.each do |lang, rel_dir|
        it "#{label} (#{lang}): every filter pill matches ≥1 rendered item" do
          doc = doc_for(rel_dir)
          skip "#{rel_dir} not built" if doc.nil?

          controls = doc.at_css("[data-filter-controls]")
          skip "no filter controls on #{rel_dir} (page may be empty)" if controls.nil?

          item_values = Hash.new { |h, k| h[k] = [] }
          doc.css("[data-filter-item]").each do |item|
            %w[themes format type tags].each do |axis|
              raw = item["data-#{axis}"].to_s
              item_values[axis].concat(raw.split(/\s+/).reject(&:empty?))
            end
          end

          dead = []
          controls.css("[data-group]").each do |group|
            axis = group["data-group"]
            group.css(".filter-pill").each do |pill|
              value = pill["data-filter"].to_s
              next if value.empty?
              unless item_values[axis].include?(value)
                dead << "#{rel_dir}: pill data-group=#{axis} data-filter=#{value.inspect} matches no rendered item"
              end
            end
          end
          expect(dead).to be_empty, "Dead filter pills:\n#{dead.join("\n")}"
        end
      end
    end
  end

  # [code review 2026-06 #7]: every link declared on a teaching item must
  # actually render as an anchor on the built page for that item's language.
  # The teaching template historically only honored external_url/pdf/slides/
  # video_url and silently dropped source_url (the field 4 entries use).
  describe "teaching item links render (#7)" do
    TEACHING_LINK_FIELDS = %w[source_url external_url pdf slides video_url].freeze

    # Returns the set of href values present on the built teaching page for a lang.
    def teaching_hrefs(rel_dir)
      doc = doc_for(rel_dir)
      return [] if doc.nil?
      doc.css('[data-test="teaching-item"] a[href]').map { |a| a["href"] }
    end

    it "every link field on a _teaching doc appears as an anchor on the built page" do
      en_hrefs = teaching_hrefs("teaching")
      fr_hrefs = teaching_hrefs("fr/teaching")
      missing = []

      Dir.glob(I18nPairs::ROOT / "_teaching" / "*.md").each do |file|
        fm = I18nPairs.frontmatter(file)
        rel = Pathname.new(file).relative_path_from(I18nPairs::ROOT).to_s
        hrefs = file.end_with?(".fr.md") ? fr_hrefs : en_hrefs
        TEACHING_LINK_FIELDS.each do |field|
          val = fm[field].to_s
          next if val.empty?
          # pdf/slides are site-relative and go through `relative_url`; match by suffix.
          present = if %w[pdf slides].include?(field)
                      hrefs.any? { |h| h.end_with?(val) || h == val }
                    else
                      hrefs.include?(val)
                    end
          missing << "#{rel}: #{field}=#{val.inspect} not rendered as an anchor" unless present
        end
      end
      expect(missing).to be_empty, "Teaching link fields not rendered:\n#{missing.join("\n")}"
    end
  end
end
