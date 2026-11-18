---
name: moliai-cli-skill
description: 通过 moliai CLI 调用 MoliAi 能力：命令速查、成本安全规则（run 前必须先 --dry-run 看 estimatedCost）、参数校验与 400 可选值处理、破坏性操作确认、长任务轮询与错误信封解析。
metadata:
  version: "0.1.0"
---

# MoliAi CLI Skill

## 开始前

- `moliai status` 确认 `authenticated` 与 `baseUrl`；`moliai whoami` 确认身份。
- **多环境（测试/生产）时用 `moliai env` 确认当前环境**：`data.current` 是本次实际会用的环境（已含 `--base-url` / `MOLIAI_BASE_URL` 覆盖），`data.default` 是默认环境；两者可能不同。环境不对时先问用户，不要自己切。
- 未登录先 `moliai login key`（KEY 从 stdin 读，等同账号全权限，不要写进日志或 shell 历史）。
- 所有命令输出 JSON 信封：成功 `{ ok: true, command, data, warnings, traceId }`，失败 `{ ok: false, error: { code, message, hint, details }, traceId }`。失败信息在 stderr。
- 汇报时带上 `traceId`。

## 多环境

| 目的 | 命令 |
|---|---|
| 看有哪些环境 / 当前环境 | `moliai env` |
| 切默认环境（不重新登录） | `moliai env use <baseUrl>` |
| 删某环境凭据 | `moliai env remove <baseUrl>` |
| 单次调用临时换环境 | 任意命令加 `--base-url <url>` |

- 每个 `baseUrl` 一份独立令牌，登录新环境不覆盖旧环境
- `MOLIAI_NOT_BOUND` + hint 指向 `moliai login key --base-url <url>` = 该环境没登录过，让用户提供该环境的 KEY，**不要**复用别的环境的凭据
- `moliai logout` 会删掉**所有**环境；只想清一个环境用 `moliai env remove <url>`，且需用户同意

## 命令速查

| 目的 | 命令 |
|---|---|
| 当前环境 / 已登录环境 | `moliai env` |
| 身份/连通性 | `moliai whoami` |
| 项目 → 画布 | `moliai project list` → `moliai canvas list -w <projectId>` |
| 绑定画布到当前目录 | `moliai canvas use <canvasId>` |
| 看画布与节点 | `moliai canvas show` / `moliai node list --limit 200` |
| 查模型契约 | `moliai model list` / `moliai model search <kw>` / `moliai model <modelKey>` |
| 建节点 | `moliai node create "<名>" -t image --x 0 --y 0` |
| 上传素材 | `moliai upload <file> <canvasId>` → `storageKey` / `mediaId` |
| 预演生成（零成本） | `moliai run <node> --dry-run --model <k> --prompt "<p>" --set k=v` |
| 真实提交（扣费） | `moliai run <node> --model <k> --prompt "<p>" --set k=v --wait 60` |
| 长任务接续 | `moliai wait <jobId> --max 60` / `moliai jobs --active` |
| 查任务/下载 | `moliai task get <taskId>` / `moliai download --task <taskId> -o ./out` |

## 成本安全规则

1. **`run` 前必须先 `--dry-run`**，读 `data.estimatedCost`。这是唯一零成本路径（只调 prepare + billing/estimate，不建任务、不预扣费）。
2. `estimatedCost` 为 `null` 时**不代表免费**，只代表算不出来；同时看 `warnings` 里的 `ESTIMATE_UNAVAILABLE` / `ESTIMATE_UNSUPPORTED`。若拿不到成本，提交前必须告知用户。
3. **视频成本 ≈ 单价 × 时长**，`480p` 与 `720p` 单价通常差一倍。改 `duration` 或 `resolution` 后必须重跑 `--dry-run`。
4. **用户未明确要求时不真实提交**。默认只执行 `--dry-run`，把模型、参数、成本呈现给用户，等确认后再提交。
5. 重复提交用同一 `--client-request-id` 走后端幂等（`deduped=true`），不会重复扣费。

## 参数校验

- 有契约的模型：服务端严格校验。CLI 默认带 `X-Moliai-Strict-Validation: true`，缺必填参数或带未声明参数直接 400。
- 无契约的模型：CLI 用 `/api/user/models` 的 `capabilities` 本地校验；显式 `--set` 违规报 `MOLIAI_ARG_INVALID`（退出码 2），继承来的非法参数会被剔除并在 `warnings` 说明。
- **写错参数会报错并列出可选值**，例如 `参数 resolution 取值非法："4k"，可选值 "480p"/"720p"/"1080p"`。不要盲试组合；先 `moliai model <modelKey>` 看契约，或改 `--dry-run` 看 `parameters` 与 `paramValidation`。
- `count` 范围 1..4；`--wait` 上限 540 秒；`--deadline` 上限 86400 秒。

## 破坏性操作

- `moliai node delete <nodeId>` **必须带 `--yes`**，否则 `MOLIAI_CONFIRM_REQUIRED`（退出码 10），`details` 里会列出将删除的节点。
- 删除后 24 小时内可恢复：按输出里的 `restoreHint` 调 `POST /canvases/{canvasId}/node-deletions/{id}/restore`（CLI 无 `node restore` 子命令）。
- 向用户确认前，先把 `details` 里的节点名称/类型如实报出来。

## 长任务

- `--wait` 默认 90 秒，**视频经常不够**（实测 268 秒）。正确做法是**提交即返回 + 分轮 wait**，不要提高 `--wait` 硬等——Agent 单条命令 120 秒会先把进程杀掉。
- `run` 拿到 taskId 的那一刻就把 `jobId`/`taskId` 写进 stderr（`[run] 已提交 taskId=... jobId=...`）和作业文件，之后被中断也能接续。
- 未完成时 `run` 返回 `done: false` + `next: moliai wait <jobId>`（退出码 0，不是失败）。
- 接续：`moliai wait <jobId> --max 60`，每轮至多 90 秒；`done:false` 时 `next` 指回自己，照它继续调。
- 跨会话找回：`moliai jobs --active`（当前画布）/ `moliai jobs --all` / `moliai jobs show <jobId>`。
- 任务失败退出码 6；超过 `--deadline`（默认 3600）退出码 7；被中断退出码 130/143。
- 轮询要有上限与间隔（2 秒间隔，上限 90 秒一轮），不要无限重试；收到用户中断立即停止并如实汇报当前阶段与 jobId。

## 失败处理

- 先读 stderr 错误信封的 `error.code` 与 `error.hint`，不要只看退出码。
- 退出码：2 参数/绑定/模型选择，3 认证授权，4 网络或限流，5 配额与本地环境，6 任务失败，7 超时，8 登录超时，10 需确认。
- 参数与环境类错误不重试，按 hint 修正后重跑；网络/限流可有限次退避重试。
- 不静默兜底：不换模型、不删参数、不跳过失败步骤来"让它跑通"。未知错误码直接停止并向用户说明。

## 环境变量

`MOLIAI_BASE_URL`（后端地址覆盖，优先级低于 `--base-url`）、`MOLIAI_TOKEN`（覆盖本地凭据，必须同时设 `MOLIAI_BASE_URL`）、`MOLIAI_CANVAS`（当前画布）、`MOLIAI_CONFIG_DIR`（配置目录）、`MOLIAI_CDN_DOMAIN`（受信 CDN 域名）。

切环境优先用 `moliai env use <url>`，不要长期依赖 `MOLIAI_BASE_URL`——环境变量会盖过默认环境，容易让人误判当前用的是哪个环境。

**没有 `MOLIAI_PROJECT`**：项目 id 只能来自 `-w/--workspace` 或 `canvas use` 写入的目录绑定。
