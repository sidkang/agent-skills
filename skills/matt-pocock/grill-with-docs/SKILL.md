---
name: grill-with-docs
description: A relentless interview to sharpen a plan or design, which also creates docs (ADR's and glossary) as we go.
disable-model-invocation: true
metadata:
  upstream:
    repo: mattpocock/skills
    path: skills/engineering/grill-with-docs
    commit: 3cca18b368ae95cdbdebbff572ccafa662551015
    status: modified
    notes:
      - local: omit agents/openai.yaml because Pi does not load OpenAI-specific skill metadata.
      - local: load the two installed skills with Pi read rather than a Skill tool.
---

Use `read` to load the installed `grilling` and `domain-modeling` SKILL.md files. Follow both: conduct the interview and update domain terms and ADRs as decisions are resolved.
