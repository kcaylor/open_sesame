# Tasks: Openness Classification Model

**Input**: Design documents from `/specs/001-openness-classification/`
**Prerequisites**: plan.md (✅), spec.md (✅), research.md (✅), data-model.md (✅), contracts/ (✅)

**Tests**: Tests are OPTIONAL for research tools. Tasks below focus on implementation and validation using real research data.

**Organization**: Tasks are grouped by user story (P1-P4) to enable independent implementation and testing of each research workflow capability.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3, US4)
- Include exact file paths in descriptions

## Path Conventions

Using nbdev structure (literate programming):
- **Notebooks**: `nbs/` (source of truth - Jupyter notebooks)
- **Library**: `openness_classifier/` (auto-generated from notebooks via nbdev)
- **Tests**: `tests/` (auto-generated + custom)
- **Data**: `data/` (training data, examples)
- **Examples**: `nbs/examples/` (user-facing tutorial notebooks)

---

## Phase 1: Setup (Project Initialization)

**Purpose**: Initialize nbdev project structure and dependencies

- [ ] T001 Create nbdev project structure with settings.ini, pyproject.toml, and nbs/ directory
- [ ] T002 Initialize pixi environment with pixi.toml for Python 3.10+ and core dependencies (nbdev, pandas, scikit-learn)
- [ ] T003 [P] Add LLM provider dependencies to pixi.toml (anthropic, openai, requests for Ollama)
- [ ] T004 [P] Add visualization dependencies to pixi.toml (matplotlib, seaborn, sentence-transformers)
- [ ] T005 Create data/ directory and add data/README.md documenting data provenance for articles_reviewed.csv
- [ ] T006 [P] Create logs/ directory for classification logging and reproducibility tracking
- [ ] T007 [P] Setup .env.example template with LLM_PROVIDER, API key placeholders, and configuration parameters
- [ ] T008 Configure settings.ini with library name (openness_classifier), author, version, and Python requirements
- [ ] T009 [P] Create .gitignore for Python, Jupyter, data files, logs, and API keys
- [ ] T010 Initialize git repository, create initial commit with project structure

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [ ] T011 Create nbs/index.ipynb as package README with project overview, installation, and quick example
- [ ] T012 Create nbs/00_core.ipynb with base types (OpennessCategory enum, ClassificationType enum) and error classes
- [ ] T013 [P] Create nbs/01_config.ipynb with LLMConfiguration dataclass and environment variable loading (load_config, save_config)
- [ ] T014 [P] Create nbs/02_data.ipynb with data loading functions (load_training_data, train_test_split wrapper) and Publication dataclass
- [ ] T015 Implement TrainingExample dataclass in nbs/02_data.ipynb with statement_text, ground_truth, type, and embedding fields
- [ ] T016 Add sentence embedding computation to nbs/02_data.ipynb using sentence-transformers (all-MiniLM-L6-v2 model)
- [ ] T017 Create nbs/03_prompts.ipynb with few-shot prompt construction functions (build_few_shot_prompt, select_knn_examples)
- [ ] T018 Implement kNN example selection in nbs/03_prompts.ipynb using semantic similarity with training examples
- [ ] T019 Add chain-of-thought prompt templates in nbs/03_prompts.ipynb for data and code classification tasks
- [ ] T020 Create LLM provider abstraction in nbs/00_core.ipynb with unified interface for Claude, OpenAI, and Ollama
- [ ] T021 Implement retry logic with exponential backoff in nbs/00_core.ipynb for LLM API error handling
- [ ] T022 Add logging infrastructure in nbs/00_core.ipynb for classification decisions (JSON Lines format to logs/)
- [ ] T023 Run nbdev_export to generate openness_classifier/ library from notebooks
- [ ] T024 Validate that all exported modules import correctly and core types are accessible

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Classify Single Publication Openness (Priority: P1) 🎯 MVP

**Goal**: Enable classification of data and code availability statements for a single publication, returning 4-category openness classifications with confidence scores

**Independent Test**: Provide a sample data/code availability statement from articles_reviewed.csv, call classify_statement(), and verify it returns a valid OpennessCategory ("open", "mostly open", "mostly closed", "closed") with confidence score matching human coding

### Implementation for User Story 1

- [ ] T025 [P] [US1] Create Classification dataclass in nbs/00_core.ipynb with category, confidence_score, reasoning, timestamp, and model_config fields
- [ ] T026 [US1] Implement classify_statement() in nbs/04_classifier.ipynb for single statement classification with LLM call
- [ ] T027 [US1] Add few-shot example selection to classify_statement() using kNN from training data based on semantic similarity
- [ ] T028 [US1] Implement confidence score extraction from LLM response in nbs/04_classifier.ipynb (parse from reasoning or use 0.8 default)
- [ ] T029 [US1] Add optional chain-of-thought reasoning capture in classify_statement() (return_reasoning parameter)
- [ ] T030 [US1] Implement classify_publication() in nbs/04_classifier.ipynb to classify both data_statement and code_statement fields
- [ ] T031 [US1] Handle missing statements gracefully in classify_publication() (return None for missing data or code statements)
- [ ] T032 [US1] Add logging of classification decisions in classify_statement() with publication_id, category, confidence, model_config
- [ ] T033 [US1] Create nbs/examples/01_single_classification.ipynb tutorial notebook with step-by-step examples
- [ ] T034 [US1] Add validation test in nbs/04_classifier.ipynb using 5 sample publications from articles_reviewed.csv (assert correct categories)
- [ ] T035 [US1] Run nbdev_export and verify classify_statement() and classify_publication() are accessible from library
- [ ] T036 [US1] Test classify_statement() with real data from articles_reviewed.csv for each openness category

**Checkpoint**: At this point, single classification should work end-to-end (statement → classification with confidence)

---

## Phase 4: User Story 2 - Batch Classification of Multiple Publications (Priority: P2)

**Goal**: Scale classification to process CSV files with multiple publications efficiently, handling errors gracefully and providing progress feedback

**Independent Test**: Create test CSV with 10 publications (mix of complete, missing data, missing code), run classify_csv(), verify output CSV has classification columns and error handling works

### Implementation for User Story 2

- [ ] T037 [P] [US2] Create BatchJob dataclass in nbs/05_batch.ipynb with job_id, input/output paths, counts, status, and timing
- [ ] T038 [US2] Implement classify_csv() in nbs/05_batch.ipynb with input CSV reading and output CSV writing
- [ ] T039 [US2] Add progress callback support to classify_csv() for progress_callback(processed, total) reporting
- [ ] T040 [US2] Implement error_handling parameter in classify_csv() with "skip", "fail", "log" options for failed classifications
- [ ] T041 [US2] Add publication identifier preservation in classify_csv() to match input/output rows correctly
- [ ] T042 [US2] Handle missing data_statement and code_statement columns in classify_csv() with clear error messages
- [ ] T043 [US2] Add classification result columns to output CSV (data_classification, data_confidence, code_classification, code_confidence)
- [ ] T044 [US2] Implement batch logging to logs/batch_{job_id}.jsonl with all classification decisions and errors
- [ ] T045 [US2] Add BatchJob statistics tracking (processed_count, failed_count, start_time, end_time)
- [ ] T046 [US2] Create nbs/examples/02_batch_processing.ipynb tutorial with example CSV processing and progress display
- [ ] T047 [US2] Add validation test in nbs/05_batch.ipynb using subset of articles_reviewed.csv (10 rows, verify all processed)
- [ ] T048 [US2] Test error handling with malformed CSV (missing columns, empty statements) and verify graceful degradation
- [ ] T049 [US2] Run nbdev_export and verify classify_csv() is accessible from library
- [ ] T050 [US2] Test batch processing with articles_reviewed.csv subset (20 publications) and verify performance (<5 minutes)

**Checkpoint**: Batch processing should handle realistic datasets with robust error handling and progress tracking

---

## Phase 5: User Story 3 - Model Performance Evaluation and Reporting (Priority: P3)

**Goal**: Provide comprehensive validation metrics (accuracy, precision, recall, F1, Cohen's kappa) and visualizations (confusion matrices) for model assessment and manuscript reporting

**Independent Test**: Split articles_reviewed.csv into train/test, run validate_classifications() on test set, verify metrics are generated and confusion matrix plots are created

### Implementation for User Story 3

- [ ] T051 [P] [US3] Create ClassificationMetrics dataclass in nbs/06_validation.ipynb with accuracy, precision, recall, F1, kappa, support
- [ ] T052 [P] [US3] Create ValidationResult dataclass in nbs/06_validation.ipynb with data_metrics, code_metrics, confusion_matrices
- [ ] T053 [US3] Implement validate_classifications() in nbs/06_validation.ipynb to classify test set and compute metrics
- [ ] T054 [US3] Add per-class precision/recall/F1 computation in nbs/06_validation.ipynb using scikit-learn classification_report
- [ ] T055 [US3] Implement Cohen's kappa calculation in nbs/06_validation.ipynb for inter-rater agreement with human coders
- [ ] T056 [US3] Generate confusion matrices in nbs/06_validation.ipynb using scikit-learn for data and code classifications
- [ ] T057 [US3] Add misclassified_examples extraction in ValidationResult (list of tuples with true/predicted labels)
- [ ] T058 [US3] Create plot_confusion_matrix() method in nbs/07_visualization.ipynb with matplotlib/seaborn heatmaps
- [ ] T059 [US3] Implement to_markdown() method in ValidationResult for manuscript-ready metrics tables
- [ ] T060 [US3] Implement to_json() method in ValidationResult for archiving validation results
- [ ] T061 [US3] Add cross_validate() function in nbs/06_validation.ipynb for k-fold cross-validation with stratification
- [ ] T062 [US3] Create nbs/examples/03_validation_analysis.ipynb tutorial with train/test split, validation, and reporting
- [ ] T063 [US3] Add validation test in nbs/06_validation.ipynb using 20% holdout from articles_reviewed.csv
- [ ] T064 [US3] Generate sample confusion matrix plots and save to figures/ directory for documentation
- [ ] T065 [US3] Test to_markdown() output format and verify it matches journal table requirements (APA/Nature style)
- [ ] T066 [US3] Run nbdev_export and verify validate_classifications() and cross_validate() are accessible

**Checkpoint**: Validation and reporting should produce publication-quality metrics and visualizations

---

## Phase 6: User Story 4 - Model Training and Refinement (Priority: P4)

**Goal**: Enable researchers to add new training examples and retrain the model to improve performance or adapt to evolving data sharing practices

**Independent Test**: Add 5 new publications to articles_reviewed.csv, reload training data, verify kNN selection uses new examples and classifications reflect updated training set

### Implementation for User Story 4

- [ ] T067 [P] [US4] Add reload_training_data() function in nbs/02_data.ipynb to refresh training examples from updated CSV
- [ ] T068 [US4] Implement validate_training_data() in nbs/02_data.ipynb to check for required columns, missing values, and class balance
- [ ] T069 [US4] Add class distribution reporting in nbs/02_data.ipynb (warn if any class <10% of total)
- [ ] T070 [US4] Create identify_low_confidence() function in nbs/04_classifier.ipynb to flag predictions with confidence <0.5
- [ ] T071 [US4] Implement suggest_training_examples() in nbs/04_classifier.ipynb to identify statements needing manual coding
- [ ] T072 [US4] Add training data augmentation notebook in nbs/examples/04_model_refinement.ipynb with workflow for adding examples
- [ ] T073 [US4] Document manual coding workflow in nbs/examples/04_model_refinement.ipynb (load suggestions, code, append to CSV)
- [ ] T074 [US4] Add retrain validation in nbs/examples/04_model_refinement.ipynb comparing old vs new model performance
- [ ] T075 [US4] Create performance_comparison() function in nbs/06_validation.ipynb to compare validation results across model versions
- [ ] T076 [US4] Test reload_training_data() with modified articles_reviewed.csv and verify embeddings are recomputed
- [ ] T077 [US4] Run nbdev_export and verify model refinement functions are accessible

**Checkpoint**: Researchers can iteratively improve the model by adding targeted training examples

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Documentation, reproducibility, and manuscript integration improvements

- [ ] T078 [P] Create comprehensive package documentation in nbs/index.ipynb with installation, configuration, and all usage examples
- [ ] T079 [P] Add data/README.md with detailed data provenance for articles_reviewed.csv (source, coding rubric, date)
- [ ] T080 [P] Document classification rubric in nbs/index.ipynb with examples for each category (open, mostly open, mostly closed, closed)
- [ ] T081 [P] Create CONTRIBUTING.md with nbdev workflow instructions (nbdev_export, nbdev_test, nbdev_preview)
- [ ] T082 Add manuscript integration examples in nbs/examples/ showing methods section generation and metric export
- [ ] T083 Create requirements.txt with pinned versions for full reproducibility (pip freeze after pixi install)
- [ ] T084 [P] Add LICENSE file (MIT) for open source distribution
- [ ] T085 [P] Add CITATION.cff file for proper software citation with DOI placeholder
- [ ] T086 Run nbdev_preview to generate and review documentation website locally
- [ ] T087 Run nbdev_test to execute all notebook tests and verify passing
- [ ] T088 Create example_config.json showing LLM configuration for reproducibility documentation
- [ ] T089 Add error handling documentation in nbs/index.ipynb for common issues (missing API keys, Ollama not running)
- [ ] T090 Performance testing with 100 publications to verify <10 minute batch processing time
- [ ] T091 Run quickstart.md validation by following all steps in fresh environment
- [ ] T092 Generate sample outputs for documentation (classification logs, validation reports, confusion matrices)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup (Phase 1) completion - BLOCKS all user stories
- **User Stories (Phase 3-6)**: All depend on Foundational (Phase 2) completion
  - User stories can proceed sequentially in priority order: US1 (P1) → US2 (P2) → US3 (P3) → US4 (P4)
  - Or in parallel if multiple researchers are collaborating
- **Polish (Phase 7)**: Depends on desired user stories being complete (minimum US1-US3 for MVP)

### User Story Dependencies

- **User Story 1 (P1)**: Depends on Foundational (Phase 2) - No dependencies on other user stories ✅ TRUE MVP
- **User Story 2 (P2)**: Depends on US1 (classification logic must work first) - Builds on classify_statement()
- **User Story 3 (P3)**: Depends on US1 (needs classifications to validate) - Independent of US2
- **User Story 4 (P4)**: Depends on US1, US2, US3 (needs full workflow to identify refinement needs)

### Within Each User Story

1. Core dataclasses and types first (T025 for US1, T037 for US2, etc.)
2. Implementation functions next (classify_statement → classify_publication for US1)
3. Logging and error handling
4. Tutorial notebooks and documentation
5. Validation tests with real data
6. nbdev export and library verification

### Parallel Opportunities

**Phase 1 (Setup)**:
- T003 (LLM dependencies) || T004 (viz dependencies) || T006 (logs/) || T007 (.env) || T009 (.gitignore)

**Phase 2 (Foundational)**:
- T013 (config.ipynb) || T014 (data.ipynb) - can develop in parallel notebooks
- After T014-T016 complete: T017-T019 (prompts.ipynb) can start
- After T013 complete: T020-T022 (LLM abstraction) can start

**Phase 3 (US1)**:
- T025 (Classification dataclass) || T033 (example notebook creation) - different files
- After T030 complete: T034 (validation test) || T033 (tutorial completion) || T032 (logging) in parallel

**Phase 4 (US2)**:
- T037 (BatchJob) || T046 (tutorial notebook) - different files

**Phase 5 (US3)**:
- T051 (ClassificationMetrics) || T052 (ValidationResult) - different dataclasses
- T058 (plotting) || T062 (tutorial) || T064 (figures) - different files

**Phase 6 (US4)**:
- T067 (reload) || T072 (tutorial) - different files

**Phase 7 (Polish)**:
- All documentation tasks (T078-T085) can run in parallel
- T086-T091 sequential (test, validate, verify)

---

## Parallel Example: User Story 1

```bash
# After Foundational phase completes, launch in parallel:

# Create dataclass (different file from main classifier)
Task T025: "Create Classification dataclass in nbs/00_core.ipynb"

# Create tutorial notebook (different file)
Task T033: "Create nbs/examples/01_single_classification.ipynb"

# After T026-T030 complete, run validation tasks in parallel:
Task T034: "Add validation test in nbs/04_classifier.ipynb"
Task T035: "Run nbdev_export and verify library functions"
```

---

## Implementation Strategy

### MVP First (User Stories 1-2 Only)

**Goal**: Deliver usable research tool for single and batch classification

1. Complete Phase 1: Setup (T001-T010) → ~1 hour
2. Complete Phase 2: Foundational (T011-T024) → ~4-6 hours
3. Complete Phase 3: User Story 1 (T025-T036) → ~3-4 hours
4. **STOP and VALIDATE**: Test with real articles_reviewed.csv data, verify 80%+ accuracy
5. Complete Phase 4: User Story 2 (T037-T050) → ~2-3 hours
6. **STOP and VALIDATE**: Run batch processing on 50 publications, verify performance
7. Deploy/share with collaborators for systematic review workflow

**Estimated MVP Time**: 10-15 hours of focused development

### Full Feature Set (All User Stories)

1. MVP complete (US1-US2)
2. Add User Story 3 (T051-T066) → ~3-4 hours for validation and reporting
3. **STOP and VALIDATE**: Generate validation metrics, create confusion matrices, verify manuscript-ready output
4. Add User Story 4 (T067-T077) → ~2 hours for model refinement workflow
5. Complete Phase 7: Polish (T078-T092) → ~3-4 hours for documentation and reproducibility
6. **FINAL VALIDATION**: Run quickstart.md end-to-end, verify all examples work
7. Ready for publication and archiving (Zenodo DOI)

**Estimated Full Development Time**: 18-24 hours

### Incremental Delivery Milestones

1. **Milestone 1: Core Classification** (Phases 1-3) → Classify single publications
2. **Milestone 2: Batch Processing** (Phase 4) → Process systematic review datasets
3. **Milestone 3: Validation & Metrics** (Phase 5) → Manuscript-ready performance reporting
4. **Milestone 4: Model Refinement** (Phase 6) → Iterative improvement workflow
5. **Milestone 5: Publication Ready** (Phase 7) → Full documentation and reproducibility

---

## Notes

- [P] tasks = different files/notebooks, can run in parallel
- [Story] label (US1-US4) maps to user stories in spec.md for traceability
- nbdev workflow: Edit notebooks → nbdev_export → test library imports
- Validation uses real articles_reviewed.csv data (not synthetic tests)
- Each user story delivers independent, testable research capability
- Commit after each task or completed notebook
- Stop at checkpoints to validate with real research data
- Focus on research reproducibility over traditional unit tests
- Document all LLM configurations for FAIR compliance
