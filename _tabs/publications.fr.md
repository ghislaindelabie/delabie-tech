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

<p class="lead">Rapports, conférences, webinaires, interviews — travaux produits ou co-produits.</p>

<ul class="publications-list">
{%- for pub in items -%}
  {% include publication-item.html pub=pub %}
{%- endfor -%}
</ul>
