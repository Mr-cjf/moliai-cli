# 给 Agent 的 MoliAi CLI 安装说明

本文件是给 **AI Agent** 读的操作手册。目标是装好 `moliai` CLI 与 Skill，并在用户提供凭据后确认后端连通。

四条铁律，先读完再动手：

1. **安装完成 ≠ 登录成功**。装好 CLI 只代表可执行文件存在，认证是独立的第二件事。
2. **不得自动提交收费生成任务**。`moliai run` 会扣减用户的魔力值。没有用户明确指令，只允许 `--dry-run`。
3. **不能自造凭据**。KEY 与 baseUrl 必须由用户提供。不要猜、不要从别处复制、不要尝试默认值。
4. **不猜、不跳过、不自动重试**。失败就报告失败与错误码，把决定权交回用户。

---

## 1. 环境检查

先确认平台与架构：

```bash
# Linux / macOS
uname -sm
```

```powershell
# Windows
[System.Environment]::Is64BitOperatingSystem
```

按结果选择对应的 Release 文件：

| 平台 | 文件 |
|---|---|
| Windows x64 | `moliai-windows-x64.exe` |
| macOS (Apple Silicon) | `moliai-darwin-arm64` |
| macOS (Intel) | `moliai-darwin-x64` |
| Linux x64 | `moliai-linux-x64` |

平台不在上表内（如 Windows ARM、Linux ARM、32 位系统）→ **停止**，告知用户当前没有对应的官方构建，不要尝试交叉运行或模拟层。

## 2. 安装 CLI

CLI 是闭源软件，源码不公开，以单文件可执行程序分发。

### 2.1 优先：一键安装脚本

**macOS / Linux**

```bash
curl -fsSL https://github.com/Mr-cjf/moliai-cli/releases/download/v0.10.3/install.sh | sh
```

**Windows（PowerShell）**

```powershell
irm https://github.com/Mr-cjf/moliai-cli/releases/download/v0.10.3/install-boot.ps1 | iex
```

注意：不要用 `irm .../install.ps1 | iex`。该文件带 UTF-8 BOM，管道进 `Invoke-Expression` 会导致 `ParseException`（PowerShell 5.1 和 7.x 均如此）。`install-boot.ps1` 是无 BOM 的纯 ASCII 引导脚本，负责下载并按 UTF-8 解码执行真正的安装器。

脚本会自动：判断平台与架构 → 下载对应 Release → 校验 SHA256 → 安装到 `~/.local/bin`（Windows 为 `%USERPROFILE%\bin`）→ 打印 PATH 提示 → 执行 `--version` 验证。

- 平台不支持时脚本会**直接报错退出**，不会尝试模拟层或交叉运行
- SHA256 校验失败时脚本以非 0 退出码结束，**不要继续使用该文件**
- 需要固定版本或自定义目录：`MOLIAI_VERSION` / `MOLIAI_INSTALL_DIR`（sh），`-Version` / `-InstallDir`（PowerShell）
- 安装目录不在 `PATH` 时脚本只打印需要追加的 `export` 行，**不会**自动修改用户的 shell 配置文件；需要用户自己决定是否写入
- Windows 脚本只会改动**用户级** `Path`，不会动系统级

如果执行环境不允许运行远程脚本，先下载审查内容再执行：

```bash
curl -fsSL https://github.com/Mr-cjf/moliai-cli/releases/download/v0.10.3/install.sh -o install.sh
# 检查内容后再执行
sh install.sh
```

```powershell
# Windows：下载后执行，install.ps1 在这条路径下是正常的
irm https://github.com/Mr-cjf/moliai-cli/releases/download/v0.10.3/install.ps1 -OutFile install.ps1
# 检查内容后再执行
.\install.ps1
```

### 2.2 备选：手动下载

一键脚本失败时，直接从 Releases 下载单文件：

```bash
# 以 macOS Apple Silicon 为例，替换为实际平台对应文件
curl -L -o moliai https://github.com/Mr-cjf/moliai-cli/releases/latest/download/moliai-darwin-arm64
chmod +x moliai
```

```powershell
# Windows 示例
Invoke-WebRequest -Uri "https://github.com/Mr-cjf/moliai-cli/releases/latest/download/moliai-windows-x64.exe" -OutFile "moliai.exe"
```

安装位置由用户决定（`/usr/local/bin`、`~/.local/bin` 或任意加入 `PATH` 的目录）。**不要**在未获用户同意时写入系统目录。

可选的完整性校验：

```bash
curl -L -O https://github.com/Mr-cjf/moliai-cli/releases/latest/download/SHA256SUMS.txt
sha256sum -c SHA256SUMS.txt
```

校验失败 → **停止并报告**，不要继续执行该文件。

**未签名提示**：Windows SmartScreen 可能拦截，macOS 可能提示「无法验证开发者」。这需要用户亲自确认，不要让用户关闭系统安全设置：

- Windows：点「更多信息」→「仍要运行」
- macOS：`xattr -dr com.apple.quarantine ./moliai`，或在「系统设置 → 隐私与安全性」中点「仍要打开」

### 2.3 npm（⚠️ 暂未发布，不要用这条路安装）

> **⚠️ 暂未发布，请勿执行。** `@moliai/cli` 尚未发布到 npm，请使用 2.1 或 2.2 的 GitHub Release 方式安装。以下命令仅供发布后参考。

```bash
npm install -g @moliai/cli@0.10.3
```

包名是 `@moliai/cli`，安装后的命令名是 `moliai`；这条路线需要 Node.js **≥ 20**。

全局安装失败（权限不足）时**不要**自行改用 `sudo` 或修改 npm prefix——先报告错误原文，由用户决定。
用户坚持走 npm 但装不上时，如实说明「npm 包暂未发布/不可用」，引导回 2.1 一键脚本或 2.2 手动下载，**不要**尝试从源码构建。

## 3. 验证安装

```bash
moliai --version    # 应输出 0.10.3
moliai help         # 应列出命令树
moliai doctor       # 本机自检，恒以退出码 0 结束，看 data.healthy
```

`doctor` 的结论要看 `data.checks` 里是否有 `fail`，而不是只看退出码。

没有网络时用 `moliai doctor --offline`，只跑本机检查。

## 4. 安装 Skill

```bash
moliai setup --agent all --dry-run   # 先看计划，不落盘
moliai setup --agent all             # 实际写入
moliai setup --agent all --check     # 复核
```

默认写入两个位置：

- `~/.agents/skills/moliai-cli-skill`（Codex / dsh / 通用宿主）
- `~/.claude/skills/moliai-cli-skill`（Claude Code）

只装给某一类宿主：`--agent claude` / `--agent codex` / `--agent dsh` / `--agent generic`。

安装后需要**重启宿主会话**新 Skill 才会生效——请如实告知用户这一步。

若宿主不是上述任一类型，把 `moliai setup` 的输出原样报告，不要假装装好了。

基于 Skills CLI 的替代方式（宿主支持 Skill 目录时同样可用）：

```bash
npx skills add Mr-cjf/moliai-cli --skill moliai-cli-skill -g
```

## 5. 配置与登录

**这一步必须由用户提供两项信息，Agent 不能自己填：**

| 需要的信息 | 来源 |
|---|---|
| `baseUrl` | 用户提供。生产环境通常是 `https://dance.aidancevid.com/api`，测试环境通常是 `https://test-api.aidancevid.com/api` |
| KEY | 用户在网页 **API 配置 → 开发者配置** 中复制 |

登录方式：让用户**自己**把 KEY 输入到 stdin，不要让用户把 KEY 贴在对话里（会留在会话记录中）。

```bash
# 交互式（推荐）：让用户在本机终端自己执行，运行后会提示粘贴 KEY，回车即读取
moliai login key --base-url "<用户提供的 baseUrl>"

# 管道式：只有用户主动把 KEY 交给你代跑时才能用（KEY 不落文件；但明文会留在 shell 历史，提醒用户自行清理）
printf %s "<KEY>" | moliai login key --base-url "<用户提供的 baseUrl>"
```

- 不要代用户执行交互式那条：stdin 没有数据时会在 10 秒后以 `MOLIAI_ARG_INVALID`（等待超时）退出，不会永久挂起
- 如果环境无法交互输入，请让用户在本机终端自己执行这条命令，再回来告诉你结果

说明给用户的风险：这个 KEY 等同于账号全权限（可建/删画布、提交生成并扣费），且无过期时间。KEY 默认保存到 `~/.moliai/credentials.json`（权限 0600）用于 token 自动续期——KEY 无法单独吊销，请确保该文件不被他人读取；不希望保存时加 `--no-save-key`，此时 token 过期后需重新登录。

### 5.1 多环境时先确认当前环境

本机可能同时保存了测试与生产两套凭据。**登录后、做任何有副作用的操作前**，先跑 `moliai env` 确认：

- `data.current` 是**本次调用实际会用的环境**（已把 `--base-url` 与 `MOLIAI_BASE_URL` 算进去）
- `data.default` 是什么都不指定时的默认环境，可能与 `current` 不同
- 每条环境的 `expired: true` 表示该环境令牌已过期，需要用户重新登录该环境

规则：

- 环境不对时**不要自己改默认环境**——先向用户确认目标环境，再由用户决定是否执行 `moliai env use <url>`
- 只想临时换环境，用全局参数而不是改默认：`moliai project list --base-url "<url>"`
- 报 `MOLIAI_NOT_BOUND` 且 `hint` 指向 `moliai login key --base-url <url>` → 该环境没登录过，让用户提供该环境的 KEY，不要复用另一个环境的凭证
- 不要执行 `moliai logout`（会删掉**所有**环境的凭据）；只清理单个环境用 `moliai env remove <url>`，且必须经用户同意

## 6. 联通验证

按顺序执行，**任何一步失败就停在该步并报告**：

```bash
moliai env           # 先确认当前环境是否正确
moliai status        # 看 baseUrl / authenticated / connectivity.ok
moliai whoami        # 看 authenticated 与 userId
moliai project list  # 只读接口，验证鉴权链路真的通
```

判定标准：

- `status.data.authenticated === true` 且 `status.data.connectivity.ok === true` → 后端连通正常
- `status.data.connectivity.error` 有值 → 按错误码定位：
  - `MOLIAI_AUTH_REQUIRED` / `MOLIAI_TOKEN_EXPIRED` → 凭据无效或过期，回到第 5 步
  - `MOLIAI_NOT_BOUND` → 当前环境没有可用凭据（没登录过，或默认环境被删了）；用 `moliai env` 看现状，再让用户提供该环境的 KEY
  - `MOLIAI_NETWORK_ERROR` → 网络/DNS/地址错误，确认 `baseUrl` 是否写全（含 `/api`）
- `project list` 返回空数组是合法结果（账号还没有项目），不代表未授权；未授权会返回 `MOLIAI_AUTH_REQUIRED`
- `project` 组支持 `list` 与 `create`：建项目用 `moliai project create "<名称>"`（**CLI 只支持 `canvas`/无限画布模式**，会顺带建一张同名画布），
  没有 `project update` / `project delete`（改名、删除仍需网页端）。传统模式（`novel-promotion`）项目没有画布、CLI 对其无写能力，
  `--mode novel-promotion` 会直接报 `MOLIAI_ARG_INVALID` 且不创建项目——需要传统模式项目时让用户到网页端创建。
  创建成功**不会**自动写目录绑定，按输出 `next` 继续；
  建项目会写入后端数据，先确认 `moliai env` / `--base-url` 指向的环境，不要在用户未同意时向生产环境创建

## 7. 报告格式

安装结束后按四个状态分别报告，不要合并成一句「安装成功」：

| 状态 | 取值 | 依据 |
|---|---|---|
| CLI 安装 | 成功 / 失败 | `moliai --version` 实际输出 |
| Skill 安装 | 成功 / 失败 / 未执行 | `moliai setup --check` 结果 |
| 登录 | 成功 / 失败 / 未执行 | `moliai whoami` 的 `authenticated` |
| 后端连通 | 正常 / 异常（附错误码） | `moliai status` 的 `connectivity.ok` |

报告里可以带 traceId，**绝不能带 KEY 或令牌**。

## 8. 失败处理

- 不猜原因：先读 stderr 错误信封的 `error.code` 与 `error.hint`，再决定动作
- 不跳过失败步骤继续往下走
- **不自动重试收费操作**：`run` 失败后不要换模型、不要改参数、不要降分辨率重试；把失败原因与 `jobId` / `taskId` 报给用户
- 网络类错误（`MOLIAI_NETWORK_ERROR` / `MOLIAI_RATE_LIMITED`）可以有限次退避重试，其余错误一律不重试
- 遇到未登记的错误码直接停止并说明，不要兜底

## 9. 装好之后

- 只读探索：`moliai project list` → `moliai canvas list -w <projectId>` → `moliai node list`
  （账号还没有项目时用 `moliai project create "<名称>"` 创建；`canvas create` / `node create` 等写命令也在 CLI 里）
- 看模型与参数：`moliai model list` / `moliai model <modelKey>`
- 生成预演（零成本）：`moliai run <node> --dry-run --model <k> --prompt "<p>"`
- 真实提交需要用户明确同意，并先展示 `--dry-run` 的 `estimatedCost` 与 `warnings`
- 长任务用 `moliai wait <jobId> --max 60` 分轮等待，不要提高 `--wait` 硬等

详细命令与成本规则见随包安装的 Skill，以及 `moliai help --json`。

## 10. ffmpeg 缺失时怎么办

`moliai derive audio-separation` / `derive audio-process` 需要系统 ffmpeg。
CLI **不内置** ffmpeg（那样会让二进制从 110MB 涨到 243MB）。

当这些命令返回 `MOLIAI_UNSUPPORTED`（退出码 5）时，按错误里的 `hint` 安装：

| 平台 | 命令 |
|---|---|
| macOS | `brew install ffmpeg` |
| Ubuntu / Debian | `sudo apt update && sudo apt install -y ffmpeg` |
| Windows | `winget install --id Gyan.FFmpeg` |

**Agent 注意事项**：

- 不要尝试用 curl/wget 直接下载 ffmpeg 二进制并塞进 PATH —— 版本与依赖不可控
- 不要尝试自己编译
- 不要因为这个失败就静默跳过音频功能，要明确告诉用户缺什么
- 安装后用 `moliai doctor` 确认 `ffmpeg` 检查项变成 `pass`
- 如果包管理器不可用（如受限环境），提示用户手动下载并设置 `MOLIAI_FFMPEG=/path/to/ffmpeg`

**已有 ffmpeg 但不想要 PATH 污染**：

```bash
moliai derive audio-process <节点> --trim-start 1 --trim-end 2 --ffmpeg /opt/ffmpeg/bin/ffmpeg
```

或

```bash
export MOLIAI_FFMPEG=/opt/ffmpeg/bin/ffmpeg
```
