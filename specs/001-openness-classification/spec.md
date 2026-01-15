# Feature Specification: Openness Classification Model

**Feature Branch**: `001-openness-classification`
**Created**: 2026-01-15
**Status**: Draft
**Input**: User description: "we are going to use the @articles_reviewed.csv file to develop a model that estimates the degree of openness of a manuscript's data and code (separately) based on the information in that file. The model take as input a data_statement and/or a code_statement (they are often the same text) for a publication and then will return a classification of the openness of the data and/or the code. These classifications are provided in the data_open and data_closed columns of the csv file, so everything needed is in the model. We may want to develop our model around a few-shot model that works with an LLM because the sample size is limited (not suitable for traditional ML techniques)."

## Clarifications

### Session 2026-01-15

- Q: What are the exact openness classification categories? → A: open, mostly open, mostly closed, closed (4-category ordinal taxonomy matching articles_reviewed.csv data_open/code_open columns)
- Q: What user interface type should the system provide? → A: nbdev framework (literate programming: Jupyter notebooks for development/exploration + auto-generated Python library/API for portability and reuse)
- Q: How should "available upon request" statements be classified? → A: classified as "closed" per existing rubric in articles_reviewed.csv (conditional/request-based access is not considered open)
- Q: What are the CSV column names for input statements? → A: data_statement and code_statement (separate columns in articles_reviewed.csv)
- Q: Which LLM API should the system use? → A: multi-provider support (Claude API, OpenAI API, or local models via Ollama) - user provides API key/URL via initialization configuration

## Research Context

### Research Objective

Develop a classification model to assess the degree of openness of scholarly publications' data and code based on data availability statements and code availability statements. This supports systematic evaluation of open science practices in published research and enables quantitative analysis of FAIR principle adherence across scientific literature. The model will facilitate meta-analysis of data and code sharing practices, identifying patterns in open science adoption and barriers to data/code accessibility.

### Method References

- Wilkinson, M. D., et al. (2016). The FAIR Guiding Principles for scientific data management and stewardship. Scientific Data, 3, 160018. https://doi.org/10.1038/sdata.2016.18
- Brown, T., et al. (2020). Language Models are Few-Shot Learners. NeurIPS. https://arxiv.org/abs/2005.14165 (Few-shot learning approach)
- Gabelica, M., et al. (2022). Many researchers were not compliant with their published data sharing statement: mixed-observational study. Journal of Clinical Epidemiology, 150, 33-41. https://doi.org/10.1016/j.jclinepi.2022.05.019

### Validation Approach

- **Validation Strategy**: Validate classification accuracy using holdout test set from articles_reviewed.csv with known openness classifications. Cross-validate model predictions against human-coded openness assessments. Test inter-rater reliability by comparing model classifications to multiple independent human raters on a subset of statements.
- **Test Data**: Use stratified split of articles_reviewed.csv (e.g., 80/20 train/test split) ensuring representation across openness categories. Include edge cases such as ambiguous statements, partial data sharing, and conditional access scenarios.
- **Success Criteria**: Model achieves minimum 80% accuracy on test set for both data and code openness classifications. Model predictions show substantial agreement (Cohen's kappa > 0.6) with human raters.

### Assumptions & Limitations

**Scientific Assumptions**:
- Data and code availability statements contain sufficient information to infer openness classification
- Few-shot learning with LLM can capture semantic patterns in openness statements with limited training examples
- The existing classifications in articles_reviewed.csv (data_open/code_open columns) represent reliable ground truth labels
- Data and code openness can be treated as separate but parallel classification tasks
- Classification rubric: conditional/request-based access (e.g., "available upon request") is classified as "closed", not a middle category

**Known Limitations**:
- Model performance depends on quality and consistency of existing human classifications in training data
- Limited sample size constrains ability to detect rare patterns or edge cases
- Model may struggle with novel phrasing or domain-specific terminology not represented in training data
- Classification accuracy may vary across scientific disciplines with different data sharing norms
- Temporal drift: openness terminology and practices evolve over time, requiring periodic model retraining

### Manuscript Integration Notes

- **Methods Section**: "We developed a classification model to assess data and code openness based on availability statements using few-shot learning with large language models. The model was trained on manually coded publications (n=[N]) and validated using [validation approach]. Classification performance was evaluated using accuracy, precision, recall, and Cohen's kappa for agreement with human raters."
- **Software Citation**: Document specific LLM provider and model used (e.g., "Claude Sonnet 3.5 via Anthropic API", "GPT-4-turbo via OpenAI API", "Llama 3 8B via Ollama"), including version and endpoint. Cite few-shot learning framework and any prompt engineering techniques employed.
- **Reproducibility**: Archive training data (articles_reviewed.csv), model prompts/configuration, LLM provider/model/version details, classification outputs, and validation metrics. Provide code for reproducing classifications and validation analyses. Document LLM configuration (provider, model, version, temperature, etc.) and date of model runs (critical for reproducibility given model versioning across providers).

---

## User Scenarios & Testing

### User Story 1 - Classify Single Publication Openness (Priority: P1)

A researcher has a data availability statement and/or code availability statement from a publication and wants to determine the openness classification for both data and code.

**Why this priority**: This is the core functionality - the minimum viable product that delivers immediate value. A working single-classification capability enables validation of the approach before scaling to batch processing.

**Independent Test**: Can be fully tested by providing a sample statement text and verifying the model returns valid openness classifications ("open", "mostly open", "mostly closed", "closed") for both data and code, matching expected classifications from the training data.

**Acceptance Scenarios**:

1. **Given** a publication with a data availability statement, **When** the user provides the statement text to the classifier (via notebook or library API), **Then** the system returns a data openness classification with confidence score
2. **Given** a publication with a code availability statement, **When** the user provides the statement text to the classifier (via notebook or library API), **Then** the system returns a code openness classification with confidence score
3. **Given** a publication where data and code statements are identical, **When** the user provides the statement, **Then** the system returns both data and code openness classifications independently
4. **Given** a publication with only a data statement (no code statement), **When** the user provides only the data statement, **Then** the system returns only data openness classification and indicates code classification is not available
5. **Given** an ambiguous or unclear statement, **When** the user provides the statement, **Then** the system returns a classification with lower confidence score and indicates uncertainty
6. **Given** a researcher using the library programmatically, **When** they import the module and call classification functions, **Then** the library provides the same functionality as the notebook interface

---

### User Story 2 - Batch Classification of Multiple Publications (Priority: P2)

A researcher has a dataset of multiple publications (CSV format) with data and code availability statements and wants to classify openness for all publications efficiently.

**Why this priority**: Scales the single-classification capability to handle systematic reviews and meta-analyses. Essential for analyzing large corpora but depends on the core classification logic being validated first.

**Independent Test**: Can be tested by providing a CSV file with multiple statement texts and verifying the system processes all rows, returns classifications for each publication, and handles errors gracefully (e.g., missing statements, malformed data).

**Acceptance Scenarios**:

1. **Given** a CSV file with columns data_statement and code_statement (matching articles_reviewed.csv format), **When** the user runs batch classification, **Then** the system processes all rows and returns classifications for each publication
2. **Given** some publications missing data or code statements, **When** batch processing runs, **Then** the system handles missing values appropriately (marks as "not available") without failing
3. **Given** a large dataset (>100 publications), **When** batch processing runs, **Then** the system provides progress indication and completes within reasonable time
4. **Given** batch processing completes, **When** the user reviews results, **Then** classifications are appended to the original CSV or exported as a new file with publication identifiers preserved

---

### User Story 3 - Model Performance Evaluation and Reporting (Priority: P3)

A researcher wants to understand model performance, including accuracy metrics, confusion matrices, and examples of misclassifications to assess trustworthiness of the classifications.

**Why this priority**: Builds confidence in model results and supports transparent reporting in publications. Important for scientific rigor but not required for basic classification functionality.

**Independent Test**: Can be tested by running validation analysis on test set and verifying the system generates comprehensive performance metrics (accuracy, precision, recall, F1, Cohen's kappa) and visualizations (confusion matrix, error analysis).

**Acceptance Scenarios**:

1. **Given** a test dataset with known classifications, **When** the user runs validation, **Then** the system reports accuracy, precision, recall, and F1 scores for data and code classifications separately
2. **Given** validation results, **When** the user requests detailed analysis, **Then** the system provides confusion matrices showing true positives, false positives, true negatives, and false negatives
3. **Given** misclassified examples, **When** the user reviews error analysis, **Then** the system displays sample statements that were misclassified with predicted vs. actual labels
4. **Given** validation metrics, **When** the user generates a report, **Then** the system produces a summary suitable for manuscript methods/results sections

---

### User Story 4 - Model Training and Refinement (Priority: P4)

A researcher wants to update the model with new training examples or adjust classification categories to improve performance or adapt to new data sharing practices.

**Why this priority**: Enables ongoing model improvement and adaptation. Important for long-term utility but not essential for initial deployment.

**Independent Test**: Can be tested by providing updated training data and verifying the model retrains successfully and performance metrics change appropriately.

**Acceptance Scenarios**:

1. **Given** new manually coded publications, **When** the user adds them to the training data, **Then** the system retrains the model incorporating the new examples
2. **Given** poor performance on specific openness categories, **When** the user adds targeted examples for those categories, **Then** model performance improves on the targeted categories in validation
3. **Given** evolving openness terminology, **When** the user reviews model predictions, **Then** the system identifies low-confidence predictions that may indicate need for additional training examples

---

### Edge Cases

- What happens when a statement contains contradictory information (e.g., conflicting access terms within the same statement)?
- How does the system handle statements in non-English languages or with significant OCR errors?
- What happens when a publication has separate statements for different data types (e.g., "raw data available, processed data not shared")?
- How does the system handle statements with unclear language or missing critical information about access restrictions?
- What happens when code statements refer to proprietary software vs. open-source code?
- How does the system handle missing or null values in the CSV input?
- What happens when the LLM API is unavailable or rate-limited during batch processing?
- How does the system handle switching between LLM providers (Claude/OpenAI/Ollama) mid-project?
- What happens if the user hasn't configured API credentials or Ollama isn't running locally?

**Classification Rules** (per articles_reviewed.csv rubric):
- Conditional/request-based access ("available upon request", "available with data use agreement", etc.) → classified as "closed"

## Requirements

### Functional Requirements

- **FR-001**: System MUST accept text input containing data availability statements and/or code availability statements
- **FR-002**: System MUST classify data openness and code openness separately using the 4-category ordinal taxonomy: "open", "mostly open", "mostly closed", "closed"
- **FR-003**: System MUST return classification results with confidence scores or uncertainty indicators
- **FR-004**: System MUST handle missing statements (data or code) gracefully without failing
- **FR-005**: System MUST support batch processing of multiple publications from CSV input with columns data_statement and code_statement (matching articles_reviewed.csv format)
- **FR-006**: System MUST preserve publication identifiers when processing batch data to enable result matching
- **FR-007**: System MUST validate input CSV format (presence of data_statement and code_statement columns) and provide clear error messages for malformed inputs
- **FR-008**: System MUST support training/retraining using articles_reviewed.csv with known classifications
- **FR-009**: System MUST provide validation metrics including accuracy, precision, recall, F1, and Cohen's kappa
- **FR-010**: System MUST generate confusion matrices for data and code classifications
- **FR-011**: System MUST handle LLM API errors (timeouts, rate limits, service unavailability) with appropriate retry logic or fallback behavior
- **FR-012**: System MUST log classification decisions, model prompts, and LLM configuration (provider, model, version) to support reproducibility and debugging
- **FR-013**: System MUST be developed using nbdev framework, providing both interactive notebook interface for exploration and auto-generated Python library/API for programmatic use
- **FR-014**: System MUST support multiple LLM providers (Claude API, OpenAI API, local models via Ollama) with user-configurable provider selection and credentials via initialization

### Key Entities

- **Publication**: Represents a scholarly article with data and code availability statements. Key attributes: publication identifier (DOI, PMID, or internal ID), data_statement (text), code_statement (text), data_openness_classification, code_openness_classification, classification_confidence.

- **Classification**: Represents an openness assessment for data or code. Key attributes: classification_type (data or code), openness_category (ordinal scale: "open", "mostly open", "mostly closed", "closed"), confidence_score, classification_timestamp, model_version.

- **Training Example**: Represents a manually coded publication used for model training. Key attributes: statement_text, ground_truth_classification, source (articles_reviewed.csv), annotation_date, annotator_id (if available).

- **Validation Result**: Represents model performance metrics. Key attributes: accuracy, precision, recall, F1_score, cohens_kappa, confusion_matrix, test_set_size, validation_date, model_version.

- **LLM Configuration**: Represents the language model configuration for reproducibility. Key attributes: provider (Claude/OpenAI/Ollama), model_name (e.g., "claude-sonnet-3.5", "gpt-4-turbo", "llama3:8b"), api_endpoint, model_version, temperature, max_tokens, configuration_timestamp.

## Success Criteria

### Measurable Outcomes

- **SC-001**: Researchers can classify data and code openness for a single publication statement in under 10 seconds (including API latency)
- **SC-002**: Model achieves minimum 80% accuracy on held-out test data for both data and code classifications
- **SC-003**: Model demonstrates substantial agreement (Cohen's kappa > 0.6) with independent human raters on a validation set
- **SC-004**: Batch processing handles datasets of 100+ publications without manual intervention or failures
- **SC-005**: Classification results enable researchers to quantify open science practices in systematic reviews (e.g., "X% of publications provide open data")
- **SC-006**: Model validation and performance reporting provides sufficient documentation for manuscript methods sections without additional analysis
- **SC-007**: System handles 95% of real-world availability statements from diverse scientific disciplines without requiring manual review
