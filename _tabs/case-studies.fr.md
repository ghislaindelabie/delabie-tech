---
title: Études de cas
icon: fas fa-folder-open
order: 2
lang: fr
ref: case-studies
permalink: /fr/case-studies/
---

{%- assign page_lang = page.lang | default: site.lang -%}
{%- assign strings = site.data.i18n.strings[page_lang] -%}
{%- assign items = site.case_studies | where: "lang", page_lang | sort: "date_start" | reverse -%}

<p class="lead">{{ strings.case_studies_intro }}</p>

<ul class="case-studies-grid" data-test="case-studies-grid">
{%- for cs in items -%}
  <li class="case-study-card" data-test="case-study-card" data-category="{{ cs.category }}">
    <div class="case-study-card__meta">
      {%- if cs.category -%}<span class="case-study-card__category">{{ cs.category }}</span>{%- endif -%}
      {%- if cs.date_start -%}
        <span class="case-study-card__dates">
          {{ cs.date_start }}{% if cs.date_end %}–{{ cs.date_end }}{% elsif cs.ongoing %} →{% endif %}
        </span>
      {%- endif -%}
    </div>
    <h2 class="case-study-card__title"><a href="{{ cs.url | relative_url }}">{{ cs.title }}</a></h2>
    {%- if cs.summary -%}<p class="case-study-card__summary">{{ cs.summary }}</p>{%- endif -%}
  </li>
{%- endfor -%}
</ul>
