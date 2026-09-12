# xcc

Xray / **sing-box** / **Nginx** 多协议节点管理工具（**单机单用户**）。TUI 参考 [v2ray-agent](https://github.com/mack-a/v2ray-agent) 的菜单流，能力参考 [3x-ui](https://github.com/MHSanaei/3x-ui) 的入站 / 流量 / 订阅 / 分流，全部收敛在一个 Bash 脚本里。

目标系统：**Ubuntu 24.04+**（主要）、Debian 12+、CentOS 9+。依赖 systemd。当前版本 **2.3.0**。

## 功能介绍

- 状态面板：CPU / 内存 / 磁盘 / 负载 / 公网 IP / Xray、sing-box、Nginx 状态 / Xray Stats 流量
- 一键无域名 Reality：与 [v2ray-agent](https://github.com/mack-a/v2ray-agent) 相同的双层入站（公网 `dokodemo-door` → `127.0.0.1:45987` Vision）、`sid=6ba85179e30d4fc2` / `fp=chrome` / `flow=xtls-rprx-vision` / mozilla 伪装
- 协议覆盖对齐 [3X-UI](https://github.com/MHSanaei/3x-ui) 入站类型（仍为**单用户**，无面板 / 多用户计费）：
  - VLESS / VMess / Trojan：TCP、WebSocket、gRPC、HTTPUpgrade、XHTTP、mKCP；安全层 TLS / REALITY / none；VLESS 可开 Vision
  - Shadowsocks：2022（128/256/chacha）以及 aes-gcm / chacha20-ietf-poly1305
  - Hysteria2（sing-box）、WireGuard 入站、HTTP 入站、SOCKS5 入站、Tunnel（dokodemo-door）
  - TUN：Xray 本机虚拟网卡入站（对齐 3X-UI / [Xray TUN](https://xtls.github.io/config/inbounds/tun.html)）；Clash 订阅可选客户端 TUN
  - 快捷项：一键 Reality、VLESS-WS-TLS、VMess-WS-TLS、Trojan-TLS（与 v2ray-agent 分享链接兼容）
  - 不做：多用户额度、Telegram 机器人、AmneziaWG / MTProto（非 Xray 标准入站或需独立栈）
- Nginx：TLS 反代 WebSocket、ACME webroot、站点伪装（`www.python.org`）、HTTPS 订阅
- ACME（Let's Encrypt / acme.sh）或自签名证书
- 通用订阅（base64）+ Clash Meta YAML 订阅 + 分享链接 / 二维码
- 出站条目与 v2ray-agent 对齐：`proxy` / `direct` / `z_direct_outbound` / `IPv4_out` / `IPv6_out` / `blackhole_out`，可选 `socks5_outbound`、WARP
- 分流：BT 阻断、广告拦截、国内直连、域名黑名单、IPv6 出站域名
- BBR 加速、SSH 端口、备份恢复、核心更新
- systemd 看门狗：端口/API 健康、坏配置重建、出站故障切直连、NTP、证书续签、每周更新核心与 geo 数据；**改配置时自动暂停**

## 安装命令

国内机器经常无法解析 `raw.githubusercontent.com`（`curl: (6) Could not resolve host`）。**终端不会自动走 Windows / 浏览器代理**，请优先用 jsDelivr：

```bash
bash <(curl -fsSL https://cdn.jsdelivr.net/gh/wang-xinchen007/xcc@main/install.sh)
```

若当前终端已经配置代理，且要把 DNS 也交给代理，使用 `socks5h`（注意多一个 `h`）：

```bash
export ALL_PROXY=socks5h://127.0.0.1:10808
bash <(curl -fsSL https://raw.githubusercontent.com/wang-xinchen007/xcc/main/install.sh)
```

GitHub 官方 raw（需本机 DNS 能解析该域名）：

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/wang-xinchen007/xcc/main/install.sh)
```

手动安装：

```bash
curl -fL -o /usr/local/bin/xcc https://cdn.jsdelivr.net/gh/wang-xinchen007/xcc@main/xcc
chmod 755 /usr/local/bin/xcc
sudo xcc run
```

安装脚本会：检测系统 → 下载 `xcc` 到 `/usr/local/bin/xcc` → 创建 `/etc/xcc/` → 自动运行 `xcc run` 进入首次配置向导。

## 使用方法

```text
xcc              显示帮助（Usage）
xcc run          启动中文 TUI
xcc status       状态面板
xcc update       从 GitHub 更新主脚本（保留 /etc/xcc/ 配置）
xcc uninstall    卸载（需输入 yes 确认）
xcc version      显示版本
xcc selftest     离线自检（Reality / TUN / 出站 / 路由 / 分享链接）
```

`xcc run` 启动时会检查 GitHub 最新版本；若有新版本会提示执行 `xcc update`。

更新前若检测到 TUI（`xcc run`）仍在运行，会提示：**请先退出 xcc 再更新**。

## 使用截图（TUI 示意）

```text
┌────────────── xcc 2.3.0  |  仅支持单用户配置 ──────────────┐
│ xcc 主菜单                                                 │
│                                                            │
│     d  状态面板 / 流量                                     │
│     q  一键 Reality（无域名）                              │
│     1  配置 Reality 节点                                   │
│     2  配置 Hysteria2 节点                                 │
│     v  配置 VLESS-WS-TLS                                   │
│     m  配置 VMess-WS-TLS                                   │
│     t  配置 Trojan-TLS                                     │
│     s  配置 Shadowsocks                                    │
│     p  更多协议（gRPC/XHTTP/WG/HTTP/SOCKS/Tunnel/TUN）      │
│     3  管理节点                                            │
│     u  订阅 / 分享链接                                     │
│     5  出站 / WARP / 分流                                  │
│     c  证书（ACME）                                        │
│     b  启用 BBR 加速                                       │
│     k  更新核心（Xray/sing-box/Nginx/xcc）                 │
│     r  重置看门狗保护                                      │
│     0  退出                                                │
│                    <确定>          <取消>                  │
└────────────────────────────────────────────────────────────┘
```

配置修改时会出现：

- 黄色：`⏸ 看门狗已暂停，配置修改期间不会自动重启 Xray / sing-box / Nginx`
- 绿色：`▶ 看门狗已恢复运行`

Reality 节点创建成功后，终端会打印 VLESS 分享链接，并用 `qrencode -t ansiutf8` 显示二维码。

## 路径与配置

| 用途 | 路径 |
|------|------|
| 主脚本 | `/usr/local/bin/xcc` |
| xcc 配置 | `/etc/xcc/` |
| 节点元数据 | `/etc/xcc/nodes.json` |
| 出站代理 | `/etc/xcc/outbound.conf`（`SOCKS5://user:pass@ip:port` 或 `DIRECT`） |
| 配置格式版本 | `/etc/xcc/version` |
| Xray 配置 | `/usr/local/etc/xray/config.json` |
| sing-box（Hysteria2） | `/usr/local/bin/sing-box`，配置 `/etc/xcc/sing-box/conf/config.json` |
| Nginx 站点 | `/etc/nginx/conf.d/xcc.conf`，webroot `/etc/xcc/www` |
| 订阅文件 | `/etc/xcc/subscribe/`（有域名证书时：`https://域名:443/s/TOKEN`） |
| 日志 | `/var/log/xcc.log` |
| 备份 | `/root/xcc-backup-日期.tar.gz` |
| 临时文件 | `/var/tmp/xcc-*`、`~/.cache/xcc/` |

敏感文件权限为 `600`。

## Nginx 与 sing-box（对齐 v2ray-agent）

- **Hysteria2** 不再使用官方 `apernet/hysteria` 二进制，改为 [SagerNet/sing-box](https://github.com/SagerNet/sing-box)。systemd 单元：`sing-box.service`（`sing-box run -c /etc/xcc/sing-box/conf/config.json`）。
- inbound：`type=hysteria2`，`listen=::`，`up_mbps=100` / `down_mbps=50`，`alpn=h3`；可选 `obfs.salamander`。有 SOCKS5 出站时 hy2 入站走 `socks5_outbound`。
- 旧版 `hysteria@端口` 会在应用配置时停止并删除。
- **Nginx** 监听 80 做 ACME webroot；有域名证书后在 `nginx_port`（默认 443）上 `listen N ssl http2`（Ubuntu 24.04 的 nginx 1.24 写法）。
- VLESS-WS / VMess 由 Nginx 反代到本机 `127.0.0.1:31297` / `31299`，Xray 对应 inbound 为 `security=none`。
- 根路径伪装反代 `https://www.python.org`；订阅：`https://域名:443/s/TOKEN` 与 `https://域名:443/s/TOKEN.clash.yaml`。无证书时订阅走 HTTP `sub_port`（默认 2096）。
- Hysteria2 默认 UDP 443，可与 Nginx TCP 443 并存。Reality 不要再占用同一 TCP 443。
- 主菜单 **p 更多协议**：按 3X-UI 的入站矩阵选协议 + 传输层 + 安全层。gRPC / XHTTP / TCP+TLS 由 Xray 本机监听；WS / HTTPUpgrade 有证书时仍走 Nginx。WireGuard / HTTP / SOCKS / Tunnel 为独立端口；TUN 为本机虚拟网卡（无监听端口）。

## TUN（对齐 3X-UI / Xray）

TUN **不是远程端口**，客户端不能 `connect` 过来。Xray 在本机创建虚拟网卡，发往该网卡的流量按现有分流 / 出站走。

默认：

- 接口名 `xcc0`，网关 `172.19.0.1/30`，MTU `1500`，DNS `1.1.1.1` / `8.8.8.8`
- **不写**系统默认路由（只建接口）。其它机器把网关指到本 VPS，或本机用 `ip rule` 把指定流量导入 `xcc0`
- 可选「本机 IPv4 / IPv4+IPv6 全局透明代理」：写入 `autoSystemRoutingTable`（`0.0.0.0/0`、`::/0`）
- 始终设置 `autoOutboundsInterface=auto`，避免 Xray 自己的出站再进 TUN 回环
- 私网地址默认走 `direct`（`10/8`、`172.16/12`、`192.168/16` 等；开 IPv6 时另含 `fc00::/7`）
- 需要 `/dev/net/tun` 与 `CAP_NET_ADMIN`（写入 `xray.service.d/10-xcc-tun.conf`），并打开 IP forwarding（`/etc/sysctl.d/99-xcc-tun.conf`）

Clash 订阅里的 TUN 是**客户端**全局代理，和服务器 TUN 入站无关。在「订阅 / 分享」里单独开关。

**不要**在未确认出站可用时打开本机全局路由，SSH 可能断连。

## Reality 约定

与 v2ray-agent 的 `07_VLESS_vision_reality_inbounds.json` 对齐：

- 必须安装支持 XTLS/Reality 的最新 Xray
- **双层入站**：公网端口 `dokodemo-door`（`destOverride: tls` + `routeOnly`）转发到 `127.0.0.1:45987`；内层 VLESS Reality Vision（`fallbacks: []`）
- dokodemo 入站固定走 `z_direct_outbound`（即使全局 SOCKS5 也不绕路）
- 服务端 `realitySettings.target`（`dest` 别名）、`minClientVer=1.8.2`、`maxTimeDiff=70000`
- `shortIds`: `["", "6ba85179e30d4fc2"]`（可另含本节点 shortId）
- `flow=xtls-rprx-vision`，`fingerprint=chrome`
- 目标域名支持 X25519MLKEM768 且证书链 > 3500 时自动生成 ML-DSA-65（与 v2ray-agent 相同）
- sniffing 开启 `routeOnly`（避免 Reality 被 sniff 改写目标）
- 日志：`"log": {"loglevel": "warning"}`
- 分享链接格式（参数顺序与 v2ray-agent 相同）：

```text
vless://uuid@ip:port?encryption=none&security=reality&type=tcp&sni=伪装域名&fp=chrome&pbk=公钥&sid=6ba85179e30d4fc2&flow=xtls-rprx-vision#备注
```

VLESS-WS / Trojan / Hysteria2 分享链接同样与 v2ray-agent 字段一致，例如：

```text
vless://uuid@ip:port?encryption=none&security=tls&type=ws&host=域名&sni=域名&fp=chrome&path=/path#备注
trojan://密码@域名:port?peer=域名&fp=chrome&sni=域名&alpn=http/1.1#备注_Trojan
hysteria2://密码@host:port?peer=host&insecure=0&sni=host&alpn=h3#备注
```

## 看门狗

服务名：`xcc-watchdog`（`Restart=always`，开机自启）。每分钟一轮。

**进程与配置**

- 不只看 `is-active`：校验 `nodes.json` / Xray JSON / `nginx -t` / sing-box check
- 配置坏了先从 `nodes.json` 重建，避免坏配置重启死循环
- 核对应监听的 TCP/UDP 端口；已启用的 TUN 接口（`ip link`）；Xray 再探 `127.0.0.1:10085` Stats API（超时视为卡死）
- 连续 2 分钟不健康才重启；Xray / sing-box / Nginx **各自** 5 分钟内重启超过 3 次则熔断，等主菜单重置
- TUI 开着时不自动重启、不自动改配置

**出站**

- SOCKS5 连续失败 3 次：备份原出站，切 `DIRECT` 并重载 Xray / sing-box
- 原 SOCKS5 连续恢复 2 次：自动切回

**系统健康（每分钟）**

- NTP：`timedatectl set-ntp true`，仍不同步则 `chronyc makestep` / `ntpdate`（避免 Reality 因时钟漂移失败）
- 磁盘 > 85%：清理 xcc 旧日志、临时文件、journal（200M）
- 负载 > CPU×2：WARN
- 日志轮转：写入前 > 50MB 切开；每分钟删除 7 天前的 `xcc.log.*` 和过期临时文件
- 证书剩余 ≤ 21 天：acme.sh 续签并 reload

**每周自动更新**（首次启动只打时间戳，满 7 天才跑；TUI 占用则推迟）

- Let's Encrypt 续签、`geoip.dat` / `geosite.dat`
- Xray、sing-box（已安装或有 Hysteria2 时）、xcc 脚本（有新版本则覆盖并重启看门狗）

配置 Reality / 节点 / 出站等时会停看门狗；完成后自动恢复。**备份不停止看门狗。**

systemd 服务 `StandardOutput=null`。logrotate：每天 / 3 份 / `size 50M`。

## Ubuntu 24.04+ 适配

1. **systemd-resolved**：若运行，Xray DNS 使用 `https://1.1.1.1/dns-query` 与 `tcp://1.1.1.1:53`，避开 `127.0.0.53`
2. **ufw**：改 SSH 端口时先 `ufw allow 新端口/tcp`，改完 `ufw reload`；inactive 则跳过
3. **防火墙顺序**：nftables → ufw → firewalld → iptables
4. **AppArmor**：安装后扫描 syslog，若有拒绝记录则 `aa-complain /usr/local/bin/xray`
5. **unattended-upgrades**：启用时提示排除 Xray
6. **cloud-init**：存在 `/etc/cloud/cloud.cfg` 时提示禁用网络管理
7. **NTP**：未同步则 `timedatectl set-ntp true`
8. **临时目录**：不使用可能 `noexec` 的 `/tmp`
9. **旧版 Xray**：存在 `/etc/xray/` 时提示 `apt purge xray -y`
10. **NetworkManager**：运行时提示纯服务器环境建议禁用

所有 `apt` 命令前设置 `export DEBIAN_FRONTEND=noninteractive`。

## 常见问题

**Q: `curl: (6) Could not resolve host: raw.githubusercontent.com`？**  
A: 这是 DNS 解析失败，不是脚本坏了。常见原因：
1. 你在 **VPS / Linux 终端**里执行，Windows 上的 Clash / v2rayN **不会**自动给这台机器用。
2. 本机终端没走代理；GUI 系统代理通常只管浏览器。
3. 即使用了 SOCKS，也应写 `socks5h://`（远程 DNS）。`socks5://` 仍在本地解析域名，照样报 6。
解决：改用上面的 jsDelivr 安装命令，或在终端 `export ALL_PROXY=socks5h://127.0.0.1:端口`。

**Q: 提示「请先退出 xcc 再更新」？**  
A: 先在 TUI 选「退出」，再执行 `xcc update`。看门狗会在更新时短暂停止。

**Q: Reality 连不上？**  
A: 确认系统时间已 NTP 同步；`target`/`dest` 应对应一个支持 TLS 1.3 的站点（默认 `download-installer.cdn.mozilla.net:443`，与 v2ray-agent 列表一致；Xray 26 会警告 microsoft/apple 等目标）；客户端 SNI、公钥、`sid=6ba85179e30d4fc2` 需一致。sniffing 必须 `routeOnly`。

**Q: 配置修改后 Xray 被看门狗重启？**  
A: 请走 TUI 菜单修改。脚本会暂停看门狗，语法检查通过后再恢复。

**Q: 包管理器里的 xray 能不能用？**  
A: 官方脚本失败时才会降级用 apt/yum。仓库版本往往过旧，不支持最新 Reality，不推荐。

**Q: TUN 连不上 / 没有接口？**  
A: 先确认 `/dev/net/tun` 存在（部分 OpenVZ / LXC 要在宿主机打开）。`xcc status` 里 TUN 节点应为启用；`ip link show xcc0` 应能看到接口。本机全局路由会劫持默认网关，出站请先设好 SOCKS5 / WARP / 直连。

**Q: 是否支持多用户？**  
A: 不支持。xcc **仅支持单用户配置**。

**Q: 卸载会删除 Xray 吗？**  
A: 默认询问「是否同时卸载 Xray、sing-box，并移除 Nginx 站点配置？」。卸载 xcc 前必须输入 `yes`。不会 `apt purge nginx`。

**Q: TUI 打不开？**  
A: 检测顺序为 whiptail → dialog；都没有会尝试安装 whiptail；仍失败则降级为 `read -p` 命令行。

## 许可证

MIT
