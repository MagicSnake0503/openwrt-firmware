#!/usr/bin/env bash
# =============================================================================
# diy-part2.sh — 个性化定制脚本（第二段）
# 作用：在 .config 已就位、make defconfig 之前运行，向 .config 追加/修改配置项。
#   常见用途：追加额外软件包、调整分区大小、覆盖某个 CONFIG 项。
# 调用方式：./diy-part2.sh <项目根目录> <immortalwrt 源码目录>
# =============================================================================

set -euo pipefail

PROJECT_ROOT="${1:-.}"
SRC_DIR="${2:-immortalwrt}"

cd "$SRC_DIR"

echo "==== [diy-part2] 开始追加 .config 项 ===="

# ---------------------------------------------------------------------------
# 1. 在 .config 末尾追加额外软件包（不修改主配置文件，按需开启）
#    使用追加方式：重复行 defconfig 时会去重，安全。
# ---------------------------------------------------------------------------
cat >> .config <<'EOF'

# ====== diy-part2 追加的包（可按需增删）======
# 自动挂载 USB 存储
CONFIG_PACKAGE_autopart=y
CONFIG_PACKAGE_block-mount=y
# 文件传输（在线安装 ipk 用）
CONFIG_PACKAGE_luci-app-filetransfer=y
# 网络唤醒
CONFIG_PACKAGE_etherwake=y
CONFIG_PACKAGE_luci-app-wol=y
CONFIG_PACKAGE_luci-i18n-wol-zh-cn=y
# SQM QoS（带宽整形）
CONFIG_PACKAGE_luci-app-sqm=y
CONFIG_PACKAGE_luci-i18n-sqm-zh-cn=y
# 网络诊断
CONFIG_PACKAGE_mtr=y
CONFIG_PACKAGE_tcpdump=y

# ====== 分区大小微调（如想覆盖 config 中的默认值，取消注释修改）======
# config 中默认 ROOTFS=8192(8GB)；250GB NVMe 充裕，想给插件/日志更多空间可改大
# CONFIG_TARGET_ROOTFS_PARTSIZE=16384
# CONFIG_TARGET_KERNEL_PARTSIZE=64
EOF

echo "  已追加自定义包与分区项"

# ---------------------------------------------------------------------------
# 2. 修复一些常见的配置冲突：去掉重复或矛盾的 CONFIG 行
#    sort -u 去重后保留最后出现的值
# ---------------------------------------------------------------------------
# cp .config .config.bak
# awk '!seen[$0]++ || $0 ~ /^# / ' .config.bak > .config  # 仅示例，defconfig 自身会规范化

echo "==== [diy-part2] .config 追加完成 ===="
