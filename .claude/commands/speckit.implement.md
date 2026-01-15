---
description: Execute the implementation plan by processing and executing all tasks defined in tasks.md
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Outline

1. Run `.specify/scripts/bash/check-prerequisites.sh --json --require-tasks --include-tasks` from repo root and parse FEATURE_DIR and AVAILABLE_DOCS list. All paths must be absolute. For single quotes in args like "I'm Groot", use escape syntax: e.g 'I'\''m Groot' (or double-quote if possible: "I'm Groot").

2. **Check checklists status** (if FEATURE_DIR/checklists/ exists):
   - Scan all checklist files in the checklists/ directory
   - For each checklist, count:
     - Total items: All lines matching `- [ ]` or `- [X]` or `- [x]`
     - Completed items: Lines matching `- [X]` or `- [x]`
     - Incomplete items: Lines matching `- [ ]`
   - Create a status table:

     ```text
     | Checklist | Total | Completed | Incomplete | Status |
     |-----------|-------|-----------|------------|--------|
     | ux.md     | 12    | 12        | 0          | ✓ PASS |
     | test.md   | 8     | 5         | 3          | ✗ FAIL |
     | security.md | 6   | 6         | 0          | ✓ PASS |
     ```

   - Calculate overall status:
     - **PASS**: All checklists have 0 incomplete items
     - **FAIL**: One or more checklists have incomplete items

   - **If any checklist is incomplete**:
     - Display the table with incomplete item counts
     - **STOP** and ask: "Some checklists are incomplete. Do you want to proceed with implementation anyway? (yes/no)"
     - Wait for user response before continuing
     - If user says "no" or "wait" or "stop", halt execution
     - If user says "yes" or "proceed" or "continue", proceed to step 3

   - **If all checklists are complete**:
     - Display the table showing all checklists passed
     - Automatically proceed to step 3

3. **Python Environment Validation** (if applicable):

   **Skip Validation Check**:
   - If user passed `--skip-validation` in arguments, display warning and skip to step 4:
     - "⚠️ Skipping environment validation (--skip-validation flag)"
     - "Warning: Reproducibility cannot be guaranteed without environment validation"

   **Python Code Detection** (T017):
   - Check plan.md for Python-related keywords: `python`, `pip`, `conda`, `pixi`, `.py`, `pytest`, `numpy`, `pandas`
   - Check if any `.py` files exist in src/ or project root
   - If NO Python references found:
     - Display: "ℹ️ No Python code detected - skipping environment validation"
     - Proceed to step 4

   **Environment Validation Execution** (T018-T019):
   - If Python detected, run validation with 30-second timeout:

     ```bash
     # Check if env-validate.sh exists
     if [[ -f ".specify/scripts/bash/env-validate.sh" ]]; then
       # Use timeout command if available, otherwise manual timeout
       if command -v timeout &>/dev/null; then
         timeout 30s .specify/scripts/bash/env-validate.sh --json
       elif command -v gtimeout &>/dev/null; then
         gtimeout 30s .specify/scripts/bash/env-validate.sh --json
       else
         # Manual timeout fallback
         .specify/scripts/bash/env-validate.sh --json &
         PID=$!
         ELAPSED=0
         while kill -0 $PID 2>/dev/null && [ $ELAPSED -lt 30 ]; do
           sleep 1
           ELAPSED=$((ELAPSED + 1))
         done
         if kill -0 $PID 2>/dev/null; then
           kill $PID 2>/dev/null
           echo '{"status":"TIMEOUT","issues":["Validation exceeded 30 seconds"]}'
         fi
       fi
     fi
     ```

   **Parse Validation Result** (T020):
   - Parse JSON output to extract: `status`, `issues`, `warnings`, `environment`
   - Capture exit code

   **Handle Validation Status** (T021):
   - **If status is "ACTIVE" (exit 0)**:
     - Display: "✅ Environment ACTIVE"
     - Show environment details (tool, Python version, etc.)
     - Proceed to step 4

   - **If status is "INACTIVE" (exit 2)**:
     - Display: "❌ Environment INACTIVE"
     - List all issues from JSON
     - Show suggested fixes (e.g., `pixi shell`, `conda activate`, `source venv/bin/activate`)
     - **HALT**: "Implementation halted. Activate environment and re-run /speckit.implement"

   - **If status is "MISMATCH" (exit 3)**:
     - Display: "❌ Python Version MISMATCH"
     - Show expected vs actual version
     - Show suggested fix
     - **HALT**: "Implementation halted. Fix Python version and re-run"

   - **If status is "MISSING_DEPS" (exit 4)**:
     - Display: "❌ Missing Dependencies"
     - List missing packages
     - Show install command (e.g., `pixi install`, `pip install -r requirements.txt`)
     - **HALT**: "Implementation halted. Install dependencies and re-run"

   - **If status is "ERROR" (exit 1)**:
     - Display: "❌ Validation Error"
     - Show error details
     - **HALT**: "Implementation halted. Check .env-config and re-run"

   **Handle Timeout** (T022):
   - **If timeout (exit 124 or TIMEOUT status)**:
     - Display: "⚠️ Validation timed out after 30 seconds"
     - Show any partial results if available
     - Prompt: "Options: (1) Retry validation (2) Skip and proceed with warning"
     - If user chooses retry, re-run validation
     - If user chooses skip, display warning about reproducibility and proceed

   **Graceful Degradation** (T023):
   - **If env-validate.sh is missing or crashes**:
     - Display: "⚠️ Environment validation script unavailable"
     - Log incident to `.specify/logs/validation-error-YYYYMMDD-HHMMSS.log`
     - Display prominent warning: "Proceeding with UNVERIFIED environment - reproducibility at risk"
     - Ask: "Continue with implementation? (yes/no)"
     - If yes, proceed with warning logged
     - If no, halt execution

4. Load and analyze the implementation context:
   - **REQUIRED**: Read tasks.md for the complete task list and execution plan
   - **REQUIRED**: Read plan.md for tech stack, architecture, and file structure
   - **IF EXISTS**: Read data-model.md for entities and relationships
   - **IF EXISTS**: Read contracts/ for API specifications and test requirements
   - **IF EXISTS**: Read research.md for technical decisions and constraints
   - **IF EXISTS**: Read quickstart.md for integration scenarios

5. **Project Setup Verification**:
   - **REQUIRED**: Create/verify ignore files based on actual project setup:

   **Detection & Creation Logic**:
   - Check if the following command succeeds to determine if the repository is a git repo (create/verify .gitignore if so):

     ```sh
     git rev-parse --git-dir 2>/dev/null
     ```

   - Check if Dockerfile* exists or Docker in plan.md → create/verify .dockerignore
   - Check if .eslintrc* exists → create/verify .eslintignore
   - Check if eslint.config.* exists → ensure the config's `ignores` entries cover required patterns
   - Check if .prettierrc* exists → create/verify .prettierignore
   - Check if .npmrc or package.json exists → create/verify .npmignore (if publishing)
   - Check if terraform files (*.tf) exist → create/verify .terraformignore
   - Check if .helmignore needed (helm charts present) → create/verify .helmignore

   **If ignore file already exists**: Verify it contains essential patterns, append missing critical patterns only
   **If ignore file missing**: Create with full pattern set for detected technology

   **Common Patterns by Technology** (from plan.md tech stack):
   - **Node.js/JavaScript/TypeScript**: `node_modules/`, `dist/`, `build/`, `*.log`, `.env*`
   - **Python**: `__pycache__/`, `*.pyc`, `.venv/`, `venv/`, `dist/`, `*.egg-info/`
   - **Java**: `target/`, `*.class`, `*.jar`, `.gradle/`, `build/`
   - **C#/.NET**: `bin/`, `obj/`, `*.user`, `*.suo`, `packages/`
   - **Go**: `*.exe`, `*.test`, `vendor/`, `*.out`
   - **Ruby**: `.bundle/`, `log/`, `tmp/`, `*.gem`, `vendor/bundle/`
   - **PHP**: `vendor/`, `*.log`, `*.cache`, `*.env`
   - **Rust**: `target/`, `debug/`, `release/`, `*.rs.bk`, `*.rlib`, `*.prof*`, `.idea/`, `*.log`, `.env*`
   - **Kotlin**: `build/`, `out/`, `.gradle/`, `.idea/`, `*.class`, `*.jar`, `*.iml`, `*.log`, `.env*`
   - **C++**: `build/`, `bin/`, `obj/`, `out/`, `*.o`, `*.so`, `*.a`, `*.exe`, `*.dll`, `.idea/`, `*.log`, `.env*`
   - **C**: `build/`, `bin/`, `obj/`, `out/`, `*.o`, `*.a`, `*.so`, `*.exe`, `Makefile`, `config.log`, `.idea/`, `*.log`, `.env*`
   - **Swift**: `.build/`, `DerivedData/`, `*.swiftpm/`, `Packages/`
   - **R**: `.Rproj.user/`, `.Rhistory`, `.RData`, `.Ruserdata`, `*.Rproj`, `packrat/`, `renv/`
   - **Universal**: `.DS_Store`, `Thumbs.db`, `*.tmp`, `*.swp`, `.vscode/`, `.idea/`

   **Tool-Specific Patterns**:
   - **Docker**: `node_modules/`, `.git/`, `Dockerfile*`, `.dockerignore`, `*.log*`, `.env*`, `coverage/`
   - **ESLint**: `node_modules/`, `dist/`, `build/`, `coverage/`, `*.min.js`
   - **Prettier**: `node_modules/`, `dist/`, `build/`, `coverage/`, `package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`
   - **Terraform**: `.terraform/`, `*.tfstate*`, `*.tfvars`, `.terraform.lock.hcl`
   - **Kubernetes/k8s**: `*.secret.yaml`, `secrets/`, `.kube/`, `kubeconfig*`, `*.key`, `*.crt`

6. Parse tasks.md structure and extract:
   - **Task phases**: Setup, Tests, Core, Integration, Polish
   - **Task dependencies**: Sequential vs parallel execution rules
   - **Task details**: ID, description, file paths, parallel markers [P]
   - **Execution flow**: Order and dependency requirements

7. Execute implementation following the task plan:
   - **Phase-by-phase execution**: Complete each phase before moving to the next
   - **Respect dependencies**: Run sequential tasks in order, parallel tasks [P] can run together  
   - **Follow TDD approach**: Execute test tasks before their corresponding implementation tasks
   - **File-based coordination**: Tasks affecting the same files must run sequentially
   - **Validation checkpoints**: Verify each phase completion before proceeding

8. Implementation execution rules:
   - **Setup first**: Initialize project structure, dependencies, configuration
   - **Tests before code**: If you need to write tests for contracts, entities, and integration scenarios
   - **Core development**: Implement models, services, CLI commands, endpoints
   - **Integration work**: Database connections, middleware, logging, external services
   - **Polish and validation**: Unit tests, performance optimization, documentation

9. Progress tracking and error handling:
   - Report progress after each completed task
   - Halt execution if any non-parallel task fails
   - For parallel tasks [P], continue with successful tasks, report failed ones
   - Provide clear error messages with context for debugging
   - Suggest next steps if implementation cannot proceed
   - **IMPORTANT** For completed tasks, make sure to mark the task off as [X] in the tasks file.

10. Completion validation:
   - Verify all required tasks are completed
   - Check that implemented features match the original specification
   - Validate that tests pass and coverage meets requirements
   - Confirm the implementation follows the technical plan
   - Report final status with summary of completed work

Note: This command assumes a complete task breakdown exists in tasks.md. If tasks are incomplete or missing, suggest running `/speckit.tasks` first to regenerate the task list.
