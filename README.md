# Personal agent config

One copy of skills and rules, shared by every agent via symlinks.

```
~/.agents/skills/<name>/SKILL.md
~/.agents/rules/<name>.mdc
        |
        +-- ~/.claude/skills|rules
        +-- ~/.codex/skills
        +-- ~/.cursor/skills|rules
```

Edit the files here. Relink after add / rename / delete:

```bash
bash ~/.agents/sync.sh            # add --dry-run to preview
```

`sync.sh` is idempotent. It creates missing links, removes links whose source is gone, and refuses to overwrite anything it does not own.

Directory name and the skill frontmatter `name:` must match.
