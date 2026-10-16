# project-template

A Claude Code skill that scaffolds new projects: it asks for a name, stack and supported versions, installs the stack, writes AGENTS.md, README.md, a `bin/setup` script and an install skill that keeps the script current, then adds a testing suite, committing after each stage.

## Installation

Link the skill into your personal skills folder so it is available in every directory:

```
ln -s "$(pwd)/skills/new-project" ~/.claude/skills/new-project
```

## Running

From the folder where the new project should live, start Claude Code and run:

```
/new-project
```

## Layout

- `skills/new-project/SKILL.md`: the process Claude follows
- `skills/new-project/templates/`: files copied into each new project, with `{{PLACEHOLDERS}}` Claude fills in
- `skills/new-project/references/stacks.md`: default build and test tools per stack
