---
title: "30 LEV — A national field trial of light electric vehicles"
lang: en
ref: 30-lev
slug: 30-lev
date_start: 2023
date_end: 2026
category: mobility
summary: "ADEME-backed programme with La Fabrique des Mobilités: 30 light electric vehicles deployed across pilot sites, instrumented, and analysed — paving the way for scale-up."
cover: /assets/img/case-studies/30-lev/cover.png
cover_alt: "Dashboard showing 30 LEV usage data"
external_url: https://wikixd.fabmob.io/wiki/Organiser_les_exp%C3%A9rimentations_des_v%C3%A9hicules_interm%C3%A9diaires
tags: [mobility, telematics, data, open-source, field-trial]
related_case_studies: [mob, maas-standards]
---

## At a glance

**30 LEV** is an ADEME-backed programme run by **La Fabrique des Mobilités**. Between 2023 and 2026 it field-tests **30 light electric vehicles (LEVs)** on several pilot sites, collects high-resolution usage data, and publishes open-source lessons to pave the way for a larger roll-out (*300 LEV*).

## Context and goals

### Why light electric vehicles?

LEVs bridge the gap between bikes and cars: compact, electric-powered and affordable — ideal for short daily trips where a full-size car is overkill.

### Project origins

- **Spring–Summer 2023** — concept note, budget and agreement with ADEME.
- Embedded in the *eXtrême Défi* roadmap for territories and trials.

### Objectives

1. Prove the technical and economic viability of LEV fleets.
2. Create reusable documentation (contracts, dashboards, data).
3. Prepare the scale-up programme *300 LEV*.

## Timeline

| Period              | Key milestones |
|---------------------|----------------|
| **Mid-2023**        | Project design and ADEME contract; call for manufacturers |
| **H2 2023**         | Sourcing the 30 LEVs; agreements with local hosts; first units on the road |
| **2024**            | Programme management and reporting; telematics roll-out and data pipeline; public GitHub repo `fabmob/dataviz-30-lev` |
| **Late 2024 – 2025**| Usage analytics and environmental KPIs; scenarios for post-trial reuse; scoping study for *300 LEV* |
| **Early 2026**      | Final synthesis, webinars, open-data release |

## Telematics and data visualisation

To capture real-world usage we specified an **end-to-end telematics stack**:

- **Hardware**: GNSS + 4G low-power boxes, easily removable.
- **Data**: position, speed, battery cycles (where the vehicle bus exposed them), odometer.
- **Backend**: MQTT → TimescaleDB → REST API.
- **Visuals**: open dashboards at <https://github.com/fabmob/dataviz-30-lev>.

## My role

| Phase                      | Contribution |
|----------------------------|--------------|
| **Design (mid-2023)**      | Concept note, budget, KPI negotiation with ADEME |
| **Kick-off (H2 2023)**     | Manufacturer call, legal and insurance framework |
| **2024**                   | Programme lead, steering committees, logistics |
| **Telematics & analytics** | Spec, vendor selection, repo supervision |
| **2025**                   | Reuse scenarios, scale-up study *300 LEV* |

## Resources

- [Wiki: Organiser les expérimentations des véhicules intermédiaires](https://wikixd.fabmob.io/wiki/Organiser_les_exp%C3%A9rimentations_des_v%C3%A9hicules_interm%C3%A9diaires)
- [Vehicle entries dashboard](https://wikixd.fabmob.io/wiki/Tableau_des_exp%C3%A9rimentations_-_Entr%C3%A9es_par_les_V%C3%A9hicules)
- [Data visualisation repo](https://github.com/fabmob/dataviz-30-lev)
