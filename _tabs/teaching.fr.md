---
title: Enseignement
icon: fas fa-chalkboard-teacher
order: 5
lang: fr
ref: teaching
permalink: /fr/teaching/
---

{%- assign page_lang = page.lang | default: site.lang -%}
{%- assign items = site.teaching | where: 'lang', page_lang | sort: 'year_end' | reverse -%}

<p class="lead">Cours, ateliers et programmes sur-mesure que j'ai animés ou que j'anime. Filtrez par thème ou par format — tous les filtres sont optionnels, et les combiner resserre la liste.</p>

{% include teaching-filters.html lang="fr" %}

<ul class="teaching-list" data-test="teaching-list">
{%- for t in items -%}
  {% include teaching-item.html t=t %}
{%- endfor -%}
</ul>

<script src="{{ '/assets/js/teaching-filters.js' | relative_url }}" defer></script>
