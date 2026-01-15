# Quickstart Guide: Openness Classification Model

**Feature**: Openness Classification Model
**Date**: 2026-01-15
**Audience**: Researchers using the classification tool

## Overview

This guide will help you get started classifying publication data and code availability statements using the `openness_classifier` library. The tool uses few-shot learning with large language models to classify statements into a 4-category ordinal taxonomy: **open**, **mostly open**, **mostly closed**, **closed**.

## Prerequisites

- Python 3.10 or higher
- Access to at least one LLM provider:
  - **Claude API** (Anthropic) - recommended for research
  - **OpenAI API** (GPT-4)
  - **Ollama** (local models) - free, no API costs

- Training data: `articles_reviewed.csv` with human-coded examples

## Installation

### Option 1: Using pip (when package is published)

```bash
pip install openness-classifier
```

### Option 2: Development installation with nbdev

```bash
# Clone the repository
git clone https://github.com/your-org/ef_2026.git
cd ef_2026

# Install dependencies with pixi (recommended for reproducibility)
pixi install

# Or use pip with requirements.txt
pip install -r requirements.txt

# Install nbdev and prepare library
nbdev_install_quarto  # Install Quarto for documentation
nbdev_install_hooks   # Install git hooks
cd nbs && nbdev_prepare  # Build library from notebooks
```

## Configuration

### Step 1: Set up LLM Provider Credentials

Create a `.env` file in the project root or set environment variables:

#### For Claude API:
```bash
export LLM_PROVIDER=claude
export ANTHROPIC_API_KEY=sk-ant-your-api-key-here
export LLM_MODEL_NAME=claude-sonnet-3.5
```

#### For OpenAI API:
```bash
export LLM_PROVIDER=openai
export OPENAI_API_KEY=sk-your-api-key-here
export LLM_MODEL_NAME=gpt-4-turbo
```

#### For Ollama (local models):
```bash
export LLM_PROVIDER=ollama
export OLLAMA_BASE_URL=http://localhost:11434
export LLM_MODEL_NAME=llama3:8b

# Make sure Ollama is running:
ollama serve
ollama pull llama3:8b
```

### Step 2: Prepare Training Data

Ensure `data/articles_reviewed.csv` exists with required columns:
- `id`: Publication identifier
- `data_statement`: Data availability statement text
- `code_statement`: Code availability statement text
- `data_open`: Ground truth data openness (open, mostly open, mostly closed, closed)
- `code_open`: Ground truth code openness

Example CSV structure:
```csv
id,data_statement,code_statement,data_open,code_open
doi:10.1234/ex1,"Data on Zenodo","Code on GitHub",open,open
doi:10.1234/ex2,"Data upon request","Not available",closed,closed
```

## Usage

### 1. Classify a Single Statement (Interactive Notebook)

Open `nbs/examples/01_single_classification.ipynb` in Jupyter:

```python
from openness_classifier.classifier import classify_statement
from openness_classifier.config import load_config

# Load configuration from environment
config = load_config()

# Classify a data statement
statement = "Data are openly available on Zenodo at doi:10.5281/zenodo.123456"
result = classify_statement(
    statement=statement,
    statement_type="data",
    config=config,
    return_reasoning=True
)

print(f"Classification: {result.category}")
print(f"Confidence: {result.confidence_score:.2f}")
print(f"Reasoning: {result.reasoning}")
```

**Expected Output**:
```
Classification: open
Confidence: 0.95
Reasoning: The statement explicitly mentions data being "openly available" on Zenodo,
a recognized open data repository, with a DOI for findability. This indicates
full open access with no restrictions mentioned.
```

### 2. Classify Both Data and Code for a Publication

```python
from openness_classifier.classifier import classify_publication
from openness_classifier.data import Publication

# Create a publication
pub = Publication(
    id="doi:10.1234/example",
    data_statement="Data available upon reasonable request from the corresponding author",
    code_statement="Analysis code available on GitHub: github.com/user/repo"
)

# Classify both statements
data_class, code_class = classify_publication(pub, return_reasoning=False)

print(f"Data: {data_class.category} (confidence: {data_class.confidence_score:.2f})")
print(f"Code: {code_class.category} (confidence: {code_class.confidence_score:.2f})")
```

**Expected Output**:
```
Data: closed (confidence: 0.88)
Code: mostly open (confidence: 0.82)
```

### 3. Batch Process a CSV File

Open `nbs/examples/02_batch_processing.ipynb`:

```python
from openness_classifier.batch import classify_csv
from pathlib import Path

def progress_callback(processed, total):
    percent = 100 * processed / total
    print(f"Progress: {processed}/{total} ({percent:.1f}%)", end="\r")

# Process CSV file
job = classify_csv(
    input_path="data/articles_reviewed.csv",
    output_path="data/classified_output.csv",
    progress_callback=progress_callback,
    error_handling="skip"  # Skip publications that fail, don't stop processing
)

print(f"\n\nBatch Processing Complete!")
print(f"  Processed: {job.processed_count}/{job.total_publications}")
print(f"  Failed: {job.failed_count}")
print(f"  Duration: {(job.end_time - job.start_time).total_seconds():.1f}s")
print(f"  Output: {job.output_file}")
```

**Output CSV** (`data/classified_output.csv`) will have added columns:
```csv
id,data_statement,code_statement,data_open,code_open,data_classification,data_confidence,code_classification,code_confidence
doi:10.1234/ex1,"Data on Zenodo","Code on GitHub",open,open,open,0.95,open,0.92
...
```

### 4. Validate Model Performance

Open `nbs/examples/03_validation_analysis.ipynb`:

```python
from openness_classifier.validation import validate_classifications
from openness_classifier.data import load_training_data
import pandas as pd
from sklearn.model_selection import train_test_split

# Load and split data
df = pd.read_csv("data/articles_reviewed.csv")
train_df, test_df = train_test_split(df, test_size=0.2, stratify=df['data_open'], random_state=42)

# Save test set for validation
test_df.to_csv("data/test_set.csv", index=False)

# Run validation
results = validate_classifications(test_df)

# Print metrics
print("Data Classification Metrics:")
print(f"  Accuracy: {results.data_metrics.accuracy:.3f}")
print(f"  Macro F1: {results.data_metrics.macro_f1:.3f}")
print(f"  Cohen's Kappa: {results.data_metrics.cohens_kappa:.3f}")

print("\nCode Classification Metrics:")
print(f"  Accuracy: {results.code_metrics.accuracy:.3f}")
print(f"  Macro F1: {results.code_metrics.macro_f1:.3f}")
print(f"  Cohen's Kappa: {results.code_metrics.cohens_kappa:.3f}")

# Plot confusion matrices
results.plot_confusion_matrix("data", save_path="figures/confusion_matrix_data.png")
results.plot_confusion_matrix("code", save_path="figures/confusion_matrix_code.png")

# Export for manuscript
markdown_table = results.to_markdown()
with open("results/validation_metrics.md", "w") as f:
    f.write(markdown_table)
```

**Expected Output**:
```
Data Classification Metrics:
  Accuracy: 0.842
  Macro F1: 0.815
  Cohen's Kappa: 0.723

Code Classification Metrics:
  Accuracy: 0.798
  Macro F1: 0.761
  Cohen's Kappa: 0.658
```

## Using the Library Programmatically

Once the library is built from notebooks, you can use it in any Python script:

```python
# myproject/analyze_publications.py
from openness_classifier.classifier import classify_csv
from openness_classifier.config import load_config

config = load_config()  # Loads from environment variables

job = classify_csv(
    input_path="my_publications.csv",
    output_path="my_publications_classified.csv"
)

print(f"Classified {job.processed_count} publications")
```

## Working with Notebooks (nbdev Workflow)

### Editing and Development

1. **Edit notebooks** in `nbs/` - this is your source of truth
2. **Export to library**: After editing, run `nbdev_export` to regenerate Python files
3. **Run tests**: Use `nbdev_test` to run all tests in notebooks
4. **Preview docs**: Run `nbdev_preview` to preview documentation locally

### Notebook Structure

Each core notebook (e.g., `nbs/04_classifier.ipynb`) includes:
- **Explanation cells**: Markdown explaining the approach (WHY)
- **Code cells with `#export`**: Code exported to library
- **Example cells**: Usage examples for documentation
- **Test cells**: Tests using `assert` or `test_eq` from nbdev

Example notebook cell:
```python
#|export
def classify_statement(statement: str, statement_type: str) -> Classification:
    """Classify an availability statement.

    Args:
        statement: The availability statement text
        statement_type: Either 'data' or 'code'

    Returns:
        Classification with category and confidence
    """
    # Implementation here...
```

## Configuration Options

### LLM Parameters

Adjust in `.env` or config file:

```bash
LLM_TEMPERATURE=0.1       # Lower = more deterministic (0.0-2.0)
LLM_MAX_TOKENS=500        # Maximum response length
LLM_TOP_P=0.95            # Nucleus sampling (0.0-1.0)
```

### Few-Shot Settings

In code or config:

```python
from openness_classifier.config import set_few_shot_config

set_few_shot_config(
    k_examples=3,              # Number of examples per prompt
    selection_method="knn",    # "knn" or "random"
    embedding_model="all-MiniLM-L6-v2"  # For semantic similarity
)
```

## Reproducibility

### Logging All Classifications

All classification decisions are automatically logged to `logs/classifications_{timestamp}.jsonl`:

```json
{"timestamp": "2026-01-15T10:30:00Z", "publication_id": "doi:123", "data_category": "open", "data_confidence": 0.95, "model_config": {"provider": "claude", "model_name": "claude-sonnet-3.5", "temperature": 0.1}}
```

### Saving Configuration for Manuscript

```python
from openness_classifier.config import load_config, save_config

config = load_config()
save_config(config, "manuscript_materials/llm_configuration.json")
```

Include this JSON file as supplementary material when publishing to ensure full reproducibility.

## Troubleshooting

### Error: "API key not found"

**Solution**: Set the appropriate environment variable:
```bash
export ANTHROPIC_API_KEY=your-key  # For Claude
export OPENAI_API_KEY=your-key     # For OpenAI
```

### Error: "Ollama connection refused"

**Solution**: Start the Ollama server:
```bash
ollama serve
```

And ensure the model is downloaded:
```bash
ollama pull llama3:8b
```

### Low Classification Accuracy (<70%)

**Possible causes**:
1. **Insufficient training examples**: Ensure articles_reviewed.csv has at least 50+ examples per category
2. **Class imbalance**: Check distribution of categories, consider oversampling minority classes
3. **Poor example selection**: Try increasing `k_examples` or using better embedding model
4. **Ambiguous statements**: Review misclassified examples for patterns

**Solutions**:
- Add more training examples for underrepresented categories
- Experiment with different LLM models or parameters
- Review and refine classification rubric

### High API Costs

**Solutions**:
1. **Use Ollama for development**: Free local models (llama3, mistral)
2. **Set rate limits**: `set_rate_limit(requests_per_minute=10)`
3. **Test on small samples first**: Validate on 10-20 publications before running full batch

## Next Steps

1. **Explore examples**: Work through all notebooks in `nbs/examples/`
2. **Customize prompts**: Edit `nbs/03_prompts.ipynb` to refine classification prompts
3. **Add training data**: Expand `articles_reviewed.csv` with more coded examples
4. **Run validation**: Establish baseline performance metrics
5. **Integrate into workflow**: Use the library in your systematic review pipeline

## Getting Help

- **Documentation**: Run `nbdev_preview` and visit http://localhost:3000
- **Issues**: Report bugs or feature requests on GitHub Issues
- **Examples**: See `nbs/examples/` for complete workflows

## References

- **nbdev Documentation**: https://nbdev.fast.ai
- **Few-Shot Learning**: Brown et al. (2020). Language Models are Few-Shot Learners. https://arxiv.org/abs/2005.14165
- **FAIR Principles**: Wilkinson et al. (2016). The FAIR Guiding Principles. https://doi.org/10.1038/sdata.2016.18
