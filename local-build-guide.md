# 本地 WSL 编译指南

在 Windows 上用 WSL2 编译 ImmortalWrt x86_64 固件。本文假设你是 Windows 10/11，从未装过 WSL。

> 编译耗时参考：首次约 **2~3 小时**（取决于 CPU 和网速，主要是下载源码包）；二次编译（已缓存）约 20~40 分钟。

---

## 一、安装 WSL2 + Ubuntu 22.04

### 1.1 一键安装（推荐）

以**管理员身份**打开 PowerShell，执行：

```powershell
wsl --install -d Ubuntu-22.04
```

安装完会提示重启，重启后会自动进入 Ubuntu 初始化，设置 UNIX 用户名和密码（记好，后面 `sudo` 要用）。

### 1.2 验证 WSL2

```powershell
wsl -l -v
```

确保 `VERSION` 列是 `2`。如果是 1，转换：

```powershell
wsl --set-version Ubuntu-22.04 2
```

### 1.3 建议分配足够资源

WSL2 默认最多用一半内存。编译吃内存，建议在 Windows 用户目录 `C:\Users\zp\.wslconfig` 写入：

```ini
[wsl2]
memory=8GB
processors=4
swap=4GB
```

改完在 PowerShell 执行 `wsl --shutdown` 再重开 Ubuntu 生效。

---

## 二、安装编译依赖

进入 Ubuntu（PowerShell 输入 `wsl` 或从开始菜单开 Ubuntu），执行：

```bash
sudo apt update && sudo apt upgrade -y

# ImmortalWrt 官方要求的编译依赖
sudo apt install -y \
  build-essential clang flex bison g++ gawk gcc-multilib g++-multilib \
  gettext git libncurses-dev libssl-dev python3-distutils rsync unzip \
  zlib1g-dev swig aria2 wget curl subversion jq python3 python3-pip \
  ccache libelf-dev device-tree-compiler libc6-dev libgmp-dev libmpc-dev \
  libmpfr-dev pkg-config
```

> ⚠️ **不要用 root 编译**，ImmortalWrt 会拒绝。用你初始化时建的普通用户即可。

---

## 三、拉取本项目与源码

### 3.1 把本项目放到 WSL 里

本项目当前在 `C:\Users\zp\ZCodeProject\openwrt-firmware`，在 WSL 里对应路径是 `/mnt/c/Users/zp/ZCodeProject/openwrt-firmware`。

为了编译稳定（避免跨 Windows/Linux 文件系统出错），**复制一份到 WSL 的家目录**：

```bash
cp -r /mnt/c/Users/zp/ZCodeProject/openwrt-firmware ~/openwrt-firmware
```

### 3.2 克隆 ImmortalWrt 源码（openwrt-24.10 稳定版）

```bash
cd ~
git clone --depth 1 --branch openwrt-24.10 https://github.com/immortalwrt/immortalwrt.git
```

`--depth 1` 只拉最新一次提交，节省时间和磁盘（约 1GB）。

> 国内网络慢可换镜像：`https://gitclone.com/github.com/immortalwrt/immortalwrt.git`

---

## 四、一键应用配置并编译

本项目提供了 `scripts/apply-config.sh`，它会自动完成：注入 feeds → 修改默认值 → 应用 .config → 补全依赖。然后询问是否开始编译。

```bash
cd ~/immortalwrt
bash ~/openwrt-firmware/scripts/apply-config.sh ~/immortalwrt
```

脚本最后会问“是否立即开始编译”，输入 `y` 回车即可。并发数回车用默认（全部 CPU 核心）。

---

## 五、（可选）手动分步编译

如果你想理解每一步，或脚本某步报错，可以手动执行：

```bash
cd ~/immortalwrt

# 1. 注入自定义 feeds（OpenClash 等）
cat ~/openwrt-firmware/scripts/feeds.conf.custom >> feeds.conf

# 2. 修改默认 IP/主机名/时区
bash ~/openwrt-firmware/scripts/diy-part1.sh ~/openwrt-firmware ~/immortalwrt

# 3. 更新 & 安装 feeds
./scripts/feeds update -a
./scripts/feeds install -a

# 4. 应用 .config 种子
cp ~/openwrt-firmware/config/x86-64.config .config
bash ~/openwrt-firmware/scripts/diy-part2.sh ~/openwrt-firmware ~/immortalwrt

# 5. defconfig 补全依赖（重要，不要跳过）
make defconfig

# 6. 进一步微调（可选，字符界面勾选/取消包）
make menuconfig

# 7. 下载源码包
make download -j$(nproc) V=s

# 8. 编译
make -j$(nproc) V=s
```

---

## 六、产物位置

编译成功后，固件在：

```
~/immortalwrt/bin/targets/x86/64/
```

主要关注这几个文件：

| 文件 | 用途 |
|---|---|
| `*-squashfs-combined-efi.img.gz` | **UEFI 引导 + 可恢复出厂**，物理机/虚拟机首选 |
| `*-ext4-combined-efi.img.gz` | UEFI 引导，ext4 可在线扩容 |
| `*-squashfs-rootfs.img.gz` | 仅 rootfs，特殊用途 |
| `*-combined-efi.vmdk` | VMware / ESXi 直接导入 |
| `*manifest` | 已编译包清单 |

复制到 Windows：

```bash
cp ~/immortalwrt/bin/targets/x86/64/*.img.gz /mnt/c/Users/zp/Desktop/
```

---

## 七、刷写固件

### 7.1 物理机（U 盘 / 写盘工具）

1. 解压 `.img.gz` 得到 `.img`（用 7-Zip 或 `gunzip`）
2. 用 **Rufus** 或 **physdiskwrite** 写入 U 盘 / 直接写硬盘：
   - Rufus：选 `.img` → 写入 U 盘 → 从 U 盘启动
   - physdiskwrite（写整块硬盘）：`physdiskwrite -u 固件.img`

### 7.2 虚拟机（PVE / ESXi / VMware）

- **PVE**：上传 `.img.gz`，解压后用 `qm importdisk` 导入，或用 `qemu-img` 转 qcow2
- **VMware**：直接用 `.vmdk` 新建虚拟机；或新建虚拟机后挂载 `.img`（需转换）
- **ESXi**：上传 `.vmdk`，用 `vmkfstools -i` 转换后附加

### 7.3 首次登录

- 浏览器访问 `192.168.5.1`（diy-part1 改过的默认 IP；不改则是 `192.168.1.1`）
- 默认无密码，进入后立即设置密码

---

## 八、常见问题

### Q1：`make` 报错 `No rule to make target ...`

通常是 feeds 没装全。回到第四步重新跑 `./scripts/feeds install -a`，再 `make defconfig`。

### Q2：下载某些包超时 / 失败

国内访问 GitHub/源站慢。重试几次；或给 WSL 配代理：

```bash
export http_proxy=http://你的代理:端口
export https_proxy=http://你的代理:端口
make download -j1 V=s
```

### Q3：磁盘空间不足（No space left on device）

完整编译需要约 **15GB** 空闲。WSL2 默认虚拟磁盘是动态扩展的，但不会自动收缩。可用：

```powershell
# 在 PowerShell 中
wsl --shutdown
diskpart
# 然后 select vdisk file="C:\Users\zp\AppData\Local\Packages\...\ext4.vhdx"
# compact vdisk
```

或干脆在 WSL 里清理后重新克隆。

### Q4：编译中断后想接着编

```bash
make -j$(nproc) V=s   # 直接重跑即可，已编译的部分会跳过
```

### Q5：想增删插件

编辑 `~/openwrt-firmware/config/x86-64.config`，对应行 `=y` 启用、改为 `# ... is not set` 禁用。然后回到第四步重跑 `apply-config.sh`。

### Q6：编译慢

```bash
# 启用 ccache
make menuconfig → Advanced → "Use ccache" 勾选
# 或编译命令加：make CC="ccache gcc" -j$(nproc)
```

二次编译 ccache 命中后能快好几倍。
