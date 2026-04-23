# frozen_string_literal: true

# Custom bilingual support for delabie-tech — no Polyglot plugin.
# See CHIRPY_MIGRATION_PLAN.md §2.
#
# Usage in Liquid:
#
#   {% assign alt = page | translation_of: "fr" %}
#   {% if alt %}
#     <a href="{{ alt.url | relative_url }}">...</a>
#   {% endif %}
#
# A "translation" is a document/page with the same frontmatter `ref`
# and a different `lang`.
#
# Performance: the translations index is built once per site (per build) and
# reused across every call. Cuts hreflang + switcher rendering from O(P) per
# call to O(1). Matters as content collections grow.

module Jekyll
  module I18nFilters
    def translation_of(page_obj, target_lang)
      return nil if page_obj.nil?
      ref = page_obj["ref"]
      return nil if ref.nil? || ref.to_s.empty?

      site = @context.registers[:site]
      index = Jekyll::I18nFilters.translations_index(site)
      match = index.dig(ref.to_s, target_lang.to_s)
      return nil unless match

      { "url" => match.url, "title" => match.data["title"], "lang" => match.data["lang"] }
    end

    # Memoized {ref => {lang => Document_or_Page}} index.
    # Recomputed when a fresh site object arrives (handles jekyll serve).
    def self.translations_index(site)
      @cached_site_id ||= nil
      if @cached_site_id != site.object_id
        @cached_index = build_index(site)
        @cached_site_id = site.object_id
      end
      @cached_index
    end

    def self.build_index(site)
      idx = Hash.new { |h, k| h[k] = {} }
      (site.documents + site.pages).each do |item|
        ref  = item.data["ref"]
        lang = item.data["lang"]
        next if ref.nil? || ref.to_s.empty? || lang.nil? || lang.to_s.empty?
        idx[ref.to_s][lang.to_s] = item
      end
      idx
    end
  end
end

Liquid::Template.register_filter(Jekyll::I18nFilters)
