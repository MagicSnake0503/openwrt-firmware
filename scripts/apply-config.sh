#!/usr/bin/env bash
# =============================================================================
# apply-config.sh — 本地编译辅助脚本（在 WSL 内运行）
# 功能：
#   1) 把 config/x86-64.config 复制为源码树中的 .config
#   2) 注入自定义 feeds 与 diy 脚本
#   3) 运行 feeds install
#   4) 运行 make defconfig 补全依赖
#   5) 询问是否直接开始 make（可选）
#
# 用法：
#   cd ~/immortalwrt              # 先进到源码目录
#   bash /path/to/apply-config.sh # 然后调用本脚本
#   或：bash apply-config.sh /home/you/immortalwrt  # 显式指定源码目录
#
# 本脚本只是把繁琐命令串起来，理解每一步后也可以手动执行。
# =============================================================================

set -euo pipefail

# 取脚本所在目录（项目根目录）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# 源码目录：优先用第一个参数，否则用环境变量 IW_HOME，再否则报错提示
SRC_DIR="${1:-${IW_HOME:-}}"
if [ -z "$SRC_DIR" ] || [ ! -d "$SRC_DIR" ]; then
    cat <<'EOF'
[!] 未找到 ImmortalWrt 源码目录。
    用法：bash apply-config.sh <immortalwrt 源码目录>
    例如：bash apply-config.sh ~/immortalwrt
EOF
    exit 1
fi

echo "==== 源码目录: $SRC_DIR"
echo "==== 项目目录: $PROJECT_ROOT"
cd "$SRC_DIR"

# 1. 注入自定义 feeds
if [ -f "$PROJECT_ROOT/scripts/feeds.conf.custom" ]; then
    echo "==== [1/5] 注入自定义 feeds ===="
    cp feeds.conf feeds.conf.bak 2>/dev/null || true
    # 去掉之前的注入（标记行之间），避免重复追加
    sed -i '/# --- BEGIN custom feeds ---/,/# --- END custom feeds ---/d' feeds.conf 2>/dev/null || true
    {
        echo ""
        echo "# --- BEGIN custom feeds ---"
        cat "$PROJECT_ROOT/scripts/feeds.conf.custom"
        echo "# --- END custom feeds ---"
    } >> feeds.conf
    echo "  已写入 feeds.conf"
fi

# 2. 运行 diy-part1（改源码默认值）
if [ -f "$PROJECT_ROOT/scripts/diy-part1.sh" ]; then
    echo "==== [2/5] 运行 diy-part1（修改源码默认值）===="
    bash "$PROJECT_ROOT/scripts/diy-part1.sh" "$PROJECT_ROOT" "$SRC_DIR"
fi

# 3. 更新并安装 feeds
echo "==== [3/5] 更新 & 安装 feeds ===="
./scripts/feeds update -a
./scripts/feeds install -a

# 4. 应用 .config 种子
echo "==== [4/5] 应用 .config 种子 ===="
cp "$PROJECT_ROOT/config/x86-64.config" .config
# 运行 diy-part2（向 .config 追加项）
if [ -f "$PROJECT_ROOT/scripts/diy-part2.sh" ]; then
    bash "$PROJECT_ROOT/scripts/diy-part2.sh" "$PROJECT_ROOT" "$SRC_DIR"
fi
# defconfig 补全依赖
make defconfig
echo "  最终 .config 包含的 luci-app："
grep -E "^CONFIG_PACKAGE_luci-app" .config || true

# 5. 询问是否编译
echo "==== [5/5] 配置就绪 ===="
read -r -p "是否立即开始编译？(y/N) " ans
if [ "${ans:-N}" = "y" ] || [ "${ans:-N}" = "Y" ]; then
    read -r -p "并发数 -j（回车默认使用全部 CPU 核心 $(nproc)）: " JN
    JN="${JN:-$(nproc)}"
    echo "==== 开始编译 make -j${JN} V=s ===="
    make -j"${JN}" V=s
    echo "==== 编译完成 ===="
    echo "固件产物位于：$(pwd)/bin/targets/x86/64/"
    ls -lh bin/targets/x86/64/*.img.gz 2>/dev/null || true
else
    echo "已跳过编译。可手动执行："
    echo "  cd $SRC_DIR"
    echo "  make menuconfig   # 如需进一步调整"
    echo "  make -j\$(nproc) V=s"
fi
