# 应用分流

[模板](config.yaml)预设 GitHub、Google、YouTube、Netflix 和常见流媒体代理，其余直连。新增规则前遵守 [路径与修改约定](../SKILL.md#路径与修改约定)。

## 观察与选择

确认应用路径、目标地区，以及只代理服务域名还是整个进程。经用户同意后，临时启用回环 controller 和强 secret，通过 `GET /connections` 查看 `metadata.process`、`processPath`、host/IP、`rule`、`rulePayload`、`chains`；用 `/rules`、`/providers/rules` 定位来源。Bearer secret 只发本机，记录脱敏并按约定关闭诊断；`/traffic` 总量不能识别应用。缺少连接或进程字段时先排查 TUN 捕获与权限，不安装 HTTPS 根证书抓内容。[API 文档](https://wiki.metacubex.one/en/api/)。

优先查 [Sukka](https://github.com/SukkaW/Surge) 与 [blackmatrix7 Clash 规则](https://github.com/blackmatrix7/ios_rule_script/tree/master/rule/Clash)，核对 URL、格式、维护情况和共享 CDN 范围。Sukka 的 `Clash/non_ip/*.txt`、`Clash/ip/lan.txt`、`stream.txt` 用 classical/text；`Clash/ip/china_ip.txt` 用 ipcidr/text。不要导入 Surge `List/*.conf`，远程 provider 保留更新间隔。

## 添加与确认

- 优先精确域名或 `RULE-SET,service,US`；确需整个进程代理时，用 `'PROCESS-PATH,C:\Program Files\Vendor\App\app.exe,US'`。`PROCESS-NAME,app.exe,US` 可能匹配同名程序，代理整个浏览器或共享 CDN 可能影响其他服务。
- 必要的 IP 规则置于非 IP 规则之后，避免过早解析目标域名。保持顺序：精确应用/域名 → GitHub → 服务域名 → 内网 IP → 流媒体 IP → CN IP 直连 → `MATCH,DIRECT`。
- 记录依据和回滚方式。在获准的真实环境检查语法、命中链、正常直连及实际服务解锁；误伤就撤回新增规则。

地区组的默认 fallback 和节点检查见 [安装](install.md#安装与节点)。参考：[路由规则](https://wiki.metacubex.one/en/config/rules/)、[策略组](https://wiki.metacubex.one/en/config/proxy-groups/)。
