# Research Specification (res_spec) Constitution: ef_2026

<!--
═══════════════════════════════════════════════════════════════════════════════
SYNC IMPACT REPORT
═══════════════════════════════════════════════════════════════════════════════
Version Change: 1.0.0 → 1.1.0
Ratification Date: 2025-12-09
Last Amended: 2026-01-15

SUMMARY:
Updated constitution for the ef_2026 project, which focuses on publication
meta-analysis, FAIR research principles, and open science practices. This
amendment adds domain-specific guidance while preserving all 5 core research
principles established in v1.0.0.

PRINCIPLES MODIFIED:
1. Research-First Development → Enhanced with publication meta-analysis context
2. Reproducibility & Transparency → Extended with FAIR principles (Findable,
   Accessible, Interoperable, Reusable)
3. Documentation as Science Communication → Enhanced with meta-analysis and
   systematic review requirements
4. Incremental Implementation with Validation → No changes
5. Library & Method Integration → Enhanced with bibliometric and meta-analysis
   library guidance

SECTIONS ADDED:
- ef_2026 Project Context (new section describing specific research domain)
- FAIR Research Requirements (new subsection under Reproducibility & Transparency)
- Meta-Analysis & Bibliometric Practices (new subsection under Research Software Requirements)

SECTIONS MODIFIED:
- Research Software Requirements → Added meta-analysis tools and data management
- Python Best Practices for Research → Added bibliometric library guidance
- Development & Collaboration Workflow → Added publication review workflow

TEMPLATES REQUIRING UPDATES:
✅ plan-template.md - Constitution Check section aligns with enhanced principles
✅ spec-template.md - Research Context section supports meta-analysis workflows
✅ tasks-template.md - Phase structure accommodates systematic review steps
✅ All command files - Generic agent references maintained

FOLLOW-UP ACTIONS:
None - all placeholders filled, all dependent artifacts checked, version
incremented to MINOR (1.1.0) per semantic versioning (new sections added).
═══════════════════════════════════════════════════════════════════════════════
-->

## ef_2026 Project Context

**Research Domain**: Publication Meta-Analysis, FAIR Research, Open Science

**Primary Focus**: The ef_2026 project conducts systematic reviews and meta-analyses of published research, with an emphasis on FAIR (Findable, Accessible, Interoperable, Reusable) data principles and open science practices. This work involves bibliometric analysis, data extraction from publications, statistical synthesis, and reproducible research workflows.

**Key Activities**:
- Systematic literature searches and screening
- Bibliometric and scientometric analysis
- Meta-analysis and statistical synthesis
- FAIR data management and publishing
- Open science workflow development

**Methodological Requirements**: All analyses must support publication in peer-reviewed journals with full reproducibility, meeting FAIR principles for both code and data.

---

## Core Principles

### I. Research-First Development

Every feature and implementation decision MUST serve scientific research goals:

- **Scientific Purpose**: Each feature must have a clear connection to research objectives (data analysis, methodology, publication, collaboration)
- **Method Validity**: Implementations that embody statistical or computational methods MUST be validated against published references or established libraries
- **Research Context**: Code should integrate seamlessly with common research workflows (Jupyter notebooks, data pipelines, manuscript generation)
- **Domain Specificity**: Tools and utilities should be tailored to the specific research domain and methods used by the lab group

**ef_2026 Application**:
- Features must support systematic review and meta-analysis workflows (literature search, screening, data extraction, synthesis)
- Tools must facilitate bibliometric analysis and scientometric methods
- Implementations must support publication-quality outputs (figures, tables, supplementary materials)
- All methods must be citeable and aligned with reporting guidelines (e.g., PRISMA for systematic reviews)

**Rationale**: Research software exists to advance scientific discovery. Keeping research objectives central ensures development effort directly contributes to scholarly outcomes rather than building generic software.

### II. Reproducibility & Transparency

All research code MUST be reproducible and scientifically transparent:

- **Environment Specification**: All dependencies, versions, and environment requirements MUST be explicitly documented (requirements.txt, environment.yml, or equivalent)
- **Data Provenance**: Data sources, processing steps, and transformations MUST be documented and traceable
- **Computational Methods**: All algorithms, parameters, and computational decisions MUST be documented with references to literature where applicable
- **Version Control**: All code changes MUST be committed with meaningful messages explaining scientific rationale
- **Open Science**: Code should be structured to support open science practices (shareable, citable, archivable)

**ef_2026 Application - FAIR Principles**:
- **Findable**: All datasets, code, and analyses must have persistent identifiers (DOIs) and be discoverable via metadata
- **Accessible**: Data and code must be openly accessible (or have clear access protocols if restricted)
- **Interoperable**: Use standard formats (CSV, JSON, RDF) and vocabularies; ensure cross-platform compatibility
- **Reusable**: Provide clear licenses (e.g., CC-BY, MIT), comprehensive documentation, and usage examples

**FAIR Data Management Requirements**:
- Document data sources with full citations and access dates
- Use structured metadata (e.g., DataCite schema) for all datasets
- Maintain data dictionaries for all variables
- Preserve raw data separately from processed data
- Archive all data with version control and checksums

**Rationale**: Reproducibility is fundamental to the scientific method. Without transparent, reproducible code, research findings cannot be validated or built upon by the scientific community. FAIR principles ensure research outputs have maximum impact and reusability.

### III. Documentation as Science Communication

Documentation MUST serve as scientific communication, not just code explanation:

- **Method Documentation**: Document WHY (scientific rationale) before HOW (implementation details)
- **Literature References**: Include citations to relevant papers, methods, and established practices
- **Assumptions & Limitations**: Explicitly document scientific assumptions, simplifications, and known limitations
- **Usage Examples**: Provide examples that reflect real research use cases with actual or realistic data
- **Narrative Structure**: Documentation should read like scientific writing—clear, precise, and contextual

**ef_2026 Application - Meta-Analysis Context**:
- **Search Strategies**: Document complete search strings, databases searched, and inclusion/exclusion criteria
- **Data Extraction Protocols**: Provide detailed protocols for extracting data from publications (variables, units, transformations)
- **Effect Size Calculations**: Document all effect size formulas, variance calculations, and statistical models used
- **Risk of Bias Assessment**: Document criteria and procedures for assessing study quality
- **Reporting Alignment**: Ensure documentation supports compliance with reporting guidelines (PRISMA, MOOSE, ROSES)

**Publication Methods Section Integration**:
- All analysis code should include comments that can be directly adapted for methods sections
- Document software versions, packages, and statistical procedures in a format ready for manuscript integration
- Maintain a bibliography of methodological references used

**Rationale**: Research code documentation bridges the gap between computational implementation and scientific understanding. It enables knowledge transfer within lab groups and supports manuscript preparation. For meta-analysis, documentation is essential for transparency and replication.

### IV. Incremental Implementation with Validation

Development MUST proceed through validated increments:

- **MVP Definition**: Define a minimal viable product that answers a specific research question or performs a discrete analytical task
- **Validation Checkpoints**: Each implementation phase MUST include validation against known results, published benchmarks, or synthetic test cases
- **User Story = Research Task**: User stories should map to actual research tasks (analyze dataset, generate figure, test hypothesis)
- **Iterative Refinement**: Start with simple, working implementations; add sophistication only when scientifically justified
- **Test with Real Data**: Validate implementations with actual research data (or representative synthetic data) as early as possible

**Rationale**: Research software development benefits from rapid feedback cycles. By validating small increments against scientific ground truth, we catch methodological errors early and build confidence in results.

### V. Library & Method Integration

Leverage and document established libraries and published methods:

- **Use Standard Libraries**: Prefer well-established scientific libraries (NumPy, Pandas, SciPy, scikit-learn, etc.) over custom implementations
- **Method References**: When implementing published methods, MUST include citation and note any adaptations
- **Custom Code Justification**: Custom implementations of standard methods MUST be justified (performance, specific requirements, novel adaptation)
- **Manuscript Integration**: Tools and utilities should be designed to support manuscript methods sections with code citations
- **Extensibility**: Design code to accommodate new methods and libraries as research evolves

**ef_2026 Application - Bibliometric & Meta-Analysis Libraries**:
- **Bibliometric Analysis**: Use established libraries such as `bibliometrix` (R), `pybliometrics`, `metaknowledge`, or `scientopy`
- **Meta-Analysis**: Use `metafor` (R), `meta` (R), or Python implementations (`statsmodels`, custom meta-analysis packages)
- **Literature Management**: Integrate with reference managers (Zotero, EndNote) and use BibTeX for citations
- **Text Mining**: Use `nltk`, `spaCy`, or `gensim` for text analysis and topic modeling
- **Statistical Synthesis**: Document all statistical models, heterogeneity measures (I², τ²), and sensitivity analyses

**Rationale**: Scientific software development should build on the shoulders of giants. Leveraging established libraries improves reliability, enables comparison with literature, and focuses effort on novel research contributions.

---

## Research Software Requirements

### Project Structure

Research projects using this template MUST organize code as follows:

- **Source Code** (`src/`): Reusable modules, functions, and classes
- **Notebooks** (`notebooks/`): Analysis notebooks organized by research question or manuscript figure
- **Data** (`data/`): Raw data (if shareable), processed data, and data documentation
  - `data/raw/`: Original, unmodified data with provenance documentation
  - `data/processed/`: Cleaned and transformed data with processing scripts
  - `data/metadata/`: Data dictionaries, codebooks, and metadata files
- **Tests** (`tests/`): Validation tests, regression tests, and method verification tests
- **Documentation** (`docs/`): Extended documentation, tutorials, and method explanations
- **Specifications** (`specs/`): Feature specifications using speckit workflow

**ef_2026 Project Extensions**:
- **Literature** (`literature/`): Systematic review materials
  - `literature/searches/`: Search strings and results from databases
  - `literature/screening/`: Screening decisions and PRISMA flow diagrams
  - `literature/included/`: PDFs and metadata for included studies
- **Extraction** (`extraction/`): Data extraction forms and extracted data
- **Analysis** (`analysis/`): Meta-analysis scripts, models, and results
- **Figures** (`figures/`): Publication-quality figures and supplementary materials

### Testing Strategy

Testing in research contexts focuses on scientific validity:

- **Method Validation**: Tests that verify implementation matches published methods or established results
- **Regression Tests**: Tests that ensure results remain consistent across code changes
- **Edge Case Testing**: Tests for boundary conditions relevant to the research domain
- **Data Integrity**: Tests that verify data loading, transformation, and integrity
- **Optional Unit Tests**: Traditional unit tests are optional unless required for specific components

**ef_2026 Testing Extensions**:
- **Effect Size Validation**: Verify effect size calculations against published examples or reference implementations
- **Meta-Analysis Replication**: Replicate published meta-analyses to validate statistical methods
- **Data Extraction Reliability**: Test inter-rater reliability for data extraction (if multiple extractors)
- **Sensitivity Analysis**: Implement and test sensitivity analyses for robustness

**NOTE**: Unlike production software, not every function needs unit tests. Focus testing effort on scientific correctness and reproducibility.

### Python Best Practices for Research

- **Python Version**: Use Python 3.9+ (or the version required by key dependencies)
- **Dependency Management**: Use `requirements.txt` or `environment.yml` with pinned versions for reproducibility
- **Code Style**: Follow PEP 8 for readability, but prioritize clarity over strict compliance
- **Notebook Hygiene**: Keep notebooks focused, restart kernel and run all cells before committing
- **Modular Code**: Extract reusable logic from notebooks into `src/` modules
- **Configuration**: Use configuration files (YAML, JSON, TOML) for parameters that vary across analyses

**ef_2026 Library Recommendations**:
- **Bibliometrics**: `pybliometrics`, `scholarly`, `habanero` (CrossRef API), `biopython` (PubMed)
- **Data Extraction**: `pandas`, `openpyxl`, `pdfplumber`, `beautifulsoup4`
- **Statistical Analysis**: `scipy`, `statsmodels`, `pingouin`, `scikit-learn`
- **Meta-Analysis**: `pymare` (Python meta-analysis), or use R via `rpy2` for `metafor`
- **Visualization**: `matplotlib`, `seaborn`, `plotly`, `forestplot`
- **FAIR Data**: `frictionless` (data packages), `datacite` (DOI minting)

### Meta-Analysis & Bibliometric Practices

**Systematic Review Workflow**:
1. **Protocol Development**: Document search strategy, inclusion/exclusion criteria, and data extraction plan before starting
2. **Literature Search**: Use multiple databases (Web of Science, Scopus, PubMed, etc.) and document search dates
3. **Screening**: Implement two-stage screening (title/abstract, then full-text) with clear criteria
4. **Data Extraction**: Use structured forms and document extraction decisions
5. **Quality Assessment**: Apply appropriate risk-of-bias tools (e.g., Cochrane Risk of Bias, GRADE)
6. **Statistical Synthesis**: Document all meta-analytic models, heterogeneity assessment, and publication bias tests
7. **Reporting**: Follow PRISMA guidelines and provide complete reproducibility materials

**Bibliometric Analysis Standards**:
- Document all bibliometric indicators calculated (h-index, citation counts, co-citation networks, etc.)
- Use established normalization methods for cross-field comparisons
- Validate results against known benchmarks or published studies
- Provide clear visualizations (network diagrams, heatmaps, temporal trends)

**FAIR Meta-Analysis Data**:
- Publish extracted data as structured datasets with DOIs
- Provide complete metadata (search strategies, inclusion criteria, data dictionaries)
- Archive analysis code with specific package versions
- Share supplementary materials (PRISMA diagrams, forest plots, sensitivity analyses)

---

## Development & Collaboration Workflow

### Feature Development Process

1. **Research Context**: Start by documenting the research question or analytical need
2. **Specification**: Use `/speckit.specify` to create a feature specification
3. **Planning**: Use `/speckit.plan` to design the implementation approach
4. **Validation Design**: Define how you will validate the implementation (test data, known results, benchmarks)
5. **Incremental Implementation**: Build in small, testable increments
6. **Scientific Review**: Have a lab member review the scientific approach, not just the code
7. **Documentation**: Document methods, assumptions, and usage examples
8. **Integration**: Integrate into broader research workflow (notebooks, pipelines, manuscripts)

**ef_2026 Workflow Extensions**:
1. **Literature Review**: Document the methodological basis (cite papers using similar methods)
2. **Protocol Registration**: Consider pre-registering systematic reviews (e.g., PROSPERO, OSF)
3. **Data Management Plan**: Define FAIR data management practices for this feature
4. **Reproducibility Check**: Test reproducibility by having another researcher run the code independently
5. **Publication Integration**: Ensure outputs are publication-ready (tables, figures, supplementary materials)

### Collaboration in Lab Groups

- **Shared Understanding**: Lab members MUST be able to understand and run each other's code
- **Code Review**: Focus code review on scientific correctness, reproducibility, and documentation clarity
- **Reusability**: Design code with lab-wide reuse in mind (common data formats, shared utilities)
- **Knowledge Transfer**: Document tribal knowledge (common gotchas, domain-specific practices, data quirks)
- **Agent Customization**: Lab groups should customize agents to reflect their specific libraries, methods, and research domain

**ef_2026 Collaboration Practices**:
- **Systematic Review Teams**: Coordinate screening, data extraction, and quality assessment across multiple researchers
- **Inter-Rater Reliability**: Document agreement metrics (Cohen's kappa, ICC) for subjective decisions
- **Data Harmonization**: Establish protocols for combining data from different sources or extractors
- **Methodological Consistency**: Ensure all team members use consistent methods and software versions

### Agent Customization for Research

This template supports agent customization to incorporate:

- **Domain-Specific Libraries**: Add tools and documentation for libraries used in your research area
- **Published Methods**: Include references and examples for methods commonly used by the lab
- **Data Standards**: Document expected data formats, naming conventions, and quality criteria
- **Lab Practices**: Encode lab-specific workflows, review processes, and best practices
- **Manuscript Integration**: Configure agents to support manuscript preparation workflows

**ef_2026 Agent Customization**:
- Include meta-analysis reporting guidelines (PRISMA, MOOSE, ROSES) in specifications
- Add bibliometric database APIs and search strategy templates
- Configure FAIR data management workflows and metadata standards
- Include effect size calculators and meta-analysis model templates

---

## Governance

### Constitution Authority

This constitution governs all feature development and code contributions within the ef_2026 project. This is a customized version of the res_spec template constitution, adapted for publication meta-analysis, FAIR research, and open science workflows.

### Amendment Process

1. **Proposal**: Any lab member can propose amendments with scientific rationale
2. **Discussion**: Lab group discusses implications for research workflow and reproducibility
3. **Approval**: Amendments require consensus or PI approval
4. **Documentation**: Document the change rationale and update dependent templates
5. **Version Update**: Increment constitution version according to semantic versioning

### Versioning Policy

- **MAJOR**: Fundamental changes to research principles or practices (e.g., change testing philosophy, remove core principle)
- **MINOR**: New principles added or significant expansions (e.g., add data management section, add domain-specific requirements)
- **PATCH**: Clarifications, refinements, or minor updates (e.g., update library versions, fix typos, clarify wording)

**Current Version History**:
- **v1.0.0** (2025-12-09): Initial constitution with 5 core research principles
- **v1.1.0** (2026-01-15): Added ef_2026 project context, FAIR principles, meta-analysis guidance, and bibliometric practices

### Compliance & Review

- **Specification Review**: Feature specifications MUST align with research principles and FAIR requirements
- **Implementation Review**: Focus on scientific correctness, reproducibility, and documentation quality
- **Complexity Justification**: Deviations from simplicity MUST be scientifically justified
- **Periodic Audit**: Lab groups should periodically review constitution alignment with research practices
- **FAIR Compliance**: All outputs must be assessed against FAIR principles before publication

**ef_2026 Review Requirements**:
- Systematic reviews must follow PRISMA or equivalent reporting guidelines
- Meta-analyses must document all statistical decisions and sensitivity analyses
- All datasets must meet FAIR criteria (assessed via FAIR metrics)
- Code must be archived with persistent identifiers (e.g., Zenodo) before publication

---

**Version**: 1.1.0 | **Ratified**: 2025-12-09 | **Last Amended**: 2026-01-15
