# GitHub 云编译指南

用 GitHub Actions 在云端编译固件，**不用本地装任何环境**，全程浏览器操作。免费账号每月 2000 分钟额度，编译一次约 90~120 分钟。

---

## 一、准备 GitHub 账号

如果没有，到 https://github.com 注册一个（免费）。确认能登录。

---

## 二、上传本项目到 GitHub

### 方式 A：用 GitHub Desktop（图形界面，推荐新手）

1. 安装 [GitHub Desktop](https://desktop.github.com/)
2. 登录账号 → `File` → `New repository`
3. 名称填 `openwrt-firmware`，**Local path 选 `C:\Users\zp\ZCodeProject\openwrt-firmware` 的父目录**，勾选 "Initialize with README"（已有的话不勾）
4. 把本项目所有文件放进去，commit 后 `Push origin`

### 方式 B：命令行（已装 git）

在 PowerShell 里：

```powershell
cd C:\Users\zp\ZCodeProject\openwrt-firmware
git init
git add .
git commit -m "init: ImmortalWrt x86_64 build project"
git branch -M main
# 先在 GitHub 网页新建空仓库 openwrt-firmware，不要勾初始化
git remote add origin https://github.com/你的用户名/openwrt-firmware.git
git push -u origin main
```

---

## 三、触发编译

1. 打开你的仓库网页，点顶部 **`Actions`** 标签
2. 左侧选 **`Build ImmortalWrt x86_64`**
3. 右侧点 **`Run workflow`** 下拉，可填写参数（一般用默认即可）：
   - `repo_url`：源码地址（默认 ImmortalWrt 官方）
   - `repo_branch`：分支（默认 `openwrt-24.10`）
   - `config_file`：配置文件路径（默认 `config/x86-64.config`）
   - `make_thread`：并发数（默认 2，GitHub runner 内存有限，不建议调高）
4. 点绿色 **`Run workflow`** 按钮

> 也可以**直接 push 代码**，会自动触发（仅当 `.github/workflows`、`config/`、`scripts/` 有改动时）。

---

## 四、查看编译进度

- `Actions` 页面会看到一次运行记录，黄色圆圈表示进行中
- 点进去 → `Compile firmware` job → 展开各 step 看实时日志
- 整个流程约 90~120 分钟，关键耗时在 `Download sources` 和 `Compile`

---

## 五、下载固件

编译成功后（绿色对勾）：

1. 点进这次运行记录
2. 页面底部 **`Artifacts`** 区有一个 `immortalwrt-x86-64-openwrt-24.10-序号` 的包
3. 点击下载，得到一个 `.zip`
4. 解压后就是固件文件：
   - `*-squashfs-combined-efi.img.gz` ← 物理机/虚拟机首选
   - `*-ext4-combined-efi.img.gz`
   - `*.vmdk` ← VMware/ESXi 用
   - `BUILD-INFO.txt` ← 编译时间、commit 等信息

> artifact 默认保留 30 天，过期会自动删除，记得及时下载。

---

## 六、刷写与首次登录

参考 [local-build-guide.md 第七章](./local-build-guide.md)，刷写方式与本地编译产物完全一致。

- 默认 IP：`192.168.5.1`（diy-part1 中改过；想改回编辑该脚本）
- 默认无密码，进 LuCI 后立即设置

---

## 七、常见问题

### Q1：Actions 里看不到 "Build ImmortalWrt x86_64"

确认 `.github/workflows/build.yml` 已 push 上去。Fork 别人的仓库时，需到 Actions 页面手动点 "I understand my workflows, go ahead and enable them" 启用。

### Q2：编译失败，超时或被取消

- GitHub 免费单 job **上限 6 小时**。本配置通常 2 小时内完成，超时一般是网络卡在下载
- 查失败 step 的日志，常见是某个 dl 包下载失败。重跑一次 workflow 往往就好
- 失败时会自动上传日志 artifact（`logs-序号`），下载排查

### Q3：免费额度够用吗？

公开仓库 Actions **完全免费、不限时**。私有仓库每月 2000 分钟。建议把仓库设为 **Public**。

### Q4：想换分支或加插件

- 换分支：`Run workflow` 时改 `repo_branch`（如 `main` 主干）
- 加插件：编辑 `config/x86-64.config`，加 `CONFIG_PACKAGE_xxx=y`，push 后自动触发

### Q5：想自动发布 Release

编辑 `.github/workflows/build.yml` 末尾被注释的 `Release` 步骤：
1. 在 GitHub → Settings → Secrets → Actions 添加 `GH_TOKEN`（个人访问令牌，勾 repo 权限）
2. 删掉那段注释
3. 之后每次编译成功会自动发 Release，固件长期保存

### Q6：二次编译还是很慢？

workflow 已配 toolchain 缓存（key 跟分支和 config 相关）。相同 config 二次编译会命中缓存，省 30~60 分钟。如果改了 config，缓存会重建。

---

## 八、⚠️ 合规提醒

本固件包含的代理类插件（PassWall / OpenClash / SSR+ / HomeProxy 等）仅用于**网络研究、开发测试、合规的企业跨境访问**等合法场景。在你所在地区使用此类工具的合规性请自行评估并遵守当地法律法规。
