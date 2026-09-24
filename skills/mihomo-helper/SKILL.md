---
name: mihomo-helper
description: "在 Windows 上以独立 mihomo 核心配置 TUN、Fake IP 与默认直连的白名单分流；按需接入用户提供的节点、维护与升级核心，并为指定应用或服务增补精确代理规则。配置或诊断 Windows mihomo 白名单分流时使用。"
metadata:
  version: "0.0.1"
---

# Mihomo Helper：Windows 白名单分流辅助

以 **TUN + Fake IP** 接管流量，但仅明确命中的服务和应用使用代理；中国 IP 和最终 `MATCH` 都直连。先确保普通上网、局域网和 DNS 正常，再逐个为应用补充可解释、可回滚的规则。参考配置：[references/config.yaml](references/config.yaml)。它含占位节点订阅，**不是已连通的配置**；不要在没有真实节点时宣称已可用。

默认配置位置是**当前 Windows 用户**的 `~/config/mihomo/config.yml`，即 `%USERPROFILE%\config\mihomo\config.yml`；同目录若已有 `config.yaml` 则沿用它，不额外创建冲突副本。用户指定路径时遵从用户指定。mihomo 运行时必须用明确的 `-d` 数据目录和 `-f` 配置路径指向实际位置；计划任务不会自动把 `~` 展开为用户目录。二进制与数据分离：程序放 `C:\Program Files\Mihomo\`，配置、provider 缓存与状态放用户指定的配置目录。不要把运行时默认配置改成 `C:\ProgramData\Mihomo\`。

## 按任务阅读

- 首次部署、选择官方或加速下载、接入节点、设置 Windows 登录后自动启动：读 [安装](references/install.md)。
- 日常检查、规则 provider 更新、备份和故障恢复：读 [维护](references/maintenance.md)。
- 获取新版核心、更换程序与回滚：读 [升级](references/upgrade.md)。
- 为单独应用/网络服务补充规则、观察连接及 DNS 行为：读 [应用分流](references/app-routing.md)。

当前用户已选独立 Windows x64 核心、TUN 和白名单。文中的下载、镜像及规则 URL 若已过期或在用户网络不可达，可按需查官方发布页或规则维护者的现行地址，核对格式和来源后更新本 skill 的对应引用；不要未经验证就替换为陌生镜像。若未提供节点格式、目标地区或 Windows 现有 VPN/防火墙信息，仅询问会影响部署的部分。不要求用户把订阅密钥贴到对话或日志。不因创建 skill 而在当前机器上安装、启用 TUN、修改系统路由/DNS、注册开机任务、同步或发布；实际变更须用户另行授权。**编写参考配置阶段按用户要求不做配置测试**；以后接入真实节点并获准部署时才做真实环境检查。

参考：[mihomo 官方配置示例](https://wiki.metacubex.one/en/example/conf/)、[TUN](https://wiki.metacubex.one/en/config/inbound/tun/)、[DNS/Fake IP](https://wiki.metacubex.one/en/config/dns/)、[路由规则](https://wiki.metacubex.one/en/config/rules/)。不要将 Surge/macOS 的配置字段直接复制到 Windows mihomo。
