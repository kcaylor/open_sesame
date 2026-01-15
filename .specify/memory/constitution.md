# Research Specification (res_spec) Constitution

<!--
═══════════════════════════════════════════════════════════════════════════════
SYNC IMPACT REPORT
═══════════════════════════════════════════════════════════════════════════════
Version Change: Initial Constitution (v1.0.0)
Ratification Date: 2025-12-09
Last Amended: 2025-12-09

SUMMARY:
Initial constitution created for the res_spec project - a template repository for
PhD research workflows using speckit. This constitution establishes principles
for research-oriented software development that balances scientific rigor with
practical implementation.

PRINCIPLES ESTABLISHED:
1. Research-First Development
2. Reproducibility & Transparency
3. Documentation as Science Communication
4. Incremental Implementation with Validation
5. Library & Method Integration

SECTIONS ADDED:
- Core Principles (5 principles)
- Research Software Requirements
- Development & Collaboration Workflow
- Governance

TEMPLATES REQUIRING UPDATES:
✅ plan-template.md - Updated (Constitution Check aligns with principles)
✅ spec-template.md - Updated (User story structure supports incremental validation)
✅ tasks-template.md - Updated (Phase structure supports research milestones)
✅ All command files - Updated (Generic agent references maintained)

FOLLOW-UP ACTIONS:
None - all placeholders filled, all dependent artifacts checked.
═══════════════════════════════════════════════════════════════════════════════
-->

## Core Principles

### I. Research-First Development

Every feature and implementation decision MUST serve scientific research goals:

- **Scientific Purpose**: Each feature must have a clear connection to research objectives (data analysis, methodology, publication, collaboration)
- **Method Validity**: Implementations that embody statistical or computational methods MUST be validated against published references or established libraries
- **Research Context**: Code should integrate seamlessly with common research workflows (Jupyter notebooks, data pipelines, manuscript generation)
- **Domain Specificity**: Tools and utilities should be tailored to the specific research domain and methods used by the lab group

**Rationale**: Research software exists to advance scientific discovery. Keeping research objectives central ensures development effort directly contributes to scholarly outcomes rather than building generic software.

### II. Reproducibility & Transparency

All research code MUST be reproducible and scientifically transparent:

- **Environment Specification**: All dependencies, versions, and environment requirements MUST be explicitly documented (requirements.txt, environment.yml, or equivalent)
- **Data Provenance**: Data sources, processing steps, and transformations MUST be documented and traceable
- **Computational Methods**: All algorithms, parameters, and computational decisions MUST be documented with references to literature where applicable
- **Version Control**: All code changes MUST be committed with meaningful messages explaining scientific rationale
- **Open Science**: Code should be structured to support open science practices (shareable, citable, archivable)

**Rationale**: Reproducibility is fundamental to the scientific method. Without transparent, reproducible code, research findings cannot be validated or built upon by the scientific community.

### III. Documentation as Science Communication

Documentation MUST serve as scientific communication, not just code explanation:

- **Method Documentation**: Document WHY (scientific rationale) before HOW (implementation details)
- **Literature References**: Include citations to relevant papers, methods, and established practices
- **Assumptions & Limitations**: Explicitly document scientific assumptions, simplifications, and known limitations
- **Usage Examples**: Provide examples that reflect real research use cases with actual or realistic data
- **Narrative Structure**: Documentation should read like scientific writing—clear, precise, and contextual

**Rationale**: Research code documentation bridges the gap between computational implementation and scientific understanding. It enables knowledge transfer within lab groups and supports manuscript preparation.

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

**Rationale**: Scientific software development should build on the shoulders of giants. Leveraging established libraries improves reliability, enables comparison with literature, and focuses effort on novel research contributions.

## Research Software Requirements

### Project Structure

Research projects using this template MUST organize code as follows:

- **Source Code** (`src/`): Reusable modules, functions, and classes
- **Notebooks** (`notebooks/`): Analysis notebooks organized by research question or manuscript figure
- **Data** (`data/`): Raw data (if shareable), processed data, and data documentation
- **Tests** (`tests/`): Validation tests, regression tests, and method verification tests
- **Documentation** (`docs/`): Extended documentation, tutorials, and method explanations
- **Specifications** (`specs/`): Feature specifications using speckit workflow

### Testing Strategy

Testing in research contexts focuses on scientific validity:

- **Method Validation**: Tests that verify implementation matches published methods or established results
- **Regression Tests**: Tests that ensure results remain consistent across code changes
- **Edge Case Testing**: Tests for boundary conditions relevant to the research domain
- **Data Integrity**: Tests that verify data loading, transformation, and integrity
- **Optional Unit Tests**: Traditional unit tests are optional unless required for specific components

**NOTE**: Unlike production software, not every function needs unit tests. Focus testing effort on scientific correctness and reproducibility.

### Python Best Practices for Research

- **Python Version**: Use Python 3.9+ (or the version required by key dependencies)
- **Dependency Management**: Use `requirements.txt` or `environment.yml` with pinned versions for reproducibility
- **Code Style**: Follow PEP 8 for readability, but prioritize clarity over strict compliance
- **Notebook Hygiene**: Keep notebooks focused, restart kernel and run all cells before committing
- **Modular Code**: Extract reusable logic from notebooks into `src/` modules
- **Configuration**: Use configuration files (YAML, JSON, TOML) for parameters that vary across analyses

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

### Collaboration in Lab Groups

- **Shared Understanding**: Lab members MUST be able to understand and run each other's code
- **Code Review**: Focus code review on scientific correctness, reproducibility, and documentation clarity
- **Reusability**: Design code with lab-wide reuse in mind (common data formats, shared utilities)
- **Knowledge Transfer**: Document tribal knowledge (common gotchas, domain-specific practices, data quirks)
- **Agent Customization**: Lab groups should customize agents to reflect their specific libraries, methods, and research domain

### Agent Customization for Research

This template supports agent customization to incorporate:

- **Domain-Specific Libraries**: Add tools and documentation for libraries used in your research area
- **Published Methods**: Include references and examples for methods commonly used by the lab
- **Data Standards**: Document expected data formats, naming conventions, and quality criteria
- **Lab Practices**: Encode lab-specific workflows, review processes, and best practices
- **Manuscript Integration**: Configure agents to support manuscript preparation workflows

## Governance

### Constitution Authority

This constitution governs all feature development and code contributions within projects derived from this template. Lab groups SHOULD adapt this constitution to their specific research needs and practices.

### Amendment Process

1. **Proposal**: Any lab member can propose amendments with scientific rationale
2. **Discussion**: Lab group discusses implications for research workflow and reproducibility
3. **Approval**: Amendments require consensus or PI approval
4. **Documentation**: Document the change rationale and update dependent templates
5. **Version Update**: Increment constitution version according to semantic versioning

### Versioning Policy

- **MAJOR**: Fundamental changes to research principles or practices (e.g., change testing philosophy)
- **MINOR**: New principles added or significant expansions (e.g., add data management section)
- **PATCH**: Clarifications, refinements, or minor updates (e.g., update library versions)

### Compliance & Review

- **Specification Review**: Feature specifications MUST align with research principles
- **Implementation Review**: Focus on scientific correctness, reproducibility, and documentation
- **Complexity Justification**: Deviations from simplicity MUST be scientifically justified
- **Periodic Audit**: Lab groups should periodically review constitution alignment with research practices

**Version**: 1.0.0 | **Ratified**: 2025-12-09 | **Last Amended**: 2025-12-09
