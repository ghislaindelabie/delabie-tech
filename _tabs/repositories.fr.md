---
title: Dépôts
icon: fas fa-code-branch
order: 4
lang: fr
ref: repositories
permalink: /fr/repositories/
---

{%- assign page_lang = page.lang | default: site.lang -%}

<p class="lead">Le code que je maintiens ou auquel je contribue, groupé par contexte.</p>

{%- for section in site.data.repositories.sections -%}
  <section class="repos-section" data-test="repos-section" data-key="{{ section.key }}">
    <h2>{{ section.label[page_lang] | default: section.label.en }}</h2>
    {%- if section.blurb -%}
      <p class="repos-section__blurb">{{ section.blurb[page_lang] | default: section.blurb.en }}</p>
    {%- endif -%}
    <ul class="repo-list">
      {%- for repo in section.repos -%}
        {% include repo-card.html repo=repo %}
      {%- endfor -%}
    </ul>
  </section>
{%- endfor -%}
