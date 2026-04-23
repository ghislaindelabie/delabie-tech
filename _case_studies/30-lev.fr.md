---
title: "30 VELI — Expérimentation nationale de véhicules légers intermédiaires"
lang: fr
ref: 30-lev
slug: 30-lev
permalink: /fr/case-studies/30-lev/
date_start: 2023
date_end: 2026
category: mobilité
summary: "Programme ADEME × La Fabrique des Mobilités : 30 véhicules légers intermédiaires déployés, instrumentés et analysés sur plusieurs territoires — préfiguration d'un programme élargi."
cover: /assets/img/case-studies/30-lev/cover.png
cover_alt: "Tableau de bord des données d'usage des 30 VELI"
external_url: https://wikixd.fabmob.io/wiki/Organiser_les_exp%C3%A9rimentations_des_v%C3%A9hicules_interm%C3%A9diaires
tags: [mobilité, télématique, données, open-source, expérimentation]
related_case_studies: [mob, maas-standards]
---

## Résumé

Lancé mi-2023 par La Fabrique des Mobilités avec le soutien de l'ADEME, **30 VELI** vise à déployer, tester et documenter l'expérimentation de **30 véhicules légers intermédiaires (VELI)** sur plusieurs territoires pilotes. Sourcing constructeurs, montage juridique et assurance, instrumentation télématique et analyse open-source des usages — l'initiative se clôt début 2026 et peut servir de tremplin à un programme élargi, *300 VELI*.

## Contexte et objectifs

### Pourquoi les VELI ?

Les « véhicules intermédiaires légers » (VELI) sont une solution pour les trajets quotidiens où la voiture est sur-dimensionnée : gabarit réduit, électrification sobre, coût d'usage faible. L'ADEME a lancé un programme national d'innovation et de développement d'une filière française et européenne, avec le soutien de France 2030 : [l'eXtrême Défi](https://xd.ademe.fr/).

### Genèse du programme

- **Printemps–Été 2023** — rédaction du dossier de financement et [cadrage méthodologique avec l'ADEME](https://wikixd.fabmob.io/wiki/Organiser_les_exp%C3%A9rimentations_des_v%C3%A9hicules_interm%C3%A9diaires). [Publication d'un AMI constructeurs](https://wiki.lafabriquedesmobilites.fr/wiki/Appel_%C3%A0_Manifestation_d%27Int%C3%A9r%C3%AAt_%28AMI%29_%C3%A0_destination_de_Constructeurs_de_V%C3%A9hicules_Interm%C3%A9diaires).
- Positionnement dans la [feuille de route « Territoires & Expérimentations » de l'eXtrême Défi](https://wikixd.fabmob.io/wiki/GT_Territoires_et_Exp%C3%A9rimentations_XD).

### Ambition

1. Valider la faisabilité technique et économique de flottes VELI.
2. Produire un retour d'expérience réplicable (guides, contrats, tableaux d'expérimentations).
3. Préparer le passage à l'échelle (*300 VELI*).

## Chronologie

| Période            | Jalons clés |
|--------------------|-------------|
| **Mi-2023**        | Conception, cadrage financier et contractualisation ADEME ; AMI constructeurs |
| **S2 2023**        | Sourcing des 30 véhicules ; conventions territoires / associations ; premières mises à disposition |
| **2024**           | Direction de projet et reporting trimestriel ; déploiement des boîtiers télématiques ; ouverture du dépôt GitHub **dataviz-30-veli** |
| **Fin 2024 – 2025**| Analyse d'usage et indicateurs environnementaux ; scénarios de réemploi ; préfiguration de **300 VELI** |
| **Début 2026**     | Clôture officielle : synthèse, webinaires, open-data |

## Solution télématique

- **Matériel** : boîtiers GNSS + 4G basse consommation, installation réversible.
- **Collecte** : positions, vitesses, cycles charge/décharge (quand le bus véhicule l'expose), compte-kilométrique.
- **Stack** : ingestion MQTT → TimescaleDB → API.
- **Dataviz** : dépôt public [`fabmob/dataviz-30-veli`](https://github.com/fabmob/dataviz-30-veli) — notebooks, requêtes SQL, [graphiques interactifs](https://30veli.fabmob.io/).

## Mon rôle

| Phase                       | Contributions |
|-----------------------------|----------------|
| **Cadrage (mi-2023)**       | Rédaction du concept, budget, négociation des objectifs et indicateurs avec l'ADEME |
| **Lancement (S2 2023)**     | Pilotage de l'AMI constructeurs ; conventions juridiques et assurance |
| **Direction 2024**          | Gouvernance projet (COPIL, KPIs) ; sourcing et logistique |
| **Télématique & analytics** | Spécification boîtiers / cloud ; supervision du dépôt *dataviz-30-veli* |
| **2025 — expertise**        | Scénarios de réemploi (associations, collectivités, [leasing social](https://lafabriquedesmobilites.fr/blog/veli_leasing_social)) ; design et pilotage de l'étude d'extension *300 VELI* |

## Ressources

- Wiki FabMob : [Organiser les expérimentations des véhicules intermédiaires](https://wikixd.fabmob.io/wiki/Organiser_les_exp%C3%A9rimentations_des_v%C3%A9hicules_interm%C3%A9diaires)
- Tableau des expérimentations : [Entrées par véhicules](https://wikixd.fabmob.io/wiki/Tableau_des_exp%C3%A9rimentations_-_Entr%C3%A9es_par_les_V%C3%A9hicules)
- Dépôt GitHub : <https://github.com/fabmob/dataviz-30-veli>
