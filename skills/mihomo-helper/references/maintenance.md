# 维护与恢复

按 [路径约定](../SKILL.md#路径与修改约定) 定位实际用户/实例/配置，记录版本、文件 SHA256、策略选择、任务定义及启用/运行状态。实际变更先读 [验证与事务](validation.md)，不把备份存在等同于可恢复。

- **Provider**：检查更新时间、失败日志、各地区节点数和选择、TCP/UDP 能力。空组、全部不可达、服务不可用分别处理；更新后重验空组不直连、不自动跨地区。保留可用缓存，不以全局代理掩盖故障；社区清单的新增关键字/进程/IP 要按已接受的范围复核。
- **网络/DNS**：分别检查 TUN、系统 DNS、浏览器 DoH、IPv6、其它 VPN、内网、普通直连和指定服务。Windows 不会自动劫持发往局域网的 DNS；无法获得域名时可能无法命中域名规则，不只是“DNS 泄漏提醒”。从实际应用的新连接记录 host、rule/rulePayload、chains 和最终地区，缺证据则标记未验证。
- **恢复**：运行中变更经本地事务和已启动的独立 watchdog 执行；误伤回滚最近变更，保持 MATCH,DIRECT。不能靠另一次模型调用恢复断网。文件/任务并发冲突时停止并报告，不覆盖用户新改动。未经允许不清 Fake IP 缓存、关连接、重启其它网络服务或启用禁用任务。

内网设备名需要真实 IP 和正确路由，fake-ip-filter 不是 DIRECT。将 system 换为公共 DoH 不自动解决应用 DNS 捕获；启用 strict-route 前评估虚拟机兼容性并获授权。临时诊断恢复 controller/secret 原状，日志脱敏。参考：[DNS](https://wiki.metacubex.one/en/config/dns/)、[TUN](https://wiki.metacubex.one/en/config/inbound/tun/)、[连接证据](app-routing.md)。
