# Feature Specification: Refined Classification Taxonomy

**Feature Branch**: `002-refine-classification-taxonomy`
**Created**: 2026-01-16
**Status**: Draft
**Input**: User description: "We need to refine how we do our classification. Here are the notes from the code that generated our training data csv: For the partially closed classifications, there are some papers worth identifying as closer to open than the others. We need to adopt this strategy in both how we do our classification, but also refine our prompts to make sure we communicate how to distinguish the categories more clearly."

## Research Context

### Research Objective

Refine the openness classification taxonomy to better distinguish between "mostly_open" and "mostly_closed" categories based on specific attributes of data and code completeness. This refinement addresses the nuanced differences between publications that have substantial barriers to reproduction versus those with minor obstacles but sufficient materials for reproduction.

### Method References

N/A - This feature refines the existing classification rubric rather than implementing new published methods.

### Validation Approach

- **Validation Strategy**: Compare refined classifications against existing human-coded ground truth in articles_reviewed.csv; measure inter-rater agreement improvements
- **Test Data**: Existing 303 publications in articles_reviewed.csv with original classifications and data_included/code_included attributes
- **Success Criteria**: Improved classification accuracy when distinguishing "mostly_open" vs "mostly_closed" based on completeness attributes; Cohen's kappa > 0.7 for refined categories

### Assumptions & Limitations

**Scientific Assumptions**:
- Data/code completeness attributes (e.g., "All", "Raw; Results; Source Data") reliably indicate reproducibility potential
- Publications with more complete materials but minor access barriers (registration, institutional access) should be distinguished from those with substantial barriers (data use agreements, proprietary restrictions)
- Classification decision can be made based on statement content and completeness indicators

**Known Limitations**:
- Subjective boundary between "minor barriers" and "substantial barriers" requires human judgment
- Some statements may lack sufficient detail about completeness to apply refined rules
- Repository type (persistent vs non-persistent) is a key distinguishing factor that may not always be clear from statements

### Manuscript Integration Notes

- **Methods Section**: Document the refined 4-category taxonomy with explicit decision rules for "mostly_open" vs "mostly_closed" based on completeness attributes
- **Reproducibility**: Classification rubric and prompts should be included in supplementary materials for reproducibility

---

## Clarifications

### Session 2026-01-16

- Q: When the LLM provider fails to classify a statement (API timeout, rate limit, malformed response), how should the system handle it? → A: Retry 3 times with exponential backoff, then mark the publication as "unclassified" with error reason logged and continue processing
- Q: The edge case mentions "prioritize the access barrier as the limiting factor" when statements have conflicting signals (e.g., persistent repository + data use agreement). Should this be an absolute rule, or should there be exceptions for specific combinations? → A: Access barrier always takes precedence (hard rule) - any substantial barrier forces mostly_closed regardless of other positive factors
- Q: For batch processing of publications, what is the acceptable latency per classification? → A: 5-10 seconds per classification (allows complex prompts with reasoning, 300 publications in ~25-50 minutes)
- Q: The acceptance scenarios use >80% threshold for validation (User Story 3), but success criteria SC-003 uses exactly 80%. Should these thresholds be aligned for consistency? → A: Align both to ≥80% for consistency

---

## User Scenarios & Testing

### User Story 1 - Classify Statements with Refined Taxonomy (Priority: P1)

Researchers using the classifier need statements to be categorized more accurately, distinguishing between publications that are nearly reproducible (mostly_open) from those with substantial barriers (mostly_closed), so that meta-analyses can better quantify the spectrum of research openness.

**Why this priority**: Core value proposition - accurate classification is the primary deliverable. Without refined taxonomy, the classifier produces ambiguous results that don't reflect reproducibility nuances.

**Independent Test**: Can be fully tested by classifying a sample of "Partially Closed" publications with different completeness levels and verifying they are correctly assigned to mostly_open vs mostly_closed based on the refined rules.

**Acceptance Scenarios**:

1. **Given** a data statement indicating "Raw; Results; Source Data available with registration", **When** the classifier evaluates it, **Then** it should classify as "mostly_open" because all necessary data types are available despite minor access barrier
2. **Given** a data statement indicating "Results available via data use agreement", **When** the classifier evaluates it, **Then** it should classify as "mostly_closed" because substantial barriers exist
3. **Given** a code statement with "All code on GitHub", **When** the classifier evaluates it, **Then** it should classify as "mostly_open" despite GitHub not being a persistent repository, because all code is available
4. **Given** a code statement with "Processing scripts in supplementary", **When** the classifier evaluates it, **Then** it should classify as "mostly_closed" because only partial code is available

---

### User Story 2 - Enhanced Prompts with Reasoning Guidance (Priority: P2)

The LLM classifier needs clearer instructions on how to distinguish categories based on specific attributes (completeness, repository type, access barriers), so that classifications are consistent and reasoning is transparent.

**Why this priority**: Improves classification quality and consistency. Without clear prompts, the model may apply inconsistent logic to boundary cases.

**Independent Test**: Can be tested by evaluating classification reasoning outputs for statements in the boundary zones, verifying the model explicitly considers completeness and barrier types.

**Acceptance Scenarios**:

1. **Given** a prompt template for data classification, **When** evaluating a statement with mixed completeness, **Then** the prompt should guide the model to explicitly assess what data types are included
2. **Given** a prompt template for code classification, **When** evaluating GitHub vs Zenodo, **Then** the prompt should guide the model to distinguish persistent repositories from non-persistent ones
3. **Given** classification reasoning output, **When** reviewed by user, **Then** reasoning should explicitly mention which completeness attributes influenced the decision

---

### User Story 3 - Validation with Completeness Attributes (Priority: P3)

Researchers need to validate that the refined taxonomy aligns with the original completeness coding (data_included, code_included columns), so they can trust that the automated classifier captures the same nuances as human coders.

**Why this priority**: Ensures refined approach is scientifically sound. Lower priority because it's a validation step that doesn't change core functionality.

**Independent Test**: Can be tested by comparing classifier outputs against ground truth for publications with known completeness attributes and measuring alignment with expected categories.

**Acceptance Scenarios**:

1. **Given** publications coded as "Partially Closed" with data_included in ["All", "Raw; Results; Source Data", "Raw; Results"], **When** classified with refined taxonomy, **Then** ≥80% should be classified as "mostly_open"
2. **Given** publications coded as "Partially Closed" with data_included NOT in the mostly_open list, **When** classified with refined taxonomy, **Then** ≥80% should be classified as "mostly_closed"
3. **Given** publications coded as "Partially Closed" with code_included in the mostly_open code categories, **When** classified with refined taxonomy, **Then** ≥80% should be classified as "mostly_open"

---

### Edge Cases

- What happens when a statement mentions both a persistent repository (mostly_open) and substantial access barriers like data use agreements (mostly_closed)? → Access barrier always takes precedence (hard rule) - classify as mostly_closed regardless of completeness or repository quality
- How does the system handle statements with ambiguous completeness like "some data available"? → Default to "mostly_closed" when completeness is unclear
- What if a statement mentions GitHub (non-persistent) but includes all code types? → Classify as "mostly_open" because completeness outweighs repository type
- How are statements with no repository information handled? → Consider access language ("available upon request" = closed, "publicly available" = open/mostly_open depending on completeness)
- What happens when LLM classification fails after retries? → Mark as "unclassified", log error reason, continue processing batch (see FR-010)

## Requirements

### Functional Requirements

- **FR-001**: System MUST define explicit decision rules for distinguishing "mostly_open" from "mostly_closed" based on data/code completeness attributes
- **FR-002**: System MUST consider the following data completeness indicators for "mostly_open" classification: "All", "Raw; Results; Source Data", "Raw; Results", "Raw" (based on research.md analysis: 40% of Partially Closed publications have "Raw" alone, indicating significant reproducibility potential)
- **FR-003**: System MUST consider the following code completeness indicators for "mostly_open" classification: "All", "Model", "Models", "Download; Process; Analysis; Figures", "Processing; Generate Results", "Processing; Results", "Models; Results", "Models; Analysis", "Analysis; Figures", "Model; Figures", "Results; Figures", "Generate Results; Figures" (based on research.md analysis: standalone "Model"/"Models" represent 35% of Partially Closed code publications, indicating computational methods are available)
- **FR-004**: System MUST classify statements with substantial access barriers (data use agreements, confidentiality restrictions, proprietary terms) as "mostly_closed" regardless of completeness or repository type (hard precedence rule - access barriers always override positive factors)
- **FR-005**: System MUST classify statements with minor barriers (registration, institutional access) combined with high completeness as "mostly_open"
- **FR-006**: System MUST distinguish between persistent repositories (Zenodo, Figshare, Dryad) and non-persistent repositories (GitHub, personal websites) in classification reasoning
- **FR-007**: Classification prompts MUST instruct the model to explicitly assess: (a) what types of data/code are included, (b) what access barriers exist, (c) whether repository is persistent
- **FR-008**: System MUST provide reasoning that explains which completeness attributes and barriers influenced the classification decision
- **FR-009**: System MUST maintain backward compatibility with existing "open" and "closed" classifications (only "mostly_open" and "mostly_closed" distinctions are refined)
- **FR-010**: When LLM classification fails (API error, timeout, malformed response), system MUST retry 3 times with exponential backoff, then mark the publication as "unclassified" with error reason logged, and continue processing remaining publications

### Key Entities

- **Classification Taxonomy**: 4-category ordinal scale (open, mostly_open, mostly_closed, closed) with refined decision rules for middle categories
- **Completeness Attributes**: Specific data types (Raw, Results, Source Data, All) and code types (Download, Process, Analysis, Figures, Models) that indicate reproducibility potential
- **Access Barriers**: Types of restrictions categorized as minor (registration, institutional access) vs substantial (data use agreements, proprietary terms, unavailable)
- **Repository Type**: Categorization of data/code locations as persistent (unique identifier, long-term preservation) vs non-persistent (GitHub, personal URLs)

## Success Criteria

### Measurable Outcomes

- **SC-001**: Classification accuracy for "mostly_open" vs "mostly_closed" improves by at least 15 percentage points compared to baseline classifier without refined taxonomy
- **SC-002**: Cohen's kappa for inter-rater agreement between refined classifier and human coders exceeds 0.70 (substantial agreement) for the full 4-category taxonomy
- **SC-003**: 80% of publications originally coded as "Partially Closed" with high completeness attributes are correctly reclassified as "mostly_open"
- **SC-004**: 90% of classification reasoning outputs explicitly mention completeness attributes when classifying statements in the "mostly_open" or "mostly_closed" categories
- **SC-005**: Classification validation against ground truth shows F1-score > 0.75 for all four categories
- **SC-006**: Single publication classification completes within 5-10 seconds, allowing batch processing of 300 publications in 25-50 minutes

## Assumptions

- Classification training data (articles_reviewed.csv) accurately reflects the intended taxonomy with data_included and code_included attributes providing ground truth for completeness
- The distinction between "mostly_open" and "mostly_closed" based on completeness attributes aligns with reproducibility outcomes (this assumption should be validated through reproduction studies)
- LLM can learn nuanced distinctions when provided with explicit reasoning guidance and few-shot examples that demonstrate completeness-based decision making
- Repository persistence is a meaningful distinguishing factor for openness (though non-persistent repositories like GitHub may still enable reproduction if comprehensive)

## Dependencies

- Existing openness_classifier library with core classification infrastructure
- articles_reviewed.csv with data_included and code_included columns for validation
- LLM provider (Claude Haiku or equivalent) with sufficient context window for enhanced prompts

## Out of Scope

- Re-coding the original articles_reviewed.csv data (using existing completeness attributes as-is)
- Changing the fundamental 4-category taxonomy structure (still using open, mostly_open, mostly_closed, closed)
- Creating new completeness attribute coding systems (using existing data_included/code_included values)
- Validating whether completeness actually predicts reproducibility (assumes this correlation exists)
