# 应用分流

[模板](config.yaml)保留 GitHub、Google、Gemini、Antigravity、ChatGPT、YouTube、Netflix 和流媒体预设，其余直连。Google/Gemini/Antigravity 使用 GOOGLE（默认 JP），ChatGPT 使用 CHATGPT（默认 US）；select 的实际选择可能受缓存影响。地区子组仍为 fallback，不自动跨国家。YouTube 独立，不随 Google 地区调整；不默认代理整个 IDE、终端或浏览器。

AI 本地规则先于通用 Google；共享登录端点也影响其它 Google 服务。ChatGPT 第三方认证、语音 IP/UDP、Antigravity 子进程及 SSH/WSL 远端需按实际连接补充，不能视为完整清单。来源：[OpenAI 网络建议](https://help.openai.com/en/articles/9247338-network-recommendations-for-chatgpt-errors-on-web-and-apps)、[Gemini 社区规则](https://github.com/blackmatrix7/ios_rule_script/tree/master/rule/Clash/Gemini)、[Antigravity 文档](https://antigravity.google/docs/ide/allowlist-denylist/)、[生产端点报告](https://discuss.ai.google.dev/t/bug-remote-servers-ssh-wsl-using-staging-endpoint-daily-cloudcode-pa-instead-of-production-fix-included/139412)。论坛不是官方完整网络清单；不修改应用二进制或改用测试端点。

## 规则范围

新增服务默认采用精确模式：审查过的 DOMAIN / DOMAIN-SUFFIX；进程、关键字、IP、共享 CDN 单独说明范围并获得相应授权。确需全进程时优先 PROCESS-PATH；PROCESS-NAME 可能匹配同名程序。

现有模板标为 **community-wide**，保留远程更新而不默默缩减覆盖。Google 等 classical 列表可能含 DOMAIN-KEYWORD、PROCESS-NAME 和 IP 规则，更新也可能扩大范围。部署前明确接受该广覆盖预设，不能声称仅代理精确服务域名。只接受精确模式时，移除未审查的整包 provider 引用及对应 UDP guard，改用审查过的本地域名/后缀，保留已确认的服务与地区；缺少覆盖证据则报告未验证，不假设域名清单完整。不要仅把 behavior 改为 domain 而沿用 classical 内容。

优先核对 [Sukka](https://github.com/SukkaW/Surge) 和 [blackmatrix7](https://github.com/blackmatrix7/ios_rule_script/tree/master/rule/Clash) 的 URL、格式、更新与共享范围。Sukka Clash/non_ip、ip/lan.txt、ip/stream.txt 用 classical/text；ip/china_ip.txt 用 ipcidr/text，不导入 Surge List/*.conf。社区预设保留 interval；精确模式的更新必须重新审查范围。

## 连接证据与添加规则

确认应用路径、目标地区和域名/全进程边界。经授权临时开启回环 controller 和随机强 secret，读取 GET /connections 的 process、processPath、host/IP、rule、rulePayload、chains，并用 /rules、/providers/rules 定位来源。secret 只发本机，日志脱敏；诊断结束恢复 controller/secret 原状态，不一律关闭用户原本使用的 API。/traffic 总量不能识别应用。[API](https://wiki.metacubex.one/en/api/)。

没有域名证据时先查实际 DNS 路径、TUN 捕获和权限，不盲加域名，也不安装 HTTPS 根证书抓内容。网页能打开不是命中证据。Windows 局域网 DNS、DoH、IPv6 和其它 VPN 必须按 [验证表](validation.md) 分别确认。

顺序：已确认的内网域名例外 → 精确应用/服务域名 → 社区服务预设 → 内网 IP → 流媒体 IP → CN IP → MATCH,DIRECT。fake-ip-filter 不决定路由；模板用显式 localhost、`.lan`、`.local` 例外避免 `google-nas.lan` 被关键字规则误伤，部署前仍须核对本地命名。新增 IP 规则通常置于域名之后，避免过早解析。

每条代理规则紧跟**同作用范围**的 UDP 拒绝兜底，例如：

```yaml
- DOMAIN-SUFFIX,chatgpt.com,CHATGPT
- AND,((NETWORK,udp),(DOMAIN-SUFFIX,chatgpt.com)),REJECT
- RULE-SET,google,GOOGLE
- AND,((NETWORK,udp),(RULE-SET,google)),REJECT
```

核心在目标不支持 UDP 时继续匹配，guard 阻止其跌入直连；不能改成全局 NETWORK,udp,REJECT。进程/IP 条件新增时也须用同范围 guard，并保留原 no-resolve 语义。显式选中 DIRECT 时第一条仍可直连，这是授权选择，不是静默降级。必须用 UDP 的服务需可用 UDP 节点，拒绝不是无损替代。[规则语义](https://wiki.metacubex.one/en/config/rules/)。

记录依据、文件哈希和回滚方式。经本地事务变更后，验收实际命中链、正常直连、内网和服务功能；失败回滚，不以全局代理掩盖问题。
