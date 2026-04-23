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

<p class="lead">Reports, talks, webinars, interviews — work I've produced or co-produced.</p>

<ul class="publications-list">
{%- for pub in items -%}
  {% include publication-item.html pub=pub %}
{%- endfor -%}
</ul>
