# Quickstart Guide: Refined Classification Taxonomy

Welcome to the refined openness classifier! This guide will help you classify data and code availability statements using the enhanced 4-category taxonomy that better distinguishes between publications based on their completeness and accessibility.

## Overview

### What's New in the Refined Taxonomy

The refined classifier improves how we distinguish between "mostly open" and "mostly closed" publications by explicitly considering:

1. **Completeness**: What types of data/code are actually available?
   - Data: Raw data, results, source data, processed data
   - Code: Download scripts, processing, analysis, figure generation

2. **Access Barriers**: What restrictions exist?
   - **Minor barriers** (mostly_open): Free registration, institutional access
   - **Substantial barriers** (mostly_closed): Data use agreements, confidentiality, proprietary terms

3. **Repository Type**: Where are materials stored?
   - **Persistent**: Zenodo, Figshare, Dryad (with unique identifiers)
   - **Non-persistent**: GitHub, personal websites

### The 4-Category Taxonomy

| Category | Description | Key Indicators |
|----------|-------------|----------------|
| **open** | Fully accessible, no restrictions | Public repository (Zenodo, Figshare), open license, no barriers |
| **mostly_open** | Largely accessible with minor restrictions | High completeness + minor barriers (registration, institutional access) |
| **mostly_closed** | Largely restricted with limited access | Low completeness OR substantial barriers (data use agreements, proprietary) |
| **closed** | Not accessible | "Available upon request", confidential, no statement |

**Important**: "Available upon request" is ALWAYS classified as **closed**, regardless of how polite or reasonable it sounds.

## Installation and Configuration

### Prerequisites

The refined classifier uses the same installation as the existing openness_classifier package:

```bash
# Install dependencies using pixi
pixi install

# Or using pip
pip install -e .
```

### Configure Your LLM Provider

Create a `.env` file in your project root:

```bash
# For Claude (recommended)
ANTHROPIC_API_KEY=your_api_key_here
LLM_PROVIDER=claude
LLM_MODEL=claude-3-5-sonnet-20241022

# For OpenAI
OPENAI_API_KEY=your_api_key_here
LLM_PROVIDER=openai
LLM_MODEL=gpt-4

# For Ollama (local)
LLM_PROVIDER=ollama
LLM_MODEL=llama2
OLLAMA_API_BASE=http://localhost:11434
```

## Usage Examples

### 1. Classify a Single Statement with Reasoning

The most common use case: classify a single data or code availability statement and see the reasoning.

```python
from openness_classifier import classify_statement

# Example: Data with minor barrier
statement = "All raw data and results are available at https://zenodo.org/record/12345 (free registration required)."

result = classify_statement(
    statement,
    statement_type="data",
    return_reasoning=True
)

print(f"Category: {result.category.value}")
print(f"Confidence: {result.confidence_score:.2f}")
print(f"\nReasoning:\n{result.reasoning}")
```

**Output:**
```
Category: mostly_open
Confidence: 0.90

Reasoning:
1. Data types: All raw data and results (high completeness - includes essential data types)
2. Access barrier: Free registration (minor barrier)
3. Repository: Zenodo (persistent repository with DOI)
4. No substantial barriers present
5. Decision: High completeness + minor barrier + persistent repository → mostly_open
```

### 2. Understanding Completeness Attributes

The refined classifier explicitly considers what types of data/code are available:

```python
# High completeness → mostly_open
high_completeness = "Data include raw measurements, processed results, and source data files at https://figshare.com/articles/12345"
result = classify_statement(high_completeness, "data")
print(f"High completeness: {result.category.value}")  # mostly_open or open

# Partial completeness → mostly_closed
partial_completeness = "Results data are available in the supplementary materials."
result = classify_statement(partial_completeness, "data")
print(f"Partial completeness: {result.category.value}")  # mostly_closed

# All code types → mostly_open
complete_code = "All code (data download, processing, analysis, and figure generation) at https://github.com/author/repo under MIT license."
result = classify_statement(complete_code, "code")
print(f"Complete code: {result.category.value}")  # mostly_open or open
```

### 3. Hard Precedence Rule for Substantial Barriers

**Important**: Substantial access barriers ALWAYS result in "mostly_closed", regardless of how complete the materials are.

```python
# Even with "All data", substantial barrier → mostly_closed
substantial_barrier = "All data available via data use agreement from the consortium."
result = classify_statement(substantial_barrier, "data")
print(f"Substantial barrier: {result.category.value}")  # mostly_closed

# Minor barrier with good completeness → mostly_open
minor_barrier = "All data available through institutional data portal (university login required)."
result = classify_statement(minor_barrier, "data")
print(f"Minor barrier: {result.category.value}")  # mostly_open
```

### 4. Batch Process Publications

Classify multiple publications from a CSV file:

```python
from openness_classifier import classify_batch
import pandas as pd

# Load your publications
df = pd.read_csv("publications.csv")

# Batch classify (handles retries and error logging automatically)
results = classify_batch(
    df,
    data_column="data_statement",
    code_column="code_statement",
    id_column="doi",
    output_path="results/classifications.csv"
)

print(f"Classified {len(results)} publications")
print(f"Distribution:\n{results['data_category'].value_counts()}")
```

**Expected Performance**:
- Single classification: 5-10 seconds
- 300 publications: 25-50 minutes

### 5. Validate Against Ground Truth

If you have human-coded classifications, validate the classifier's performance:

```python
from openness_classifier.validation import validate_classifications
import pandas as pd

# Load ground truth data
ground_truth = pd.read_csv("resources/abpoll-open-b71bd12/data/processed/articles_reviewed.csv")

# Classify and compare
validation_results = validate_classifications(
    ground_truth,
    statement_column="Data Availability Statement",
    ground_truth_column="openness_code_data",
    statement_type="data"
)

# See detailed metrics
print(f"Overall Accuracy: {validation_results['accuracy']:.2%}")
print(f"Cohen's Kappa: {validation_results['cohens_kappa']:.3f}")
print(f"\nPer-category F1 scores:")
for category, f1 in validation_results['f1_by_category'].items():
    print(f"  {category}: {f1:.3f}")
```

## Interpreting Classification Reasoning

### What to Look For

The refined classifier provides explicit reasoning that shows:

1. **Completeness attributes identified**: What data/code types were mentioned
2. **Access barriers detected**: What restrictions exist (minor vs substantial)
3. **Repository type**: Whether a persistent or non-persistent repository is used
4. **Decision logic**: How these factors led to the classification

### Example Reasoning Output

```
Reasoning:
1. Data types: Raw data, Results, Source Data (high completeness - all necessary types)
2. Access barrier: Free registration (minor barrier)
3. Repository: Zenodo (persistent repository with DOI)
4. No substantial barriers present
5. Decision: High completeness + minor barrier + persistent repository → mostly_open
```

### Key Indicators in Reasoning

**For mostly_open classifications**, look for:
- Mentions of multiple data/code types ("Raw", "Results", "All", "Processing", "Analysis")
- Minor barriers only ("registration", "institutional access")
- Persistent repositories or comprehensive non-persistent ones

**For mostly_closed classifications**, look for:
- Partial completeness ("only Results", "some data", "processing scripts only")
- Substantial barriers ("data use agreement", "proprietary", "confidential")
- Unclear or ambiguous availability

**For closed classifications**, look for:
- "Available upon request" language
- Author contact required
- No availability statement

## Performance Expectations

### Latency

- **Single classification**: 5-10 seconds per statement
- **Batch processing**: ~25-50 minutes for 300 publications
- **Retry handling**: Automatic retry with exponential backoff (3 attempts max)

### Accuracy Targets

Based on validation against human-coded ground truth:

- **Overall accuracy**: 80%+ for refined taxonomy
- **Cohen's kappa**: > 0.70 (substantial agreement)
- **F1-score**: > 0.75 for all four categories
- **Reasoning quality**: 90%+ of mostly_open/mostly_closed classifications explicitly mention completeness

### Confidence Scores

The classifier provides confidence scores (0.0-1.0):

- **0.9-1.0**: Very confident (clear indicators, unambiguous)
- **0.7-0.9**: Confident (clear but may have minor ambiguities)
- **0.5-0.7**: Moderate confidence (boundary cases, limited information)
- **Below 0.5**: Low confidence (highly ambiguous, unclear statements)

## Troubleshooting Common Issues

### Issue: Classifications seem inconsistent

**Solution**: Check if you're using enough training examples. The classifier uses k=5 similar examples by default. If your training data is sparse for certain categories, increase k or add more training examples.

```python
from openness_classifier import classify_statement

# Use more examples for better consistency
result = classify_statement(
    statement,
    statement_type="data",
    k=10  # Use 10 similar examples instead of 5
)
```

### Issue: API rate limits or timeouts

**Solution**: The classifier automatically retries with exponential backoff. If you're still hitting limits:

1. Reduce batch size:
```python
# Process in smaller batches
for batch in df.groupby(df.index // 50):  # Batches of 50
    results = classify_batch(batch, ...)
    time.sleep(60)  # Wait between batches
```

2. Increase retry delay:
```python
from openness_classifier.config import load_config

config = load_config()
config.retry_delay = 2.0  # Longer initial delay
config.max_retries = 5    # More retry attempts
```

### Issue: Reasoning doesn't mention completeness

**Possible causes**:
1. Statement doesn't provide enough detail about what's available
2. LLM model temperature too high (causing more variable outputs)
3. Training examples don't emphasize completeness

**Solution**:
```python
# Ensure low temperature for consistency
from openness_classifier.core import LLMConfiguration, LLMProviderType

config = LLMConfiguration(
    provider=LLMProviderType.CLAUDE,
    model_name='claude-3-5-sonnet-20241022',
    temperature=0.1  # Lower = more consistent reasoning
)
```

### Issue: Mostly_open/mostly_closed boundary unclear

**This is expected**: The boundary between these categories is inherently subjective. Key guidelines:

- If **substantial barriers** exist (data use agreement, confidentiality) → **mostly_closed** (hard rule)
- If **high completeness** + **minor barriers** → **mostly_open**
- If **partial completeness** OR **unclear/ambiguous** → default to **mostly_closed**

When in doubt, examine the reasoning to see which factors the classifier prioritized.

### Issue: Classification failed with "unclassified" status

**Causes**:
- API errors after 3 retry attempts
- Malformed LLM response that couldn't be parsed
- Network connectivity issues

**Solution**: Check the error logs for details:

```python
from openness_classifier.core import ClassificationLogger

logger = ClassificationLogger('logs/classifications.jsonl')
# Review the log file for error_type and error_message
```

Then retry the failed publications individually with higher retry limits.

## Next Steps

### For Researchers

- **Classify your corpus**: Use `classify_batch()` to process CSV files of publications
- **Validate results**: Compare against any existing human coding using `validate_classifications()`
- **Analyze patterns**: Use the reasoning outputs to understand what factors drive openness in your field

### For Developers

- **Customize prompts**: See `nbs/03_prompts.ipynb` to modify classification templates
- **Add training data**: Extend `articles_reviewed.csv` with domain-specific examples
- **Fine-tune parameters**: Adjust k (number of examples), temperature, confidence thresholds

### Resources

- **Specification**: See `spec.md` for detailed requirements and scientific rationale
- **Implementation Plan**: See `plan.md` for technical architecture and design decisions
- **Notebooks**:
  - `nbs/examples/01_single_classification.ipynb` - Interactive examples
  - `nbs/examples/02_batch_processing.ipynb` - Batch processing workflows
  - `nbs/examples/03_validation_analysis.ipynb` - Validation and metrics

## Support

For questions or issues:

1. Check the reasoning output to understand the classification logic
2. Review the examples in this guide
3. Consult the specification (`spec.md`) for edge case handling rules
4. Examine the validation notebook for performance benchmarking examples

The refined taxonomy aims to provide more nuanced classifications that better reflect the spectrum of research openness. By explicitly considering completeness, barriers, and repository quality, you can better quantify and analyze open science practices in your field.
