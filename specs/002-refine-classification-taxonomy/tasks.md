# Tasks: Refined Classification Taxonomy

**Input**: Design documents from `/specs/002-refine-classification-taxonomy/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Tests**: Tests are NOT explicitly requested in the specification, so test tasks are excluded. Validation will be performed through comparison with ground truth data (articles_reviewed.csv).

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **nbdev project**: `openness_classifier/` (source), `nbs/` (notebooks), `tests/` (tests)
- Paths follow the existing project structure (single Python package with notebook-based development)

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and configuration for refined taxonomy feature

- [ ] T001 Create feature branch 002-refine-classification-taxonomy and validate git status
- [ ] T002 Review research.md completeness indicator refinements and update spec.md FR-002/FR-003 if needed based on research findings (data: add "Raw" standalone, code: add "Model" and "Models" standalone)
- [ ] T003 [P] Configure LLM provider max_tokens increase from 500 to 750-1000 in openness_classifier/config.py to accommodate longer reasoning outputs

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure enhancements that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [ ] T004 Implement retry logic with exponential backoff (3 retries, 1s initial delay, 2x multiplier, full jitter) in openness_classifier/core.py LLMProvider.complete() method (research decision: use LiteLLM retry config with retryable codes [408, 429, 500, 502, 503, 504])
- [ ] T005 [P] Add ClassificationFailure dataclass to openness_classifier/core.py with fields: publication_id, error_type, retry_count, final_status, error_reason (per data-model.md)
- [ ] T006 [P] Enhance Classification dataclass in openness_classifier/core.py to validate that reasoning field is non-empty for mostly_open/mostly_closed classifications (FR-008 validation)
- [ ] T007 Update parse_classification_response() in openness_classifier/prompts.py to extract completeness attributes from reasoning text (keyword detection for data/code types)

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Classify Statements with Refined Taxonomy (Priority: P1) 🎯 MVP

**Goal**: Enable accurate classification of statements distinguishing mostly_open from mostly_closed based on completeness attributes, access barriers, and repository type

**Independent Test**: Classify a sample of "Partially Closed" publications with different completeness levels and verify correct assignment to mostly_open vs mostly_closed based on refined rules (acceptance scenarios 1-4)

**Acceptance Criteria**:
1. Data statement "Raw; Results; Source Data available with registration" → mostly_open
2. Data statement "Results available via data use agreement" → mostly_closed
3. Code statement "All code on GitHub" → mostly_open
4. Code statement "Processing scripts in supplementary" → mostly_closed

### Implementation for User Story 1

- [ ] T008 [P] [US1] Update SYSTEM_PROMPT in openness_classifier/prompts.py with refined category definitions emphasizing completeness attributes for mostly_open vs mostly_closed boundary (per research.md 5-step structure)
- [ ] T009 [P] [US1] Enhance DATA_CLASSIFICATION_TEMPLATE in openness_classifier/prompts.py with 5-step chain-of-thought reasoning: (1) identify data types, (2) assess completeness, (3) identify access barriers, (4) determine repository type, (5) apply classification rules with hard precedence
- [ ] T010 [P] [US1] Enhance CODE_CLASSIFICATION_TEMPLATE in openness_classifier/prompts.py with 5-step chain-of-thought reasoning: (1) identify code types, (2) assess completeness, (3) identify access barriers, (4) determine repository type, (5) apply classification rules with hard precedence
- [ ] T011 [US1] Update SYSTEM_PROMPT with hard precedence rule enforcement: "CRITICAL RULE: If substantial access barriers exist (data use agreements, proprietary terms, confidentiality restrictions), classification MUST be mostly_closed or closed, regardless of completeness or repository quality" (FR-004 three-layer enforcement per research.md)
- [ ] T012 [US1] Add completeness indicator checklists to classification templates in openness_classifier/prompts.py: data mostly_open indicators (All, Raw; Results; Source Data, Raw; Results, Raw) and code mostly_open indicators (All, Model, Models, 7 other combinations per FR-002/FR-003 as refined in research.md)
- [ ] T013 [US1] Update classify_statement() in openness_classifier/classifier.py to use enhanced prompts and validate reasoning quality (ensure completeness attributes mentioned for mostly_open/mostly_closed)
- [ ] T014 [US1] Add validation logic in openness_classifier/classifier.py to enforce hard precedence rule post-classification: if substantial barriers detected in statement AND category is mostly_open, downgrade to mostly_closed with logged warning
- [ ] T015 [US1] Update nbs/03_prompts.ipynb with examples demonstrating refined taxonomy classification with reasoning outputs showing completeness assessment
- [ ] T016 [US1] Update nbs/04_classifier.ipynb with examples of mostly_open vs mostly_closed classification boundary cases (high completeness + minor barriers vs low completeness + no barriers)

**Checkpoint**: At this point, User Story 1 should be fully functional - classifier produces refined classifications with explicit completeness reasoning for mostly_open/mostly_closed boundary

---

## Phase 4: User Story 2 - Enhanced Prompts with Reasoning Guidance (Priority: P2)

**Goal**: Ensure classification reasoning explicitly mentions completeness attributes, repository types, and access barriers to improve transparency and consistency

**Independent Test**: Evaluate classification reasoning outputs for boundary-zone statements and verify the model explicitly considers completeness and barrier types (acceptance scenarios 1-3)

**Acceptance Criteria**:
1. Data classification prompt guides model to assess data types explicitly
2. Code classification prompt guides model to distinguish persistent vs non-persistent repositories
3. Classification reasoning explicitly mentions completeness attributes that influenced decision

### Implementation for User Story 2

- [ ] T017 [P] [US2] Add explicit repository type guidance to classification templates in openness_classifier/prompts.py: "Persistent repositories (Zenodo, Figshare, Dryad with DOIs) provide long-term preservation. Non-persistent repositories (GitHub, personal websites) may be temporary but can still enable reproduction if all materials are present."
- [ ] T018 [P] [US2] Enhance parse_classification_response() in openness_classifier/prompts.py to extract and log mentioned completeness attributes, access barriers, and repository types from reasoning text for transparency validation
- [ ] T019 [US2] Add reasoning quality metrics to Classification dataclass: completeness_attributes_mentioned: List[str], access_barriers_mentioned: List[str] fields (optional, for validation purposes)
- [ ] T020 [US2] Update classify_statement() in openness_classifier/classifier.py to populate reasoning quality fields by parsing reasoning text for attribute keywords
- [ ] T021 [US2] Create tutorial notebook nbs/tutorials/02_refined_taxonomy.ipynb demonstrating how to interpret classification reasoning outputs and identify which completeness attributes influenced decisions
- [ ] T022 [US2] Add examples to tutorial showing: (1) mixed completeness statement with data types extracted, (2) GitHub vs Zenodo comparison with repository type reasoning, (3) access barrier precedence rule in action

**Checkpoint**: At this point, User Stories 1 AND 2 should both work independently - classifications include transparent reasoning with explicit attribute mentions

---

## Phase 5: User Story 3 - Validation with Completeness Attributes (Priority: P3)

**Goal**: Validate refined taxonomy aligns with original completeness coding from articles_reviewed.csv to ensure automated classifier captures human coder nuances

**Independent Test**: Compare classifier outputs against ground truth for publications with known completeness attributes and measure alignment with expected categories (acceptance scenarios 1-3)

**Acceptance Criteria**:
1. Publications with data_included in ["All", "Raw; Results; Source Data", "Raw; Results"] → ≥80% classified as mostly_open
2. Publications with data_included NOT in mostly_open list → ≥80% classified as mostly_closed
3. Publications with code_included in mostly_open categories → ≥80% classified as mostly_open

### Implementation for User Story 3

- [ ] T023 [P] [US3] Add completeness-based validation function to openness_classifier/validation.py: validate_completeness_alignment(classifications, ground_truth_df) that checks if classifications align with data_included/code_included columns per FR-002/FR-003 rules
- [ ] T024 [P] [US3] Add Cohen's kappa calculation for 4-category taxonomy to openness_classifier/validation.py using scikit-learn (SC-002: target > 0.70)
- [ ] T025 [P] [US3] Add F1-score per category calculation to openness_classifier/validation.py (SC-005: target > 0.75 for all categories)
- [ ] T026 [US3] Add reasoning quality metric to openness_classifier/validation.py: calculate percentage of mostly_open/mostly_closed classifications that explicitly mention completeness attributes in reasoning field (SC-004: target 90%)
- [ ] T027 [US3] Create validation analysis notebook nbs/06_validation.ipynb with section for refined taxonomy validation: load articles_reviewed.csv, classify Partially Closed subset, compare against completeness attributes
- [ ] T028 [US3] Add validation visualization to nbs/06_validation.ipynb: confusion matrix for refined 4-category taxonomy, completeness attribute distribution by classification, reasoning quality metrics
- [ ] T029 [US3] Update validation notebook to compute SC-001 (15pp accuracy improvement), SC-002 (kappa > 0.70), SC-003 (80% correct reclassification), SC-004 (90% reasoning mentions completeness), SC-005 (F1 > 0.75)
- [ ] T030 [US3] Add validation report generation in nbs/06_validation.ipynb: summary table of all success criteria with pass/fail status and recommendations for prompt tuning if metrics fall short

**Checkpoint**: All user stories should now be independently functional - refined classifier validated against ground truth with measurable success criteria

---

## Phase 6: Failure Handling & Batch Processing Enhancements (Cross-Cutting)

**Purpose**: Ensure robust failure handling for batch processing (FR-010) and performance optimization

- [ ] T031 [P] Add batch processing failure tracking to openness_classifier/batch.py: maintain list of ClassificationFailure instances for publications that fail after retry exhaustion
- [ ] T032 [P] Update batch processing in openness_classifier/batch.py to continue processing after individual classification failures (graceful degradation per FR-010)
- [ ] T033 Update batch processing to log unclassified publications with error reasons to separate CSV file: unclassified_publications.csv with columns [publication_id, error_type, retry_count, error_reason, timestamp]
- [ ] T034 Add performance benchmarking to nbs/05_batch.ipynb: measure average classification latency on 50-publication test set and verify 5-10 second target per classification (SC-006)
- [ ] T035 Update nbs/05_batch.ipynb with example showing batch processing resilience: simulate API failures and demonstrate continued processing with unclassified publications logged

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Documentation, refinement, and final validation

- [ ] T036 [P] Update README.md with refined taxonomy overview: explain mostly_open vs mostly_closed distinctions based on completeness attributes
- [ ] T037 [P] Update quickstart.md validation: manually test all examples in quickstart.md work with refined prompts and produce expected reasoning outputs
- [ ] T038 Generate updated documentation using nbdev: run `nbdev_docs` to regenerate API documentation reflecting enhanced Classification dataclass and prompt templates
- [ ] T039 [P] Update tutorial notebooks (tutorials/01_single_publication.ipynb if exists) to demonstrate refined taxonomy with before/after examples showing improved classification accuracy
- [ ] T040 Add CHANGELOG.md entry documenting refined taxonomy feature: completeness-based classification, enhanced prompts, validation metrics, failure handling improvements
- [ ] T041 Code review and cleanup: remove debug logging, ensure consistent error messages, validate all file paths in docstrings match actual structure
- [ ] T042 Final validation run: classify all 303 publications from articles_reviewed.csv with refined taxonomy and generate comprehensive validation report confirming all success criteria (SC-001 through SC-006)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-5)**: All depend on Foundational phase completion
  - User stories can proceed in parallel if multiple developers available
  - Recommended sequential: US1 → US2 → US3 (priority order) for single developer
- **Failure Handling (Phase 6)**: Depends on US1 completion (needs classify_statement functionality)
- **Polish (Phase 7)**: Depends on all user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - Core classification with refined taxonomy
- **User Story 2 (P2)**: Can start after US1 T013 (needs classify_statement with enhanced prompts) - Enhances reasoning transparency
- **User Story 3 (P3)**: Can start after US1 completion - Validates US1 classifications against ground truth
- **Failure Handling (Phase 6)**: Can start after US1 completion - Enhances batch processing robustness

### Within Each User Story

**User Story 1**:
- T008, T009, T010 (prompt template updates) can run in parallel
- T011, T012 must complete before T013 (classifier update needs final prompts)
- T014 validation logic requires T013 classifier update
- T015, T016 notebook updates can run in parallel after T013

**User Story 2**:
- T017, T018 (prompt enhancements, parsing) can run in parallel
- T019, T020 (dataclass fields, population) sequential
- T021, T022 tutorial creation can run in parallel after T020

**User Story 3**:
- T023, T024, T025 (validation metrics) can run in parallel
- T026 (reasoning quality) can run in parallel with T023-T025
- T027, T028, T029, T030 (validation notebook) sequential, depend on T023-T026

**Phase 6**:
- T031, T032 (batch failure tracking) can run in parallel
- T033 depends on T032 (logging needs tracking)
- T034, T035 (performance benchmarking) can run in parallel after T033

**Phase 7**:
- T036, T037, T038, T039, T040, T041 can all run in parallel
- T042 (final validation) must be last

### Parallel Opportunities

- **Phase 1**: T002, T003 can run in parallel
- **Phase 2**: T005, T006 can run in parallel with T004 (different files)
- **User Story 1**: T008, T009, T010 (all prompt files); T015, T016 (different notebooks)
- **User Story 2**: T017, T018 (different functions); T021, T022 (tutorial sections)
- **User Story 3**: T023, T024, T025, T026 (all validation functions)
- **Phase 6**: T031, T032, T034, T035 (different aspects)
- **Phase 7**: T036-T041 (all documentation tasks)

---

## Parallel Example: User Story 1

```bash
# Launch all prompt template enhancements in parallel:
Task: "Update SYSTEM_PROMPT in openness_classifier/prompts.py"
Task: "Enhance DATA_CLASSIFICATION_TEMPLATE in openness_classifier/prompts.py"
Task: "Enhance CODE_CLASSIFICATION_TEMPLATE in openness_classifier/prompts.py"

# After T013 completes, launch notebook updates in parallel:
Task: "Update nbs/03_prompts.ipynb with refined taxonomy examples"
Task: "Update nbs/04_classifier.ipynb with boundary case examples"
```

## Parallel Example: User Story 3

```bash
# Launch all validation metric implementations in parallel:
Task: "Add completeness validation to openness_classifier/validation.py"
Task: "Add Cohen's kappa calculation to openness_classifier/validation.py"
Task: "Add F1-score calculation to openness_classifier/validation.py"
Task: "Add reasoning quality metric to openness_classifier/validation.py"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (3 tasks)
2. Complete Phase 2: Foundational (4 tasks - CRITICAL)
3. Complete Phase 3: User Story 1 (9 tasks)
4. **STOP and VALIDATE**: Test US1 independently
   - Classify 10-20 Partially Closed publications manually
   - Verify mostly_open vs mostly_closed boundary decisions are reasonable
   - Check reasoning outputs mention completeness attributes
5. Demo refined classifier if validation passes

**MVP Scope**: 16 tasks total (Phases 1-3)
**Expected Outcome**: Functional refined classifier with improved mostly_open/mostly_closed distinctions

### Incremental Delivery

1. **MVP (Phases 1-3)**: Refined classification with completeness reasoning → Test → Deploy
2. **Enhancement (Phase 4)**: Transparent reasoning with explicit attributes → Test → Deploy
3. **Validation (Phase 5)**: Ground truth validation with success metrics → Test → Deploy
4. **Robustness (Phase 6)**: Failure handling for production batch processing → Test → Deploy
5. **Polish (Phase 7)**: Documentation and final validation → Deploy

Each phase adds measurable value:
- MVP: Core refined taxonomy (SC-001: accuracy improvement)
- Enhancement: Reasoning transparency (SC-004: 90% attribute mentions)
- Validation: Scientific rigor (SC-002: kappa > 0.70, SC-003: 80% reclassification)
- Robustness: Production readiness (SC-006: performance target, FR-010: failure handling)
- Polish: Publication readiness (complete documentation for manuscript methods section)

### Parallel Team Strategy

With 2-3 developers:

1. **Team completes Phases 1-2 together** (7 tasks, foundational)
2. Once Foundational is done:
   - **Developer A**: User Story 1 (T008-T016, 9 tasks) - Core refined classification
   - **Developer B**: User Story 2 (T017-T022, 6 tasks) - Reasoning enhancements (starts after A completes T013)
   - **Developer C**: User Story 3 (T023-T030, 8 tasks) - Validation metrics (starts after A completes Phase 3)
3. **Team tackles Phases 6-7 together** (12 tasks, cross-cutting)

**Timeline Estimate** (single developer, 8 task-hours/day):
- Setup + Foundational: 1 day
- User Story 1: 1.5 days
- User Story 2: 1 day
- User Story 3: 1.5 days
- Phases 6-7: 2 days
- **Total**: ~7 days for complete feature with validation

---

## Notes

- **[P] tasks**: Different files, no dependencies - safe to parallelize
- **[Story] labels**: Map task to specific user story for traceability and independent testing
- **nbdev workflow**: Notebooks (nbs/) are source of truth, export to openness_classifier/ package
- **Validation-driven**: Each user story has explicit acceptance criteria and independent test strategy
- **Research-informed**: Tasks incorporate decisions from research.md (5-step CoT, completeness indicators, backoff strategy)
- **Ground truth validation**: Success criteria measurable against articles_reviewed.csv (SC-001 through SC-006)
- **Failure resilience**: FR-010 implemented in Phase 6 for robust batch processing
- **Performance target**: SC-006 (5-10s per classification) validated in Phase 6 benchmarking
- **Backward compatibility**: No breaking changes to existing API (OpennessCategory, Classification dataclass extensions only)

**Critical Path**: Setup → Foundational → User Story 1 core classification → Validation
**Riskiest Task**: T013 (classify_statement update) - core classification logic changes
**Highest Value**: T008-T012 (enhanced prompts) - directly address refined taxonomy requirement
**Key Validation**: T027-T030 (validation notebook) - measures all success criteria scientifically
