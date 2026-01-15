# Implementation Plan: Openness Classification Model

**Branch**: `001-openness-classification` | **Date**: 2026-01-15 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-openness-classification/spec.md`

## Summary

Develop a few-shot LLM-based classification model to assess data and code openness from availability statements in scholarly publications. The model uses a 4-category ordinal taxonomy ("open", "mostly open", "mostly closed", "closed") and is trained on articles_reviewed.csv with human-coded examples. Implements nbdev framework for literate programming (notebooks + auto-generated library), supports multiple LLM providers (Claude API, OpenAI API, Ollama local models), and produces validation metrics suitable for manuscript methods sections.

## Technical Context

**Language/Version**: Python 3.10+ (required for modern type hints and compatibility with nbdev2, pandas, scikit-learn)
**Primary Dependencies**:
- nbdev (2.x) - literate programming framework, notebook-to-library conversion
- pandas - CSV handling, data manipulation
- scikit-learn - train/test splitting, validation metrics (accuracy, precision, recall, F1, Cohen's kappa)
- anthropic (Claude API), openai (OpenAI API), requests (Ollama API) - LLM providers
- pydantic - configuration management, validation
- matplotlib, seaborn - visualization (confusion matrices, performance plots)

**Storage**: File-based (CSV for training data, JSON for configuration, logs for reproducibility tracking)
**Testing**: pytest for unit/integration tests, nbdev's test framework for notebook testing
**Target Platform**: Cross-platform (macOS, Linux, Windows) - runs locally, Jupyter-compatible
**Project Type**: Single library project (nbdev structure: notebooks/ for development, auto-generates to library/)
**Performance Goals**: <10 seconds per single classification (including LLM API latency), batch processing 100+ publications within reasonable time (~5-10 minutes depending on LLM provider)
**Constraints**: Limited training sample size (few-shot approach necessary), LLM API costs (support local models via Ollama for development), reproducibility tracking required (log all LLM configurations)
**Scale/Scope**: Small-scale research tool (10-1000 publications per analysis), single-user initially (extensible to team workflows)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### ef_2026 Constitution Compliance (v1.1.0)

**Principle I: Research-First Development** ✅
- **Scientific Purpose**: Directly supports open science meta-analysis and FAIR compliance evaluation
- **Method Validity**: Few-shot learning validated against Brown et al. (2020); classification rubric from articles_reviewed.csv ground truth
- **Research Context**: Integrates with Jupyter notebooks; outputs suitable for manuscript methods sections
- **Domain Specificity**: Tailored to bibliometric analysis and systematic review workflows

**Principle II: Reproducibility & Transparency** ✅
- **Environment Specification**: pixi.toml/requirements.txt with pinned versions
- **Data Provenance**: Training data (articles_reviewed.csv) documented; classification decisions logged
- **Computational Methods**: LLM prompts, few-shot examples, and classification rubric documented
- **Version Control**: All code changes tracked; clarifications in spec.md
- **FAIR Principles**:
  - **Findable**: Code repo with DOI (Zenodo), training data with metadata
  - **Accessible**: Open source (MIT license), public repository
  - **Interoperable**: Standard CSV/JSON formats, cross-platform Python
  - **Reusable**: nbdev-generated documentation, usage examples in notebooks

**Principle III: Documentation as Science Communication** ✅
- **Method Documentation**: Notebooks explain WHY (research objective) before HOW (implementation)
- **Literature References**: FAIR principles (Wilkinson et al. 2016), few-shot learning (Brown et al. 2020), data sharing compliance (Gabelica et al. 2022)
- **Assumptions & Limitations**: Documented in spec.md (sample size, temporal drift, domain-specific accuracy)
- **Usage Examples**: Notebooks with real examples from articles_reviewed.csv
- **Manuscript Integration**: Methods section templates, LLM configuration documentation for reproducibility

**Principle IV: Incremental Implementation with Validation** ✅
- **MVP Definition**: P1 (single classification) → P2 (batch processing) → P3 (validation metrics) → P4 (model refinement)
- **Validation Checkpoints**: 80% accuracy target, Cohen's kappa > 0.6 vs. human raters
- **User Story = Research Task**: Each priority maps to practical research workflow step
- **Iterative Refinement**: Start with simple prompt engineering, add complexity only if accuracy requires
- **Test with Real Data**: Validate on articles_reviewed.csv holdout set

**Principle V: Library & Method Integration** ✅
- **Use Standard Libraries**: pandas, scikit-learn, nbdev (established scientific Python tools)
- **Method References**: Few-shot learning (Brown et al. 2020), classification rubric from existing human coding
- **Custom Code Justification**: Custom LLM prompt engineering necessary (domain-specific classification task)
- **Manuscript Integration**: Export validation metrics, LLM configuration for methods sections
- **Extensibility**: Multi-provider LLM support enables adaptation to new models

**Constitution Gates**: ✅ PASS - All principles aligned

## Project Structure

### Documentation (this feature)

```text
specs/001-openness-classification/
├── plan.md              # This file (/speckit.plan command output)
├── spec.md              # Feature specification (complete)
├── checklists/
│   └── requirements.md  # Specification quality checklist
├── research.md          # Phase 0: Technology research decisions (to be generated)
├── data-model.md        # Phase 1: Entity and data structure design (to be generated)
├── quickstart.md        # Phase 1: Getting started guide (to be generated)
└── contracts/           # Phase 1: API contracts for library functions (to be generated)
```

### Source Code (repository root - nbdev structure)

```text
nbs/                              # nbdev notebooks (literate programming source)
├── 00_core.ipynb                 # Core classification logic, LLM interface
├── 01_config.ipynb               # Configuration management (LLM provider, API keys)
├── 02_data.ipynb                 # Data loading, CSV handling
├── 03_prompts.ipynb              # Few-shot prompt engineering
├── 04_classifier.ipynb           # Main classification functions (data/code openness)
├── 05_batch.ipynb                # Batch processing for CSV inputs
├── 06_validation.ipynb           # Validation metrics, confusion matrices
├── 07_visualization.ipynb        # Performance visualization
├── index.ipynb                   # Package documentation/README
└── examples/
    ├── 01_single_classification.ipynb
    ├── 02_batch_processing.ipynb
    └── 03_validation_analysis.ipynb

openness_classifier/              # Auto-generated library (from notebooks)
├── __init__.py
├── core.py
├── config.py
├── data.py
├── prompts.py
├── classifier.py
├── batch.py
├── validation.py
└── visualization.py

tests/                            # Auto-generated tests + custom tests
├── test_core.py
├── test_classifier.py
├── test_batch.py
└── test_validation.py

data/                             # Training data and examples
├── articles_reviewed.csv         # Ground truth training data
└── README.md                     # Data provenance documentation

settings.ini                      # nbdev configuration
pyproject.toml                    # Project metadata, dependencies
requirements.txt                  # Pinned dependencies for reproducibility
pixi.toml                         # Pixi environment configuration (if used)
```

**Structure Decision**: Using nbdev's literate programming structure where notebooks in `nbs/` serve as both development environment AND documentation source, with library code auto-generated to `openness_classifier/`. This aligns with research workflows (interactive exploration) while producing a reusable Python package. Separates examples (user-facing) from core library notebooks.

## Complexity Tracking

> **No constitution violations requiring justification.**

All design decisions align with ef_2026 constitution principles:
- Nbdev adds complexity but justified by research workflow integration (Principle I, III)
- Multi-provider LLM support adds abstraction but necessary for cost control and reproducibility (Principle II, V)
- Extensive logging adds overhead but essential for FAIR reproducibility requirements (Principle II)
