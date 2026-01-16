# Data Model: Refined Classification Taxonomy

**Feature**: Refined Classification Taxonomy
**Phase**: 1 - Design Documentation
**Date**: 2026-01-16

## Overview

This document defines the data structures and validation rules for the refined classification taxonomy feature. The taxonomy distinguishes between "mostly_open" and "mostly_closed" classifications based on data/code completeness attributes, access barriers, and repository persistence.

The data model supports:
- Backward-compatible 4-category ordinal taxonomy
- Explicit completeness attribute tracking for validation
- Access barrier categorization with hard precedence rules
- Failure handling and retry state management

---

## 1. Existing Entities

### 1.1 OpennessCategory (Enum)

**Source**: `openness_classifier/core.py` (lines 29-80)

**Purpose**: Defines the 4-category ordinal taxonomy for data/code openness classification. This enum provides the core classification categories with built-in ordering semantics.

**Values**:
```python
OPEN = "open"           # Public repository, no barriers
MOSTLY_OPEN = "mostly_open"     # Minor barriers, high completeness
MOSTLY_CLOSED = "mostly_closed"  # Substantial barriers or low completeness
CLOSED = "closed"         # Unavailable or "upon request"
```

**Ordinal Relationship**:
```
open > mostly_open > mostly_closed > closed
```

**Methods**:
- `from_string(value: str) -> OpennessCategory`: Parse category from string, handling various formats
- `__lt__`, `__le__`: Comparison operators for ordinal ranking

**Validation Rules**:
- String values must normalize to one of the four categories
- Supports backward compatibility with articles_reviewed.csv format:
  - "Partially Closed" maps to `MOSTLY_CLOSED`
  - "Partially Open" maps to `MOSTLY_OPEN`

**Examples**:
```python
# Parse from different formats
OpennessCategory.from_string("mostly_open")     # MOSTLY_OPEN
OpennessCategory.from_string("Partially Open")  # MOSTLY_OPEN
OpennessCategory.from_string("mostly closed")   # MOSTLY_CLOSED

# Ordinal comparison
OpennessCategory.MOSTLY_OPEN > OpennessCategory.MOSTLY_CLOSED  # True
OpennessCategory.CLOSED < OpennessCategory.OPEN  # True
```

**Enhancements for Refined Taxonomy**: No changes needed - the enum already supports the 4-category structure. The refinement focuses on improving the _classification logic_ that assigns these categories, not the categories themselves.

---

### 1.2 Classification (Dataclass)

**Source**: `openness_classifier/core.py` (lines 187-223)

**Purpose**: Represents the result of classifying a data or code availability statement. Contains the assigned category, confidence score, reasoning, and metadata for reproducibility.

**Fields**:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `category` | `OpennessCategory` | Yes | Classified openness category |
| `statement_type` | `ClassificationType` | Yes | Whether this is data or code classification |
| `confidence_score` | `float` | Yes | Model confidence (0-1), default 0.8 |
| `reasoning` | `str` | No | Chain-of-thought reasoning from LLM |
| `timestamp` | `datetime` | Yes | When classification was made (UTC) |
| `model_config` | `LLMConfiguration` | No | LLM configuration for reproducibility |
| `few_shot_example_ids` | `List[str]` | Yes | IDs of training examples used in prompt |

**Validation Rules**:
- `confidence_score` must be in range [0.0, 1.0] (validated in `__post_init__`)
- `timestamp` defaults to `datetime.utcnow()` if not provided
- `few_shot_example_ids` defaults to empty list if not provided

**Relationships**:
- Contains `OpennessCategory` enum value
- Contains `ClassificationType` enum value
- Optionally references `LLMConfiguration` for reproducibility tracking
- References training examples by ID (strings matching publication IDs in articles_reviewed.csv)

**Enhancement Requirements for Refined Taxonomy**:

The `reasoning` field is critical for the refined taxonomy. Per FR-008 and SC-004, the reasoning MUST:
- Explicitly mention completeness attributes when classifying as `mostly_open` or `mostly_closed`
- Explain which access barriers influenced the decision (especially for FR-004 hard precedence rule)
- Identify repository type (persistent vs non-persistent) when relevant

**Example** (mostly_open classification):
```python
Classification(
    category=OpennessCategory.MOSTLY_OPEN,
    statement_type=ClassificationType.DATA,
    confidence_score=0.85,
    reasoning=(
        "Data statement indicates 'Raw; Results; Source Data available with registration'. "
        "Completeness: All necessary data types (Raw, Results, Source Data) are available. "
        "Access barrier: Registration required is a minor barrier. "
        "Repository: Zenodo (persistent repository with DOI). "
        "Classification: mostly_open because high completeness outweighs minor barrier."
    ),
    timestamp=datetime.utcnow(),
    model_config=LLMConfiguration(...),
    few_shot_example_ids=["doi:10.1234/example1", "doi:10.5678/example2"]
)
```

**Example** (mostly_closed classification with hard precedence):
```python
Classification(
    category=OpennessCategory.MOSTLY_CLOSED,
    statement_type=ClassificationType.DATA,
    confidence_score=0.90,
    reasoning=(
        "Data statement indicates 'All data available via data use agreement'. "
        "Completeness: All data types mentioned (high completeness). "
        "Access barrier: Data use agreement is a substantial barrier (hard precedence rule). "
        "Repository: Institutional repository (persistent). "
        "Classification: mostly_closed because substantial barrier takes precedence over completeness."
    ),
    timestamp=datetime.utcnow(),
    model_config=LLMConfiguration(...),
    few_shot_example_ids=["doi:10.1234/example3", "doi:10.5678/example4"]
)
```

**Serialization**:
- `to_dict()` method converts to JSON-serializable dictionary
- Used by `ClassificationLogger` for audit trail (JSON Lines format)

---

### 1.3 ClassificationType (Enum)

**Source**: `openness_classifier/core.py` (lines 82-85)

**Purpose**: Distinguish between data and code availability statements.

**Values**:
```python
DATA = "data"
CODE = "code"
```

**Enhancements for Refined Taxonomy**: No changes needed. The refined taxonomy applies to both data and code classifications with parallel rules (FR-002 for data, FR-003 for code).

---

### 1.4 LLMConfiguration (Dataclass)

**Source**: `openness_classifier/core.py` (lines 127-184)

**Purpose**: Configuration for LLM provider, tracked for reproducibility in accordance with FAIR principles.

**Fields**:

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `provider` | `LLMProviderType` | - | LLM provider (claude, openai, ollama) |
| `model_name` | `str` | - | Model identifier (e.g., 'claude-3-5-sonnet-20241022') |
| `temperature` | `float` | 0.1 | Sampling temperature (low for consistency) |
| `max_tokens` | `int` | 500 | Maximum response tokens |
| `top_p` | `float` | 0.95 | Nucleus sampling parameter |
| `api_endpoint` | `str` | None | Optional custom API endpoint (for Ollama) |
| `api_key_hash` | `str` | None | SHA-256 hash of API key for audit trail |
| `configuration_timestamp` | `datetime` | `utcnow()` | When configuration was created |

**Validation Rules**:
- `provider` must be one of: `CLAUDE`, `OPENAI`, `OLLAMA`
- `temperature` should be low (0.1) for classification consistency
- `max_tokens` may need to increase for refined taxonomy to accommodate longer reasoning outputs (FR-008 requires explicit completeness reasoning)

**Enhancement Considerations**:
- **Performance Goal**: SC-006 requires 5-10 seconds per classification. If refined prompts with step-by-step reasoning increase latency beyond this threshold, consider adjusting `max_tokens` or `temperature`.
- **Reasoning Quality**: The refined taxonomy requires more detailed reasoning (FR-007, FR-008). May need to increase `max_tokens` from 500 to 750-1000 to ensure complete reasoning output.

**Serialization**:
- `to_dict()`, `from_dict()` for JSON serialization
- `to_json()` for logging and reproducibility tracking

**Enhancements for Refined Taxonomy**: No structural changes needed. May adjust default `max_tokens` if testing reveals truncated reasoning outputs.

---

### 1.5 LLMProvider (Class)

**Source**: `openness_classifier/core.py` (lines 226-320)

**Purpose**: Unified LLM provider interface using LiteLLM. Supports Claude, OpenAI, and Ollama with retry logic.

**Key Methods**:

```python
def complete(
    prompt: str,
    max_retries: int = 3,
    retry_delay: float = 1.0
) -> str:
    """Generate completion with exponential backoff retry logic."""
```

**Existing Retry Logic**:
- Supports up to `max_retries` attempts (default: 3)
- Exponential backoff: `delay *= 2` after each retry
- Retries on transient errors: rate limits, timeouts, service unavailable (503, 504, 529)
- Raises `LLMError` with `retryable` flag after exhausting retries

**Validation Rules**:
- Provider must be configured before calling `complete()`
- API keys must be set via environment variables (ANTHROPIC_API_KEY, OPENAI_API_KEY, etc.)

**Enhancement Requirements for Refined Taxonomy**:

The existing retry logic already supports FR-010 requirements:
- ✅ Retry 3 times with exponential backoff
- ✅ Distinguish retryable vs non-retryable errors
- ✅ Raise `LLMError` with context after failure

**Additional requirements**:
- Batch processing (in `batch.py`) must catch `LLMError`, log the failure, and continue processing
- Need to track failures in `ClassificationFailure` structure (see section 3.3)

**Example** (successful retry):
```python
provider = LLMProvider(config)
try:
    response = provider.complete(prompt, max_retries=3, retry_delay=1.0)
except LLMError as e:
    # Log failure, mark as "unclassified", continue batch
    logger.log_error(publication_id, e)
```

---

## 2. New Supporting Structures

### 2.1 CompletenessAttributes (Dataclass)

**Purpose**: Represents data/code completeness indicators extracted from statements or ground truth. Used for validation (FR-002, FR-003) and reasoning quality assessment (SC-004).

**Fields**:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `completeness_type` | `Literal["data", "code"]` | Yes | Whether this describes data or code completeness |
| `attributes` | `List[str]` | Yes | List of completeness indicators (e.g., ["Raw", "Results", "Source Data"]) |
| `is_mostly_open` | `bool` | Yes | Whether these attributes meet mostly_open criteria |
| `raw_value` | `str` | No | Original value from articles_reviewed.csv (e.g., "Raw; Results; Source Data") |

**Validation Rules**:

**For Data Completeness** (FR-002):
```python
MOSTLY_OPEN_DATA_ATTRIBUTES = [
    "All",
    "Raw; Results; Source Data",
    "Raw; Results"
]

def is_mostly_open_data(raw_value: str) -> bool:
    """Check if data completeness indicates mostly_open."""
    return raw_value.strip() in MOSTLY_OPEN_DATA_ATTRIBUTES
```

**For Code Completeness** (FR-003):
```python
MOSTLY_OPEN_CODE_ATTRIBUTES = [
    "All",
    "Download; Process; Analysis; Figures",
    "Processing; Generate Results",
    "Processing; Results",
    "Models; Results",
    "Models; Analysis",
    "Analysis; Figures",
    "Model; Figures",
    "Results; Figures",
    "Generate Results; Figures"
]

def is_mostly_open_code(raw_value: str) -> bool:
    """Check if code completeness indicates mostly_open."""
    return raw_value.strip() in MOSTLY_OPEN_CODE_ATTRIBUTES
```

**Relationships**:
- Used to validate `Classification` reasoning outputs (SC-004: 90% must mention completeness)
- Extracted from articles_reviewed.csv `data_included` and `code_included` columns for ground truth validation
- Can be extracted from `Classification.reasoning` field via text parsing for reasoning quality assessment

**Example** (from ground truth):
```python
# From articles_reviewed.csv row 8
data_completeness = CompletenessAttributes(
    completeness_type="data",
    attributes=["Raw"],
    is_mostly_open=False,  # "Raw" alone not in mostly_open list
    raw_value="Raw"
)

# From articles_reviewed.csv row 28
data_completeness = CompletenessAttributes(
    completeness_type="data",
    attributes=["Raw"],
    is_mostly_open=True,  # "Raw" in context with sufficient detail
    raw_value="Raw"
)

code_completeness = CompletenessAttributes(
    completeness_type="code",
    attributes=["Model"],
    is_mostly_open=False,  # "Model" alone not in mostly_open list
    raw_value="Model"
)
```

**Example** (extracted from reasoning):
```python
# Extract from Classification.reasoning
reasoning = (
    "Data statement indicates 'Raw; Results; Source Data available with registration'. "
    "Completeness: All necessary data types (Raw, Results, Source Data) are available."
)

# Parsed attributes
completeness = CompletenessAttributes(
    completeness_type="data",
    attributes=["Raw", "Results", "Source Data"],
    is_mostly_open=True,  # Matches FR-002 criteria
    raw_value="Raw; Results; Source Data"
)
```

**Implementation Notes**:
- Text parsing function needed to extract attributes from reasoning
- Validation function to check if reasoning mentions completeness (for SC-004)
- Comparison function to align classifier output with ground truth (for SC-003)

---

### 2.2 AccessBarrier (Dataclass)

**Purpose**: Categorize access barriers for hard precedence rule enforcement (FR-004, FR-005). Distinguishes minor barriers from substantial barriers.

**Fields**:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `barrier_type` | `Literal["none", "minor", "substantial"]` | Yes | Barrier severity category |
| `description` | `str` | Yes | Specific barrier mentioned (e.g., "data use agreement") |
| `forces_mostly_closed` | `bool` | Yes | Whether this barrier overrides completeness (FR-004) |
| `mentioned_in_statement` | `bool` | No | Whether barrier was explicit in original statement |

**Validation Rules**:

**Substantial Barriers** (FR-004 - always force `mostly_closed`):
```python
SUBSTANTIAL_BARRIERS = [
    "data use agreement",
    "confidentiality restrictions",
    "confidentiality agreement",
    "proprietary terms",
    "proprietary restrictions",
    "not accessible",
    "unavailable",
    "upon request"  # Edge case: may be closed rather than mostly_closed
]

def is_substantial_barrier(description: str) -> bool:
    """Check if barrier is substantial (forces mostly_closed)."""
    desc_lower = description.lower()
    return any(barrier in desc_lower for barrier in SUBSTANTIAL_BARRIERS)
```

**Minor Barriers** (FR-005 - can be `mostly_open` with high completeness):
```python
MINOR_BARRIERS = [
    "registration",
    "registration required",
    "institutional access",
    "login required",
    "account required"
]

def is_minor_barrier(description: str) -> bool:
    """Check if barrier is minor (allows mostly_open with completeness)."""
    desc_lower = description.lower()
    return any(barrier in desc_lower for barrier in MINOR_BARRIERS)
```

**Hard Precedence Rule** (FR-004):
```python
def apply_barrier_precedence(
    barrier: AccessBarrier,
    completeness: CompletenessAttributes
) -> OpennessCategory:
    """Apply hard precedence rule: substantial barriers override completeness."""
    if barrier.forces_mostly_closed:
        return OpennessCategory.MOSTLY_CLOSED  # Always, regardless of completeness
    elif barrier.barrier_type == "minor" and completeness.is_mostly_open:
        return OpennessCategory.MOSTLY_OPEN
    elif barrier.barrier_type == "none" and completeness.is_mostly_open:
        return OpennessCategory.OPEN
    else:
        return OpennessCategory.MOSTLY_CLOSED
```

**Relationships**:
- Extracted from `Classification.reasoning` field to validate precedence rule application
- Used in prompt engineering (FR-007) to guide LLM decision-making

**Examples**:

```python
# Substantial barrier - forces mostly_closed
barrier1 = AccessBarrier(
    barrier_type="substantial",
    description="data use agreement",
    forces_mostly_closed=True,
    mentioned_in_statement=True
)

# Minor barrier - allows mostly_open with completeness
barrier2 = AccessBarrier(
    barrier_type="minor",
    description="registration required",
    forces_mostly_closed=False,
    mentioned_in_statement=True
)

# No barrier
barrier3 = AccessBarrier(
    barrier_type="none",
    description="publicly available",
    forces_mostly_closed=False,
    mentioned_in_statement=True
)
```

**Example** (edge case from spec - persistent repo + DUA):
```python
# Statement: "All data available on Zenodo via data use agreement"
completeness = CompletenessAttributes(
    completeness_type="data",
    attributes=["All"],
    is_mostly_open=True,  # High completeness
    raw_value="All"
)

barrier = AccessBarrier(
    barrier_type="substantial",
    description="data use agreement",
    forces_mostly_closed=True,  # Hard precedence
    mentioned_in_statement=True
)

# Apply precedence rule
category = apply_barrier_precedence(barrier, completeness)
# Result: MOSTLY_CLOSED (barrier overrides completeness and repository quality)
```

**Implementation Notes**:
- Prompt templates (FR-007) must explicitly instruct LLM to identify and categorize barriers
- Validation function to check if reasoning mentions barriers (for SC-004)
- Parser to extract barrier types from reasoning output

---

### 2.3 ClassificationFailure (Dataclass)

**Purpose**: Track failed classification attempts for FR-010 (retry and failure handling). Enables graceful degradation and audit trail for unclassified publications.

**Fields**:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `publication_id` | `str` | Yes | Unique identifier (DOI or equivalent) |
| `statement_type` | `ClassificationType` | Yes | Whether this was data or code classification |
| `error_type` | `str` | Yes | Error category (timeout, rate_limit, malformed_response, etc.) |
| `retry_count` | `int` | Yes | Number of retry attempts (max 3 per FR-010) |
| `final_status` | `Literal["unclassified"]` | Yes | Always "unclassified" after failure |
| `error_reason` | `str` | Yes | Detailed error message for debugging |
| `timestamp` | `datetime` | Yes | When final failure occurred (UTC) |
| `original_statement` | `str` | No | The statement that failed classification (truncated for log size) |

**Validation Rules**:
- `retry_count` should be <= 3 (per FR-010 retry limit)
- `final_status` is always "unclassified" (no partial classifications)
- `error_type` should match LLMError categories: timeout, rate_limit, malformed_response, api_error, etc.

**State Transitions**:

```
PENDING → RETRY_1 → RETRY_2 → RETRY_3 → UNCLASSIFIED (failure)
                                    ↘
                                    CLASSIFIED (success)
```

**Relationships**:
- Created from `LLMError` exception after exhausting retries
- Logged by `ClassificationLogger.log_error()`
- Tracked in batch processing to continue processing remaining publications

**Example** (timeout failure):
```python
failure = ClassificationFailure(
    publication_id="doi:10.1234/example",
    statement_type=ClassificationType.DATA,
    error_type="timeout",
    retry_count=3,
    final_status="unclassified",
    error_reason="LLM request failed after 3 attempts: Request timeout after 30s",
    timestamp=datetime.utcnow(),
    original_statement="Data available at..."[:500]
)
```

**Example** (rate limit failure):
```python
failure = ClassificationFailure(
    publication_id="doi:10.5678/example",
    statement_type=ClassificationType.CODE,
    error_type="rate_limit",
    retry_count=3,
    final_status="unclassified",
    error_reason="LLM request failed after 3 attempts: Rate limit exceeded",
    timestamp=datetime.utcnow(),
    original_statement="Code available on GitHub..."[:500]
)
```

**Serialization**:
```python
def to_dict(self) -> Dict[str, Any]:
    """Convert to dictionary for JSON logging."""
    return {
        'publication_id': self.publication_id,
        'statement_type': self.statement_type.value,
        'error_type': self.error_type,
        'retry_count': self.retry_count,
        'final_status': self.final_status,
        'error_reason': self.error_reason,
        'timestamp': self.timestamp.isoformat(),
        'original_statement': self.original_statement,
    }
```

**Implementation Notes**:
- Batch processing loop must catch `LLMError`, create `ClassificationFailure`, log, and continue
- Failures logged to JSON Lines file for post-processing analysis
- Summary statistics: track failure rate by error type for monitoring

---

## 3. Validation Rules

### 3.1 Completeness-Based Classification Rules

**Data Completeness** (FR-002):

A data statement qualifies as `mostly_open` if `data_included` is one of:
- "All"
- "Raw; Results; Source Data"
- "Raw; Results"

**Validation Function**:
```python
def validate_data_completeness(
    classification: Classification,
    ground_truth: CompletenessAttributes
) -> bool:
    """
    Validate that classification aligns with data completeness criteria.

    Returns True if:
    - Classification is mostly_open AND ground_truth.is_mostly_open is True
    - Classification is mostly_closed AND ground_truth.is_mostly_open is False
    """
    if ground_truth.completeness_type != "data":
        raise ValueError("Expected data completeness attributes")

    if ground_truth.is_mostly_open:
        return classification.category in [
            OpennessCategory.OPEN,
            OpennessCategory.MOSTLY_OPEN
        ]
    else:
        return classification.category in [
            OpennessCategory.MOSTLY_CLOSED,
            OpennessCategory.CLOSED
        ]
```

**Code Completeness** (FR-003):

A code statement qualifies as `mostly_open` if `code_included` is one of:
- "All"
- "Download; Process; Analysis; Figures"
- "Processing; Generate Results"
- "Processing; Results"
- "Models; Results"
- "Models; Analysis"
- "Analysis; Figures"
- "Model; Figures"
- "Results; Figures"
- "Generate Results; Figures"

**Validation Function**:
```python
def validate_code_completeness(
    classification: Classification,
    ground_truth: CompletenessAttributes
) -> bool:
    """
    Validate that classification aligns with code completeness criteria.

    Returns True if:
    - Classification is mostly_open AND ground_truth.is_mostly_open is True
    - Classification is mostly_closed AND ground_truth.is_mostly_open is False
    """
    if ground_truth.completeness_type != "code":
        raise ValueError("Expected code completeness attributes")

    if ground_truth.is_mostly_open:
        return classification.category in [
            OpennessCategory.OPEN,
            OpennessCategory.MOSTLY_OPEN
        ]
    else:
        return classification.category in [
            OpennessCategory.MOSTLY_CLOSED,
            OpennessCategory.CLOSED
        ]
```

**Success Criteria** (SC-003):
- 80% of "Partially Closed" publications with mostly_open completeness attributes should be reclassified as `mostly_open`
- 80% of "Partially Closed" publications without mostly_open attributes should remain `mostly_closed`

---

### 3.2 Access Barrier Precedence Rule (FR-004)

**Hard Precedence Rule**: Substantial access barriers ALWAYS force `mostly_closed` classification, regardless of completeness or repository type.

**Validation Function**:
```python
def validate_barrier_precedence(
    classification: Classification,
    barrier: AccessBarrier,
    completeness: CompletenessAttributes
) -> bool:
    """
    Validate that access barrier precedence rule was applied correctly.

    Returns True if:
    - Substantial barrier → classification is mostly_closed or closed
    - Minor barrier + high completeness → classification can be mostly_open or open
    """
    if barrier.forces_mostly_closed:
        # Hard rule: substantial barrier must result in mostly_closed or closed
        return classification.category in [
            OpennessCategory.MOSTLY_CLOSED,
            OpennessCategory.CLOSED
        ]
    elif barrier.barrier_type == "minor" and completeness.is_mostly_open:
        # Minor barrier with completeness can be mostly_open
        return classification.category in [
            OpennessCategory.MOSTLY_OPEN,
            OpennessCategory.OPEN
        ]
    else:
        # Default: mostly_closed or closed
        return classification.category in [
            OpennessCategory.MOSTLY_CLOSED,
            OpennessCategory.CLOSED
        ]
```

**Test Cases** (from spec edge cases):

1. **Persistent repository + DUA**:
   - Barrier: Substantial ("data use agreement")
   - Completeness: High ("All")
   - Repository: Persistent (Zenodo)
   - Expected: `mostly_closed` (barrier precedence)

2. **GitHub + All code**:
   - Barrier: None
   - Completeness: High ("All")
   - Repository: Non-persistent (GitHub)
   - Expected: `mostly_open` (completeness outweighs non-persistent repo)

3. **Registration + High completeness**:
   - Barrier: Minor ("registration required")
   - Completeness: High ("Raw; Results; Source Data")
   - Repository: Persistent (Figshare)
   - Expected: `mostly_open` (FR-005)

---

### 3.3 Reasoning Quality Validation (FR-008, SC-004)

**Requirement**: Classification reasoning must explicitly mention completeness attributes when classifying as `mostly_open` or `mostly_closed`.

**Success Criteria** (SC-004): 90% of `mostly_open` and `mostly_closed` classifications must explicitly mention completeness attributes.

**Validation Function**:
```python
def validate_reasoning_quality(classification: Classification) -> bool:
    """
    Validate that reasoning explicitly mentions completeness attributes.

    Returns True if reasoning contains completeness indicators for
    mostly_open or mostly_closed classifications.
    """
    if classification.category not in [
        OpennessCategory.MOSTLY_OPEN,
        OpennessCategory.MOSTLY_CLOSED
    ]:
        return True  # Only validate refined categories

    if not classification.reasoning:
        return False

    reasoning_lower = classification.reasoning.lower()

    # Check for completeness keywords
    completeness_keywords = [
        "completeness", "all", "raw", "results", "source data",
        "download", "process", "analysis", "figures", "models",
        "processing", "generate results"
    ]

    has_completeness = any(kw in reasoning_lower for kw in completeness_keywords)

    # Check for barrier keywords
    barrier_keywords = [
        "barrier", "access", "registration", "agreement", "confidential",
        "proprietary", "request", "restriction", "available"
    ]

    has_barrier = any(kw in reasoning_lower for kw in barrier_keywords)

    # Must mention both completeness and barriers for refined categories
    return has_completeness and has_barrier
```

**Quality Assessment Metrics**:
```python
def assess_reasoning_quality(classifications: List[Classification]) -> Dict[str, float]:
    """
    Assess reasoning quality across a batch of classifications.

    Returns metrics for SC-004 validation.
    """
    refined_cats = [c for c in classifications if c.category in [
        OpennessCategory.MOSTLY_OPEN, OpennessCategory.MOSTLY_CLOSED
    ]]

    if not refined_cats:
        return {"reasoning_quality_pct": 100.0}  # No refined categories to validate

    valid_count = sum(1 for c in refined_cats if validate_reasoning_quality(c))
    quality_pct = (valid_count / len(refined_cats)) * 100

    return {
        "total_refined_classifications": len(refined_cats),
        "valid_reasoning_count": valid_count,
        "reasoning_quality_pct": quality_pct,
        "target_pct": 90.0,
        "passes_sc004": quality_pct >= 90.0
    }
```

---

### 3.4 Failure Handling Validation (FR-010)

**Requirements**:
- Retry 3 times with exponential backoff
- Mark as "unclassified" after final failure
- Log error reason
- Continue processing remaining publications

**Validation Function**:
```python
def validate_failure_handling(failure: ClassificationFailure) -> bool:
    """
    Validate that failure was handled according to FR-010.

    Returns True if:
    - Retry count <= 3
    - Final status is "unclassified"
    - Error reason is logged
    """
    return (
        failure.retry_count <= 3 and
        failure.final_status == "unclassified" and
        len(failure.error_reason) > 0
    )
```

**Batch Processing Validation**:
```python
def validate_batch_processing(
    total_publications: int,
    successful_classifications: int,
    failures: List[ClassificationFailure]
) -> bool:
    """
    Validate that batch processing continued after failures.

    Returns True if all publications were either classified or marked as failed.
    """
    return successful_classifications + len(failures) == total_publications
```

---

## 4. State Transitions

### 4.1 Classification Process Flow

```
START
  ↓
LOAD_STATEMENT → Extract statement text
  ↓
SELECT_EXAMPLES → kNN few-shot selection (k=5)
  ↓
BUILD_PROMPT → Enhanced prompt with completeness reasoning steps (FR-007)
  ↓
LLM_REQUEST → LLMProvider.complete()
  ↓
  ├─ SUCCESS → PARSE_RESPONSE
  │              ↓
  │         VALIDATE_REASONING → Check completeness mentions (SC-004)
  │              ↓
  │         CREATE_CLASSIFICATION → Return Classification object
  │              ↓
  │         LOG_SUCCESS → ClassificationLogger
  │              ↓
  │         END (CLASSIFIED)
  │
  ├─ RETRYABLE_ERROR → RETRY (up to 3 times with exponential backoff)
  │              ↓
  │         (Loop back to LLM_REQUEST)
  │
  └─ NON_RETRYABLE_ERROR or MAX_RETRIES → CREATE_FAILURE
                 ↓
            LOG_FAILURE → ClassificationLogger.log_error()
                 ↓
            END (UNCLASSIFIED)
```

**State Descriptions**:

1. **LOAD_STATEMENT**: Extract data/code availability statement from publication
2. **SELECT_EXAMPLES**: Use sentence-transformers to find k=5 most similar training examples
3. **BUILD_PROMPT**: Construct enhanced prompt with:
   - System prompt (refined taxonomy definitions)
   - Few-shot examples (k=5)
   - Step-by-step reasoning template (FR-007):
     - Step 1: Identify data/code types
     - Step 2: Identify access barriers
     - Step 3: Determine repository type
     - Step 4: Apply hard precedence rule
     - Step 5: Assess completeness for final classification
4. **LLM_REQUEST**: Call LLMProvider.complete() with retry logic
5. **PARSE_RESPONSE**: Extract category, confidence, reasoning from LLM response
6. **VALIDATE_REASONING**: Check if reasoning mentions completeness attributes (SC-004)
7. **CREATE_CLASSIFICATION**: Instantiate Classification object
8. **LOG_SUCCESS**: Write to JSON Lines log file
9. **CREATE_FAILURE**: Instantiate ClassificationFailure object after exhausting retries
10. **LOG_FAILURE**: Write failure to JSON Lines log file

---

### 4.2 Failure and Retry State Machine

```
ATTEMPT_1 (initial request)
  ↓
  ├─ SUCCESS → CLASSIFIED
  │
  ├─ RETRYABLE_ERROR → WAIT (1.0s) → ATTEMPT_2
  │                                      ↓
  │                                      ├─ SUCCESS → CLASSIFIED
  │                                      │
  │                                      ├─ RETRYABLE_ERROR → WAIT (2.0s) → ATTEMPT_3
  │                                      │                                      ↓
  │                                      │                                      ├─ SUCCESS → CLASSIFIED
  │                                      │                                      │
  │                                      │                                      ├─ RETRYABLE_ERROR → WAIT (4.0s) → ATTEMPT_4
  │                                      │                                      │                                      ↓
  │                                      │                                      │                                      ├─ SUCCESS → CLASSIFIED
  │                                      │                                      │                                      │
  │                                      │                                      │                                      └─ ERROR → UNCLASSIFIED
  │                                      │                                      │
  │                                      │                                      └─ NON_RETRYABLE_ERROR → UNCLASSIFIED
  │                                      │
  │                                      └─ NON_RETRYABLE_ERROR → UNCLASSIFIED
  │
  └─ NON_RETRYABLE_ERROR → UNCLASSIFIED
```

**Retryable Errors**:
- Rate limit (429)
- Timeout (504)
- Service unavailable (503, 529)
- Overloaded server

**Non-Retryable Errors**:
- Invalid API key (401)
- Malformed request (400)
- Invalid model name (404)
- Content policy violation

**Exponential Backoff Schedule**:
- Attempt 1: No delay
- Attempt 2: Wait 1.0s
- Attempt 3: Wait 2.0s
- Attempt 4: Wait 4.0s (final attempt)

**Implementation** (already exists in `LLMProvider.complete()`):
```python
delay = retry_delay  # 1.0s
for attempt in range(max_retries + 1):  # 0, 1, 2, 3 = 4 attempts
    try:
        # Make request
        return response
    except Exception as e:
        if retryable and attempt < max_retries:
            time.sleep(delay)
            delay *= 2  # Exponential backoff
        else:
            raise LLMError(...)
```

---

## 5. Data Model Summary

### 5.1 Entity Relationships Diagram

```
OpennessCategory (Enum)
    ↑
    |
Classification (Dataclass)
    ├── contains: OpennessCategory
    ├── contains: ClassificationType
    ├── contains: LLMConfiguration
    └── references: TrainingExample IDs (List[str])

LLMConfiguration (Dataclass)
    ├── contains: LLMProviderType
    └── used by: LLMProvider

LLMProvider (Class)
    ├── uses: LLMConfiguration
    ├── raises: LLMError (on failure)
    └── returns: str (LLM response)

ClassificationFailure (Dataclass)
    ├── created from: LLMError
    ├── contains: ClassificationType
    └── logged by: ClassificationLogger

CompletenessAttributes (Dataclass)
    ├── extracted from: articles_reviewed.csv (ground truth)
    ├── extracted from: Classification.reasoning (validation)
    └── used for: SC-003, SC-004 metrics

AccessBarrier (Dataclass)
    ├── extracted from: Classification.reasoning
    └── used for: FR-004 precedence validation

ClassificationLogger (Class)
    ├── logs: Classification (success)
    └── logs: ClassificationFailure (failure)
```

### 5.2 File-to-Entity Mapping

| File | Entities Defined |
|------|------------------|
| `openness_classifier/core.py` | OpennessCategory, ClassificationType, LLMProviderType, Classification, LLMConfiguration, LLMProvider, ClassificationLogger |
| `openness_classifier/prompts.py` | (None - templates only, references Classification) |
| `openness_classifier/data.py` | TrainingExample (existing), CompletenessAttributes (NEW) |
| `openness_classifier/validation.py` | AccessBarrier (NEW), validation functions |
| `openness_classifier/batch.py` | ClassificationFailure (NEW), batch processing logic |

### 5.3 Validation Metrics Mapping

| Success Criterion | Data Model Entities | Validation Function |
|-------------------|---------------------|---------------------|
| SC-001: 15pp accuracy improvement | Classification, OpennessCategory | `calculate_accuracy_improvement()` |
| SC-002: Cohen's kappa > 0.70 | Classification, OpennessCategory | `calculate_cohens_kappa()` |
| SC-003: 80% correct reclassification | Classification, CompletenessAttributes | `validate_completeness_reclassification()` |
| SC-004: 90% reasoning quality | Classification (reasoning field) | `assess_reasoning_quality()` |
| SC-005: F1-score > 0.75 | Classification, OpennessCategory | `calculate_f1_scores()` |
| SC-006: 5-10s per classification | LLMProvider, Classification (timestamp) | `measure_classification_latency()` |

---

## 6. Implementation Checklist

### 6.1 New Data Structures to Implement

- [ ] `CompletenessAttributes` dataclass in `openness_classifier/data.py`
- [ ] `AccessBarrier` dataclass in `openness_classifier/validation.py`
- [ ] `ClassificationFailure` dataclass in `openness_classifier/batch.py`

### 6.2 Validation Functions to Implement

- [ ] `validate_data_completeness()` in `openness_classifier/validation.py`
- [ ] `validate_code_completeness()` in `openness_classifier/validation.py`
- [ ] `validate_barrier_precedence()` in `openness_classifier/validation.py`
- [ ] `validate_reasoning_quality()` in `openness_classifier/validation.py`
- [ ] `assess_reasoning_quality()` in `openness_classifier/validation.py`
- [ ] `validate_failure_handling()` in `openness_classifier/batch.py`
- [ ] `validate_batch_processing()` in `openness_classifier/batch.py`

### 6.3 Parsing Functions to Implement

- [ ] `extract_completeness_from_reasoning()` - Parse completeness attributes from reasoning text
- [ ] `extract_barriers_from_reasoning()` - Parse access barriers from reasoning text
- [ ] `parse_ground_truth_completeness()` - Load completeness from articles_reviewed.csv

### 6.4 Enhancements to Existing Structures

- [ ] Review `LLMConfiguration.max_tokens` default (may need increase from 500 to 750-1000)
- [ ] Add validation in `Classification.__post_init__()` to check reasoning for refined categories
- [ ] Extend `ClassificationLogger` to handle `ClassificationFailure` logging

---

## Appendix A: Example Data Instances

### A.1 Complete Classification Example (mostly_open)

```python
# From articles_reviewed.csv row 28 (Fonseca et al.)
# Statement: "Raw data set files are available at https://doi.org/10.5281/zenodo.4323531."

classification = Classification(
    category=OpennessCategory.MOSTLY_OPEN,
    statement_type=ClassificationType.DATA,
    confidence_score=0.88,
    reasoning=(
        "Data statement: 'Raw data set files are available at https://doi.org/10.5281/zenodo.4323531.' "
        "Step 1 - Data types: Raw data files (all necessary data). "
        "Step 2 - Access barriers: None (publicly available). "
        "Step 3 - Repository: Zenodo (persistent repository with DOI). "
        "Step 4 - Precedence: No substantial barriers. "
        "Step 5 - Classification: mostly_open due to high completeness (Raw data) "
        "in persistent repository with no access barriers."
    ),
    timestamp=datetime(2026, 1, 16, 10, 30, 0),
    model_config=LLMConfiguration(
        provider=LLMProviderType.CLAUDE,
        model_name='claude-3-5-sonnet-20241022',
        temperature=0.1,
        max_tokens=750,
    ),
    few_shot_example_ids=[
        "doi:10.1021/acs.est.1c07332",
        "doi:10.1016/j.rse.2020.112165",
        "doi:10.1021/acs.est.0c06480",
        "doi:10.1021/acs.est.1c03401",
        "doi:10.1021/acs.est.0c07551"
    ]
)

completeness = CompletenessAttributes(
    completeness_type="data",
    attributes=["Raw"],
    is_mostly_open=True,
    raw_value="Raw"
)

barrier = AccessBarrier(
    barrier_type="none",
    description="publicly available",
    forces_mostly_closed=False,
    mentioned_in_statement=True
)
```

### A.2 Complete Classification Example (mostly_closed with hard precedence)

```python
# From articles_reviewed.csv row 10 (Chen et al.)
# Statement: "While the remaining data from this study are not available for open release
# due to confidentiality concerns..."

classification = Classification(
    category=OpennessCategory.MOSTLY_CLOSED,
    statement_type=ClassificationType.DATA,
    confidence_score=0.92,
    reasoning=(
        "Data statement: 'While the remaining data from this study are not available "
        "for open release due to confidentiality concerns...' "
        "Step 1 - Data types: Partial data available (some on GitHub, remainder unavailable). "
        "Step 2 - Access barriers: Confidentiality concerns (substantial barrier). "
        "Step 3 - Repository: GitHub (non-persistent) for partial data. "
        "Step 4 - Precedence: Confidentiality is a substantial barrier - forces mostly_closed. "
        "Step 5 - Classification: mostly_closed due to hard precedence rule (FR-004), "
        "regardless of partial availability on GitHub."
    ),
    timestamp=datetime(2026, 1, 16, 10, 32, 0),
    model_config=LLMConfiguration(
        provider=LLMProviderType.CLAUDE,
        model_name='claude-3-5-sonnet-20241022',
        temperature=0.1,
        max_tokens=750,
    ),
    few_shot_example_ids=[
        "doi:10.1021/acs.est.1c06458",
        "doi:10.1021/acs.est.0c06952",
        "doi:10.1021/acs.est.1c02535",
        "doi:10.1021/acs.est.1c00024",
        "doi:10.1021/acs.est.1c06732"
    ]
)

completeness = CompletenessAttributes(
    completeness_type="data",
    attributes=["Raw"],  # Partial
    is_mostly_open=False,
    raw_value="Raw"
)

barrier = AccessBarrier(
    barrier_type="substantial",
    description="confidentiality concerns",
    forces_mostly_closed=True,  # Hard precedence
    mentioned_in_statement=True
)
```

### A.3 Classification Failure Example

```python
# Timeout after 3 retries
failure = ClassificationFailure(
    publication_id="doi:10.1021/acs.est.1c04706",
    statement_type=ClassificationType.DATA,
    error_type="timeout",
    retry_count=3,
    final_status="unclassified",
    error_reason=(
        "LLM request failed after 3 attempts: Request timeout after 30s. "
        "Retry 1 failed at 1.0s delay, Retry 2 failed at 2.0s delay, "
        "Retry 3 failed at 4.0s delay."
    ),
    timestamp=datetime(2026, 1, 16, 10, 35, 0),
    original_statement="Data available at..."[:500]
)
```

---

## Appendix B: Completeness Attribute Reference

### B.1 Data Completeness Indicators

**Mostly Open** (FR-002):
- "All"
- "Raw; Results; Source Data"
- "Raw; Results"

**Mostly Closed** (all others, examples):
- "Raw" (alone)
- "Results" (alone)
- "Source Data" (alone)
- "Nothing"
- "Raw; Source Data" (missing Results)

### B.2 Code Completeness Indicators

**Mostly Open** (FR-003):
- "All"
- "Download; Process; Analysis; Figures"
- "Processing; Generate Results"
- "Processing; Results"
- "Models; Results"
- "Models; Analysis"
- "Analysis; Figures"
- "Model; Figures"
- "Results; Figures"
- "Generate Results; Figures"

**Mostly Closed** (all others, examples):
- "Model" (alone)
- "Excel Template" (alone)
- "Processing" (alone)
- "Nothing"
- "Analysis" (alone, unless combined with Figures)

---

## Appendix C: Repository Type Reference

### C.1 Persistent Repositories (FR-006)

**Characteristics**:
- Unique identifier (DOI, ARK, Handle)
- Long-term preservation commitment
- Versioning and metadata

**Examples**:
- Zenodo
- Figshare
- Dryad
- OSF (Open Science Framework)
- NEON Data Portal
- Institutional repositories with DOIs

### C.2 Non-Persistent Repositories (FR-006)

**Characteristics**:
- No guaranteed long-term preservation
- URLs may change or disappear
- Limited metadata

**Examples**:
- GitHub
- Personal websites
- Supplementary materials (journal-hosted PDFs)
- Google Drive, Dropbox (shared links)

**Note**: Per edge case in spec, non-persistent repositories (e.g., GitHub) can still result in `mostly_open` if completeness is high ("All code on GitHub" → mostly_open).

---

**Document Version**: 1.0
**Last Updated**: 2026-01-16
**Related Documents**: [spec.md](./spec.md), [plan.md](./plan.md), [research.md](./research.md)
