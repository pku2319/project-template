# project-template

An agent skill that scaffolds new projects: it asks for a name, stack and supported versions, installs the stack, writes AGENTS.md, README.md, a `bin/setup` script and an install skill that keeps the script current, then adds a testing suite, committing after each stage.

The skill follows the open [Agent Skills](https://agentskills.io) format, so it works in Claude Code and in any other agent that loads skills from a `SKILL.md` folder.

## Installation

Link the skill into your personal skills folder so it is available in every directory.

Claude Code:

```
ln -s "$(pwd)/skills/new-project" ~/.claude/skills/new-project
```

Other agents: link it into the folder your agent reads personal skills from. Many read the shared `~/.agents/skills/` folder:

```
mkdir -p ~/.agents/skills
ln -s "$(pwd)/skills/new-project" ~/.agents/skills/new-project
```

## Running

From the folder where the new project should live, start your agent and ask it to start a new project. In Claude Code you can also run:

```
/new-project
```

## Layout

- `skills/new-project/SKILL.md`: the process the agent follows
- `skills/new-project/templates/`: files copied into each new project, with `{{PLACEHOLDERS}}` the agent fills in
- `skills/new-project/references/stacks.md`: default build and test tools per stack

Projects created by the skill keep their install skill in `.agents/skills/install/`, with a link at `.claude/skills/install` so Claude Code finds it as well.
