---
title: "OpenAIRE MCP — Connecter les agents IA à 150M+ entités scientifiques"
lang: fr
ref: openaire-mcp
slug: openaire-mcp
permalink: /fr/case-studies/openaire-mcp/
date_start: 2026
ongoing: true
category: ai-data-infrastructure
summary: "Serveur Model Context Protocol exposant le OpenAIRE Research Graph — plus de 150 M publications, jeux de données et logiciels scientifiques — aux agents IA via une interface d'outils typée."
external_url: https://www.openaire.eu
tags: [agents-ia, mcp, science-ouverte, graphe-recherche, europe]
related_case_studies: [lds-copyfair, gallica-bnf]
---

## Aperçu

**Le savoir scientifique est le corpus le plus précieux qu'un agent IA puisse mobiliser — et l'un des plus difficiles à bien atteindre.** Le [graphe de recherche OpenAIRE](https://www.openaire.eu) agrège plus de 150 millions de publications, jeux de données et logiciels issus des infrastructures de science ouverte européennes et mondiales, avec les métadonnées qui rendent la recherche *navigable* : auteurs, financements, citations, organisations, projets. Les moteurs de recherche n'en montrent que des fragments. Les agents IA, jusqu'à récemment, n'y avaient accès sous aucune forme exploitable.

Chez Alien Intelligence, nous construisons et opérons un serveur [MCP (Model Context Protocol)](https://modelcontextprotocol.io) qui expose le graphe aux agents IA via une interface d'outils typée : recherche et consultation des productions scientifiques, profils d'auteurs et d'organisations, projets et financements, réseaux de citations, classes d'impact bibliométriques. Un agent passe de *« trouve les articles de référence sur ce sujet »* à *« cartographie qui finance ce champ en Europe »* en quelques appels d'outils — chaque réponse traçable jusqu'aux enregistrements du graphe, plutôt que des bribes moissonnées.

## Mon rôle

Je pilote le projet de bout en bout chez Alien Intelligence : le partenariat avec OpenAIRE, la conception de l'interface d'outils — ce qu'un agent doit pouvoir demander à un graphe de recherche, et ce qu'il ne devrait pas avoir à savoir des API sous-jacentes — et le passage du prototype au service opéré.

## Où en est le projet

Une première version du serveur est opérationnelle et utilisée par des agents IA, et nous avons lancé un hackathon ouvert avec OpenAIRE pour le mettre entre les mains des chercheurs et des développeurs. Un article complet — architecture, choix de conception de l'interface d'outils, enseignements sur l'accès « agentique » aux données scientifiques — suivra à mesure que le projet mûrit. Les mêmes principes guident les travaux [Gallica / BnF](/fr/case-studies/gallica-bnf/) et [LDS / Copyfair](/fr/case-studies/lds-copyfair/).
