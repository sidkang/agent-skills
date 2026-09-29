# Agent Skills

个人维护的 Agent Skills 集合，涵盖需求梳理、项目规划、架构设计与工具维护，主要用于 Pi。

## Skills

| Skill | 用途 |
| --- | --- |
| [codebase-design](skills/matt-pocock/codebase-design/SKILL.md) † | 用深模块原则设计接口与边界，减少耦合并明确测试切入点。 |
| [domain-modeling](skills/matt-pocock/domain-modeling/SKILL.md) † | 梳理业务概念与领域边界，将共识沉淀为术语表和 ADR。 |
| [grill-with-docs](skills/matt-pocock/grill-with-docs/SKILL.md) † | 通过多轮访谈澄清方案，同时记录领域术语与架构决策。 |
| [grilling](skills/matt-pocock/grilling/SKILL.md) † | 通过追问挑战假设，明确需求范围、约束和待决问题。 |
| [handoff](skills/matt-pocock/handoff/SKILL.md) † | 提炼当前讨论、关键决策与待办，生成供下一次会话接手的文档。 |
| [improve-codebase-architecture](skills/matt-pocock/improve-codebase-architecture/SKILL.md) † | 扫描代码库中的架构改进机会，生成 HTML 报告并讨论候选方案。 |
| [prototype](skills/matt-pocock/prototype/SKILL.md) † | 构建一次性逻辑或 UI 原型，在正式开发前验证行为与交互设计。 |
| [setup-repo](skills/matt-pocock/setup-repo/SKILL.md) † | 配置项目的议题跟踪、分类标签与领域文档，为规划流程做准备。 |
| [teach](skills/matt-pocock/teach/SKILL.md) † | 结合当前工作区教授概念与技能，通过练习和学习记录巩固理解。 |
| [to-spec](skills/matt-pocock/to-spec/SKILL.md) † | 将已达成共识的讨论整理成需求规格，并发布到项目议题跟踪器。 |
| [to-tickets](skills/matt-pocock/to-tickets/SKILL.md) † | 将规格拆成可独立验收的纵向任务，明确交付内容和阻塞关系。 |
| [triage](skills/matt-pocock/triage/SKILL.md) † | 对 issues 与外部 PR 分类、核实和澄清，整理为可执行的简报。 |
| [wayfinder](skills/matt-pocock/wayfinder/SKILL.md) † | 将大型规划组织为跨会话的决策地图，逐步解决未知与阻塞。 |
| [mihomo-helper](skills/mihomo-helper/SKILL.md) | 安装、升级和维护 Windows mihomo 核心，配置 TUN 与应用分流。 |

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

## 许可证

本仓库采用 [MIT License](LICENSE)，保留上游作者的版权声明。

## 致谢

- [mattpocock/skills](https://github.com/mattpocock/skills) — Matt Pocock 系列的上游来源。
- [vercel-labs/skills](https://github.com/vercel-labs/skills) — Skill 安装与更新工具。
