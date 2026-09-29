# Agent Skills

个人维护的 Agent Skills 集合，涵盖需求梳理、项目规划、架构设计与工具维护，主要用于 Pi。

## Skills

| Skill | 用途 | 来源 |
| --- | --- | --- |
| [codebase-design](skills/matt-pocock/codebase-design/SKILL.md) | 用深模块设计原则梳理模块接口、边界与可测试性。 | Matt Pocock |
| [domain-modeling](skills/matt-pocock/domain-modeling/SKILL.md) | 明确领域术语与模型，并将共识沉淀为词汇表和 ADR。 | Matt Pocock |
| [grill-with-docs](skills/matt-pocock/grill-with-docs/SKILL.md) | 通过追问澄清方案，同时记录领域术语和架构决策。 | Matt Pocock |
| [grilling](skills/matt-pocock/grilling/SKILL.md) | 通过多轮访谈挑战假设、澄清需求并收敛决策。 | Matt Pocock |
| [handoff](skills/matt-pocock/handoff/SKILL.md) | 将当前讨论整理为可供下一位 agent 或下一次会话接手的交接文档。 | Matt Pocock |
| [improve-codebase-architecture](skills/matt-pocock/improve-codebase-architecture/SKILL.md) | 扫描代码库的模块设计改进机会，生成 HTML 报告并讨论选中的方案。 | Matt Pocock |
| [prototype](skills/matt-pocock/prototype/SKILL.md) | 用一次性逻辑或 UI 原型验证设计问题，而不是直接交付生产实现。 | Matt Pocock |
| [setup-repo](skills/matt-pocock/setup-repo/SKILL.md) | 为工程规划流程配置议题跟踪、分类标签和领域文档布局。 | Matt Pocock |
| [teach](skills/matt-pocock/teach/SKILL.md) | 在当前工作区内教授概念或技能，并组织学习记录与练习。 | Matt Pocock |
| [to-spec](skills/matt-pocock/to-spec/SKILL.md) | 将已讨论清楚的内容整理成需求规格并发布到项目议题跟踪器。 | Matt Pocock |
| [to-tickets](skills/matt-pocock/to-tickets/SKILL.md) | 将计划或规格拆成可验收的纵向任务，并明确任务之间的阻塞关系。 | Matt Pocock |
| [triage](skills/matt-pocock/triage/SKILL.md) | 对 issues 和外部 PR 分类、核实和澄清，整理成可交给 agent 执行的简报。 | Matt Pocock |
| [wayfinder](skills/matt-pocock/wayfinder/SKILL.md) | 将跨多个会话的大型规划组织为决策地图，逐步消除未知和阻塞。 | Matt Pocock |
| [mihomo-helper](skills/mihomo-helper/SKILL.md) | 安装、维护和升级 Windows mihomo 独立核心，管理 TUN、Fake IP 与应用分流。 | |

## 安装与更新

需要 Node.js 和 npm。

```sh
# 查看可安装的 skills
npx skills@latest add sidkang/agent-skills --list

# 安装指定 skill 到全局 Pi
npx skills@latest add sidkang/agent-skills --skill grilling -g -a pi

# 安装全部 Matt Pocock skills
npx skills@latest add \
  https://github.com/sidkang/agent-skills/tree/master/skills/matt-pocock \
  --skill '*' -g -a pi

# 更新指定的全局 skill
npx skills@latest update grilling -g

# 更新所有由 CLI 管理的全局 skills
npx skills@latest update -g
```

省略 `-g` 则安装到当前项目。已有手动安装的同名 skill 时，先清理旧副本，避免重复加载。更新以本仓库为来源，需先通过 CLI 安装才能跟踪更新。

## 致谢

- [mattpocock/skills](https://github.com/mattpocock/skills) — Matt Pocock 系列的上游来源。
- [vercel-labs/skills](https://github.com/vercel-labs/skills) — Skill 安装与更新工具。
