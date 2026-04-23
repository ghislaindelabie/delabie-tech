---
title: Articles
icon: fas fa-pen-nib
order: 3
lang: fr
ref: writing
permalink: /fr/writing/
---

{%- assign page_lang = page.lang | default: site.lang -%}
{%- assign lang_posts = site.posts | where: 'lang', page_lang | where_exp: 'p', 'p.hidden != true' -%}

{%- if lang_posts.size == 0 -%}

Rien de publié ici pour l'instant. Le cadre pour les articles est en place ; les posts arriveront progressivement depuis le [projet de migration du blog]({{ '/fr/about/' | relative_url }}) après relecture éditoriale. En attendant, les [études de cas]({{ '/fr/case-studies/' | relative_url }}) offrent des travaux plus développés.

{%- else -%}
<ul class="writing-list">
  {%- for post in lang_posts -%}
    <li class="writing-list__item">
      <time datetime="{{ post.date | date: '%Y-%m-%d' }}">{{ post.date | date: '%Y-%m-%d' }}</time>
      <a href="{{ post.url | relative_url }}">{{ post.title | default: post.name | default: post.url }}</a>
      {%- if post.description -%}
        <p class="writing-list__desc">{{ post.description }}</p>
      {%- endif -%}
    </li>
  {%- endfor -%}
</ul>
{%- endif -%}
