---
title: Teaching
icon: fas fa-chalkboard-teacher
order: 5
lang: en
ref: teaching
permalink: /teaching/
---

{%- assign page_lang = page.lang | default: site.lang -%}
{%- assign items = site.teaching | where: 'lang', page_lang -%}

<p class="lead">Courses and workshops I teach or have taught, grouped by institution.</p>

<ul class="teaching-list">
{%- for t in items -%}
  {% include teaching-item.html t=t %}
{%- endfor -%}
</ul>
