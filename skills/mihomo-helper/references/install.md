# 安装与登录自启

## 下载

从 [官方 latest API](https://api.github.com/repos/MetaCubeX/mihomo/releases/latest) 取得 `tag_name` 和资产 URL，优先选实际存在的 `mihomo-windows-amd64-compatible-${tag}.zip`；已知 CPU 能力时可选其它 amd64 构建。`${tag}` 使用当次结果。

```text
官方：https://github.com/MetaCubeX/mihomo/releases/download/${tag}/mihomo-windows-amd64-compatible-${tag}.zip
加速 1：https://ghproxy.net/https://github.com/MetaCubeX/mihomo/releases/download/${tag}/mihomo-windows-amd64-compatible-${tag}.zip
加速 2：https://gh-proxy.org/https://github.com/MetaCubeX/mihomo/releases/download/${tag}/mihomo-windows-amd64-compatible-${tag}.zip
```

先在用户网络做限时 HEAD/重定向检查；不支持 HEAD 时用受限 GET。官方优先，官方不可达且用户接受风险时才用第三方加速；它们不保证国内可达，不接收私密订阅或凭据。GitHub 签名跳转地址会过期；jsDelivr `/gh/` 只提供仓库文件，不能直接镜像这些 Release ZIP。下载后对照官方 SHA256（若发布）；HTTP 200 不是完整性证明。参见 [Windows 构建列表](https://wiki.metacubex.one/en/startup/)。

## 安装与节点

按 [路径与修改约定](../SKILL.md#路径与修改约定) 安装程序和配置。检查已有 `.yml`、`.yaml` 与核心位置，不覆盖未获授权的配置；首次部署填写模板注释头中的真实路径及初始记录。程序目录只允许管理员修改，配置和缓存不允许其他低权限账户写入，避免提升权限后加载不可信文件。

识别输入是节点订阅、完整配置、URI/base64/Surge 格式还是本地节点。只接入节点，不让供应商配置覆盖本模板的 DNS、TUN 和规则。需转换时优先本地受信任工具；未经同意不把订阅发送给在线转换站。HTTP provider 按 `interval` 更新，静态节点不会自动更新。

地区组 US/JP/TW/HK/SG/OTHER 默认 `fallback`，按节点顺序故障切换；用户明确要求时才改变。检查名称筛选、优先级及空组，不能依赖空组静默直连。`AUTO` 保留 `url-test`；探测延迟不等于流媒体解锁。不要启用未经稳定版确认的 `smart`。[Provider 文档](https://wiki.metacubex.one/en/config/proxy-providers/)。

## 登录自启

接入节点并验证配置后，在授权范围内创建用户登录时触发的计划任务，以该用户提升权限运行核心，设置绝对路径、工作目录和有限失败重试。核对 TUN 权限、防火墙及旧任务/VPN 冲突；不要把订阅密钥放进任务命令行。

登录自启不是登录前启动。若要求无人登录时运行，先另行确定受保护的数据目录与服务账户，不能让 SYSTEM 直接加载普通用户可改写的配置。普通控制台 exe 也不能直接通过 `sc create` 假定为 Windows 服务；[官方服务示例](https://wiki.metacubex.one/en/startup/service/)仅涵盖 systemd。

启动后按 [维护](maintenance.md) 检查网络；开机网络未就绪时检查缓存及后续更新。卸载只移除本次创建的任务和用户确认的程序，保留配置，不覆盖未知同名任务。
