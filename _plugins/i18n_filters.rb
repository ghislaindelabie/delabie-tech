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
# and a different `lang`. Posts, collections, and static pages are all
# searched.

module Jekyll
  module I18nFilters
    # `page` in Liquid context is typically a Drop (DocumentDrop / PageDrop /
    # UnifiedPayloadDrop). Drops respond to [] for frontmatter keys. We accept
    # anything that duck-types that way, plus raw Hashes for tests.
    def translation_of(page_obj, target_lang)
      site = @context.registers[:site]
      ref = frontmatter_value(page_obj, "ref")
      return nil if ref.nil? || ref.to_s.empty?
      target_lang = target_lang.to_s

      doc = site.documents.find do |d|
        d.data["ref"].to_s == ref.to_s && d.data["lang"].to_s == target_lang
      end
      return { "url" => doc.url, "title" => doc.data["title"], "lang" => doc.data["lang"] } if doc

      pg = site.pages.find do |p|
        p.data["ref"].to_s == ref.to_s && p.data["lang"].to_s == target_lang
      end
      return { "url" => pg.url, "title" => pg.data["title"], "lang" => pg.data["lang"] } if pg

      nil
    end

    private

    def frontmatter_value(obj, key)
      if obj.respond_to?(:[])
        obj[key] || (obj.respond_to?(:key?) && obj.key?(key.to_sym) ? obj[key.to_sym] : nil)
      elsif obj.respond_to?(:data)
        obj.data[key]
      end
    end
  end
end

Liquid::Template.register_filter(Jekyll::I18nFilters)
