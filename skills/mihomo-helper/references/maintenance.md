# 维护与恢复

按 [路径与修改约定](../SKILL.md#路径与修改约定) 定位配置、备份并记录变更。维护前记下核心版本、策略选择和自启任务状态。

- **Provider**：检查更新时间、失败日志和地区组节点数。更新失败时分别检查下载地址及代理节点可达性，保留可用缓存；不以全局代理掩盖故障。
- **网络**：确认没有重复核心，分别检查 TUN、DNS、局域网、国内网站、GitHub 与指定代理服务。虚拟机或防火墙冲突时先恢复原网络状态。
- **DNS**：Fake IP 保留域名供非 IP 规则匹配，但节点自身仍可能本地解析。53 端口劫持不一定覆盖局域网 DNS 或浏览器 DoH，不能承诺零泄漏；内网设备名需返回真实 IP。启用 `strict-route` 前评估虚拟机兼容性并获授权。
- **恢复**：误伤时撤回最近的规则，保持 `MATCH,DIRECT`。未经允许不清空 Fake IP 缓存、关闭连接或重启其他网络服务。

需要连接证据时读 [应用分流](app-routing.md)。参考：[DNS](https://wiki.metacubex.one/en/config/dns/)、[TUN](https://wiki.metacubex.one/en/config/inbound/tun/)。
