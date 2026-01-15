# Classifier API Contract

**Feature**: Openness Classification Model
**Date**: 2026-01-15
**Type**: Python Library API

## Overview

This document defines the public API for the `openness_classifier` Python library. The API supports single and batch classification of publication data/code availability statements.

## Module: `openness_classifier.classifier`

### Function: `classify_statement`

Classify a single data or code availability statement.

**Signature**:
```python
def classify_statement(
    statement: str,
    statement_type: Literal["data", "code"],
    config: Optional[LLMConfiguration] = None,
    return_reasoning: bool = False
) -> Classification
```

**Parameters**:
- `statement` (str, required): The availability statement text to classify
- `statement_type` (Literal["data", "code"], required): Whether this is a data or code statement
- `config` (Optional[LLMConfiguration]): LLM configuration. If None, uses default from environment
- `return_reasoning` (bool, default=False): Whether to include chain-of-thought reasoning in response

**Returns**:
- `Classification`: Contains category, confidence score, and optionally reasoning

**Raises**:
- `ValueError`: If statement is empty or invalid
- `LLMAPIError`: If LLM API call fails after retries
- `ConfigurationError`: If LLM configuration is invalid or credentials missing

**Example**:
```python
from openness_classifier.classifier import classify_statement

statement = "Data available on Zenodo at doi:10.5281/zenodo.123456"
result = classify_statement(statement, "data", return_reasoning=True)

print(f"Category: {result.category}")        # "open"
print(f"Confidence: {result.confidence_score}")  # 0.95
print(f"Reasoning: {result.reasoning}")      # Chain-of-thought explanation
```

### Function: `classify_publication`

Classify both data and code statements for a publication.

**Signature**:
```python
def classify_publication(
    publication: Publication,
    config: Optional[LLMConfiguration] = None,
    return_reasoning: bool = False
) -> Tuple[Optional[Classification], Optional[Classification]]
```

**Parameters**:
- `publication` (Publication, required): Publication with data_statement and/or code_statement
- `config` (Optional[LLMConfiguration]): LLM configuration
- `return_reasoning` (bool, default=False): Whether to include reasoning

**Returns**:
- `Tuple[Optional[Classification], Optional[Classification]]`: (data_classification, code_classification). Either can be None if corresponding statement is missing.

**Raises**:
- `ValueError`: If publication has no statements
- `LLMAPIError`: If LLM API call fails after retries

**Example**:
```python
from openness_classifier.classifier import classify_publication
from openness_classifier.data import Publication

pub = Publication(
    id="doi:10.1234/example",
    data_statement="Data available upon request",
    code_statement="Code on GitHub: github.com/user/repo"
)

data_class, code_class = classify_publication(pub, return_reasoning=True)

print(f"Data: {data_class.category}, Confidence: {data_class.confidence_score}")
print(f"Code: {code_class.category}, Confidence: {code_class.confidence_score}")
```

## Module: `openness_classifier.batch`

### Function: `classify_csv`

Process a CSV file with multiple publications and add classification columns.

**Signature**:
```python
def classify_csv(
    input_path: Path | str,
    output_path: Path | str,
    config: Optional[LLMConfiguration] = None,
    id_column: str = "id",
    data_statement_column: str = "data_statement",
    code_statement_column: str = "code_statement",
    progress_callback: Optional[Callable[[int, int], None]] = None,
    error_handling: Literal["skip", "fail", "log"] = "skip"
) -> BatchJob
```

**Parameters**:
- `input_path` (Path | str, required): Path to input CSV with publications
- `output_path` (Path | str, required): Path to output CSV (will be created/overwritten)
- `config` (Optional[LLMConfiguration]): LLM configuration
- `id_column` (str, default="id"): Name of identifier column
- `data_statement_column` (str, default="data_statement"): Name of data statement column
- `code_statement_column` (str, default="code_statement"): Name of code statement column
- `progress_callback` (Optional[Callable], default=None): Callback function(processed_count, total_count) for progress updates
- `error_handling` (Literal["skip", "fail", "log"], default="skip"): How to handle classification errors

**Returns**:
- `BatchJob`: Batch job object with results and statistics

**Side Effects**:
- Creates output CSV with added columns: `data_classification`, `data_confidence`, `code_classification`, `code_confidence`
- Logs all classification decisions to `logs/batch_{job_id}.jsonl`

**Raises**:
- `FileNotFoundError`: If input_path doesn't exist
- `ValueError`: If required columns are missing from CSV
- `BatchProcessingError`: If error_handling="fail" and any classification fails

**Example**:
```python
from openness_classifier.batch import classify_csv
from pathlib import Path

def progress_callback(processed, total):
    print(f"Progress: {processed}/{total} ({100*processed/total:.1f}%)")

job = classify_csv(
    input_path="data/articles_reviewed.csv",
    output_path="data/classified_articles.csv",
    progress_callback=progress_callback,
    error_handling="skip"
)

print(f"Processed: {job.processed_count}")
print(f"Failed: {job.failed_count}")
print(f"Duration: {(job.end_time - job.start_time).total_seconds()}s")
```

## Module: `openness_classifier.validation`

### Function: `validate_classifications`

Validate model performance against ground truth labels.

**Signature**:
```python
def validate_classifications(
    test_data: pd.DataFrame,
    ground_truth_data_column: str = "data_open",
    ground_truth_code_column: str = "code_open",
    config: Optional[LLMConfiguration] = None
) -> ValidationResult
```

**Parameters**:
- `test_data` (pd.DataFrame, required): Test dataset with statements and ground truth labels
- `ground_truth_data_column` (str, default="data_open"): Column with ground truth data classifications
- `ground_truth_code_column` (str, default="code_open"): Column with ground truth code classifications
- `config` (Optional[LLMConfiguration]): LLM configuration

**Returns**:
- `ValidationResult`: Comprehensive validation metrics including accuracy, precision, recall, F1, Cohen's kappa, confusion matrices

**Raises**:
- `ValueError`: If required columns are missing or ground truth labels are invalid

**Example**:
```python
from openness_classifier.validation import validate_classifications
import pandas as pd

# Load test set
test_df = pd.read_csv("data/test_set.csv")

# Run validation
results = validate_classifications(test_df)

# Print metrics
print(f"Data Accuracy: {results.data_metrics.accuracy:.3f}")
print(f"Code Accuracy: {results.code_metrics.accuracy:.3f}")
print(f"Data Cohen's Kappa: {results.data_metrics.cohens_kappa:.3f}")

# Generate confusion matrix plot
results.plot_confusion_matrix("data", save_path="figures/confusion_matrix_data.png")

# Export metrics for manuscript
markdown_table = results.to_markdown()
print(markdown_table)
```

### Function: `cross_validate`

Perform k-fold cross-validation on training data.

**Signature**:
```python
def cross_validate(
    data: pd.DataFrame,
    n_splits: int = 5,
    stratify: bool = True,
    config: Optional[LLMConfiguration] = None
) -> List[ValidationResult]
```

**Parameters**:
- `data` (pd.DataFrame, required): Full dataset with ground truth labels
- `n_splits` (int, default=5): Number of folds for cross-validation
- `stratify` (bool, default=True): Whether to stratify splits by classification category
- `config` (Optional[LLMConfiguration]): LLM configuration

**Returns**:
- `List[ValidationResult]`: Validation results for each fold

**Example**:
```python
from openness_classifier.validation import cross_validate
import pandas as pd
import numpy as np

data = pd.read_csv("data/articles_reviewed.csv")
fold_results = cross_validate(data, n_splits=5)

# Aggregate metrics across folds
accuracies = [r.data_metrics.accuracy for r in fold_results]
print(f"Mean Accuracy: {np.mean(accuracies):.3f} ± {np.std(accuracies):.3f}")
```

## Module: `openness_classifier.config`

### Function: `load_config`

Load LLM configuration from environment or file.

**Signature**:
```python
def load_config(
    config_file: Optional[Path | str] = None
) -> LLMConfiguration
```

**Parameters**:
- `config_file` (Optional[Path | str], default=None): Path to config file (JSON). If None, loads from environment variables.

**Returns**:
- `LLMConfiguration`: Validated LLM configuration

**Raises**:
- `ConfigurationError`: If required credentials are missing or configuration is invalid
- `FileNotFoundError`: If config_file specified but doesn't exist

**Example**:
```python
from openness_classifier.config import load_config

# Load from environment variables
config = load_config()

# Or load from file
config = load_config("config/llm_config.json")

print(f"Provider: {config.provider}")
print(f"Model: {config.model_name}")
```

### Function: `save_config`

Save LLM configuration to file for reproducibility.

**Signature**:
```python
def save_config(
    config: LLMConfiguration,
    output_path: Path | str
) -> None
```

**Parameters**:
- `config` (LLMConfiguration, required): Configuration to save
- `output_path` (Path | str, required): Path to output JSON file

**Example**:
```python
from openness_classifier.config import save_config, load_config

config = load_config()
save_config(config, "logs/experiment_config.json")
```

## Module: `openness_classifier.data`

### Function: `load_training_data`

Load and prepare training examples from CSV.

**Signature**:
```python
def load_training_data(
    csv_path: Path | str,
    compute_embeddings: bool = True,
    embedding_model: str = "all-MiniLM-L6-v2"
) -> List[TrainingExample]
```

**Parameters**:
- `csv_path` (Path | str, required): Path to articles_reviewed.csv
- `compute_embeddings` (bool, default=True): Whether to compute sentence embeddings for kNN selection
- `embedding_model` (str, default="all-MiniLM-L6-v2"): Sentence-transformers model for embeddings

**Returns**:
- `List[TrainingExample]`: List of training examples with embeddings

**Raises**:
- `FileNotFoundError`: If csv_path doesn't exist
- `ValueError`: If CSV is missing required columns or has invalid data

**Example**:
```python
from openness_classifier.data import load_training_data

training_examples = load_training_data("data/articles_reviewed.csv")
print(f"Loaded {len(training_examples)} training examples")
```

## Error Handling

### Custom Exceptions

```python
class ClassifierError(Exception):
    """Base exception for classifier errors"""
    pass

class LLMAPIError(ClassifierError):
    """LLM API call failed"""
    pass

class ConfigurationError(ClassifierError):
    """Invalid or missing configuration"""
    pass

class BatchProcessingError(ClassifierError):
    """Batch processing failed"""
    pass
```

### Error Handling Strategy

1. **Retries**: LLM API calls automatically retry with exponential backoff (3 attempts)
2. **Fallback**: If configured, falls back to alternate LLM provider on persistent failure
3. **Logging**: All errors logged to `logs/errors.log` with context
4. **User Feedback**: Clear error messages indicating problem and suggested resolution

## Rate Limiting and Cost Control

### Rate Limiting

```python
from openness_classifier.config import set_rate_limit

# Limit to 10 requests per minute
set_rate_limit(requests_per_minute=10)
```

### Cost Tracking

```python
from openness_classifier.batch import classify_csv

job = classify_csv("input.csv", "output.csv")
print(f"Estimated Cost: ${job.estimated_cost:.2f}")
print(f"Tokens Used: {job.total_tokens}")
```

## Logging and Reproducibility

All classification decisions are logged to `logs/classifications_{timestamp}.jsonl` in JSON Lines format for full reproducibility:

```json
{"timestamp": "2026-01-15T10:30:00Z", "publication_id": "doi:123", "data_category": "open", "data_confidence": 0.95, "model_config": {...}}
```

## Version Compatibility

- **Python**: 3.10+
- **pandas**: 1.5+
- **numpy**: 1.23+
- **scikit-learn**: 1.2+

## CLI Interface (Optional)

For non-programmatic use, a CLI wrapper is provided:

```bash
# Classify single statement
openness-classifier classify "Data available on Zenodo" --type data

# Batch process CSV
openness-classifier batch input.csv output.csv --progress

# Run validation
openness-classifier validate test_set.csv --output validation_report.md
```

See `docs/cli.md` for full CLI documentation.
