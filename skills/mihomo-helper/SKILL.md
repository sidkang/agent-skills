---
name: mihomo-helper
description: "安装、维护和升级 Windows mihomo 独立核心，使用 TUN、Fake IP 和默认直连的白名单配置，为指定应用或服务增补代理规则。配置或诊断 Windows mihomo 分流时使用。"
compatibility: "Windows x64；启用 TUN 需要可提升权限的用户会话。"
metadata:
  version: "0.0.3"
---

# Mihomo Helper

以 **TUN + Fake IP、默认直连**为基础，在保持普通上网和局域网体验的前提下，为指定应用添加代理规则。中国 IP 和最终 `MATCH` 均直连。[参考配置](references/config.yaml)含占位订阅，部署前须接入真实节点。

## 路径与修改约定

- 程序：`C:\Program Files\Mihomo\mihomo.exe`。
- 配置：当前用户的 `~/config/mihomo/config.yml`，即 `%USERPROFILE%\config\mihomo\config.yml`；已有 `config.yaml` 则沿用，用户指定路径优先。
- 数据：配置所在目录存放 provider 缓存和状态。启动时用 `-d`、`-f` 指定实际绝对路径，不依赖计划任务展开 `~`。

修改实际配置前先备份、阅读差异。文件顶部用 `# mihomo-helper:` **YAML 注释头**记录程序位置、配置路径及变更日志（日期、原因、摘要、回滚依据）；不写密钥，不加 Markdown 式 `---` frontmatter。缺少标记仅表示本 skill 无维护记录：询问用户保留、合并或备份后替换，确认后再改。有标记也不代表可以覆盖用户后续修改。

## 按任务阅读

- [安装](references/install.md)：下载、节点接入与登录自启。
- [维护](references/maintenance.md)：provider 更新、DNS 排查与恢复。
- [升级](references/upgrade.md)：更换核心与回滚。
- [应用分流](references/app-routing.md)：连接证据和精确规则。

URL 过期或不可达时，可核对官方或维护者的现行地址后更新引用。仅询问影响当前操作的环境、节点格式和目标地区；不索取公开的订阅密钥。实际安装、网络变更、自启、同步与发布须取得对应授权。**编写模板时不运行配置测试**；真实部署获准后再检查运行效果。
