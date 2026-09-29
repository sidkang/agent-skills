# Changelog

## 0.0.4 — 2026-09-24

- 七个 provider 组显式 empty-fallback: REJECT；所有代理规则增加同范围 UDP 拒绝兜底，保留默认直连、Google JP、ChatGPT US 和地区 fallback。
- 内网域名例外先于社区服务规则；明确区分精确服务规则与保留的 community-wide 预设，不静默缩减原覆盖。
- 分离离线静态、核心语义、真实网络验收；DNS/实际命中链成为部署成功条件，诊断恢复 controller 原状态。
- 新增带受保护快照、哈希冲突检查、单实例验证和独立 watchdog 的 Windows 本地事务入口；显式验收后提交，否则回滚。
- 补充外部内容信任边界、二进制来源验证、维护授权，以及静态/核心/Windows 故障注入测试。
