---
name: moliai-cli-skill
description: 通过 moliai CLI 调用 MoliAi 能力：命令速查、成本安全规则（run 前必须先 --dry-run 看 estimatedCost）、写操作预演前后对照（--dry-run --diff）、参数校验与 400 可选值处理、破坏性操作确认、批量任务汇总通知、长任务轮询与错误信封解析。
metadata:
  version: "0.10.0"
---

# MoliAi CLI Skill

## 开始前

- `moliai status` 确认 `authenticated` 与 `baseUrl`；`moliai whoami` 确认身份。
- **多环境（测试/生产）时用 `moliai env` 确认当前环境**：`data.current` 是本次实际会用的环境（已含 `--base-url` / `MOLIAI_BASE_URL` 覆盖），`data.default` 是默认环境；两者可能不同。环境不对时先问用户，不要自己切。
- 未登录先 `moliai login key`（KEY 从 stdin 读，等同账号全权限，不要写进日志或 shell 历史）。
- 所有命令输出 JSON 信封：成功 `{ ok: true, command, data, warnings, traceId }`，失败 `{ ok: false, error: { code, message, hint, details }, traceId, traceIdSource }`。失败信息在 stderr。
- 失败信封的 `traceId` 是**服务端** traceId（`traceIdSource: "server"`）；网络错误与纯本地错误为 `null` + `"local"`。stderr 另有一行可直接复制的 `错误 traceId: ...`。
- 汇报时带上 `traceId`（`null` 时说明是本地错误，不要编造）。

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

## 升级 CLI（`update`）

| 目的 | 命令 |
|---|---|
| 只查有没有新版本（不下载） | `moliai update --check` → `data.hasUpdate` |
| 看会做什么（不下载） | `moliai update --dry-run` → `data.actions` |
| 真更新（⚠️ 替换当前二进制） | `moliai update`（`setup --upgrade` 等价） |
| 同版本重装 | `moliai update --force` |
| 换镜像/私有 fork | `moliai update --repo <owner/repo>` 或 `moliai update config --repo <owner/repo>` 持久化 |
| 看当前生效仓库与来源 | `moliai update config --show`（`arg` / `env` / `config` / `default`） |

- **只有用户要求升级时才执行 `moliai update`**：它会替换正在使用的二进制，Windows 下 CLI 会直接退出（`replaced=false`，更新由 `.update.bat` 在后台完成）。汇报时要说明"CLI 将退出，更新在后台完成"，并提醒用户重新执行 `moliai --version` 确认。
- 仓库优先级：`--repo` > `MOLIAI_UPDATE_REPO` > 配置 `updateRepo` > 默认 `Mr-cjf/moliai-cli`。`github.com` 下载域名不通时用 `--repo` 指向镜像，**不要**改代码或跳过校验。
- `MOLIAI_UNSUPPORTED`（"当前不是单文件二进制安装"）= npm/源码安装，改用 `npm i -g @moliai/cli@latest` 或安装脚本，不要试图继续自动更新。
- `MOLIAI_UNSUPPORTED`（"当前平台不支持自更新"）= 该平台无发布产物，改用安装脚本按版本重装。
- `MOLIAI_NETWORK_ERROR`（404 / 下载失败 / SHA256 不匹配）= 如实上报，不自动换源、不跳过校验；SHA256 不匹配时已删除临时文件。

## 命令速查

| 目的 | 命令 |
|---|---|
| 当前环境 / 已登录环境 | `moliai env` |
| 身份/连通性 | `moliai whoami`（`data.balance` 是真实余额，`quota` 只是本地占位） |
| 项目 → 画布 | `moliai project list` → `moliai canvas list -w <projectId>`；没有项目时 `moliai project create "<名称>"`（**CLI 只支持 `canvas`/无限画布模式**，顺带建一张同名画布；传统模式 `novel-promotion` 项目没有画布、CLI 无法操作，会直接报错，请到网页端创建；不自动写目录绑定，按输出 `next` 继续） |
| 绑定画布到当前目录 | `moliai canvas use <canvasId>` |
| 看画布与节点 | `moliai canvas show` / `moliai node list --limit 200` |
| 画布体检（只读，零扣费） | `moliai diagnose` → 先看 `data.source`（`server` = 后端 Doctor 报告，`local` = 后端无该路由时的本地降级）；再按 `empty` / `failed` / `rerunnable` 查看问题，`--out report.json` 落盘 |
| 按条件筛节点 | `moliai node list --status completed --has-result` / `--group "<组名>"` / `--sort y --limit 20` |
| 查模型契约 | `moliai model list` / `moliai model search <kw>` / `moliai model <modelKey>` |
| 建节点 | `moliai node create "<名>" -t image --x 0 --y 0`（`-t super_resolution` 必须加 `--super-resolution-type image\|video`） |
| 连线 | `moliai connection create <源> <目标>` / `moliai connection list` |
| 编组 | `moliai group create <节点...> --name "名"` / `moliai group list` / `moliai group merge <g1> <g2> --yes` |
| 声明式搭建（默认零扣费） | `moliai apply -f plan.json --dry-run --diff` → 确认后 `moliai apply -f plan.json`；加 `--run` 建完即生成（⚠️ 扣费），加 `--prune --yes` 清理组内计划外节点（⚠️ 删除） |
| 分镜组（读/建/改/清/成员） | `moliai storyboard list` / `show "<组名>"` / `create --from-nodes <节点...> --dry-run` / `config "<组名>" --rows 2 --columns 3 --dry-run` / `add-node "<组名>" "<节点>" --slot 1` / `move "<组名>" "<节点>" --from 0 --to 2` / `duplicate "<组名>" --offset-x 200 --offset-y 200 --yes` / `stitch-inputs "<组名>"` / `dissolve "<组名>" --yes` |
| 分镜拼接（上传+登记，零扣费，需本机 ffmpeg） | `moliai storyboard stitch "<组名>" -o ./分镜.png --keep-inputs ./原图`（依赖后端 `cells[]` 新字段；旧构建会 `MOLIAI_UNSUPPORTED`） |
| 整组批量执行 | `moliai group run "<组名>"`（预览）→ `moliai group run "<组名>" --execute`（真跑） |
| 派生场景清单 | `moliai derive list` |
| 深度动作捕捉（建节点，零扣费） | `moliai derive depth-capture <video节点> --resolution 480p --dry-run` |
| 视频续写（建占位节点，零扣费） | `moliai derive video-continuation <video节点> --model <k> --from 0 --to 4 --dry-run` |
| 视频续写生成（本地裁切+上传，扣费，需本机 ffmpeg） | `moliai derive video-continuation <video节点> --model <k> --from 0 --to 4 --duration 5 --resolution 720p --run --max-cost <n>`（`--duration` 是输出秒数=计费秒数，与选段长度无关） |
| 预设图派生（零扣费建节点+连线） | `moliai derive panorama <image节点> --model tencent::gpt-image-2` / `moliai derive three-view <image节点>` / `moliai derive nine-grid <image节点>` / `moliai derive portrait-texture <image节点>` |
| 超分（零扣费建节点+连线） | 图片：`moliai derive super-resolution <image节点> --size 1080p --dry-run --run`；视频：`moliai derive super-resolution <video节点> --resolution 1080P --dry-run --run`（视频按秒计费，只报价不跑） |
| 涂鸦重绘（零扣费建节点+连线） | `moliai derive image-edit <image节点> --doodle ./doodle.png --model <k> --dry-run --run`（`--doodle` 是「源图+涂鸦」完整整图，不是 mask） |
| 视频编辑（默认只预览报价） | `moliai derive video-edit <video节点> --model <k> --resolution 720p`（720p 24 魔力值/秒；确认价格后才加 `--run`） |
| 音视频分离（零扣费，需本机 ffmpeg） | `moliai derive audio-separation <video节点> --dry-run` → 确认后去掉 `--dry-run`（产出无声视频 + 分离音频两个节点） |
| 音频截取/变速（零扣费，需本机 ffmpeg） | `moliai derive audio-process <audio节点> --trim-start 0.5 --trim-end 3.7` / `--speed 1.5`（变速保调；输出 PCM wav） |
| 网格切图（零扣费，需本机 ffmpeg） | `moliai derive from-grid <image节点> --rows 2 --columns 2`（切成 N 张 → 建 N 个 image 节点 + N 条 manual 连线；源图格子有间隔时加 `--gap <px>`） |
| 上传素材 | `moliai upload <file> <canvasId>` → `storageKey` / `mediaId` |
| 预演生成（零成本） | `moliai run <node> --dry-run --model <k> --prompt "<p>" --set k=v` |
| 查参数来源（零成本） | 加 `--explain`：`moliai run <node> --model <k> --explain`（自动走 dry-run，输出每个参数为什么是这个值） |
| 真实提交（扣费） | `moliai run <node> --model <k> --prompt "<p>" --set k=v --wait 60`（可加 `--max-cost <n>` 设上限） |
| 长任务接续 | `moliai wait <jobId> --max 60` / `moliai jobs --active` |
| 作业标签（并行 Agent 区分） | `moliai run <node> ... --label agent-a` → `moliai jobs --label agent-a`（也可用 `MOLIAI_AGENT_LABEL`） |
| 完成通知 | `moliai run <node> ... --notify desktop`（或 `--notify 'cmd:<本地命令>'`；`run` / `wait` 单节点通知，批量命令整批汇总一条） |
| 查任务/下载 | `moliai task get <taskId>` / `moliai download --task <taskId> -o ./out` |
| 实时观察任务 | `moliai task watch <taskId> --output text`（状态/进度变化各打印一行，终态退出；失败退出码 6） |
| 取消任务（不退费） | `moliai task cancel <taskId> --yes`（只有 queued/processing 会被取消） |

## 成本安全规则

1. **`run` 前必须先 `--dry-run`**，读 `data.estimatedCost`。这是唯一零成本路径（只调 prepare + billing/estimate，不建任务、不预扣费）。
2. `estimatedCost` 为 `null` 时**不代表免费**，只代表算不出来；同时看 `warnings` 里的 `ESTIMATE_UNAVAILABLE` / `ESTIMATE_UNSUPPORTED`。若拿不到成本，提交前必须告知用户。
3. **视频成本 ≈ 单价 × 时长**，`480p` 与 `720p` 单价通常差一倍。改 `duration` 或 `resolution` 后必须重跑 `--dry-run`。
   视频生成（`taskType=video`）必须显式给出 `resolution`：模型参数契约声明了 `default` 时 CLI 会补上并在 `warnings` 里说明；
   契约没有默认值时 CLI 直接报错并列出可选档位（`moliai run <节点> --set resolution=720p`）——CLI 不从候选档位里替你挑一个，后端也不再猜。
4. **用户未明确要求时不真实提交**。默认只执行 `--dry-run`，把模型、参数、成本呈现给用户，等确认后再提交。
5. 重复提交用同一 `--client-request-id` 走后端幂等（`deduped=true`），不会重复扣费。
6. **成本上限**：`--max-cost <n>`（或环境变量 `MOLIAI_MAX_COST`，参数优先）在**提交前**校验预估消耗；
   超限或**无法预估**都会以 `MOLIAI_BUDGET_EXCEEDED`（退出码 5）拒绝且不提交。`--max-cost 0` 是合法值。
   它是预估口径，**不保证实扣不超**；用户给了预算时优先带上它。

## 查参数来源（`--explain`）

用户/自己不确定「这个值为什么是这样」时，用 `--explain`（**自动走 dry-run，零写入零扣费**）：

```bash
moliai run <node> --model qwen-image::qwen-image-2.1 \
  --set aspectRatio=9:16 --set resolution=1K --set generationMode=normal --explain
moliai run --where 'type=image' --max-nodes 1 --explain   # 批量：每个 nodes[] 都带 explain
```

输出在 dry-run 结构上多 `data.explain = { request, parameterSources, steps, warnings }`：

| 字段 | 用途 |
|---|---|
| `request` | 将发出的请求体（key 名含 key/token/secret/password/credential 的值已替换为 `***`） |
| `parameterSources` | 参数名 → 来源，七类：`explicit` / `binding` / `schema-default` / `upstream-inferred` / `node-config` / `cli-default` / `unknown` |
| `steps` | 组装流程各步（resolve-canvas / resolve-node / resolve-prompt / resolve-parameters / build-request / validate-params）与来源 |
| `warnings` | explain 自身的问题（最重要：schema 不可得、契约必填参数缺失） |

规则：

1. `--explain` 就是 dry-run 的超集，**它不会提交**；批量模式下给 `--execute` 也会被忽略（`warnings` 说明）。
2. `explicit` 优先：即使显式值和契约默认值相同，也标 `explicit`，不会被说成「默认值」。
3. **schema 只覆盖已配置参数契约的 modelKey**（`moliai model list` 里 `schemaAvailable=true` 的那几条）。
   其它模型 `parameterSources` 会标 `unknown` + warning「该模型未配置参数契约」，这是真实情况，不是 CLI 漏报。
4. 契约声明的**必填参数**如果既没 `--set` 也没在节点上，`warnings` 会明确列出（并附契约默认值），
   但 **CLI 不会替你填**——后端不会自动补默认值，直接提交会 400。
5. prepare 被 400 拒绝时，`error.details.explain` 里同样有 explain，可直接定位少传/传错了什么。

## 整组批量执行（`group run`）
⚠️ **和 `run` 的三处默认值完全相反**：

| | `run` | `group run` |
|---|---|---|
| 默认是否扣费 | **默认真跑**（`--dry-run` 预览） | **默认只预览**（`--execute` 才真跑） |
| 连线推导 | 永远不做 | **默认开启**（`--no-from-connections` 关闭） |
| 提交节流 | 无 | **间隔 ≥ 6 秒**（网关限 10 次/分钟） |

1. 先 `moliai group run "<组名>"` 预览：读 `totalEstimatedCost`、`nodes[].estimatedCost`、
   `nodes[].contextNodeIds`、`skipped`、`blockers`，把成本与顺序呈现给用户。
2. 用户确认后加 `--execute`。20 个节点至少 20×6 秒 ≈ 2 分钟提交，别在 120 秒就断言"卡死"。
3. `--order position`（默认，按坐标行优先）/ `member` / `topological`（DAG 拓扑，有环直接报错）；
   `STORYBOARD` 组强制 `member`，输出 `orderStrategyApplied` 会写明。
4. `--concurrency > 1` 必须同时 `--no-from-connections`（并发时上游产物未就绪），否则 `MOLIAI_ARG_INVALID`。
5. `--rerun-failed` 只重跑失败成员：远端 `status=failed`，**或本地有该节点的失败作业记录**
   （prepare 阶段被拒时远端仍是 `idle`，只有本地记录能识别）；远端已完成且有产物一律跳过。
   `status=generating` 一律跳过，避免重复提交。`skipped[].reason` 区分
   `already-completed` / `already-generating` / `not-failed`。
   本地没有该画布的作业记录时（换机器），CLI 会在 `warnings` 里提示无法识别 prepare 失败的节点，
   此时需去掉 `--rerun-failed` 全量执行或手动指定。
   `--max-attempts <n>` 可限制同一节点的重跑次数（已重跑次数 = 本地 run 作业记录数 - 1，超限进
   `skipped` 且 `reason=max-attempts-reached`）；**不传时不限制**（保持既有行为）。
6. `--client-request-id` 是**前缀**：每节点用 `<prefix>-<序号>`。整组共用一个会被后端幂等去重，
   第 2 个节点起全部丢弃。
7. 有任何一个节点构建失败（缺模型/缺提示词/参数非法）→ `--execute` 拒绝整组，`details.blockers`
   列出全部问题节点；修好再跑，不要绕过。
8. 视频节点默认 `--wait 90` 等不到：`succeeded[].status` 为 `queued`/`processing` 时用
   `moliai wait <jobId>` 分轮跟进，不要提高 `--wait` 硬等。
9. `--max-cost <n>` 在**任何节点提交之前**判定整组合计：超限 → 整组零提交（`MOLIAI_BUDGET_EXCEEDED`，
   退出码 5，`details.nodes` 给每节点明细）；有节点无法预估时 `totalEstimatedCost` 为 `null`（不当 0），
   `warnings` 注明「上限校验不完整」；全部无法预估 → 直接拒绝整组。预览输出带 `maxCost` / `withinBudget`。

## 按选择器批量生成（`run --where`）

⚠️ **默认行为与单节点 `run` 刻意相反**：

| | `run <node>` | `run --where '<expr>'` |
|---|---|---|
| 默认是否扣费 | **默认真跑**（`--dry-run` 预览） | **默认只预览（零扣费）**（`--execute` 才真跑） |
| 连线推导 | 永远不做 | **默认开启**（`--no-from-connections` 关闭） |
| 提交节流 | 无 | **间隔 ≥ 6 秒** |

1. 先预览：`moliai run --where 'type=image&hasResult=false'`，读 `matched` / `matchedBeforeLimit` /
   `nodes[].estimatedCost` / `nodes[].skipReason` / `totalEstimatedCost` / `estimatedSubmitMinutes` / `blockers`。
2. 用户确认后加 `--execute`。命中数超过 `--max-nodes`（默认 20）需 `--yes`，否则退出码 10。
3. 位置参数是**画布 id**（`moliai run --where '...' <canvasId>`）；同时给节点会报 `MOLIAI_ARG_INVALID`。
   批量模式不支持 `--ref-*` / `--client-request-id`（会显式报错，不会静默忽略）。
4. 命中 0 个 → `MOLIAI_ARG_INVALID`「没有匹配的节点」（不静默成功）。
   `status=generating` 与不支持生成的节点类型进 `skipped`；缺模型/提示词/参数非法进 `blockers`，
   `--execute` 时整批一个都不提交。
5. `run --rerun-failed` 等价于 `--where 'status=failed'`（并额外包含本地有失败作业记录的节点），
   **默认预览**。`--max-attempts <n>` 默认 1：同一节点最多再重跑一次，超限进 `skipped`
   （`attemptsUsed` 按「本地 run 作业记录数 - 1」推断）。
6. 命中节点已有产物时**不会自动跳过**（显式选择优先），但 `warnings` 会提示会再次扣费。

## 派生（`derive`：深度动作捕捉 / 视频续写）

1. 先 `moliai derive list`：`scenes[].supported` 为 `false` 的场景没有独立命令，`note` 里给了替代方案
   （多数可用 `moliai run` 间接实现）。
2. **两个命令默认只建节点、不提交生成、不扣费**；只有加 `--run` 才提交生成（会扣费）。
   用户没明确要求时不要传 `--run`。
3. 幂等键是 `--operation-id <uuid>`（`--client-request-id` 是别名），后端字段名是 `operationId`，
   不是 `clientRequestId`。同键不同请求体 → 409，需换新键。`--dry-run` 输出里会打印本次 `operationId`。
4. 本地硬约束（CLI 先拦，退出码 2）：
   - `--resolution` 只接受**小写** `480p` / `720p`；
   - 深度捕捉源：`video` / `super_resolution(video)` / `depth_capture`，且 `mediaUrl` 非空；
   - 续写源必须是 `video`，有 `mediaUrl` 与 `duration`；**源全长与选段都要 4–30 秒**，
     选段 `0 <= start < end <= 源时长`；`--from/--to`（秒）与 `--from-ms/--to-ms` 二选一。
5. 续写产出是 `mediaUrl` 为空的占位 `video` 节点，必须再生成才有产物；
   生成请用 `--run` 或对新建节点单独 `moliai run`（后者同样扣费，先 `--dry-run`）。
6. 视频续写创建前 CLI 会先 `reference-media/prepare` 取 `sourceExpectations`（后端强制要求），
   这一步会登记素材元数据；`--dry-run` 不调它。
7. **续写 `--run` 走 `frontend_clip`**：CLI 下载源视频 → 本地 ffmpeg 裁切 `[--from,--to)` → 上传片段
   （`clipMediaId` = storageKey）→ 提交时补 `options.duration` / `options.resolution` /
   `videoContinuation.inputMode=frontend_clip / clipMediaId / clipDurationMs / extensionDurationSeconds`。
   因此：
   - **`--duration <秒>`（4–30 整数）`--run` 时必填**，它是「续写输出秒数」也是计费秒数（720p 16 魔力值/秒，
     4 秒=64、5 秒=80）；不要和选段长度 `--to - --from` 混淆；
   - `--resolution` 默认 `720p`，只接受 `480p` / `720p`（续写恒 reference 档，缺参会 400）；
   - 需要系统 ffmpeg（`--dry-run` 不做裁切，不需要）；
   - 裁切默认**重编码**（精确到帧）；`--fast` 用 `-c copy`（快、不重编码，但端点吸附包/关键帧边界，
     实测 4.000 秒 → 4.1 秒，偏差随源 GOP 增大）；`--keep-clip <path>` 可保留片段检查；
   - 临时文件用完自动删除。

## 节点写入（`node create` / `node update`）

1. `node create` 必填 `-t` + `--x` + `--y`；`node update` 用 `nodeId` 定位，至少给一个可更新字段。
2. **`-t super_resolution` 必须带 `--super-resolution-type image|video`**：后端不补默认值，落 null 的节点在网页端
   `resolveSuperResolutionType` 处直接抛错，`connection create` / `derive` 也判不出语义。缺这个参数 CLI 直接
   `MOLIAI_ARG_INVALID`（不是 warning）。
3. 非 `super_resolution` 节点传 `--super-resolution-type` → `MOLIAI_ARG_INVALID`（不静默忽略）；
   `node update` 会先按 nodeId 读节点类型再判。
4. `node create` / `node update` / `node list` / `canvas show` 输出都带 `superResolutionType`（非超分节点为 `null`）。
   排查「为什么这条连线/派生被拒」时先看它。
5. **写前预演**：`node update <nodeId> ... --dry-run` 零写入（不发 PATCH），输出
   `{ mode: "dry-run", nodeId, canvasId, diff: { before, after, changes } }`；再加 `--diff` 让
   `changes` 展开成「只含真正变化的字段」。`--diff` 不带 `--dry-run` → `MOLIAI_ARG_INVALID`（退出码 2）。

## 改生成参数（`node update` 的 `--model` / `-s, --set` / `--clear-params`）

1. 写模型：`moliai node update <nodeId> --model qwen-image::qwen-image-2.1`（写 `modelKey`，下一次生成用它）。
2. 写参数：`-s, --set <key=value>` 可重复，值**优先按 JSON 解析**——`--set count=3` 是数字 `3`，
   `--set flag=true` 是布尔，解析失败按字符串（`--set ratio=9:16` → `"9:16"`）。
3. 清空：`--clear-params`（提交 `{}`）；与 `--set` 互斥，两个一起给 → `MOLIAI_ARG_INVALID`。
4. **后端对普通节点是整体替换 `modelParams`**（只有 `video_continuation` / `voice` 在服务端逐键合并），
   所以 CLI 会先读节点当前值再本地合并后提交：`-s duration=5` 不会清掉已有 `ratio`。不要自己拼完整对象。
5. `node update` 输出带 `modelKey` / `modelParams`（后端回执的最终值），改完可直接核对。

## 批量改生成参数（`node update --where`）

1. `moliai node update --where 'type=image&group=第01集' -s ratio=9:16`：选择器语法与 `node delete --where` 完全相同。
   位置参数 `<nodeId>` 与 `--where` **互斥**。
2. 走 `PUT /api/canvases/{id}/nodes/batch`，逐节点先读后合并再一次性提交（all-or-nothing：任一节点不属于本画布则整批 400）。
3. 必须至少给 `--set` / `--model` / `--clear-params` 之一；命中 0 个 → `MOLIAI_ARG_INVALID`（不会静默成功）。
4. `--dry-run` 展示将改动的节点与目标参数（不提交）；命中数 > `--max-nodes`（缺省 20）且无 `--yes` →
   `MOLIAI_CONFIRM_REQUIRED`（退出码 10）；带 `--yes` 时**只处理前 N 个**（`truncated: true` + `warnings` 提示）。
5. `--max-nodes` / `--yes` 只在批量模式有效（单节点传会 `MOLIAI_ARG_INVALID`）；`--dry-run` / `--diff` 两种模式都支持。
6. 输出 `{ dryRun, canvasId, matched, updated, failed[], nodes[], canvasVersion, truncated }`；
   `updated` 是**回读校验后**确认生效的数量，`failed[]` 列出回读不一致的节点与原因（不拿 `updatedCount` 冒充成功）。
7. `--dry-run` 多一个 `diff[]`（逐节点 `{ nodeId, name, before, after, changes }`），加 `--diff` 才展开 `changes`。

## 节点查询（`node list` 过滤 / 排序）

1. **全部是客户端过滤**（一次 `GET /api/canvases/{id}` 拉全量），多个条件 AND；参数：
   `--type` / `--name-like` / `--status <idle|generating|completed|failed>` / `--group <groupId或组名>` /
   `--has-result` / `--no-has-result` / `--edit-mode <direct|ai>` / `--model <provider::modelId>` /
   `--sort <name|type|status|x|y>` / `--limit <n>`。
2. `--status` 只接受后端值域四个值，写错（如 `uploading`）本地就拒（退出码 2），不会静默命中 0 条。
3. `--group` 读同一份 `groups[].memberNodeIds`；组名不唯一会列出候选，组不存在报错——别猜，直接用 groupId。
4. `--has-result` 判据是 `mediaUrl` 非空（`super_resolution` / `depth_capture` 也可能有产物）。
5. `--model` 与 `--where model=` 同规则：`modelKey` 优先，为空回退 `generationModel`（即「下一次生成会用的模型」）。
6. 输出 `{ nodes, total, matched, filters }`：`total`=过滤前总数，`matched`=**截断前**命中数（`nodes` 已被 `--limit` 截断），
   `filters` 回显生效条件。汇报「有几个」时用 `matched`，不要数 `nodes.length`。
7. `--sort` 单字段升序，空值排最后，同值按 `nodeId` 稳定排序；`--limit` 在排序之后截断。
8. `node list` 的专用参数与 `--where` 是**互补**关系：`node list` 用于只读查询（另有 `--sort` / `--limit`），
   `--where` 用于写/执行命令（`node update` / `node delete` / `run` / `group run`）。先用 `node list` 预览命中范围，
   再把等价表达式交给写命令。
9. `node update <nodeId>` / `node delete <nodeId>` / `task get` / `task cancel` **只接受 UUID**；
   传节点名等非 UUID 会本地报 `MOLIAI_ARG_INVALID`「不是合法的 UUID：xxx」（不再报「画布中找不到节点」/404）。
   接受节点引用的命令（`run` / `extract` / `derive` / `node delete --ids`）不受此限制。

## 画布体检（`diagnose`，只读、零扣费）

1. `moliai diagnose [canvasId] [--out report.json]`：**没有 `--fix`、没有 `--yes`、不自动重跑、不写任何业务数据**。
   `canvasId` 省略时用 `MOLIAI_CANVAS` / 目录绑定。
2. **先看 `data.source`**：`server` = 后端 Doctor 报告（`POST /canvases/{id}/doctor/reports`）；
   `local` = 后端没有该路由时的本地降级扫描。降级会在 `warnings` 第一条明确说明（不静默）。
3. `source=server` 时三类都有：`empty`（无内容且无任务）、`failed`（`status=failed` + `taskId`，后端已映射
   `failReason`）、`rerunnable`（失败但参数齐全、无运行中任务）；`refErrors` / `orderRisks` 由后端在
   `notImplemented` 中声明未实现，恒为空数组。
4. `source=local` 时只有 `empty` / `failed`（`remediation` 为 `moliai run "<节点名>"`），
   `rerunnable` / `refErrors` / `orderRisks` 恒为空数组，`notImplemented` = `["rerunnable","refError","orderRisk"]`。
5. 什么情况**不降级**（直接报错）：`POST` 404 但 `serverCode` 是业务码（`DOCTOR_*` / `CANVAS_*`）、
   5xx、401/403、网络错误——那是真实故障/业务拒绝，降级会把问题掩盖成「扫不到问题」。
6. 环境自检用 `moliai doctor`（本机 + 连接环境），**不要混用**：`doctor` 不看画布内容，`diagnose` 不看环境。

## 批量选择器（`--where`）与批量删除

1. 表达式 `'字段 运算符 值'`，多条件用 `&` 连接（**全部 AND**）；运算符只有 `=`（精确等于）与
   `~`（子串包含，忽略大小写）。值按第一个运算符切分后整体取值，`ark::doubao-seedance-2.0`、中文、`-` 都不用转义。
2. 字段白名单 7 个：`type` / `status` / `name` / `group` / `model` / `hasResult` / `editMode`；
   `hasResult` 只接受 `=true` / `=false`，其余字段都支持 `=` 与 `~`。
3. **`group` 是靠 `groups[].memberNodeIds` 反查的**（节点对象上没有组名字段）；不属于任何编组的节点组名为空串，
   不会被 `group=<非空>` 命中。后端返回 `group.name=null` 的默认组无法用 `group=` 选中。
4. `model` 取 `modelKey`，为空时回退 `generationModel`——所以「按模型筛」筛的是**下一次生成会用的模型**。
5. `node delete` 三个入口**互斥**：`<nodeId>` / `--where` / `--ids`；批量模式不要给位置参数
   （画布用 `MOLIAI_CANVAS` 或 `moliai canvas use` 绑定），否则会和 nodeId 冲突。
6. 命中数 > `--max-nodes`（缺省 20）且没有 `--yes` → `MOLIAI_CONFIRM_REQUIRED`（退出码 10，
   `details.candidateNodes` 列出前 N 个）；表达式语法/未知字段/非法 `hasResult` → `MOLIAI_SELECTOR_INVALID`（退出码 2）。
7. **先 `--dry-run` 看命中，再带 `--yes` 真删**。`--where` 命中 0 个会报 `MOLIAI_ARG_INVALID`（破坏性操作不静默成功）；
   `--ids` 里不存在的 id 只进 `warnings` 并跳过。
8. 输出 `{ dryRun, matched, deleted, deletionOperationId, nodes[], restoreHint }`：**后端一次请求只返回一个
   `deletionOperationId`（无逐节点 opId）**，`nodes[]` 回显 `deletedNodeIds`，恢复按整批执行。

## 预设图派生（`derive panorama` / `three-view` / `nine-grid` / `portrait-texture`）

1. 四个场景共用一套实现：**默认只建节点 + 建 manual 连线（零扣费）**，加 `--run` 才提交生成（扣费）。
   用户没明确要求时不要传 `--run`。
2. 源节点必须是 `image`，或 `super_resolution` 且 `superResolutionType=image`（用 `node list` 的
   `superResolutionType` 确认，`null` 的超分节点会被拒）；`mediaUrl` 非空；
   `status` 不能是 `uploading`/`generating`。源节点的 `mediaUrl` 会作为 `referenceImages` 提交。
3. **`panorama` 的 taskType 是 `panorama_image`**（其余三个是 `image`）；模型只允许
   `tencent::gpt-image-2` / `openai::gpt-image-2` / `framefly::gpt-image-2`，其它模型本地即拒。
4. **`--run` 必须给 `--model`**（新节点没有可继承的 `modelKey`）；给了 `--model` 也会写进节点 `modelKey`。
5. **没有幂等键**：建节点与建连线后端都不支持幂等，重复执行会产生重复节点/重复连线，需要手工清理
   （`moliai node delete <id> --yes` / `moliai connection delete --ids <id> --yes`）。
   `--client-request-id` / `--operation-id` 只作用于最后的 `/generate` 提交。
6. 部分模型必须显式尺寸：`qwen-image-2.1` 不给 `aspectRatio` 会 `UNSUPPORTED_IMAGE_SIZE`，
   用 `--set aspectRatio=1:1`（它只支持 `1:1` / `16:9` / `9:16` / `4:3` / `3:4` / `16:10`，且只有 1K）。
   `tencent::gpt-image-2` 的 `2:1` 只有 4K 有映射（panorama 就是这条）。
7. 三个 image 场景的预设（`layoutPreset`/`anglePreset`/`promptPreset`）会随请求提交，是后端认可的
   内容来源，因此**可以不给 `--prompt`**。
8. 报价：`--dry-run --run` 的 `estimatedCost` 与真实扣费同口径（panorama 计入后端注入的 `2:1`/`4K`；
   实测 `tencent::gpt-image-2` + `4K` 全景图约 **11 魔力值**，`qwen-image-2.1` 1K 约 **0.5**）。

## 超分（`derive super-resolution`：图片 / 视频）

1. **模式由源节点类型决定**：`image` → `super-resolution-image`；`video` → `super-resolution-video`；
   `super_resolution` 节点按 `superResolutionType` 判定。其它类型（text/audio/voice…）→ `MOLIAI_ARG_INVALID`。
2. 图片目标（二选一，必须给一组）：`--size 720p|1080p|2k|4k`（档位换算：目标短边取档位短边，
   长边按源宽高比换算，超 4096 等比缩到长边 4096），或 `--width`+`--height`（整数 1–4096）。
   `--size` 与 `--width/--height` 同时给 → `MOLIAI_ARG_INVALID`。
3. 视频目标：`--resolution 720P|1080P|2K|4K`，**大小写敏感**（写 `1080p` 本地即拒，退出码 2）；
   `--duration <秒>` 可选，只写节点 `duration`，**不改变计费时长**（后端自己解析源视频）。
4. **不降级校验必须由 CLI 做**：后端只校验 1–4096，**不校验目标大于源**，降级请求会正常受理并扣费。
   CLI 与网页端同口径：`min(target) > min(source)`，否则 `MOLIAI_ARG_INVALID`「目标分辨率必须高于源分辨率」。
   源节点缺 `mediaWidth`/`mediaHeight`（或 `mediaUrl` 为空、正在 uploading/generating）→ 直接拒绝。
5. **默认只建节点 + manual 连线（零扣费）**，`--run` 才提交生成。用户没明确要求时不要传 `--run`。
   视频超分按秒计费（720P 0.25 / 1080P 0.5 / 2K 1.0 / 4K 2.0 / 8K 8.0 每秒），**先 `--dry-run --run` 看价**。
6. **结果回写到 `targetNodeId`（不是新节点）**：`mediaUrl`/`mediaId`/`mediaWidth`/`mediaHeight`/
   `generationModel`/`superResolutionType`/`origin=ai_generated`。`--run` 完成后 CLI 从画布回读并输出
   `run.mediaWidth`/`run.mediaHeight`；`mediaUrl` 仍为空会有 warning（回写延迟），用 `node list --has-result` 核对。
7. **没有幂等键**（建节点/连线后端都不支持）：重复执行会产生重复节点/连线，需 `moliai node delete <id> --yes`。
   `--client-request-id`/`--operation-id` 只作用于 `/generate` 提交。
8. `--max-cost <n>` 在提交前拦（无法预估或超限 → `MOLIAI_BUDGET_EXCEEDED`，退出码 5，零提交）。
9. `moliai run <超分节点>` 仍然报 `MOLIAI_UNSUPPORTED`（run 的通用路径带不上 `sourceUrl`/目标尺寸）；
   要重跑超分就再执行一次 `derive super-resolution`（会产生新节点）。

## 涂鸦重绘（`derive image-edit`）

1. **`--doodle` 必须是「源图 + 涂鸦」的完整整图，不是 mask**。后端把它追加到参考图末尾，并在 prompt 前
   自动加固定前缀「对涂鸦区域重绘，涂鸦区域重绘后，去掉涂鸦。」；CLI 不重复加这段前缀。
2. `--doodle` 本地文件 → CLI 先按文件头解析宽高（PNG/JPEG/WebP）再走 multipart 上传
   `POST /canvases/{id}/upload-doodle`（后端对 image **强制要求 `width`/`height`**）；上限 200MB。
   `http(s)://` 开头的 `--doodle` 直接当完整 URL 用，不上传。
3. 源节点必须是 `image` 且有 `mediaUrl`；本地涂鸦图宽高与源 `mediaWidth`/`mediaHeight` 不一致时只给
   `DOODLE_SIZE_MISMATCH` 警告（**不阻断**，避免误伤「刻意改尺寸」的场景）。
4. **默认只建节点（`nodeType=image`）+ manual 连线（零扣费）**；`--run` 才提交，且 `--run` 必须给 `--model`。
   价格为模型定价（`wetoken::doubao-seedream-5-0-260128` = 2/张，`qwen-image::qwen-image-2.1` = 0.5/张）。
5. **结果回写到 CLI 预创建的 `targetNodeId`**（Worker 不另建节点）；`--dry-run` 时本地涂鸦图不会上传。
6. 建节点/连线/上传都没有幂等键：重复执行会产生重复节点/连线，需要手工清理。

## 视频编辑（`derive video-edit`）

1. **默认只预览 + 报价（零写入、零扣费）**：不加 `--run` 只打印 `estimatedCost` 与将要提交的请求摘要。
   **必须用户明确要求才加 `--run`**——720p 24 / 480p 12 魔力值每秒，10 秒 = 240 魔力值。
2. **永不传 `targetNodeId`**：传了 Worker 会走回写分支，结果节点没有 `derivationType=video_edit`。
   正确形态是 Worker 新建节点（`derivedFromNodeId=源节点`、`derivationType=video_edit`、
   `derivationOperationId=taskId`），CLI 提交后按 `derivationOperationId === taskId` 反查并输出 `resultNodeId`；
   找不到时如实告警返回 `null`（不伪造）。
3. `--ref <节点>`（可重复）+ `--ref-label <文本>`（可选，与 `--ref` 一一对应）→ `videoEdit.references[]`：
   `referenceId` 自动 `ref-1..N`，`mediaType` 按节点类型推导（image/video/audio），`url` 用节点 `mediaUrl`。
4. **`sourceExpectations` 必须与实际视频消费精确相等**：CLI 为「源视频 + 视频类 `--ref`」逐条
   `reference-media/prepare`（图片/音频 ref 不计入）；条数不对后端 409 `CANVAS_REFERENCE_SPEC_CONFLICT`。
5. `frameAnnotations` **恒为 `[]`**（CLI 不做帧标注，后端接受空数组）；`--duration` 不生效
   （后端 `remove("duration")`，输出与计费都跟随源视频），CLI 只回 `DURATION_IGNORED` 警告。
6. `--resolution` 只接受小写 `480p`/`720p`，`--run` 时必填；源视频时长必须 4–30.2 秒。
7. 报价口径：`generationMode=reference` + `ceil(源时长ms/1000)` 秒（与后端预扣同口径）；
   想只验证请求体合法而不花钱，用 `--run --max-cost 0.1`（走到 prepare 后被预算拦下，零提交零扣费）。

## 网格切图（`derive from-grid`）

1. **不扣费**：本地 ffmpeg 切图 → 逐张上传 → 建 N 个 `image` 节点 + N 条 `manual` 连线，没有 `--run`。
2. 源节点**必须是 `image`** 且 `mediaUrl` 非空；`--rows` / `--columns` 必填且 ≥1。
3. `--x/--y` 给**首个**结果节点坐标（都不给则按源节点右侧自动避让），其余按网格顺延（节点间距 40）。
4. `--gap <px>` 表示**源图格子之间本身有空隙**（不是结果节点间距）：CLI 先扣掉 `(count-1) * gap`
   再等分，间隔不进入产物。源图无间隔就别传（默认 0）。
5. 切图余数归最后一格（`gap=0` 时按边界取整），不丢像素也不重叠。
6. 节点/连线**没有幂等键**：重复执行会产生重复节点。中途失败时错误 `details.createdNodes` 列出已建节点
   （不自动回滚），核对后用 `moliai node delete --ids ... --yes` 清理。
7. 与分镜组的关系：切出来的图若要做分镜，再执行 `moliai storyboard create --from-nodes <切出的节点...>`；
   **没有** `storyboard create --from-grid`。

## 音视频分离 / 音频处理（`derive audio-separation` / `derive audio-process`）

1. **两个命令都不扣费**：本地 ffmpeg 处理完上传，只调事务端点创建节点 + 派生连线，
   后端没有计费分支，所以没有 `--run`、也不会提交生成任务。
2. **依赖本机 ffmpeg（CLI 不内置）**：解析顺序 `--ffmpeg` > `MOLIAI_FFMPEG` > PATH，都没有则显式报
   `MOLIAI_UNSUPPORTED` 并给出分平台安装命令。`moliai doctor` 的 `ffmpeg` 项能看到用的是哪一个（系统/指定）与版本；
   缺失时就别执行这两条命令（以及 `derive video-continuation --run`，它也要裁切视频），先让用户装系统 ffmpeg
   （macOS `brew install ffmpeg` / Ubuntu `sudo apt install ffmpeg` /
   Windows `winget install FFmpeg`，或从 https://ffmpeg.org/download.html 下载）。
3. `audio-separation <video节点>`：源必须是 `video` 或超分视频（`super_resolution` 且
   `superResolutionType=video`）且有 `mediaUrl`。一次产出**两个节点**（无声视频 + 分离音频）+ 两条派生连线。
4. `audio-process <audio节点>`：源必须是 `nodeType=audio`（`voice` 节点不是 `audio`，会被后端 400）。
   `--trim-start`/`--trim-end`（区间 ≥0.5 秒）与 `--speed`（0.1–4.0）**互斥且必须给一个**。
5. **变速是保调的**（`atempo` WSOLA）：只改时长、不改音高；倍率超出单级 0.5–2.0 时 CLI 自动串联多级。
   不要告诉用户「变速会变调」——实测 2 倍速后基频几乎不变。
6. **音频输出只能是 wav（PCM）**：后端上传白名单硬编码 `{wav, mp3}`，m4a/aac 会被 400 拒绝，
   而 mp3 编码器按许可证红线不使用。代价是体积大（约 1.4MB / 10 秒），大文件上传会更慢。
7. 分离音频的 `mediaId` 是后端硬校验（必须已登记为 `audio/*`），CLI 总是先上传再提交，不要手拼请求。
8. 幂等键 `--operation-id`（别名 `--client-request-id`），同键不同请求体 → 409；`--dry-run` 零写入，
   只输出下载/处理/上传/提交四步与坐标；`--keep-work-files` 保留本地中间产物便于排查。
9. 失败时本地工作目录会保留（成功才按 `--keep-work-files` 决定），`workDir` 字段回显路径。

### 遇到 ffmpeg 缺失（`MOLIAI_UNSUPPORTED` + 退出码 5）

音频派生、分镜拼接与网格切图都需要系统 ffmpeg，CLI 不内置。

1. 告诉用户具体缺什么（不要只说"失败了"）
2. 给对应平台的安装命令（错误 `hint` 里已有）：macOS `brew install ffmpeg` / Ubuntu `sudo apt update && sudo apt install -y ffmpeg` / Windows `winget install --id Gyan.FFmpeg`
3. 装完让用户跑 `moliai doctor` 验证（`ffmpeg` 项应为 `pass`）
4. **不要**跳过音频功能继续、**不要**自己下载二进制、**不要**自己编译

## 参数校验

- 有契约的模型：服务端严格校验。CLI 默认带 `X-Moliai-Strict-Validation: true`，缺必填参数或带未声明参数直接 400。
- 无契约的模型：CLI 用 `/api/user/models` 的 `capabilities` 本地校验；显式 `--set` 违规报 `MOLIAI_ARG_INVALID`（退出码 2），继承来的非法参数会被剔除并在 `warnings` 说明。
- **写错参数会报错并列出可选值**，例如 `参数 resolution 取值非法："4k"，可选值 "480p"/"720p"/"1080p"`。不要盲试组合；先 `moliai model <modelKey>` 看契约，或改 `--dry-run` 看 `parameters` 与 `paramValidation`。
- `count` 范围 1..4；`--wait` 上限 540 秒；`--deadline` 上限 86400 秒。

## 分镜组（`storyboard`：读 + 建组 + 改配置 + 成员操作 + 拼接输入 + 三种清理）

1. 读：`moliai storyboard list`（只列 `groupType=STORYBOARD`）/ `moliai storyboard show "<组名或 groupId>"`。
   输出里 `storyboard.rows` / `columns` 是网格，`slots[].index` 是槽位号（`members[].slotIndex` 才是成员序号），
   `slots[].nodeId=null` 表示空尾槽，`placeholder=true` 表示空图片占位（不参与拼接）。
2. 建：`--from-nodes <节点...>` 框选新建；`--from-group <普通组>` 原位转换（保留 groupId/名称/颜色/左上角）。
   两者互斥且必须给一个；`--add-nodes` 只能配 `--from-group`。
3. **先 `--dry-run`**：零改动预览成员顺序（`posY→posX→nodeId`）与自动布局推算（`columns=ceil(sqrt(n))`，
   `rows=ceil(n/columns)`，单成员固定 1×2）。确认后再去掉 `--dry-run`。
4. 建组端点**不接受名称/颜色**：`--name` / `--color` 会在建组成功后追加一次 PATCH，
   输出会带 `GROUP_LABEL_APPLIED_IN_SECOND_WRITE` 警告（属预期，不是错误）。
5. `expectedCanvasVersion` 必填，省略时 CLI 自动取当前画布版本；并发写入报 409 `MOLIAI_CONFLICT` 时重新读一次再试。
6. 成员准入：只接受 `image` / `nine_grid` / `three_view` / `portrait_texture` / `panorama_image`，
   以及 `super_resolution` 且 `superResolutionType=image`；已属任何编组的节点都不能再入组；上限 25。
7. 清理三选一（都**必须 `--yes`**，缺了是 `MOLIAI_CONFIRM_REQUIRED` 退出码 10，`details` 会列出成员与后果）：
   - `moliai storyboard dissolve "<组名>" --yes`：**解组** —— 组消失，**成员节点全部保留**为组外普通节点；
   - `moliai storyboard clear "<组名>" --yes`：**清空成员** —— 成员节点与组外关联连线**软删**，组与配置保留（空 STORYBOARD 组）；
   - `moliai storyboard to-normal "<组名>" --yes`：**转普通组** —— 槽位信息作废（`slotIndex` 置 NULL、9 个分镜配置清空），
     **成员节点仍在该组内**，之后可正常用 `group` 系列命令（含 `group delete`）。
8. **改配置用 `moliai storyboard config "<组名>"`**（`PATCH .../storyboard`）：
   - 网格 `--rows/--columns`（**必须成对**，`1..5`，`rows*columns >= 2`；1×1 直接拒绝）；
   - 单元格比例 `--ratio 16:9` 或 `--ratio-width 16 --ratio-height 9`（**二选一**）；
   - `--show-numbers` / `--no-show-numbers` / `--export 2K|4K` / `--bg "#RRGGBB"`；
   - `--move-to 100,200` = 组框**新原点**，组内全部成员同位移（不能单独缩放组框）。
   - **缩容会脱组**：容量 < 成员数时，后端按旧 `slotIndex` 保留前 N 个，其余变组外普通节点（**节点不删、图不丢**）。
     改网格前**先 `--dry-run`**，它会打印 `当前 N 个成员 → 新容量 M → 后 (N-M) 个会脱为普通节点：<名称…>`；
     真跑后在 `detachedNodeIds` 与 `warnings` 里同样能看到。把这条副作用如实告诉用户再执行。
   - **前后对照**：`--dry-run --diff` 的 `diff` 只含本次显式要改的配置项
     （`rows` / `columns` / `cellAspectRatio*` / `showNumbers` / `exportResolution` / `backgroundColor` / `frameX,frameY`），
     `changes` 只列真正变化的字段。`--diff` 不带 `--dry-run` → `MOLIAI_ARG_INVALID`。
9. **拼接前的基线用 `moliai storyboard stitch-inputs "<组名>"`**（只读、不推进画布版本）：
   `inputs` **只含有图成员**（零有图成员时是空列表，不是错误）；`config` 是冻结配置
   （拼接时原样回传 `inputSnapshot.config`，`inputCanvasVersion` 取输出的 `canvasVersion`）；
   `slots` 是全容量槽位（`nodeId=null` 空尾槽、`placeholder=true` 空图片占位不参与拼接）。
   `--out snapshot.json` 可把原始响应落盘。
   **真拼接是 `moliai storyboard stitch "<组名>" -o ./分镜.png`**：下载每格 → 本地 ffmpeg 合成
   （`contain` 缩放不拉伸 + 背景色 pad + 按 `cells[]` 的 `x/y` overlay）→ 上传 PNG → 登记结果节点。
   **只上传与登记、零扣费**。它依赖后端新增的 `cells[]` / `outputWidth` / `outputHeight`：
   旧构建返回空 → `MOLIAI_UNSUPPORTED`（不下载、不上传、不写画布）。空组 → 「分镜组没有可拼接的图」。
   后端输出尺寸是纯网格比例，与网页端观感可能有细微 gap/padding 偏差。
10. **成员操作（入组 / 补图 / 换位 / 拖出 / 跨组迁移 / 整组复制）**：
    - `add-node "<组名>" "<节点...>" --slot <n>`：**已有**图片节点入组（不复制节点、不写来源行、不建来源线）。
      满组自动扩容（优先加行，5×5 才拒）。多节点时逐个提交：每个节点**独立幂等键**、每次**重读画布版本**，
      所以多节点不能带 `--client-request-id` / `--expected-version`；节点依次落 `--slot, --slot+1, …`。
    - `fill "<组名>" --slot <n> -f <本地图片>`：上传后补到槽位（服务端**新建**成员节点，满组**不扩容**）。
      **先 `--dry-run`**：不上传、不调后端，只报插入位置 `finalIndex = min(slot, 成员数)` 与上传目标。
    - `move "<组名>" "<节点>" --from <n> --to <m>`：组内换位，**插入不是交换**：
      `[A,B,C,D]` 把 A 从 0 移到 2 → `[B,C,A,D]`（不是 `[C,B,A,D]`）。`--from` 必须等于真实槽位；
      传错本地直接报「该节点实际在 slot N（0 基）」。no-op 时输出 `changed=false`，画布版本不推进。
    - `detach "<组名>" "<节点>" --from <n> --x <n> --y <n>`：拖出组，**节点与连线保留**、后续槽位顺延压实。
    - `transfer "<来源组>" "<节点>" --from <n> --to-group "<目标组>" --slot <m>`：跨组迁移，两侧各自重排；
      目标组满自动扩容一格（5×5 才 409 且来源组零变更）。输出 `targetGroupId` 是**目标组**
      （后端 `result.groupId` 即目标组），并给出 `sourceMemberNodeIds` / `targetMemberNodeIds`。
    - `duplicate "<组名>" --offset-x <n> --offset-y <n> [--connections none|all] --yes`：整组复制。
      会新建 1 个组 + N 个节点，**必须 `--yes`**（缺失退出码 10）；`--connections` 默认 `none`。
      **`nodeIdMap` 方向是「新节点 ID → 源节点 ID」**（与普通组复制相反），CLI 会自校验方向。
    - 槽位语义提醒：`--slot` 对 `add-node`/`fill`/`transfer` 都是「插入位置」，**允许超过当前成员数但小于容量**
      （插到末尾）；`--from` 一律是 0 基真实槽位。
11. 分镜组不能用 `group delete`（本地 `MOLIAI_ARG_INVALID` 并指路 `storyboard dissolve`）；反过来
    `storyboard dissolve` 也不能删普通编组（指路 `group delete`）——不要互相替代。
12. 分镜组的拼接登记走 `storyboard stitch`（见第 9 条）；`storyboard create --from-grid` 不存在，
    网格切图属于画布派生：`moliai derive from-grid <image节点> --rows N --columns N`（见派生章节）。

## 声明式搭建（`apply`）

**一条命令把整张图搭好时的首选**：`moliai apply -f plan.json` 按计划文件幂等建节点 / 改参数 / 建编组 / 连线。
默认**不生成、不删除**；两个可选阶段各自有独立开关：

- `--run`（⚠️ **扣费**）：搭完按 `left` / `context` 依赖**拓扑顺序**提交生成，复用 `group run` 的骨架
  （6 秒节流 / `--max-cost` 预算闸门 / `--continue-on-error` / job 记录 / `--wait` 轮询）
- `--prune`（⚠️ **破坏性**）：删除**计划声明的编组内**、计划里没有的节点；必须 `--yes` 且计划必须有 `group`

```bash
moliai apply -f plan.json --dry-run --diff        # 只看差异（零写入、零扣费）
moliai apply -f plan.json --run --dry-run         # 搭建 + 生成报价（零扣费，先看总成本）
moliai apply -f plan.json --run --max-cost 10     # 搭建 + 生成（扣费；超预算整批零提交）
moliai apply -f plan.json --prune --dry-run       # 看会删哪些组内节点（零写入）
moliai apply -f plan.json --prune --yes           # 搭建 + 清理（删除，24h 可恢复）
```

1. **先 `--dry-run --diff`**：看 `diff.create` / `diff.update[].changes` / `diff.connect` / `diff.unchanged` / `diff.conflicts`。
   `conflicts` 非空时真实执行会直接 `MOLIAI_PLAN_INVALID`（整份拒绝、零写入），先把冲突清掉。
2. 计划格式：`{ "version": 1, "group": "组名"?, "nodes": [...] }`；节点字段
   `name`（必填，计划内唯一）/ `type`（必填）/ `x` / `y` / `upload`（相对计划文件目录）/ `prompt` /
   `content` / `set`（`model` 写 modelKey，其余合并进 modelParams）/ `left` / `context` /
   `editMode` / `fitMode` / `superResolutionType` / `promptPreset` / `layoutPreset` / `anglePreset` / `autoLink`。
   **未知字段会报错**，不要写计划里没定义的键。
3. **按名称对齐 + 幂等**：同名节点更新、缺失新建；同名多个 → 报错（不做任意择一）；`type` 不同 → 整份拒绝。
   重复执行同一份计划安全（不产生重复节点/连线、已有媒体的节点不重复上传、未声明字段不改动）。
4. `left` 与 `context` **都建 `manual` 连线**；想连上游的 text 节点必须 `"editMode": "ai"`（`direct` 文本不接受入线）。
   `{{Node "名称"}}` 占位符引用的节点必须能在计划内或画布上解析到，否则 `MOLIAI_PLAN_INVALID`。
5. 执行顺序固定：上传 → 建节点（含初始参数）→ 改已存在节点参数 → 建/复用编组 → 连线 →（`--run`）→（`--prune`）。
6. 中途失败**不自动回滚**：命令返回非 0，stdout 里 `executed` 是已完成步骤、`rollbackHints` 是可复制的撤销命令、
   `failed` 是失败步骤与原因。按 hints 逐条处理，并把 `failed` 与 traceId 原样报给用户，不要自行猜测已完成了多少。
7. `--run` 只生成「需要生成」的节点：`audio`/`super_resolution`/`depth_capture`/`voice`（`unsupported-type`）、
   计划声明 `upload`（`upload-node`）、正在生成（`already-generating`）、已有产出（`already-completed`/`has-media`）、
   直连文本（`direct-text`）都跳过，原因在 `run.skipped[].reason`。**看不到被跳过的节点就断言"已生成"是错的。**
8. `--run` 有依赖边时只能用 `--concurrency 1`；计划内依赖有环 → `MOLIAI_PLAN_INVALID`（在任何写入之前）。
9. `--prune` 的三重保护：`--yes` 必填（缺省退出码 10）、候选超过 `--max-nodes`（默认 20）**即使带 `--yes` 也拒绝**、
   `--dry-run` 只列清单。计划没有 `group` → 直接报错（**绝不默认整个画布**）。
   候选节点若被计划引用（`left`/`context`/占位符）会拒绝整次 prune——不要试图绕过。

## 破坏性操作

- `moliai node delete <nodeId>` **必须带 `--yes`**，否则 `MOLIAI_CONFIRM_REQUIRED`（退出码 10），`details` 里会列出将删除的节点。
- 批量删除用 `--where '<表达式>'` 或 `--ids a,b`（与位置参数三选一，混用 `MOLIAI_ARG_INVALID`）；命中数超
  `--max-nodes`（缺省 20）同样要 `--yes`。**先 `--dry-run` 确认命中范围**，`--where` 命中 0 个会报错而不是静默成功。
- 删除后 24 小时内可恢复：按输出里的 `restoreHint` 调 `POST /canvases/{canvasId}/node-deletions/{id}/restore`（CLI 无 `node restore` 子命令）。
- 向用户确认前，先把 `details` 里的节点名称/类型如实报出来。
- `moliai connection delete` 同样必须 `--yes`。要能恢复就用 `--ids`（批量端点幂等 + 返回 `deletionOperationId`，24 小时内 `moliai connection restore <opId>`）；单条 `DELETE` 非幂等且普通连线不返回恢复操作 id。
- `moliai task cancel <taskId>` **必须带 `--yes`**；它不退预扣费，确认前先把 `details.status` 与退费说明报给用户。
- `moliai group delete <groupId>` **默认只解组**（节点全部保留，无恢复入口）；`--with-members --yes` 才会连成员节点与连线一起删（24 小时内 `moliai group restore <restoreOperationId>`）。同样必须 `--yes`。
- 分镜组（`groupType=STORYBOARD`）三个破坏性操作**必须用 `storyboard` 子命令**，语义别混：
  - `dissolve` = **组没、节点留**；`clear` = **组在、节点软删**；`to-normal` = **组降级成普通组、节点留在组里**。
  - 三者都不需要网页端操作，也不要写临时脚本直接调 HTTP。
  - 普通编组的写操作对分镜组仍会被本地拒绝（`MOLIAI_UNSUPPORTED`），只有 `group update` 改名称/颜色可用。
- `group update` / `connection update` 支持 `--dry-run --diff`：本地算前后对照、零写入、零请求（除一次画布详情 GET），
  输出 `{ mode: "dry-run", ...ids, diff: { before, after, changes } }`；改名称/颜色/编组框/连线样式前先看 `changes`。

## 任务取消（`task cancel`）

1. `moliai task cancel <taskId> --yes`，端点 `DELETE /api/tasks/{taskId}`。**必须 `--yes`**（缺失退出码 10，`details` 给状态与退费说明）。
2. 后端**只有 `queued` / `processing`** 会被真正取消；其它状态后端返回 200 + `cancelled=false`（no-op），
   CLI 视为失败 `MOLIAI_CONFLICT`（退出码 9）——已完成/已失败任务不能"取消"。
3. 取消成功后状态是 `failed` + `errorCode=TASK_CANCELLED`（**没有** `cancelled` 状态），`currentStatus` 如实回传。
4. **不退预扣费**：`refunded` 恒为 `null`（后端不返回退费信息，不要编造 true/false）。告诉用户钱不会自动退。
5. 不要为了验证而启动新任务再取消——取消不退费，等于白烧一次成本。

## 长任务

- `--wait` 默认 90 秒，**视频经常不够**（实测 268 秒）。正确做法是**提交即返回 + 分轮 wait**，不要提高 `--wait` 硬等——Agent 单条命令 120 秒会先把进程杀掉。
- `run` 拿到 taskId 的那一刻就把 `jobId`/`taskId` 写进 stderr（`[run] 已提交 taskId=... jobId=...`）和作业文件，之后被中断也能接续。
- 未完成时 `run` 返回 `done: false` + `next: moliai wait <jobId>`（退出码 0，不是失败）。
- 接续：`moliai wait <jobId> --max 60`，每轮至多 90 秒；`done:false` 时 `next` 指回自己，照它继续调。
- 跨会话找回：`moliai jobs --active`（当前画布）/ `moliai jobs --all`（=`--everywhere`）/ `moliai jobs show <jobId>`。
- 并行 Agent 区分作业：提交时带 `--label <文本>`（或 `MOLIAI_AGENT_LABEL`），之后 `moliai jobs --label <文本>` 只看自己的。
  ⚠️ 这是**作业标签**（只写本地作业记录），与「连线标签」（`connection create --label`）和
  「参考素材别名」（`derive video-edit --ref-label`）不是一回事，别指望它出现在画布上。
- 提交/准备阶段就失败的尝试会落一条 `status=failed`、`taskId=null` 的作业记录（`jobs show` 给
  `SUBMIT_FAILED` 警告，`wait` 直接报 `MOLIAI_TASK_FAILED`）；这类节点用 `group run --rerun-failed` 重跑。
- 任务失败退出码 6；超过 `--deadline`（默认 3600）退出码 7；被中断退出码 130/143。
- 轮询要有上限与间隔（2 秒间隔，上限 90 秒一轮），不要无限重试；收到用户中断立即停止并如实汇报当前阶段与 jobId。

## 完成通知（`--notify`）

作业到达终态时通知一次，两种粒度：

- **单节点**（`run <node>` / `wait` / `extract` / `derive * --run`）：该作业到达终态时通知一次
- **批量**（`group run` / `run --where --execute` / `apply --run`）：**整批结束发一条汇总**
  （20 个节点 = 1 条，正文如 `[group run] 18 成功 / 2 失败（耗时 320 秒）`）。逐节点明细看命令输出的
  `succeeded[]` / `failed[]` / `skipped[]`，事后用 `moliai jobs` / `jobs show <jobId>`

`--dry-run` 或未加 `--run`（如 `derive video-edit` 默认只预览）时不会触发，只给 `warnings` 说明。

形态：

- `--notify desktop`：系统通知（Windows Toast / macOS / Linux `notify-send`）
- `--notify 'cmd:<本地命令>'`：执行本地命令，作业事实由环境变量提供（**不要**把值拼进命令字符串）

单节点变量：

| 变量 | 含义 |
|---|---|
| `MOLIAI_JOB_ID` / `MOLIAI_TASK_ID` / `MOLIAI_NODE_ID` | 作业 / 任务 / 节点 id（缺失为空串） |
| `MOLIAI_STATUS` | 终态：`completed` / `failed` / `paused` / `dismissed`（批量：有失败=`failed`，否则 `completed`） |
| `MOLIAI_MEDIA_URL` | 产物地址（无产物为空串） |
| `MOLIAI_ELAPSED_SECONDS` | 耗时（秒；批量=整批耗时） |
| `MOLIAI_JOB_LABEL` | 作业标签（`--label` / `MOLIAI_AGENT_LABEL`） |

批量汇总额外变量（`MOLIAI_BATCH_*`）：

| 变量 | 含义 |
|---|---|
| `MOLIAI_BATCH_SCOPE` | 命令标识：`group run` / `run --where` / `apply --run` |
| `MOLIAI_BATCH_SUCCEEDED` / `MOLIAI_BATCH_FAILED` / `MOLIAI_BATCH_SKIPPED` | 成功 / 失败 / 跳过节点数 |
| `MOLIAI_BATCH_ELAPSED_SECONDS` | 整批耗时（秒，与 `MOLIAI_ELAPSED_SECONDS` 同值） |
| `MOLIAI_BATCH_JOB_IDS` | 本次提交的 jobId，逗号分隔 |
| `MOLIAI_BATCH_FAILED_NODES` | `nodeId:errorCode` 逗号分隔 |

- 批量模式下 `MOLIAI_JOB_ID` / `MOLIAI_TASK_ID` / `MOLIAI_NODE_ID` / `MOLIAI_MEDIA_URL` **恒为空串**
  （不是「不设置」：空串能让你用 `-n` / `-z` 稳定判断，也不会把 shell 里的旧值误读成本次作业）
- **只在终态触发一次**：`run --wait 0` 时作业还在跑，输出里会是 `NOTIFY_SKIPPED`；改用 `moliai wait <jobId> --notify ...` 接续
- 通知失败/超时（10 秒）只给 `NOTIFY_FAILED` / `BATCH_NOTIFY_FAILED` / `NOTIFY_DESKTOP_UNAVAILABLE` 警告，
  **不改作业结果与退出码**；遇到这个警告不要当作业失败
- 不做第三方 webhook（飞书等由服务端统一实现），**不要让用户在 CLI 里塞 webhook 凭据**

## 失败处理

- 先读 stderr 错误信封的 `error.code` 与 `error.hint`，不要只看退出码。
- 退出码：2 参数/绑定/模型选择，3 认证授权，4 网络或限流，5 配额与本地环境，6 任务失败，7 超时，8 登录超时，9 状态冲突（409），10 需确认。
- 409 报 `MOLIAI_CONFLICT`：按 hint 重新读取最新数据后重试（版本冲突可省略 `--expected-version`、节点已属其他编组先 `group remove-member`），**不要**当成 bug 去反馈。
- 参数与环境类错误不重试，按 hint 修正后重跑；网络/限流可有限次退避重试。
- 不静默兜底：不换模型、不删参数、不跳过失败步骤来"让它跑通"。未知错误码直接停止并向用户说明。

## 环境变量

`MOLIAI_BASE_URL`（后端地址覆盖，优先级低于 `--base-url`）、`MOLIAI_TOKEN`（覆盖本地凭据，必须同时设 `MOLIAI_BASE_URL`）、`MOLIAI_CANVAS`（当前画布）、`MOLIAI_CONFIG_DIR`（配置目录）、`MOLIAI_CDN_DOMAIN`（受信 CDN 域名）、`MOLIAI_AGENT_LABEL`（作业标签默认值，优先级低于 `--label`）、`MOLIAI_MAX_COST`（成本上限，优先级低于 `--max-cost`）、`MOLIAI_JOBS_DIR`（作业记录目录）。

切环境优先用 `moliai env use <url>`，不要长期依赖 `MOLIAI_BASE_URL`——环境变量会盖过默认环境，容易让人误判当前用的是哪个环境。

**没有 `MOLIAI_PROJECT`**：项目 id 只能来自 `-w/--workspace` 或 `canvas use` 写入的目录绑定。
