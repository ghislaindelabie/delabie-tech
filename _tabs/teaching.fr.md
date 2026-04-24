---
title: Enseignement
icon: fas fa-chalkboard-teacher
order: 5
lang: fr
ref: teaching
permalink: /fr/teaching/
---

{%- assign page_lang = page.lang | default: site.lang -%}
{%- comment -%}
  Tri sur la clef composite `sort_key` (= year_end * 10000 + year_start)
  puis `reverse`. Un seul sort sur un scalaire évite le comportement
  instable des tris chaînés en Liquid. Résultat : year_end le plus
  récent en tête ; à year_end égal, l'engagement démarré le plus
  récemment gagne.
{%- endcomment -%}
{%- assign items = site.teaching | where: 'lang', page_lang | sort: 'sort_key' | reverse -%}

<p class="lead">Cours, ateliers et programmes sur-mesure que j'ai animés ou que j'anime. Filtrez par thème ou par format — tous les filtres sont optionnels, et les combiner resserre la liste.</p>

<div data-filter-list>

  {% include teaching-filters.html lang="fr" %}

  <ul class="teaching-list" data-filter-items data-test="teaching-list">
  {%- for t in items -%}
    {% include teaching-item.html t=t %}
  {%- endfor -%}
  </ul>

  <p class="list-empty" data-filter-empty data-test="teaching-empty" hidden>{{ site.data.i18n.strings.fr.teaching_filter_empty }}</p>

</div>

<script src="{{ '/assets/js/filter-list.js' | relative_url }}" defer></script>
