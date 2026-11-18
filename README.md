# MoliAi CLI

> 本仓库仅包含使用文档与 Agent Skill，CLI 源码不公开。
> 可执行程序请从 Releases 下载。

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
     curl -fsSL https://raw.githubusercontent.com/Mr-cjf/moliai-cli/main/install.sh | sh
   - Windows PowerShell：
     irm https://raw.githubusercontent.com/Mr-cjf/moliai-cli/main/install.ps1 | iex
3. 验证安装：moliai --version（应为 0.1.0）、moliai doctor（看 healthy 是否为 true）
4. 安装 Agent Skill：moliai setup --agent all，然后 moliai setup --check 确认
5. 把登录命令原样给我，由我本人执行（不要向我要 API KEY，也不要把它写进任何文件或对话）：
   moliai login key --base-url https://test-api.aidancevid.com/api
   注意：目前只有测试环境可用，生产环境会返回 404。

铁律：
- 不要自动执行 moliai run 或其他会产生费用的命令
- 任何一步失败就停下报告原始错误，不要跳过、不要换镜像源、不要从源码构建
- 最后分三段汇报：安装状态 / Skill 状态 / 登录状态
```

**复制完等它跑完就行。** 后续所有命令见下方[命令清单](#命令清单)。

### 不知道该选哪种方式？

| 情况 | 怎么做 |
|---|---|
| 有 AI 编程工具（Claude Code / Codex / DSH） | 复制上面那段话给它 |
| 没有 AI 工具，用命令行 | `curl -fsSL https://raw.githubusercontent.com/Mr-cjf/moliai-cli/main/install.sh \| sh`（Windows 用 `irm https://raw.githubusercontent.com/Mr-cjf/moliai-cli/main/install.ps1 \| iex`） |
| 想自己控制 | 从 [Releases](https://github.com/Mr-cjf/moliai-cli/releases) 手动下载 |

---

## 开始之前

1. 打开 <https://aidancevid.com> 注册账号，并完成充值（生成任务消耗「魔力值」）
2. 在网页上**新建一个项目**——CLI 没有 `project create`，项目只能在网页创建

## 其他安装方式

### 一键脚本（推荐）

**macOS / Linux**

```bash
curl -fsSL https://raw.githubusercontent.com/Mr-cjf/moliai-cli/main/install.sh | sh
```

**Windows（PowerShell）**

```powershell
irm https://raw.githubusercontent.com/Mr-cjf/moliai-cli/main/install.ps1 | iex
```

脚本会：判断平台 → 下载对应版本 → 校验 SHA256 → 安装到 `~/.local/bin`（Windows 为 `%USERPROFILE%\bin`）→ 处理 PATH → 验证版本。

- macOS / Linux：安装目录不在 `PATH` 时脚本只**打印**需要追加的 `export` 行，不会自动改你的 shell 配置
- Windows：脚本只修改**用户级** `Path`，不动系统级；已改动的 `Path` 需要新开终端才生效

可用环境变量（sh 脚本）/ 参数（PowerShell 脚本）覆盖默认行为：

| 变量 / 参数 | 默认值 | 说明 |
|---|---|---|
| `MOLIAI_VERSION` / `-Version` | `v0.1.0` | 要安装的版本（含 `v` 前缀） |
| `MOLIAI_INSTALL_DIR` / `-InstallDir` | `~/.local/bin`（不可写时 `~/bin`）/ `%USERPROFILE%\bin` | 安装目录 |

不想直接管道执行，可以先下载审查：

```bash
# macOS / Linux
curl -fsSL https://raw.githubusercontent.com/Mr-cjf/moliai-cli/main/install.sh -o install.sh
less install.sh        # 看完再执行
sh install.sh
```

```powershell
# Windows
irm https://raw.githubusercontent.com/Mr-cjf/moliai-cli/main/install.ps1 -OutFile install.ps1
notepad install.ps1    # 看完再执行
.\install.ps1
```

### 手动下载

如果一键安装失败，也可从 [Releases](https://github.com/Mr-cjf/moliai-cli/releases) 手动下载对应平台的单文件可执行程序：

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

## 获取 KEY

在网页登录后进入 **API 配置 → 开发者配置**，复制其中的 KEY。

> ⚠️ 这个 KEY **等同于你的账号全权限**：可以创建/删除画布、提交生成并扣除魔力值，而且没有过期时间。
> 不要把它写进脚本、CI 配置或聊天记录，也不要交给来路不明的 Agent。

## 登录

```bash
moliai login key --base-url "https://dance.aidancevid.com/api"
# 按提示把 KEY 粘贴进去并回车（从 stdin 读取，不会进入 shell 历史）
moliai whoami
```

- KEY 只从 **stdin** 读取，不接受命令行参数
- KEY 本身**不落盘**；登录成功后保存的是它换来的令牌
- 令牌保存在本地 `~/.moliai/credentials.json`（目录 0700、文件 0600）
- **令牌按环境（`base-url`）分开保存**：登录测试环境不会覆盖生产环境的令牌，切换环境不需要重新登录
- `--base-url` 填 API 网关根地址（结尾带 `/api`）。CLI 没有内置默认地址，地址以官方控制台/文档为准；写错通常表现为 401 或 404

`moliai logout` 删除本地凭据（会删掉所有环境）。

## 多环境（测试 / 生产）

凭据文件是 v2 结构：每个 `baseUrl` 一份独立令牌，另有一个「默认环境」。登录新环境只写该环境的记录，不动其它环境。

```bash
# 1) 分别登录两个环境（各自一份令牌，互不影响）
moliai login key --base-url "https://test-api.aidancevid.com/api"
moliai login key --base-url "https://dance.aidancevid.com/api"

# 2) 看有哪些环境、当前的默认环境与本次实际会用的环境
moliai env

# 3) 切默认环境（直接用已保存的令牌，不需要重新登录）
moliai env use "https://dance.aidancevid.com/api"

# 4) 删掉某个环境的凭据（删的若是默认环境，默认自动切到剩下的一个）
moliai env remove "https://test-api.aidancevid.com/api"
```

`moliai env` 的输出：

```json
{
  "ok": true,
  "command": "env",
  "data": {
    "default": "https://test-api.aidancevid.com/api",
    "current": "https://test-api.aidancevid.com/api",
    "environments": [
      {
        "baseUrl": "https://test-api.aidancevid.com/api",
        "userId": "<your-user-id>",
        "nickname": "<your-nickname>",
        "expiresAt": "2026-11-25T08:05:02.000Z",
        "expired": false,
        "isDefault": true,
        "isCurrent": true
      }
    ]
  }
}
```

- `default`：什么都不指定时用的环境
- `current`：**本次调用实际会用的环境**，已经把 `--base-url` 与 `MOLIAI_BASE_URL` 算进去，可能不等于 `default`
- 单个命令临时换环境不必改默认：`moliai project list --base-url "https://test-api.aidancevid.com/api"`

### 环境解析优先级

```
--base-url <url>   （命令行，最高）
  > MOLIAI_BASE_URL   （环境变量）
  > credentials.json 的 defaultEnvironment
  > 都没有 → MOLIAI_NOT_BOUND（退出码 2）
```

选中环境后只用该环境的令牌；该环境没登录过时报 `MOLIAI_NOT_BOUND`，hint 会直接给出该环境的登录命令。

### 从旧版本升级

v1 的 `credentials.json`（顶层平铺 `baseUrl` + `token`）在第一次读取时**自动迁移**成 v2（该环境成为默认环境）并写回，无需手动操作；加 `--verbose` 可以看到迁移日志。

## 五分钟跑通（只读，零成本）

```bash
moliai status                 # 看配置目录、版本、登录状态、后端连通性
moliai project list           # 列出你的项目，拿到 projectId
moliai canvas list -w <projectId>   # 列出该项目下的画布
moliai canvas use <canvasId>  # 把画布绑定到当前目录（之后命令可省略画布参数）
moliai node list              # 看这张画布上已有的节点
moliai model list --type video      # 看你的账号能用哪些模型
```

这几步都不产生费用，也不修改任何数据。

## 命令清单

全局选项对每条命令都有效：

```bash
--output <json|ndjson|text>   # 输出格式，默认 json
--json                        # 等价于 --output json（优先级更高）
--compact                     # 单行紧凑 JSON
--quiet                       # 静默 stderr 上的进度信息
--verbose                     # stderr 输出调试信息
--trace-id <id>               # 指定 traceId（默认随机生成）
--fields <list>               # 只输出 data 里的指定字段，支持 a.b 与 a[].b
--base-url <url>              # 本次调用使用的后端地址（优先级最高）
-V, --version                 # 版本
```

### 认证

| 命令 | 说明 | 最小示例 |
|---|---|---|
| `login key` | 用网页「开发者配置」里的 KEY 换取令牌并保存（推荐） | `moliai login key --base-url "https://dance.aidancevid.com/api"` |
| `login token` | 直接粘贴一个 access token（备用路径） | `moliai login token --base-url "<url>"` |
| `logout` | 删除本地凭据（所有环境） | `moliai logout` |
| `env` | 列出已登录的环境、默认环境与本次实际环境 | `moliai env` |
| `env use <url>` | 把某环境设为默认（不用重新登录） | `moliai env use "https://dance.aidancevid.com/api"` |
| `env remove <url>` | 删除某环境的凭据 | `moliai env remove "https://test-api.aidancevid.com/api"` |
| `whoami` | 打印当前身份与令牌过期时间 | `moliai whoami` |
| `status` | 打印宿主、配置目录、版本、后端连通性 | `moliai status` |

### 安装与自检

| 命令 | 说明 | 最小示例 |
|---|---|---|
| `setup` | 把 MoliAi Skill 安装到 Agent 宿主目录 | `moliai setup --agent all --dry-run` |
| `doctor` | 本机自检：Node 版本、配置目录可写、宿主探测、网络沙箱信号 | `moliai doctor` |
| `help` | 命令树（人类可读；加 `--json` 输出结构化命令树） | `moliai help --json` |
| `schema <command>` | 单条命令的结构（参数、默认值、可选值、输出字段） | `moliai schema run` |

`setup` 支持 `--agent claude|codex|dsh|generic|all`、`--scope user`、`--check`、`--dry-run`、`--target-dir`。
`--upgrade` / `--uninstall` / `--quarantine` / `--dir` / `--set` / `--scope project` 尚未实现，使用时会明确报「不支持」。

### 项目

| 命令 | 说明 | 最小示例 |
|---|---|---|
| `project list` | 列出你的项目（`--limit` 1..200，默认 20） | `moliai project list --limit 10` |

### 画布

| 命令 | 说明 | 最小示例 |
|---|---|---|
| `canvas list` | 列出项目下的画布（`-w <projectId>`，省略时用目录绑定） | `moliai canvas list -w <projectId>` |
| `canvas show` | 画布详情 + 精简节点列表 | `moliai canvas show <canvasId>` |
| `canvas create` | 新建画布（不自动切换当前绑定） | `moliai canvas create "第一集分镜" -w <projectId>` |
| `canvas use` | 校验画布存在并绑定到当前目录 | `moliai canvas use <canvasId>` |
| `canvas unuse` | 解除当前目录绑定 | `moliai canvas unuse` |

### 节点

| 命令 | 说明 | 最小示例 |
|---|---|---|
| `node list` | 列出节点（`--type` / `--name-like` / `--limit`） | `moliai node list --type image` |
| `node create` | 创建节点（`-t` 必填，`--x/--y` 必填） | `moliai node create "开场画面" -t image --x 0 --y 0` |
| `node update` | 修改名称/坐标/文本/挂载素材 | `moliai node update <nodeId> --name "新名字"` |
| `node delete` | 删除节点（必须带 `--yes`，24 小时内可恢复） | `moliai node delete <nodeId> --yes` |

节点类型可选：`text` / `image` / `video` / `audio` / `super_resolution` / `panorama_image` / `portrait_texture` / `three_view` / `nine_grid` / `video_synthesis` / `depth_capture` / `voice`。

### 模型

| 命令 | 说明 | 最小示例 |
|---|---|---|
| `model list` | 列出账号可见模型（`--type image\|video`） | `moliai model list --type video` |
| `model search` | 按关键词搜索模型 | `moliai model search seedance` |
| `model <modelKey>` | 查单个模型的参数契约 | `moliai model <provider>::<modelId>` |

### 任务

| 命令 | 说明 | 最小示例 |
|---|---|---|
| `task list` | 列出任务（`--limit` / `--ids` / `--canvas` / `--client-request-id` / `--status`） | `moliai task list --canvas <canvasId> --limit 10` |
| `task get` | 查单个任务（`--events` 附带事件流） | `moliai task get <taskId>` |

### 素材

| 命令 | 说明 | 最小示例 |
|---|---|---|
| `upload` | 上传本地媒体到画布素材库，返回 `storageKey` 与 `mediaId` | `moliai upload ./cover.png <canvasId>` |
| `download` | 下载节点或任务的产物到本地（同名默认不覆盖，`--force` 覆盖） | `moliai download <nodeId> -o ./out` |

### 生成

| 命令 | 说明 | 最小示例 |
|---|---|---|
| `run` | 在画布节点上提交一次生成任务（**唯一扣费命令**） | `moliai run <nodeId> --dry-run --model <k> --prompt "<p>"` |

### 长任务

| 命令 | 说明 | 最小示例 |
|---|---|---|
| `jobs` | 列出本地作业记录（`--active` / `--all` / `-c <canvasId>`） | `moliai jobs --active` |
| `jobs show` | 单条作业完整记录，并顺带核对远端真实状态 | `moliai jobs show <jobId>` |
| `jobs prune` | 清理已结束且超期的作业文件（默认 7 天） | `moliai jobs prune --older-than 7d` |
| `wait` | 按 jobId 分轮等待（`--max` 默认 60，上限 90） | `moliai wait <jobId> --max 60` |

## 生成与成本

`run` 是唯一会真实扣减魔力值的命令。

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
```

关于 `estimatedCost`：

- 它是本次提交的**预估**消耗，不是最终账单
- **`estimatedCost: null` 不代表免费**，只代表当前算不出来（原因写在 `warnings` 里）。拿不到成本时要主动告知使用者
- **视频成本 ≈ 单价 × 时长**，而且 `480p` 与 `720p` 的单价通常相差一倍。改动 `duration` 或 `resolution` 之后必须重跑 `--dry-run`
- 计费预估失败**不会阻断提交**，只写 warning——所以提交前要主动读 `warnings`
- 同一个 `--client-request-id` 重复提交会命中服务端幂等，不会重复扣费

参考素材（`--ref-image` / `--ref-video` / `--ref-audio`）只来自显式参数，CLI 不会从画布连线去猜。默认会在 prompt 开头自动插入素材引用标记，`--no-auto-mention` 可关闭。

## 数据流向

诚实说明 CLI 会把什么发到哪里：

| 内容 | 去向 |
|---|---|
| 认证（KEY / 令牌）、提示词、生成参数、上传的素材 | **只发到你配置的 baseUrl**（CLI 没有内置默认地址；未配置时直接报错） |
| 下载产物、读取远端素材规格（分辨率/时长/文件头） | **直接访问 CDN `cdn.aidancevid.com`**，不经过你的 baseUrl |
| 令牌 | 仅存本地 `~/.moliai/credentials.json`（目录 0700、文件 0600），按环境分别保存 |
| KEY | 只从 stdin 读取，只用于换取令牌，不落盘 |

- **没有独立遥测**：CLI 不会向任何第三方上报使用数据
- CLI **不跟随 HTTP 重定向**：避免把带凭据的请求体被 307/308 转到别的主机
- 作业记录（`~/.moliai/jobs/`）只保存定位与计费事实：`jobId` / `taskId` / `canvasId` / `nodeId` / 模型 / 预估成本，**不存令牌、不存提示词全文、不存带签名的媒体地址**

相关环境变量：

| 变量 | 作用 |
|---|---|
| `MOLIAI_BASE_URL` | 后端地址，优先级低于 `--base-url`、高于凭据文件里的默认环境；切换环境不必改它，用 `moliai env use <url>` 即可 |
| `MOLIAI_TOKEN` | 直接提供令牌（覆盖本地凭据）；**必须同时设置 `MOLIAI_BASE_URL`**，否则报错 |
| `MOLIAI_CANVAS` | 当前画布 id，优先级高于目录绑定 |
| `MOLIAI_CONFIG_DIR` | 配置目录，默认 `~/.moliai` |
| `MOLIAI_JOBS_DIR` | 作业记录目录 |

## Agent 集成

把 MoliAi Skill 装到宿主目录，Agent 就能自查命令与成本规则：

```bash
moliai setup --agent all --dry-run   # 先看计划
moliai setup --agent all             # 实际写入
moliai setup --agent all --check     # 复核
```

默认写入 `~/.agents/skills/moliai-cli-skill` 与 `~/.claude/skills/moliai-cli-skill`，安装后重启宿主会话生效。

也可以用支持 Skill 目录的通用方式安装：把本仓库的 `skills/moliai-cli-skill/` 整个目录复制到宿主的 skills 目录。

基于 Skills CLI 的安装方式：

```bash
npx skills add Mr-cjf/moliai-cli --skill moliai-cli-skill -g
```

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
| `MOLIAI_NOT_BOUND` | 当前环境没登录过，或根本没有环境。`moliai env` 看现状，再 `moliai login key --base-url <url>` |
| 404 / 找不到资源 | id 写错，或该资源不属于当前账号。先 `moliai project list` / `canvas list` 核对 |
| 网络错误 / 超时 | 检查 `MOLIAI_BASE_URL` 是否写全（漏了 `/api`）、本机 DNS 与网络是否可达 |
| 未绑定画布 | 传画布参数，或先 `moliai canvas use <canvasId>` |
| 参数非法 | 报错会列出可选值。先 `moliai model <modelKey>` 或 `moliai run ... --dry-run` 看契约，不要盲试 |
| 429 / 限流 | 降低请求频率，稍后重试 |
| 退出码 10 | 需要显式确认（如 `node delete` 没带 `--yes`） |

退出码分组：`0` 成功、`2` 参数/绑定错误、`3` 认证授权、`4` 网络/限流、`5` 配额与本地环境、`6` 任务失败、`7` 任务超时、`8` 登录超时、`10` 需确认、`130`/`143` 被中断。

## 已知限制

| 限制 | 说明 |
|---|---|
| `upload` 需要 canvasId | 上传按画布鉴权，没有通用上传通道；省略时只能靠 `MOLIAI_CANVAS` 或目录绑定 |
| `download --task` 只取首个产物 | `--count > 1` 时服务端只返回一个产物地址，其余产物取不到 |
| 没有 `canvas delete` | 需要在网页操作 |
| 没有 `balance` | 余额请在网页查看 |
| 没有 `node restore` | 删除后的恢复要按 `node delete` 输出的 `restoreHint` 自行调用接口 |
| 没有 `--watermark` | 服务端无对应能力，CLI 也不提供该参数 |
| 没有 `project create` | 项目只能在网页创建 |
| `run` 不支持部分节点类型 | `audio` / `voice` / `super_resolution` / `depth_capture` 需要本命令签名之外的必填输入，会明确返回「不支持」 |

## 支持与反馈

- 平台与账号问题：[aidancevid.com](https://aidancevid.com)
- 提交问题反馈时，请附上错误响应中的 `code` 与 `traceId`，便于定位
- 请勿在反馈中粘贴 API KEY、token 或完整凭据

## 许可证

本仓库包含两类许可：

| 范围 | 许可 |
|---|---|
| CLI 本体（可执行文件、构建产物） | **专有软件，仅授权使用**。禁止修改、再分发、反向工程。详见 [LICENSE](LICENSE) |
| Agent Skill（`skills/` 目录） | **MIT License**。可自由使用、修改、分发。详见 [skills/moliai-cli-skill/LICENSE](skills/moliai-cli-skill/LICENSE) |

第三方依赖的许可声明见 [NOTICE](NOTICE)。
