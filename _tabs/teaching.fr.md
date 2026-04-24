---
title: Enseignement
icon: fas fa-chalkboard-teacher
order: 5
lang: fr
ref: teaching
permalink: /fr/teaching/
---

{%- assign page_lang = page.lang | default: site.lang -%}
{%- assign items = site.teaching | where: 'lang', page_lang -%}

<p class="lead">Cours et ateliers que j'enseigne ou que j'ai enseignés, groupés par institution.</p>

<ul class="teaching-list">
{%- for t in items -%}
  {% include teaching-item.html t=t %}
{%- endfor -%}
</ul>
