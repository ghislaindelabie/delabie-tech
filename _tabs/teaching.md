---
title: Teaching
icon: fas fa-chalkboard-teacher
order: 5
lang: en
ref: teaching
permalink: /teaching/
---

{%- assign page_lang = page.lang | default: site.lang -%}
{%- assign items = site.teaching | where: 'lang', page_lang | sort: 'year_end' | reverse -%}

<p class="lead">Courses, workshops and custom programs I teach or have taught. Filter by theme or format — all filters are optional, and combining them narrows the list.</p>

{% include teaching-filters.html lang="en" %}

<ul class="teaching-list" data-test="teaching-list">
{%- for t in items -%}
  {% include teaching-item.html t=t %}
{%- endfor -%}
</ul>

<script src="{{ '/assets/js/teaching-filters.js' | relative_url }}" defer></script>
