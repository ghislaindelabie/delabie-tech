---
title: Publications
icon: fas fa-book
order: 4
lang: en
ref: publications
permalink: /publications/
---

{%- assign page_lang = page.lang | default: site.lang -%}
{%- assign items = site.publications | where: 'lang', page_lang | sort: 'date' | reverse -%}

<p class="lead">Reports, talks and webinars I've produced or co-produced. Filter by theme or format — all filters are optional, and combining them narrows the list.</p>

<div data-filter-list>

  {% include publication-filters.html lang="en" %}

  <ul class="publications-list" data-filter-items data-test="publications-list">
  {%- for pub in items -%}
    {% include publication-item.html pub=pub %}
  {%- endfor -%}
  </ul>

  <p class="list-empty" data-filter-empty data-test="publications-empty" hidden>{{ site.data.i18n.strings.en.publications_filter_empty }}</p>

</div>

<script src="{{ '/assets/js/filter-list.js' | relative_url }}" defer></script>
