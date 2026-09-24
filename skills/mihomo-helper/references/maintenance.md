# 日常维护与故障恢复

先定位当前用户的 `~/config/mihomo/config.yml`（Windows `%USERPROFILE%\config\mihomo\config.yml`）；如果用户选的是同目录 `config.yaml` 或自定路径，按实际文件处理。通过配置文件查明节点与规则 provider 的 `interval`、缓存文件和地区组，勿把订阅 URL/令牌写进共享报告。实际维护前备份配置和用户自定义规则，记录当前 mihomo 版本、当前选择的策略组及任务状态。

- 自动更新：HTTP 节点和规则 provider 根据配置中的 interval 更新；核对更新时间、HTTP 失败记录、地区组节点数，以及 GitHub 规则和其他规则是否成功加载。首次或持续更新失败时，在用户网络上分别检查 provider 域名连通性和代理节点可达性；不擅自把全部流量改成代理或把密钥发到第三方转换站。静态本地节点不会因 interval 自动更新。
- 健康检查：登录后任务是否启动且未重复运行；TUN、DNS、普通国内网站、局域网访问及已明确代理的 GitHub/流媒体分别是否正常。`MATCH,DIRECT` 保持不变。短暂网络断开时核对缓存和自动重试；如发现虚拟机/防火墙冲突，先恢复先前网络状态，再定位原因。
- DNS：Fake IP 保留域名给非 IP 规则先匹配；已确定走代理的域名不必为目标站预先做本地 DNS 解析，但节点自身域名仍可能本地解析。Windows TUN 的 53 端口劫持不一定包含局域网 DNS、浏览器内置 DoH 等；不能保证零泄漏。内网设备名要能得到真实 IP；如需 `strict-route` 防多宿主 DNS 泄漏，先评估 VirtualBox/局域网兼容性并获用户同意。[官方 DNS 文档](https://wiki.metacubex.one/en/config/dns/)与 [TUN 文档](https://wiki.metacubex.one/en/config/inbound/tun/)。
- 配置更改：先保存旧版，明确是哪个规则/provider/进程被调整；取得实际部署授权后再做语法检查及连接命中验证。误伤时撤回最近的精确规则，而不是放宽兜底。不要未经允许重置 Fake IP 缓存、删除连接或重启其他网络服务。

若用户希望看到进程/规则证据，可在同意后临时启用仅回环监听的 controller，使用强 secret，从 `/connections`、`/rules`、`/providers/rules` 查看路由依据；脱敏处理并在诊断结束后按约定关闭。流量总量 `/traffic` 不能识别应用。[Controller API](https://wiki.metacubex.one/en/api/)。
