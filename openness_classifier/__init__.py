"""
Openness Classifier - Few-shot LLM-based classification of data and code openness

This library provides tools for classifying the openness of data and code
availability statements in scholarly publications using few-shot learning
with large language models.

Classification Categories:
- open: Fully open access, no restrictions
- mostly_open: Largely accessible with minor restrictions
- mostly_closed: Largely restricted with limited access
- closed: Not accessible, includes "upon request"

Example:
    >>> from openness_classifier import classify_statement, load_config
    >>> config = load_config()
    >>> result = classify_statement(
    ...     "Data are available at https://zenodo.org/record/12345",
    ...     statement_type="data",
    ...     config=config
    ... )
    >>> print(result.category)  # OpennessCategory.OPEN
"""

__version__ = "0.1.0"
__author__ = "Kelly Caylor"
__email__ = "kcaylor@ucsb.edu"

# Core types and enumerations
from openness_classifier.core import (
    OpennessCategory,
    ClassificationType,
    Classification,
    LLMConfiguration,
    LLMProviderType,
    BatchStatus,
    LLMProvider,
    ClassificationLogger,
    # Errors
    ClassificationError,
    LLMError,
    ConfigurationError,
    DataError,
    ValidationError,
)

# Configuration
from openness_classifier.config import (
    ClassifierConfig,
    load_config,
    save_config,
)

# Data handling
from openness_classifier.data import (
    Publication,
    TrainingExample,
    EmbeddingModel,
    load_training_data,
    train_test_split,
    validate_training_data,
    reload_training_data,
    compute_embeddings,
)

# Classification
from openness_classifier.classifier import (
    OpennessClassifier,
    classify_statement,
    classify_publication,
    get_classifier,
    identify_low_confidence,
    suggest_training_examples,
)

# Batch processing
from openness_classifier.batch import (
    BatchJob,
    classify_csv,
)

# Validation
from openness_classifier.validation import (
    ClassificationMetrics,
    ValidationResult,
    compute_metrics,
    validate_classifications,
    cross_validate,
    performance_comparison,
)

# Prompts (for advanced users)
from openness_classifier.prompts import (
    SYSTEM_PROMPT,
    build_few_shot_prompt,
    select_knn_examples,
    parse_classification_response,
)

__all__ = [
    # Version
    "__version__",
    # Core types
    "OpennessCategory",
    "ClassificationType",
    "Classification",
    "LLMConfiguration",
    "LLMProviderType",
    "BatchStatus",
    "LLMProvider",
    "ClassificationLogger",
    # Errors
    "ClassificationError",
    "LLMError",
    "ConfigurationError",
    "DataError",
    "ValidationError",
    # Config
    "ClassifierConfig",
    "load_config",
    "save_config",
    # Data
    "Publication",
    "TrainingExample",
    "EmbeddingModel",
    "load_training_data",
    "train_test_split",
    "validate_training_data",
    "reload_training_data",
    "compute_embeddings",
    # Classification
    "OpennessClassifier",
    "classify_statement",
    "classify_publication",
    "get_classifier",
    "identify_low_confidence",
    "suggest_training_examples",
    # Batch
    "BatchJob",
    "classify_csv",
    # Validation
    "ClassificationMetrics",
    "ValidationResult",
    "compute_metrics",
    "validate_classifications",
    "cross_validate",
    "performance_comparison",
    # Prompts
    "SYSTEM_PROMPT",
    "build_few_shot_prompt",
    "select_knn_examples",
    "parse_classification_response",
]
