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
| [librarian](skills/armin/librarian/SKILL.md) ‡ | 缓存并更新远程 Git 仓库，供本地阅读源码、检索文件与查看历史。 |
| [web-browser](skills/armin/web-browser/SKILL.md) ‡ | 通过 CDP 操作浏览器，支持页面交互、截图与控制台和网络调试。 |
| [bro](skills/bro/SKILL.md) § | 将上一条回复改写得简洁易懂，少用术语，保留原来的语言。 |
| [getme](skills/getme/SKILL.md) | 复述对用户目标和问题的理解，区分明确意图与推测，不开始执行。 |
| [skill-authoring](skills/skill-authoring/SKILL.md) | 指导编写和改进 skill，明确工具接口、辅助脚本与验证方法。 |
| [try-serve](skills/try-serve/SKILL.md) | 通过临时 Cloudflare 隧道分享本地 HTML 或静态目录，支持自动到期。 |
| [quark](skills/quark/SKILL.md) | 操作夸克网盘，支持搜索、上传、下载、分享、转存与可逆隔离删除。 |
| [mihomo-helper](skills/mihomo-helper/SKILL.md) | 安装、升级和维护 Windows mihomo 核心，配置 TUN 与应用分流。 |

† 改编自 [Matt Pocock](https://github.com/mattpocock/skills)；‡ 改编自 [Armin Ronacher](https://github.com/mitsuhiko/agent-stuff)；§ 改编自 [dmmulroy/skills](https://github.com/dmmulroy/skills)。

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

除另有注明外采用 [MIT License](LICENSE)；`skills/armin/` 保留上游的 [Apache-2.0](LICENSE-APACHE) 许可，修改说明见各 skill 的来源记录。单独分发 skill 时也需随附适用的许可证。

## 致谢

- [mattpocock/skills](https://github.com/mattpocock/skills) — Matt Pocock 系列的上游来源。
- [mitsuhiko/agent-stuff](https://github.com/mitsuhiko/agent-stuff) — Armin 系列的上游来源及 skill-authoring 的方法启发。
- [dmmulroy/skills](https://github.com/dmmulroy/skills) — bro 的上游来源。
