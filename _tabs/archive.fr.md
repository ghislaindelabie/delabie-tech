---
title: Archive
icon: fas fa-archive
order: 8
lang: fr
ref: archive
permalink: /fr/archive/
---

{%- assign page_lang = page.lang | default: site.lang -%}
{%- assign strings = site.data.i18n.strings[page_lang] | default: site.data.i18n.strings[site.lang] -%}
{%- assign items = site.archive | where: 'lang', page_lang | sort: 'date' | reverse -%}

<p class="lead">{{ strings.archive_intro }}</p>

{%- if items.size == 0 -%}

  <p>—</p>

{%- else -%}

<div data-filter-list>

  {% include archive-filters.html lang="fr" items=items %}

  <ul class="archive-list" data-filter-items data-test="archive-list">
  {%- for item in items -%}
    {% include archive-row.html item=item strings=strings %}
  {%- endfor -%}
  </ul>

  <p class="list-empty" data-filter-empty data-test="archive-empty" hidden>{{ strings.archive_filter_empty }}</p>

</div>

<script src="{{ '/assets/js/filter-list.js' | relative_url }}" defer></script>

{%- endif -%}
