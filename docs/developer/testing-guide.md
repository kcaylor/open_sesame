# Testing Guide

This guide covers testing procedures for res_spec contributions. Since res_spec is primarily documentation and bash scripts, testing focuses on validation rather than unit tests.

## Testing Categories

### 1. Script Testing

Environment scripts in `.specify/scripts/bash/` require manual testing:

#### Syntax Validation

```bash
# Check bash syntax without executing
bash -n ./.specify/scripts/bash/your-script.sh

# Check with shellcheck (if installed)
shellcheck ./.specify/scripts/bash/your-script.sh
```

#### Functional Testing

Test each script with various scenarios:

```bash
# Test help output
./script.sh --help

# Test with valid inputs
./script.sh --option value

# Test with invalid inputs (should fail gracefully)
./script.sh --invalid

# Test quiet mode
./script.sh --quiet

# Test JSON output (if supported)
./script.sh --json
```

### 2. Documentation Testing

#### Link Validation

Check all internal links resolve:

```bash
# Manual check: Search for markdown links
grep -r '\[.*\](.*\.md)' docs/ README.md CONTRIBUTING.md

# Verify each link target exists
# Links should be relative paths like:
# [Guide](docs/user/guide.md) - from root
# [Other](../developer/other.md) - relative to current file
```

#### Code Example Validation

Verify code examples are accurate:

```bash
# Copy-paste code blocks and verify they work
# Check command outputs match documentation
# Ensure file paths in examples are correct
```

### 3. Template Testing

#### Generation Validation

```bash
# Run speckit commands that use templates
/speckit.specify "Test feature"

# Verify generated files:
# - Match expected structure
# - Contain no raw placeholders
# - Have valid markdown syntax
```

### 4. Integration Testing

#### Full Workflow Test

Run through the complete res_spec workflow:

```bash
# 1. Initialize fresh project
./.specify/scripts/bash/init-project.sh --dry-run --project-name test-project

# 2. Create specification
/speckit.specify "Test analysis feature"

# 3. Generate plan
/speckit.plan

# 4. Generate tasks
/speckit.tasks

# 5. Verify all artifacts exist and link correctly
ls -la specs/NNN-test-feature/
```

## Test Scenarios

### Environment Scripts

#### env-init.sh

| Scenario | Command | Expected Result |
|----------|---------|-----------------|
| Help output | `--help` | Display usage |
| Pixi init | `--tool pixi --quiet` | Creates pixi.toml, .env-config |
| Conda init | `--tool conda --quiet` | Creates environment.yml, .env-config |
| Venv init | `--tool venv --quiet` | Creates .venv/, requirements.txt |
| From config | `--from-config` | Recreates environment from .env-config |
| Invalid tool | `--tool invalid` | Error message, exit 1 |

#### env-sync.sh

| Scenario | Command | Expected Result |
|----------|---------|-----------------|
| Auto sync | `--auto` | Updates .env-config with current packages |
| Package doc | `--package numpy` | Prompts for package notes |
| JSON output | `--json` | Outputs package info as JSON |
| No env | (no environment active) | Error with activation instructions |

#### env-validate.sh

| Scenario | Command | Expected Result |
|----------|---------|-----------------|
| Valid env | (with valid env) | Success message |
| Missing packages | (with missing deps) | List missing packages |
| Fix mode | `--fix` | Attempts to install missing |
| JSON output | `--json` | Machine-readable validation result |

#### init-project.sh

| Scenario | Command | Expected Result |
|----------|---------|-----------------|
| Dry run | `--dry-run --project-name test` | Shows actions without executing |
| Full init | `--project-name test --env-tool venv --quiet` | Complete initialization |
| Invalid name | `--project-name "Bad Name!"` | Error about invalid characters |
| Already init | (run twice) | Warning, offer --force |
| Force reinit | `--force` | Reinitializes existing project |

### Cross-Platform Testing

Test scripts on multiple platforms:

- **macOS** - Primary development platform
- **Linux** - Production environments
- **WSL** - Windows developers

Platform-specific issues to watch for:

```bash
# Date format differences
date -Iseconds  # May not work on macOS
date +%Y-%m-%dT%H:%M:%S%z  # More portable

# sed differences
sed -i '' 's/old/new/' file  # macOS requires ''
sed -i 's/old/new/' file     # Linux doesn't

# Path handling
"$HOME/path"  # Works everywhere
~/path        # Works everywhere
```

## Validation Checklists

### Before Submitting Changes

#### Documentation Changes

- [ ] All markdown renders correctly
- [ ] Internal links work (relative paths)
- [ ] Code examples are tested and accurate
- [ ] Spelling and grammar checked
- [ ] Consistent with existing documentation style

#### Script Changes

- [ ] `bash -n` syntax check passes
- [ ] `--help` output is accurate
- [ ] Error messages are helpful
- [ ] Exit codes are correct (0 success, 1+ error)
- [ ] Works on macOS and Linux
- [ ] Handles edge cases gracefully
- [ ] No hardcoded paths (use variables)

#### Template Changes

- [ ] Generated output is valid markdown
- [ ] All placeholders are documented
- [ ] Existing commands still work
- [ ] Template follows established patterns

#### Command Changes

- [ ] Prerequisites are documented
- [ ] Process steps are clear
- [ ] Output is specified
- [ ] Works with existing workflow
- [ ] Constitution checks included if appropriate

### After Making Changes

#### Quick Validation

```bash
# 1. Check syntax of all bash scripts
for script in .specify/scripts/bash/*.sh; do
    bash -n "$script" && echo "✓ $script"
done

# 2. Check markdown links exist
# (manual review of grep output)
grep -rh '\[.*\]([^)]*\.md)' docs/ README.md CONTRIBUTING.md | sort -u
```

#### Integration Check

```bash
# Run through primary workflow
/speckit.specify "Validation test"
# Verify spec.md created correctly

/speckit.plan
# Verify plan.md created correctly

# Clean up test files
rm -rf specs/*-validation-test/
```

## Common Issues

### Script Issues

**Problem**: Script fails on macOS but works on Linux

**Cause**: BSD vs GNU tool differences (sed, date, etc.)

**Solution**: Use portable syntax or check platform:

```bash
if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' 's/old/new/' file
else
    sed -i 's/old/new/' file
fi
```

---

**Problem**: Script fails with "unbound variable"

**Cause**: Using `set -u` with unset variables

**Solution**: Provide defaults:

```bash
VARIABLE="${VARIABLE:-default_value}"
```

---

**Problem**: Script continues after error

**Cause**: Missing `set -e` or error in pipe

**Solution**: Use proper error handling:

```bash
set -euo pipefail
command_that_might_fail || {
    echo "Failed"
    exit 1
}
```

### Documentation Issues

**Problem**: Links break after file moves

**Cause**: Absolute paths or incorrect relative paths

**Solution**: Use correct relative paths from the linking file's location:

```markdown
<!-- From docs/user/quickstart.md linking to docs/user/troubleshooting.md -->
[Troubleshooting](troubleshooting.md)

<!-- From README.md linking to docs/user/quickstart.md -->
[Quickstart](docs/user/quickstart.md)
```

---

**Problem**: Code block doesn't highlight correctly

**Cause**: Missing or incorrect language specifier

**Solution**: Always specify language:

````markdown
```bash
echo "Hello"
```
````

### Template Issues

**Problem**: Placeholders appear in output

**Cause**: Template not being processed correctly

**Solution**: Verify placeholder syntax matches what the command expects

---

**Problem**: Template changes break existing specs

**Cause**: New required sections or changed structure

**Solution**: Maintain backward compatibility or document migration steps

## Automated Validation

While res_spec doesn't have a formal test suite, you can create validation scripts:

```bash
#!/usr/bin/env bash
# validate.sh - Quick validation of res_spec

set -euo pipefail

echo "Checking bash syntax..."
for script in .specify/scripts/bash/*.sh; do
    bash -n "$script" || exit 1
done
echo "✓ All scripts have valid syntax"

echo ""
echo "Checking required files exist..."
required_files=(
    "README.md"
    "CONTRIBUTING.md"
    "CLAUDE.md"
    ".specify/memory/constitution.md"
)
for file in "${required_files[@]}"; do
    [[ -f "$file" ]] || { echo "Missing: $file"; exit 1; }
done
echo "✓ All required files exist"

echo ""
echo "Validation complete!"
```

## See Also

- [Architecture](architecture.md) - System design
- [Extending Speckit](extending-speckit.md) - Adding commands
- [CONTRIBUTING.md](../../CONTRIBUTING.md) - Contribution guidelines
