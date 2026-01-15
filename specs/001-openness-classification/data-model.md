# Data Model: Openness Classification Model

**Feature**: Openness Classification Model
**Date**: 2026-01-15
**Source**: Derived from [spec.md](./spec.md) Key Entities

## Overview

This document defines the data structures and entities for the openness classification system. The model supports few-shot LLM-based classification of publication data/code availability statements into a 4-category ordinal taxonomy.

## Core Entities

### 1. Publication

**Purpose**: Represents a scholarly article with data and code availability statements to be classified.

**Attributes**:
```python
class Publication:
    id: str                          # Unique identifier (DOI, PMID, or internal ID)
    data_statement: Optional[str]    # Data availability statement text
    code_statement: Optional[str]    # Code availability statement text
    data_classification: Optional[OpennessCategory]  # Classified data openness
    code_classification: Optional[OpennessCategory]  # Classified code openness
    data_confidence: Optional[float] # Confidence score for data classification (0-1)
    code_confidence: Optional[float] # Confidence score for code classification (0-1)
    metadata: Dict[str, Any]         # Additional publication metadata (optional)
```

**Validation Rules**:
- `id` is required and must be unique
- At least one of `data_statement` or `code_statement` must be non-empty
- Confidence scores must be between 0 and 1 if present
- Classifications are only set after successful classification run

**State Transitions**:
1. **Created**: Publication loaded with statements, no classifications
2. **Classified**: Classifications assigned after LLM inference
3. **Validated**: Classifications verified against ground truth (if available)

### 2. OpennessCategory (Enum)

**Purpose**: 4-category ordinal taxonomy for data/code openness classification.

**Values**:
```python
class OpennessCategory(str, Enum):
    OPEN = "open"                    # Fully open access, no restrictions
    MOSTLY_OPEN = "mostly open"      # Largely accessible with minor restrictions
    MOSTLY_CLOSED = "mostly closed"  # Largely restricted with limited access
    CLOSED = "closed"                # Not accessible, includes "upon request"
```

**Classification Rules** (per articles_reviewed.csv rubric):
- Conditional/request-based access → CLOSED
- Data use agreements → CLOSED
- Institutional access only → MOSTLY_CLOSED
- Public repository with registration → MOSTLY_OPEN
- Public repository, no barriers → OPEN

### 3. Classification

**Purpose**: Represents an openness assessment for data or code with metadata for reproducibility.

**Attributes**:
```python
class Classification:
    type: ClassificationType         # "data" or "code"
    category: OpennessCategory       # Openness classification
    confidence_score: float          # Model confidence (0-1)
    reasoning: Optional[str]         # Chain-of-thought reasoning from LLM
    timestamp: datetime              # When classification was made
    model_config: LLMConfiguration   # LLM configuration used
    few_shot_examples: List[str]     # IDs of training examples used
```

**Validation Rules**:
- `confidence_score` must be between 0 and 1
- `timestamp` automatically set to current UTC time
- `model_config` required for reproducibility tracking

### 4. TrainingExample

**Purpose**: Represents a manually coded publication used for few-shot learning.

**Attributes**:
```python
class TrainingExample:
    id: str                          # Unique identifier
    statement_text: str              # Data or code availability statement
    ground_truth: OpennessCategory   # Human-coded classification
    type: ClassificationType         # "data" or "code"
    source: str                      # "articles_reviewed.csv"
    embedding: Optional[np.ndarray]  # Sentence embedding for kNN selection
    annotation_date: Optional[date]  # When manually coded
    annotator_id: Optional[str]      # Who coded it (if available)
```

**Validation Rules**:
- `statement_text` must be non-empty
- `ground_truth` must be valid OpennessCategory
- Embeddings computed lazily for kNN example selection

**Relationships**:
- Used by `Classifier` to construct few-shot prompts
- Selected via semantic similarity (kNN) for each classification task

### 5. LLMConfiguration

**Purpose**: Tracks language model configuration for reproducibility (FAIR principles).

**Attributes**:
```python
class LLMConfiguration:
    provider: LLMProvider            # Claude, OpenAI, or Ollama
    model_name: str                  # e.g., "claude-sonnet-3.5", "gpt-4-turbo", "llama3:8b"
    api_endpoint: Optional[str]      # API base URL (for Ollama or custom endpoints)
    model_version: Optional[str]     # Model version identifier
    temperature: float               # Sampling temperature (default: 0.1)
    max_tokens: int                  # Maximum response tokens (default: 500)
    top_p: float                     # Nucleus sampling parameter (default: 0.95)
    api_key_hash: Optional[str]      # SHA-256 hash of API key (for logging, not the key itself)
    configuration_timestamp: datetime # When configuration was created
```

**Validation Rules**:
- `temperature` must be between 0 and 2
- `max_tokens` must be positive
- `top_p` must be between 0 and 1
- API key never stored directly, only hash for audit trail

**Security**:
- API keys loaded from environment variables or config files
- Only hash stored in logs for reproducibility verification
- Configuration serialized to JSON for manuscript methods sections

### 6. ValidationResult

**Purpose**: Aggregates model performance metrics for reporting and manuscript integration.

**Attributes**:
```python
class ValidationResult:
    data_metrics: ClassificationMetrics
    code_metrics: ClassificationMetrics
    overall_accuracy: float
    test_set_size: int
    train_set_size: int
    validation_timestamp: datetime
    model_config: LLMConfiguration
    confusion_matrices: Dict[str, np.ndarray]  # {"data": matrix, "code": matrix}
    misclassified_examples: List[Tuple[str, OpennessCategory, OpennessCategory]]
```

**Nested Structure - ClassificationMetrics**:
```python
class ClassificationMetrics:
    accuracy: float                  # Overall accuracy
    precision_per_class: Dict[OpennessCategory, float]
    recall_per_class: Dict[OpennessCategory, float]
    f1_per_class: Dict[OpennessCategory, float]
    macro_f1: float                  # Macro-averaged F1
    weighted_f1: float               # Weighted F1 by class support
    cohens_kappa: float              # Inter-rater agreement
    support_per_class: Dict[OpennessCategory, int]  # Number of samples per class
```

**Export Methods**:
- `to_markdown()`: Generate table for manuscript results section
- `to_json()`: Save metrics for archiving
- `plot_confusion_matrix()`: Visualize confusion matrix

### 7. BatchJob

**Purpose**: Tracks batch processing of multiple publications for progress monitoring.

**Attributes**:
```python
class BatchJob:
    job_id: str                      # Unique job identifier (UUID)
    input_file: Path                 # Path to input CSV
    output_file: Path                # Path to output CSV with classifications
    total_publications: int          # Number of publications to process
    processed_count: int             # Number processed so far
    failed_count: int                # Number that failed classification
    status: BatchStatus              # "pending", "running", "completed", "failed"
    start_time: datetime
    end_time: Optional[datetime]
    error_log: List[Tuple[str, str]] # [(publication_id, error_message)]
```

**State Transitions**:
1. **Pending**: Job created, not started
2. **Running**: Processing publications
3. **Completed**: All publications processed successfully
4. **Failed**: Job terminated due to error

## Data Storage

### Training Data (articles_reviewed.csv)

**Schema**:
```csv
id,data_statement,code_statement,data_open,code_open,[other columns...]
```

**Required Columns**:
- `id`: Publication identifier
- `data_statement`: Data availability statement text
- `code_statement`: Code availability statement text
- `data_open`: Ground truth data openness (one of: "open", "mostly open", "mostly closed", "closed")
- `code_open`: Ground truth code openness (one of: "open", "mostly open", "mostly closed", "closed")

**Loading**:
```python
df = pd.read_csv("data/articles_reviewed.csv")
training_examples = df.to_dict("records")
```

### Classification Logs (JSON)

**Purpose**: Log all classification decisions for reproducibility.

**Format**:
```json
{
  "classification_id": "uuid",
  "timestamp": "2026-01-15T10:30:00Z",
  "publication_id": "doi:10.1234/example",
  "data_classification": {
    "category": "open",
    "confidence": 0.92,
    "reasoning": "Statement indicates data deposited in Zenodo..."
  },
  "code_classification": {
    "category": "mostly open",
    "confidence": 0.85,
    "reasoning": "Code available on GitHub but requires registration..."
  },
  "model_config": {
    "provider": "Claude",
    "model_name": "claude-sonnet-3.5",
    "temperature": 0.1
  },
  "few_shot_examples_used": ["ex1", "ex2", "ex3"]
}
```

### Configuration (config.json or .env)

**Environment Variables**:
```bash
# LLM Provider Selection
LLM_PROVIDER=claude  # or "openai", "ollama"

# API Credentials
ANTHROPIC_API_KEY=sk-ant-...
OPENAI_API_KEY=sk-...
OLLAMA_BASE_URL=http://localhost:11434

# Model Configuration
LLM_MODEL_NAME=claude-sonnet-3.5
LLM_TEMPERATURE=0.1
LLM_MAX_TOKENS=500

# Data Paths
TRAINING_DATA_PATH=data/articles_reviewed.csv
LOG_DIR=logs/
```

## Relationships Diagram

```
TrainingExample (1:N) ───uses──→ Classification
                                    ↓
Publication (1:2) ───has──→ Classification (data & code)
                                    ↓
                            LLMConfiguration (N:1)
                                    ↓
ValidationResult (1:1) ───aggregates──→ ClassificationMetrics

BatchJob (1:N) ───processes──→ Publication
```

## Data Flow

1. **Training Data Load**:
   - Load `articles_reviewed.csv` → `TrainingExample` instances
   - Compute embeddings for kNN selection
   - Split into train/test sets

2. **Single Classification**:
   - Input: `Publication` with statements
   - Select k=3-5 `TrainingExample` via semantic similarity
   - Construct few-shot prompt with chain-of-thought
   - Call LLM → get `Classification` with reasoning
   - Log decision → classification logs

3. **Batch Processing**:
   - Create `BatchJob` with input CSV
   - For each row → create `Publication` → classify
   - Update `BatchJob` progress
   - Export classifications to output CSV

4. **Validation**:
   - Load test set with ground truth
   - Classify all test publications
   - Compare predictions vs. ground truth
   - Compute `ValidationResult` with metrics
   - Generate confusion matrices and reports

## Type Definitions (Python)

```python
from typing import Optional, Dict, Any, List, Tuple
from enum import Enum
from dataclasses import dataclass, field
from datetime import datetime, date
from pathlib import Path
import numpy as np

class ClassificationType(str, Enum):
    DATA = "data"
    CODE = "code"

class LLMProvider(str, Enum):
    CLAUDE = "claude"
    OPENAI = "openai"
    OLLAMA = "ollama"

class BatchStatus(str, Enum):
    PENDING = "pending"
    RUNNING = "running"
    COMPLETED = "completed"
    FAILED = "failed"
```

## Validation and Constraints

### Data Quality Checks

1. **Statement Validation**:
   - Remove excessive whitespace
   - Check for minimum statement length (>10 characters)
   - Flag statements with non-English characters (log warning)

2. **Classification Validation**:
   - Confidence score sanity check (warn if <0.3)
   - Flag contradictory classifications (data=open, code=closed with similar statements)

3. **Training Data Validation**:
   - Check for class imbalance (warn if any class <10% of total)
   - Verify all required columns present
   - Check for missing values in critical columns

### Error Handling

- **Missing statements**: Return `None` for classification, log warning
- **LLM API errors**: Retry with exponential backoff, fallback to different provider if configured
- **Invalid classifications**: Log error, return lowest confidence classification
- **CSV errors**: Clear error messages indicating row number and issue

## Version History

- **v1.0** (2026-01-15): Initial data model for openness classification system
