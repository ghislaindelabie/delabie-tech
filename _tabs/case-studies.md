---
title: Case studies
icon: fas fa-folder-open
order: 2
lang: en
ref: case-studies
permalink: /case-studies/
---

{%- assign page_lang = page.lang | default: site.lang -%}
{%- assign strings = site.data.i18n.strings[page_lang] -%}
{%- assign items = site.case_studies | where: "lang", page_lang | sort: "date_start" | reverse -%}

<p class="lead">{{ strings.case_studies_intro }}</p>

<ul class="case-studies-grid" data-test="case-studies-grid">
{%- for cs in items -%}
  {% include case-study-card.html cs=cs %}
{%- endfor -%}
</ul>
