# Extending Speckit Commands

This guide explains how to add new speckit commands to res_spec. Speckit commands are Claude Code slash commands that guide researchers through specification-driven workflows.

## Command Architecture

### How Commands Work

Speckit commands are markdown files in `.claude/commands/` that Claude Code executes as slash commands. When a user types `/speckit.specify`, Claude Code:

1. Loads `.claude/commands/speckit.specify.md`
2. Interprets the markdown as instructions
3. Executes the workflow defined within
4. Produces output artifacts (typically in `specs/`)

### Command Components

A typical speckit command involves:

```
.claude/commands/speckit.commandname.md  ← Command definition
           │
           ├──→ .specify/templates/*.md   ← Document templates
           │
           ├──→ .specify/memory/          ← Constitution checks
           │
           └──→ .specify/scripts/bash/    ← Helper scripts (optional)
```

## Creating a New Command

### Step 1: Define the Command

Create `.claude/commands/speckit.yourcommand.md`:

```markdown
# /speckit.yourcommand

[Brief description of what this command does]

## Prerequisites

- [What must exist before running this command]
- [Required files or prior commands]

## Process

1. [First step the agent should take]
2. [Second step]
3. [Third step]

## Input

- [What the user provides]
- [Expected format]

## Output

- [What files are generated]
- [Where they are placed]

## Template

Use the template at `.specify/templates/yourcommand-template.md`

## Validation

- [Quality checks to perform]
- [Constitution principles to verify]
```

### Step 2: Create Template (Optional)

If your command generates structured documents, create `.specify/templates/yourcommand-template.md`:

```markdown
# {{TITLE}}

**Branch**: `{{BRANCH_NAME}}`
**Created**: {{DATE}}

## Section 1

{{CONTENT_1}}

## Section 2

{{CONTENT_2}}
```

Placeholders use `{{PLACEHOLDER_NAME}}` syntax and are filled by the agent during execution.

### Step 3: Add Helper Script (Optional)

For commands that need validation or complex logic, add `.specify/scripts/bash/yourcommand-helper.sh`:

```bash
#!/usr/bin/env bash
# Description: Helper for speckit.yourcommand
# Usage: ./yourcommand-helper.sh [OPTIONS]

set -euo pipefail

# Your helper logic here
```

### Step 4: Update CLAUDE.md

If the command should be discoverable, add it to `CLAUDE.md`:

```markdown
## Available Commands

- `/speckit.yourcommand` - Brief description
```

## Command Examples

### Example: Review Command

A command to review specifications for completeness:

**`.claude/commands/speckit.review.md`**:

```markdown
# /speckit.review

Review a completed feature specification for constitution compliance and quality.

## Prerequisites

- Feature specification exists in `specs/NNN-feature-name/`
- spec.md and plan.md are complete

## Process

1. Read the feature specification from the provided path
2. Check each constitution principle:
   - Research-First Development: Does feature serve scientific goals?
   - Reproducibility: Is environment documented?
   - Documentation: Is "why" explained before "how"?
   - Incremental: Is MVP defined?
   - Library Integration: Are standard tools used?
3. Review acceptance criteria for testability
4. Generate review report

## Input

Provide the feature path: `specs/NNN-feature-name/`

## Output

- `specs/NNN-feature-name/review.md` - Review findings

## Validation Checklist

- [ ] All 5 constitution principles addressed
- [ ] Acceptance criteria are measurable
- [ ] Dependencies are documented
- [ ] No out-of-scope items in implementation
```

### Example: Export Command

A command to export specification summaries:

**`.claude/commands/speckit.export.md`**:

```markdown
# /speckit.export

Export feature specification summary for external sharing.

## Prerequisites

- Feature specification is complete (spec.md, plan.md, tasks.md exist)

## Process

1. Read the complete feature specification
2. Generate a summary document with:
   - Feature overview (from spec.md)
   - Key decisions (from plan.md)
   - Task count and status (from tasks.md)
3. Format for external audience (no internal references)

## Input

- Feature path: `specs/NNN-feature-name/`
- Format: markdown (default) or plain text

## Output

- `specs/NNN-feature-name/summary.md` - Exportable summary
```

## Template Syntax

### Placeholders

Use double curly braces for placeholders:

| Placeholder | Description |
|------------|-------------|
| `{{FEATURE_NAME}}` | Human-readable feature name |
| `{{BRANCH_NAME}}` | Git branch name (NNN-feature-slug) |
| `{{DATE}}` | Current date (YYYY-MM-DD) |
| `{{USER_STORIES}}` | Generated user stories section |
| `{{REQUIREMENTS}}` | Requirements list |

### Conditional Sections

Templates can include optional sections with comments:

```markdown
## Optional Section

<!-- Include if: condition description -->
{{OPTIONAL_CONTENT}}
<!-- End optional -->
```

### Linked Templates

Templates can reference other templates:

```markdown
## Constitution Check

<!-- See: .specify/templates/constitution-check.md -->
{{CONSTITUTION_CHECK}}
```

## Integration with Constitution

### Adding Constitution Checks

Commands that create plans should include constitution validation:

```markdown
## Constitution Check

Before proceeding, verify this feature aligns with research principles:

### Principle I: Research-First Development
- Does this feature serve a scientific research goal?
- Is the purpose clearly documented?

### Principle II: Reproducibility
- Is the environment specified?
- Are dependencies documented?

[Continue for all 5 principles]

**Gate**: All principles must pass to proceed with planning.
```

### Referencing the Constitution

In command definitions, reference the constitution:

```markdown
## Validation

Verify against constitution at `.specify/memory/constitution.md`:
- Check all applicable principles
- Document any principle-specific considerations
- Flag potential violations for user review
```

## Best Practices

### Command Design

1. **Single responsibility** - Each command does one thing well
2. **Clear prerequisites** - State what must exist before running
3. **Defined outputs** - Specify exactly what gets created
4. **Validation steps** - Include quality checks

### Template Design

1. **Consistent structure** - Follow patterns from existing templates
2. **Meaningful placeholders** - Names should be self-documenting
3. **Include examples** - Show expected content format
4. **Link to guides** - Reference relevant documentation

### Documentation

1. **Update CONTRIBUTING.md** - Add command to developer docs
2. **Add to README if user-facing** - Include in command list
3. **Include examples** - Show realistic usage

## Testing Your Command

### Manual Testing

1. Create a test feature:
   ```bash
   # Run your command
   /speckit.yourcommand "Test feature"
   ```

2. Verify output:
   - Check generated files exist
   - Validate content structure
   - Ensure links work

3. Test edge cases:
   - Missing prerequisites
   - Invalid input
   - Large inputs

### Integration Testing

Run through the full workflow:

```bash
# 1. Create specification
/speckit.specify "Test feature"

# 2. Run your new command
/speckit.yourcommand specs/NNN-test-feature/

# 3. Verify it integrates with existing commands
/speckit.plan
```

## Troubleshooting

### Command Not Found

- Verify file is in `.claude/commands/`
- Check filename matches `speckit.commandname.md`
- Ensure Claude Code has access to the directory

### Template Not Loading

- Verify template path is correct
- Check template file exists
- Ensure markdown syntax is valid

### Output Not Generated

- Check prerequisites are met
- Verify output path is writable
- Review command process steps

## See Also

- [Architecture](architecture.md) - System overview
- [Testing Guide](testing-guide.md) - Validation procedures
- [CONTRIBUTING.md](../../CONTRIBUTING.md) - Contribution guidelines
