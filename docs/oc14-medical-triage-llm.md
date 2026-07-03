---
# Source material for a portfolio case-study page. An agent may reshape this into the
# site's case-study collection (translate/trim as needed). All facts & links are accurate
# as of 2026-07-03. Repo tag `v2` is the state described here.
title: "Medical Triage LLM — a fine-tuned clinical triage assistant (POC)"
subtitle: "Specializing Qwen3-1.7B for emergency-department triage: SFT+LoRA → DPO → agentic pipeline → cloud serving"
type: case-study
date: 2026-07
role: "Solo — end-to-end AI Engineer (data, labeling, training, agent, serving, MLOps, report)"
context: "OpenClassrooms AI-Engineer certification — project #14, «Fine-tune your own LLM». Brief: a triage assistant for the ED of a fictional hospital (CHSA)."
duration: "~4 weeks"
status: "Proof-of-concept — positioned as decision-support / human-in-the-loop, NOT autonomous triage"
tags: [LLM fine-tuning, LoRA, DPO, RAG-free distillation, medical NLP, agents, LangGraph, GDPR, MLOps, vLLM]
stack:
  - Python, uv
  - Qwen3-1.7B-Base
  - Unsloth, LoRA / QLoRA (4-bit)
  - TRL (SFT + DPO, rpo_alpha)
  - LangGraph (agent chain)
  - Microsoft Presidio + spaCy (GDPR anonymization)
  - vLLM on RunPod serverless
  - FastAPI + Gradio
  - Hugging Face (model + Space)
  - Weights & Biases (experiment tracking + sweep)
  - GitHub Actions (CI/CD + auto-deploy)
links:
  live_demo: "https://ghislaindelabie-oc14-triage-demo.hf.space/"
  source_code: "https://github.com/ghislaindelabie/oc14-medical-triage-llm"
  fine_tuned_model: "https://huggingface.co/ghislaindelabie/oc14-qwen3-1.7b-triage-sft"
  experiment_tracking: "https://wandb.ai/ghislaindelabie/oc14-triage-eval"
  technical_report_pdf: "https://github.com/ghislaindelabie/oc14-medical-triage-llm/blob/main/docs/RAPPORT_FR.pdf"
headline_metrics:
  - "macro-F1 0.19 → 0.82 (untrained base → fine-tuned model), n=300 held-out gold"
  - "critical-urgency (maximale) recall 0.90 [95% CI 0.83–0.95]"
  - "DPO with rpo_alpha: +0.018 macro-F1 over SFT, like-for-like, with no class collapse"
  - "3-LLM consensus labeling, inter-annotator Fleiss κ ≈ 0.67 (substantial)"
---

## TL;DR

I specialized a small open-weights model (**Qwen3-1.7B-Base**) into a **medical-triage assistant** that
takes a patient's described symptoms, assesses an **urgency level** (*maximale / modérée / différée*),
justifies the decision, and runs inside a full **agentic pipeline** (adaptive intake → GDPR anonymization →
triage → explanation → traceability → hospital-system output). Fine-tuning took macro-F1 from **0.19 to
0.82** on a held-out test set. It's deployed as a **live cloud demo** and positioned honestly as
**human-in-the-loop decision support** — not an autonomous system.

- 🩺 **Live demo:** <https://ghislaindelabie-oc14-triage-demo.hf.space/>
- 💻 **Code (public):** <https://github.com/ghislaindelabie/oc14-medical-triage-llm>
- 🧠 **Fine-tuned model:** <https://huggingface.co/ghislaindelabie/oc14-qwen3-1.7b-triage-sft>
- 📊 **Experiments (W&B):** <https://wandb.ai/ghislaindelabie/oc14-triage-eval>
- 📄 **Technical report (FR, PDF):** [in the repo](https://github.com/ghislaindelabie/oc14-medical-triage-llm/blob/main/docs/RAPPORT_FR.pdf)

## The problem

A hospital emergency department faces chronic overload: stretched triage staff, long waits, and the risk
that critical cases aren't spotted fast enough. The brief was to build a POC assistant that collects a
patient's symptoms, evaluates a **priority level**, explains its reasoning, integrates with the hospital
information system (SIH), and guarantees **traceability** for medical audits.

Key design decision: the graded deliverable is a **complete agent** (the whole patient journey), not just a
fine-tuned LLM. I treated the fine-tuned model as the clinical core and built the functional chain around it.

## What I built

An agent implemented as a **LangGraph state machine** whose nodes *are* the required patient journey:

```
Patient → adaptive questionnaire → anonymization (GDPR boundary) → pre-processing / red-flags
        → triage (fine-tuned LLM) → explanation (+ safety override) → traceability (SQLite)
        → SIH output (FHIR R4, mock)
```

Deliberately linear with a single conditional (a deterministic safety override) — the deliverable is the
chain and its guarantees, not framework depth.

## Approach & methodology

### Data & GDPR

- **Bilingual (FR/EN) dataset (~5,600 pairs)** built from **real, open medical sources** (MediQAl exam
  vignettes, MedQuAD patient-education Q&A) plus a small set of hand-written safety vignettes.
- **The triage signal was labeled by a 3-LLM consensus** (GPT, Mistral, Claude) applying a cited clinical
  rubric (ESI/MTS-derived), returning a 3-level urgency + an ESI cross-check. Inter-annotator agreement
  **Fleiss κ ≈ 0.67 (substantial)**; the gold test set keeps only unanimous cases. This is an honest
  *silver* standard — clinician validation is the documented next step.
- **GDPR by construction**: the sources are exam questions + synthetic vignettes (no real patients →
  non-personal, GDPR Recital 26). Proven with a **Microsoft Presidio + spaCy** pass over 6,695 texts, and
  enforced at runtime by an **anonymization node that erases raw text** — only an anonymized version and a
  one-way `SHA-256` hash are ever stored ("hash for traceability, anonymize for storage").

### Training (SFT + LoRA, then DPO)

- **SFT + LoRA** on Qwen3-1.7B-Base with **Unsloth** on a free T4 GPU: only a ~0.3% adapter is trained
  (4-bit QLoRA, r=16, α=16, 2 epochs, seed 3407, ~80 min, ≈ €0). ChatML template imposed explicitly (a
  *Base* model ships none), served exactly as trained.
- **DPO — the interesting story.** My first preference-optimization attempt *regressed*: it collapsed the
  middle urgency class (recall 0.85 → 0.55). I diagnosed this as **likelihood displacement** (the middle
  level was the "rejected" side of both error directions) — a documented DPO failure mode. I then **fixed
  it**: rebalanced the preference pairs and added **`rpo_alpha`** (an NLL anchor on the chosen answer that
  prevents the collapse). On a strict like-for-like eval (same 300 gold, same harness, adapter on/off), the
  corrected DPO **improves macro-F1 0.827 → 0.845 with no collapse** and a safety-leaning profile. Lesson:
  the failure was in the *pair design*, not the method.

### Evaluation (honest, safety-first)

- **Held-out gold, n=300, stratified, greedy decoding, leak-free.** Headline metric = **macro-F1** (raw
  accuracy is gameable by over-predicting the most severe class). Reported with **Wilson confidence
  intervals**, per-class recall, and a confusion matrix.
- **Result: macro-F1 0.19 (base) → 0.82 (served model)**; critical-urgency recall **0.90 [0.83–0.95]**;
  format/disclaimer compliance 1.00 (learned from scratch).
- I ran an **adversarial audit of my own pipeline** and *retracted* an earlier inflated 0.81 (it had an
  eval→train leak + non-deterministic decoding). The defensible 0.82 replaced it. Owning the retraction is
  part of the story.

### The agent (safety & robustness)

- **Deterministic safety override**: any detected red-flag forces *urgence maximale* — a rule the model
  can never silently under-ride (the neuro-symbolic guardrail idea: rules for the non-negotiable, the LLM
  for nuance).
- **Out-of-distribution guardrail**: nonsensical/gibberish input is rejected *before* triage (the model,
  left alone, confabulates a verdict on garbage) — the deterministic counterpart to the red-flag override.
- **Traceability**: every interaction is a SQLite dossier row (request id, timestamp, model version,
  urgency, latency, input hash) with **no raw PII**.
- **SIH integration**: the case is shaped into a **FHIR R4 bundle** (a realistic mock of what a hospital
  system would ingest).
- Exposed as a **FastAPI** service (`/session/*`) with a **Gradio** patient UI.

### Serving & MLOps

- **vLLM** (OpenAI-compatible) on **RunPod serverless** (scale-to-zero), model pulled from a public HF repo,
  behind a FastAPI wrapper (system-prompt injection, stop tokens, API-key gate, privacy-safe audit log).
- **Live demo** as a **Hugging Face Space**.
- **CI/CD** (GitHub Actions): `ruff` + `pytest` on every push; pushes to `main` that touch the runtime
  **auto-deploy the Space**. Experiments tracked in **Weights & Biases** (arm comparison + a LoRA
  hyperparameter sweep). Fully reproducible (seed 3407, `uv.lock`, versioned Kaggle notebooks).

## Key results

| Metric (n=300 gold, greedy, leak-free) | Untrained Base | Fine-tuned (SFT v9, served) |
|---|--:|--:|
| **macro-F1** | 0.19 | **0.82** |
| accuracy | 0.25 | 0.82 |
| critical-urgency recall (safety) | 0.70 | **0.90 [0.83–0.95]** |
| format / disclaimer compliance | 0.68 / 0.00 | **1.00 / 1.00** |

Plus: corrected **DPO (rpo_alpha)** → **+0.018 macro-F1** like-for-like over the served model, no class
collapse. Labeling agreement **Fleiss κ ≈ 0.67**.

## Honest positioning & limitations

This is a **POC demonstrating a method and a clear signal of progress — not a deployable autonomous
triage system.** A 0.90 recall on life-threatening cases (CI floor 0.83) means up to ~1 in 6 could be
missed in the worst case → unacceptable for autonomy. It is positioned as **human-in-the-loop decision
support**: it assists staff, the clinician decides, it never diagnoses or prescribes, and it always shows a
disclaimer. Labels are a silver standard (LLM consensus, not clinician-validated); the corpus is exam
vignettes (over-represents severe cases); n=300 gives wide CIs. All limitations are documented in the report.

## Skills demonstrated

End-to-end LLM specialization: dataset design + weak-supervision labeling, PEFT (LoRA/QLoRA), preference
optimization (DPO) with a real diagnosed-and-fixed failure, rigorous & honest evaluation, agent design
(LangGraph), GDPR/privacy engineering (Presidio), cloud serving (vLLM/RunPod), MLOps (CI/CD, auto-deploy,
experiment tracking), and clear technical writing.

## All links

| | |
|---|---|
| **Live demo** (full agent) | <https://ghislaindelabie-oc14-triage-demo.hf.space/> |
| **Source code** (public, tag `v2`) | <https://github.com/ghislaindelabie/oc14-medical-triage-llm> |
| **Fine-tuned model** (SFT v9) | <https://huggingface.co/ghislaindelabie/oc14-qwen3-1.7b-triage-sft> |
| **Experiment tracking** (W&B) | <https://wandb.ai/ghislaindelabie/oc14-triage-eval> · [sweep](https://wandb.ai/ghislaindelabie/oc14-sft-sweep) |
| **Technical report** (French, PDF) | <https://github.com/ghislaindelabie/oc14-medical-triage-llm/blob/main/docs/RAPPORT_FR.pdf> |

> Note for the integrating agent: the technical report is in French; the demo UI is in French (medical
> context). This write-up is in English — translate/adapt to the site's FR/EN convention as needed. The
> served model is public; the corrected-DPO adapter also exists (private HF repo) if a link is wanted later.
