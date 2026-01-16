# Research Report: Refined Classification Taxonomy

**Feature**: 002-refine-classification-taxonomy
**Date**: 2026-01-16
**Phase**: Phase 0 - Pre-Implementation Research

## Executive Summary

This research report addresses five critical unknowns before implementing the refined classification taxonomy for the openness classifier. The investigation combines analysis of existing training data (303 publications with completeness attributes), review of 2025 LLM prompt engineering best practices, and examination of the current codebase to inform design decisions for distinguishing "mostly_open" from "mostly_closed" classifications.

**Key Findings**:
1. Structured chain-of-thought prompts with explicit attribute checklists produce the most consistent classifications
2. Training data completeness indicators from FR-002/FR-003 align well with actual data distributions, requiring minor refinements
3. Hard precedence rules require system-level positioning and explicit validation steps
4. Exponential backoff with jitter (3 retries, 1s initial delay, 2x multiplier) is industry standard for 2025
5. Diverse kNN example selection (current approach) outperforms boundary-focused selection for refined taxonomy

---

## Research Task 1: Prompt Engineering Patterns for Completeness-Based Classification

### Research Question
What prompt structure best guides LLMs to consistently classify statements based on specific completeness attributes (data/code types) while maintaining transparent reasoning?

### Research Findings

#### Current State Analysis
The existing prompt structure (`/Users/kellycaylor/dev/ef_2026/openness_classifier/prompts.py`) uses:
- System prompt with 4-category definitions
- Few-shot examples (k=5) selected via cosine similarity
- Simple 3-step chain-of-thought template asking about repository, restrictions, and "upon request" language

**Gaps Identified**:
- No explicit instruction to assess data/code completeness types
- No guidance on weighting completeness vs access barriers
- Missing repository persistence distinction (Zenodo vs GitHub)

#### 2025 Best Practices Review

**Chain-of-Thought for Classification**:
- CoT prompting enhances reasoning by breaking tasks into sub-steps, particularly effective for nuanced classification
- Combining CoT with few-shot prompting is most effective for complex tasks requiring logic and step-by-step reasoning
- Clarity, context, and specificity are the most predictive factors for high-quality LLM results in 2025

**Attribute-Based Classification**:
- Fine-grained attribute frameworks can achieve 80.4% exact classification agreement with proper structure
- Nine prompt engineering themes are effective: context, persona, templates, disambiguation, reasoning, analysis, keywords, wording, and few-shot prompting
- Chain-of-thought templates with contextual anchoring produce best results for attribute-dependent decisions

**Key Principle**: "Choose chain-of-thought prompts for tasks that require logic, analysis, or step-by-step reasoning—like math, troubleshooting, or decision-making."

#### Training Data Validation

Analysis of `/Users/kellycaylor/dev/ef_2026/resources/abpoll-open-b71bd12/data/processed/articles_reviewed.csv`:

**Partially Closed Data (78 publications)**:
- High completeness: "Raw" (31), "Raw; Results" (6), "All" (3), "Raw; Results; Source Data" (1) = **41 publications (53%)**
- Lower completeness: "Results" (19), "Source Data" (4), various partial combinations = **37 publications (47%)**

**Partially Closed Code (55 publications)**:
- High completeness: "All" (5), "Download; Process; Analysis; Figures" (1), "Processing; Generate Results" (1), "Generate Results; Figures" (1) = **8 publications (15%)**
- Moderate completeness: "Model" (11), "Models" (8), "Analysis" (5), "Analysis; Figures" (2) = **26 publications (47%)**
- Lower completeness: "Results" (4), "Processing" (2), partial combinations = **21 publications (38%)**

This distribution confirms that completeness attributes provide meaningful signal for distinguishing mostly_open vs mostly_closed, but the boundary is nuanced (not a clean 80/20 split).

### Decision: Enhanced Structured Chain-of-Thought Prompt

Adopt a 5-step explicit checklist structure for classification prompts:

```
Think step-by-step:
1. Identify data/code types mentioned: List specific types (Raw, Results, Source Data, All / Download, Process, Analysis, Figures, Models)
2. Assess completeness: Does the statement indicate all necessary materials for reproduction or only partial materials?
3. Identify access barriers: Minor (registration, institutional access) or Substantial (DUA, proprietary, confidentiality, "upon request")
4. Determine repository type: Persistent (Zenodo, Figshare, Dryad, institutional) or Non-persistent (GitHub, personal website)
5. Apply classification rules:
   - Substantial barrier → mostly_closed (ALWAYS, regardless of completeness)
   - No substantial barrier + high completeness (all/most materials) → mostly_open
   - No substantial barrier + low completeness (partial materials) → mostly_closed
   - No materials or "upon request" → closed
```

### Rationale

1. **Explicit Attribute Enumeration**: Step 1 forces the model to extract specific completeness indicators matching FR-002/FR-003 categories, reducing ambiguity
2. **Completeness Assessment**: Step 2 provides interpretation guidance for the extracted attributes
3. **Barrier Categorization**: Step 3 creates clear distinction between minor and substantial barriers critical for mostly_open/mostly_closed boundary
4. **Repository Context**: Step 4 adds persistence factor mentioned in FR-006 without over-weighting it
5. **Rule Application**: Step 5 explicitly states the decision logic including hard precedence (substantial barriers always win)

This structure aligns with 2025 best practices emphasizing "clarity, context, and specificity" and the proven effectiveness of "chain-of-thought templates with contextual anchoring."

### Alternatives Considered

**Alternative A: Free-form CoT with Examples Only**
- Rely on few-shot examples to demonstrate completeness reasoning
- *Rejected*: Less consistent across diverse statement phrasings; model may miss completeness signals not prominent in examples

**Alternative B: Multi-stage Classification (Completeness First, Then Barriers)**
- Separate API calls: first classify completeness, then assess barriers
- *Rejected*: 2x API cost, 2x latency, introduces error compounding between stages

**Alternative C: Scoring System (Weighted Attributes)**
- Assign numerical scores to completeness/barriers, use threshold
- *Rejected*: Reduces interpretability of reasoning; hard precedence rule difficult to enforce in scoring system

---

## Research Task 2: Completeness Indicator Validation

### Research Question
Do the completeness indicators specified in FR-002 (data) and FR-003 (code) accurately represent the "mostly_open" category in the training data? Are these lists exhaustive?

### Research Findings

#### FR-002 Validation: Data Completeness Indicators

**Specified indicators for mostly_open**: "All", "Raw; Results; Source Data", "Raw; Results"

**Training Data Analysis**:

From 78 Partially Closed data publications:
- **"All"**: 3 publications (4%)
- **"Raw; Results; Source Data"**: 1 publication (1%)
- **"Raw; Results"**: 6 publications (8%)
- **"Raw" (alone)**: 31 publications (40%) ← **NOT in FR-002 list**
- **"Raw; Source Data"**: 1 publication (1%)
- Other combinations: 36 publications (46%)

**Critical Finding**: The most common completeness attribute in Partially Closed data is "Raw" alone (31/78, 40%), which is NOT included in the FR-002 list. This suggests raw data alone, even with access barriers, indicates significant reproducibility potential.

**Additional patterns**:
- "Results" alone appears in 19 publications (24%) - arguably lower completeness
- "Source Data" alone appears in 4 publications (5%)
- Combinations with "Results" but without raw data are common

#### FR-003 Validation: Code Completeness Indicators

**Specified indicators for mostly_open**: "All", "Download; Process; Analysis; Figures", "Processing; Generate Results", "Processing; Results", "Models; Results", "Models; Analysis", "Analysis; Figures", "Model; Figures", "Results; Figures", "Generate Results; Figures"

**Training Data Analysis**:

From 55 Partially Closed code publications:
- **"All"**: 5 publications (9%) ✓ in FR-003
- **"Download; Process; Analysis; Figures"**: 1 publication (2%) ✓ in FR-003
- **"Processing; Generate Results"**: 1 publication (2%) ✓ in FR-003
- **"Processing; Results"**: 1 publication (2%) ✓ in FR-003
- **"Generate Results; Figures"**: 1 publication (2%) ✓ in FR-003
- **"Analysis; Figures"**: 2 publications (4%) ✓ in FR-003
- **"Model; Figures"**: 2 publications (4%) ✓ in FR-003
- **"Results; Figures"**: 2 publications (4%) ✓ in FR-003
- **"Models; Analysis"**: 1 publication (2%) ✓ in FR-003
- **"Models; Results"**: 1 publication (2%) ✓ in FR-003
- **"Model" (alone)**: 11 publications (20%) ← **NOT in FR-003 list** (though "Model; Figures" is)
- **"Models" (alone)**: 8 publications (15%) ← **NOT in FR-003 list** (though "Models; Results" is)
- **"Analysis" (alone)**: 5 publications (9%) ← **NOT in FR-003 list** (though "Analysis; Figures" is)
- Other: 15 publications (27%)

**Critical Finding**: Standalone "Model" (11), "Models" (8), and "Analysis" (5) are common in Partially Closed but NOT in FR-003. This totals 24/55 publications (44%) with potentially mostly_open code completeness not captured by FR-003.

#### Completeness Distribution Insights

**Data "mostly_open" threshold**:
- FR-002 list captures: 10/78 Partially Closed publications (13%)
- Adding "Raw" alone: 41/78 publications (53%)
- This suggests raw data availability, even partial, is strong signal for mostly_open

**Code "mostly_open" threshold**:
- FR-003 list captures: 17/55 Partially Closed publications (31%)
- Adding standalone "Model", "Models", "Analysis": 41/55 publications (75%)
- However, these standalone terms may indicate incomplete workflows

### Decision: Refine Completeness Indicator Lists

**Updated FR-002 (Data Completeness for mostly_open)**:
- Add: "Raw" (standalone - indicates source data available despite access barriers)
- Keep: "All", "Raw; Results; Source Data", "Raw; Results"
- Rationale: Raw data is most valuable for reproduction; 31/78 Partially Closed have this

**Updated FR-003 (Code Completeness for mostly_open)**:
- Add: "Model" or "Models" (standalone - indicates computational methods available)
- Keep existing multi-component combinations
- Do NOT add: "Analysis" alone (too vague, may be post-processing scripts only)
- Rationale: Models represent core computational approach; 19/55 Partially Closed have Model/Models

**Final Lists**:
- **Data mostly_open**: "All", "Raw; Results; Source Data", "Raw; Results", "Raw", "Raw; Source Data"
- **Code mostly_open**: All FR-003 items + "Model" + "Models"

### Rationale

1. **Evidence-Based**: Training data shows "Raw" and "Model/Models" are prevalent in Partially Closed, suggesting these indicate mostly_open potential
2. **Reproducibility Logic**: Raw data enables re-analysis; computational models enable method replication
3. **Conservative for Analysis**: Analysis scripts alone don't indicate complete workflow, so excluded
4. **Alignment with Success Criteria**: SC-003 requires ≥80% correct reclassification; including "Raw" and "Model/Models" increases coverage from 13%/31% to 53%/75% of Partially Closed, better positioning for meeting target

### Alternatives Considered

**Alternative A: Keep FR-002/FR-003 Lists Unchanged**
- Maintain original specifications from training data generation
- *Rejected*: Captures only 13% (data) and 31% (code) of Partially Closed publications, likely failing SC-003 ≥80% target

**Alternative B: Include All Partial Completeness ("Results", "Analysis" alone)**
- Maximize coverage by classifying any materials as mostly_open
- *Rejected*: "Results" alone or "Analysis" alone typically insufficient for reproduction; would over-classify as mostly_open

**Alternative C: Use Machine Learning to Determine Thresholds**
- Train classifier on completeness attributes to learn boundary
- *Rejected*: Small sample size (78 data, 55 code Partially Closed); lacks interpretability for scientific transparency

---

## Research Task 3: Hard Precedence Rule Implementation

### Research Question
How can prompts reliably enforce the hard precedence rule (FR-004): substantial access barriers ALWAYS result in mostly_closed classification, regardless of completeness or repository quality?

### Research Findings

#### 2025 Research on LLM Constraint Enforcement

**Instruction Hierarchy Approaches**:
- A 2025 approach proposes instilling hierarchy into LLMs where system messages take precedence over user messages, and user messages over third-party content
- LLM applications establish hierarchical order: system instructions > user instructions > data
- Critical editorial rules should be moved to system prompt, as "the top instruction wins in system-user collisions"

**Limitations and Challenges**:
- System message precedence is "not directly programmed but learned" through supervised/reinforcement learning, making it susceptible to errors or adversarial manipulation
- Model performance "quickly approaches zero when stress tested with an increasing number of guardrails in the system message" (1-20 guardrails)
- System prompts are powerful but "not absolute" - LLMs may ignore parts if conflicting with higher-level alignment guardrails

**Practical Recommendations**:
- Use explicit validation: Don't rely solely on prompt; validate output against rules
- Position critical constraints in system prompt, not user prompt
- Combine with output parsing to catch rule violations

#### Current Implementation Analysis

Existing `SYSTEM_PROMPT` in `/Users/kellycaylor/dev/ef_2026/openness_classifier/prompts.py`:
```python
IMPORTANT: "Available upon request" or "contact the authors" is ALWAYS classified as **closed**.
```

This demonstrates one hard rule enforcement (closed category). The precedence rule for mostly_closed needs similar treatment.

#### Edge Case from Specification

Spec states: "What happens when a statement mentions both a persistent repository (mostly_open) and substantial access barriers like data use agreements (mostly_closed)? → Access barrier always takes precedence (hard rule) - classify as mostly_closed regardless of completeness or repository quality"

This tests whether model can override positive completeness signals when substantial barrier exists.

### Decision: Three-Layer Precedence Enforcement

Implement hard precedence rule using three complementary mechanisms:

**Layer 1: System Prompt Declaration**
```
CRITICAL RULE: Substantial access barriers (data use agreements, confidentiality restrictions,
proprietary terms, "available upon request") ALWAYS result in mostly_closed or closed classification,
regardless of completeness or repository type. This rule has absolute precedence.
```

**Layer 2: Chain-of-Thought Validation Step**
In Step 5 (Apply classification rules), enforce explicit check:
```
5. Apply classification rules:
   - FIRST CHECK: Substantial barrier present? → mostly_closed or closed (STOP, do not consider other factors)
   - If no substantial barrier: assess completeness and repository for mostly_open vs mostly_closed
```

**Layer 3: Post-Processing Validation**
In `parse_classification_response()` function, add validation logic:
```python
def validate_precedence_rule(category: OpennessCategory, reasoning: str) -> OpennessCategory:
    """Enforce hard precedence rule if reasoning mentions substantial barriers."""
    substantial_barriers = [
        "data use agreement", "confidentiality", "proprietary",
        "upon request", "contact author", "restricted access", "DUA"
    ]

    reasoning_lower = reasoning.lower()
    has_substantial_barrier = any(barrier in reasoning_lower for barrier in substantial_barriers)

    # If substantial barrier mentioned but classified as mostly_open or open, override to mostly_closed
    if has_substantial_barrier and category in [OpennessCategory.OPEN, OpennessCategory.MOSTLY_OPEN]:
        return OpennessCategory.MOSTLY_CLOSED

    return category
```

### Rationale

1. **System-Level Positioning**: Following 2025 best practice of placing critical rules in system prompt for maximum precedence
2. **Explicit CoT Integration**: Step 5's "FIRST CHECK" forces model to evaluate barrier before completeness, preventing over-weighting of positive factors
3. **Validation Safety Net**: Post-processing catches cases where model ignores system/CoT instructions, addressing the "not absolute" limitation identified in research
4. **Transparency**: Reasoning field captures whether substantial barrier was detected, enabling debugging and validation
5. **Conservative Approach**: Three-layer redundancy addresses 2025 findings that guardrails can be unreliable under stress

This design acknowledges that "LLMs may still ignore parts of a system prompt" while providing multiple enforcement points.

### Alternatives Considered

**Alternative A: System Prompt Only**
- Rely solely on CRITICAL RULE in system prompt
- *Rejected*: 2025 research shows "model performance quickly approaches zero" with multiple guardrails; single-layer enforcement too fragile

**Alternative B: Pre-Classification Barrier Detection**
- Use separate rule-based system to detect barriers before LLM call
- *Rejected*: Loses nuance of LLM's natural language understanding; "substantial" vs "minor" barrier distinction requires semantic reasoning

**Alternative C: Fine-Tuning for Hard Rules**
- Fine-tune model specifically on precedence rule examples
- *Rejected*: Requires training infrastructure and ongoing maintenance; prompt engineering is more flexible for research context

**Alternative D: Two-Stage Classification (Barriers First, Then Completeness)**
- First API call: detect barriers; second call: classify completeness if no barriers
- *Rejected*: 2x cost and latency (addressed in Task 1 alternatives); error compounding between stages

---

## Research Task 4: Failure Handling and Retry Strategies

### Research Question
What retry strategy with exponential backoff best balances reliability and performance for LLM API classification tasks, given the 5-10 second per-classification target?

### Research Findings

#### 2025 Industry Best Practices

**Exponential Backoff with Jitter**:
- Standard approach: exponential backoff with jitter to "enhance system resilience by scattering retry attempts to avoid thundering herd problem"
- Jitter incorporates randomness into exponential backoff, most recommended for distributed systems and high-concurrency APIs (OpenAI, Anthropic)
- Prevents synchronized retry storms when multiple requests fail simultaneously

**Error Classification**:
- "Distinguishing between transient and permanent errors is important to prevent unnecessary retries"
- Retryable status codes (2025 consensus): {408, 429, 500, 502, 503, 504}
- Non-retryable: 400 (bad request), 401 (unauthorized), 403 (forbidden), 422 (validation error)
- Retry on network errors (connection timeout, DNS failure)

**Configuration Recommendations**:
```
max_retries: 3
initial_delay: 1.0 seconds
max_delay: 60.0 seconds
exponential_base: 2
jitter: enabled (full jitter or decorrelated jitter)
```

**Advanced Patterns**:
- Define retry policies with exponential backoff
- Build fallback chains across providers or models
- Configure circuit breakers that detect failure patterns
- Monitor success rates to detect systemic issues

#### Performance Implications

Given 5-10 second per-classification target:
- No retries: 5-10s baseline
- 3 retries with exponential backoff: 1s + 2s + 4s = 7s additional maximum
- Total worst case: 5s (attempt 1) + 1s (wait) + 5s (attempt 2) + 2s (wait) + 5s (attempt 3) + 4s (wait) + 5s (attempt 4) = 27s
- With jitter, average retry delay: 0.5s + 1s + 2s = 3.5s, typical worst case ~18-20s

For batch processing (300 publications):
- Success rate 95% (no retries needed): 300 × 7.5s = 37.5 min
- Success rate 90% (10% need 1 retry): 300 × 7.5s + 30 × 1.5s = 38.25 min
- Success rate 80% (20% need retries): 300 × 7.5s + 60 × 2s = 39.5 min

All scenarios remain within 25-50 minute target range from SC-006.

#### Implementation Tools

Research recommends:
- **Python Tenacity library**: "decorators and utilities for handling transient failures, rate limits, and validation errors with intelligent backoff strategies"
- **LiteLLM built-in support**: Existing `litellm` dependency (used in current codebase) has native retry configuration
- **Circuit breaker patterns**: For systemic failures (e.g., API down for extended period)

### Decision: 3-Retry Exponential Backoff with Full Jitter

Implement retry strategy using LiteLLM's built-in configuration:

```python
retry_config = {
    "max_retries": 3,
    "initial_delay": 1.0,  # seconds
    "exponential_base": 2.0,
    "max_delay": 60.0,
    "jitter": "full",  # randomize delay between 0 and calculated backoff
    "retryable_status_codes": [408, 429, 500, 502, 503, 504],
    "retry_on_timeout": True,
    "retry_on_connection_error": True,
}
```

**Error Handling Flow**:
1. Attempt 1: Immediate API call
2. Transient failure (429, 503, timeout): Wait 0-1s (jittered), retry
3. Attempt 2: If fails, wait 0-2s (jittered), retry
4. Attempt 3: If fails, wait 0-4s (jittered), retry
5. Attempt 4: If fails, mark as "unclassified", log error reason, continue batch

**Non-Retryable Errors**:
- 400 (malformed request): Log error, mark "unclassified", continue
- 401/403 (auth failure): Raise exception, halt batch (configuration issue)
- 422 (validation error): Log error, mark "unclassified", continue

**Logging Requirements**:
```python
ClassificationFailure(
    publication_id=pub_id,
    error_type="rate_limit" | "timeout" | "server_error" | "malformed_response",
    retry_count=attempts,
    final_status="unclassified",
    error_reason=f"Failed after {attempts} retries: {last_error}"
)
```

### Rationale

1. **Industry Standard**: 3 retries with exponential backoff + jitter is 2025 consensus for LLM APIs
2. **Performance Acceptable**: Worst-case 18-20s per failed request still allows batch completion within 25-50 min target (SC-006)
3. **Jitter Benefits**: Prevents thundering herd if batch processing encounters systemic rate limits
4. **Error Classification**: Distinguishing transient (retry) from permanent (don't retry) optimizes resource utilization
5. **Graceful Degradation**: FR-010 requirement to continue processing after failures is met with "unclassified" marking
6. **Observability**: Logging enables post-batch analysis of failure patterns

**Initial delay of 1.0s** balances responsiveness (not too long for first retry) with API rate limit recovery time.

### Alternatives Considered

**Alternative A: Fixed Delay Retry**
- Retry after fixed 2s delay (no exponential growth)
- *Rejected*: Doesn't adapt to increasing backpressure; more likely to hit rate limits on subsequent retries

**Alternative B: 5 Retries with Longer Delays**
- max_retries=5, initial_delay=2s
- *Rejected*: Worst case 40+ seconds per request exceeds acceptable latency; diminishing returns after 3 retries

**Alternative C: No Jitter (Pure Exponential Backoff)**
- Use deterministic delays (1s, 2s, 4s)
- *Rejected*: 2025 research emphasizes jitter for "distributed systems and high-concurrency APIs"; batch processing may trigger synchronized retries

**Alternative D: Immediate Retry (No Initial Delay)**
- Retry immediately on first failure, then exponential
- *Rejected*: For rate limit errors (429), immediate retry likely to fail again; wastes API quota

**Alternative E: External Retry Library (Tenacity)**
- Add new dependency for retry logic instead of using LiteLLM built-in
- *Rejected*: Unnecessary complexity when LiteLLM already provides retry configuration; avoids dependency bloat

---

## Research Task 5: Few-Shot Example Selection with Refined Taxonomy

### Research Question
Should the kNN example selection strategy be modified to favor examples near the mostly_open/mostly_closed boundary to better teach the model this refined distinction?

### Research Findings

#### Current Implementation Analysis

From `/Users/kellycaylor/dev/ef_2026/openness_classifier/prompts.py`:

```python
def select_knn_examples(
    statement: str,
    training_examples: List[TrainingExample],
    embedding_model: EmbeddingModel,
    k: int = 5,
    diversify: bool = True
) -> List[TrainingExample]:
    """Select k most similar training examples using kNN with diversity."""
```

**Current Strategy**:
- Cosine similarity between statement and training examples (semantic similarity)
- k=5 examples selected
- `diversify=True`: Ensures at least one example from each category if available
- First pass: one example per unique label from top candidates
- Second pass: fill remaining slots with most similar

**Effectiveness**: This is a well-designed diversity-aware kNN approach that balances similarity and label representation.

#### 2025 Research on Few-Shot Selection

**Skill-Based Selection**:
- Skill-KNN is a "skill-based few-shot selection method" addressing bias from pre-trained embeddings toward surface features
- Recent HED-LM approach "filters candidates based on Euclidean distance and re-ranks them using contextual relevance scored by LLMs"
- Key insight: "Performance depends on the quality of selected examples"

**Boundary Cases in kNN**:
- In edited kNN, "data points that do not affect the decision boundary are permanently removed"
- Training examples surrounded by other classes are "class outliers"
- kNN "can naturally produce highly irregular decision boundaries" which is "often successful when decision boundary is very irregular"

**General Principle**: "K-Nearest Neighbor (KNN) selects relevant exemplars to improve Few-Shot prompts by finding the most similar examples to the input query, enhancing model accuracy"

#### Boundary-Focused Selection Analysis

**Arguments FOR boundary-focused selection**:
- Mostly_open vs mostly_closed distinction IS the refined taxonomy's primary contribution
- Examples at boundary would demonstrate nuanced reasoning needed for difficult cases
- Could improve calibration for Partially Closed publications (which straddle boundary)

**Arguments AGAINST boundary-focused selection**:
- Current diversity approach already ensures representation from all 4 categories, including both middle categories
- Semantic similarity (cosine distance) captures domain-relevant features better than label-space proximity
- Boundary examples may be inherently ambiguous or inconsistent, confusing the model
- 2025 research (Skill-KNN) warns against biasing selection toward specific attributes over semantic relevance

#### Training Data Distribution Context

From Task 2 analysis:
- Partially Closed data: 78 publications (30% of data statements)
- Partially Closed code: 55 publications (39% of code statements)
- These represent the publications most likely to be reclassified by refined taxonomy

The large proportion of Partially Closed suggests boundary cases are well-represented in training data already.

#### Simulation: Impact of Boundary Bias

Consider query: "Raw data available via institutional repository with registration"

**Current diversity approach** (similarity + one per category):
- Example 1: Open (high similarity, GitHub + open license)
- Example 2: Mostly_open (high similarity, Zenodo + registration)
- Example 3: Mostly_closed (moderate similarity, DUA required)
- Example 4: Closed (moderate similarity, contact author)
- Example 5: Mostly_open (next most similar)

**Boundary-focused approach** (favor mostly_open/mostly_closed):
- Example 1: Mostly_open (boundary case, all data + registration)
- Example 2: Mostly_closed (boundary case, raw data + DUA)
- Example 3: Mostly_open (boundary case, GitHub + all code)
- Example 4: Mostly_closed (boundary case, partial data + restrictions)
- Example 5: Mostly_open or Mostly_closed

**Trade-off**: Boundary approach loses representation of clear open/closed cases, which provide anchoring for the taxonomy's extremes. This could reduce model's ability to distinguish "mostly_closed" from "fully closed."

### Decision: Maintain Current Diversity-Aware kNN Selection

Keep existing `select_knn_examples()` implementation with `diversify=True` and semantic similarity (cosine distance).

**No modifications required** for refined taxonomy.

### Rationale

1. **Diversity > Boundary Focus**: Current approach's guarantee of "at least one example from each category" ensures model sees both boundary cases (mostly_open, mostly_closed) AND anchoring cases (open, closed)
2. **Semantic Similarity is Key**: 2025 research emphasizes that "finding the most similar examples to the input query" enhances accuracy; boundary proximity is less relevant than domain similarity
3. **Well-Represented Boundaries**: 30-39% of training data is Partially Closed, so boundary cases are already well-represented in kNN candidates
4. **Irregular Decision Boundary**: The mostly_open/mostly_closed distinction has irregular boundary (completeness + barriers + repository type); research shows kNN handles this naturally without boundary-specific selection
5. **Avoid Ambiguity**: Boundary examples may be inherently ambiguous or represent labeling inconsistencies; prioritizing these could reduce classification confidence
6. **Parsimony**: If current approach is working (baseline accuracy before refinement), minimizing changes reduces risk

**Chain-of-thought prompts (Task 1 decision) address the refined taxonomy teaching** more directly than example selection; explicit attribute reasoning guides the model regardless of which examples are shown.

### Alternatives Considered

**Alternative A: Favor Mostly_Open and Mostly_Closed Examples**
- Modify selection to prioritize k=3-4 boundary cases, k=1-2 anchoring cases
- *Rejected*: Loses anchor representation; research warns against biasing away from semantic similarity

**Alternative B: Separate Example Pools by Category**
- Force k=2 mostly_open, k=2 mostly_closed, k=1 rotating
- *Rejected*: Overly rigid; query may be clearly open or closed, not need boundary examples

**Alternative C: Dynamic Selection Based on Confidence**
- If model confidence is low, add more boundary examples adaptively
- *Rejected*: Requires multiple API calls (first classification, then retry with different examples); 2x cost and complexity

**Alternative D: Skill-KNN or HED-LM Hybrid Approach**
- Implement 2025 Skill-KNN or HED-LM re-ranking
- *Rejected*: Requires additional LLM calls for relevance scoring (HED-LM) or skill-based filtering logic (Skill-KNN); complexity not justified without evidence of current approach failing

**Alternative E: Increase k to 7-10 Examples**
- More examples ensures better boundary representation
- *Rejected*: Longer prompts increase API cost and latency; diminishing returns beyond k=5-7 for few-shot learning

---

## Summary of Decisions and Implementation Impact

| Research Task | Decision | Implementation Changes Required |
|--------------|----------|--------------------------------|
| **1. Prompt Engineering** | 5-step structured CoT with explicit attribute checklist | Modify `DATA_CLASSIFICATION_TEMPLATE` and `CODE_CLASSIFICATION_TEMPLATE` in `prompts.py` |
| **2. Completeness Indicators** | Add "Raw" to data list; add "Model"/"Models" to code list | Update FR-002/FR-003 in spec; document in validation logic |
| **3. Hard Precedence Rule** | Three-layer enforcement (system prompt + CoT + validation) | Add CRITICAL RULE to `SYSTEM_PROMPT`; add Step 5 check; implement `validate_precedence_rule()` in `prompts.py` |
| **4. Retry Strategy** | 3-retry exponential backoff with full jitter (1s, 2s, 4s) | Configure LiteLLM retry params in `classifier.py`; add `ClassificationFailure` logging in `batch.py` |
| **5. Example Selection** | Maintain current diversity-aware kNN | No changes required |

### Risk Assessment

| Risk | Likelihood | Mitigation |
|------|-----------|------------|
| 5-step CoT too verbose, reduces model coherence | Low | Prompt length remains <500 tokens; 2025 LLMs handle structured prompts well |
| Updated completeness indicators over-classify as mostly_open | Medium | Validate against ground truth (SC-003); adjust threshold if <80% accuracy |
| Hard precedence rule still ignored by LLM in edge cases | Low | Three-layer enforcement provides redundancy; post-processing catches violations |
| Retry strategy increases batch processing time beyond target | Low | Math shows 39.5 min worst case within 25-50 min range (SC-006) |
| Current example selection underperforms for refined taxonomy | Low | Diversity approach already includes boundary cases; CoT handles teaching |

### Next Steps

1. **Update Specification**: Revise FR-002/FR-003 with refined completeness indicators
2. **Implement Phase 1 Design**: Create `data-model.md` with `ClassificationFailure` entity and retry configuration schema
3. **Generate Implementation Tasks**: Run `/speckit.tasks` to create dependency-ordered task list for Phase 2

---

## References

### Web Sources

**Prompt Engineering and Chain-of-Thought**:
- [Prompt Engineering Best Practices 2025](https://garrettlanders.com/prompt-engineering-guide-2025/)
- [Chain-of-Thought Prompting | Prompt Engineering Guide](https://www.promptingguide.ai/techniques/cot)
- [Prompt Engineering 101: The "Chain of Thought" Technique Explained](https://www.aisupersmart.com/master-chain-of-thought-prompting-guide/)
- [The Ultimate Guide to Prompt Engineering in 2025 | Lakera](https://www.lakera.ai/blog/prompt-engineering-guide)

**Hard Precedence Rules and Constraints**:
- [The Instruction Hierarchy: Training LLMs to Prioritize Privileged Instructions](https://arxiv.org/html/2404.13208v1)
- [System Prompts Versus User Prompts - AI Muse](https://aimuse.blog/article/2025/06/14/system-prompts-versus-user-prompts-empirical-lessons-from-an-18-model-llm-benchmark-on-hard-constraints)
- [Guide to Writing System Prompts: The Hidden Force Behind Every AI Interaction](https://saharaai.com/blog/writing-ai-system-prompts)

**Retry Strategies and Exponential Backoff**:
- [Mastering Retry Logic Agents: A Deep Dive into 2025 Best Practices](https://sparkco.ai/blog/mastering-retry-logic-agents-a-deep-dive-into-2025-best-practices)
- [How to Implement Retry Logic for LLM API Failures in 2025 | Markaicode](https://markaicode.com/llm-api-retry-logic-implementation/)
- [Retries, fallbacks, and circuit breakers in LLM apps: what to use when](https://portkey.ai/blog/retries-fallbacks-and-circuit-breakers-in-llm-apps/)
- [Building Unstoppable AI: 5 Essential Resilience Patterns](https://medium.com/@sammokhtari/building-unstoppable-ai-5-essential-resilience-patterns-d356d47b6a01)

**Few-Shot Learning and kNN Selection**:
- [Skill-Based Few-Shot Selection for In-Context Learning](https://arxiv.org/abs/2305.14210)
- [K-Nearest Neighbor (KNN) Prompting: Find Good Few-Shot Exemplars](https://learnprompting.org/docs/advanced/few_shot/k_nearest_neighbor_knn)
- [Few-Shot Optimization for Sensor Data Using Large Language Models](https://pmc.ncbi.nlm.nih.gov/articles/PMC12157906/)

### Training Data

- `/Users/kellycaylor/dev/ef_2026/resources/abpoll-open-b71bd12/data/processed/articles_reviewed.csv`
  - 303 publications with human-coded classifications
  - 78 Partially Closed data statements analyzed for completeness attributes
  - 55 Partially Closed code statements analyzed for completeness attributes

### Codebase References

- `/Users/kellycaylor/dev/ef_2026/openness_classifier/prompts.py`: Current prompt templates and kNN selection implementation
- `/Users/kellycaylor/dev/ef_2026/specs/002-refine-classification-taxonomy/spec.md`: Feature requirements (FR-001 through FR-010)
- `/Users/kellycaylor/dev/ef_2026/specs/002-refine-classification-taxonomy/plan.md`: Implementation plan and research task definitions

---

**End of Research Report**
