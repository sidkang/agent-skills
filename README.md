# Agent Skills

个人维护的 Agent Skills 集合，涵盖需求梳理、项目规划、架构设计与工具维护，主要用于 Pi。

## Skills

| Skill | 用途 |
| --- | --- |
| [codebase-design](skills/matt-pocock/codebase-design/SKILL.md) † | 设计模块接口、边界与测试切入点。 |
| [domain-modeling](skills/matt-pocock/domain-modeling/SKILL.md) † | 梳理领域模型，记录术语与 ADR。 |
| [grill-with-docs](skills/matt-pocock/grill-with-docs/SKILL.md) † | 通过访谈澄清方案并沉淀决策文档。 |
| [grilling](skills/matt-pocock/grilling/SKILL.md) † | 通过追问挑战假设、澄清需求。 |
| [handoff](skills/matt-pocock/handoff/SKILL.md) † | 将当前讨论整理为交接文档。 |
| [improve-codebase-architecture](skills/matt-pocock/improve-codebase-architecture/SKILL.md) † | 扫描架构改进机会并生成可视化报告。 |
| [prototype](skills/matt-pocock/prototype/SKILL.md) † | 用一次性逻辑或 UI 原型验证设计。 |
| [setup-repo](skills/matt-pocock/setup-repo/SKILL.md) † | 配置议题跟踪、标签和领域文档。 |
| [teach](skills/matt-pocock/teach/SKILL.md) † | 教授概念与技能，组织练习和学习记录。 |
| [to-spec](skills/matt-pocock/to-spec/SKILL.md) † | 将讨论整理成需求规格并发布。 |
| [to-tickets](skills/matt-pocock/to-tickets/SKILL.md) † | 拆分可验收的任务并明确依赖。 |
| [triage](skills/matt-pocock/triage/SKILL.md) † | 分诊 issues 与 PR，整理执行简报。 |
| [wayfinder](skills/matt-pocock/wayfinder/SKILL.md) † | 用决策地图推进跨会话的大型规划。 |
| [mihomo-helper](skills/mihomo-helper/SKILL.md) | 维护 Windows mihomo 核心与应用分流。 |

† 改编自 [Matt Pocock](https://github.com/mattpocock/skills)。

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
