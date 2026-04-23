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
# The filter returns a small hash (not the full Document) so Liquid templates
# treat every translation as the same shape — url, title, lang — regardless
# of whether the translation is a Document or a Page. [REVIEW-5 @ 07:01]:
# if a template needs additional fields later, extend the hash deliberately
# rather than exposing Jekyll internals.
#
# Performance: the translations index is built once per site build and
# reused. Cuts hreflang + switcher rendering from O(P) per call to O(1).

module Jekyll
  module I18nFilters
    def translation_of(page_obj, target_lang)
      return nil if page_obj.nil?
      ref = page_obj["ref"]
      return nil if ref.nil? || ref.to_s.strip.empty?

      site = @context.registers[:site]
      index = Jekyll::I18nFilters.translations_index(site)

      # Case-insensitive + whitespace-tolerant lookup. Stray capitalization
      # or trailing whitespace in frontmatter should not silently skip the
      # match. Addresses [REVIEW-25].
      match = index.dig(ref.to_s.strip.downcase, target_lang.to_s.strip.downcase)
      return nil unless match

      { "url" => match.url, "title" => match.data["title"], "lang" => match.data["lang"] }
    end

    # Memoized {ref => {lang => Document|Page}} index.
    #
    # Cache key is the site's build signature, not site.object_id. Ruby can
    # re-use an object_id after GC, so two different site objects could
    # collide and silently return a stale index.
    # Addresses [REVIEW-18] / [REVIEW-6 @ 07:01].
    def self.translations_index(site)
      sig = signature(site)
      @cached_index = nil if @cached_signature != sig
      @cached_index ||= build_index(site)
      @cached_signature = sig
      @cached_index
    end

    # Build signature robust across rebuilds. Any change to counts, source
    # path, or build time rebuilds the index.
    def self.signature(site)
      time = site.respond_to?(:time) ? site.time.to_i : 0
      [site.source, site.documents.size, site.pages.size, time].join("|")
    end

    def self.build_index(site)
      idx = Hash.new { |h, k| h[k] = {} }
      (site.documents + site.pages).each do |item|
        ref  = item.data["ref"]
        lang = item.data["lang"]
        next if ref.nil? || ref.to_s.strip.empty?
        next if lang.nil? || lang.to_s.strip.empty?
        idx[ref.to_s.strip.downcase][lang.to_s.strip.downcase] = item
      end
      idx
    end
  end
end

Liquid::Template.register_filter(Jekyll::I18nFilters)
