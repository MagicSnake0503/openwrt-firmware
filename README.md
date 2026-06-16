# ImmortalWrt x86_64 软路由固件构建项目

为 x86_64 软路由定制编译 ImmortalWrt 固件。**本地 WSL 编译和 GitHub 云编译共用同一套配置**，改一处两边生效。

基于 **ImmortalWrt openwrt-24.10 稳定版**，预置了科学上网（11 种代理工具）、去广告、DNS 优化、远程访问、流量管理、监控通知、NAS 等常用功能。所有功能均为原生 LuCI 插件，不使用 Docker。

## 🖥 目标硬件（已针对本机优化）

| 项目 | 规格 |
|---|---|
| CPU | Intel Pentium Silver **N6005**（4C/4T，Jasper Lake，支持 AES-NI） |
| 内存 | 32 GB |
| 存储 | NVMe 250 GB |
| 网卡 | 4 × Intel **I226-V** 2.5GbE（PCI `8086:125c`，`igc` 驱动） |
| 启动 | UEFI（`*-combined-efi.img.gz`） |
| WAN | PPPoE 拨号（光猫桥接） |

配置已针对此硬件：根分区 **8GB**、内置 `kmod-igc` + NVMe 驱动、AES-NI 硬件加密、PPPoE/IPv6 支持、去除无用无线驱动减重。**所有功能均原生编译进固件（在 LuCI「服务」菜单里直接用），不使用 Docker**。换机时编辑 `config/x86-64.config` 即可。

---

## ✨ 功能特性

| 类别 | 包含插件 |
|---|---|
| 🌐 科学上网 | PassWall、PassWall2、SSR-Plus、OpenClash、HomeProxy、Nikki（Mihomo）、FullCombo Shark!、luci-app-xray、NeKoBox、Daed、v2rayA（含 sing-box / xray / v2ray / mihomo 内核） |
| 🚫 去广告 | AdBlock、AdGuard Home（DNS 层） |
| 🧭 DNS 优化 | mosdns（分流防污染）、SmartDNS（测速加速）、https-dns-proxy（加密DNS）、网易云解锁 |
| 🌍 远程访问 | Tailscale、ZeroTier、WireGuard、frp 内网穿透（frpc+frps） |
| 📊 流量管理 | mwan3 多 WAN 负载、nlbwmon 流量统计、SQM 智能限速、上网时间控制 |
| 🔔 监控通知 | Netdata 实时监控、collectd 历史统计、微信/TG 推送（serverchan + wechatpush）、网络唤醒 |
| 💾 NAS 存储 | Samba4、NFS、NTFS/exFAT/ext4 支持、磁盘管理、自动挂载 |
| 🎨 主题界面 | argon 主题、全中文 LuCI |
| ⚙️ 系统工具 | TurboACC 硬件 NAT 加速、AES-NI 硬件加密、ttyd 终端等 |
| 🔧 网络基础 | 防火墙、UPnP、DDNS、BBR、PPPoE/IPv6 拨号、NTP（阿里云/腾讯云） |

> 🚫 **不含 Docker**：所有应用均为原生 LuCI 插件，开机即用、无需拉镜像，资源占用低、升级直接重刷固件。

固件根分区 **8GB**（给代理内核、日志、配置留空间），EFI 引导，同时输出 squashfs（可恢复出厂）和 ext4（可扩容）两种格式。

---

## 📁 目录结构

```
openwrt-firmware/
├── .github/workflows/
│   └── build.yml                  # GitHub Actions 云编译工作流
├── config/
│   └── x86-64.config              # .config 种子文件（云端+本地共用）
├── scripts/
│   ├── feeds.conf.custom          # 自定义 feeds（OpenClash 等外部源）
│   ├── diy-part1.sh               # 个性化：默认 IP/主机名/时区/主题
│   ├── diy-part2.sh               # 个性化：向 .config 追加额外包
│   └── apply-config.sh            # 本地一键应用配置并编译
├── local-build-guide.md           # WSL 本地编译完整教程
├── cloud-build-guide.md           # GitHub 云编译使用说明
└── README.md                      # 本文件
```

---

## 🚀 快速开始（选一种）

### 方式一：GitHub 云编译（无需本地环境，推荐新手）

👉 详细步骤见 **[cloud-build-guide.md](./cloud-build-guide.md)**

简述：把本项目 push 到你的 GitHub 仓库 → Actions 页面点 `Run workflow` → 等 1.5~2 小时 → 下载固件 artifact。

### 方式二：本地 WSL 编译（可控性强）

👉 详细步骤见 **[local-build-guide.md](./local-build-guide.md)**

简述：WSL 装 Ubuntu → 装依赖 → 克隆源码 → 跑 `apply-config.sh` → 编译 → 拿到固件。

---

## 🔧 如何定制

| 想改的东西 | 改哪里 |
|---|---|
| 增删插件 | `config/x86-64.config`，`CONFIG_PACKAGE_xxx=y` 启用，`# ... is not set` 禁用 |
| 默认 LAN IP | `scripts/diy-part1.sh` 里的 `LAN_IP` 变量（默认 192.168.5.1） |
| 主机名 / 时区 / NTP | `scripts/diy-part1.sh` |
| 根分区大小 | `config/x86-64.config` 里 `CONFIG_TARGET_ROOTFS_PARTSIZE`（默认 2048 MB） |
| 添加外部插件源 | `scripts/feeds.conf.custom` |
| 默认密码 | `scripts/diy-part1.sh` 末尾注释段，用 `openssl passwd -6` 生成哈希 |

改完 push 到 GitHub 即自动触发云编译；本地则重跑 `apply-config.sh`。

---

## 📦 固件产物说明

编译成功后 `bin/targets/x86/64/` 下会生成：

| 文件 | 用途 | 推荐场景 |
|---|---|---|
| `*-squashfs-combined-efi.img.gz` | UEFI + squashfs，可恢复出厂 | **物理机/虚拟机首选** |
| `*-ext4-combined-efi.img.gz` | UEFI + ext4，可在线扩容 | 需要扩容根分区时 |
| `*-combined-efi.vmdk` | VMware/ESXi 镜像 | 虚拟机直接导入 |
| `*manifest` | 已编译包清单 | 排查包是否包含 |

刷写方法见 [local-build-guide.md 第七章](./local-build-guide.md#七刷写固件)。

---

## 🔑 首次登录

- 地址：`http://192.168.5.1`（diy-part1 改过的默认 IP）
- 用户名：`root`
- 密码：空（进入 LuCI 后立即设置）

---

## ⚠️ 合规说明

本固件包含的代理类插件（PassWall / OpenClash / SSR+ / HomeProxy 等）仅供**网络技术研究、开发测试、合规的企业跨境访问**等合法用途。在你所在地区使用此类工具的合规性请自行评估并遵守当地法律法规。本项目仅提供技术方案，不承担因使用产生的任何责任。

---

## 📚 参考资源

- ImmortalWrt 官方源码：https://github.com/immortalwrt/immortalwrt
- OpenClash：https://github.com/vernesong/OpenClash
- 官方构建脚本：https://build-scripts.immortalwrt.org/
- 编译文档：https://immortalwrt.org/docs/start

---

## ❓ 常见问题

编译失败、刷写问题、增删插件等，先看对应编译指南的「常见问题」章节：
- 云编译：[cloud-build-guide.md 第八章](./cloud-build-guide.md#七常见问题)
- 本地编译：[local-build-guide.md 第八章](./local-build-guide.md#八常见问题)
