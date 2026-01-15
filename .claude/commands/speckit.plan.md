---
description: Execute the implementation planning workflow using the plan template to generate design artifacts.
handoffs: 
  - label: Create Tasks
    agent: speckit.tasks
    prompt: Break the plan into tasks
    send: true
  - label: Create Checklist
    agent: speckit.checklist
    prompt: Create a checklist for the following domain...
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Outline

1. **Setup**: Run `.specify/scripts/bash/setup-plan.sh --json` from repo root and parse JSON for FEATURE_SPEC, IMPL_PLAN, SPECS_DIR, BRANCH. For single quotes in args like "I'm Groot", use escape syntax: e.g 'I'\''m Groot' (or double-quote if possible: "I'm Groot").

2. **Load context**: Read FEATURE_SPEC and `.specify/memory/constitution.md`. Load IMPL_PLAN template (already copied).

3. **Execute plan workflow**: Follow the structure in IMPL_PLAN template to:
   - Fill Technical Context (mark unknowns as "NEEDS CLARIFICATION")
   - Fill Constitution Check section from constitution
   - Evaluate gates (ERROR if violations unjustified)
   - Phase 0: Generate research.md (resolve all NEEDS CLARIFICATION)
   - Phase 1: Generate data-model.md, contracts/, quickstart.md
   - Phase 1: Update agent context by running the agent script
   - Re-evaluate Constitution Check post-design

4. **Constitution Compliance Validation** (after plan.md generation):

   **Run Constitution Check** (T027-T028):
   - After plan.md is written, run constitution compliance check:
     ```bash
     .specify/scripts/bash/check-constitution.sh "$IMPL_PLAN" --json
     ```
   - Parse JSON output to extract `status` and `principle_checks`

   **Handle Check Results** (T029-T030):
   - **If status is "PASS"**:
     - Display: "✅ Constitution Check: PASS - All principles aligned"
     - Proceed silently to step 5

   - **If status is "WARN" or "FAIL"**:
     - Run check again without --json for human-readable output:
       ```bash
       .specify/scripts/bash/check-constitution.sh "$IMPL_PLAN"
       ```
     - Display all flagged sections with specific recommendations
     - Add emphasis on importance of reproducibility and method documentation (T033):
       - "📋 Research reproducibility requires clear validation strategies"
       - "📖 Method documentation enables peer review and replication"
     - Prompt researcher with options (T030):
       ```text
       Constitution check found issues. How would you like to proceed?

       Options:
         1. fix - Update plan.md to address concerns (recommended)
         2. proceed without fix - Continue with bypass logged

       Your choice: _
       ```

   **Handle Researcher Response** (T031-T032):
   - **If "fix" or "yes" or "1"**:
     - Display: "Please update plan.md to address the flagged concerns:"
     - List each flagged issue with its recommendation
     - Display: "When ready, re-run /speckit.plan to re-validate"
     - **HALT** - Do not proceed to step 5

   - **If "proceed without fix" or "bypass" or "skip" or "2"**:
     - Display: "⚠️ Bypassing constitution check"
     - Log bypass to `.specify/logs/constitution-bypass-YYYYMMDD.log`:
       ```bash
       echo "$(date -Iseconds): Bypassed constitution check for $IMPL_PLAN" >> .specify/logs/constitution-bypass-YYYYMMDD.log
       ```
     - Display: "Note: Plan may lack scientific rigor. Review before publication."
     - Proceed to step 5

5. **Stop and report**: Command ends after Phase 2 planning. Report branch, IMPL_PLAN path, and generated artifacts.

## Phases

### Phase 0: Outline & Research

1. **Extract unknowns from Technical Context** above:
   - For each NEEDS CLARIFICATION → research task
   - For each dependency → best practices task
   - For each integration → patterns task

2. **Generate and dispatch research agents**:

   ```text
   For each unknown in Technical Context:
     Task: "Research {unknown} for {feature context}"
   For each technology choice:
     Task: "Find best practices for {tech} in {domain}"
   ```

3. **Consolidate findings** in `research.md` using format:
   - Decision: [what was chosen]
   - Rationale: [why chosen]
   - Alternatives considered: [what else evaluated]

**Output**: research.md with all NEEDS CLARIFICATION resolved

### Phase 1: Design & Contracts

**Prerequisites:** `research.md` complete

1. **Extract entities from feature spec** → `data-model.md`:
   - Entity name, fields, relationships
   - Validation rules from requirements
   - State transitions if applicable

2. **Generate API contracts** from functional requirements:
   - For each user action → endpoint
   - Use standard REST/GraphQL patterns
   - Output OpenAPI/GraphQL schema to `/contracts/`

3. **Agent context update**:
   - Run `.specify/scripts/bash/update-agent-context.sh claude`
   - These scripts detect which AI agent is in use
   - Update the appropriate agent-specific context file
   - Add only new technology from current plan
   - Preserve manual additions between markers

**Output**: data-model.md, /contracts/*, quickstart.md, agent-specific file

## Key rules

- Use absolute paths
- ERROR on gate failures or unresolved clarifications
