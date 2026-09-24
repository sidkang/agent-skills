---
name: mihomo-helper
description: "在 Windows 上以独立 mihomo 核心配置 TUN、Fake IP 与默认直连的白名单分流；按需接入用户提供的节点、自动更新 provider，并为指定应用或服务增补精确代理规则。配置或诊断 Windows mihomo 白名单分流时使用。"
metadata:
  version: "0.0.1"
---

# Mihomo Helper：白名单分流辅助

**基底**：TUN 接管 Windows 流量、Fake IP 保留域名；只有明确命中的服务/应用才使用代理，国内 IP 和最终 `MATCH` 均 `DIRECT`。在保证日常直连和局域网体验的基础上，逐个增加有证据的代理规则，不把“海外域名全集”或未知流量一股脑代理。参考配置：[references/config.yaml](references/config.yaml)。该文件是带占位订阅的模板，**不是已连通的配置**；没有真实节点时不能宣称可用。

## 使用前确认

用户选择独立 Windows x64 mihomo 核心、TUN 模式和白名单路由。仅需确认 Windows 环境（防火墙、权限、是否与其他 VPN/TUN 共存）、节点输入形式及目标流媒体解锁区域；不要求用户公开订阅密钥。做本仓的 skill 不等于允许在当前机器安装核心、启动 TUN、改变 DNS/路由或修改现有配置。交付真实 Windows 部署时，先备份原配置并确认具体安装位置和网络变更权限。

## 1. 获取 Windows x64 核心

实际安装前查 [官方 Releases](https://github.com/MetaCubeX/mihomo/releases) 与 [latest API](https://api.github.com/repos/MetaCubeX/mihomo/releases/latest)，以 API 的 `tag_name` 和 `assets[].browser_download_url` 精确选 `mihomo-windows-amd64-compatible-${tag}.zip`；如已知 CPU 能力，可选择对应 amd64 优化版。**不要把某一版本号当作永远的 latest**。官方下载链接会跳转 GitHub 资产分发 CDN；`curl.exe -IL <官方资产 URL>` 可查看当下 CDN 重定向，临时签名地址不可固定，也不将未核验的第三方镜像称为官方 CDN。若官方 release 同时提供校验和，用其验证下载的文件；若没有就如实说明。解压至用户指定目录，不覆盖现有核心、不自动注册服务或开机自启。安装到目标 Windows 并取得授权后，使用压缩包内 exe 的实际名称检查 `-v`；首次运行以 `-d <用户数据目录> -f <配置路径>` 指定目录。

## 2. 接入节点，而非接管供应商配置

1. 询问节点格式：mihomo/Clash **节点列表订阅**、完整 Clash 配置、v2rayN/base64 URI、Surge 格式、单独节点，或本地文件。`proxy-providers.subscription.url` **仅接受 mihomo 能识别的节点订阅**，不能直接填任意格式或完整配置链接。解析完整配置时只抽取用户授权的 `proxies`/节点 provider，审阅后合并到本模板的 `proxy-providers` 或 `proxies`；不要导入其 DNS/TUN/rules 覆盖白名单。需要格式转换时，优先用户本地受信任的转换器，明确说明转换方可能看到订阅凭据；未经授权不把私密链接发给公共在线转换站。静态本地节点无法自动更新，HTTP provider 的 `interval` 才能定期更新。用户格式未知时，保留占位 URL，不假装已接好。
2. 节点名称逐一归属 US/JP/TW/HK/SG；其余少量地区归 `OTHER`。模板以 provider `use` 和 `filter`/`exclude-filter` 做自动测速组，手动策略组 `PROXY`、`STREAM`、`NETFLIX` 可选区域。按用户的真实节点命名修正正则，剔除订阅中的套餐信息/剩余流量/“直连”假节点；核对 **AUTO 和所需地区组非空**，不得依赖空组静默回落为直连。`OTHER` 用 `exclude-filter`，不是 Go 正则不支持的负向前瞻。`url-test` 是延迟选择，不保证服务解锁；不使用尚未证实可用于稳定版的 `type: smart`（见 [Smart PR](https://github.com/MetaCubeX/mihomo/pull/2711)）。
3. 阅读配置中的中文注释：`tun.stack: mixed` + `auto-route` + `dns-hijack`，`dns.enhanced-mode: fake-ip`，`direct-nameserver: system`。未命中域名/国内直连用系统 DNS 以照顾本地 CDN；明确代理的域名在 IP 规则之前匹配，可避免为了目标站的 IP 分流提前做本地 DNS 解析。代理**节点自身**的域名仍可能由本地 DNS 解析。Windows 上 TUN 不一定劫持向局域网 DNS 的查询，浏览器 DoH 等也可能绕开 53 端口，不能承诺绝对无 DNS 泄漏。若需要更严格的 Windows DNS 防漏，评估 `strict-route: true` 与虚拟机/局域网兼容性，取得用户同意后再开。`fake-ip-filter` 排除局域网域名，**不是**路由白名单。

## 3. 基础规则与按需增加

模板的基础代理规则仅含 Google、YouTube、Netflix 及 Sukka 常见流媒体；地区限定流媒体先匹配 US/JP/TW/HK，其他流媒体进 `STREAM` 手选。只使用上游确认存在的 [SukkaW/Surge mihomo Clash 规则](https://github.com/SukkaW/Surge) 和 [blackmatrix7 Clash 服务规则](https://github.com/blackmatrix7/ios_rule_script/tree/master/rule/Clash)；`Clash/non_ip/*.txt` 对应 `classical/text`，`Clash/ip/lan.txt` 和 `stream.txt` 也是 classical（并非纯 ipcidr），`Clash/ip/china_ip.txt` 为纯 CIDR。Sukka 的 Surge `List/*.conf` 不能直接塞进 mihomo provider。规则首次获取失败就说明来源不可达，不改 `MATCH` 去掩盖。远程规则自动更新，需留意许可、规则变化及潜在误伤；这里只引用 URL，不复制上游规则文件。

路由顺序保持：精确应用/域名 → 流媒体/服务域名 → 内网 IP → 流媒体 IP → 中国 IP `DIRECT` → `MATCH,DIRECT`。CN IP 使用 Sukka 的 `china_ip`，不借用可能与分流目的不符的 `geosite:cn`；未归类的国内外域名最终都直连，这是**白名单的有意取舍**，不保证未列入白名单的海外域名可达，也不能保证其不会使用本地 DNS。不要把 Sukka `global`、全量非中国 geosite、广告拦截或 SmartDNS 方案一并塞进起步配置；确有需求时再按证据增补。若后来启用更多规则，始终把非 IP 规则放在会引起解析的 IP 规则前。应用层广告拦截不是域名规则所能替代。

为某个应用/服务添加代理：

1. 确定用户期望的 exe 完整路径、仅指定域名还是该进程全部连接、目标国家，以及是否与其他应用共享域名或 CDN。先查看现成 Clash/mihomo 服务规则，再核对提供者 URL、`format` 和 `behavior`，别凭名字猜。只在用户同意诊断时临时启用回环 controller 和私有强 secret；`GET /connections` 的 `metadata.process`、`processPath`、目标 host/IP、`rule`、`rulePayload`、`chains` 可判断是否经过 TUN 和命中哪里；`GET /rules`、`GET /providers/rules` 帮助确定规则来源。使用 `Authorization: Bearer <secret>`，不泄露令牌/订阅或连接内容，尽量短时观察并脱敏。
2. 精确域名优先：`DOMAIN-SUFFIX,example.com,US` 或已核实的 `RULE-SET,service,US`；确需代理整个 exe 时用 `PROCESS-PATH,C:\\Program Files\\Vendor\\App\\app.exe,US`，在 YAML 中用单引号包住整条规则；`PROCESS-NAME,app.exe,US` 可能误伤同名进程。对于不显露域名的硬编码 IP，确认后再在域名规则**之后**增加 `IP-CIDR`。如果观察中进程字段缺失，先排查捕获或权限，不能宣称进程规则生效。
3. 保留 `MATCH,DIRECT`，记录改动的命中证据和回滚方式；流媒体节点需核查地区实际解锁，不用测速结果代替解锁结果。**写参考配置阶段按用户要求不进行测试**；真正拿到用户授权的 Windows 环境和节点后，才用 `mihomo.exe -t -d <数据目录> -f <配置路径>` 验证配置，再检查 TUN、DNS、规则命中、正常直连和应用播放。遇到误伤先撤回新增规则。

资料：[官方参考配置](https://wiki.metacubex.one/en/example/conf/)、[TUN](https://wiki.metacubex.one/en/config/inbound/tun/)、[DNS/Fake IP](https://wiki.metacubex.one/en/config/dns/)、[节点 provider](https://wiki.metacubex.one/en/config/proxy-providers/)、[路由规则](https://wiki.metacubex.one/en/config/rules/)、[controller API](https://wiki.metacubex.one/en/api/)；Sukka 的 [规则分层说明](https://github.com/SukkaW/Surge) 与用户提供的两篇文章解释域名规则在 IP 规则之前的 DNS 理由。不要原样照搬 Surge/macOS 专有配置到 Windows mihomo。
