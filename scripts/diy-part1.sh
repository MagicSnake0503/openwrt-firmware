#!/usr/bin/env bash
# =============================================================================
# diy-part1.sh — 个性化定制脚本（第一段）
# 作用：在 feeds install 之后、make defconfig 之前运行，修改源码树中的默认值。
#   常见用途：修改默认 LAN IP、主机名、时区、WIFI 区域、默认密码哈希等。
# 调用方式：./diy-part1.sh <项目根目录> <immortalwrt 源码目录>
#   云编译：由 workflow 自动调用
#   本地：  bash scripts/diy-part1.sh "$(pwd)" "immortalwrt"
# =============================================================================

set -euo pipefail

PROJECT_ROOT="${1:-.}"
SRC_DIR="${2:-immortalwrt}"

# 切到源码目录
cd "$SRC_DIR"

echo "==== [diy-part1] 开始个性化定制 ===="

# ---------------------------------------------------------------------------
# 1. 修改默认 LAN IP（默认 192.168.1.1）
#    改成 192.168.5.1 避免与上级光猫/上级路由冲突；如需改回，编辑此行
# ---------------------------------------------------------------------------
LAN_IP="192.168.5.1"
sed -i "s/192\.168\.1\.1/${LAN_IP}/g" package/base-files/files/bin/config_generate
echo "  默认 LAN IP → ${LAN_IP}"

# ---------------------------------------------------------------------------
# 2. 修改主机名（在 LuCI 和 SSH 提示符中可见）
# ---------------------------------------------------------------------------
HOSTNAME="ImmortalWrt"
sed -i "s/ImmortalWrt/${HOSTNAME}/g" package/base-files/files/bin/config_generate 2>/dev/null || true

# ---------------------------------------------------------------------------
# 3. 修改时区为东八区、设置 NTP 服务器
# ---------------------------------------------------------------------------
TARGET_DIR="package/base-files/files/etc"
# 时区（先确保目录存在）
mkdir -p "${TARGET_DIR}/config"
cat > "${TARGET_DIR}/config/system" <<'EOF'
config system
	option hostname 'ImmortalWrt'
	option timezone 'CST-8'
	option zonename 'Asia/Shanghai'
	option log_size '128'

config timeserver 'ntp'
	option enabled '1'
	option enable_server '0'
	list server 'ntp.aliyun.com'
	list server 'time1.cloud.tencent.com'
	list server 'cn.pool.ntp.org'
EOF
echo "  时区 → Asia/Shanghai，NTP → 阿里云/腾讯云"

# ---------------------------------------------------------------------------
# 4. 设置默认主题为 argon
# ---------------------------------------------------------------------------
mkdir -p "${TARGET_DIR}/uci-defaults"
cat > "${TARGET_DIR}/uci-defaults/99-default-theme" <<'EOF'
#!/bin/sh
[ -f /etc/config/luci ] || exit 0
uci set luci.main.mediaurlbase='/luci-static/argon'
uci commit luci
exit 0
EOF
chmod +x "${TARGET_DIR}/uci-defaults/99-default-theme"
echo "  默认主题 → argon"

# ---------------------------------------------------------------------------
# 5. 默认密码留空（首次进 LuCI 直接设置），如需硬编码密码取消下面注释
#    密码哈希生成：openssl passwd -6 '你的密码'
# ---------------------------------------------------------------------------
# HASHED_PASS='替换为 openssl passwd -6 生成的哈希'
# sed -i "/^root:/c\\root:${HASHED_PASS}:19000:0:99999:7:::" "${TARGET_DIR}/shadow" 2>/dev/null || true

echo "==== [diy-part1] 个性化定制完成 ===="
