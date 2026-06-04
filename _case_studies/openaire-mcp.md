---
title: "OpenAIRE MCP — Connecting AI agents to 150M+ scientific records"
lang: en
ref: openaire-mcp
slug: openaire-mcp
date_start: 2025
ongoing: true
category: ai-data-infrastructure
summary: "Model Context Protocol server exposing the OpenAIRE Research Graph — 150M+ scientific publications, datasets and software entities — to AI agents through a typed tool surface."
external_url: https://www.openaire.eu
tags: [ai-agents, mcp, open-science, research-graph, eu]
related_case_studies: [lds-copyfair, gallica-bnf]
---

## Overview

**Scientific knowledge is the highest-value corpus an AI agent can draw on — and one of the hardest to reach well.** The [OpenAIRE Research Graph](https://www.openaire.eu) aggregates 150M+ publications, datasets and software records from European and global open-science infrastructure, with the metadata that makes research *navigable*: authorship, funding, citations, organisations, projects. Search engines surface fragments of it. AI agents, until recently, saw none of it in a form they could reason over.

At Alien Intelligence we build and operate an [MCP (Model Context Protocol)](https://modelcontextprotocol.io) server that exposes the Research Graph to AI agents as a typed tool surface: search and retrieval across research products, author and organisation profiles, project and funding lookups, citation networks, bibliometric impact classes. An agent can go from *"find the key papers on this topic"* to *"map who funds this field in Europe"* in a handful of tool calls — every answer traceable to graph records rather than scraped snippets.

## My role

I lead the project end to end at Alien Intelligence: the partnership with OpenAIRE, the tool-surface design — what an agent should be able to ask of a research graph, and what it shouldn't have to know about the underlying APIs — and the path from prototype to operated service.

## Where it stands

A first version of the server is operational and in use with AI agents. A full write-up — architecture, tool-surface design choices, and what we learned about agent-shaped access to scholarly data — will follow as the project matures. The same principles drive the [Gallica / BnF](/case-studies/gallica-bnf/) and [LDS / Copyfair](/case-studies/lds-copyfair/) work.
