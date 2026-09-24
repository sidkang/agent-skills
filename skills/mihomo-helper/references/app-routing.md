# 为应用和网络服务增补白名单规则

基础配置 [config.yaml](config.yaml) 只让 GitHub、Google、YouTube、Netflix 和已列入规则的常见流媒体走代理。CN IP 和最终 `MATCH` 都是 `DIRECT`；未列入白名单的海外域名可能无法访问，不能以“整体改成代理”代替排查。按用户要求逐个补充精确服务/应用规则，并保持国内直连与局域网体验。

1. 先确认应用 exe 完整路径、是否只代理特定服务域名或整个进程、目标地区和预期解锁结果。观察已授权的实际连接：如已启用回环 controller，可从 `GET /connections` 读 `metadata.process`、`processPath`、目标域名/IP、`rule`、`rulePayload`、`chains`；`GET /rules` 与 `GET /providers/rules` 用于定位规则来源。带 Bearer secret 的请求只发本机，短时记录并脱敏，不泄露令牌/订阅/访问记录。若应用没有经过 TUN 或缺少进程字段，先查权限/捕获方式，不假定进程规则有效。不安装 HTTPS 根证书抓内容。
2. 优先查看 [SukkaW/Surge 的 mihomo Clash 规则](https://github.com/SukkaW/Surge) 和 [blackmatrix7 的 Clash 服务规则](https://github.com/blackmatrix7/ios_rule_script/tree/master/rule/Clash)，核对 URL、`behavior`、`format`、维护情况及是否包含共享 CDN。Sukka 的 Surge `List/*.conf` 不能直接作为 mihomo provider：`Clash/non_ip/*.txt` 是 classical/text，`Clash/ip/lan.txt` 和 `stream.txt` 也是 classical，`Clash/ip/china_ip.txt` 为纯 CIDR。引入远程列表时保留更新间隔；第一次获取失败不要靠放宽 `MATCH` 掩盖。
3. 先加确定的域名或已核实的 `RULE-SET,service,US`，必要时再用 `PROCESS-PATH,C:\\Program Files\\Vendor\\App\\app.exe,US`（YAML 中用单引号包住完整规则）。`PROCESS-NAME,app.exe,US` 可能误匹配同名程序；整个浏览器/共享 CDN 无差别代理会伤及其他服务。只对确实缺少域名的硬编码 IP 添加 `IP-CIDR`；IP 类规则放在域名和其他非 IP 规则后。路由顺序：精确应用/域名 → GitHub → 服务/流媒体域名 → 内网 IP → 流媒体 IP → CN IP 直连 → `MATCH,DIRECT`。域名先于 IP 规则能减少被代理目标域名的本地解析，但不能保证其他未知域名无 DNS 查询。[mihomo 规则说明](https://wiki.metacubex.one/en/config/rules/)。
4. 标记改动意图、预期地区、观测证据和撤销方式。只在用户授权、真实节点就绪的目标 Windows 上校验语法、命中链、普通直连和服务实际解锁；延迟测试不等于流媒体解锁。若误伤，撤回新增规则，不把最后一条改成 PROXY。写参考模板时不运行配置测试。

地区组按 US、JP、TW、HK、SG、OTHER 分类，靠节点名过滤；真正接入订阅后要确认组内有节点及订阅顺序。默认 `fallback`：优先使用排序在前的可用节点，故障才切换，而非选延迟最低者；用户明确要求时再改。`AUTO` 单独保留 `url-test`，测速不保证解锁。不使用未经稳定版确认的 `type: smart`。[Proxy group 字段](https://wiki.metacubex.one/en/config/proxy-groups/)。
