---
title: Writing
icon: fas fa-pen-nib
order: 3
lang: en
ref: writing
permalink: /writing/
---

{%- assign page_lang = page.lang | default: site.lang -%}
{%- assign lang_posts = site.posts | where: 'lang', page_lang | where_exp: 'p', 'p.hidden != true' -%}

{%- if lang_posts.size == 0 -%}

Nothing published here yet. The writing framework is in place; posts land incrementally from the [blog-migration project]({{ '/about/' | relative_url }}) after editorial review. Meanwhile, see the [case studies]({{ '/case-studies/' | relative_url }}) for longer-form work.

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
