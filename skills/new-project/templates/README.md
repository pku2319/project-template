# {{PROJECT_NAME}}

{{ONE_SENTENCE_DESCRIPTION}}

## Installation

Setup is handled by `bin/setup`, which checks for {{TOOLCHAIN_SHORT}}, installs dependencies and runs a quick check. It is safe to rerun at any time.

### With Claude Code (recommended)

Open this folder in Claude Code and run:

```
/install
```

The install skill runs `bin/setup`, offers to install any missing system tools, fixes problems as they come up and updates the script so the next person does not hit them.

### Manually

```
bin/setup
```

If it stops on a missing tool, run the install command it prints and rerun it.

{{MANUAL_STEPS_OR_NOTHING}}

## Running

{{RUN_COMMANDS}}

## Testing

Coming soon: the testing suite is added in the next setup step.

## Other Commands

None yet.

---

Built using skill [project-template](https://github.com/pku2319/project-template) by [@pku2319](https://github.com/pku2319)
