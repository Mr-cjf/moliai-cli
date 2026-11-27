# MoliAi CLI

`moliai` 是 MoliAi 的命令行客户端，用来在终端或 AI Agent 里操作魔力画布：浏览项目与画布、管理节点、查询模型参数契约、上传素材、提交图片/视频生成任务，并把产物下载到本地。

- 所有命令输出结构化 JSON（也支持 `ndjson` / `text`），便于脚本和 Agent 解析
- 失败不静默：参数非法会直接报错并列出可选值，不会偷偷换成别的参数或别的模型
- **只有 `run` 会真实扣费**，`run --dry-run` 是零成本预演

---

## 最简单的方式：把下面这段复制给 Agent

如果你在用 Claude Code / Codex / DeepSeek Harness 等 AI 编程工具，**不需要看后面的内容**，把下面整段复制给它就行：

```text
请帮我安装 moliai CLI 并配置好。按以下步骤执行：

1. 判断我的系统（Windows / macOS / Linux）和架构
2. 执行对应的一键安装命令：
   - macOS / Linux：
     curl -fsSL https://github.com/Mr-cjf/moliai-cli/releases/download/v0.10.5/install.sh | sh
   - Windows PowerShell：
     irm https://github.com/Mr-cjf/moliai-cli/releases/download/v0.10.5/install-boot.ps1 | iex
3. 验证安装：moliai --version（应为 0.10.5）、moliai doctor（看 healthy 是否为 true）
4. 安装 Agent Skill：moliai setup --agent all，然后 moliai setup --check 确认
5. 把登录命令原样给我，由我本人执行（不要向我要 API KEY，也不要把它写进任何文件或对话）：
   moliai login key --base-url https://dance.aidancevid.com/api
   我在自己的终端里运行时它会提示我粘贴 KEY 并回车；**你不要代跑这条命令**（stdin 只能由我输入，
   你代跑会读不到 KEY，10 秒后超时报错）
   这条地址就是 CLI 的内置默认（生产环境）；如果我说的服务地址不是它，以我给的为准。

铁律：
- 不要自动执行 moliai run 或其他会产生费用的命令
- 任何一步失败就停下报告原始错误，不要跳过、不要换镜像源、不要从源码构建
- 最后分三段汇报：安装状态 / Skill 状态 / 登录状态
```

**复制完等它跑完就行。** 后续所有命令见下方[命令清单](#命令清单)。

> Windows 用 `install-boot.ps1`：它是个引导脚本，下载并执行真正的安装器。直接 `irm .../install.ps1 | iex` 在 PowerShell 下会因 UTF-8 BOM 解析失败。

### 不知道该选哪种方式？

| 情况 | 怎么做 |
|---|---|
| 有 AI 编程工具（Claude Code / Codex / DSH） | 复制上面那段话给它 |
| 没有 AI 工具，用命令行 | `curl -fsSL https://github.com/Mr-cjf/moliai-cli/releases/download/v0.10.5/install.sh \| sh`（Windows 用 `irm https://github.com/Mr-cjf/moliai-cli/releases/download/v0.10.5/install-boot.ps1 \| iex`） |
| 想自己控制 | 从 [Releases](https://github.com/Mr-cjf/moliai-cli/releases) 手动下载 |

---

## 开始之前

1. 打开 <https://aidancevid.com> 注册账号，并完成充值（生成任务消耗「魔力值」）
2. 准备一个项目：在网页上新建，或直接用 `moliai project create "<项目名>"`（CLI 只支持 `canvas`/无限画布模式，会创建一张同名画布；传统模式请在网页端建）
3. 二进制安装不需要 Node.js（一键脚本装的是单文件二进制）。只有将来通过 npm 安装（**当前暂未发布**）才需要 Node.js **≥ 20**

## 其他安装方式

### 一键脚本

macOS / Linux：

```bash
curl -fsSL https://github.com/Mr-cjf/moliai-cli/releases/download/v0.10.5/install.sh | sh
```

Windows PowerShell：

```powershell
irm https://github.com/Mr-cjf/moliai-cli/releases/download/v0.10.5/install-boot.ps1 | iex
```

脚本会：识别平台 → 从 Releases 下载对应二进制 → 校验 SHA256 → 安装到 `~/.local/bin`（Windows 为 `%USERPROFILE%\bin`）→ 处理 PATH → 执行 `moliai --version` 验证。

- macOS / Linux：安装目录不在 `PATH` 时脚本只**打印**需要追加的 `export` 行，不会自动改你的 shell 配置
- Windows：脚本只修改**用户级** `Path`，不动系统级；已改动的 `Path` 需要新开终端才生效

> **Windows PowerShell 中文乱码**：如遇中文输出乱码，先执行
> `[Console]::OutputEncoding = [Text.Encoding]::UTF8`（只影响当前会话，无需改任何代码或配置）。

可用环境变量覆盖：`MOLIAI_VERSION`（默认 `v0.10.5`）、`MOLIAI_INSTALL_DIR`。

不想直接管道执行，可以先下载审查：

```bash
# macOS / Linux
curl -fsSLO https://github.com/Mr-cjf/moliai-cli/releases/download/v0.10.5/install.sh
less install.sh        # 看完再执行
sh install.sh
```

```powershell
# Windows
irm https://github.com/Mr-cjf/moliai-cli/releases/download/v0.10.5/install.ps1 -OutFile install.ps1
notepad install.ps1    # 看完再执行
.\install.ps1
```

### 手动下载

不想跑脚本就自己下。从 [Releases](https://github.com/Mr-cjf/moliai-cli/releases) 下载对应平台的单文件可执行程序：

| 平台 | 文件 |
|---|---|
| Windows x64 | `moliai-windows-x64.exe` |
| macOS (Apple Silicon) | `moliai-darwin-arm64` |
| macOS (Intel) | `moliai-darwin-x64` |
| Linux x64 | `moliai-linux-x64` |

下载后校验完整性（可选）：

```bash
# Linux / macOS
sha256sum -c SHA256SUMS.txt
```

```powershell
# Windows
Get-FileHash .\moliai-windows-x64.exe -Algorithm SHA256
# 与 SHA256SUMS.txt 中对应行比对
```

**未签名说明**：

- Windows 首次运行可能被 SmartScreen 拦截 → 点「更多信息」→「仍要运行」
- macOS 首次运行可能提示「无法验证开发者」→ 执行 `xattr -dr com.apple.quarantine ./moliai`，或在「系统设置 → 隐私与安全性」中点「仍要打开」

macOS / Linux 下载后需要赋予执行权限：

```bash
chmod +x ./moliai-darwin-arm64
mv ./moliai-darwin-arm64 /usr/local/bin/moliai
```

确认安装：

```bash
moliai --version
```

### npm（源码方式）

> **⚠️ 暂未发布，请勿执行。** `@moliai/cli` 尚未发布到 npm，请使用上方 GitHub Release 安装方式。以下命令仅供发布后参考。

```bash
npm install -g @moliai/cli
moliai --version
```

包名是 `@moliai/cli`，安装后命令名是 `moliai`。运行时依赖只有 `commander`。这个仓库是 CLI 的源码仓库，但 `@moliai/cli` **目前尚未发布到 npm**，所以上面这条命令暂时无法使用——安装请走 GitHub Release（一键脚本或手动下载单文件二进制）。

### 升级（自更新）

单文件二进制安装可以直接自更新（检测最新版本 → 下载 → 校验 SHA256 → 替换）：

```bash
moliai update --check      # 只查有没有新版本，不下载
moliai update --dry-run    # 看会做什么（含产物大小），不下载
moliai update              # 真正更新
moliai update --force      # 版本号相同也重装
```

`setup --upgrade` 与 `moliai update` 完全等价：

```bash
moliai setup --upgrade --dry-run
moliai setup --upgrade
```

**Windows 特别注意**：运行中的 `moliai.exe` 无法被覆盖。CLI 会下载新版本并生成 `.update.bat`，
然后立即退出；脚本在约 2 秒后完成替换并自删。因此：

- 命令输出里 `replaced` 为 `false`，`message` 提示「CLI 将退出，更新在后台完成」
- 更新完成后重新执行 `moliai --version` 确认版本
- 更新期间不要重复执行命令

**平台支持**（与发布产物一致）：`win32-x64` / `darwin-x64` / `darwin-arm64` / `linux-x64`。
其它平台（如 `linux-arm64`）会明确报 `MOLIAI_UNSUPPORTED`，请用 `install.sh` / `install-boot.ps1` 重装，或从 [Releases](https://github.com/Mr-cjf/moliai-cli/releases) 手动下载对应平台的二进制后自行放到 `PATH` 里（**npm 包暂未发布，当前不可用**）。

**仓库来源**（优先级从高到低）：

1. `--repo <owner/repo>`
2. 环境变量 `MOLIAI_UPDATE_REPO`
3. 配置文件 `~/.moliai/config.json` 的 `updateRepo`（`MOLIAI_CONFIG_DIR` 可改目录）
4. 默认 `Mr-cjf/moliai-cli`

配置持久化与查看：

```bash
moliai update config --repo <owner/repo>   # 写入配置
moliai update config --show                # 显示当前生效仓库与来源（arg/env/config/default）
```

用途：内网镜像、私有 fork、`github.com` 下载域名不通时的替代源。
`api.github.com` 未认证限流为 60 次/小时，够用；配了 `GITHUB_TOKEN` 会自动带上以提高额度
（私有仓库还需要该 token，且 release 资产必须可被下载）。

> ⚠️ `GITHUB_TOKEN` 必须对执行命令的进程可见：用 `[Environment]::SetEnvironmentVariable(..., "User")` 或系统设置面板配置后，**需要重开终端 / 重启 IDE 或 Agent 宿主进程**才会生效，已在运行的进程不会自动继承。判断是否生效：`moliai update --check` 返回 `MOLIAI_RATE_LIMITED` 且 `rateLimitRemaining: 0`，说明本次调用没带上 token。

**npm / 源码安装**不走自更新（替换 `node` 可执行文件会破坏运行时），会明确拒绝并提示：

> **⚠️ npm 包暂未发布，以下升级命令当前不可用，请勿执行。** 二进制安装请使用 `moliai update`。

```bash
npm i -g @moliai/cli@latest
```

下载失败会给出清晰错误（网络不可达 / HTTP 状态 / 限流），不会静默跳过，也不会自动降级到其它来源。

### 版本兼容性（请求头 + 426）

每个请求都会带上 `X-Moliai-Cli-Version: <当前 CLI 版本>`（框架层统一附加，调用方无法覆盖，匿名与 multipart 请求同样带）。后端据此判定兼容性。

当前 CLI 低于后端要求的最低版本时，后端返回 **HTTP 426**：

```json
{
  "success": false,
  "error": { "code": "CLI_VERSION_TOO_OLD", "message": "...", "retryable": false },
  "minVersion": "0.10.0",
  "recommendedVersion": "<最新版本>",
  "upgradeHint": "moliai update"
}
```

CLI 映射为 `MOLIAI_VERSION_TOO_OLD`（退出码 5）：

- `error.message` 给出当前版本与后端最低版本
- `error.hint` 给出建议升级版本与升级命令
- `error.details` 带 `currentVersion` / `minVersion` / `recommendedVersion`

后端若用 400 + `error.code=CLI_VERSION_TOO_OLD` 返回，同样映射为该错误码。老后端不返回版本字段时降级为通用文案（不崩、不猜版本号）。

`moliai doctor` 的 `cli-version-compatible` 检查直接比对公开端点 `GET /cli/version`（无需登录）返回的 `minVersion`。

## 获取 KEY

在网页登录后进入 **API 配置 → 开发者配置**，复制其中的 KEY。

> ⚠️ 这个 KEY **等同于你的账号全权限**：可以创建/删除画布、提交生成并扣除魔力值，而且没有过期时间。
> 不要把它写进脚本、CI 配置或聊天记录，也不要交给来路不明的 Agent。
>
> CLI 默认会把 KEY 保存到 `~/.moliai/credentials.json`（权限 0600）用于令牌自动续期。
> KEY 等同账号全权限且**无法单独吊销**，请确保该文件不被他人读取；不希望保存时用 `login key --no-save-key`。

## 登录

```bash
# 交互式：运行后会提示，然后粘贴 KEY 并回车
moliai login key --base-url "https://dance.aidancevid.com/api"

# 管道式（推荐用于脚本 / CI / Agent）
"<KEY>" | moliai login key --base-url "https://dance.aidancevid.com/api"

moliai whoami
```

- KEY 只从 **stdin** 读取，不接受命令行参数（避免进入 shell 历史）
- 非交互环境（CI / Agent / 重定向）**必须用管道**：stdin 无数据时 10 秒超时会报错退出（终端里等待 120 秒），不会永久挂起；超时时间可用 `MOLIAI_STDIN_TIMEOUT_SECONDS` 覆盖
- 交互式粘贴不会进入 shell 历史；但管道里的 KEY 明文会留在 bash/zsh 历史与进程列表，共享机器上优先交互式，或先 `read -s K` 再从变量管道输入
- KEY 默认与令牌一起保存在 `~/.moliai/credentials.json`（目录 0700、文件 0600），用于令牌自动续期
- 令牌剩余有效期不足阈值（`MOLIAI_REFRESH_THRESHOLD_SECONDS`，默认 3600 秒）时，CLI 会用保存的 KEY 自动换新令牌，不需要手动重新登录
- 不希望保存 KEY 时加 `--no-save-key`：只存令牌，令牌过期后需重新 `login key`
- 令牌保存在本地 `~/.moliai/credentials.json`（目录 0700、文件 0600）
- **令牌按环境（`base-url`）分开保存**：登录测试环境不会覆盖生产环境的令牌，切换环境不需要重新登录
- `--base-url` 填 API 网关根地址（结尾带 `/api`）。**不传时默认使用生产环境** `https://dance.aidancevid.com/api`（内置默认），要连其它环境用 `--base-url` / `MOLIAI_BASE_URL` 显式指定；地址写错通常表现为 401 或 404

`moliai whoami` 的 `data` 里除了身份信息还有：

| 字段 | 含义 |
|---|---|
| `quota` | 本地占位（`source: "local-default"`），**不是**服务端配额 |
| `balance` | 真实余额：`total`（合计）/ `general`（通用）/ `membership`（会员）/ `frozen`（冻结）/ `totalSpent`（累计已消耗），来自 `GET /user/balance` |
| `balance: null` | 未登录，或余额接口查询失败；原因写在 `warnings`（不会伪造数字） |

`moliai logout` 删除本地凭据（会删掉所有环境）。

## 多环境（测试 / 生产）

凭据文件是 v4 结构：每个 `baseUrl` 下可存多个账号（按 `userId` 索引），另有 `defaultAccount` 指向当前使用的账号。
登录新环境只写该环境的记录，不动其它环境；同一环境再登录另一个账号会追加，不覆盖已有账号。

```bash
# 1) 分别登录两个环境（各自一份令牌，互不影响）
moliai login key --base-url "https://dance.aidancevid.com/api"   # 生产（CLI 的内置默认）
moliai login key --base-url "<你的 API 地址>"                     # 其它环境（例如内部测试环境）

# 2) 看有哪些环境、当前的默认环境与本次实际会用的环境
moliai env

# 3) 切默认环境（直接用已保存的令牌，不需要重新登录）
moliai env use "https://dance.aidancevid.com/api"

# 4) 删掉某个环境的凭据（删的若是默认环境，默认自动切到剩下的一个）
moliai env remove "<你的 API 地址>"
```

`moliai env` 的输出：

```json
{
  "ok": true,
  "command": "env",
  "data": {
    "default": "https://dance.aidancevid.com/api",
    "currentSource": "store",
    "current": "https://dance.aidancevid.com/api",
    "environments": [
      {
        "baseUrl": "https://dance.aidancevid.com/api",
        "userId": "b4f68a63-...",
        "nickname": "cjf",
        "expiresAt": "2027-01-25T08:05:02.000Z",
        "expired": false,
        "accountCount": 1,
        "defaultAccount": "b4f68a63-...",
        "isDefault": true,
        "isCurrent": true
      }
    ]
  }
}
```

- `default`：什么都不指定时用的环境；`null` 表示还没有登录过任何环境
- `current`：**本次调用实际会用的环境**，已经把 `--base-url` 与 `MOLIAI_BASE_URL` 算进去，可能不等于 `default`
- `currentSource`：`current` 从哪来——`flag`（`--base-url`）/ `env`（`MOLIAI_BASE_URL`）/ `store`（凭据文件里的默认环境）/ `builtin-default`（内置默认的生产地址，此时 `environments` 为空，表示**还没登录过任何环境**）
- 单个命令临时换环境不必改默认：`moliai project list --base-url "<你的 API 地址>"`

### 环境（`env`）与账号（`account`）

- **env = 环境**：按 `baseUrl` 区分（测试环境 / 生产环境），各存各的凭据
- **account = 账号**：同一个环境下的多个账号（同一个 `baseUrl` 用不同 KEY 登录）

```bash
moliai env                    # 列出环境（含默认环境与本次实际环境）
moliai env use <url>          # 切换环境（用该环境已保存的令牌，不重新登录）
moliai account list           # 列出当前环境的账号（默认账号单独标出；不输出 token/KEY）
moliai account use <id>       # 切换当前环境的默认账号
```

`account` 的账号标识可以是 `userId`、昵称或账号 id；**昵称重复时必须用 `userId`**。
所有 `account` 子命令只作用于当前环境，用全局 `--base-url` 可临时对其它环境操作。

### 环境解析优先级

```
--base-url <url>   （命令行，最高）
  > MOLIAI_BASE_URL   （环境变量）
  > credentials.json 的 defaultEnvironment
  > 内置默认：https://dance.aidancevid.com/api（生产）
```

选中环境后只用该环境的令牌；该环境没登录过时报 `MOLIAI_NOT_BOUND`，hint 会直接给出该环境的登录命令。
唯一例外是内置默认地址：没登录过只算「未登录」（`whoami` / `status` 显示 `authenticated: false`、`env` 显示 `currentSource: "builtin-default"`），不会因为「没有指定环境」而直接报错。

### 从旧版本升级

v1 / v2 / v3 的 `credentials.json` 在**第一次读取时自动迁移到 v4** 并写回，无需手动操作：

| 旧版本 | 旧结构 | 迁移后 |
|---|---|---|
| v1 | 顶层平铺 `baseUrl` + `token` | 该环境成为默认环境，令牌成为该环境下的一个账号 |
| v2 | 按环境存令牌，无 `apiKey` | 每个环境的令牌成为该环境下的一个账号 |
| v3 | 按环境存令牌（含 `apiKey`） | 同上，`apiKey` 原样保留 |

迁移**保留原有全部字段**（令牌、`apiKey`、默认环境等），只补齐 v4 所需的账号集合与 `defaultAccount`；
加 `--verbose` 可以看到迁移日志（不静默改写你的文件）。

### 本地依赖：ffmpeg（音频派生 + 分镜拼接 + 网格切图）

`derive audio-separation` / `derive audio-process`（抽音轨、去音轨、截取、变速）、
`storyboard stitch`（分镜拼图合成）与 `derive from-grid`（网格切图）在**本地**用 ffmpeg 处理媒体，
其余命令完全不需要 ffmpeg。

**CLI 不内置 ffmpeg**，请先安装系统版：

```bash
# macOS
brew install ffmpeg
# Ubuntu / Debian
sudo apt update && sudo apt install -y ffmpeg
# Windows（任选其一）
winget install --id Gyan.FFmpeg
# 或从 https://www.gyan.dev/ffmpeg/builds/ 下载后把 bin 目录加进 PATH
```

安装后验证：

```bash
ffmpeg -version
moliai doctor        # ffmpeg 项应为 pass
```

不想改 PATH？用 `--ffmpeg <path>` 或 `MOLIAI_FFMPEG` 指定路径。

解析优先级（**显式失败，不静默兜底**）：

```
--ffmpeg <path>            （命令行，最高）
  > MOLIAI_FFMPEG            （环境变量）
  > PATH 里的 ffmpeg         （系统安装）
  > 都没有 → MOLIAI_UNSUPPORTED（退出码 5），hint 给出分平台安装指引
```

- **ffprobe 是可选的**：探测时长时能拿到 ffprobe 就用它，没有则回退解析 `ffmpeg -i` 的 stderr；
  想指定路径可以设 `MOLIAI_FFPROBE=<path>`
- `moliai doctor` 的 `ffmpeg` 检查项会显示来源（`系统` / `指定`）、版本与路径；缺失时是 `warn`
  （只影响音频派生 / 分镜拼接 / 网格切图，不影响其它命令）
- 单文件二进制与 npm 包的行为一致：都不自带 ffmpeg（产物约 110MB）

> ⚖️ **音频输出固定 PCM wav**：不使用 mp3 编码器（许可证红线），变速只用原生 `atempo` 滤镜；
> 视频一律流复制（`-c:v copy`），不解码也不编码。

## 五分钟跑通（零成本）

> **项目从哪来**：已有项目用 `moliai project list` 取 `projectId`；还没有项目时用
> `moliai project create "<项目名>"` 创建（CLI 只支持 `canvas`/无限画布模式，会顺带建一张同名画布，见「命令清单 → 项目」）。

```bash
moliai status                 # 看配置目录、版本、登录状态、后端连通性
moliai project list           # 列出你的项目，拿到 projectId（没有项目就先 project create）
moliai canvas list -w <projectId>   # 列出该项目下的画布
moliai canvas use <canvasId>  # 把画布绑定到当前目录（之后命令可省略画布参数）
moliai node list              # 看这张画布上已有的节点
moliai model list --type video      # 看你的账号能用哪些模型
```

除 `project create` 外，这几步都不产生费用，也不修改任何数据。

## 命令清单

全局选项对每条命令都有效：

```bash
--output <json|ndjson|text>   # 输出格式，默认 json
--json                        # 等价于 --output json（优先级更高）
--compact                     # 单行紧凑 JSON
--quiet                       # 静默 stderr 上的进度信息
--verbose                     # stderr 输出调试信息
--trace-id <id>               # 指定成功信封的 traceId（默认随机生成；失败信封用服务端 traceId）
--fields <list>               # 只输出 data 里的指定字段，支持 a.b 与 a[].b
--base-url <url>              # 本次调用使用的后端地址（优先级最高）
--poll-interval <seconds>     # 轮询间隔（秒），默认 2；取值 0.5-60，支持小数
--no-estimate                 # 跳过费用预估（--max-cost 与余额预校验不会生效）
--retry <times>               # 失败重试次数，仅只读 GET 请求（网络错误 / 5xx / 429）；默认 0，上限 5
-V, --version                 # 版本
```

- `--poll-interval` 影响 `wait` / `task watch` 以及生成类命令的轮询节奏
- `--no-estimate` 会同时使**成本闸门**与**余额预校验**失效，因此与 `--max-cost` 互斥（同时传直接报 `MOLIAI_ARG_INVALID`）
- `--retry` **需要次数**（`--retry 3`，不是布尔开关）；写命令（POST / PATCH / DELETE）永不重试，只提示

### 认证

| 命令 | 说明 | 最小示例 |
|---|---|---|
| `login key` | 用网页「开发者配置」里的 KEY 换取令牌并保存（推荐；读前会提示粘贴，非交互环境用管道） | `"<KEY>" \| moliai login key --base-url "https://dance.aidancevid.com/api"` |
| `login token` | 直接粘贴一个 access token（备用路径） | `"<token>" \| moliai login token --base-url "<url>"` |
| `login web` | 浏览器授权登录（授权码 + PKCE）：本机起回调服务器，用网页登录态换令牌。需前端授权页实现 `/oauth/cli-authorize`；不提供该页时继续用 `login key` | `moliai login web --base-url "https://dance.aidancevid.com/api"` |
| `logout` | 删除本地凭据（所有环境） | `moliai logout` |
| `env` | 列出已登录的环境、默认环境与本次实际环境 | `moliai env` |
| `env use <url>` | 把某环境设为默认（不用重新登录） | `moliai env use "https://dance.aidancevid.com/api"` |
| `env remove <url>` | 删除某环境的凭据 | `moliai env remove "https://dance.aidancevid.com/api"` |
| `account list` | 列出当前环境的账号（默认账号单独标出；不显示 token / KEY） | `moliai account list` |
| `account use <标识>` | 切换当前环境的默认账号（标识可为 userId / 昵称 / 账号 id；昵称重复时用 userId） | `moliai account use cjf` |
| `account remove <标识>` | 删除账号（需 `--yes`；不能删最后一个账号） | `moliai account remove cjf --yes` |
| `whoami` | 打印当前身份、令牌过期时间与**真实余额**（`balance`） | `moliai whoami` |
| `status` | 打印宿主、配置目录、版本、后端连通性 | `moliai status` |

### 安装与自检

| 命令 | 说明 | 最小示例 |
|---|---|---|
| `setup` | 把 MoliAi Skill 安装到 Agent 宿主目录 | `moliai setup --agent all --dry-run` |
| `setup --upgrade` | 自更新 CLI（等价于 `moliai update`） | `moliai setup --upgrade --dry-run` |
| `update` | 自更新：检测版本、下载、校验 SHA256、替换二进制 | `moliai update --check` |
| `update config` | 查看/持久化自更新仓库 | `moliai update config --repo <owner/repo>` |
| `doctor` | 环境自检：本机（Node 版本、配置目录、宿主、沙箱信号）+ 连接环境（网关、token、画布、模型清单） | `moliai doctor` |
| `diagnose` | 画布内容只读体检：优先调后端 Doctor 接口（`empty` / `failed` / `rerunnable`），后端未提供该端点时降级为本地扫描（仅 `empty` + `failed`，`data.source=local`） | `moliai diagnose --out report.json` |
| `help` | 命令树（人类可读；加 `--json` 输出结构化命令树） | `moliai help --json` |
| `schema <command>` | 单条命令的结构（参数、默认值、可选值、输出字段） | `moliai schema run` |

`setup` 支持 `--agent claude|codex|dsh|generic|all`、`--scope user`、`--check`、`--dry-run`、`--target-dir`，
以及 `--upgrade`（自更新，可配合 `--repo` / `--force` / `--dry-run`）。
`--uninstall` / `--quarantine` / `--dir` / `--set` / `--scope project` 尚未实现，使用时会明确报「不支持」。

`update` 支持 `--check`、`--dry-run`、`--repo <owner/repo>`、`--force`；`update config --repo/--show` 管理仓库配置。
Windows 下替换由 `.update.bat` 在 CLI 退出后完成（`replaced: false`），详见「升级（自更新）」。

#### `doctor` 的检查项

`doctor` 只判断「本机与连接环境能否用」，**不检查画布内容**（画布内容体检是 `moliai diagnose` 的职责，见下一节）。
每项结果为 `pass` / `warn` / `fail`；`healthy = (fail 数 === 0)`（`warn` 不算不健康）。联网检查并行发起、单项 3 秒超时，整条命令通常在 1 秒内结束。

| 检查项 | 类型 | 判定 |
|---|---|---|
| `node-version` | 本机 | Node 主版本 ≥ 20 为 `pass`，否则 `fail` |
| `config-dir-writable` | 本机 | 配置目录（`~/.moliai`）写探针成功为 `pass`，否则 `fail` |
| `host-detection` | 本机 | 识别到 claude / codex / dsh 宿主为 `pass`，未识别为 `warn` |
| `network-sandbox` | 本机 | 无沙箱网络限制信号为 `pass`，检测到为 `warn` |
| `gateway-reachable` | 联网 | `GET /user/profile` 2xx → `pass`（带延迟）；401/403 → `warn`（网关通但鉴权有问题）；其它状态/网络错误 → `fail`（区分超时 / DNS / TLS / 连接被拒） |
| `token-validity` | 本机（读凭据） | 无 token → `fail`；已过期 → `fail`（保存了有效 API KEY 时降为 `warn`，下次请求会自动续期）；剩余 < 24 小时 → `warn`；正常 → `pass`。消息里说明是否会自动续期：存了 KEY → 「剩余不足阈值自动续期」；KEY 被后端拒绝过 → 「需重新 login key」；没存 KEY → 「过期后需重新登录」。doctor 本身**不发起续期请求** |
| `canvas-access` | 联网 | `GET /canvases/{id}`：正常 → `pass`；404 → `fail`；`readOnly=true` 或 `canvasPurpose=subject` → `warn`；未指定画布 → `warn`。**只读判断，不建探测节点** |
| `models-available` | 联网 | `GET /user/models` 有模型 → `pass`（带数量与各模态分布）；为空 → `warn`；拉取失败 → `fail`；同时统计 `/cli/models` 中有参数契约（`schemaAvailable`）的模型数 |
| `cli-version-compatible` | 联网 | `GET /cli/version`（公开端点，匿名请求）比对本地 CLI 版本与后端 `minVersion`：满足 → `pass`；低于最低版本 → `fail`（消息给 `recommendedVersion` 与 `moliai update`）；404 / 401 / 网络失败 / 响应缺字段 → `warn`（「无法检查」，不阻断其它检查项） |

- `--offline`：只跑前 4 项本机检查，跳过所有联网检查（离线环境下也能自检）。
- 无法判断时（例如 token 不是标准 JWT、没有 `exp`）显式输出 `warn` 并说明原因，不会静默当 `pass`。

#### `diagnose` 的检查项（优先后端 Doctor，失败降级本地扫描）

```bash
moliai diagnose [canvasId] [--out report.json]
```

`diagnose` 是**只读**命令：无 `--fix`、无 `--yes`、不自动重跑、不写任何业务数据、零扣费。
`canvasId` 省略时用 `MOLIAI_CANVAS` 或目录绑定。

数据来源由 `data.source` 明确标注：

| `source` | 请求 | 覆盖分类 |
|---|---|---|
| `server` | `GET /canvases/{id}`（确认存在）→ `POST /canvases/{id}/doctor/reports`（`{"scope":"all"}`，201） | `empty` / `failed` / `rerunnable`；`refError` / `orderRisk` 由后端在 `notImplemented` 中声明未实现 |
| `local` | `GET /canvases/{id}` + 每个失败节点一次 `GET /tasks/{taskId}` | 仅 `empty` / `failed`；`rerunnable` / `refErrors` / `orderRisks` 恒为空数组 |

**降级判定（只有一种情况降级）**：先 `GET` 确认画布存在；`POST` 返回 404 且 `serverCode`
不是业务码（缺失或 `NOT_FOUND`）→ 视为后端没有该路由 → 降级本地扫描，并在 `warnings` 中
明确写出「后端未提供 Doctor 接口，使用本地扫描（仅 empty + failed）」（不静默）。

| 后端响应 | 行为 |
|---|---|
| `POST` 2xx | `source: "server"`，用后端 `issues` 分组 |
| `POST` 404 + `DOCTOR_*` / `CANVAS_*` 等业务码 | 如实报错，**不降级** |
| `POST` 404 且无业务码 / `NOT_FOUND` | 降级本地扫描，`source: "local"` + warning |
| `POST` 5xx / 401 / 403 / 网络错误 | 如实报错，**不降级**（可能是后端故障，不是未实现） |

分类口径（后端与本地扫描一致）：

| 分类 | 判定 |
|---|---|
| `empty` | 无内容 **且** 无任务（`taskId` 为空）。text 节点看 `content` 是否空白；其余类型看 `mediaUrl` / `mediaId` / `content` 是否全空 |
| `failed` | 节点 `status=failed` 且有 `taskId`，取错误码映射 `failReason`（后端模式下 `failReason` 由后端映射好，直接用） |
| `rerunnable` | `status=failed` + 有 prompt + 有 model + 无运行中任务（**仅后端模式**；本地扫描无此项） |

`failReason` 映射（本地扫描口径；先看业务 `errorCode`，未登记再看系统级 `error.code`，都没登记才是 `unknown`）：

| failReason | 来源错误码 |
|---|---|
| `compliance` | `SENSITIVE_CONTENT` |
| `reference_limit` | `TOO_MANY_REFERENCE_IMAGES` |
| `cancelled` | `TASK_CANCELLED` |
| `invalid_request` | 提交期拦截类：`MODEL_UNSUPPORTED` / `TASK_TYPE_MISMATCH` / `COUNT_OUT_OF_RANGE` / `CONTEXT_NODE_INVALID` |
| `unknown` | 未登记的错误码，或任务没有错误码 |

`failed[].remediation` 可直接复制执行：后端模式用后端给出的命令（如 `moliai run "<节点名>" --rerun-failed`），
本地模式用 `moliai run "<节点名>"`（节点无名称时用 nodeId）。

输出结构（`--out` 落盘内容与 stdout 的 `data` 完全相同；两种来源字段一致）：

```json
{ "ok": true, "data": {
  "source": "server",
  "canvasId": "...", "canvasVersion": 123,
  "reportId": "rpt-a3f9c2e1",
  "generatedAt": "2026-11-24T10:30:00Z", "expiresAt": "2026-11-24T11:30:00Z",
  "summary": { "empty": 1, "failed": 1, "rerunnable": 1, "refError": 0, "orderRisk": 0 },
  "empty":     [{ "nodeId": "...", "name": "..." }],
  "failed":    [{ "nodeId": "...", "name": "...", "taskId": "...", "failReason": "compliance", "remediation": "moliai run \"镜头-03\" --rerun-failed" }],
  "rerunnable":[{ "nodeId": "...", "name": "..." }],
  "refErrors": [], "orderRisks": [],
  "notImplemented": ["refError", "orderRisk"]
}}
```

- `source: "local"` 时：`reportId` 形如 `report-<8位hash>`（CLI 本地生成），`expiresAt` 为 `null`，
  `rerunnable` 恒为空，`notImplemented` 为 `["rerunnable","refError","orderRisk"]`，并带降级 warning。
- `source: "server"` 时：`reportId` 是后端 `rpt-*`，报告有效期 1 小时（过期后重新执行即可，不复用旧 id）。
- 节点 `status=failed` 但没有 `taskId`（无法映射 `failReason`）不会静默丢弃，会在 `warnings` 里点名列出（本地扫描）。
- 本地模式下某个失败节点的任务详情查不到（接口报错/缺 `task` 字段）时整条命令显式失败，不伪造 `unknown`。


### 项目

| 命令 | 说明 | 最小示例 |
|---|---|---|
| `project list` | 列出你的项目（`--limit` 1..200，默认 20） | `moliai project list --limit 10` |
| `project create` | 创建项目（`--description` / `--mode canvas`；**仅支持 `canvas`/无限画布**，省略时默认 `canvas`；不自动写目录绑定） | `moliai project create "我的项目" --mode canvas` |
| `project update` | 修改项目名称 / 描述（`--name` / `-d, --description`；只提交显式指定的字段） | `moliai project update <projectId> --name "新名字"` |
| `project delete` | 删除项目（需 `--yes`；**不可逆**：软删项目下画布 + 删云端 COS 文件 + 删项目行） | `moliai project delete <projectId> --yes` |

> **CLI 只支持 `canvas`（无限画布）模式**：`--mode` 省略时按 `canvas` 处理（会创建一张同名画布并把 id 回填到输出的
> `canvasIds` / `canvasId`）。传统模式（`novel-promotion`）项目没有画布，CLI 对其没有任何写能力，
> 因此 `--mode novel-promotion` 会**本地直接报 `MOLIAI_ARG_INVALID`（退出码 2）且不创建项目**，请到网页端创建。
> 创建成功**不会**自动绑定当前目录，输出里的 `next` 给出下一步命令（`canvas use <canvasId>` 或
> `canvas create <name> -w <projectId>`）。参数限制与后端一致：名称 1..100 字符、描述 ≤500 字符，
> 越界直接本地报 `MOLIAI_ARG_INVALID`（退出码 2）。

### 画布

| 命令 | 说明 | 最小示例 |
|---|---|---|
| `canvas list` | 列出项目下的画布（`-w <projectId>`，省略时用目录绑定） | `moliai canvas list -w <projectId>` |
| `canvas show` | 画布详情 + 精简节点列表 | `moliai canvas show <canvasId>` |
| `canvas create` | 新建画布（不自动切换当前绑定） | `moliai canvas create "第一集分镜" -w <projectId>` |
| `canvas use` | 校验画布存在并绑定到当前目录 | `moliai canvas use <canvasId>` |
| `canvas unuse` | 解除当前目录绑定 | `moliai canvas unuse` |

### 作品发布

> **`canvas publish` 是「提交审核」，不是立即上线**：新建记录 `reviewStatus=pending`，管理员通过后才写
> `publishedAt` 并进入公开列表；审核通过前公开详情按 404 处理。**后端没有取消发布接口**（`canvas unpublish`
> 显式报 `MOLIAI_UNSUPPORTED`），要关闭公开可见只能 `--no-public --yes` 重新提审（会再次进入审核）。

| 命令 | 说明 | 最小示例 |
|---|---|---|
| `canvas publish` | 提交发布审核（PUT `publish-settings`）。`--name` 必填；`--video` 与 `--video-node` 二选一；`--public` / `--no-public` **必须显式二选一**（PUT 全量覆盖）；写操作需 `--yes` | `moliai canvas publish <canvasId> --name "我的短片" --video-node <nodeId> --public --yes` |
| `canvas publish list` | 发布列表。`--type my`（默认，需登录，含 `total`）/ `--type public`（公开池，免登录，元素是精简视图且**无 `total`**） | `moliai canvas publish list --type public --size 5` |
| `canvas publish show` | 公开发布详情（精简视图）。只有 `approved` 且上架的发布可见，未过审一律 404 | `moliai canvas publish show <publishId>` |
| `canvas publish status` | 某张画布的发布状态：拉取「我的发布」全量分页后按 `canvasId` 匹配，取不全显式失败 | `moliai canvas publish status <canvasId>` |
| `canvas publish copy` | 复制公开作品到自己账号（`clientRequestId` 自动生成，幂等） | `moliai canvas publish copy <publishId>` |
| `canvas unpublish` | 取消发布（后端无该接口，显式报 `MOLIAI_UNSUPPORTED`） | `moliai canvas unpublish <canvasId>` |

> `--video-node` 会把节点 `mediaUrl` 归一成公网 CDN 直链；`asset://` 与 `/m/{id}` 形态无法归一，
> 会显式失败并提示改用 `--video <url>`。发布输出与 `warnings` 都会声明「已提交审核、当前未对外可见」。

### 作品分享

> 分享是**项目级**：同项目所有画布共用一份策略。`GET share-settings` 在从未生成过链接时返回 `access="private"`；
> `PUT share-settings` **只接受 `access=code` + `--days 1|7|30`**，每次调用新增一条独立链接（旧链接与其授权不受影响），
> 并在响应里返回本次明文验证码。**后端没有关闭分享接口**（`canvas share disable` 显式报 `MOLIAI_UNSUPPORTED`），
> 链接只能等有效期到期自动失效。

| 命令 | 说明 | 最小示例 |
|---|---|---|
| `canvas share show` | 查询分享设置（`verificationCode` 在 GET 上恒为 `null`） | `moliai canvas share show <canvasId>` |
| `canvas share enable` | 生成新分享链接（`--days` 必填 1/7/30，`--code` 可选自定义 7 位验证码，需 `--yes`） | `moliai canvas share enable <canvasId> --days 7 --yes` |
| `canvas share access` | 查询当前账号访问状态：`allowed` / `code_required` / `expired` / `private` | `moliai canvas share access <canvasId>` |
| `canvas share verify` | 提交验证码换授权（`--code` 必填，7 位区分大小写）；返回 `allowed` / `expired` | `moliai canvas share verify <canvasId> --code aB3k9X2` |
| `canvas share open` | 读取分享项目详情；默认只给项目名与画布清单，`--with-nodes` 才带 `nodes` / `connections` / `groups` | `moliai canvas share open <canvasId> --with-nodes` |
| `canvas share copy` | 把分享项目**整项目**复制到自己账号（幂等） | `moliai canvas share copy <canvasId>` |
| `canvas share disable` | 关闭分享（后端无该接口，显式报 `MOLIAI_UNSUPPORTED`） | `moliai canvas share disable <canvasId>` |

### 节点

| 命令 | 说明 | 最小示例 |
|---|---|---|
| `node list` | 列出节点（`--type` / `--name-like` / `--status` / `--group` / `--has-result` / `--no-has-result` / `--edit-mode` / `--model` / `--sort` / `--limit`，全部客户端过滤） | `moliai node list --type image --status completed` |
| `node create` | 创建节点（`-t` 必填，`--x/--y` 必填；`-t super_resolution` 时 `--super-resolution-type` 必填；`--content` / `--edit-mode` / `--fit-mode` / `--prompt-preset` / `--layout-preset` / `--angle-preset` / `--auto-link` 可选） | `moliai node create "开场画面" -t image --x 0 --y 0` |
| `node update` | 修改名称/坐标/文本/挂载素材/编辑模式/填充模式/超分类型/预设/自动链接，以及**生成参数**（`--model` / `-s, --set` / `--clear-params`）；带 `--where` 时批量改生成参数 | `moliai node update <nodeId> -s ratio=9:16` |
| `node delete` | 删除节点：`<nodeId>` / `--where '<表达式>'` / `--ids a,b` **三选一**；`--dry-run` 预览，`--max-nodes` 控制选择器上限（**仅 `--where` 模式**，单节点模式传了会 `MOLIAI_ARG_INVALID`）；24 小时内可恢复 | `moliai node delete --where 'type=video&status=failed' --yes` |

`node create` / `node update` 的字段说明：

| 参数 | 取值 | 说明 |
|---|---|---|
| `--edit-mode <mode>` | `direct` \| `ai` | 文本/音频编辑模式。`direct`=直接编辑，**不接受上游连线**；`ai`=AI 生成，可接上游。`node create` 不传则用后端默认 `direct`，`node update` 不传则不修改 |
| `--fit-mode <mode>` | `cover` \| `contain` \| `fill` | 媒体填充模式（image/video 节点） |
| `--super-resolution-type <type>` | `image` \| `video` | 超分节点的二级类型（仅 `super_resolution` 节点）。`node create -t super_resolution` **必须**提供，否则直接 `MOLIAI_ARG_INVALID`（后端无默认值，落 null 的节点网页端会抛错）；`node update` 可选，不传则不修改；节点不是 `super_resolution` 却传该参数 → `MOLIAI_ARG_INVALID` |
| `--prompt-preset <value>` | ≤512 字符 | 生图预设风格参数，原样提交 |
| `--layout-preset <value>` | ≤512 字符 | 画面版式预设，如 `"画面版式:三视图"` |
| `--angle-preset <value>` | ≤512 字符 | 镜头角度预设，如 `"镜头角度:仰视;景别:特写"` |
| `--auto-link` / `--no-auto-link` | 布尔 | 关键词自动链接开关（后端默认 `true`）；两个都不传则不改动当前值 |
| `--model <modelKey>` | `provider::modelId` | 写入 `modelKey`（下一次生成使用的模型），如 `qwen-image::qwen-image-2.1`。`node update` 不传则不修改 |
| `-s, --set <key=value>` | 可重复 | 写生成参数 `modelParams[key]`。值**优先按 JSON 解析**：`--set count=3` → 数字 `3`，`--set flag=true` → 布尔 `true`，解析失败按字符串（`--set ratio=9:16` → `"9:16"`） |
| `--clear-params` | 布尔 | 清空该节点 `modelParams`（提交 `{}`）。与 `--set` 互斥 |

> 「建 text 节点 → 连上游」必须先把目标节点设为 `--edit-mode ai`，否则 `connection create` 会被本地规则拦住
> （`direct` 的文本节点不接受上游连线，与网页端一致）。`node list` / `canvas show` 的节点视图也带 `editMode`，便于事先确认。
>
> 超分节点必须带 `superResolutionType`（`image`=图片超分，`video`=视频超分）：`node create -t super_resolution` 不传会直接拒绝，
> 不是 warning——后端不补默认值，落成 `null` 的节点在网页端 `resolveSuperResolutionType` 处会抛错，且 `connection create` /
> `derive` 也会因缺少该字段无法判定语义。`node list` / `canvas show` / `node create` / `node update` 输出都带
> `superResolutionType`（非超分节点为 `null`），可用它确认节点能不能接某类源/目标。

节点类型可选：`text` / `image` / `video` / `audio` / `super_resolution` / `panorama_image` / `portrait_texture` / `three_view` / `nine_grid` / `video_synthesis` / `depth_capture` / `voice`。

`node list` 的过滤 / 排序参数（**全部在客户端完成**，画布详情一次拉全量；多个条件为 AND 关系）：

| 参数 | 取值 | 说明 |
|---|---|---|
| `--type <nodeType>` | 上面列出的节点类型 | 按 `nodeType` 精确匹配 |
| `--name-like <keyword>` | 任意文本 | 按名称子串匹配，忽略大小写（无名称的节点不匹配） |
| `--status <status>` | `idle` \| `generating` \| `completed` \| `failed` | 按 `status` 精确匹配；其它取值本地直接拒绝（后端值域只有这四个） |
| `--group <groupRef>` | groupId 或组名 | 只保留该编组的成员节点（读同一份 `groups[].memberNodeIds`）；组名不唯一时报错并列出候选，组不存在也报错 |
| `--has-result` / `--no-has-result` | 布尔 | `mediaUrl` 非空即「有产物」。注意 `super_resolution` / `depth_capture` 等节点同样可能有 `mediaUrl` |
| `--edit-mode <mode>` | `direct` \| `ai` | 按编辑模式精确匹配 |
| `--model <modelKey>` | `provider::modelId` | 按「下一次生成使用的模型」精确匹配：`modelKey` 优先，为空时回退 `generationModel`（与 `--where model=` **同一取值规则**） |
| `--sort <field>` | `name` \| `type` \| `status` \| `x` \| `y` | 单字段升序（`x`/`y` 按 `posX`/`posY`）；空值排最后，同值按 `nodeId` 稳定排序 |
| `--limit <n>` | 1..1000 | **排序后**截断前 n 条（默认不截断） |

> **`node list` 的专用参数 vs `--where`**：两者是**互补**关系，不是重复实现。
> `node list` 是**只读查询**，专用参数（`--type` / `--status` / `--model` … ）直接映射到列表视图字段，另提供
> `--sort` / `--limit` 这类只对查询有意义的参数；`--where '<表达式>'` 出现在**写/执行命令**
> （`node update` / `node delete` / `run` / `group run`）里，按选择器统一求值并带命中上限确认。
> 同一个条件两边规则一致（例如 `--model` 与 `--where model=` 都按 `modelKey` 优先、回退 `generationModel`），
> 因此可以先用 `node list` 预览命中范围，再把等价表达式交给写命令。

> **ID 参数本地格式校验**：`node update <nodeId>` / `node delete <nodeId>` / `task get <taskId>` /
> `task cancel <taskId>` **只接受 UUID**，传非 UUID（例如把节点名当 id）会在本地直接报
> `MOLIAI_ARG_INVALID`「不是合法的 UUID：xxx」，而不是被报成「画布中找不到节点」或服务端 404。
> 接受「节点引用」的地方（`run <nodeRef>` / `extract <nodeRef>` / `derive <nodeRef>` /
> `node delete --ids`）不做该限制——它们允许传名称或 id 列表。

输出结构为 `{ nodes, total, matched, filters }`：

- `nodes`：过滤 + 排序 + 截断后的节点（字段与 `canvas show` 的节点视图一致，`nodes` 字段本身未变）
- `total`：过滤前画布节点总数
- `matched`：过滤后、**截断前**的命中数（配合 `--limit` 判断是否被截断）
- `filters`：本次实际生效的条件（未使用的条件不出现，例如 `{"type":"image","status":"completed"}`；`--has-result` 记为 `hasResult: true/false`）

#### `node update` 的生成参数与 `--where` 批量改参数

两个入口**互斥**：位置参数 `<nodeId>`（单个，走 `PATCH /api/canvases/{canvasId}/nodes/{nodeId}`）与
`--where '<表达式>'`（批量，走 `PUT /api/canvases/{canvasId}/nodes/batch`）。同时给两个 → `MOLIAI_ARG_INVALID`。

```bash
# 单个节点
moliai node update <nodeId> --model qwen-image::qwen-image-2.1
moliai node update <nodeId> -s ratio=9:16 -s count=3
moliai node update <nodeId> --clear-params

# 批量（与 node delete 的 --where 一致，见下一节选择器语法）
moliai node update --where 'type=image&group=第01集' -s ratio=9:16 --dry-run
moliai node update --where 'type=image&group=第01集' -s ratio=9:16
moliai node update --where 'name~镜头-&model=ark::doubao-seedance-2.0' -s duration=5 --max-nodes 10 --yes
```

**`modelParams` 合并语义（重要）**：后端对**普通节点**是把请求里的 `modelParams` **整体替换**库中值
（只有 `video_continuation` 续写节点与 `voice` 节点在服务端逐键合并）。所以 CLI 在提交前会先读节点当前
`modelParams`，本地合并后再提交完整对象——`node update <id> -s duration=5` **不会**清掉已有 `ratio`。这一点无需用户操心。

批量模式参数：

| 参数 | 说明 |
|---|---|
| `--max-nodes <n>` | 命中数上限（缺省 20，1..1000）。命中数超过上限且没带 `--yes` → `MOLIAI_CONFIRM_REQUIRED`（退出码 10）；带 `--yes` 时**只处理前 n 个**，输出 `truncated: true` 并在 `warnings` 明确提示其余节点未改动 |
| `--dry-run` | 只预演（不提交、无需 `--yes`，单节点与批量都支持）；同样做语法解析、命中求值与逐节点参数合并 |
| `--diff` | 让 `diff.changes` 展开成「只列真正变化的字段」（必须配合 `--dry-run`） |
| `--yes` | 确认超出 `--max-nodes` 的范围（仅批量模式有效；单节点模式传了会 `MOLIAI_ARG_INVALID`） |

批量模式必须至少给出 `--set` / `--model` / `--clear-params` 之一，否则 `MOLIAI_ARG_INVALID`；
命中 0 个同样报 `MOLIAI_ARG_INVALID`（批量改参数静默成功会让人以为改了）。

输出结构：`{ dryRun, canvasId, matched, updated, failed[], nodes[{nodeId,name,nodeType,modelKey,modelParams}], canvasVersion, truncated }`
（`--dry-run` 多一个逐节点 `diff[]`，见下一节）

- `matched`：`--where` 命中的节点总数（截断前）
- `updated`：**回读校验后**确认已生效的节点数（写完后重新拉画布详情，逐节点比对 `modelKey` / `modelParams`）
- `failed[]`：回读未生效的节点及原因。后端批量端点本身是 all-or-nothing（任一节点不属于本画布即整批 400），
  所以这一项只在「后端返回成功但回读值与提交值不一致」时出现，不会隐藏为成功
- 单节点 `node update` 的输出新增 `modelKey` / `modelParams`（后端回执的最终值），可直接确认参数是否落库

#### 写操作预演：`--dry-run --diff`（只列变化字段）

写命令都支持「先预演、再执行」。`--dry-run` 零写入（不发 PATCH/PUT），`--diff` 让 `changes` 展开成
**只列真正变化的字段**（未变化的不出现）；`--diff` 单独使用会直接报 `MOLIAI_ARG_INVALID`（退出码 2）：
`--diff` 只描述「如果执行会改哪些字段」，不会偷偷替用户打开预演。

> ⚠️ **`--diff` 语义分叉（刻意如此，不是 bug）**：
> - `apply` 的 `--diff` **可独立使用**：不带 `--dry-run` 也照常执行，并输出字段级明细；
> - 其他命令（`node update` / `group update` / `connection update` / `storyboard config`）的 `--diff`
>   **必须配合 `--dry-run`**，单独使用报 `MOLIAI_ARG_INVALID`。
>
> 差异来源：`apply` 是先输出计划再落库的幂等工作流，明细本身就是它的主输出；写命令则区分
> 「预演」与「真改」，不允许 `--diff` 顺带开启预演或反向触发写入。

| 命令 | 预演参数 | 输出 |
|---|---|---|
| `node update <nodeId>` | `--dry-run [--diff]` | `{ mode:"dry-run", nodeId, canvasId, diff }` |
| `node update --where '<表达式>'` | `--dry-run [--diff]` | 上述批量结构 + `diff[{ nodeId, name, before, after, changes }]` |
| `group update <groupRef>` | `--dry-run [--diff]` | `{ mode:"dry-run", groupId, canvasId, diff }` |
| `connection update <connId>` | `--dry-run [--diff]` | `{ mode:"dry-run", connectionId, diff }` |
| `storyboard config <groupRef>` | `--dry-run [--diff]` | 原有预演结构 + `diff` |
| `apply -f plan.json` | `--dry-run --diff` | 计划级 `diff`（见 `apply` 章节，历史行为不变） |

`diff` 段与 `apply` 同一形态：`before` / `after` 只含**本次要改的字段**，`changes` 只含**真正变化**的字段。

```bash
moliai node update <nodeId> --name "新名" --x 200 --dry-run --diff
```

```json
{
  "mode": "dry-run",
  "nodeId": "…",
  "canvasId": "…",
  "diff": {
    "before": { "name": "旧名", "posX": 100 },
    "after":  { "name": "新名", "posX": 200 },
    "changes": {
      "name": { "from": "旧名", "to": "新名" },
      "posX": { "from": 100, "to": 200 }
    }
  }
}
```

语义约定：

- **只比较本次显式给出的字段**（`after` 只含请求体里的字段），没写的字段一律不动，也不会出现在 `diff` 里
- **`null` 与「不改」严格区分**：`null` 是显式清空（`--clear-name` → `changes.name = { from: "旧名", to: null }`），
  而「没传该参数」不会产生任何条目
- 数组/对象**深比较**（键排序后比对），所以 `modelParams` 只改了 `duration` 时也只在 `changes` 里出现 `modelParams` 一项
- 命中的字段值没变 → `changes: {}`（预演成功但「没有要改的东西」，不是错误）
- `group update --dry-run` 不把 `expectedCanvasVersion` 算进对照（并发控制字段，不是变更内容）

> 形态说明：需求原文写作 `moliai node --where ... -s ...`（不带子命令），CLI 采用
> `moliai node update --where ...`，与 `node delete --where` 保持一致——`node` 是命令组，
> 在组上挂写入参数会让 `node` 裸命令也具备写入副作用，且 `-s/--set` 与 `--where` 的归属不清。

#### `node delete` 的三种目标方式与 `--where` 选择器

三个入口**互斥**（同时给多个 → `MOLIAI_ARG_INVALID`），都走同一个批量端点
`POST /api/canvases/{canvasId}/node-deletions`（幂等信封，24 小时内可恢复）：

| 入口 | 写法 | 说明 |
|---|---|---|
| 位置参数 | `moliai node delete <nodeId> --yes` | 单个节点；nodeId 必须存在，否则本地拒绝 |
| 选择器 | `moliai node delete --where 'type=video&status=failed' --yes` | 按表达式批量选中；命中 0 个报 `MOLIAI_ARG_INVALID`（不静默成功） |
| id 列表 | `moliai node delete --ids id1,id2 --yes` | 逗号分隔，最多 200 个；本地不存在的 id 只进 `warnings` 并跳过 |

> 批量模式不接受位置参数（画布请用 `MOLIAI_CANVAS` 环境变量或 `moliai canvas use` 绑定），
> 否则第一个位置参数会被当成 nodeId 与 `--where` / `--ids` 冲突。

`--where` 表达式：`字段 运算符 值`，多个条件用 `&` 连接（**全部 AND**）；运算符只有 `=`（精确等于）与
`~`（子串包含，忽略大小写）。值按**第一个**运算符切分后整体取值，因此 `ark::doubao-seedance-2.0`、
中文、`-`、值内的 `=` 都不需要转义。

| 字段 | 对应后端字段 | 可用运算符 | 说明 |
|---|---|---|---|
| `type` | `nodeType` | `=` `~` | 节点类型，如 `video` / `text` |
| `status` | `status` | `=` `~` | 值域 `idle` / `generating` / `completed` / `failed` |
| `name` | `name` | `=` `~` | `~` 忽略大小写；`=` 为精确匹配（区分大小写）；无名称节点不匹配 |
| `group` | `groups[].name`（按 `memberNodeIds` 反查） | `=` `~` | 节点不在任何编组时组名为空串，因此不会被非空条件命中 |
| `model` | `modelKey`（为空时回退 `generationModel`） | `=` `~` | 留空 `modelKey` 的节点按 `generationModel` 参与匹配 |
| `hasResult` | `mediaUrl` 非空 | 仅 `=` | 取值只能是 `true` / `false`（写 `~` 或其它值 → 选择器错误） |
| `editMode` | `editMode` | `=` `~` | `direct` / `ai` |

示例：

```bash
moliai node delete --where 'type=video&status=failed' --dry-run   # 先看会删哪些
moliai node delete --where 'name~镜头-&group=第01集' --yes
moliai node delete --where 'model=ark::doubao-seedance-2.0' --yes
moliai node delete --where 'hasResult=false' --max-nodes 5 --yes
```

约束：

- 表达式语法错误 / 未知字段 / 空条件 / `hasResult` 非法取值 → `MOLIAI_SELECTOR_INVALID`（退出码 2），`details` 给位置与允许值
- 命中数 > `--max-nodes`（缺省 20）且没带 `--yes` → `MOLIAI_CONFIRM_REQUIRED`（退出码 10），`details.candidateNodes` 列出前 N 个
- `--dry-run` 不提交删除、无需 `--yes`，但依然做语法解析、命中求值与名称解析
- 输出结构：`{ dryRun, matched, deleted, deletionOperationId, nodes[{nodeId,name,nodeType}], restoreHint }`。
  **后端一次请求只返回一个 `deletionOperationId`（不提供逐节点 opId）**，恢复按整批执行，`restoreHint` 里给出恢复端点


### 连线

| 命令 | 说明 | 最小示例 |
|---|---|---|
| `connection create` | 建手工连线（起点/终点支持 nodeId 或节点名；同 source+target 幂等） | `moliai connection create "上游" "下游" --label "节奏"` |
| `connection list` | 列出连线（`--source` / `--target` / `--type manual\|derivation`） | `moliai connection list --source "上游"` |
| `connection update` | 改连线样式（`--label` / `--style` / `--color` / `--arrow` / `--no-arrow`）；`--dry-run --diff` 可先看前后对照 | `moliai connection update <connId> --color "#ff0000"` |
| `connection delete` | 删单条（`--yes`）或批量（`--ids`，幂等 + 24h 可恢复） | `moliai connection delete --ids id1,id2 --yes` |
| `connection restore` | 恢复批量删除的连线（24 小时内） | `moliai connection restore <deletionOperationId>` |

后端不拦的规则由 CLI 兜住：自环、节点 `uploading`/`generating`、类型矩阵、voice 入线、
`editMode=direct` 的文本入线、派生节点入线、audio 双向特例、超分语义与单上游、**全图环检测**。
`connection create` 输出带 `duplicate`：后端幂等命中既有边时为 `true`（不推进画布版本）。

**连线规则按网页端逻辑类型对齐（2026-11-20 重写）**：后端通用建线端点不校验类型矩阵，
本地校验是唯一防线，所以 CLI 先把后端 `nodeType` 映射到网页端的 7 个逻辑类型
（`CanvasNodeType`），再用网页端 `connectionRules.ts` 的 `ALLOWED_CONNECTIONS` 判类型：

| 后端 nodeType | 前端逻辑类型 |
|---|---|
| `image` / `panorama_image` / `portrait_texture` / `three_view` / `nine_grid` | `image` |
| `video` / `depth_capture` | `video` |
| `text` / `audio` / `voice` / `super_resolution` / `video_synthesis` | 同名 |

所以 `text → panorama_image` / `three_view` / `nine_grid` / `portrait_texture` 全部放行（都算 `text → image`），
`depth_capture` 按 `video` 处理（如 `depth_capture → text` 被拒），与网页端完全一致。
矩阵之外的旧写法（为 4 个预设图节点单独加 target 白名单）已删除。

语义层同步对齐前端 `isValidCanvasDataConnection`：

- **超分目标**：`audio`/`voice` 源只能连视频超分；其余源的语义必须等于超分的 `superResolutionType`
  （`image` 源只能连图片超分，`video` 源只能连视频超分）
- **超分上游**：一个超分节点只允许一个上游素材，已有其它上游时拒绝
- **视频合成目标**：只接收视频语义上游；图片超分语义是 `image`，连入会被拒
- **超分源**：图片超分只能连 `text` / `image` / `video`，视频超分只能连 `video`
- **视频续写目标**：接受手工入线，但源不能是 `video_synthesis` 或文本语义
- **派生节点入线**：`video_edit` / `video_audio_separation` / `audio_processing`、
  `depth_capture`（非「从生成历史插入」）、`text` + `sourceAssetType=text-extraction`、
  `video` + `sourceAssetType=synthesis-editor-export` 均拒绝手工入线

`nodeType` 无法映射到逻辑类型（未知类型）时跳过矩阵与语义判定，不新增拒绝。

`connection delete` 两种形态语义不同：

- 单条 `DELETE /connections/{connId}` **非幂等**，已删再删返回 404；普通边不返回
  `X-Deletion-Operation-Id`，因此**没有恢复入口**（输出 `deletionOperationId: null` 并附警告）。
- 批量 `POST /connection-deletions` **幂等**（`clientRequestId` 必填，省略时 CLI 生成 UUID v4），
  返回 `deletionOperationId`，24 小时内可用 `connection restore` 恢复，超期 410。

### 编组（group）

| 命令 | 说明 | 最小示例 |
|---|---|---|
| `group list` | 列出画布编组（`--type NORMAL\|STORYBOARD`，过滤在客户端完成） | `moliai group list` |
| `group show` | 查看单个编组（groupId 或**组名**；组名不唯一时报错并列出候选） | `moliai group show "第一幕"` |
| `group create` | 建普通编组（成员 ≥ 2；frame 默认按包围盒 + 28px 自动算） | `moliai group create "A" "B" "C" --name "第一幕" --color "#3B82F6"` |
| `group update` | 改名称/颜色/编组框（`--clear-name` 清空名称）；`--dry-run --diff` 可先看前后对照 | `moliai group update <groupId> --name "改名"` |
| `group delete` | **默认只解组**（节点保留）；`--with-members` 整组删（可恢复） | `moliai group delete <groupId> --yes` |
| `group add-member` | 追加成员（后端拒绝跨组归属） | `moliai group add-member <groupId> "D"` |
| `group remove-member` | 移除成员（**带 body 的 DELETE**，节点仍保留在画布） | `moliai group remove-member <groupId> "D"` |
| `group merge` | 合并 ≥2 个普通编组为一个新编组 | `moliai group merge <g1> <g2> --yes` |
| `group restore` | 恢复整组删（24 小时内） | `moliai group restore <restoreOperationId>` |
| `group run` | **按顺序批量执行组成员**（默认只预览、零扣费；`--execute` 才真跑） | `moliai group run "第一幕"` → 确认后 `moliai group run "第一幕" --execute` |

#### `group run`：整组批量执行

> ⚠️ **和 `run` 的三处默认值完全相反，先看清再用**
>
> | | `run`（单节点） | `group run`（整组） |
> |---|---|---|
> | 默认是否扣费 | **默认真跑**，`--dry-run` 才预览 | **默认只预览**，`--execute` 才真跑 |
> | 连线推导 | 永远不做（参考素材只来自 `--ref-*`） | **默认开启**（`--no-from-connections` 关闭） |
> | 提交节流 | 无 | **间隔 ≥ 6 秒**（网关限制 10 次/分钟） |

```bash
# 1) 预览（零扣费）：看顺序、每节点成本、跳过的节点、会带上哪些上游
moliai group run "第一幕"

# 1b) 显式写 --dry-run 也可以：与默认预览等价（no-op），便于和 run --where 统一写法
moliai group run "第一幕" --dry-run

# 2) 确认无误后真跑
moliai group run "第一幕" --execute

# 3) 只重跑失败的成员（远端 status=failed，或本地有该节点的失败作业记录）
moliai group run "第一幕" --execute --rerun-failed

# 4) 按连线拓扑顺序跑（跨组连线忽略并告警；有环直接报错）
moliai group run "第一幕" --order topological

# 5) 并发跑（必须关掉推导：并发时上游产物还没就绪，下游会拿到旧数据）
moliai group run "第一幕" --execute --concurrency 3 --no-from-connections
```

| 参数 | 取值 | 说明 |
|---|---|---|
| `--execute` | 布尔 | 真提交；不带时只预览（零扣费） |
| `--dry-run` | 布尔 | 与默认预览等价（no-op，可省略）；与 `--execute` 同时给 → `MOLIAI_ARG_INVALID` |
| `--order <strategy>` | `position`（默认）/ `member` / `topological` | `position`=按坐标行优先（posY 升序、posX 次之，同坐标按编组成员原序）；`member`=编组成员顺序；`topological`=只有两端都在组内的连线参与排序 |
| `--concurrency <n>` | 1..10，默认 1 | `>1` 时必须 `--no-from-connections`，否则 `MOLIAI_ARG_INVALID` |
| `--from-connections` / `--no-from-connections` | boolean | 默认开启：把「全图所有指向本节点的上游」写进 `contextNodeIds` |
| `--continue-on-error` | 布尔 | 失败继续；默认首个失败即停 |
| `--rerun-failed` | 布尔 | 只跑失败成员：远端 `status=failed`，**或**本地有该节点的失败作业记录（覆盖 prepare 阶段被拒、远端仍 `idle` 的节点） |
| `--max-attempts <n>` | 1..100 | 配合 `--rerun-failed`：同一节点最多重跑 n 次（已重跑次数 = 本地 run 作业记录数 - 1）；**省略时不限制**（保持既有行为） |
| `--wait` / `--deadline` / `--model` / `--prompt` / `--set` | 同 `run` | 对所有节点生效 |
| `--client-request-id <uuid>` | UUID | **前缀语义**：每节点用 `<prefix>-<序号>`（整组共用一个会被后端幂等去重，第 2 个起全部丢弃） |
| `--max-cost <n>` | ≥0 的数字 | 整组预估消耗上限（魔力值）。预览合计超过上限、或**无法预估**时 `--execute` 整组零提交（`MOLIAI_BUDGET_EXCEEDED`，退出码 5），`details.nodes` 列出每节点明细。也可用环境变量 `MOLIAI_MAX_COST`（参数优先） |

**提交节流**：每次 `/generate` 之间至少 6 秒（网关限流 10 次提交/分钟）。所以 20 个节点至少要
20 × 6 秒 ≈ 2 分钟（预览里的 `estimatedSubmitMinutes` 就是算好的这个数）。并发只加速「等待与轮询」，
提交仍被串行节流。

**连线推导**（`contextNodeIds`）：后端不读画布连线表，上游关系必须由调用方显式声明。CLI 按网页端语义取
「全图所有 `target === 本节点` 的 `source`」，并排除两类上游（各给 warning，不静默丢）：

| 上游情况 | 处理 |
|---|---|
| `editMode=direct` 的文本节点 | 跳过 + warning |
| `derivationType != null` 的派生节点 | 跳过 + warning |
| 属于组外节点 | **保留**（与前端一致） |

**执行顺序与跳过规则**：默认跑所有 `status !== completed` 或没有产物的成员；`status=generating`
的成员一律跳过并告警（避免重复提交）。`STORYBOARD` 组无论传什么 `--order` 都强制用 `member`
（分组成员已按 `slotIndex` 升序），输出里的 `orderStrategyApplied` 会显示 `member`。

**跳过原因可区分**：`data.skipped[].reason` 取 `already-completed`（远端已完成且有产物）、
`already-generating`（远端生成中）、`not-failed`（`--rerun-failed` 模式下远端非 failed 且本地无失败记录）、
`max-attempts-reached`（`--rerun-failed --max-attempts N` 时该节点已达重跑上限），
`reasonDetail` 给出包含远端 `status` 的人类可读说明。

**`--rerun-failed` 为什么看本地作业记录**：prepare 阶段被拒（如 400 `REFERENCE_MEDIA_UNAVAILABLE`）时
后端**不会**把节点状态改成 `failed`（远端仍是 `idle`），也不会返回 taskId。`group run` 会把这类
「提交/准备阶段失败」落盘成一条 `status=failed`、`taskId=null` 的作业记录（`failureStage=prepare|generate`），
`--rerun-failed` 据此识别这些节点；否则用户只能全量重跑，把已完成节点重复扣费。
（`run` 单节点不写这类记录，保持原有行为。）

> ⚠️ **换机器场景**：本地没有该画布的作业记录时，CLI 无法识别「prepare 失败但远端仍 `idle`」的节点。
> 此时会在 `warnings` 里明确提示，`skipped[].reason` 全部为 `not-failed`。
> 需要重跑这些节点请去掉 `--rerun-failed` 全量执行，或在组内手动指定节点。
> 这类失败记录没有 taskId：`moliai jobs show` 会给出 `SUBMIT_FAILED` 警告，`moliai wait` 会直接报
> `MOLIAI_TASK_FAILED`（没有远端任务可等）。

**查询节流**：整组在提交前要对每个节点调 `generations/prepare` 与 `billing/estimate`，
CLI 用一个 500ms 间隔的查询闸门把它们压到 2 次/秒（网关查询限流 120 次/分钟）。
`run` 单节点**不经过该闸门**（只 prepare/estimate 各一次，加延迟没有意义）。

**成本上限（`--max-cost` / `MOLIAI_MAX_COST`）**：整组闸门在**任何节点提交之前**判定，`totalEstimatedCost`
是「本次要执行的节点」的预估合计（已跳过的节点不计入）。

- 合计 > 上限 → 整组零提交，退出码 5，`details.nodes` 给出每节点 `estimatedCost`
- 有节点无法预估成本 → `totalEstimatedCost` 记为 `null`（**不把 null 当 0**），并在 `warnings` 注明
  「N 个节点无法预估成本，上限校验不完整」；如果**全部**可执行节点都无法预估 → 整组拒绝执行
- 预览输出带 `maxCost` 与 `withinBudget`（未设上限或无法预估时为 `null`）
- 口径是**预估**：后端按 resolve 后的模型与 prepare 归一化参数计费，CLI 用同一口径预估，
  但仍不保证实扣不超（例如生成过程中参数被后端改写）

**视频节点等不到**：默认 `--wait 90`，视频实测常在 4 分钟以上，`succeeded[].status` 会是
`queued`/`processing` 且带 `mediaUrl: null`。这不是失败，用 `moliai wait <jobId>`（或
`moliai jobs --active`）分轮跟进。

**一有问题就整组不提交**：任一节点的模型/提示词/参数构建失败时，`--execute` 会以 `MOLIAI_ARG_INVALID`
拒绝，并在 `details.blockers` 里**列出全部问题节点**（不是只看第一个），`data.nodes[].warnings`
保留每节点的细粒度原因。

成员 / 合并的编组参数支持 **groupId 或组名**；成员节点支持 **nodeId 或节点名**。
`group create` / `group add-member` / `group remove-member` / `group merge` 的第一个位置参数是
变参（`<nodeRefs...>` / `<groupRefs...>`），因此**画布用 `--canvas <canvasId>` 传**，
不再用末尾位置参数（省略 `--canvas` 时仍走 `MOLIAI_CANVAS` / 当前目录绑定）。

`group create` 的编组框默认按「成员包围盒 + 28px 内边距」自动计算（与网页端
`CANVAS_GROUP_FRAME_PADDING` 一致；节点自身宽高缺失时按节点类型回落网页端默认尺寸：
text 300×209、无媒体 image/video 360×200、有媒体按 `calcNodeDimensions` 等比并 clamp、
audio 320×144 或 300×171、voice 320×76 或 320×170）。
`--x` / `--y` / `--width` / `--height` **四项独立覆盖**，只给其中一项时其余仍用自动值。

> ⚠️ **两种删除语义必须分清**
>
> - `moliai group delete <groupId> --yes`（**默认**）→ `DELETE /groups/{id}`，**只删组，成员节点全部保留在画布上**。
>   输出 `mode: "detach"` + `retainedNodeCount` + `retainedNodeIds`，`restoreOperationId` 为 `null`（解组没有恢复入口）。
> - `moliai group delete <groupId> --with-members --yes` → `POST /group-deletions`，**组 + 成员节点 + 关联连线一起删除**。
>   输出 `mode: "with-members"` + `deletedNodeCount` + `nodeNames` + `nodes`（名称/类型清单）
>   + `restoreOperationId` + `restoreExpiresIn: "24h"`。
>   不带 `--yes` 时以 `MOLIAI_CONFIRM_REQUIRED`（退出码 10）拒绝，并在 `details.nodes` 里列出将被删除的节点。

`group merge` 的 `additionalNodeIds` 固定传空数组（后端 `@NotNull`）；CLI 暂不支持把组外节点一起合并。
合并接口本身没有 `name` 字段，`--name` 会在合并成功后追加一次 `PATCH` 设置名称，并给出
`NAME_APPLIED_IN_SECOND_WRITE` 警告。

分镜组（`groupType=STORYBOARD`）在 `group list` / `group show` 中正常展示（含 `storyboard` 布局配置，
见下节）；其余写操作**本地前置拒绝**（`MOLIAI_UNSUPPORTED`，退出码 5），提示改用 `moliai storyboard` 命令。
例外一：`group update` 只改 `--name` / `--clear-name` / `--color` 时放行（后端允许），
一旦涉及 `--x/--y/--width/--height` 即拒绝。
例外二：`group delete` 对分镜组报 `MOLIAI_ARG_INVALID`，hint 指向 `moliai storyboard dissolve <groupId> --yes`
（分镜组删组走独立端点 `DELETE /storyboard-groups/{id}`，普通 `DELETE /groups/{id}` 对它会 409）。

CLI 本地兜住的编组规则：成员 < 2、节点 `uploading`/`generating`、节点已属其他组（hint 给组名与
`group remove-member` 命令）、节点属分镜组、颜色非 `#RRGGBB`、名称 trim 后为空或 > 191、
显式宽高 ≤ 0、合并源组 < 2、破坏性操作缺 `--yes`。

### 声明式搭建（apply）

`moliai apply -f plan.json` 按一份计划文件**幂等**搭建画布：上传本地素材、建节点、改生成参数、建/复用编组、连线。
在此基础上还有两个**可选阶段**（默认都不执行）：

| 阶段 | 开关 | 风险 | 说明 |
|---|---|---|---|
| 生成 | `--run` | ⚠️ **会扣费** | 建完节点后按 `left`/`context` 依赖**拓扑顺序**提交生成；复用 `group run` 的 6 秒节流与 `--max-cost` 预算闸门 |
| 清理 | `--prune` | ⚠️ **会删节点**（24h 可恢复） | 删除**同一编组内**、计划里没有的节点；必须 `--yes`，且计划必须声明 `group` |

```bash
moliai apply -f plan.json --dry-run --diff        # 只看差异：零写入、零上传
moliai apply -f plan.json                         # 只搭建（上传 → 建节点 → 改参数 → 编组 → 连线），零扣费
moliai apply -f plan.json --run --dry-run         # 搭建 + 生成报价（零写入、零扣费）
moliai apply -f plan.json --run --max-cost 10     # 搭建 + 生成（⚠️ 扣费，超预算整批不提交）
moliai apply -f plan.json --prune --dry-run       # 展示会被删掉的组内节点（零写入）
moliai apply -f plan.json --prune --yes           # 搭建 + 删除组内计划外节点（⚠️ 破坏性）
```

| 选项 | 说明 |
|---|---|
| `-f, --file <path>` | 计划文件路径（必填） |
| `--canvas <canvasId>` | 画布 id；省略时用 `MOLIAI_CANVAS` 或目录绑定 |
| `--dry-run` | 只计算并输出差异（含 `--run` 报价、`--prune` 候选），不发起任何写请求、不上传文件、不提交生成 |
| `--diff` | 输出字段级变更明细（`from`/`to`）；不加时 `update[].changes` 为空对象，其余清单照常输出 |
| `--run` | 建完节点后按依赖顺序提交生成（⚠️ 扣费；默认不生成） |
| `--prune` | 删除同组内计划外节点（⚠️ 破坏性；必须 `--yes`，计划必须声明 `group`） |
| `--max-nodes <n>` | `--prune` 删除上限（默认 20）。**候选超过上限即使带 `--yes` 也拒绝**，要显式提高上限 |
| `--max-cost <n>` | `--run` 预估消耗上限（魔力值，也可用 `MOLIAI_MAX_COST`）；无法预估或超限时整批零提交 |
| `--concurrency <n>` | `--run` 并发节点数 1..10（默认 1）。**计划内存在依赖边时只允许 1** |
| `--continue-on-error` | `--run` 某节点失败后继续后续节点（默认首个失败即停） |
| `--wait` / `--deadline` | `--run` 单节点等待秒数（默认 90）/ 任务截止秒数（默认 3600） |
| `--yes` | 确认 `--prune` 的删除（缺省以退出码 10 拒绝） |

计划格式：

```json
{
  "version": 1,
  "group": "第01集",
  "nodes": [
    { "name": "产品图", "type": "image", "upload": "./product.png", "x": 80, "y": 40 },
    { "name": "文案", "type": "text", "prompt": "写一条 15 秒耳机广告口播" },
    {
      "name": "镜头-01",
      "type": "video",
      "x": 560,
      "y": 60,
      "set": { "model": "ark::doubao-seedance-2.0", "modeType": "image2video", "ratio": "9:16", "duration": 5 },
      "left": ["产品图"],
      "context": ["文案"],
      "prompt": "把 {{Node \"产品图\"}} 中的耳机作为主体，特写开场"
    }
  ]
}
```

单个节点的全部字段：

| 字段 | 必填 | 说明 |
|---|---|---|
| `name` | ✅ | 节点名，**计划内唯一**（忽略大小写与首尾空白）；同时是画布按名称对齐的键 |
| `type` | ✅ | 后端 `nodeType`：`text` / `image` / `video` / `audio` / `super_resolution` / `panorama_image` / `portrait_texture` / `three_view` / `nine_grid` / `video_synthesis` / `depth_capture` / `voice` |
| `x` / `y` | — | 坐标。新建节点未给时按计划顺序自动排布（4 列网格，**确定性**：同一份计划重复执行得到同一坐标） |
| `upload` | — | 本地文件路径，**相对计划文件所在目录**解析。节点已有媒体时跳过重复上传 |
| `prompt` | — | 写入 `promptDraft`；支持 `{{Node "节点名"}}` 占位符（引用的节点必须能解析到计划内或画布上） |
| `content` | — | 写入 `content`（text 节点正文） |
| `set` | — | `{ "model": "provider::modelId", ...生成参数 }`：`model` 写 `modelKey`，其余键**逐键合并**进 `modelParams`（不会清掉画布上已有的其它参数） |
| `left` / `context` | — | 上游节点名称数组；两者**都落成 `connectionType=manual` 连线**，`kind` 只用于差异展示与语义区分 |
| `editMode` | — | `direct` / `ai`。`direct` 文本节点不接受上游连线，要连上游必须写 `ai` |
| `fitMode` | — | `cover` / `contain` / `fill` |
| `superResolutionType` | — | 仅 `type: super_resolution` 必填：`image` / `video`（后端无默认值） |
| `promptPreset` / `layoutPreset` / `anglePreset` | — | 预设类字段（≤512 字符，原样提交） |
| `autoLink` | — | 关键词自动链接开关（布尔） |

顶层字段：`version`（必须 `1`）、`group`（可选编组名，≤191 字符）、`nodes`（非空数组）。
**未知字段一律报错**——拼写错误（如 `promt`）不会被静默忽略。

**按名称对齐与幂等**：

- 计划节点名与画布现有节点名（trim + 忽略大小写）匹配：命中则**更新**，未命中则**新建**；重复执行不会产生重复节点。
- 画布上同名节点有**多个**时直接报 `MOLIAI_PLAN_INVALID`（名称歧义，不做任意择一，也不猜）。
- `type` 与画布已有节点不同 → **整份计划报错，不部分执行**。
- 同向连线已存在时跳过；节点已有媒体时不重复上传；参数键值相同不计入变更。
- 计划未声明的字段一律不改动（不会清空画布上已有的模型/参数/坐标/名称）。

**执行顺序（固定）**：上传 → 建节点（含初始参数） → 改已存在节点参数 → 建/复用编组 → 连线 → [`--run` 生成] → [`--prune` 删除]。

编组：`group` 同名普通组存在则复用并补加缺失成员；不存在则新建（成员为计划内全部节点，frame 按成员包围盒 + 28px 自动计算）。
同名分镜组（`groupType=STORYBOARD`）→ 报错（请用 `moliai storyboard`）；计划内节点 < 2 时声明 `group` 会报错（后端建组要求 ≥2 成员）。

**先全量校验再写**：名称唯一性、类型白名单、字段 schema、上传文件存在性、
`left` / `context` / `{{Node "名"}}` 可解析性、连线规则（类型矩阵 / `direct` 文本入线 / 超分语义与单上游 / 全图环检测）
全部通过后才开始写入。任一项不通过 → `MOLIAI_PLAN_INVALID`（退出码 2），**零写入**。

**中途失败不自动回滚**：停止后续步骤（含 `--run` / `--prune`），stdout 仍输出完整报告
`{ mode, plan, diff, executed[], failed, run, prune, rollbackHints[] }`，并按失败原因返回非 0 退出码。
`rollbackHints` 按已完成步骤给出可复制的撤销命令（`node delete` / `group remove-member` /
`connection delete` / `group delete`）；已修改的参数无法自动还原，会给出 nodeId 让人工处理。
上传过的媒体保留在画布媒体库，CLI 没有删除入口。

`--dry-run --diff` 输出示例：

```json
{
  "mode": "dry-run",
  "plan": { "version": 1, "nodeCount": 3, "group": "第01集" },
  "diff": {
    "create": [{ "name": "产品图", "type": "image" }],
    "update": [{ "nodeId": "...", "name": "文案", "changes": { "prompt": { "from": null, "to": "写一条 15 秒耳机广告口播" } } }],
    "connect": [{ "from": "产品图", "to": "镜头-01", "kind": "left" }],
    "unchanged": ["镜头-01"],
    "conflicts": []
  },
  "executed": [],
  "failed": null,
  "run": null,
  "prune": null,
  "rollbackHints": []
}
```

#### `--run`：建完即生成（⚠️ 扣费）

```bash
moliai apply -f plan.json --run --dry-run              # 先报价：预计总成本 + 执行顺序 + 每节点跳过原因
moliai apply -f plan.json --run --max-cost 10          # 确认后真跑（超过 10 魔力值整批不提交）
moliai apply -f plan.json --run --continue-on-error    # 某节点失败后继续（下游可能拿到上游旧产物）
```

**依赖顺序**来自计划里的 `left` / `context`（两者都落成 manual 连线）：

- 上游在本计划内 → 建边，上游先执行；同层节点按**计划声明顺序**执行
- 上游在本计划外（画布已有节点）→ 不建边（本次不执行它，下游用它**当前已有**的产物，并给 warning）
- 有环 → `MOLIAI_PLAN_INVALID`（在任何写入之前报错，不做猜测式排序）
- 计划内**存在依赖边时禁止 `--concurrency > 1`**（并发会拿到上游旧产物）→ `MOLIAI_ARG_INVALID`

**哪些节点会被生成**（四个硬规则，每条跳过都写进 `run.skipped[].reason`）：

| 规则 | 跳过原因 | 说明 |
|---|---|---|
| 类型不支持 | `unsupported-type` | `audio` / `super_resolution` / `depth_capture` / `voice` 不走该端点 |
| 计划声明了 `upload` | `upload-node` | 节点内容来自上传文件，不生成 |
| 远端 `generating` | `already-generating` | 正在生成，不重复提交 |
| 已有 mediaUrl | `already-completed` / `has-media` | 不覆盖已有产出（要重跑请显式 `moliai run <节点>`） |
| 文本节点 `editMode=direct` | `direct-text` | 内容由编辑写入，不提交生成 |

提交顺序与节流与 `group run` 完全一致（同一套 `batch-run` 骨架）：**6 秒/次提交节流**、每节点落 job 记录、
按 `--wait` 轮询、上游完成后下游才提交。任一节点无法构建提交请求（缺模型/缺提示词/计划参数非法）→ **整批零提交**。

输出段：

```json
{
  "mode": "apply+run",
  "run": {
    "order": ["产品图", "文案", "镜头-01"],
    "nodes": [{ "name": "产品图", "nodeId": "...", "nodeType": "image", "estimatedCost": 0.5, "contextNodeIds": [] }],
    "succeeded": [{ "nodeId": "...", "taskId": "...", "jobId": "...", "status": "completed", "mediaUrl": "..." }],
    "failed": [],
    "skipped": [{ "nodeId": "...", "name": "文案", "reason": "direct-text", "reasonDetail": "..." }],
    "blockers": [],
    "totalEstimatedCost": 1.5,
    "maxCost": 10,
    "withinBudget": true,
    "estimatedSubmitMinutes": 0.3,
    "jobIds": ["job_..."],
    "elapsedSeconds": 97
  }
}
```

`--run` 失败时：`run.failed` 照实回显、退出码非 0（`--continue-on-error` 时全部跑完再返回）；
fail-fast 中断也会保留已完成/已失败清单。

#### `--prune`：删除同组内计划外节点（⚠️ 破坏性，24h 可恢复）

```bash
moliai apply -f plan.json --prune --dry-run     # 1) 先看会删什么（零写入、无需 --yes）
moliai apply -f plan.json --prune               # 2) 不带 --yes：MOLIAI_CONFIRM_REQUIRED（退出码 10）
moliai apply -f plan.json --prune --yes         # 3) 确认执行
```

**作用范围只有「计划声明的 group」**：

- 计划没有 `group` → 直接 `MOLIAI_ARG_INVALID`「计划未指定 group，--prune 无作用范围」，**绝不默认整个画布**
- 编组尚不存在（本次会新建）→ 候选为空，不报错（warning 说明）
- 画布有多个同名编组 → `MOLIAI_PLAN_INVALID`（无法确定范围）
- 同名编组是分镜组 → `MOLIAI_PLAN_INVALID`（请用 `moliai storyboard` 维护）
- 候选 = 该组成员 − 计划节点（**组外节点永远不会被删**）

三重保护：

1. **必须 `--yes`**：缺省 `MOLIAI_CONFIRM_REQUIRED`，`details.candidates` 列出全部将被删除的节点
2. **受 `--max-nodes` 约束**（默认 20）：候选超过上限时**即使带 `--yes` 也拒绝**，必须显式提高上限（不做截断，避免半清理状态）
3. **`--dry-run` 只列清单不删除**：`prune.deleted` 为空、`deletionOperationId` 为 null

额外保护：若某个候选节点被计划引用（`left` / `context` / `{{Node "名"}}` 占位符），整次 prune 拒绝
（`MOLIAI_PLAN_INVALID`，`details.referencedByPlan` 列出引用关系）——删了它会让计划里的引用变成悬空。

删除走 `POST /canvases/{canvasId}/node-deletions`（批量、幂等、24 小时内可恢复）：

```json
{
  "mode": "apply+prune",
  "prune": {
    "groupId": "76eb434d-...",
    "groupName": "第01集",
    "maxNodes": 20,
    "candidates": [{ "nodeId": "...", "name": "旧镜头", "nodeType": "image" }],
    "deleted": [{ "nodeId": "...", "name": "旧镜头", "nodeType": "image" }],
    "deletionOperationId": "98835ade-..."
  },
  "rollbackHints": ["--prune 已删除 1 个节点（deletionOperationId=...）：24 小时内可通过 POST .../restore 恢复"]
}
```

### 分镜（storyboard）

> 本版本提供**读取**、**两种建组**、**三个破坏性清理操作**（`dissolve` / `clear` / `to-normal`）、
> **配置更新**（`config`）、**拼接输入快照**（`stitch-inputs`）、**真正拼接**（`stitch`：
> 本地 ffmpeg 合成 + 上传 + 登记），以及**成员操作**
> （`add-node` / `fill` / `move` / `detach` / `transfer`）与**整组复制**（`duplicate`）。
> `stitch` 依赖后端 `stitch-inputs` 的像素布局新字段（`cells[]` / `outputWidth` / `outputHeight`）：
> 这些字段为 `null` 时（旧构建）命令以 `MOLIAI_UNSUPPORTED` 明确报错，见下方「拼接」小节。
> 另外**用户上传的图片不能放进分镜组**（缺 `sha256`，会 422），见「已知限制」第 1、2 条。

| 命令 | 说明 | 最小示例 |
|---|---|---|
| `storyboard list` | 列出画布上的分镜组（含 `storyboard` 布局配置） | `moliai storyboard list` |
| `storyboard show` | 查看单个分镜组（groupId 或**组名**；含 rows/columns/slots） | `moliai storyboard show "第一幕分镜"` |
| `storyboard create --from-nodes` | 框选未编组图片节点**新建**分镜组（服务端自动布局） | `moliai storyboard create --from-nodes "镜头1" "镜头2" "镜头3" --dry-run` |
| `storyboard create --from-group` | **普通组原位转**分镜组（保留 groupId/名称/颜色/左上角） | `moliai storyboard create --from-group "第一幕"` |
| `storyboard add-node` | 已有图片节点**入组**（插入槽位；满组自动扩容） | `moliai storyboard add-node "第一幕分镜" "散图" --slot 1` |
| `storyboard fill` ⚠️ | 上传本地图片**补到槽位**（服务端新建成员节点）。**当前不可用**：后端不写 `sha256`，恒 422 | `moliai storyboard fill "第一幕分镜" --slot 0 -f ./frame.png` |
| `storyboard move` | 组内**换位**（插入语义，不是交换） | `moliai storyboard move "第一幕分镜" "镜头2" --from 0 --to 2` |
| `storyboard detach` | **拖出**组（成员关系删除，节点与连线保留） | `moliai storyboard detach "第一幕分镜" "镜头2" --from 1 --x 100 --y 100` |
| `storyboard transfer` | **跨组迁移**到另一个分镜组 | `moliai storyboard transfer "第一幕分镜" "镜头2" --from 1 --to-group "第二幕分镜" --slot 0` |
| `storyboard duplicate` ⚠️ | **整组复制**（新组 + 新成员节点 + 裁切来源身份） | `moliai storyboard duplicate "第一幕分镜" --offset-x 200 --offset-y 200 --yes` |
| `storyboard config` | 更新布局配置（网格/比例/编号/导出档/背景色/整组平移） | `moliai storyboard config "第一幕分镜" --rows 2 --columns 3 --dry-run` |
| `storyboard stitch-inputs` | 读取拼接输入快照（只读；`inputs` 只含有图成员） | `moliai storyboard stitch-inputs "第一幕分镜" --out snapshot.json` |
| `storyboard stitch` | **拼接**：本地 ffmpeg 按 `cells[]` 合成 PNG → 上传 → 登记结果节点（不扣费） | `moliai storyboard stitch "第一幕分镜" -o ./分镜.png` |
| `storyboard dissolve` ⚠️ | **破坏性**：解组（删组，成员节点保留为组外普通节点） | `moliai storyboard dissolve "第一幕分镜" --yes` |
| `storyboard clear` ⚠️ | **破坏性**：清空成员（成员节点**软删** + 组外关联连线，组与配置保留） | `moliai storyboard clear "第一幕分镜" --yes` |
| `storyboard to-normal` ⚠️ | **破坏性**：转普通编组（槽位信息作废，成员节点保留） | `moliai storyboard to-normal "第一幕分镜" --yes` |

```bash
# 1) 先预览（零改动）：看成员顺序、类型检查结果、自动布局推算的 rows/columns
moliai storyboard create --from-nodes "镜头1" "镜头2" "镜头3" --dry-run

# 2) 确认后建组
moliai storyboard create --from-nodes "镜头1" "镜头2" "镜头3"

# 3) 普通组转分镜组（可顺带并入未编组散图）
moliai storyboard create --from-group "第一幕" --add-nodes "多余的一张图"

# 4) 读回来核对
moliai storyboard show "第一幕"

# 5) 清理（三种语义，都要 --yes）
moliai storyboard clear "第一幕" --yes      # 只清成员：节点软删，组还在（STORYBOARD 空组）
moliai storyboard dissolve "第一幕" --yes   # 解组：组消失，节点全部保留
moliai storyboard to-normal "第一幕" --yes  # 转普通组：槽位作废，节点仍属该组
```

| 参数 | 适用 | 说明 |
|---|---|---|
| `--from-nodes <nodeRef...>` | 二选一 | 成员节点：nodeId 或节点名（**不可重复**，1..25 个）。顺序无意义，服务端按 `posY→posX→nodeId` 重排 |
| `--from-group <groupRef>` | 二选一 | 要原位转为分镜组的**普通**编组：groupId 或组名 |
| `--add-nodes <nodeRef...>` | 仅 `--from-group` | 一并并入的**未编组**散图节点；不得包含目标组既有成员 |
| `--name <text>` / `--color <color>` | 两者 | 后端建组端点**不接受**名称/颜色，会在建组成功后追加一次 `PATCH /groups/{groupId}`，并给出 `GROUP_LABEL_APPLIED_IN_SECOND_WRITE` 警告 |
| `--canvas <canvasId>` | 两者 | 成员是变参选项，故画布用选项传（省略时走 `MOLIAI_CANVAS` / 当前目录绑定） |
| `--expected-version <n>` | 两者 | 分镜写端点**必填**；省略时自动取当前画布版本 |
| `--dry-run` | 两者 | 只本地推算并展示，不调用任何写端点（画布零变更） |

**自动布局由服务端决定，CLI 只按同一算法预览**：`columns = ceil(sqrt(n))`、`rows = ceil(n / columns)`，
单成员固定 **1×2**（分镜组最少两个槽位），行列数上限 5×5 = 25。

**CLI 本地拦住的规则**（后端同样会拒，本地先拦以省一次往返）：

| 情况 | 结果 |
|---|---|
| `--from-nodes` 与 `--from-group` 同时给 / 都不给 | `MOLIAI_ARG_INVALID` |
| `--add-nodes` 配 `--from-nodes` | `MOLIAI_ARG_INVALID` |
| 同一节点被重复引用 | `MOLIAI_ARG_INVALID`（后端 400 `CANVAS_STORYBOARD_INVALID_REQUEST`） |
| 成员 > 25 | `MOLIAI_ARG_INVALID`「分镜组成员上限 25」 |
| 节点类型不在 `image/nine_grid/three_view/portrait_texture/panorama_image`（或 `super_resolution` 且 `superResolutionType=image`） | `MOLIAI_ARG_INVALID`，`details.unsupported` 列出**全部**不支持的节点 |
| 节点 `status` 为 `uploading`/`generating` | `MOLIAI_ARG_INVALID` |
| 节点已属**分镜组** / 已属**普通组** | `MOLIAI_ARG_INVALID`（分别给「已属分镜组 X」「已属编组 X」） |
| `--from-group` 目标是分镜组 | `MOLIAI_ARG_INVALID`「已经是分镜组」 |
| `--from-group` 目标组为空 | `MOLIAI_ARG_INVALID`「目标组为空，无法转为分镜组」 |
| `--from-group` 合并后（原成员 + `--add-nodes`）> 25 | `MOLIAI_ARG_INVALID` |

#### 破坏性清理：`dissolve` / `clear` / `to-normal`

这三个命令**都会改画布结构**，因此都必须带 `--yes`；缺失时以 `MOLIAI_CONFIRM_REQUIRED`（退出码 10）拒绝，
并在 `details` 里列出组名、成员数、每个成员节点的名称与类型，以及**具体会发生什么**。

| 命令 | 端点 | 对组 | 对成员节点 | 对连线 / 来源行 |
|---|---|---|---|---|
| `dissolve` | `DELETE /storyboard-groups/{groupId}`（**DELETE 带 body**） | 软删（组消失） | **保留**，变组外普通节点 | 连线、来源行全部保留 |
| `clear` | `POST /groups/{groupId}/storyboard/clear` | 保留（仍是 STORYBOARD 空组，配置不变） | **软删** | 组外关联连线一并软删；来源行保留 |
| `to-normal` | `POST /groups/{groupId}/convert-to-normal` | `groupType → NORMAL`，9 个分镜配置列清空 | **保留**在该普通组内，`slotIndex` 全置 NULL | 连线不变；`storyboardSourceEligible` 作为历史事实不清除 |

```bash
# 不带 --yes 时只报错+说明，不会改任何东西
moliai storyboard dissolve "第一幕分镜"        # → 退出码 10，details.effect 说明「节点会保留」
moliai storyboard clear "第一幕分镜"           # → 退出码 10，details.nodes 列出每个将软删的节点
moliai storyboard to-normal "第一幕分镜"       # → 退出码 10，details.effect 说明「槽位会丢失、节点保留」

# 确认后
moliai storyboard dissolve "第一幕分镜" --yes
```

| 参数 | 说明 |
|---|---|
| `<groupRef>` | 分镜组 groupId 或**组名**（必须是 `groupType=STORYBOARD`，普通组会 `MOLIAI_ARG_INVALID` 并指路 `group delete`） |
| `[canvasId]` | 省略时走 `MOLIAI_CANVAS` / 当前目录绑定 |
| `--yes` | **必填**的确认开关（缺失 → 退出码 10） |
| `--expected-version <n>` | 画布结构版本基线；**省略时自动取当前画布版本**（三个都是破坏性操作，用最新版本可减少 409 重试） |
| `--client-request-id <uuid>` | 幂等键（省略时自动生成 UUID v4；重试复用同一值可命中后端幂等回放） |

输出统一含 `operationId` / `canvasVersion`，并额外给出各自的记账字段：

- `dissolve`：`detachedNodeCount` + `detachedNodeIds`（解组后变回普通节点的成员，取后端 `result.affectedNodeIds`）
- `clear`：`removedNodeCount` + `removedNodeIds`（本次软删的成员，取后端 `result.deletedNodeIds`）
- `to-normal`：`groupId`（原位转换不变）+ `memberCount`（取后端 `result.affectedNodeIds` 长度）

**本地拦住的规则**：

| 情况 | 结果 |
|---|---|
| 目标组不是 `STORYBOARD` | `MOLIAI_ARG_INVALID`，hint 指向 `moliai group delete <groupId> --yes` |
| 缺 `--yes` | `MOLIAI_CONFIRM_REQUIRED`（退出码 10） |
| `clear` 时组内无成员 | `MOLIAI_ARG_INVALID`「组内无成员，无需清空」（后端同样 422 `CANVAS_STORYBOARD_EMPTY_GROUP`） |
| `--client-request-id` 非小写 UUID | `MOLIAI_ARG_INVALID` |
| 组不存在 / 组名歧义 | `MOLIAI_ARG_INVALID`（列出候选或说明找不到） |

> ⚠️ **`group delete` 不能删分镜组**：`DELETE /groups/{groupId}` 对 `STORYBOARD` 组会 409，CLI 本地直接以
> `MOLIAI_ARG_INVALID` 拒绝，hint 指向 `moliai storyboard dissolve`。反过来，`storyboard dissolve` 也拒绝普通组
> （指路 `group delete`）——两边互相指路，不要互相替代。
> `dissolve` 与 `clear` 的分界：想让**节点留下**用 `dissolve`（只删组）；想让**节点消失**用 `clear`（组留着）。

#### 成员操作：`add-node` / `fill` / `move` / `detach` / `transfer` / `duplicate`

```bash
# 已有图片节点入组（插入到 slot 1，原 slot 1 及之后顺延；满组自动扩容）
moliai storyboard add-node "第一幕分镜" "散图A" "散图B" --slot 1

# 上传本地图片补到槽位（先 upload 拿 storageKey，再 source.kind=UPLOAD_KEY 提交）
moliai storyboard fill "第一幕分镜" --slot 0 -f ./frame.png --dry-run
moliai storyboard fill "第一幕分镜" --slot 0 -f ./frame.png

# 组内换位（插入语义）；--from 必须等于节点真实槽位
moliai storyboard move "第一幕分镜" "镜头2" --from 0 --to 2

# 拖出组：成员关系删除，节点移到 (100,100)，节点与连线保留
moliai storyboard detach "第一幕分镜" "镜头2" --from 1 --x 100 --y 100

# 跨组迁移：来源组少一个、目标组多一个，两侧各自重排
moliai storyboard transfer "第一幕分镜" "镜头2" --from 1 --to-group "第二幕分镜" --slot 0

# 整组复制（会建新组 + N 个新节点，故要 --yes）
moliai storyboard duplicate "第一幕分镜" --offset-x 200 --offset-y 200 --connections none --yes
```

| 命令 | 端点 | 关键语义 |
|---|---|---|
| `add-node` | `POST /groups/{g}/storyboard/members` | **不复制节点**、不写来源行、不建来源线（节点媒体/配置/已有连线全部保留）；满组**自动扩容**（优先加行，行满加列，5×5 才 409 `CANVAS_STORYBOARD_GROUP_FULL`）；入组同事务把 `panoramaPreviewMode` 置 false |
| `fill` | `POST /groups/{g}/storyboard/slot-images` | 服务端**新建**成员节点（`createdNodeIds` 有值）；插入位置 `finalIndex = min(slotIndex, 当前成员数)`；**满组不扩容**（唯一「满组即拒」的端点）；`source` 是资源判别联调，CLI 固定用 `{kind:"UPLOAD_KEY", storageKey}` |
| `move` | `POST /groups/{g}/storyboard/moves` (`mode=WITHIN`) | **插入不是交换**（见下） |
| `detach` | 同上 (`mode=DETACH`) | 删成员关系 + 节点移到 `position`；**节点与连线保留**，后续槽位顺延压实 |
| `transfer` | 同上 (`mode=TRANSFER`) | 删旧行 + 建新行，两侧各自重排；目标组满时**自动扩容一格**，5×5 才 409 且**来源组零变更** |
| `duplicate` | `POST /storyboard-duplications` | 新组 + 新成员节点 + 成员关系 + 裁切来源身份（`NONE` 也复制）；`connectionMode` 后端必填，CLI 默认 `none` |

**`move` 是插入不是交换**（与界面拖拽一致，也是本组最容易搞反的语义）：

```
原顺序 [A, B, C, D]，A 在 slot 0
moliai storyboard move <组> A --from 0 --to 2
→ 先摘出 A 得 [B, C, D]，再插到 min(2, 3) = 2 → [B, C, A, D]
→ 不是交换得到的 [C, B, A, D]
```

- `finalIndex = min(--to, 剩余长度)`，**不因 from < to 做减一修正**
- no-op 判据是「归一后的最终位置 == 当前 `slotIndex`」（输出 `changed=false`，画布版本不推进）
- `--from` 传错本地直接报错，并告诉你真实槽位：`--from 与节点实际槽位不符：--from 1，该节点实际在 slot 2（0 基）`

**`duplicate` 的 `nodeIdMap` 方向是「新节点 ID → 源节点 ID」**（与普通组复制**相反**）：

```json
{
  "duplicatedGroupId": "a29e0241-…",
  "nodeIdMap": {
    "f1efff2a-…": "26849bd1-…",   // key = 新节点 id，value = 源节点 id
    "c19ff046-…": "dadb4ed4-…"
  }
}
```

CLI 会写后自校验这个方向（键必须落在 `createdNodeIds`、值必须落在源组成员里），方向不符直接报协议错误，
不会把错映射当成功结果输出。

**多节点 `add-node` 的幂等键与版本**：后端单次只收一个 `nodeId`，CLI 逐个提交，并且

- 每个节点用**独立** `clientRequestId`（复用同一个会被后端幂等命中，第二个节点不会生效）
- 每次提交前**重新读取画布版本**（每次入组都会推进版本）
- 因此多节点时 `--client-request-id` / `--expected-version` 会被**拒绝**（只对单节点有意义）
- 多节点逐个占位：`--slot n` 的 N 个节点依次落到 `n, n+1, …`（避免同位置插入导致顺序倒置）
- 任一节点失败即停下，报错 `details.completed` 列出已成功的节点（后端不回滚已完成的部分）

| 参数 | 适用 | 说明 |
|---|---|---|
| `--slot <n>` | `add-node` / `fill` / `transfer` | 插入位置（0 基）。`add-node` 按扩容后容量校验，`fill` 按当前容量校验，`transfer` 按目标组（可能扩容后）容量校验；**三者都允许「超出当前成员数但小于容量」→ 插到末尾** |
| `--from <n>` | `move` / `detach` / `transfer` | 节点**当前**槽位（0 基，与后端 `fromSlotIndex` 严格比对） |
| `--to <n>` | `move` | 目标槽位（0 基，必须 `< rows*columns`） |
| `--x <n>` / `--y <n>` | `detach` | 拖出后节点的画布坐标 |
| `--to-group <groupRef>` | `transfer` | 目标分镜组（必须 `STORYBOARD`，且不等于来源组） |
| `-f, --file <path>` | `fill` | 本地图片路径（后缀必须是 png/jpeg/jpg/webp） |
| `--offset-x <n>` / `--offset-y <n>` | `duplicate` | 新组/新成员相对源组的偏移 |
| `--connections <none\|all>` | `duplicate` | `none`（默认）不复制连线；`all` 复制内部线 + 外部入线 + 外部出线 |
| `--canvas <canvasId>` | 仅 `add-node` | 节点是变参参数，故画布用选项传；其余命令用位置参数 `[canvasId]` |
| `--yes` | `duplicate` | 缺失 → `MOLIAI_CONFIRM_REQUIRED`（退出码 10） |

**`fill --dry-run` 不上传**：只做本地校验（文件存在、是普通文件、非 0 字节、后缀是图片、`--slot < 容量`），
然后打印「上传目标 + 插入位置 + 组容量」。`uploadedStorageKey` / `operationId` / `canvasVersion` 均为 `null`。

**本地拦住的规则**（后端同样会拒，本地先拦以省一次往返）：

| # | 情况 | 结果 |
|---|---|---|
| 1 | 组不存在 / 组名歧义 | `MOLIAI_ARG_INVALID`（列出候选） |
| 2 | 组不是 `STORYBOARD` | `MOLIAI_ARG_INVALID` |
| 3 | 节点不在该组（`move`/`detach`/`transfer`） | `MOLIAI_ARG_INVALID`，`details.members` 列出每个成员的 slotIndex |
| 4 | `--from` 与实际 slotIndex 不符 | `MOLIAI_ARG_INVALID`「该节点实际在 slot N（0 基）」（后端 409 `CANVAS_STORYBOARD_SLOT_CHANGED`） |
| 5 | 目标槽位越界（`< 0` 或 `>= 容量`） | `MOLIAI_ARG_INVALID` |
| 6 | `add-node`：节点已是本组成员 | `MOLIAI_ARG_INVALID`「已是本组成员」 |
| 7 | `add-node`：节点已属其他编组 | `MOLIAI_ARG_INVALID`「已属编组 X / 已属分镜组 X」（分镜组给 transfer 提示） |
| 8 | `add-node`：类型不在白名单 | `MOLIAI_ARG_INVALID` + `details.unsupported` |
| 9 | `add-node`：节点 `uploading`/`generating` | `MOLIAI_ARG_INVALID` |
| 10 | `fill`：文件不存在 / 非图片后缀 / 0 字节 | `MOLIAI_ARG_INVALID` |
| 11 | `transfer`：目标组不是 `STORYBOARD` | `MOLIAI_ARG_INVALID` |
| 12 | `transfer`：目标是同一组 | `MOLIAI_ARG_INVALID`（提示改用 `move`） |
| 13 | `duplicate`：缺 `--yes` | `MOLIAI_CONFIRM_REQUIRED`（退出码 10） |
| 14 | `duplicate`：`--connections` 非法值 | commander `choices` 直接拒绝 |
| 15 | `--slot` / `--to` / `--from` 为负数 | `MOLIAI_ARG_INVALID` |
| 16 | `--client-request-id` 非小写 UUID | `MOLIAI_ARG_INVALID` |

输出字段（都在 `operationId` / `canvasVersion` 之外额外给验证用的现状）：

| 命令 | 输出 |
|---|---|
| `add-node` | `createdNodeIds`（恒空：入组不建节点）、`storyboard`（`rows` / `columns` / `memberNodeIds` / `memberCount`） |
| `fill` | `dryRun`、`createdNodeIds`（新建的成员节点）、`uploadedStorageKey` |
| `move` | `mode`（`WITHIN`）、`changed`（`false` = no-op）、`memberNodeIds`（写后顺序） |
| `detach` | `position`、`memberNodeIds`（写后顺序） |
| `transfer` | `targetGroupId`（注意后端 `result.groupId` 是**目标组**）、`sourceMemberNodeIds`、`targetMemberNodeIds` |
| `duplicate` | `duplicatedGroupId`、`nodeIdMap`（**新 → 源**） |


#### 配置更新：`config`

```bash
# 先预览：展示变更后的配置、容量变化、以及缩容会脱组哪些成员（不发 PATCH）
moliai storyboard config "第一幕分镜" --rows 2 --columns 3 --dry-run

# 改网格（行/列必须成对；1..5，且 rows*columns >= 2）
moliai storyboard config "第一幕分镜" --rows 2 --columns 3

# 单元格宽高比：整写法或分离写法二选一
moliai storyboard config "第一幕分镜" --ratio 16:9
moliai storyboard config "第一幕分镜" --ratio-width 16 --ratio-height 9

# 其余配置项
moliai storyboard config "第一幕分镜" --show-numbers
moliai storyboard config "第一幕分镜" --no-show-numbers
moliai storyboard config "第一幕分镜" --export 4K
moliai storyboard config "第一幕分镜" --bg "#22C55E"

# 整组平移（组框新原点；全部成员同位移，不能单独缩放组框）
moliai storyboard config "第一幕分镜" --move-to 500,3500
```

| 参数 | 说明 |
|---|---|
| `--rows <n>` / `--columns <n>` | 网格行/列，`1..5`；**必须成对**给出，且 `rows*columns >= 2`（1×1 直接拒绝） |
| `--ratio <w:h>` | 单元格宽高比，如 `16:9`；与 `--ratio-width/--ratio-height` **二选一** |
| `--ratio-width <n>` / `--ratio-height <n>` | 分离写法，**必须成对**且为正整数 |
| `--show-numbers` / `--no-show-numbers` | 槽位是否显示编号（未传则不改） |
| `--export <2K\|4K>` | 导出分辨率档位（commander `choices` 拦非法值） |
| `--bg <#RRGGBB>` | 背景色；后端**不支持**把已有背景色清空为 `null` |
| `--move-to <x,y>` | 整组平移：组框**新原点**，全部成员同位移 |
| `--dry-run` | 只本地预览（配置 / 容量变化 / 脱组名单），**不发 PATCH** |
| `--diff` | 让 `diff.changes` 展开成「只列真正变化的配置项」（必须配合 `--dry-run`） |
| `--expected-version <n>` | 画布结构版本基线；**省略时自动取当前画布版本** |
| `--client-request-id <uuid>` | 幂等键（省略时自动生成 UUID v4；重试复用同一值可命中后端幂等回放） |

**缩容脱组（最容易踩的副作用）**：`rows × columns` 小于**当前成员数**时，后端**不报错**，而是
按**旧 `slotIndex` 升序**保留前 `capacity` 个成员，其余**原子脱组**为组外普通节点
（**不删除、不丢图**，保留来源行与全部连线；落点失败则整笔回滚并返回 422 `CANVAS_STORYBOARD_PLACEMENT_FAILED`）。

- `--dry-run` 会把这件事**明确打印**出来：`当前 4 个成员 → 新容量 2（1×2）→ 后 2 个会脱为普通节点（…）：SB测试图3、SB测试图4`
- 真跑不需要 `--yes`（不删节点，只是脱组），但 `warnings` 会写明：
  `已有 2 个成员脱出分镜组（节点保留为普通节点，未丢图）：…`
- 脱组的节点 id 在输出的 `detachedNodeIds`（取后端 `result.detachedNodeIds`）

输出 `storyboard` 是**写后权威配置**（`rows` / `columns` / `cellAspectRatio*` / `showNumbers` /
`exportResolution` / `backgroundColor` / `layoutVersion`）；`--dry-run` 的 `layoutVersion` 仍是写前值
（版本由后端在写成功后推进），`operationId` / `canvasVersion` 为 `null`。

**本地拦住的规则**（后端同样会拒，本地先拦以省一次往返）：

| 情况 | 结果 |
|---|---|
| 目标组不是 `STORYBOARD` | `MOLIAI_ARG_INVALID`，hint 指向 `moliai group show/update` |
| 只给 `--rows` 或只给 `--columns` | `MOLIAI_ARG_INVALID`「--rows 与 --columns 必须同时指定」 |
| `--rows`/`--columns` 不在 `1..5` | `MOLIAI_ARG_INVALID` |
| `rows × columns < 2`（1×1） | `MOLIAI_ARG_INVALID`「网格容量至少 2（当前 1×1）」 |
| `--ratio` 格式不是 `N:M` 或分量 ≤ 0 | `MOLIAI_ARG_INVALID` |
| `--ratio-width` 与 `--ratio-height` 只给一个 | `MOLIAI_ARG_INVALID` |
| `--ratio` 与 `--ratio-width/--ratio-height` 同时给 | `MOLIAI_ARG_INVALID` |
| `--export` 不是 `2K`/`4K` | commander `choices` 直接拒绝 |
| `--bg` 不是 `#RRGGBB` | `MOLIAI_ARG_INVALID` |
| `--move-to` 不是 `x,y` 两个数值 | `MOLIAI_ARG_INVALID` |
| 一个配置项都没给 | `MOLIAI_ARG_INVALID`「没有要修改的配置项」 |
| `--client-request-id` 非小写 UUID | `MOLIAI_ARG_INVALID` |

> 「1×1」按**变更后的最终配置**判定，不是只看传入值：只给 `--bg` 等非网格参数时，
> 同样会用当前 `rows×columns` 复核（历史 1×1 脏数据会被本地拦下，而不是到后端才 400）。

#### 拼接输入快照：`stitch-inputs`

`GET /api/canvases/{canvasId}/groups/{groupId}/storyboard/stitch-inputs`（**只读，不推进画布版本**）。

```bash
moliai storyboard stitch-inputs "第一幕分镜"
moliai storyboard stitch-inputs "第一幕分镜" --out snapshot.json
```

| 输出字段 | 说明 |
|---|---|
| `inputs[]` | 只含**有图成员**（`slotIndex` / `nodeId` / `mediaId` / `sha256` / `mediaWidth` / `mediaHeight`），按真实 `slotIndex` 升序、不重新编号；**零有图成员时是空列表，不是错误** |
| `config` | **冻结的拼接配置**（`rows` / `columns` / `cellAspectRatio*` / `showNumbers` / `exportResolution` / `backgroundColor` / `layoutVersion`），可原样回传给 `stitches` 的 `inputSnapshot.config` |
| `slots[]` | 全容量槽位（`index` / `nodeId` / `hasImage` / `placeholder`）：`nodeId=null` 是空尾槽，`placeholder=true` 是空图片占位（不参与拼接） |
| `canvasVersion` / `layoutVersion` / `backgroundColor` | 当前快照的版本与背景色；拼接时 `inputSnapshot.inputCanvasVersion` 应取 `canvasVersion` |
| `inputCount` | `inputs` 条数（即有图成员数） |
| `outPath` | `--out` 写出的文件绝对路径；未指定为 `null` |

`--out <path>` 写出的是**原始服务端响应 JSON**（不做字段裁剪），便于后续手工拼接或留档；
目录不存在时会自动创建。

#### 拼接：`stitch`

把一个分镜组的有图成员拼成一张 PNG，上传后登记为**组外普通结果节点**（不建连线、不提交生成、**不扣费**）。

```bash
# 最小用法：合成 + 上传 + 登记
moliai storyboard stitch "第一幕分镜" -o ./第一幕.png

# 保留每格下载的原图，便于核对每格取图是否正确
moliai storyboard stitch "第一幕分镜" -o ./第一幕.png --keep-inputs ./原图
```

| 参数 | 说明 |
|---|---|
| `<groupRef>` | 分镜组 groupId 或组名 |
| `[canvasId]` | 省略时走 `MOLIAI_CANVAS` / 当前目录绑定 |
| `-o, --out <path>` | **必填**：输出 PNG 路径（父目录自动创建，同名文件直接覆盖） |
| `--keep-inputs <dir>` | 保留下载的原图（`slot-<slotIndex>.png`）；不给则用临时目录并在结束后清理 |
| `--ffmpeg <path>` | ffmpeg 可执行文件路径（优先级最高；也可 `MOLIAI_FFMPEG` 或 PATH） |
| `--client-request-id <uuid>` | 幂等键（省略时自动生成 UUID v4） |

**像素口径**（复刻网页端 canvas 合成，不自行推算尺寸）：

1. 输出尺寸**完全取后端** `outputWidth × outputHeight`（与登记校验同源）；
2. 每张图先 `contain` 缩放到槽位内（**保持宽高比、不拉伸**），再 pad 到槽位的精确 `w×h`，
   填充色 = 组 `backgroundColor`（`null` 时透明）；
3. 再按 `cells[]` 的 `x` / `y` 顺序 `overlay` 到画布；
4. 合成后本地复核 PNG 尺寸必须等于 `outputWidth × outputHeight`，不符即报错（不静默上传错图）。

> ⚠️ **依赖后端新字段**：`stitch-inputs` 必须返回 `cells[]` / `outputWidth` / `outputHeight`
> （`cellGap` / `padding` / `cellLongSide` 为组内持久化策略值，CLI 不重复使用）。
> **当前 test 环境仍是旧构建，这三个字段为空** → 命令以 `MOLIAI_UNSUPPORTED` 明确报错，
> 此时**不会下载、不会上传、不会改画布**。需后端部署后再用。
>
> ⚠️ 后端输出尺寸是**纯网格比例**（格子矩形按组框本地矩形轴向缩放），
> 与网页端画布上肉眼看到的 gap/padding 观感可能有细微偏差。

登记请求体（`POST /groups/{groupId}/storyboard/stitches`）：

```json
{
  "clientRequestId": "<uuid>",
  "expectedCanvasVersion": 7,
  "outputResourceRef": { "kind": "UPLOAD_KEY", "storageKey": "<上传返回的最终 key>" },
  "inputSnapshot": {
    "config": { "...": "stitch-inputs 的 config 原样回传" },
    "inputs": [ "..." ],
    "inputCanvasVersion": 7
  }
}
```

- `expectedCanvasVersion` 与 `inputCanvasVersion` **都取 `stitch-inputs` 的 `canvasVersion`**（后端要求二者相等）；
- `config` / `inputs` **原样回传**服务端快照；`inputs` 必须**精确等于有图成员集合**（后端逐项比对，多/少都 409）；
- 空组（零有图成员）直接报错「分镜组没有可拼接的图」，不生成空图。

输出：`groupId` / `operationId` / `clientRequestId` / `canvasId` / `canvasVersion` /
`outputPath` / `outputWidth` / `outputHeight` / `uploadedStorageKey` / `resultNodeId` /
`stitchId` / `inputCount` / `keptInputsDir`。

### 模型

| 命令 | 说明 | 最小示例 |
|---|---|---|
| `model list` | 列出账号可见模型（`--type image\|video`） | `moliai model list --type video` |
| `model search` | 按关键词搜索模型 | `moliai model search seedance` |
| `model <modelKey>` | 查单个模型的参数契约 | `moliai model <provider>::<modelId>` |
| `capabilities` | 模型能力矩阵（时长/分辨率/生成模式/素材上限 + 参数契约） | `moliai capabilities --model <provider>::<modelId>` |

> **`model` 组是只读的**：只有 `list` / `search` / `<modelKey>` 三种查询，没有增删改模型的命令。
> 可用模型由账号配置决定，CLI 不提供写入口。

> **模型能力矩阵（`capabilities`）**：`moliai capabilities [--model <modelKey>]` 展示各模型的时长/分辨率/生成模式/素材上限与参数契约。
> 其中 `firstlastframe` **不随 `GET /api/user/models` 返回**（服务端用它做提交校验，不对外投影），CLI 输出恒为 `null`、
> 文本模式显示「未提供」——表示**未知**，不是「不支持」。判断首尾帧/参考能力请以
> `videoPricingTiers[].when.generationMode` 为准。

### 任务

| 命令 | 说明 | 最小示例 |
|---|---|---|
| `task list` | 列出任务（`--limit` 每页条数 / `--page` 页码 / `--ids` / `--canvas` / `--client-request-id` / `--status`） | `moliai task list --canvas <canvasId> --limit 10` |
| `task get` | 查单个任务（`--events` 附带事件流） | `moliai task get <taskId>` |
| `task watch` | 实时观察任务：状态或进度变化时打印一行，终态退出（`--interval` / `--until`） | `moliai task watch <taskId> --output text` |
| `task cancel` | 取消任务（`--yes` 必填；只有 `queued` / `processing` 会被真正取消）；`--where '<选择器>'` 批量取消 | `moliai task cancel <taskId> --yes` |

#### `task watch` 的参数与输出

```bash
moliai task watch <taskId> --output text                 # 终端里逐行看进度
moliai task watch <taskId> --until any-change            # 首次变化就返回
moliai task watch <taskId> --interval 1 --output ndjson  # 每行一个事件对象，便于管道消费
```

| 参数 | 取值 / 说明 |
|---|---|
| `--interval <秒>` | 轮询间隔，`0.5`–`60`（支持小数），默认取全局 `--poll-interval`（2 秒） |
| `--until <模式>` | `done`（默认，等到终态再退出）/ `any-change`（首次状态或进度变化就返回；首屏那次快照不算变化） |
| `--fields` | **不支持**，会直接报 `MOLIAI_ARG_INVALID`（流式逐行输出，不做字段裁剪） |

输出：

- `text`：每行 `[HH:MM:SS] status progress=N`，只在状态或进度变化时打印
- `json` / `ndjson`：每行一个事件对象 `{ ts, timestamp, status, progress, errorCode }`（流式，不套一次性成功信封）
- 与 `wait` 的区别：`wait` 等到终态才返回；`task watch` 一边等一边实时打印，失败 / 暂停 / 驳回以退出码 6 结束（`paused` 用 `MOLIAI_TASK_PAUSED`）

#### `task list` 的分页与 `--client-request-id`

- 分页：`--limit` 是每页条数（后端 `pageSize`，1..200，默认 50），`--page` 是页码（0 起，默认 0）。
  响应为 `{ tasks, count, total, hasMore }`；`count` 是本页实际条数，`total` 是匹配总数，`hasMore` 表示是否还有下一页。
  `--output text` 末尾会追加一行汇总，例如 `显示 50 / 1234 条（第 0 页；还有更多，用 --page 1 查看下一页）`。
- 旧版本后端不返回 `total` / `hasMore`：这两个字段输出 `null`（**不伪造**），默认 `--page 0` 行为不变；
  此时若显式给了 `--page > 0`，CLI 以 `MOLIAI_UNSUPPORTED` 显式失败（后端不认页码，不能把第 0 页当第 N 页返回）。
- `--client-request-id` 可**单独使用**（后端走 `(userId, clientRequestId)` 组合索引找回任务），不需要 `--canvas`；
  同时给 `--canvas` 时按该画布内的幂等键（`canvas:{userId}:{canvasId}:{clientRequestId}`，含音频任务的 `:nodeId` 变体）定位，语义不同。
  未命中时后端返回 404（不区分「不存在」与「不属于当前账号」），CLI 报 `MOLIAI_ARG_INVALID` 并列出全部可能原因，**不会自动改用别的查询方式**。

#### `task cancel` 的行为（与后端实现对齐）

- 后端端点：`DELETE /api/tasks/{taskId}`，**只有 `queued` / `processing`** 会被取消；其它状态后端返回 200 + `cancelled=false`（静默 no-op）。
- CLI 把这种 no-op **显式当作失败**：`MOLIAI_CONFLICT`（退出码 9），`details` 给出 `previousStatus` / `currentStatus` / `cancellableStatuses`。已完成任务不会被"取消"成别的东西。
- 取消成功后后端把任务置为 `failed` + `errorCode=TASK_CANCELLED`（**不是** `cancelled` 状态），`currentStatus` 就是后端返回的真实值。
- **不退还预扣费**：后端 `TasksApiService#cancelTask` 不做任何退费调用。CLI 的 `refunded` 恒为 `null`（后端不返回退费信息，**不伪造**），`message` 里写明这一点。
- 缺 `--yes` 时以 `MOLIAI_CONFIRM_REQUIRED`（退出码 10）拒绝，`details` 给任务 id、当前状态、`cancellable` 与退费说明。
- 输出：`{ taskId, previousStatus, currentStatus, cancelled, refunded, message }`。

#### `task cancel --where` 批量取消

```bash
moliai task cancel --where 'status=queued' --yes
moliai task cancel --where 'type=video&status=failed' --yes
```

- 选择器支持 `status` / `type` / `targetType` / `canvasId` / `projectId` / `errorCode`（**不支持 `id`**，单条取消用 `<taskId>`）
- `--where` 与 `<taskId>` **互斥**；`status` 不支持逗号分隔多值（一次只按一个状态筛）
- **必须带 `--yes`**（不带统一 `MOLIAI_CONFIRM_REQUIRED`，退出码 10），`details.tasks` 预览前 20 条；
  命中数超过 `--max-nodes`（默认 100，与后端单批上限一致）时 message 会提示改用更精确的条件或调大上限
- 真正取消的仍然只有 `queued` / `processing`；其余任务进 `failed[]`（`reason` 由后端给出，如 `not-active`），同样不退预扣费
- 输出：`{ cancelled, failed, cancelledCount, failedCount }`


### 素材

| 命令 | 说明 | 最小示例 |
|---|---|---|
| `upload` | 上传本地媒体到画布素材库，返回 `storageKey` 与 `mediaId` | `moliai upload ./cover.png <canvasId>` |
| `download` | 下载节点或任务的产物到本地（同名默认不覆盖，`--force` 覆盖） | `moliai download <nodeId> -o ./out` |
| `download --watermark-text <文本>` | 下载后**本地**叠加文字水印（需 ffmpeg） | `moliai download <nodeId> --watermark-text "© 我的水印"` |
| `download --watermark-image <路径>` | 下载后**本地**叠加图片水印（需 ffmpeg） | `moliai download <nodeId> --watermark-image ./logo.png` |

水印细节：

- `--watermark-text` 与 `--watermark-image` **二选一**，同时传直接报 `MOLIAI_ARG_INVALID`
- 位置 `--watermark-position tl|tr|bl|br`（默认 `br` 右下角），不透明度 `--watermark-opacity 0`–`1`（默认 `0.6`）
- **只支持图片（jpg / png / webp）与视频（mp4 / mov）**；音频等其它类型明确报 `MOLIAI_UNSUPPORTED`，不会静默跳过
- 水印是在下载**之后**用本机 ffmpeg 处理，服务端不参与，因此需要本机 ffmpeg（见「本地依赖：ffmpeg」）
- Windows 上文字水印会自动挑选系统中常见的字体文件传给 ffmpeg；都不存在时不传 `fontfile`（由 ffmpeg 自行解析，通常直接报错，不会静默产出无水印文件）

### 生成

| 命令 | 说明 | 最小示例 |
|---|---|---|
| `run` | 在画布节点上提交一次生成任务（**唯一扣费命令**） | `moliai run <nodeId> --dry-run --model <k> --prompt "<p>"` |
| `extract` | 从 text 节点提取角色/场景/物品，并把结果落成画布节点（`--kind` 必填） | `moliai extract <nodeId> --kind character --wait 120` |

#### `run --explain`：看清每个参数从哪来（零写入）

`--explain` 在 `--dry-run` 的基础上，额外输出**将发出的请求体（已脱敏）**与**每个参数的来源**，
用于 Agent 自查「为什么是这个值」。

```bash
moliai run 26849bd1-... --model qwen-image::qwen-image-2.1 \
  --set aspectRatio=9:16 --set resolution=1K --set generationMode=normal \
  --dry-run --explain
```

> - `--explain` **强制走 dry-run 路径**：不写画布、不建任务、不扣费（NFR-20）。
>   批量模式下 `--explain` 也会忽略 `--execute` 并在 `warnings` 里说明，本次只输出预览。
> - 输出在原有 dry-run 结构上多一个 `data.explain`；dry-run 其余字段不变。

`data.explain` 结构：

```json
{
  "request": {
    "taskType": "image",
    "model": "qwen-image::qwen-image-2.1",
    "prompt": "橘子，很多橘子",
    "options": { "aspectRatio": "9:16", "resolution": "1K", "generationMode": "normal" },
    "count": 1,
    "targetNodeId": "26849bd1-...",
    "clientRequestId": "f316a100-..."
  },
  "parameterSources": {
    "canvasId": "binding",
    "nodeId": "explicit",
    "taskType": "node-config",
    "model": "explicit",
    "prompt": "node-config",
    "count": "cli-default",
    "clientRequestId": "cli-default",
    "aspectRatio": "explicit",
    "resolution": "explicit",
    "generationMode": "explicit"
  },
  "steps": [
    { "step": "resolve-canvas", "source": "binding", "detail": "环境变量 MOLIAI_CANVAS" },
    { "step": "resolve-node", "source": "explicit", "detail": "命令行位置参数（节点 id 或名称）" },
    { "step": "resolve-prompt", "source": "node-config", "detail": "node.promptDraft" },
    { "step": "resolve-parameters", "source": "mixed", "detail": "--set 3 项，节点 modelParams 2 项" },
    { "step": "build-request", "source": "mixed" },
    { "step": "validate-params", "source": "schema", "detail": "按模型契约 qwen-image::qwen-image-2.1 校验" }
  ],
  "warnings": []
}
```

**参数来源的七类取值**：

| 来源 | 含义 | 判定方式 |
|---|---|---|
| `explicit` | 用户在命令行显式传入 | `--model` / `--prompt` / `--set k=v` / `--count` / 位置参数 |
| `binding` | 环境变量或工作目录绑定 | `MOLIAI_CANVAS` / `.moliai/config.json` |
| `schema-default` | 模型参数契约声明的默认值 | 值等于 `schema.properties.<name>.default`，且**不是** `--set` 或节点继承来的 |
| `upstream-inferred` | 画布连线/上游节点推断 | `contextNodeIds`（仅 `group run` / 批量连线推导） |
| `node-config` | 节点自身已保存的配置 | `node.modelKey` / `generationModel` / `promptDraft` / `generationPrompt` / `content` / `modelParams` |
| `cli-default` | CLI 内置缺省值 | `--count` 缺省 `1`、`clientRequestId` 自动生成的 UUID |
| `unknown` | 无法判定 | 该模型没有参数契约，或值既非显式也非节点继承、契约也没声明默认值 |

> **`explicit` 优先于 `schema-default`**：用户显式传了与契约默认值相同的值，仍标 `explicit`
> （他确实传了，不该被说成"默认值"）。

**schema 覆盖限制（必须知道）**：参数契约只覆盖**已配置 `parameterSchema` 的 modelKey**（当前目录下
`moliai model list` 里 `schemaAvailable=true` 的模型，如 `qwen-image::qwen-image-2.1`、
`tokenproto::doubao-seedance-2-5-260628`）。其它模型没有契约：

```json
"warnings": [
  "schema 不可得：wetoken::bytedance-seedance-2-0-260128 该模型未配置参数契约（schema 未配置），相关参数来源标记为 unknown"
]
```

此时 `schema-default` 这一路**不可得**，CLI 标 `unknown` + warning，**不会猜**（也绝不静默省略）。
`validate-params` 一步的 `source` 会随之变成 `capabilities`（本地 capabilities 校验）或 `none`（无任何校验依据）。

**prepare 被拒时也会给出 explain**：`--explain` 下若 prepare 返回 400（如缺必填参数），
错误信封的 `error.details.explain` 里同样带 `request` / `parameterSources` / `steps` / `warnings`，
并明确列出「契约声明必填但本次未提供」的参数（含其契约默认值），便于一次改对：

```json
"warnings": [
  "契约 qwen-image::qwen-image-2.1 声明这些参数必填，但本次既未显式传入也未从节点继承：generationMode（契约默认值 \"normal\"，但后端不会自动补）、resolution（契约默认值 \"1K\"，但后端不会自动补）；prepare 很可能被后端拒绝"
]
```

> 注意：**后端不会自动补契约默认值**，`--set`/节点上没有的必填参数不会被 CLI 偷偷填上；
> 想让 `schema-default` 出现在请求里，需要显式传值（此时标 `explicit`）。

**脱敏**：`request` 中 key 名匹配 `key|token|secret|password|credential` 的值替换为 `***`
（`modelKey` 是模型标识，不属于敏感字段，保留原值；`clientRequestId` 是 UUID，无敏感性，不脱敏）。

**批量模式**：`run --where ... --explain` 在每个 `nodes[]` 里附加同名 `explain`（批量预览不调 prepare，
`parameterSources` 只反映 CLI 构造的请求体）。

#### `run --where` / `run --rerun-failed`：按选择器批量生成

> ⚠️ **默认行为与单节点 `run` 刻意相反，必须先看清**
>
> | | `run <node>`（单节点） | `run --where '<expr>'`（批量） |
> |---|---|---|
> | 节点来源 | 用户明确指定的 1 个 | 选择器可能命中 20 个 |
> | 默认是否扣费 | **默认真跑**（`--dry-run` 才预览） | **默认只预览（零扣费）**，`--execute` 才真跑 |
> | 连线推导 | 永远不做（参考素材只来自 `--ref-*`） | **默认开启**（`--no-from-connections` 关闭） |
> | 提交节流 | 无 | **间隔 ≥ 6 秒**（网关限制 10 次提交/分钟） |
>
> 为什么相反：单节点是用户明确指定，直接执行符合预期；批量可能命中几十个节点，
> 默认必须让人先看清命中范围与总成本。这是**刻意的不一致**，不是遗漏。

```bash
# 1) 预览（零扣费）：命中数、每节点成本、跳过原因、预计提交耗时
moliai run --where 'type=image&status=failed'
moliai run --where 'name~镜头-&hasResult=false'
moliai run --rerun-failed                                   # 等价于 --where 'status=failed'

# 2) 确认后真跑（提交按 6 秒节流，N 个节点至少 N×6 秒）
moliai run --where 'name~测试' --execute \
  --model qwen-image::qwen-image-2.1 --prompt "一只橘色小猫坐在窗台上" \
  --set aspectRatio=1:1 --set resolution=1K --set generationMode=normal --max-cost 3
```

选择器语法与字段见上文 [`node delete` 的 `--where`](#node-delete-的三种目标方式与-where-选择器)（同一套解析器与字段白名单）。

| 参数 | 取值 | 说明 |
|---|---|---|
| `--where <expr>` | 表达式 | 选择器命中哪些节点；`--where` 与位置参数 `<node>` 同时给 → `MOLIAI_ARG_INVALID` |
| `--rerun-failed` | 布尔 | 等价于 `--where 'status=failed'`，但**额外包含**「远端仍 `idle`、本地有失败作业记录」的节点（prepare 阶段被拒的情形）；与 `--where` 互斥 |
| `--execute` | 布尔 | 真提交；不带时只预览（零扣费） |
| `--max-nodes <n>` | 1..1000，默认 20 | 命中数超过上限且没带 `--yes` → `MOLIAI_CONFIRM_REQUIRED`（退出码 10）；带 `--yes` 时按上限截断，`matchedBeforeLimit` 会显示截断前的命中数 |
| `--max-attempts <n>` | 1..100，默认 1 | 仅 `--rerun-failed` 生效：同一节点最多重跑 n 次，超限进 `skipped`（`reason=max-attempts-reached`） |
| `--concurrency <n>` | 1..10，默认 1 | `>1` 时必须 `--no-from-connections` |
| `--continue-on-error` | 布尔 | 失败继续；默认首个失败即停 |
| `--wait` / `--deadline` / `--model` / `--prompt` / `--set` / `--count` / `--max-cost` | 同 `run` | 对所有命中节点生效 |
| `--dry-run` | 布尔 | 强制预览（与默认等价，保留兼容） |

**批量模式的位置参数是画布 id**：`moliai run --where '...' <canvasId>`。同时给节点和画布
（两个位置参数）会报错——批量模式不接受节点参数。

**跳过与阻断**：

| 情况 | 处理 |
|---|---|
| 命中 0 个 | `MOLIAI_ARG_INVALID`「没有匹配的节点」（批量生成不静默成功） |
| `status=generating` | 进 `skipped`（`already-generating`）+ warning |
| 节点类型不支持生成（audio/voice/super_resolution/depth_capture…） | 进 `skipped`（`unsupported-type`） |
| 缺模型/缺提示词/参数非法 | 进 `blockers`，`--execute` 时整批**一个都不提交** |
| 命中节点已有产物 | **不跳过**（显式选择优先，与单节点 `run` 一致），但 `warnings` 提示会再次扣费 |

**输出结构**：

- 预览：`{ mode:"preview", where, matched, matchedBeforeLimit, nodes[{nodeId,name,nodeType,status,estimatedCost,willSubmit,skipReason,attemptsUsed}], totalEstimatedCost, maxCost, withinBudget, estimatedSubmitMinutes, blockers, skipped }`
- 执行：`{ mode:"execute", where, succeeded[{nodeId,taskId,jobId,status,mediaUrl}], failed[...], skipped, totalEstimatedCost, elapsedSeconds }`
- `totalEstimatedCost` 口径与 `group run` 相同：只统计本次要执行的节点；**有节点无法预估且并非全部无法预估**时给出可预估部分的和并告警，**全部无法预估**时记为 `null`（不把 `null` 当 0），配合 `--max-cost` 会整批拒绝

**`--rerun-failed` 的 `--max-attempts` 怎么判断已重跑次数**：读本地作业记录，
`已重跑次数 = 该节点本地 run 作业记录数 - 1`（首次提交算原始尝试，之后每次提交都算一次重跑）。
因此默认 `--max-attempts 1` 表示「同一节点最多再重跑一次」。换机器/清过作业目录时本地没有记录，
`attemptsUsed` 一律按 0 计算，CLI 会在 `warnings` 里明确说明。

> `group run --rerun-failed` 也支持 `--max-attempts`，但**未设置时不限制**（保持既有行为）；
> `run --rerun-failed` 的默认值是 1。两者默认值不同是有意的：组内成员是人工挑过的，
> 选择器批量命中范围更大，默认更保守。


`extract` 的 `--kind` 取 `character` / `scene` / `item`（对应后端 `extract_character` / `extract_scene` / `extract_item`），
三个类别互不阻塞，同一节点 × 同一类别同时只允许一个任务。

```bash
# 1) 零成本预演：只走 prepare，不建任务、不扣费
moliai extract <text节点id> --kind character --dry-run

# 2) 真实执行：默认把结果落成 text 节点 + 连线（每个 item 一个节点）
moliai extract <text节点id> --kind character --wait 120

# 3) 只看结果不落画布（仍会清理任务）
moliai extract <text节点id> --kind scene --no-apply
```

落地规则（对齐网页端）：节点名 `提取角色-<名称>`、内容 `<名称>\n\n<提取内容>`、
`sourceAssetType=text-extraction`、`derivedFromNodeId=源节点`、`origin=ai_generated`，
连线为 `manual` + `arrow=false`。

**结果节点定位（自动避让）**：结果节点落在源节点右侧（`源 posX + 源 width + 80`），同批多个节点
在同一列内**自上而下**排列（行间距 = 节点高 200 + 40），一列排满（20 行）后右移一列。
每个节点创建后立即占用自己的矩形，因此同批节点不会互相叠放，也不会压到画布上已有节点。
画布上该区域排满时显式失败（`MOLIAI_ARG_INVALID`），不会静默重叠落点。

模型选择链：`--model` > 源节点 `modelKey` > `/user/models` 的 `llm[0]`（推断时给出 `MODEL_INFERRED` 警告）。
计费口径是 `canvas-text`，但后端 `/billing/estimate` 的参数白名单不含该值，因此 `estimatedCost` 恒为 `null`
并附 `ESTIMATE_UNAVAILABLE` 警告——实际扣费以后台账单为准。

### 派生（derive）

| 命令 | 说明 | 最小示例 |
|---|---|---|
| `derive list` | 列出全部派生场景与 CLI 支持状态（13 项） | `moliai derive list` |
| `derive depth-capture` | 从 video / 超分视频 / 深度捕捉节点创建 `depth_capture` 节点 | `moliai derive depth-capture <video节点> --dry-run` |
| `derive video-continuation` | 从 video 节点创建视频续写占位节点（`mediaUrl` 为空）；`--run` 时本地裁切源视频并上传片段走 `frontend_clip` 续写 | `moliai derive video-continuation <video节点> --model <k> --from 0 --to 4 --dry-run` |
| `derive panorama` | 从图片节点派生 720° 全景图节点（`taskType=panorama_image`） | `moliai derive panorama <image节点> --model tencent::gpt-image-2` |
| `derive three-view` | 从图片节点派生角色三视图节点（`layoutPreset=画面版式:三视图`） | `moliai derive three-view <image节点>` |
| `derive nine-grid` | 从图片节点派生多机位九宫格节点（`anglePreset=机位视角:九宫格`） | `moliai derive nine-grid <image节点>` |
| `derive portrait-texture` | 从图片节点派生人像质感调节节点（`promptPreset` 人景融合预设） | `moliai derive portrait-texture <image节点>` |
| `derive super-resolution` | 从 image / video 节点派生超分节点（`super-resolution-image` / `super-resolution-video`） | `moliai derive super-resolution <image节点> --size 1080p --dry-run` |
| `derive image-edit` | 从图片节点派生涂鸦重绘结果节点（`--doodle` 是「源图+涂鸦」完整整图） | `moliai derive image-edit <image节点> --doodle ./doodle.png --dry-run` |
| `derive video-edit` | 从 video 节点派生视频编辑结果节点（Worker 新建 `video_edit` 节点） | `moliai derive video-edit <video节点> --model <k> --resolution 720p` |
| `derive audio-separation` | 音视频分离：本地 ffmpeg 抽音轨 + 去音轨，上传后一次性建两个派生节点 | `moliai derive audio-separation <video节点>` |
| `derive audio-process` | 音频处理：本地 ffmpeg 截取 / 保调变速，上传后建派生音频节点 | `moliai derive audio-process <audio节点> --speed 1.5` |
| `derive from-grid` | 网格切图：本地 ffmpeg 按 rows × columns 切分图片，建 N 个 image 节点 + N 条连线（不扣费） | `moliai derive from-grid <image节点> --rows 2 --columns 2` |

`derive list` 输出 `scenes[]`（`scene` / `supported` / `command` / `endpoint` / `note`）+ `supportedCount` / `totalCount`；
未支持的场景给出原因与替代方案（多数可用 `moliai run` 间接实现）。

```bash
# 深度动作捕捉：默认只创建节点（零扣费），--run 才提交生成
moliai derive depth-capture <video节点> --resolution 480p --dry-run
moliai derive depth-capture <video节点> --resolution 480p

# 视频续写：--from/--to 用秒（支持小数），内部转毫秒；也可用 --from-ms/--to-ms
moliai derive video-continuation <video节点> \
  --model wetoken::bytedance-seedance-2-5-260628 --from 0 --to 4 --dry-run
moliai derive video-continuation <video节点> \
  --model wetoken::bytedance-seedance-2-5-260628 --from 0 --to 4
# --run 走 frontend_clip：本地裁切 [--from,--to) → 上传片段 → 提交续写生成
# --duration 是「续写输出秒数」（4–30 整数，= 计费秒数），不是选段长度
moliai derive video-continuation <video节点> \
  --model wetoken::bytedance-seedance-2-0-260128 \
  --from 0 --to 4 --duration 5 --resolution 720p --run --max-cost 100
# 想检查裁切结果/更快？--keep-clip 保留 mp4；--fast 用 -c copy（不重编码，端点会吸附包边界）
moliai derive video-continuation <video节点> \
  --model wetoken::bytedance-seedance-2-0-260128 \
  --from 0 --to 4 --duration 4 --keep-clip ./clip.mp4 --dry-run
```

关键约束：

- **幂等键是 `operationId`**（不是 `clientRequestId`）。CLI 对外用 `--operation-id <uuid>`
  （同时接受 `--client-request-id` 作为别名，二者等价）；省略时自动生成 UUID。同 `operationId`
  不同请求体 → 409（`DEPTH_CAPTURE_OPERATION_CONFLICT` / `VIDEO_CONTINUATION_OPERATION_CONFLICT`）。
- `--resolution` 只接受**小写** `480p` / `720p`（`480P` / `720P` 会被拒绝）。
- **预算闸门**：`--max-cost <n>`（或环境变量 `MOLIAI_MAX_COST`）在报价之后、提交之前校验；
  预估超限或无法预估时零提交并返回 `MOLIAI_BUDGET_EXCEEDED`（退出码 5）。所有 `derive` 子命令都支持。
- 深度捕捉源节点：`video` / `super_resolution`（`superResolutionType=video`）/ `depth_capture`，且 `mediaUrl` 非空。
  后端要求源视频 ≤ 30 秒（`--run` 时更强校验），超长源会给出 `SOURCE_TOO_LONG` 警告。
- 视频续写源节点必须是 `video` 且有 `mediaUrl`、有 `duration`；**源全长与选段都要落在 4–30 秒**，
  选段满足 `0 <= start < end <= 源时长`。`sourceDurationMs` 由节点 `duration`（秒）×1000 得到。
- 视频续写创建前 CLI 会先调 `reference-media/prepare` 取 `sourceExpectations`（后端写事务强制要求，
  缺它会 409 `CANVAS_REFERENCE_RELATION_REQUIRED`）。
- **`--run` 的续写链路（`frontend_clip`）**：下载源视频 → 本地 ffmpeg 裁切 `[--from, --to)` → 上传片段拿
  `clipMediaId`（storageKey，形态 `images/doodles/{canvasId}-{13位时间戳}-{8位hex}.mp4`）→
  `POST /canvases/{id}/generate` 带齐 `options.duration` / `options.resolution` / `sourceExpectations` /
  `videoContinuation{inputMode, clipMediaId, clipDurationMs, extensionDurationSeconds}`。
  因此 **`--run` 必须有系统 ffmpeg**（`--dry-run` 不做下载与裁切，不需要）。
- **`--duration <秒>`** 是续写**输出**秒数（4–30 整数，= `options.duration` = `extensionDurationSeconds`，
  也是**计费秒数**）；与选段长度 `--to - --from` 无耦合。`--run` 时必填。
- **`--resolution`** 默认 `720p`（只接受 `480p` / `720p`），直接决定每秒单价。
- **裁切精度**：默认**重编码**（`libx264 -crf 20` + `aac`），起点精确到帧；`--fast` 改用 `-c copy`
  （不重编码、更快、保留源码率，但端点只能落在包/关键帧边界，实测同区间 4.000 秒 → 4.1 秒，
  且偏差随源 GOP 增大）。`--keep-clip <path>` 把裁切出的 mp4 另存出来检查（默认临时文件用完即删）。
- 两个命令默认只创建节点，**不提交生成、不扣费**；`--run` 才会提交生成任务（会扣费），
  提交前打印预估消耗，作业记录可用于 `moliai wait <jobId>`。
- `--dry-run` 零网络写入（不调 prepare、不建节点），只输出将要提交的 `operationId`、坐标与连线参数。
  带 `--run` 时会额外调用 `/billing/estimate`（零成本只读）并输出 `estimatedCost`，便于扣费前确认金额。
- `--run` 提交后立刻落作业记录，轮询中状态变化与终态都会回写（`status` / `done` / `mediaUrl`），
  因此任务未在 `--wait` 内完成时可用 `moliai wait <jobId>` 继续跟。
- **自动定位（源锚定 + 簇内递增）**：不给 `--x/--y` 时，新节点落在源节点右侧
  （`源 posX + 源 width + 80`），同源派生在右侧列内**纵向排列**（行间距 = 高 + 40），
  一列试满 20 行后右移一列；画布上已有节点的矩形全部参与避让，因此同一源节点连续派生两次
  会得到不同坐标、不会重叠。只给一个坐标时该轴固定不动，另一轴在其所在列/行内避让。
  **`--x` 与 `--y` 都给时不做避让**（用户显式指定的位置原样使用，允许有意重叠）。
  源节点右侧 50 列 × 20 行都被占满时显式失败（`MOLIAI_ARG_INVALID`），不会静默叠上去。

#### 预设图派生（`panorama` / `three-view` / `nine-grid` / `portrait-texture`）

四个场景共用一套实现，差异只在配置表（nodeType / 默认名 / 预设字段 / taskType）：

| 场景 | nodeType | 默认节点名 | 节点预设字段 | 生成 taskType |
|---|---|---|---|---|
| `panorama` | `panorama_image` | `720° 全景图` | `modelParams={aspectRatio:"2:1",resolution:"4k"}`、`panoramaPreviewMode=false` | `panorama_image` |
| `three-view` | `three_view` | `角色三视图` | `layoutPreset="画面版式:三视图"` | `image` |
| `nine-grid` | `nine_grid` | `多机位九宫格` | `anglePreset="机位视角:九宫格"` | `image` |
| `portrait-texture` | `portrait_texture` | `人像质感调节` | `promptPreset="人景融合:自然融合;光影融合:自然匹配;皮肤:自然肤质;纹理:自然纹理;锐度:标准清晰"` | `image` |

**`panorama` 的 taskType 是 `panorama_image`，不是 `image`。**

```bash
# 只建节点 + 建连线（零扣费）
moliai derive three-view <image节点>
moliai derive panorama <image节点> --model tencent::gpt-image-2

# 先报价再决定是否生成
moliai derive panorama <image节点> --model tencent::gpt-image-2 --dry-run --run

# 真实生成（会扣费）
moliai derive nine-grid <image节点> --model qwen-image::qwen-image-2.1 --set aspectRatio=1:1 --run --wait 90
```

关键约束：

- **源节点**必须是 `image`，或 `super_resolution` 且 `superResolutionType=image`（图片超分）；
  且 `mediaUrl` 非空、`status` 不是 `uploading`/`generating`。图片超分会把超分后的 `mediaUrl` 作为参考图。
- **源 → 新节点建的是 `manual` 连线**（不写 `derivationType`，与网页端一致）。
- **这四个场景不走派生事务端点**，因此没有 `operationId` 语义：
  - 建节点（`POST /nodes`）与建连线（`POST /connections`）**都没有幂等键**，
    重复执行会产生重复节点/重复连线，需要手工清理（`node delete` / `connection delete --ids`）。
  - `--client-request-id` / `--operation-id` 只作用于最后的 `/generate` 提交（同名互斥校验，省略自动生成 UUID）。
- **`--run` 必须给 `--model`**：新节点上没有可继承的 `modelKey`，CLI 不猜默认模型。
  给了 `--model` 时也会写进节点 `modelKey`，后续可用 `moliai run` 直接重跑。
- **panorama 模型白名单**（后端硬编码，CLI 本地同样拦）：`tencent::gpt-image-2` /
  `openai::gpt-image-2` / `framefly::gpt-image-2`；其它模型 → `MOLIAI_ARG_INVALID`
  （后端报 `PANORAMA_MODEL_UNSUPPORTED`）。后端提交时还会强制 `aspectRatio=2:1` 并补 `resolution=4K`。
- **`--set <key=value>`** 透传生成参数（可重复，值按 JSON 解析）。部分模型（如 `qwen-image-2.1`）
  没有显式尺寸会直接失败（`UNSUPPORTED_IMAGE_SIZE`），此时需要 `--set aspectRatio=1:1`；
  各模型支持的比值/分辨率见 `moliai model list` 与网页端参数面板。
- 三个 image 场景把预设（`layoutPreset`/`anglePreset`/`promptPreset`）随生成请求一起提交，
  后端把它们作为内容来源，因此**可以不给 `--prompt`**；给了就原样作为提示词。
- `--dry-run --run` 的 `estimatedCost` 与真实扣费同口径（panorama 会把后端注入的 `2:1`/`4K` 计入报价）。
- 后端无 `panoramaEnabled` 字段（该标记由前端按 nodeType 派生），CLI 不下发；CLI 只写
  `panoramaPreviewMode`（后端可空布尔，`null` = 不修改）。

#### 超分派生（`super-resolution`：图片 / 视频）

超分按**源节点类型**决定模式，不需要手选：

| 源节点 | 模式 | `taskType` | 必填目标参数 | 目标写法 |
|---|---|---|---|---|
| `image`（或 `super_resolution` 且 `superResolutionType=image`） | 图片超分 | `super-resolution-image` | `--size` **或** `--width`+`--height` | 档位：`720p` / `1080p` / `2k` / `4k`；或像素（整数 1–4096） |
| `video`（或 `super_resolution` 且 `superResolutionType=video`） | 视频超分 | `super-resolution-video` | `--resolution` | `720P` / `1080P` / `2K` / `4K`（**大小写敏感**） |

```bash
# 图片超分：先报价（0.4 魔力值），确认后再真跑
moliai derive super-resolution <image节点> --size 1080p --dry-run --run
moliai derive super-resolution <image节点> --size 1080p --run --wait 120

# 图片超分：按像素指定（与 --size 二选一）
moliai derive super-resolution <image节点> --width 2048 --height 2048 --run

# 视频超分：只报价不跑（按秒计费，贵）
moliai derive super-resolution <video节点> --resolution 1080P --dry-run --run

# 视频超分：显式指定节点回写的时长（不影响计费时长，计费由后端解析源视频）
moliai derive super-resolution <video节点> --resolution 1080P --duration 10 --run
```

**档位换算（照抄网页端 `resolveSuperResolutionTargetDimensions`）**：目标**短边**取档位短边
（`720p→720`、`1080p→1080`、`2k→1440`、`4k→2160`），长边按**源宽高比**换算（四舍五入）；
图片长边超过 4096 时宽高等比缩到长边 4096（不裁切、不变形）。例：源 `1024×1024` + `--size 1080p`
→ 目标 `1080×1080`；源 `1920×1080` + `--size 1080p` → 目标 `1920×1080`（短边 1080，与源短边相同）。

> ⚠️ **不降级校验由 CLI 强制实现（后端不校验！）**
>
> 后端只校验目标边长在 1–4096 之间，**不校验「目标必须大于源」**——降级请求会正常受理并扣费，
> 产出反而更模糊的图。因此 CLI 与网页端同口径拦截：
> `min(targetWidth, targetHeight) > min(sourceWidth, sourceHeight)`，否则
> `MOLIAI_ARG_INVALID`「目标分辨率必须高于源分辨率」（退出码 2，零提交、零扣费）。
> 视频同样校验（`--resolution` 的短边必须大于源短边）。源节点缺 `mediaWidth`/`mediaHeight`
> 时无法判断，也会直接拒绝（不会猜）。

**价格表**（`tencent::mps-super-resolution`）：

| 类型 | 计费口径 | 价格 |
|---|---|---|
| 图片 | 按**目标短边**分档 × 次数 | `720p` 0.2 / `1080p` 0.4 / `2k` 0.8 / `4k` 1.6 / `8k` 3.2 魔力值 |
| 视频 | 按 `resolution` × **实测时长（秒）** × 次数 | `720P` 0.25 / `1080P` 0.5 / `2K` 1.0 / `4K` 2.0 / `8K` 8.0 魔力值**每秒** |

实测：图片 `1024×1024 → 1080×1080` 扣 **0.4**；视频 `1280×720 → 1080P`（源 4.064 秒）报价 **2**
（0.5/秒 × 4 秒，服务端时长取整口径 `Math.max(1, trunc(duration))`）。

关键约束：

- **Worker 不建新节点，结果回写到 `targetNodeId`**（即本命令创建的超分节点）：
  `mediaUrl` / `mediaId` / `mediaWidth` / `mediaHeight` / `generationModel` /
  `superResolutionType` / `origin=ai_generated`（创建时是 `manual`）。
  所以 `--run` 后产物就在超分节点上，不是另一个节点。
- **`model` 固定 `tencent::mps-super-resolution`**（后端省略时也自动补该值）；CLI 显式下发，
  不依赖隐式默认，也不允许换模型。
- **`sourceUrl` 取源节点 `mediaUrl`**（画布内的 storageKey，后端会解析成可访问地址）；
  `sourceWidth`/`sourceHeight` 取源节点 `mediaWidth`/`mediaHeight`（不是节点矩形 `width`/`height`）。
- **建节点与建连线都没有幂等键**：重复执行会产生重复节点/连线，需要手工清理
  （`moliai node delete <id> --yes`，删节点时后端级联删连线）。
  `--client-request-id` / `--operation-id` 只作用于最后的 `/generate` 提交。
- **`--run` 必过 `--max-cost` 闸门**：预估（含 count）超过上限或无法预估时零提交。
- `--dry-run --run` 的 `estimatedCost` 与真实扣费同口径（图片按短边档位、视频按秒 × 取整时长）。
- `--duration` 只写进提交体 `options.duration`（影响节点回写的 `duration`），**不改变计费时长**；
  不传时后端自己用 `DescribeMediaMetaData` 解析源视频。
- 视频超分按秒计费，先用 `--dry-run --run` 看价；`--wait` 默认 120 秒，超时用
  `moliai wait <jobId>` 继续。
- `--expected-version` 走节点创建的 `expectedCanvasVersion`（版本不匹配 → 409），
  省略则不校验（与其它 derive 场景一致）。

#### 涂鸦重绘（`image-edit`）

```bash
# 本地文件作为涂鸦图：先报价（2 魔力值/张，价格由模型决定），确认后真跑
moliai derive image-edit <image节点> --doodle ./doodle.png \
  --model wetoken::doubao-seedream-5-0-260128 --dry-run --run
moliai derive image-edit <image节点> --doodle ./doodle.png \
  --model wetoken::doubao-seedream-5-0-260128 --prompt "把涂鸦区域改成红色" --run --wait 180

# 已有整图（http/https）直接用，不上传
moliai derive image-edit <image节点> --doodle https://cdn.aidancevid.com/doodles/xxx.png --dry-run

# 只建节点与连线（零扣费）
moliai derive image-edit <image节点> --doodle ./doodle.png
```

> ⚠️ **`--doodle` 必须是「源图 + 涂鸦」的完整整图，不是 mask。**
>
> 后端不把 `doodleImage` 当蒙版用：它会把这整张图**追加到参考图末尾**，并在 prompt 前自动加上固定前缀
> 「对涂鸦区域重绘，涂鸦区域重绘后，去掉涂鸦。」。传 mask（黑底白洞）会得到一张按 mask 结构重画的图。
> CLI **不会**自己再加这段前缀（后端已加，重复会出现两次）。

关键约束：

- **源节点必须是 `image`** 且有 `mediaUrl`、`status` 不是 `uploading`/`generating`。
- **`--doodle` 本地文件 → 先上传**（`POST /canvases/{id}/upload-doodle`，multipart）：
  图片按后端契约**必须带 `width`/`height`**（`MediaSpecNormalizer.validateSpecs` 对 image 强制），
  因此 CLI 会先按文件头解析宽高（PNG/JPEG/WebP）；解析不出直接失败（不猜、不发不合法的请求）。
  上传上限 200MB，图片会被后端统一转成 PNG 落库（`key` 形如 `doodles/{canvasId}/{uuid}.png`）。
  `http(s)://` 开头的 `--doodle` 直接当完整 URL 用，不上传。
- **尺寸一致性只警告不阻断**：本地涂鸦图能读到宽高时，与源节点 `mediaWidth`/`mediaHeight` 比较，
  不一致给 `DOODLE_SIZE_MISMATCH` 警告（模型会拉伸对齐，重绘区域可能偏移），不会拒绝执行。
  URL 形式的涂鸦图无法在本地读尺寸，跳过该检查。
- **结果节点由 CLI 预创建**（`nodeType=image`，默认名「涂鸦重绘」）+ `manual` 连线，
  `--run` 时以 `targetNodeId` 指向它，**Worker 回写到该节点**（不是另建节点）。
- **`--run` 必须给 `--model`**（新节点上没有可继承模型，CLI 不猜）；给了 `--model` 也会写进节点 `modelKey`。
- **计费**：`apiType=image`，价格由模型定价表决定（例：`wetoken::doubao-seedream-5-0-260128` = 2 魔力值/张；
  `qwen-image::qwen-image-2.1` = 0.5/张）。`--dry-run --run` 先看 `estimatedCost`，`--max-cost` 在提交前拦截。
- 建节点 / 建连线 / 上传都没有幂等键：重复执行会产生重复节点/连线，需要手工清理
  （`--client-request-id` / `--operation-id` 只作用于最后的 `/generate` 提交）。
- `--dry-run` 零网络写入：本地涂鸦图**不会上传**（只读文件头拿尺寸）。

#### 视频编辑（`video-edit`）

```bash
# 默认只预览 + 报价（零写入、零扣费）
moliai derive video-edit <video节点> --model tokenproto::doubao-seedance-2-5-260628 \
  --prompt "把背景换成雪天" --resolution 720p

# 确认真实价格后显式 --run 才提交（很贵，见下表）
moliai derive video-edit <video节点> --model tokenproto::doubao-seedance-2-5-260628 \
  --prompt "把背景换成雪天" --resolution 720p --max-cost 200 --run --wait 300

# 带参考素材（图片/视频/音频按节点类型自动映射 mediaType）
moliai derive video-edit <video节点> --model tokenproto::doubao-seedance-2-5-260628 \
  --resolution 720p --ref <图片节点> --ref <第二段视频节点> --ref-label 角色 --ref-label 参考片段

# 只想验证请求体合法而不想花钱：用极低预算触发提交前拦截（会走到 prepare，零提交零扣费）
moliai derive video-edit <video节点> --model tokenproto::doubao-seedance-2-5-260628 \
  --resolution 720p --run --max-cost 0.1
```

> 💸 **价格警告：视频编辑按秒计费，`720p` 24 魔力值/秒、`480p` 12 魔力值/秒。**
>
> 计费秒数 = 后端**实测源视频时长向上取整**（例：4.064 秒 → 5 秒），
> 所以 `720p` 5 秒 = **120 魔力值**、10 秒 = **240 魔力值**（10 × 24）。
> 因此本命令**默认不提交**：不加 `--run` 只输出预览与 `estimatedCost`，加 `--run` 才真跑。

关键约束：

- **源节点必须是 `video`** 且有 `mediaUrl`、有 `duration`；源时长必须在 **4–30.2 秒**之间
  （后端实测口径，`< 4s` 或 `> 30.2s` 直接 400）。
- **CLI 绝不传 `targetNodeId`**：传了 Worker 就会走「回写既有节点」分支，结果节点不会带
  `derivationType=video_edit`、也不会有派生连线。正确形态是让 Worker 新建节点：
  `derivedFromNodeId=源节点`、`derivationType=video_edit`、**`derivationOperationId=taskId`**。
- **结果节点靠反查定位**：`--run` 完成后 CLI 拉画布找
  `derivationType === 'video_edit' && derivationOperationId === taskId` 的节点，
  输出 `resultNodeId` / `resultNodeMediaUrl`。反查不到时**如实告警并返回 null**（不伪造节点 id）。
- **`targetPosX` / `targetPosY`**：取 `--x/--y`；不给时按源节点右侧自动定位（同一套避让算法）。
  这是 Worker 新建结果节点的位置来源。
- **`sourceExpectations` 由 CLI 先 prepare**：`taskType=video` 且有视频来源时后端强制要求，
  且条数必须与**实际视频消费**精确相等。CLI 为「源视频 + 视频类 `--ref`」逐条调
  `reference-media/prepare`（图片/音频 ref 不计入），多一条少一条都会 409 `CANVAS_REFERENCE_SPEC_CONFLICT`。
- **`frameAnnotations` 恒为空数组**：CLI 不做帧标注（后端接受空数组，无最小条数）。
  需要帧标注请在网页端操作。
- **`--duration` 不生效**：后端在 `videoEdit` 分支会 `remove("duration")`，输出时长与计费秒数都跟随源视频；
  CLI 仍接受该参数但只回一条 `DURATION_IGNORED` 警告（不静默忽略，也不假装它有用）。
- **禁止首尾帧**：视频编辑不支持 `firstFrameUrl`/`lastFrameUrl`（后端 400 `VIDEO_EDIT_NO_FRAME_CONTROL`），CLI 也不提供该参数。
- **`--resolution` 只接受小写 `480p` / `720p`**，且 `--run` 时必须显式给出（CLI 不替你选贵档位）。
- 素材上限：图片 ≤30、视频 ≤10、音频 ≤10、总数 ≤50（后端硬校验）。

#### 音视频分离（`audio-separation`）与音频处理（`audio-process`）

两个场景都在**本地**用 ffmpeg 处理完再上传，最后调事务端点一次性落库。
**只创建节点与派生连线，不提交生成任务、不扣费**（后端这两个端点没有计费分支）。

```bash
# 音视频分离：一个视频节点 → 无声视频节点 + 分离音频节点 + 两条派生连线
moliai derive audio-separation <video节点> --dry-run     # 先看步骤与坐标（零写入）
moliai derive audio-separation <video节点>               # 真跑（不扣费）

# 音频处理：截取（区间至少 0.5 秒）
moliai derive audio-process <audio节点> --trim-start 0.5 --trim-end 3.7

# 音频处理：变速（保调，0.1–4.0；只改时长，不改音高）
moliai derive audio-process <audio节点> --speed 1.5

# 输入是超分视频节点也可以分离
moliai derive audio-separation <超分视频节点> --name "对白-无声" --x 3000 --y 800
```

| 场景 | 端点 | 产出 |
|---|---|---|
| `audio-separation` | `POST /canvases/{id}/derivations/video-audio-separation` | 无声 `video` 节点 + `audio` 节点 + 2 条 `derivation` 连线（`derivationType=video_audio_separation`） |
| `audio-process` | `POST /canvases/{id}/derivations/audio-processing` | 结果 `audio` 节点 + 1 条 `derivation` 连线（`derivationType=audio_processing`） |

执行顺序（两个场景一致）：

1. 下载源节点媒体（节点 `mediaUrl` 是裸 storageKey，CLI 先归一成 CDN 直链再下）
2. ffmpeg 本地处理（分离：抽音轨 + 去音轨；处理：截取或变速）
3. 上传处理结果（四段式分片上传 → 拿到 `storageKey` + `mediaId`）
4. 提交事务端点（用上传返回的 CDN 地址作为节点 `mediaUrl`）

关键约束：

- **分离的 `audio.mediaId` 是硬校验**：后端要求它指向 `media_objects` 里已登记、mime 为 `audio/*` 的记录，
  否则 400 `INVALID_PARAMS:分离音频未登记，请重新上传`。CLI **总是先上传**再提交，不会传空 `mediaId`。
- **音频输出只能是 wav**：后端上传白名单（`AudioFormatPolicy`）把音频格式硬编码为 `{wav, mp3}`，
  m4a/aac/ogg/flac 会被 400 `DOODLE_IMAGE_TYPE_INVALID` 拒绝；而 mp3 编码器按许可证红线不使用
  → 唯一组合是 **PCM wav**（无损）。代价是体积大（48kHz 立体声 s16 约 **1.4MB / 10 秒**）。
- **变速是保调的**：`atempo` 是 WSOLA 时间伸缩，只改时长不改音高（实测 440Hz 正弦 2 倍速后基频仍 ≈438Hz）。
  倍率 0.1–4.0（与后端白名单一致），超出单级 0.5–2.0 时 CLI 自动串联多级（`atempoChain`）。
- **截取区间**：`--trim-start` / `--trim-end` 必须成对给出，`end > start` 且差值 **≥ 0.5 秒**
  （CLI 与后端同口径校验，零上传前就拦）。`-ss` 在 `-i` 之前 + `-t` 取长度，避免 `-to` 的时间基准歧义。
- **截取与变速互斥**（后端 `processing.type` 只接受单一类型）；两个都不给会显式报错。
- **连线 `arrow` 恒为 `false`**：后端对 `audio-processing` 强制要求（`true` → 400）。
- **幂等键是 `operationId`**（`--operation-id` / 别名 `--client-request-id`，省略自动生成 UUID）：
  同 `operationId` 重试返回既有结果；同 `operationId` 不同请求体 →
  409（`AUDIO_PROCESSING_OPERATION_CONFLICT`）。
- **源节点类型**：分离必须是 `video` 或 `super_resolution(superResolutionType=video)`；
  处理必须是 `audio`（`voice` 节点不是 `audio`，会被后端 400 `AUDIO_PROCESSING_SOURCE_TYPE_INVALID`）。
- **定位**：无声视频按标准派生定位（源节点右侧避让），分离音频放在同一列的下一个空位
  （源节点正下方那列）；`--x/--y` 同时给出时不避让。
- **失败会保留本地工作目录**（下载与处理产物），成功才按 `--keep-work-files` 决定是否保留，
  `workDir` 字段回显保留路径。
- `--expected-version <n>` 传画布结构版本基线，不匹配时 409（与其它派生场景一致）。

#### 网格切图（`from-grid`）

把一张图片按 `rows × columns` 切成 N 张，**上传后逐张创建 `image` 节点，并从源节点各建一条
manual 连线**。只建节点与连线，**不提交生成、不扣费**。

```bash
# 2×2 切图：源图右侧自动定位，创建 4 个 image 节点 + 4 条 manual 连线
moliai derive from-grid <image节点> --rows 2 --columns 2

# 指定首个结果节点位置（其余按网格顺延）
moliai derive from-grid <image节点> --rows 3 --columns 3 --x 200 --y 800

# 源图格子之间本身有间隔时：--gap 告诉 CLI 每格之间空了多少像素（间隔不进入产物）
moliai derive from-grid <image节点> --rows 2 --columns 2 --gap 12
```

| 参数 | 说明 |
|---|---|
| `<nodeId\|nodeName>` | 源节点，**必须是 `image`** 且 `mediaUrl` 非空 |
| `--rows <n>` / `--columns <n>` | **必填**，≥1 的整数 |
| `--x/--y` | 首个结果节点坐标；都不给时按源节点右侧避让算法定位 |
| `--gap <px>` | 源图格子之间的间隔像素（默认 0），≥0 的整数 |
| `--ffmpeg <path>` | ffmpeg 可执行文件路径（优先级最高；也可 `MOLIAI_FFMPEG` 或 PATH） |

切图口径（`gap=0`）：按「左/右边界各自取整后相减」切分，**余数归最后一格**，
因此所有格子拼起来正好覆盖源图、不丢像素也不重叠。`gap>0` 时先扣掉 `count-1` 个间隔再等分，
间隔不进入产物。

输出：`sourceNodeId` / `sourceName` / `rows` / `columns` / `gap` / `sourceWidth` / `sourceHeight` /
`cellWidth` / `cellHeight` / `createdNodeCount` / `createdConnectionCount` / `nodes[]`
（每项含 `nodeId` / `connectionId` / `x` / `y` / `storageKey` / `mediaId` / `cropX` / `cropY` / `cropWidth` / `cropHeight`）。

> 节点与连线**没有幂等键**：重复执行会产生重复节点/连线。中途失败时错误 `details.createdNodes`
> 列出已创建的节点（不自动回滚，避免制造新的不确定性），核对后用 `node delete` 清理。

### 长任务

| 命令 | 说明 | 最小示例 |
|---|---|---|
| `jobs` | 列出本地作业记录（`--active` / `--all`（=`--everywhere`）/ `--label <文本>` / `-c <canvasId>`） | `moliai jobs --active --label agent-a` |
| `jobs show` | 单条作业完整记录，并顺带核对远端真实状态 | `moliai jobs show <jobId>` |
| `jobs prune` | 清理已结束且超期的作业文件（默认 7 天） | `moliai jobs prune --older-than 7d` |
| `wait` | 按 jobId 分轮等待（`--max` 默认 60，上限 90；`--until done\|change\|any-failed`；`--notify` 终态通知）；`--all-active` 汇总等待所有活跃任务 | `moliai wait <jobId> --max 60` |
| `wait --all-active` | 等待当前所有活跃任务（`queued` / `processing`）到终态，汇总输出 | `moliai wait --all-active --max 60` |

`--all-active` 的口径：

- **只算 `queued` + `processing`，`paused` 不算活跃**（`paused` 已停在前端，不会自行恢复）
- 与 `jobId` 互斥；当前没有活跃任务时报 `MOLIAI_JOB_NOT_FOUND`（不是成功空结果）
- 输出 `{ total, done, failed, stillActive, tasks[] }`（`tasks[]` 含每个任务的 `status` / `progress` / `mediaUrl` / `errorCode`）
- 超过 `--max` 仍在跑时**正常返回**（不报错）：`stillActive > 0` 并带 `WAIT_TIMEOUT` warning，再次执行同一条命令继续等
- 单个任务失败不会中断整批等待：计入 `failed`，其余任务继续等到终态

## 生成与成本

`run` 是会真实扣减魔力值的命令；`derive depth-capture --run` / `derive video-continuation --run` /
`derive super-resolution --run` / `derive image-edit --run` 在创建节点后会提交生成任务，同样会扣费
（不传 `--run` 时只建节点、不扣费）。**`derive video-edit` 例外：默认只预览报价，必须显式 `--run` 才提交**
（720p 24 魔力值/秒）。

```bash
# 1) 先预演：零成本，只算不提交
moliai run "主图" --dry-run \
  --model <provider>::<modelId> \
  --prompt "一只在雪地里的柴犬，电影感光线" \
  --set aspectRatio=1:1 --set resolution=1K

# 2) 看 data.estimatedCost 与 warnings，确认无误后再真实提交
moliai run "主图" \
  --model <provider>::<modelId> \
  --prompt "一只在雪地里的柴犬，电影感光线" \
  --set aspectRatio=1:1 --set resolution=1K --wait 120

# 3) 加上成本上限：预估超过上限（或无法预估）时直接拒绝，不提交、不扣费
moliai run "主图" --max-cost 2 \
  --model <provider>::<modelId> --prompt "一只在雪地里的柴犬"
```

关于 `estimatedCost`：

- 它是本次提交的**预估**消耗，不是最终账单
- **`estimatedCost: null` 不代表免费**，只代表当前算不出来（原因写在 `warnings` 里）。拿不到成本时要主动告知使用者
- **视频成本 ≈ 单价 × 时长**，而且 `480p` 与 `720p` 的单价通常相差一倍。改动 `duration` 或 `resolution` 之后必须重跑 `--dry-run`
- 计费预估失败**不会阻断提交**，只写 warning——所以提交前要主动读 `warnings`（**例外**：传了 `--max-cost` 时，无法预估会直接拒绝，因为无法校验上限）
- 同一个 `--client-request-id` 重复提交会命中服务端幂等，不会重复扣费

### 成本上限：`--max-cost` / `MOLIAI_MAX_COST`

`run` 与 `group run` 都支持成本上限，判定发生在**提交之前**（拒绝时不会产生任何任务、不扣费）：

```bash
moliai run "主图" --max-cost 2 ...        # 本次预估上限 2 魔力值
MOLIAI_MAX_COST=2 moliai group run "第一幕" --execute   # 环境变量给整组设上限
moliai run "主图" --max-cost 10 ...       # 参数优先于环境变量
```

| 场景 | 结果 |
|---|---|
| 预估 ≤ 上限 | 正常提交，输出里带 `maxCost` |
| 预估 > 上限 | `MOLIAI_BUDGET_EXCEEDED`（退出码 5），`details.estimatedCost` / `details.maxCost`，**不提交** |
| 无法预估（`estimatedCost: null`） | 同上错误码，`details.source: "estimate-unavailable"`，**不提交** |
| 取值非法（负数/非数字） | `MOLIAI_ARG_INVALID`（退出码 2） |

与 `--no-estimate` 互斥：跳过预估后没有比较基准，两者不能同时使用（同时传直接 `MOLIAI_ARG_INVALID`）。
`--no-estimate` 会同时让成本闸门与余额预校验失效，并写进 `warnings`。

优先级：`--max-cost` > `MOLIAI_MAX_COST` > 不设上限。`--max-cost 0` 是有效值（任何消耗都超限）。

> ⚠️ 口径是**预估**：CLI 用与真实提交相同的口径（resolve 后的模型 + prepare 归一化参数）调用
> `/billing/estimate`，但**不保证实扣一定不超过上限**——后端最终按实际用量结算。

参考素材（`--ref-image` / `--ref-video` / `--ref-audio`）只来自显式参数，CLI 不会从画布连线去猜。默认会在 prompt 开头自动插入素材引用标记，`--no-auto-mention` 可关闭。

### 作业标签：`--label` / `MOLIAI_AGENT_LABEL`

多个 Agent 并行跑同一张画布时，用作业标签区分「这条作业是谁提交的」：

```bash
moliai run "主图" --label agent-a ...          # 写进本地作业记录
MOLIAI_AGENT_LABEL=agent-a moliai run "主图" ... # 等价的环境变量写法
moliai jobs --label agent-a                    # 只看自己提交的作业
```

优先级：`--label` > `MOLIAI_AGENT_LABEL` > 无标签。显式传空串（`--label ""`）会报 `MOLIAI_ARG_INVALID`，不会静默当作「没有标签」。

> ⚠️ **三个「label」同名不同物**，别混用：

| 写法 | 存在哪里 | 是什么 | 用途 |
|---|---|---|---|
| `run` / `group run` / `apply --run` / `derive --run` / `extract` 上的 **`--label`** | **CLI 本地作业记录**（`~/.moliai/jobs/*.json` 的 `label` 字段），**不发进请求体** | **作业标签**：本次提交的审计标记 | 并行 Agent 按标签筛自己的作业 |
| `connection create` / `connection update` 上的 **`--label`** | 后端连线记录里的连线标签字段 | **连线标签**：画布上连线的显示名 | 给画布连线命名，画布里人人可见 |
| `derive video-edit --ref-label` | 请求体里的参考素材别名 | **参考素材别名**：给参考素材起名 | 让提示词能引用到具体素材 |

- 作业标签**只写本地**，后端不知道它的存在（后端也没有作业概念）
- 作业标签**不影响生成结果**：同一个 `--set` / `--prompt` 换标签重跑，产物完全一样
- 支持范围：凡是会写作业记录的命令都支持——`run`（单节点与 `--where` 批量）、`group run`、`apply --run`、`derive` 各场景的 `--run`、`extract`
- 筛选：`moliai jobs --label <文本>`（精确匹配；`--label` 在这里是筛选条件，**不读** `MOLIAI_AGENT_LABEL`）
- 旧版本写的作业记录没有 `label` 字段，读出来是 `null`（向后兼容，不会报记录损坏）

### 完成通知：`--notify`

`run` / `wait` 在**作业到达终态时**通知一次；`extract` 与 `derive * --run`（深度捕捉 / 视频续写 / 超分 /
全景 / 三视图 / 九宫格 / 人像质感 / 图像重绘 / 视频编辑）同样在作业终态通知一次；
`group run` / `run --where --execute` / `apply --run` **整批结束时只发一条汇总通知**（不是逐节点通知）：

```bash
# 1) 系统通知（Windows Toast / macOS 通知中心 / Linux notify-send）
moliai run "主图" --notify desktop ...

# 2) 执行一条本地命令（可接团队自己的消息工具）
moliai run "主图" --notify 'cmd:curl -s -X POST http://localhost:8080/notify -d "$MOLIAI_STATUS"' ...
moliai wait job_20261118T101530_a3f2c1 --max 90 --notify 'cmd:echo $MOLIAI_JOB_ID >> ~/done.log'

# 3) 批量：整批结束汇总一条，正文形如 [group run] 18 成功 / 2 失败（耗时 320 秒）
moliai group run "第一幕" --execute --notify 'cmd:sh ./on-batch-done.sh'
```

`cmd:` 的作业事实**全部通过环境变量传入**（不拼进命令字符串，避免命令注入）：

| 变量 | 含义 | 缺失时 |
|---|---|---|
| `MOLIAI_JOB_ID` | 作业 id（`job_...`） | 批量模式恒为空串 |
| `MOLIAI_TASK_ID` | 后端 taskId | 提交阶段就失败的作业为空串 |
| `MOLIAI_NODE_ID` | 画布节点 id | 批量模式恒为空串 |
| `MOLIAI_STATUS` | 终态：`completed` / `failed` / `paused` / `dismissed`；批量：有失败=`failed`，否则 `completed` | 一定存在 |
| `MOLIAI_MEDIA_URL` | 产物地址（后端原始值，不带签名） | 无产物/批量模式为空串 |
| `MOLIAI_ELAPSED_SECONDS` | 耗时（秒）；批量=整批耗时 | 未知时为空串 |
| `MOLIAI_JOB_LABEL` | 作业标签（`--label` / `MOLIAI_AGENT_LABEL`） | 无标签时为空串 |

批量汇总另有 `MOLIAI_BATCH_*` 一组变量（`run` / `wait` 单节点通知里不设置）：

| 变量 | 含义 | 示例 |
|---|---|---|
| `MOLIAI_BATCH_SCOPE` | 命令标识 | `group run` / `run --where` / `apply --run` |
| `MOLIAI_BATCH_SUCCEEDED` / `MOLIAI_BATCH_FAILED` / `MOLIAI_BATCH_SKIPPED` | 成功 / 失败 / 跳过节点数 | `18` / `2` / `0` |
| `MOLIAI_BATCH_ELAPSED_SECONDS` | 整批耗时（秒，与 `MOLIAI_ELAPSED_SECONDS` 同值） | `320` |
| `MOLIAI_BATCH_JOB_IDS` | 本次提交的 jobId，逗号分隔 | `job_a,job_b` |
| `MOLIAI_BATCH_FAILED_NODES` | 失败节点与错误码，逗号分隔 | `node1:MOLIAI_TASK_FAILED,node2:MOLIAI_REFERENCE_MISSING` |

> 批量模式下 `MOLIAI_JOB_ID` / `MOLIAI_TASK_ID` / `MOLIAI_NODE_ID` / `MOLIAI_MEDIA_URL` **恒为空串**
> （而不是「不设置」）：空串让你能稳定用 `-z` / `-n` 判断，也避免 shell 里遗留的旧值被误读成本次作业。
> 逐节点明细不在通知里 —— 命令输出的 `succeeded[]` / `failed[]` / `skipped[]` 与事后的 `moliai jobs`
> / `moliai jobs show <jobId>` 才是明细入口。

触发规则：

- **只在终态触发一次**：`run --wait 0` 提交后立即返回（`status=queued`）时不会通知，输出里会给 `NOTIFY_SKIPPED` 警告，提示改用 `moliai wait <jobId> --notify ...` 接续
- `wait` 只在「本次等待观察到进入终态」时通知；对已结束的作业再 `wait` 一次会返回 `NOTIFY_SKIPPED`，不重复通知
- 批量命令（`group run` / `run --where --execute` / `apply --run`）**整批结束发一条汇总**：20 个节点 = 1 条通知；
  fail-fast 中断（未加 `--continue-on-error`）同样会先发这条汇总再报错，`warnings` 里的通知失败会附在错误 `details.notifyWarnings`
- `--dry-run` / 预览模式不提交任务，`--notify` 会在 `warnings` 里说明未触发
- `extract` / `derive *` 的 `--notify` 只在真正提交生成时有意义：`--dry-run` 或未加 `--run`（如
  `derive video-edit` 默认只预览）时给出 `warnings` 说明本次不会触发，避免误以为已开启通知

失败与超时的处理（**通知永远不影响主流程**）：

| 情况 | 行为 |
|---|---|
| `cmd:` 退出码非 0 | 写出 `NOTIFY_FAILED` / `BATCH_NOTIFY_FAILED` 警告，作业结果照常返回（退出码不变） |
| `cmd:` 超过 10 秒 | 终止进程（Windows 用 `taskkill /T` 杀整棵进程树）并给对应警告 |
| 系统通知不可用（如 Linux 没装 `notify-send`） | 显式 `NOTIFY_DESKTOP_UNAVAILABLE` 警告并说明怎么装，**不静默跳过** |
| `--notify` 取值非法 | `MOLIAI_ARG_INVALID`（退出码 2），提交前就失败 |

> 只做本地命令与系统通知。飞书等第三方 webhook 由服务端统一实现（P2），CLI 不保存任何第三方凭据。


## 数据流向

诚实说明 CLI 会把什么发到哪里：

| 内容 | 去向 |
|---|---|
| 认证（KEY / 令牌）、提示词、生成参数、上传的素材 | **只发到当前 baseUrl**（不指定时就是内置默认的生产地址，可用 `--base-url` 切换到其它环境） |
| 下载产物、读取远端素材规格（分辨率/时长/文件头） | **直接访问 CDN `cdn.aidancevid.com`**，不经过你的 baseUrl |
| 令牌 | 仅存本地 `~/.moliai/credentials.json`（目录 0700、文件 0600），按环境分别保存 |
| KEY | 只从 stdin 读取，默认保存到本地 `~/.moliai/credentials.json`（文件 0600）用于令牌自动续期；`--no-save-key` 时不保存 |

- **没有独立遥测**：CLI 不会向任何第三方上报使用数据
- CLI **不跟随 HTTP 重定向**：避免把带凭据的请求体被 307/308 转到别的主机
- 作业记录（`~/.moliai/jobs/`）只保存定位与计费事实：`jobId` / `taskId` / `canvasId` / `nodeId` / 模型 / 预估成本 / **作业标签（`--label`，本次提交的审计标记）**，**不存令牌、不存提示词全文、不存带签名的媒体地址**

相关环境变量：

| 变量 | 作用 |
|---|---|
| `MOLIAI_BASE_URL` | 后端地址，优先级低于 `--base-url`、高于凭据文件里的默认环境；不设置时使用内置默认（生产）。切换环境不必改它，用 `moliai env use <url>` 即可 |
| `MOLIAI_TOKEN` | 直接提供令牌（覆盖本地凭据）；**必须同时设置 `MOLIAI_BASE_URL`**，否则报错。设置后不触发自动续期 |
| `MOLIAI_REFRESH_THRESHOLD_SECONDS` | token 自动续期阈值（秒），默认 `3600`：剩余有效期不足该值时用保存的 API KEY 换取新 token |
| `MOLIAI_CANVAS` | 当前画布 id，优先级高于目录绑定 |
| `MOLIAI_CONFIG_DIR` | 配置目录，默认 `~/.moliai` |
| `MOLIAI_CDN_DOMAIN` | 受信 CDN 域名清单（逗号分隔），默认 `cdn.aidancevid.com` |
| `MOLIAI_JOBS_DIR` | 作业记录目录 |
| `MOLIAI_AGENT_LABEL` | 作业标签默认值（优先级低于 `--label`）；只写本地作业记录，见「作业标签」 |

## Agent 集成

把 MoliAi Skill 装到宿主目录，Agent 就能自查命令与成本规则：

```bash
moliai setup --agent all --dry-run   # 先看计划
moliai setup --agent all             # 实际写入
moliai setup --agent all --check     # 复核
```

默认写入 `~/.agents/skills/moliai-cli-skill` 与 `~/.claude/skills/moliai-cli-skill`，安装后重启宿主会话生效。
也可以用支持 Skill 目录的通用方式安装：`npx skills add Mr-cjf/moliai-cli --skill moliai-cli-skill -g`（宿主支持 Skill 目录时可用）。若你本地 clone 了仓库，Skill 目录在仓库内的 `skills/moliai-cli-skill/`，复制到宿主的 skills 目录即可。（`@moliai/cli` 暂未发布到 npm，不存在 `node_modules/@moliai/cli/skills/moliai-cli-skill/` 这条路径。）

给 Agent 看的安装说明见 [INSTALL-FOR-AGENTS.md](./INSTALL-FOR-AGENTS.md)。

## 长任务

`run` 默认只等 90 秒，视频任务经常等不到结果，此时会返回：

```json
{ "done": false, "next": "moliai wait job_20261118T101530_a3f2c1" }
```

这是**正常返回**（退出码 0），不是失败。正确做法是分轮等待：

```bash
moliai wait job_20261118T101530_a3f2c1 --max 60
# 每轮最多等 90 秒；done:false 时 next 会指回同一条命令，照它继续调
```

- `run` 拿到 taskId 的那一刻就把 `jobId` / `taskId` 打到 stderr 并写入作业文件，所以进程被 Ctrl+C 或宿主超时杀掉也**不会丢 taskId**
- 跨会话找回：`moliai jobs --active`
- 中断（130/143）**不会取消远端任务**，任务还在跑，接续查询即可
- 不要靠提高 `--wait` 硬等：Agent 的单条命令超时通常会先把进程杀掉

## 常见错误

| 现象 | 说明与处理 |
|---|---|
| 401 / 认证失败 | KEY 或令牌无效、已过期。重新执行 `moliai login key` |
| `MOLIAI_NOT_BOUND` | 当前环境没登录过（通常是内置默认的生产环境）。`moliai env` 看 `currentSource`：`builtin-default` 表示还没绑定过任何环境，再 `moliai login key --base-url <url>` |
| 404 / 找不到资源 | id 写错，或该资源不属于当前账号。先 `moliai project list` / `canvas list` 核对 |
| 网络错误 / 超时 | 检查 `MOLIAI_BASE_URL` 是否写全（漏了 `/api`）、本机 DNS 与网络是否可达 |
| 未绑定画布 | 传画布参数，或先 `moliai canvas use <canvasId>` |
| 参数非法 | 报错会列出可选值。先 `moliai model <modelKey>` 或 `moliai run ... --dry-run` 看契约，不要盲试 |
| 429 / 限流 | 降低请求频率，稍后重试 |
| 409 状态冲突（`MOLIAI_CONFLICT`） | 画布版本已变化、节点已属其他编组、请求标识与内容不一致等。按 `hint` 重新读取最新数据后重试；**不需要**反馈 bug |
| 退出码 10 | 需要显式确认（如 `node delete` 没带 `--yes`） |

退出码分组：`0` 成功、`2` 参数/绑定错误、`3` 认证授权、`4` 网络/限流、`5` 配额与本地环境、`6` 任务失败、`7` 任务超时、`8` 登录超时、`9` 状态冲突、`10` 需确认、`130`/`143` 被中断。

### Windows 下的 JSON 输出是纯 ASCII

Windows 下 `--json` / `--output json|ndjson` 会把非 ASCII 字符转义为 `\uXXXX`，输出纯 ASCII：

```json
{ "ok": true, "data": { "name": "\u6d4b\u8bd5\u9879\u76ee" } }
```

原因：PowerShell 按系统代码页（如 936/GBK）解码子进程的 UTF-8 输出会乱码，管道里 `ConvertFrom-Json` 直接失败。
转义后与读取端编码无关，`ConvertFrom-Json` 能正常解析（解析后中文自动还原）。

- 只影响 **JSON 输出**；`--output text` 仍输出 UTF-8（人眼可读）
- 其它平台保持原样输出，不做转义

### 失败信封里的 traceId

错误输出固定带两个字段，**任何错误都有**（值可能是 `null`）：

| 字段 | 含义 |
|---|---|
| `traceId` | 服务端 traceId；本地错误/网络错误为 `null` |
| `traceIdSource` | `server` = 来自后端响应（体 `traceId`，或 `X-Trace-Id` / `X-Request-Id` 响应头，含 204 空响应）；`local` = 没有可用的服务端 traceId |

规则：

- **绝不伪造**：本地参数错误、网络错误不会塞一个随机值，否则用户会拿它去查不存在的日志
- HTTP 错误一律 `traceIdSource: "server"`（响应头没带时 `traceId: null` 但仍标 `server`）
- 业务错误（`MOLIAI_TASK_FAILED` / `MOLIAI_JOB_DEADLINE_EXCEEDED`）用最后一次轮询拿到的服务端 traceId
- `group run --execute` 的 `data.failed[].traceId` 是该节点失败对应的服务端 traceId

除 JSON 信封外，stderr 还会多打一行可直接复制：

```
错误 traceId: 0af0bc45cf8c43d1a7fa8f288fa95870（可用于反馈或查询服务端日志）
本地错误，无服务端 traceId
```

> `--trace-id` 只影响**成功信封**的 `traceId`；失败信封始终用服务端 traceId（或 `null`）。

## 已知限制

下面每一条都是**当前后端能力决定的既成事实**，不是 CLI 的缺陷。遇到时先对照本节，再判断是否反馈。

### 1. `storyboard stitch-inputs` 会因单个坏成员整组失败

- **现象**：`moliai storyboard stitch-inputs <组>` 返回 `422 CANVAS_STORYBOARD_RESOURCE_INVALID`，即使组里大部分成员都正常。
- **原因**：后端解析组内**全部有图成员**，只要有一个成员的 `media_objects.sha256` 为空（即用户上传产物），整组读取失败。
- **怎么办**：把上传的图片移出该组（`storyboard detach` / `storyboard transfer`），组内只保留 AI 生成的图。

### 2. 用户上传的图片不能作为分镜组成员

| 图片来源 | 能进分镜组 | 能拼接 |
|---|---|---|
| AI 生成（`moliai run` 产出） | ✅ | ✅ |
| 用户上传（`moliai upload` 产出） | ❌ 422 | ❌ |

- **原因**：AI 产物由任务回调登记，带 `sha256`；上传产物不带。
- **怎么办**：分镜组里只用 AI 生成的图。

### 3. `storyboard fill` 当前不可用

- **现象**：`moliai storyboard fill <组> --slot 0 -f photo.png` → `422 CANVAS_STORYBOARD_RESOURCE_INVALID`（换成 `MEDIA` kind 同样 422）。
- **原因**：`MediaObjectPersistenceService.persist` 不写 `sha256`，而槽位身份校验 `CanvasStoryboardResourceResolver.toIdentity` 要求 `sha256` 非空。
- **怎么办**：等后端补齐 sha256 写入与存量回填；临时改用 AI 生成的图片。

### 4. `storyboard stitch` 依赖后端新增的像素布局字段（当前 test 环境未部署）

- **现象**：`moliai storyboard stitch <组> -o out.png` → `MOLIAI_UNSUPPORTED`：
  「当前后端未提供拼接像素布局（stitch-inputs 缺少 cells/outputWidth/outputHeight）」。
- **原因**：CLI 按后端 `stitch-inputs` 新增的 `cells[]` / `outputWidth` / `outputHeight` 合成像素
  （`cellGap` / `padding` / `cellLongSide` 为组内持久化策略值）；旧构建不返回这些字段时
  **不本地推算几何**，直接显式失败（不下载、不上传、不写画布）。
- **怎么办**：等后端部署新契约后再用；临时排查可用
  `moliai storyboard stitch-inputs <组> --out snapshot.json` 导出快照自行合成。
- **注意**：即使部署后，后端输出尺寸是**纯网格比例**（按组框本地矩形轴向缩放），
  与网页端肉眼看到的 gap/padding 观感可能有细微偏差。

### 5. 网格切图是 `derive from-grid`，不是 `storyboard create --from-grid`

- **现象**：`moliai storyboard create --from-grid` 不存在。
- **原因**：分镜建组端点不接受「切图来源」语义；切图属于画布派生（建节点 + 建连线），
  因此实现为 `moliai derive from-grid <image节点> --rows N --columns N`（本地 ffmpeg 切图）。
- **怎么办**：切图用 `moliai derive from-grid`；把切出来的图建成**分镜组**再执行
  `moliai storyboard create --from-nodes <切出的节点...>`。

### 6. `diagnose` 走了本地降级（`source: "local"`）

- **现象**：`moliai diagnose` 能跑，但 `data.source` 是 `local`，`rerunnable` 恒为空，`warnings` 第一条是
  「后端未提供 Doctor 接口，使用本地扫描（仅 empty + failed）」。
- **原因**：`POST /canvases/{id}/doctor/reports` 返回 404 且 `serverCode` 不是业务码（缺失或 `NOT_FOUND`）
  → CLI 判定「后端没有这个路由」，降级为本地扫描（不是静默降级，warning 会明说）。
- **怎么办**：确认后端已部署含 Doctor 端点的构建（重刷 `/api` 网关路由）；部署后无需改 CLI。
  若要确认是不是业务错误，看 `data`/`details.serverCode`——`DOCTOR_*` / `CANVAS_*` 是业务码，CLI 会如实报错而不是降级。
- **注意**：5xx / 401 / 403 / 网络错误**不会**降级，会直接报错——那不是「后端未实现」，可能是故障。

| 命令 | 检查什么 | 状态 |
|---|---|---|
| `moliai doctor` | 本机 + 连接环境（版本、登录、网关可达、画布可用、模型清单） | ✅ 可用 |
| `moliai diagnose`（`source: server`） | **画布内容**：`empty` / `failed` / `rerunnable`（后端 Doctor 报告） | ✅ 可用（需后端已部署该端点） |
| `moliai diagnose`（`source: local`） | **画布内容**：`empty` / `failed`（本地降级，仅在后端无该路由时） | ✅ 可用 |

### 7. `run` 不支持部分节点类型

- **现象**：返回 `MOLIAI_UNSUPPORTED`。可提交的只有 `image` / `portrait_texture` / `three_view` / `nine_grid` / `panorama_image` / `video` / `video_synthesis` / `text`。
- **原因**：只允许已验证过的类型，避免产生未验证的生成任务。
- **怎么办**：`super_resolution` / `extract_*` / `audio` / `voice` 请用网页端操作（`extract_*` 用 `moliai extract`）；
  深度动作捕捉与视频续写用 `moliai derive depth-capture` / `moliai derive video-continuation`（创建节点），需要生成时再加 `--run`。

### 8. 没有 3D 导演台

- **现象**：后端有 `director_3d` 节点类型与 `director` 工程字段，CLI 无对应命令。
- **怎么办**：用网页端操作。

### 9. 429 默认不自动重试（只读 GET 可用 `--retry` 显式开启）

- **现象**：默认返回 `MOLIAI_RATE_LIMITED`，提示稍后重试，不自动重试。
- **原因**：网关限流为提交 10 次/分钟、查询 120 次/分钟（`group run` 的 6 秒提交节流已对齐前者）；
  全局 `--retry` 默认 `0`，所以默认不重试。
- **怎么办**：只读查询可以加 `--retry`（如 `moliai task list --retry 2`，指数退避 1/2/4/8/16 秒，上限 5）。
  **写命令（提交 / 取消 / 删除）永不重试**，并发跑多个 `group run` 或跑 30+ 节点的大组时撞上限流，只能等一会再跑。

### 10. 视频续写要求模型具备 reference profile

- **现象**：`moliai derive video-continuation <video> --model wetoken::bytedance-seedance-2-0-260128 --from 0 --to 4 --run`
  在**创建阶段**返回 `500 SEEDANCE_REFERENCE_PROFILE_UNAVAILABLE`（`No complete reference profile exists for this model`）：
  节点没建成、生成任务没提交、魔力值没扣。
- **原因**：创建端点按 `provider::modelId` 查后端 `standards/capabilities/image-video.catalog.json` 的
  `capabilities.video.referenceLimits`（未命中时再看路由组的组级 `referenceLimits`）。该模型当前只有定价、
  没有完整的 reference profile，因此报价能成功（`/billing/estimate` 只查定价）而创建被拒。
- **计费口径**：续写按**输出秒数**（`extensionDurationSeconds`）计费，选段只做合法性校验、不参与计费；
  计费档恒为 `reference` 档，故必须显式给 `--resolution`（720p / 480p）。实测 720p reference 档
  16 魔力值/秒（`--duration 4` → 64，`--duration 5` → 80）。
- **怎么办**：等后端补齐该模型的 `referenceLimits` 后再 `--run`；`--dry-run` 与节点预览不受影响。

### 11. 其他已知缺口

| 限制 | 说明 |
|---|---|
| `upload` 需要 canvasId | 上传按画布鉴权，没有通用上传通道；省略时只能靠 `MOLIAI_CANVAS` 或目录绑定 |
| `download --task` 只取首个产物 | `--count > 1` 时服务端只返回一个产物地址，其余产物取不到 |
| 没有 `canvas delete` | 需要在网页操作 |
| 没有独立的 `balance` 命令 | 余额用 `moliai whoami` 的 `balance` 查看（来自 `GET /user/balance`，含通用/会员/冻结） |
| 没有 `node restore` | 删除后的恢复要按 `node delete` 输出的 `restoreHint` 自行调用接口 |

## 支持与反馈

- 平台与账号问题：[aidancevid.com](https://aidancevid.com)
- 提交问题反馈时，请附上错误响应中的 `code` 与 `traceId`，便于定位
- 请勿在反馈中粘贴 API KEY、token 或完整凭据

## 测试交付说明

面向测试同学的安装、登录、命令速查与已知限制说明，见交付说明（内部文档，不随本仓库分发）。

## 许可证

本仓库包含两类许可：

| 范围 | 许可 |
|---|---|
| CLI 本体（`src/`、构建产物、可执行文件） | **专有软件，仅授权使用**。禁止修改、再分发、反向工程。详见 [LICENSE](LICENSE) |
| Agent Skill（`skills/` 目录） | **MIT License**。可自由使用、修改、分发。详见 [skills/moliai-cli-skill/LICENSE](skills/moliai-cli-skill/LICENSE) |

第三方依赖的许可声明见 [NOTICE](NOTICE)。
