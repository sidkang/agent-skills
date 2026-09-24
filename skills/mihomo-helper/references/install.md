# 首次安装与启动（Windows x64）

## 下载前确认

从 [官方稳定版 Release API](https://api.github.com/repos/MetaCubeX/mihomo/releases/latest) 取得 `tag_name` 和 `assets[].browser_download_url`，核对 `mihomo-windows-amd64-compatible-${tag}.zip` 确实存在；了解 CPU 能力后也可考虑其它 amd64 构建。`${tag}` 必须使用当次 API 结果，不把示例版本当作永久 latest。官方下载和两个第三方加速地址：

```text
官方：https://github.com/MetaCubeX/mihomo/releases/download/${tag}/mihomo-windows-amd64-compatible-${tag}.zip
加速 1：https://ghproxy.net/https://github.com/MetaCubeX/mihomo/releases/download/${tag}/mihomo-windows-amd64-compatible-${tag}.zip
加速 2：https://gh-proxy.org/https://github.com/MetaCubeX/mihomo/releases/download/${tag}/mihomo-windows-amd64-compatible-${tag}.zip
```

如需一个具体示例，[v1.19.31 的加速 1 地址](https://ghproxy.net/https://github.com/MetaCubeX/mihomo/releases/download/v1.19.31/mihomo-windows-amd64-compatible-v1.19.31.zip)；仅作格式示例。**先在用户实际使用的网络探测连通性**：对选中的下载 URL 做限时 HEAD/重定向检查，确认解析、TLS、HTTP 响应及最终主机；部分服务器不支持 HEAD，可用受限的小范围 GET 辅助判断。可访问性和速度不等于内容可信；优先官方地址，只有官方不可达且用户接受风险时才尝试加速地址。GitHub 官方 URL 本身会跳转到 GitHub 资产 CDN，签名跳转 URL 会过期，不能保存成固定下载链接。`ghproxy.net` 和 `gh-proxy.org` **不是官方 CDN，也不保证在中国大陆某一网络可访问**；不把订阅链接或凭据交给它们。jsDelivr 普通 `/gh/` 仅提供仓库文件，不是本项目 Release ZIP 附件的通用镜像。

下载后如官方发布校验和则对照官方 SHA256；若没有，明确说明不能仅凭镜像返回 200 证明二进制可信。不要下载后立即执行未知内容。[官方 Windows 构建列表](https://wiki.metacubex.one/en/startup/)；[GitHub Release 链接说明](https://docs.github.com/en/repositories/releasing-projects-on-github/linking-to-releases)。

## 程序、配置和节点

将确认来源的 exe 安装为 `C:\Program Files\Mihomo\mihomo.exe`（必要时从解压后的实际文件名改名），不要从下载目录或普通用户可写目录以高权限运行。默认配置用**当前用户**的 `%USERPROFILE%\config\mihomo\config.yml`，对应 `~/config/mihomo/config.yml`；如同目录已使用 `config.yaml`，保持该文件名，用户另指定路径则遵从。把 [config.yaml](config.yaml) 作为参考模板复制到实际配置位置，不覆盖已有文件；先备份原配置。mihomo 的 `-d` 指向实际配置所在目录，`-f` 指向实际 `.yml` 或 `.yaml` 文件；provider/规则缓存也在该数据目录下。请勿将真实订阅凭据放进公开仓库。

确认用户提供的是节点列表订阅、完整 Clash 配置、URI/base64/Surge 格式，还是本地节点。`proxy-providers.subscription.url` 只可填写 mihomo 可读取的**节点**订阅；完整配置不可直接当节点 provider。按授权抽取节点，不导入供应商的 DNS/TUN/全局规则覆盖本模板。格式转换优先本地受信任工具，未经同意不要将私密订阅提交在线转换服务；静态节点不能自动更新，HTTP provider 的 `interval` 才支持定期更新。核对 US/JP/TW/HK/SG/OTHER 的节点名称和筛选正则，确保 AUTO 与必需地区组非空；不要依赖空组静默回落直连。US/JP/TW/HK/SG/OTHER 地区组默认用 `fallback`，按节点顺序取首个可用节点，失效时切换；检查订阅节点顺序，用户明确要求延迟优先时才改组类型。`AUTO` 保留 `url-test` 供手选，但测速不保证流媒体解锁；稳定版不假定支持尚未确认的 `type: smart`（[相关 PR](https://github.com/MetaCubeX/mihomo/pull/2711)）。

## 登录后自动启动

用户要求开机后自动运行。在**完成节点接入、配置检查并取得用户对系统路由变更的授权之后**，为该 Windows 用户设置「登录时触发」的任务计划程序任务，以该用户的提升权限运行 Program Files 中的 mihomo；操作指定其配置目录的**绝对路径**作为 `-d`、真实配置文件绝对路径作为 `-f`，设置合适的工作目录，并配置异常退出后的有限次数重试。任务不能把 `~` 原样传给核心。部署时核对该账户有创建 TUN/改路由的权限、Windows 防火墙允许程序、且不存在并行运行的其他 VPN/TUN 或旧 mihomo 任务。只给当前用户对配置及订阅缓存的访问权，不允许其他低权限账户改写配置，避免以管理员身份运行时加载不可信文件；二进制目录只由管理员修改，订阅密钥不写入任务命令行。

“登录后自动启动”不等于“登录前即有网络接管”：若用户必须在无人登录时也运行，**先明确另行设计**受保护的数据目录和服务账户；不能用 SYSTEM 的 `~` 冒充当前用户目录，也不能把普通用户可改写的配置以 SYSTEM 权限直接加载。mihomo 的[官方服务示例](https://wiki.metacubex.one/en/startup/service/)仅覆盖 Linux systemd，不能将控制台 exe 直接用 Windows `sc create` 注册并假定其实现服务协议。

实际启动后检查进程、任务状态、TUN/DNS、局域网直连、普通网站、GitHub 和预设流媒体规则。网络尚未就绪时检查缓存和稍后的 provider 更新；不改成全局代理来掩盖问题。不覆盖未知同名任务，卸载只移除本次创建的任务和经用户确认的程序，保留用户配置/缓存以便恢复。
