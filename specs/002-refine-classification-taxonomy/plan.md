# Implementation Plan: Refined Classification Taxonomy

**Branch**: `002-refine-classification-taxonomy` | **Date**: 2026-01-16 | **Spec**: [spec.md](./spec.md)

## Summary

Refine the openness classifier's 4-category taxonomy to better distinguish between "mostly_open" and "mostly_closed" classifications by enhancing prompts with explicit decision rules based on data/code completeness attributes, access barrier types, and repository persistence. The classifier currently uses few-shot learning with k=5 similar examples, but needs more explicit guidance to consistently apply the nuanced distinction between publications with minor obstacles but sufficient materials (mostly_open) versus those with substantial barriers (mostly_closed). This refinement will improve classification accuracy by 15+ percentage points and achieve Cohen's kappa > 0.70 for inter-rater agreement.

## Technical Context

**Language/Version**: Python 3.10+ (per pyproject.toml requirements)
**Primary Dependencies**:
- `litellm>=1.0` (unified LLM provider interface for Claude, OpenAI, Ollama)
- `sentence-transformers>=2.2` (semantic similarity for kNN example selection)
- `scikit-learn>=1.3` (Cohen's kappa, metrics)
- `pandas>=2.0` (data loading and batch processing)
- `pydantic>=2.0` (structured data validation)

**Storage**: CSV files (articles_reviewed.csv with training data including data_included/code_included columns)
**Testing**: pytest>=7.0 with method validation tests against ground truth data
**Target Platform**: Python CLI/notebook environment (nbdev-based development)
**Project Type**: Single project (scientific library with notebook-based development)
**Performance Goals**: 5-10 seconds per classification (300 publications in 25-50 minutes)
**Constraints**:
- LLM API latency (retry with exponential backoff for transient failures)
- Must maintain backward compatibility with existing "open" and "closed" classifications
- Classification decisions must be explainable (chain-of-thought reasoning required)

**Scale/Scope**:
- Training data: 303 publications with human-coded classifications
- 162 data statements, 141 code statements
- Validation target: >80% accuracy on "Partially Closed" reclassification

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Research-First Development ✅
- **Scientific Purpose**: Directly supports meta-analysis of research openness by improving classification accuracy for reproducibility assessment
- **Method Validity**: Uses established few-shot learning pattern with semantic similarity (sentence-transformers), validated against human-coded ground truth
- **Research Context**: Integrates seamlessly with existing Jupyter notebook workflow (nbdev architecture)
- **Domain Specificity**: Tailored to scholarly publication data/code availability statements with domain-specific taxonomy

### Reproducibility & Transparency ✅
- **Environment Specification**: Dependencies pinned in pyproject.toml, pixi.toml manages environment
- **Data Provenance**: Training data from articles_reviewed.csv with full metadata (data_included, code_included columns)
- **Computational Methods**: Explicit decision rules based on completeness attributes documented in spec
- **Version Control**: Feature branch workflow with git
- **Open Science**: Classification rubric and prompts will be transparent and documented

### Documentation as Science Communication ✅
- **Method Documentation**: Specification documents WHY (scientific rationale) for refined taxonomy based on reproducibility potential
- **Literature References**: Classification taxonomy derived from systematic review of openness practices
- **Assumptions & Limitations**: Explicitly documented in spec (subjective boundaries, statement detail limitations)
- **Usage Examples**: Existing tutorial notebooks (01_single_publication.ipynb demonstrates usage)
- **Narrative Structure**: Specification written for research stakeholders, not just developers

### Incremental Implementation with Validation ✅
- **MVP Definition**: Refine prompts for mostly_open/mostly_closed distinction, validate against existing ground truth
- **Validation Checkpoints**: Success criteria include measurable targets (15pp improvement, kappa > 0.70, 80% reclassification accuracy)
- **User Story = Research Task**: User stories map to research tasks (classify statements, validate taxonomy, generate reasoning)
- **Iterative Refinement**: Start with prompt refinement, validate, then iterate based on results
- **Test with Real Data**: Validation uses actual training data (303 publications with completeness attributes)

### Library & Method Integration ✅
- **Use Standard Libraries**: Leverages sentence-transformers (established semantic similarity), litellm (unified LLM interface), scikit-learn (validation metrics)
- **Method References**: Few-shot learning with kNN example selection is established method
- **Custom Code Justification**: Custom prompt templates needed for domain-specific openness taxonomy (not general-purpose)
- **Manuscript Integration**: Classification reasoning outputs support methods section documentation
- **Extensibility**: Prompt template structure allows future refinement without architectural changes

**Gate Result**: ✅ PASS - All principles aligned. No violations requiring justification.

## Project Structure

### Documentation (this feature)

```text
specs/002-refine-classification-taxonomy/
├── plan.md              # This file
├── research.md          # Phase 0: Prompt engineering patterns, completeness indicator validation
├── data-model.md        # Phase 1: Enhanced classification data structures
├── quickstart.md        # Phase 1: Usage guide for refined classifier
├── contracts/           # Phase 1: LLM prompt contracts (input/output schemas)
└── tasks.md             # Phase 2: Implementation tasks (generated by /speckit.tasks)
```

### Source Code (repository root)

```text
# Single project structure (nbdev-based scientific library)
openness_classifier/
├── core.py              # Existing: OpennessCategory, Classification, LLMProvider
├── prompts.py           # MODIFY: Enhanced prompt templates with completeness reasoning
├── classifier.py        # MODIFY: Updated classification logic with refined rules
├── data.py              # Existing: TrainingExample, load_training_data
├── config.py            # Existing: Configuration loading
├── batch.py             # MODIFY: Add retry logic and failure handling (FR-010)
├── validation.py        # MODIFY: Add completeness-based validation metrics
└── visualization.py     # Existing: Results visualization

nbs/
├── 00_core.ipynb        # Existing: Core types and enums
├── 01_config.ipynb      # Existing: Configuration
├── 02_data.ipynb        # Existing: Data loading
├── 03_prompts.ipynb     # MODIFY: Enhanced prompt engineering with completeness rules
├── 04_classifier.ipynb  # MODIFY: Refined classification logic
├── 05_batch.ipynb       # MODIFY: Failure handling and retry logic
├── 06_validation.ipynb  # MODIFY: Completeness-based validation
└── tutorials/
    └── 02_refined_taxonomy.ipynb  # NEW: Tutorial demonstrating refined classification

tests/
├── test_prompts.py      # MODIFY: Add tests for completeness-aware prompts
├── test_classifier.py   # MODIFY: Add tests for refined taxonomy
└── test_validation.py   # MODIFY: Add tests for completeness metrics

resources/
└── abpoll-open-b71bd12/data/processed/
    └── articles_reviewed.csv  # Existing: Training data with completeness attributes
```

**Structure Decision**: Single project structure is appropriate because this is a scientific library with notebook-based development (nbdev pattern). All code lives in `openness_classifier/` package with parallel notebook development in `nbs/`. The existing structure already supports the classification workflow; this feature only enhances the prompt engineering and validation components.

## Complexity Tracking

> **No violations detected** - Constitution Check passed all principles.

---

## Phase 0: Research & Design Decisions

### Research Tasks

1. **Prompt Engineering Patterns for Completeness-Based Classification**
   - Research: Best practices for chain-of-thought prompting with attribute-based reasoning
   - Research: Techniques for instructing LLMs to weight specific attributes (completeness vs barriers)
   - Decision: How to structure prompts to ensure explicit consideration of data_included/code_included indicators

2. **Completeness Indicator Validation**
   - Research: Validate that the completeness indicators from training data generation (FR-002, FR-003) align with actual articles_reviewed.csv values
   - Research: Analyze distribution of "Partially Closed" publications by completeness attributes
   - Decision: Confirm indicator lists are exhaustive and correctly categorize mostly_open vs mostly_closed

3. **Hard Precedence Rule Implementation**
   - Research: Prompt engineering techniques for absolute rules (FR-004: access barriers always take precedence)
   - Research: How to prevent LLMs from over-weighting positive factors when barriers exist
   - Decision: Prompt structure to enforce hard precedence without ambiguity

4. **Failure Handling and Retry Strategies**
   - Research: Exponential backoff best practices for LLM API calls (FR-010)
   - Research: Error categorization (retryable vs non-retryable)
   - Decision: Backoff parameters (initial delay, multiplier, max attempts)

5. **Few-Shot Example Selection with Refined Taxonomy**
   - Research: Should kNN example selection favor examples near the mostly_open/mostly_closed boundary?
   - Research: Diversity vs similarity tradeoff for refined taxonomy
   - Decision: Modify example selection strategy or keep existing cosine similarity approach

**Output**: `research.md` with findings, decisions, and rationale for each research task

---

## Phase 1: Design & Implementation Planning

### 1. Data Model Enhancements (`data-model.md`)

**Entities from Specification**:

- **OpennessCategory** (existing, no changes needed)
  - 4-category enum: open, mostly_open, mostly_closed, closed
  - Ordinal comparison operators

- **Classification** (existing, may need enhancement)
  - Fields: category, statement_type, confidence_score, reasoning, timestamp
  - Enhancement: Ensure reasoning field captures completeness attributes explicitly

- **CompletenessAttributes** (new supporting structure)
  - Purpose: Represent data/code completeness indicators for validation
  - Fields:
    - completeness_type: "data" | "code"
    - attributes: List[str] (e.g., ["Raw", "Results", "Source Data"])
    - is_mostly_open: bool (based on FR-002/FR-003 rules)

- **AccessBarrier** (new supporting structure)
  - Purpose: Categorize access barriers for precedence rule (FR-004)
  - Fields:
    - barrier_type: "none" | "minor" | "substantial"
    - description: str (e.g., "data use agreement", "registration required")
    - forces_mostly_closed: bool (true if substantial barrier)

- **ClassificationFailure** (new for FR-010)
  - Purpose: Track failed classification attempts
  - Fields:
    - publication_id: str
    - error_type: str (timeout, rate_limit, malformed_response)
    - retry_count: int
    - final_status: "unclassified"
    - error_reason: str

### 2. API Contracts (`/contracts/`)

**Refined Classification Prompt Schema** (OpenAPI-style):

```yaml
# contracts/classification_prompt.yaml
prompt_request:
  statement: string (the data/code availability statement)
  statement_type: enum [data, code]
  few_shot_examples: array[TrainingExample]

prompt_response:
  category: enum [open, mostly_open, mostly_closed, closed]
  confidence: float (0.0-1.0)
  reasoning: string (MUST mention completeness attributes for mostly_open/mostly_closed)
  completeness_attributes_mentioned: array[string] (extracted from reasoning)
  access_barriers_mentioned: array[string] (extracted from reasoning)
```

**Enhanced Prompt Structure**:
- System prompt: Existing taxonomy definitions
- Few-shot examples: k=5 semantically similar examples
- Classification template: Enhanced with explicit steps (FR-007):
  1. Identify data/code types mentioned (Raw, Results, Source Data, etc.)
  2. Identify access barriers (registration, DUA, proprietary, etc.)
  3. Determine repository type (persistent: Zenodo/Figshare vs non-persistent: GitHub)
  4. Apply hard precedence rule: substantial barriers → mostly_closed
  5. Assess completeness for mostly_open vs mostly_closed if no substantial barriers

### 3. Quickstart Guide (`quickstart.md`)

**Content**:
- Overview of refined taxonomy (mostly_open vs mostly_closed distinctions)
- Installation and configuration (no changes from existing)
- Usage examples:
  - Classify a statement with explicit reasoning output
  - Batch process with refined taxonomy
  - Validate against ground truth with completeness attributes
- Interpreting classification reasoning (how to see completeness attributes)
- Performance expectations (5-10 seconds per classification)

### 4. Agent Context Update

Run `.specify/scripts/bash/update-agent-context.sh claude` to update `CLAUDE.md` with:
- Technologies added: None (all dependencies already exist)
- Methods documented: Refined prompt engineering pattern with completeness attributes
- Testing approach: Validation against ground truth with completeness-based metrics

**Output**:
- `data-model.md` with enhanced entities and validation rules
- `/contracts/classification_prompt.yaml` with enhanced prompt schema
- `quickstart.md` with usage guide for refined classifier
- Updated agent context file

---

## Phase 2: Implementation Tasks

**Note**: Detailed implementation tasks will be generated by `/speckit.tasks` command. The tasks will cover:

1. **Prompt Enhancement** (FR-001 to FR-009)
   - Update `SYSTEM_PROMPT` with refined category definitions
   - Enhance `DATA_CLASSIFICATION_TEMPLATE` with completeness step-by-step reasoning
   - Enhance `CODE_CLASSIFICATION_TEMPLATE` with completeness step-by-step reasoning
   - Add hard precedence rule enforcement to templates

2. **Classification Logic Refinement**
   - Update `parse_classification_response()` to extract completeness attributes from reasoning
   - Validate that reasoning mentions completeness for mostly_open/mostly_closed classifications (SC-004)

3. **Failure Handling** (FR-010)
   - Implement retry logic with exponential backoff in `LLMProvider.complete()`
   - Add `ClassificationFailure` tracking in batch processing
   - Ensure graceful degradation (mark as "unclassified", continue processing)

4. **Validation Enhancements**
   - Add completeness-based validation metrics (SC-003: 80% correct reclassification)
   - Calculate Cohen's kappa for 4-category taxonomy (SC-002: > 0.70)
   - Measure reasoning quality (SC-004: 90% mention completeness)

5. **Testing**
   - Test refined prompts with boundary cases (persistent repo + DUA, ambiguous completeness)
   - Test failure handling and retry logic
   - Validate against articles_reviewed.csv ground truth

**Next Command**: Run `/speckit.tasks` to generate dependency-ordered implementation tasks.

---

## Risk & Mitigation

| Risk | Impact | Mitigation |
|------|--------|------------|
| LLM doesn't consistently follow completeness reasoning despite enhanced prompts | HIGH: Classification accuracy doesn't improve | Validate early with small test set; iterate prompt structure; consider adding few-shot examples specifically near mostly_open/mostly_closed boundary |
| Completeness indicators from training data don't match spec assumptions | HIGH: Validation metrics fail | Phase 0 research validates indicators against actual articles_reviewed.csv values before implementation |
| Hard precedence rule too conservative (over-classifies as mostly_closed) | MEDIUM: Lower F1-score for mostly_open | Validate against ground truth SC-003 (80% threshold); adjust if needed with user approval |
| Performance target (5-10s) not met due to longer reasoning prompts | LOW: Slower batch processing | Optimize prompt length; consider parallel batch processing; acceptable range is broad (25-50 min for 300 pubs) |

---

## Validation Strategy

1. **Ground Truth Validation**: Compare refined classifications against articles_reviewed.csv with completeness attributes
   - Metric: % correct reclassification of "Partially Closed" publications (target: ≥80%)
   - Metric: Cohen's kappa for 4-category taxonomy (target: >0.70)

2. **Reasoning Quality Assessment**: Analyze classification reasoning outputs
   - Metric: % of mostly_open/mostly_closed classifications that explicitly mention completeness attributes (target: 90%)
   - Method: Text analysis to detect completeness keywords in reasoning field

3. **Performance Benchmarking**: Measure classification latency
   - Metric: Average time per classification (target: 5-10 seconds)
   - Method: Batch process 50 test publications and calculate mean latency

4. **Failure Handling Validation**: Test retry logic and error handling
   - Method: Simulate API failures and verify exponential backoff behavior
   - Method: Verify batch processing continues after individual failures

---

## Dependencies

- **Existing Codebase**:
  - `openness_classifier` package with core classification infrastructure
  - `articles_reviewed.csv` with training data and completeness attributes
  - Few-shot learning with kNN example selection (sentence-transformers)
  - LLM provider abstraction (litellm)

- **External Services**:
  - LLM API (Claude Haiku or equivalent) with sufficient rate limits for batch processing
  - No new external dependencies required

- **Development Tools**:
  - nbdev for notebook-based development
  - pytest for validation testing
  - scikit-learn for Cohen's kappa calculation

---

## Out of Scope (per specification)

- Re-coding the original articles_reviewed.csv data
- Changing the fundamental 4-category taxonomy structure
- Creating new completeness attribute coding systems
- Validating whether completeness actually predicts reproducibility
- Adding new LLM providers beyond existing litellm support
- Web interface or API deployment (CLI/notebook usage only)
