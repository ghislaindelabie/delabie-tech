---
title: Publications
icon: fas fa-book
order: 4
lang: fr
ref: publications
permalink: /fr/publications/
---

{%- assign page_lang = page.lang | default: site.lang -%}
{%- assign items = site.publications | where: 'lang', page_lang | sort: 'date' | reverse -%}

<p class="lead">Rapports, conférences et webinaires produits ou co-produits. Filtrez par thème ou par format — tous les filtres sont optionnels, et les combiner resserre la liste.</p>

<div data-filter-list>

  {% include publication-filters.html lang="fr" %}

  <ul class="publications-list" data-filter-items data-test="publications-list">
  {%- for pub in items -%}
    {% include publication-item.html pub=pub %}
  {%- endfor -%}
  </ul>

  <p class="list-empty" data-filter-empty data-test="publications-empty" hidden>{{ site.data.i18n.strings.fr.publications_filter_empty }}</p>

</div>

<script src="{{ '/assets/js/filter-list.js' | relative_url }}" defer></script>
