# 更新日志

本文件记录 `@moliai/cli` 的版本变更。格式参考 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)，版本号遵循语义化版本。

## [Unreleased]

（无）

## [0.10.2] - 2026-11-26

### 修复

- `login key` / `login token` 在终端里不再静默等待：读 stdin 前会提示「请粘贴 API KEY，然后回车」。
- `login key` / `login token` 在非交互环境（CI / Agent / 重定向）且 stdin 无数据时，改为 10 秒超时报错，不再永久挂起。

## [0.10.1] - 2026-11-26

### 修复

- `task list --client-request-id` 不再要求同时给 `--canvas`：后端已支持 `clientRequestId` 单参数找回（走 `(userId, clientRequestId)` 组合索引，`canvasId` 已降为可选），原来的本地硬校验是过时分支，会封死后端已有能力并给出错误指引。未命中时（后端 404，不区分「不存在」与「不属于当前账号」）给出完整原因说明与后续建议，不自动改用其它查询方式。
- `task list` 改为传 `page` / `pageSize` 并输出 `total` / `hasMore`：此前传 `limit` 不传 `page`/`pageSize`，后端走历史分支不返回分页信息，取到 200 条时无法判断是否还有更多。不返回分页字段的旧版本后端仍按原行为工作（两项为 `null`）。

### 新增

- `task list --page <n>`：0 起页码（默认 0），配合 `--limit`（每页条数，后端 `pageSize`）翻页；`--output text` 末尾追加分页汇总行。

## [0.10.0] - 2026-11-26

### 新增

- `capabilities` 命令：查看各模型的能力矩阵（时长范围、分辨率选项、生成模式、素材上限）以及是否配置了参数契约。数据来自运行期接口，不依赖仓库静态配置。
- `project update` / `project delete`：项目改名、改描述、删除。删除需 `--yes`（不可逆，会删画布与云端文件）。
- `task watch`：实时观察单个任务状态，状态或进度变化时打印一行，终态退出。
- `task cancel --where`：按选择器批量取消任务，需 `--yes`。单条取消行为不变。
- `wait --all-active`：等待当前所有活跃任务（queued/processing）到终态。
- `download --watermark-text` / `--watermark-image`：下载后本地叠加水印。仅支持图片与视频，其他类型明确报错。
- `account list` / `account use` / `account remove`：同一环境下的多账号管理，凭证升级到 v4。
- `login web`：浏览器授权登录（OAuth 2.0 授权码 + PKCE），不需要手动复制 API KEY。需前端授权页配合。
- 全局选项 `--poll-interval`：自定义轮询间隔（0.5-60 秒）。
- 全局选项 `--no-estimate`：跳过费用预估（会失效成本闸门与余额预校验，并与 `--max-cost` 互斥）。
- 全局选项 `--retry`：只读请求失败重试（网络错误/5xx/429），写命令永不重试。

### 修复

- Windows 下 `--json` 输出的中文会因 PowerShell 按系统代码页解码而乱码，且 `ConvertFrom-Json` 直接失败。改为在 Windows 上把 JSON 输出中的非 ASCII 字符转义为 `\uXXXX`，输出纯 ASCII。
- 此前 API KEY 只用于一次性换取 token、不落盘，token 7 天过期后必须手动重新登录。现在 `login key` 默认保存 KEY 并自动续期（剩余不足 1 小时时用 KEY 重新换取）；`--no-save-key` 可关闭。KEY 等同账号全权限且无法单独吊销，已保存到权限 0600 的凭证文件。

### 变更

- `--max-cost` 与 `--no-estimate` 互斥（后者会让前者失去比较基准）。

## [0.9.0] - 2026-11-26

### 新增

- 提交生成任务前做余额预校验：可用余额不足以覆盖预估费用时明确报错并拒绝提交（退出码 5，错误码 `MOLIAI_INSUFFICIENT_BALANCE`）。预估不可用时给出警告并放行，如实说明未做校验。
- 覆盖全部提交链路：run / run --where / group run / apply --run / derive 各场景 / extract / super-resolution。批量按累计预估比较。dry-run 不触发校验。

### 修复

- video 生成的 `resolution` 缺省值改为「显式 > 契约 default > 硬编码 720p > 首个可选档」；此前契约缺失时直接报错，导致所有 video 模型都必须手动传 `--set resolution`。

## [0.8.0] - 2026-11-26

### 变更

- `project create` 仅支持 `canvas`（无限画布）模式；`--mode novel-promotion` 会明确报错并提示到网页端创建。传统模式项目没有画布，CLI 无法对其执行任何写操作。

### 修复

- `derive` 预设场景（`panorama` / `three-view` / `nine-grid` / `portrait-texture`）提交时，若服务端已受理但响应丢失，CLI 之前只报网络错误、不写作业记录，用户重试会重复建节点和任务。现在会明确提示「提交结果未知，先查再重试」，并在提交前落盘 pending 记录，下次执行时警告存在未确认的提交。
- `run` 的提交失败同样区分「明确未生效」与「结果未知」，且结果未知时不再落盘假失败记录（避免 `--rerun-failed` 重复扣费）。
- 结果未知的错误提示附上原 `clientRequestId`，并给出「用同一 ID 重试可命中后端幂等」的指引。

## [0.7.1] - 2026-11-25

### 变更

- `project create` 的默认模式改为 `canvas`（省略 `--mode` 时不再使用后端默认的 `novel-promotion`）。`canvas` 模式会同时创建一张同名画布，更符合 CLI 的使用场景；需要旧行为时显式传 `--mode novel-promotion`。

## [0.7.0] - 2026-11-25

### 新增

- `moliai project create <name>`：创建项目（`POST /api/projects`）。支持 `--description`（≤500 字符）与
  `--mode <novel-promotion|canvas>`（省略时由后端按默认 `novel-promotion` 处理）；`canvas` 模式会顺带创建一张
  同名画布并回填 `canvasIds` / `canvasId`。名称非空且 ≤100 字符，越界本地即报 `MOLIAI_ARG_INVALID`；
  创建成功不自动写目录绑定，输出 `next` 给出下一步命令。此前 `project` 组只有 `list`。

## [0.6.0] - 2026-11-25

### 新增

- `install-boot.ps1`：Windows 一键安装的引导脚本。此前 `irm .../install.ps1 | iex` 在 PowerShell 5.1 与 7.x 下都会因 UTF-8 BOM 解析失败，无法安装；现在改为由纯 ASCII 引导脚本下载安装器并按 UTF-8 解码执行。
- 发版产物新增 `install-boot.ps1`，Release 资产从 7 个增至 8 个。

### 修复

- Windows 安装脚本在非交互场景（重定向、CI、日志捕获）下载缺少跟随重定向的参数，导致 GitHub Release 跳转后拿到空文件、SHA256 校验失败。修复后重定向场景可正常安装。
- Windows 安装日志在输出被重定向时按系统本地编码写出，非本地编码的查看器打开会乱码；改为 UTF-8 输出。
- Linux 安装在 `.profile` 等配置文件已包含安装目录时，仍提示用户手动追加 PATH，容易造成同一目录重复写入；改为自动识别已有配置并提示重开终端即可。
- Windows 安装的下载进度在非交互场景刷屏；改为交互式显示单行进度、非交互静默。
- Windows ARM64 未被正确识别（x64 模拟环境下架构变量为 AMD64），会静默安装 x64 版本；改为同时检查底层架构变量，并明确提示通过系统 x64 模拟运行。

### 变更

- 公开仓库同步时新增死链改写规则，避免指向内部文档的链接在公开仓库中失效。

## [0.5.0] - 2026-11-24

### 新增 `update` 自更新与 `setup --upgrade`

- **`moliai update`**：检测 GitHub Release 最新版本 → 下载当前平台产物 → 按 `SHA256SUMS.txt` 校验 → 替换二进制。
  `--check` 只查版本、`--dry-run` 只列动作（含产物大小）、`--force` 版本相同也重装；
  仓库可用 `--repo <owner/repo>` 指定，优先级 `--repo` > `MOLIAI_UPDATE_REPO` > 配置 `updateRepo` > 默认 `Mr-cjf/moliai-cli`
- **`moliai update config --repo/--show`**：把仓库持久化到 `<配置目录>/config.json` 的 `updateRepo`（读改写，保留其它键）
- **`moliai setup --upgrade`**：与 `moliai update` 完全同一套逻辑（同 `--dry-run` / `--repo` / `--force`），输出为 update 形态
- **Windows 延迟替换**：运行中的 exe 无法覆盖，改为生成 `.update.bat` 并以 detached 方式启动，CLI 立即退出，
  脚本 2 秒后 `move /y` 覆盖并自删；因此 Windows 下 `replaced=false`，`message` 明确提示「CLI 将退出，更新在后台完成」
- **POSIX 原子替换**：同目录 `rename`（`current → current.old`、`new → current`），失败回滚，成功删除 `.old`
- **平台支持**：`win32-x64` / `darwin-x64` / `darwin-arm64` / `linux-x64`；其它平台显式 `MOLIAI_UNSUPPORTED`
- **npm/源码形态显式拒绝自更新**（`process.execPath` 是 node，替换会破坏运行时），提示 `npm i -g @moliai/cli@latest`
- **失败不静默**：网络不可达 / HTTP 404 / 403 限流 / 缺产物 / 缺校验和 / SHA256 不匹配 均为明确错误，
  校验失败即删除临时文件，不做自动换源或跳过
- 新增 `src/core/update/{version,platform,release,download,replace,config}.ts` 与 `src/commands/update.ts`

## [0.4.0]

### `diagnose` 对接后端 Doctor 接口（保留本地降级）

- **`moliai diagnose` 改为优先调 `POST /canvases/{id}/doctor/reports`（`{"scope":"all"}`）**：
  报告含 `empty` / `failed` / `rerunnable` 三类，`refError` / `orderRisk` 由后端在 `notImplemented` 中
  声明未实现（`summary` 计数恒为 0，CLI 不补造内容）
- **新增 `data.source`（`server` / `local`）**：明确标注本次报告来自后端还是本地降级扫描；
  两种来源输出同一套字段（不可用处为空数组 / 空计数 / `null`）
- **降级判定只认一种情况**：先 `GET /canvases/{id}` 确认画布存在；`POST` 返回 404 且 `serverCode`
  不是业务码（缺失或 `NOT_FOUND`）→ 判定「后端没有该路由」→ 降级本地扫描（现有一套逻辑原样保留），
  并追加 warning「后端未提供 Doctor 接口，使用本地扫描（仅 empty + failed）」
- **不降级**（如实报错）：`POST` 404 且 `serverCode` 是 `DOCTOR_*` / `CANVAS_*` 等业务码、5xx、401/403、网络错误
  ——这些是业务拒绝或后端故障，降级会把真实问题掩盖成「扫不到问题」
- **后端报告严格解析**：缺字段 / `failReason` 未登记 / `category` 未登记 → `MOLIAI_INTERNAL_ERROR`
  （带 `serverTraceId`），不猜、不丢弃问题条目
- 后端模式下 `failed[].remediation` 直接用后端给出的命令（如 `moliai run "<节点名>" --rerun-failed`）；
  `--out` 与只读边界不变

## [0.3.0]

### 新增 `storyboard stitch`：本地 ffmpeg 拼图 → 上传 → 登记结果节点

- **新命令 `moliai storyboard stitch <组> -o <png>`**：读 `GET .../storyboard/stitch-inputs` 的
  `cells[]`（每格 `slotIndex/x/y/width/height/mediaUrl`）→ 下载每格图 → 本地 ffmpeg 合成 PNG →
  四段式分片上传 → `POST .../storyboard/stitches` 登记；**只上传与登记，不提交生成、不扣费**
- **像素口径**：输出尺寸完全取后端 `outputWidth × outputHeight`；每格先 `contain` 缩放（保持比例、
  不拉伸）再 `pad` 到精确 `w×h`（填充色 = 组背景色，`null` 时透明），最后按 `cells` 的 `x/y`
  `overlay` 到画布。合成后本地复核 PNG 尺寸，不符即报错，不上传错图
- **`inputSnapshot` 原样回传**：`config` / `inputs` 直接取服务端快照，`expectedCanvasVersion` 与
  `inputCanvasVersion` 都取 `stitch-inputs.canvasVersion`（后端要求二者相等）；`inputs` 精确等于
  有图成员集合，多/少都在本地先拦
- **依赖后端新字段**：`cells[]` / `outputWidth` / `outputHeight`（`cellGap` / `padding` / `cellLongSide`
  仅回显）。字段为空（旧构建）→ `MOLIAI_UNSUPPORTED` 明确报错并**不下载、不上传、不写画布**；
  空组（零有图成员）→ `MOLIAI_ARG_INVALID`「分镜组没有可拼接的图」
- **`--keep-inputs <dir>`** 保留下载的原图（`slot-<slotIndex>.png`），默认用临时目录并在结束后清理
- 新增 `src/core/ffmpeg/image-ops.ts`（`compositeStoryboardPng` / `cropGridImages` /
  `probeLocalImageSize`）；新增 `src/commands/storyboard-stitch.ts`

### 新增 `derive from-grid`：网格切图派生 N 个 image 节点

- **新命令 `moliai derive from-grid <image节点> --rows N --columns N`**：下载源图 →
  ffmpeg `crop` 切成 N 张 → 逐张上传 → 创建 N 个 `image` 节点（`origin=manual`，挂 `mediaUrl` +
  `mediaId`）→ 从源节点各建一条 `manual` 连线。**只建节点与连线，不提交生成、不扣费**
- **切图口径**：`gap=0` 时按「左右边界各自取整后相减」切分，余数归最后一格（不丢像素、不重叠）；
  `--gap <px>` 表示源图格子之间本身有间隔，先扣掉 `count-1` 个间隔再等分，间隔不进入产物
- **定位**：`--x/--y` 给首个结果节点坐标（都不给时复用 `canvas-placement` 的避让算法），
  其余按 `rows × columns` 网格顺延（节点间距 40）
- **中途失败不静默**：错误 `details.createdNodes` 列出已创建节点（节点/连线无幂等键，不做回滚）
- `derive list` 增加 `from-grid` 场景（共 13 项）

### 新增 `diagnose`：画布内容只读体检（部分实现：`empty` + `failed`）

- **新命令 `moliai diagnose [canvasId] [--out <path>]`**：纯只读（只发 `GET /canvases/{id}` 与失败节点的
  `GET /tasks/{taskId}`），无 `--fix`、无 `--yes`、不自动重跑、零写入零扣费
- **只输出两类**：
  - `empty`：无内容 **且** 无任务（`taskId` 为空）。text 节点看 `content` 是否空白；其余类型看
    `mediaUrl` / `mediaId` / `content` 是否全空
  - `failed`：节点 `status=failed` 且有 `taskId` → 查任务 → 映射 `failReason`，并给出可执行
    `remediation`（`moliai run "<节点名>"`，无名称时用 nodeId）
- **`failReason` 映射（§6.15.3）**：`SENSITIVE_CONTENT`→`compliance`、
  `TOO_MANY_REFERENCE_IMAGES`→`reference_limit`、`TASK_CANCELLED`→`cancelled`、
  提交期拦截类（`MODEL_UNSUPPORTED` / `TASK_TYPE_MISMATCH` / `COUNT_OUT_OF_RANGE` / `CONTEXT_NODE_INVALID`）→`invalid_request`；
  兜底顺序为「先看 `errorCode`，未登记再看 `error.code`」，都没登记才是 `unknown`
- **另外三类恒为空 + 显式说明**：`refErrors` / `orderRisks` / `rerunnable` 需要后端 Doctor 三段接口
  （`/doctor/reports` 等），当前后端零实现；按需求 §8.4「未接入前不得输出这些分类」，保持空数组并在
  `warnings` 里写明原因与「接入时须标注 `source: client_check`」，**不静默返回空**
- **`reportId` 由 CLI 本地生成**（`sha256(canvasId + canvasVersion + 时间戳)` 前 8 位，格式 `report-<hash>`）；
  后端不保存诊断报告，该 id 只用于引用本次本地报告
- **不静默**：`status=failed` 但没有 `taskId` 的节点无法映射 `failReason`，会在 `warnings` 中点名列出；
  失败节点的任务详情取不到（接口报错/缺 `task`）时整条命令显式失败，不伪造 `unknown`
- `--out` 落盘内容与 stdout 的 `data` 完全相同；输出字段登记进 `OUTPUT_FIELDS_REGISTRY`（`moliai schema diagnose` 可见）

### 新增 `run --explain`：输出每个参数的来源（零写入）

- **`run` 新增全局风格开关 `--explain`**：在 `--dry-run` 基础上输出 `data.explain`
  = `{ request（已脱敏）, parameterSources, steps, warnings }`，回答「为什么这个值是它」
- **`--explain` 强制走 dry-run**：不写画布、不建任务、不扣费（NFR-20）；批量模式下会忽略
  `--execute` 并在 `warnings` 中说明只输出预览
- **来源七类**：`explicit` / `binding` / `schema-default` / `upstream-inferred` / `node-config` /
  `cli-default` / `unknown`。用户显式传入的值即使等于契约默认值也标 `explicit`
- **只在参数组装环节埋点**判定：画布来自 `resolveCanvasId` 的 source、prompt 来自 `resolvePrompt` 的
  source、模型来自是否传 `--model`、生成参数来自 `--set` / 节点 `modelParams` / 契约 `default`
- **schema 覆盖限制如实标注**：契约只覆盖已配置 `parameterSchema` 的 modelKey（当前
  `qwen-image::qwen-image-2.1`、`tokenproto::doubao-seedance-2-5-260628` 等）；其它模型
  标 `unknown` + warning，**不静默省略**
- **prepare 被拒时也附 explain**：`--explain` 下若 400，`error.details.explain` 同样给出请求体与来源，
  并列出「契约必填但未提供」的参数（含契约默认值）
- 新增 `src/core/explain.ts`（来源判定 / 契约默认值查询 / 脱敏）；`RunDryRunData` 增加可选 `explain`

### 打通 `derive video-continuation --run`（frontend_clip 裁切上传 + 报价口径）

- **`derive video-continuation --run` 现在真的可用**：下载源视频 → 本地 ffmpeg 裁切 `[--from, --to)` →
  上传片段取 `clipMediaId` → `POST /canvases/{id}/generate` 以 `frontend_clip` 模式提交。
  补齐此前缺失的 6 个字段：`videoContinuation.inputMode/clipMediaId/clipDurationMs/extensionDurationSeconds`、
  外层 `options.duration` / `options.resolution`，外加 `sourceExpectations`（复用创建时的 prepare 结果）。
  此前请求被后端 400 `VIDEO_CONTINUATION_INPUT_MODE_UNSUPPORTED`
- **新参数**：`--duration <秒>`（输出/续写秒数，4–30 整数，`--run` 必填）、
  `--resolution <480p|720p>`（默认 720p）、`--fast`（裁切改用 `-c copy`）、`--keep-clip <path>`（保留片段检查）
- **报价修正**：`--dry-run --run` 与提交前报价都改用 `videoContinuationBilling{inputMode, selectedDurationMs,
  extensionDurationSeconds}` 口径，并显式带 `options.resolution`（此前只发 `{apiType, model, options.duration}`
  落到 1080p 默认档口径错误）。实测 720p 4 秒 = **64**（原口径 100）
- **`core/ffmpeg` 新增 `trimVideo`**：默认重编码（`libx264 -crf 20 -preset veryfast` + `aac 128k`，
  精确到帧），`{ fast: true }` 用 `-c copy`；返回值用 `probeDuration` + ffprobe 回读**实际**时长与宽高
- **许可证口径更新**：ffmpeg 不随 CLI 分发，改用用户系统 ffmpeg，因此不再受 LGPL 约束，
  重编码使用用户 ffmpeg 自带编码器（`media-ops.ts` / `ffmpeg/index.ts` 注释同步修正）

### 新增（音频两个派生场景）

- **运行期 ffmpeg 解析（`core/ffmpeg/`）**：`--ffmpeg` > `MOLIAI_FFMPEG` > PATH > 显式失败
  （`MOLIAI_UNSUPPORTED`，hint 给出分平台安装指引）；**不内置 ffmpeg**，用户装系统版即可；
  `ffprobe` 可选（`MOLIAI_FFPROBE`），没有时回退解析 `ffmpeg -i`
- **`doctor` 新增 `ffmpeg` 检查项**：显示来源（系统/指定）、版本与路径；缺失为 `warn`（只影响音频派生）
- **`derive audio-separation`（音视频分离）**：本地抽音轨（PCM wav）+ 去音轨（视频流复制）→ 上传两个文件 →
  `POST /derivations/video-audio-separation` 一次性建无声视频节点 + 分离音频节点 + 2 条派生连线
- **`derive audio-process`（音频处理）**：本地截取（`--trim-start`/`--trim-end`，区间 ≥0.5 秒）或
  保调变速（`--speed 0.1–4.0`，`atempo`，超出单级范围自动串联）→ 上传 → `POST /derivations/audio-processing`
- 两个场景都**只建节点与派生连线，不提交生成、不扣费**；支持 `--dry-run`（零写入预览步骤）、
  `--operation-id` 幂等、`--expected-version`、`--keep-work-files`；`derive list` 里状态由 `supported: false` 改为 `true`
- **音频输出固定 PCM wav**：后端上传白名单硬编码 `{wav, mp3}`（m4a/aac 会被 400 `DOODLE_IMAGE_TYPE_INVALID`），
  而 mp3 编码器按许可证红线不使用 → 唯一组合是 wav；体积代价见 README
- **NOTICE**：ffmpeg 不随包分发，仅说明「运行期需用户自行安装、不经本软件分发」

## [0.2.0]

### 修复（derive 预算闸门覆盖全部子命令）

- `derive depth-capture` / `derive video-continuation` 与 4 个预设图场景
  （`panorama` / `three-view` / `nine-grid` / `portrait-texture`）补齐 `--max-cost <n>`
  （也可用 `MOLIAI_MAX_COST`）：报价之后、提交之前校验，超限或无法预估时零提交并返回
  `MOLIAI_BUDGET_EXCEEDED`（退出码 5）。此前这 6 个子命令传 `--max-cost` 会报
  `error: unknown option '--max-cost'`，与 `image-edit` / `video-edit` / `super-resolution` 不一致

### 修复（回归测试发现的 5 项不一致 + 3 项建议）

- `node delete <nodeId> --max-nodes` 不再静默忽略：单节点模式下传 `--where` 专属参数直接
  `MOLIAI_ARG_INVALID`（与 `node update` 对齐）；`--dry-run` 在单节点模式仍然有效，不受影响
- `group run` 接受 `--dry-run`：与默认预览等价（no-op，零扣费），并提示「默认即预览，`--execute` 才提交」；
  `--dry-run` 与 `--execute` 同时给 → `MOLIAI_ARG_INVALID`（语义相反，不静默择一）
- `run --where --dry-run` 增加冗余提示：批量模式默认即预览，`--dry-run` 可省略
- `node list --model <modelKey>`：按「下一次生成使用的模型」精确过滤（`modelKey` 优先，为空回退
  `generationModel`，与 `--where model=` 同一规则）；README 说明 `node list` 专用参数与 `--where` 是互补关系
- `extract` 与 `derive * --run`（`depth-capture` / `video-continuation` / `panorama` / `three-view` /
  `nine-grid` / `portrait-texture` / `super-resolution` / `image-edit` / `video-edit`）补上 `--notify`，
  覆盖范围与 `run` / `wait` 一致；`--dry-run` 或未加 `--run` 时显式 `warnings` 说明本次不会触发
- 明确只接受 UUID 的入参增加本地格式校验：`node update <nodeId>` / `node delete <nodeId>` /
  `task get <taskId>` / `task cancel <taskId>` 传非 UUID → `MOLIAI_ARG_INVALID`「不是合法的 UUID：xxx」，
  不再被报成「画布中找不到节点」或服务端 404；接受「节点引用」（`run` / `extract` / `derive` /
  `node delete --ids`）的地方不加该校验（允许名称）。新增 `core/uuid.ts`
- 文档：`--diff` 语义分叉（`apply` 的 `--diff` 可独立使用；其他命令必须配合 `--dry-run`）、
  Windows PowerShell 中文乱码的处理办法（`[Console]::OutputEncoding = [Text.Encoding]::UTF8`）

### 新增

- **写操作预演前后对照（`--dry-run --diff`）**
  - `node update`（单节点**新增** `--dry-run`；批量模式原已有）与 `node update --where` 都支持 `--diff`
  - `group update` / `connection update` 新增 `--dry-run` 与 `--diff`
  - `storyboard config`（原已有 `--dry-run`）新增 `--diff`
  - 输出统一为 `{ mode: "dry-run", <定位字段>, diff: { before, after, changes } }`：
    `before`/`after` 只含**本次要改的字段**，`changes` 只含**真正变化**的字段
  - 语义：`null` 是显式清空（`--clear-name` → `{ from: "旧名", to: null }`），「没传该字段」不产生任何条目；
    数组/对象按键排序后深比较；`group update` 的 `expectedCanvasVersion`（并发控制）不参与对照
  - `--diff` 单独使用（不带 `--dry-run`）→ `MOLIAI_ARG_INVALID`（退出码 2）：不偷偷替用户打开预演
  - 新模块 `core/field-diff.ts`（`fieldDiff` / `buildFieldDiff` / `assertDiffRequiresDryRun`）

- **作业标签（`--label` / `MOLIAI_AGENT_LABEL`）与完成通知（`--notify`）**
  - `JobRecord` 新增 `label` 字段（写进本地作业记录 JSON）；旧版本记录没有该字段，读取时按
    `null` 处理（向后兼容，不会报 `MOLIAI_JOB_CORRUPTED`）
  - 优先级：`--label` > `MOLIAI_AGENT_LABEL` > 无标签；`--label ""` 显式报 `MOLIAI_ARG_INVALID`
  - 支持范围：所有会写作业记录的命令——`run`（单节点与 `--where` 批量）、`group run`、
    `apply --run`、`derive`（`depth-capture` / `video-continuation` / `preset` 系列 /
    `super-resolution` / `image-edit` / `video-edit`）的 `--run`、`extract`
  - `moliai jobs --label <文本>` 按作业标签筛选（精确匹配）；`moliai jobs --everywhere` 与
    `--all` 等价（跨全部画布）；`jobs` 输出每项新增 `label` 字段
  - ⚠️ 作业标签与**连线标签**（`connection create/update --label` → 后端连线记录里的连线标签字段）、
    **参考素材别名**（`derive video-edit --ref-label`）是三个不同东西，README 有对照表；
    作业标签只写本地作业记录，**不进请求体、不影响生成结果**
  - `--notify desktop | cmd:"<本地命令>"`（`run` / `wait` / `group run` / `apply --run`）：
    作业到达终态（`completed`/`failed`/`paused`/`dismissed`）时通知一次；`cmd:` 通过环境变量
    传入 `MOLIAI_JOB_ID` / `MOLIAI_TASK_ID` / `MOLIAI_NODE_ID` / `MOLIAI_STATUS` /
    `MOLIAI_MEDIA_URL` / `MOLIAI_ELAPSED_SECONDS` / `MOLIAI_JOB_LABEL`（不拼命令字符串，避免注入）
  - 通知失败/超时（10 秒，Windows 用 `taskkill /T` 终止进程树）只写 `NOTIFY_FAILED` /
    `NOTIFY_DESKTOP_UNAVAILABLE` 警告，**不改变作业结果与退出码**；系统通知不可用时显式告警，
    不静默跳过；不做第三方 webhook（飞书等由服务端实现）
  - 新增内部模块 `core/notify.ts`；`resolveAgentLabel` 放在 `core/environment.ts`（与
    `resolveMaxCost` 同范式）
- **`derive image-edit`：涂鸦重绘（C-2b）**
  - 新增 `moliai derive image-edit <源节点> [canvasId] --doodle <路径|URL>`：源图 + 涂鸦整图 → 新 `image`
    结果节点（建节点 + `manual` 连线）；**默认零扣费**，`--run` 才提交生成
  - **`--doodle` 是「源图 + 涂鸦」的完整整图，不是 mask**：后端把它追加到参考图末尾并自动前置固定
    prompt 前缀「对涂鸦区域重绘，涂鸦区域重绘后，去掉涂鸦。」，CLI 不重复加
  - 本地文件走单次 multipart 上传 `POST /canvases/{id}/upload-doodle`（复用 `requestMultipart`），
    按后端契约**必须带 `width`/`height`**，因此 CLI 先用文件头解析 PNG/JPEG/WebP 宽高；
    上限 200MB；`http(s)://` 开头的 `--doodle` 直接当完整 URL 用、不上传
  - **尺寸一致性检查（只警告不阻断）**：本地涂鸦图宽高与源节点 `mediaWidth`/`mediaHeight` 不一致时
    给 `DOODLE_SIZE_MISMATCH` 警告（模型会拉伸对齐，重绘区域可能偏移）；URL 形式跳过该检查
  - 计费 `apiType=image`，价格由模型决定（`wetoken::doubao-seedream-5-0-260128` = 2/张，
    `qwen-image::qwen-image-2.1` = 0.5/张），`--dry-run --run` 报价 + `--max-cost` 提交前拦截
  - 结果回写到 CLI 预创建的 `targetNodeId`（Worker 不另建节点）；`--dry-run` 时本地涂鸦图**不上传**
- **`derive video-edit`：视频编辑（C-2b）**
  - 新增 `moliai derive video-edit <源节点> [canvasId] --model <k>`：**默认只预览 + 报价（零写入、零扣费）**，
    必须显式 `--run` 才提交（720p 24 / 480p 12 魔力值每秒，10 秒 = 240）
  - **绝不传 `targetNodeId`**：Worker 才走新建分支并写入 `derivedFromNodeId` / `derivationType=video_edit` /
    `derivationOperationId=taskId`；CLI 提交后按这两个字段**反查结果节点**，反查不到如实告警返回 null
  - `sourceExpectations` 由 CLI 先 `reference-media/prepare`（源视频 + 视频类 `--ref` 各一条，
    条数必须与实际视频消费精确相等，图片/音频 ref 不计入）；`frameAnnotations` 恒为 `[]`
  - `--ref` / `--ref-label` 映射成 `videoEdit.references[]`（`referenceId` 自动 `ref-1..N`，
    `mediaType` 按节点类型推导，`url` 用节点 `mediaUrl`）
  - `--duration` 被接受但不生效（后端在 `videoEdit` 分支 `remove("duration")`），只回 `DURATION_IGNORED` 警告；
    `--resolution` 只接受小写 `480p`/`720p` 且 `--run` 时必填；源时长强制 4–30.2 秒
  - 报价与后端预扣同口径：`generationMode=reference`（`hasReferenceMedia=true` 才命中 24/12 档位，
    否则会按 normal 档低估 60%）+ `ceil(源时长ms/1000)` 计费秒数
  - `derive list` 中 `image-edit` / `video-edit` 由「未支持」改为支持；`derive` 描述同步；
    新增 `DERIVE_IMAGE_EDIT_OUTPUT_FIELDS` / `DERIVE_VIDEO_EDIT_OUTPUT_FIELDS`
  - 新增内部模块 `derive-edit-run.ts`（两个命令共用：prepare → estimate → `--max-cost` 闸门 →
    generate → 轮询 → 结果定位），结果定位支持「已知节点 id」与「按派生字段反查」两种规则
- **`derive super-resolution`：图片 / 视频超分（需求 §6.13.7）**
  - 新增 `moliai derive super-resolution <源节点> [canvasId]`：按源节点类型自动选模式
    （`image` → `super-resolution-image`；`video` → `super-resolution-video`；`super_resolution`
    节点按 `superResolutionType` 判定），建 `super_resolution` 节点 + `manual` 连线，**默认零扣费**，
    `--run` 才提交生成（`model` 固定 `tencent::mps-super-resolution`）
  - 图片目标：`--size 720p|1080p|2k|4k`（档位换算照抄网页端：短边对齐 + 长边按源宽高比 + 图片超 4096
    等比缩到长边 4096），或 `--width`/`--height`（整数 1–4096）；两者互斥且必须给一组
  - 视频目标：`--resolution 720P|1080P|2K|4K`（**大小写敏感**，小写本地即拒）；
    `--duration <秒>` 可选（只写 `options.duration`，不改变计费时长）
  - **本地强制不降级校验**（后端只校验 1–4096，**不校验目标必须大于源**，降级会白扣费）：
    `min(target) > min(source)`，否则 `MOLIAI_ARG_INVALID`「目标分辨率必须高于源分辨率」；
    源节点缺 `mediaWidth`/`mediaHeight` 时同样拒绝（无法判断）
  - 计费与报价同口径：图片按目标短边档位 × count（720p 0.2 / 1080p 0.4 / 2k 0.8 / 4k 1.6 / 8k 3.2），
    视频按每秒单价 × 服务端取整时长 × count（720P 0.25 / 1080P 0.5 / 2K 1.0 / 4K 2.0 / 8K 8.0 每秒）；
    `--dry-run --run` 报价，`--max-cost` 在提交前拦截（无法预估或超限时零提交）
  - 结果由 Worker 回写到 `targetNodeId`（不建新节点）：`mediaUrl` / `mediaId` / `mediaWidth` /
    `mediaHeight` / `generationModel` / `superResolutionType` / `origin=ai_generated`；
    `--run` 完成后从画布回读该节点并在输出 `run.mediaWidth`/`run.mediaHeight` 中确认
  - `run-executor` 的 `BILLING_API_TYPE_BY_TASK_TYPE` 补 `super-resolution-image → image`、
    `super-resolution-video → video`（供报价）；`TASK_TYPE_BY_NODE_TYPE` **不加入**
    `super_resolution`——`run` 的通用路径带不上 `sourceUrl`/目标尺寸，放行只会换来后端 400，
    错误提示改为指向 `moliai derive super-resolution`
  - `derive list` 中 `super-resolution` 由「未支持」改为支持，`derive` 命令描述与 `outputFields` 同步
    （新增 `DERIVE_SUPER_RESOLUTION_OUTPUT_FIELDS`）
  - 定位复用 `canvas-placement` 新增的 `resolveDerivedPlacement`（与 derive 其它场景同一套避让算法）
- **`apply` 声明式搭建骨架（需求 §6.13.5）**
  - 新增 `moliai apply -f plan.json [--dry-run] [--diff] [--canvas <id>] [--yes]`：按计划文件**幂等**搭建画布
    （上传本地素材 / 建节点 / 改生成参数 / 建或复用编组 / 建 manual 连线），**全程零扣费**
  - 计划格式 `{ "version": 1, "group"?: string, "nodes": PlanNode[] }`；节点支持 `name` / `type` / `x` / `y` /
    `upload` / `prompt` / `content` / `set` / `left` / `context` / `editMode` / `fitMode` / `superResolutionType` /
    `promptPreset` / `layoutPreset` / `anglePreset` / `autoLink`；**未知字段显式拒绝**（拼写错误不会被静默忽略）
  - **按名称对齐**：计划节点名与画布现有节点名（trim + 忽略大小写）匹配 → 命中更新、缺失新建；
    画布同名节点多个 → `MOLIAI_PLAN_INVALID`（名称歧义，不做任意择一）；`type` 不同 → 整份拒绝、不部分执行
  - **先全量校验再写**：名称唯一性 / 类型白名单 / 字段 schema / `upload` 文件存在性 /
    `left`·`context`·`{{Node "名"}}` 占位符可解析性 / 连线规则（类型矩阵、direct 文本入线、超分语义与单上游、
    全图环检测）全部通过后才写入；任一项不通过 → `MOLIAI_PLAN_INVALID`（退出码 2）+ **零写入**
  - 执行顺序固定：**上传 → 建节点（含初始参数） → 改已存在节点参数 → 建/复用编组 → 连线**；
    `modelParams` 先读后合并（后端对普通节点是整体替换，只发改动键会清掉其它参数）
  - 幂等：重复执行不产生重复节点/连线；节点已有媒体不重复上传；计划未声明的字段不改动；
    新建节点未给坐标时按计划顺序自动排布（4 列网格，确定性）
  - 中途失败**不自动回滚**：停止后续步骤，stdout 输出 `{ mode, plan, diff, executed[], failed, run, prune, rollbackHints[] }`
    并按失败原因返回非 0 退出码；`rollbackHints` 按已完成步骤给出可复制的撤销命令
  - 新增错误码 `MOLIAI_PLAN_INVALID`（退出码 2）

- **`apply --run` 建完即生成 + `apply --prune` 清理组内计划外节点（需求 §6.13.6；PR-6）**
  - `--run`：搭建完成后按计划 `left` / `context` 依赖做 **Kahn 拓扑排序**后提交生成；
    环 → `MOLIAI_PLAN_INVALID`（在任何写入之前报错）；计划内存在依赖边时禁止 `--concurrency > 1`
  - 生成骨架完全复用 `batch-run`（`group run` / `run --where` 同一套）：6 秒提交节流、`--max-cost` 预算闸门
    （无法预估或超限 → 整批零提交）、`--continue-on-error`、job 记录与 `--wait` 轮询
  - 「是否需要生成」按四条硬规则判定，全部写进 `run.skipped[].reason`：
    `unsupported-type`（audio / super_resolution / depth_capture / voice）、`upload-node`（计划声明 `upload`）、
    `already-generating` / `already-completed` / `has-media`（远端已生成或有产出）、`direct-text`（`editMode=direct` 文本）
  - 任一节点无法构建提交请求（缺模型 / 缺提示词 / 计划 `set` 参数非法）→ **整批零提交**；
    计划 `set` 里的参数按**显式参数**校验（违法报错），不会被当成节点继承参数静默剔除
  - `--run --dry-run` 只报价（零扣费）：输出拓扑顺序、逐节点预估成本、跳过原因、预计提交耗时
  - `--prune`：删除**计划声明的编组内**、计划里没有的节点（组外节点永不触碰）；计划无 `group` → 明确报错拒绝
    （绝不默认整个画布）；同名编组多个 / 分镜组 → 拒绝
  - 三重保护：必须 `--yes`（缺省 `MOLIAI_CONFIRM_REQUIRED`，退出码 10，列出全部候选）/
    受 `--max-nodes`（默认 20）硬上限约束（超限即使带 `--yes` 也拒绝，不自动截断）/ `--dry-run` 只列清单不删除
  - 额外保护：候选节点若被计划引用（`left` / `context` / `{{Node "名"}}`）→ 拒绝整次 prune
    （避免删掉后计划里的引用变成悬空）
  - 删除走 `POST /canvases/{id}/node-deletions`（批量、幂等、24h 可恢复），输出 `deletionOperationId` 与恢复提示
  - `apply` 输出新增 `run` / `prune` 两段（未请求时为 `null`），`mode` 扩展为
    `dry-run` / `apply` / `apply+run` / `apply+prune` / `apply+run+prune`

- **`node update -s/--set` 生成参数 + `node update --where` 批量改参数（需求 §6.13.4）**
  - `node update` 新增 `--model <provider::modelId>`（写 `modelKey`）、`-s, --set <key=value>`（可重复，
    写 `modelParams[key]`，值与 `run --set` 一致：**JSON 优先**，`--set count=3` 是数字、`--set ratio=9:16` 是字符串）、
    `--clear-params`（提交 `{}` 清空）；`--clear-params` 与 `--set` 互斥
  - **`modelParams` 先读后合并**：后端 `CanvasApiService#mergeModelParams` 对普通节点是把请求里的
    `modelParams` **整体替换**（只有 `video_continuation` / `voice` 节点在服务端逐键合并），因此 CLI 提交前先读节点
    当前 `modelParams` 并在本地合并——`node update <id> -s duration=5` 不会丢掉已有 `ratio`
  - 新增 `node update --where '<表达式>' -s ratio=9:16`：复用 `src/core/node-selector.ts`，走
    `PUT /api/canvases/{canvasId}/nodes/batch`，逐节点先读后合并后一次性提交
  - 批量模式新增 `--max-nodes <n>`（缺省 20）、`--dry-run`（展示将改动的节点与目标参数，不提交）、
    `--yes`（超上限时截断到上限并置 `truncated: true`，与 `run --where` 一致）；这三个参数在单节点模式传会 `MOLIAI_ARG_INVALID`
  - 写后**回读校验**：重新拉画布详情逐节点比对 `modelKey` / `modelParams`（键序无关比较），
    不一致进 `failed[]` 并附原因，不用后端 `updatedCount` 冒充成功
  - 输出：`{ dryRun, canvasId, matched, updated, failed[], nodes[{nodeId,name,nodeType,modelKey,modelParams}],
    canvasVersion, truncated }`（`NODE_PARAMS_UPDATE_OUTPUT_FIELDS` 登记）；单节点 `node update` 输出新增
    `modelKey` / `modelParams`（后端回执最终值）
  - 边界：`--where` 与位置参数 `nodeId` 互斥、`--set` 非 `key=value`、命中 0 个、`--clear-params` + `--set`
    → 均 `MOLIAI_ARG_INVALID`
  - 形态与需求原文（`moliai node --where ... -s ...`）的差异：本 CLI 采用 `moliai node update --where ...`，
    与 `node delete --where` 一致；`node` 是命令组，在组上挂写入参数会让 `node` 裸命令也具备写入副作用

- **`run --where` 批量生成 + `run --rerun-failed --max-attempts`（需求 §6.12）**
  - `moliai run --where '<expr>'`：复用 `src/core/node-selector.ts` 的 `selectNodes` 选中节点，
    **默认只预览（零扣费）**，`--execute` 才真跑（**与单节点 `run` 默认真跑刻意相反**，文档已显著标注）
  - `moliai run --rerun-failed`：等价于 `--where 'status=failed'`，并额外包含「远端仍 `idle`、
    本地有失败作业记录」的节点（prepare 阶段被拒的情形）；默认预览
  - `--max-attempts <n>`（默认 1）：同一节点最多重跑 n 次。已重跑次数读本地作业记录推断
    （`本地 run 作业记录数 - 1`），超限进 `skipped`（`reason=max-attempts-reached`），
    换机器无本地记录时按 0 计并在 `warnings` 说明
  - `group run --rerun-failed` 同步支持 `--max-attempts`（**不传时不限制**，保持既有行为）
  - 新增 `src/commands/batch-run.ts`：把 `group run` 的编排骨架（逐节点构建 → 参数校验 → 成本预估 →
    `--max-cost` 闸门 → 6 秒提交节流 / 500ms 查询节流 → 并发 / `--continue-on-error` → 结果汇总）
    抽成共享模块，`group run` 与 `run --where` 共用；重构前后 `group run` 的 7 条预览/错误路径输出
    逐字节一致（仅 traceId 变化）
  - 新增 `src/commands/run-batch.ts`：批量模式的选项解析、选择器求值、命中上限/`--yes` 确认、
    跳过判定（`generating` / `unsupported-type` / `max-attempts-reached`）与输出
  - 输出：预览 `{ mode:"preview", where, matched, matchedBeforeLimit, nodes[{nodeId,name,nodeType,status,
    estimatedCost,willSubmit,skipReason,attemptsUsed}], totalEstimatedCost, maxCost, withinBudget,
    estimatedSubmitMinutes, blockers, skipped }`；执行 `{ mode:"execute", where, succeeded, failed,
    skipped, totalEstimatedCost, elapsedSeconds }`
  - 边界：命中 0 个 → `MOLIAI_ARG_INVALID`；命中 > `--max-nodes`（默认 20）无 `--yes` →
    `MOLIAI_CONFIRM_REQUIRED`（带 `--yes` 时按上限截断）；`--where` 与位置参数 `<node>` 冲突、
    `--where` 与 `--rerun-failed` 冲突、单节点模式用批量专用参数 → 均 `MOLIAI_ARG_INVALID`；
    批量模式不支持 `--ref-*` / `--client-request-id`（显式报错）
  - `src/commands/run.ts` 的位置参数改为可选：批量模式下第一个位置参数是画布 id，单节点行为零变化

- **`--where` 选择器 + `node delete` 批量删除（需求 §6.13.4）**
  - 新增 `src/core/node-selector.ts`：`parseWhere` 解析 `'字段 运算符 值'` 用 `&` 连接的表达式
    （运算符只有 `=` 与 `~`；值按**第一个**运算符切分，`ark::doubao-seedance-2.0` / 中文 / 值内 `=` 无需转义），
    `selectNodes` 做求值与命中上限检查
  - 字段白名单 7 个：`type`（nodeType）/ `status` / `name`（`~` 忽略大小写）/ `group`（按 `groups[].memberNodeIds`
    反查组名，节点对象上没有组名字段）/ `model`（`modelKey` 优先，为空回退 `generationModel`）/
    `hasResult`（`mediaUrl` 非空，仅 `=` 且只接受 `true`/`false`）/ `editMode`；未知字段 → `MOLIAI_SELECTOR_INVALID`
  - `node delete` 支持三种互斥入口：位置参数 `<nodeId>`、`--where '<表达式>'`、`--ids a,b`（≤200，对齐 `connection delete`）；
    混用 → `MOLIAI_ARG_INVALID`
  - 新增 `--max-nodes <n>`（缺省 20，仅作用于 `--where`）：命中数超上限且无 `--yes` → `MOLIAI_CONFIRM_REQUIRED`
    （退出码 10），`details.candidateNodes` 列出前 N 个节点
  - 新增 `--dry-run`：展示将删除的节点（nodeId / 名称 / 类型），不提交删除、无需 `--yes`
  - `--where` 命中 0 个 → `MOLIAI_ARG_INVALID`（破坏性操作不静默成功）；`--ids` 中不存在的 id 只进 `warnings`
  - 输出结构改为 `{ dryRun, matched, deleted, deletionOperationId, nodes[], restoreHint }`：
    **后端一次请求只返回一个 `deletionOperationId`（无逐节点 opId）**，`nodes[]` 按 `deletedNodeIds` 回显，
    恢复按整批执行；`NODE_DELETE_OUTPUT_FIELDS` 同步登记
  - `errors.ts` 新增 `MOLIAI_SELECTOR_INVALID`（退出码 2）

- **`node list` 过滤 / 排序能力补齐**（全部客户端过滤，多个条件 AND）
  - 新增 `--status <idle|generating|completed|failed>`（后端 `VALID_NODE_STATUSES` 值域，其它取值本地拒绝，
    避免过滤条件静默命中 0 条）、`--group <groupRef>`（groupId 或组名，读 `groups[].memberNodeIds`；
    组名不唯一列出候选、组不存在报错）、`--has-result` / `--no-has-result`（`mediaUrl` 非空即「有产物」）、
    `--edit-mode <direct|ai>`、`--sort <name|type|status|x|y>`（单字段升序，空值排最后，同值按 `nodeId` 稳定排序）
  - `--limit` 语义明确为**排序后**截断；新增 `matched`（截断前命中数）便于判断是否被截断
  - 输出结构由 `{ nodes }` 扩展为 `{ nodes, total, matched, filters }`：`nodes` 字段未变（向后兼容），
    `total` 为过滤前总数，`filters` 回显本次实际生效的条件；`NODE_LIST_OUTPUT_FIELDS` 同步登记
- **`task cancel <taskId> --yes` 新增**（`DELETE /api/tasks/{taskId}`）
  - 只有 `queued` / `processing` 会被后端真正取消；对其它状态后端返回 200 + `cancelled=false`，
    CLI 把这种 no-op 显式当作失败（`MOLIAI_CONFLICT`，退出码 9），不把「没取消」当成功
  - 缺 `--yes` 以 `MOLIAI_CONFIRM_REQUIRED`（退出码 10）拒绝，`details` 含任务 id、当前状态、可取消性与退费说明
  - 取消后后端把任务置为 `failed` + `errorCode=TASK_CANCELLED`（不是 `cancelled` 状态），`currentStatus` 如实回传
  - **不退预扣费**：后端取消实现不做退费调用，故输出 `refunded: null`（后端不返回该信息，不伪造），`message` 说明原因
  - 输出 `{ taskId, previousStatus, currentStatus, cancelled, refunded, message }`，新增 `TASK_CANCEL_OUTPUT_FIELDS`

- **`node create` / `node update` 支持 `--super-resolution-type <image|video>`**
  - 此前 CLI 建出的 `super_resolution` 节点 `superResolutionType` 恒为 `null`，网页端 `resolveSuperResolutionType`
    在该字段为空时直接抛错（节点不可用），`connection create` / `derive` 也无法判定超分语义
  - `node create -t super_resolution` 现在**必须**指定 `--super-resolution-type`，缺失即 `MOLIAI_ARG_INVALID`
    （后端 `CanvasNodeCreateRequest`/`applyNodeFields` 无默认值，落 null 是确定性缺陷，不产出前端无法处理的节点）
  - 非 `super_resolution` 节点传该参数 → `MOLIAI_ARG_INVALID`（不静默忽略）；`node update` 会先按 nodeId
    读节点类型，节点不是超分时同样拒绝
  - `node create` / `node update` / `node list` / `canvas show` 输出新增 `superResolutionType`（非超分节点为 `null`），
    `NODE_CREATE_OUTPUT_FIELDS` / `NODE_UPDATE_OUTPUT_FIELDS` 同步登记
- **`derive` 预设图派生：`derive panorama` / `derive three-view` / `derive nine-grid` / `derive portrait-texture`**
  - 四个子命令共用一套实现（`src/commands/derive-preset.ts` 的配置表 + 单一执行体）：
    校验源节点 → 建目标节点（带预设字段）→ 建 `manual` 连线 → 可选 `--run` 提交生成 → 轮询
  - 源节点限 `image`，或 `super_resolution`（`superResolutionType=image`）；`mediaUrl` 非空；
    `status` 不能是 `uploading`/`generating`；`mediaUrl` 会作为 `referenceImages` 传给生成
  - `panorama`：target `nodeType=panorama_image`，节点预设 `modelParams={aspectRatio:"2:1",resolution:"4k"}` +
    `panoramaPreviewMode=false`，生成 `taskType=panorama_image`；模型限
    `tencent::gpt-image-2` / `openai::gpt-image-2` / `framefly::gpt-image-2`（与后端白名单一致，本地先拦）
  - `three-view` / `nine-grid` / `portrait-texture`：target `three_view` / `nine_grid` / `portrait_texture`，
    节点预设 `layoutPreset=画面版式:三视图` / `anglePreset=机位视角:九宫格` / `promptPreset=人景融合:...`，
    生成 `taskType=image`
  - 新增 `--set <key=value>` 透传生成参数（可重复，值按 JSON 解析）：`qwen-image-2.1` 等模型必须显式给
    `aspectRatio`，否则 worker 报 `UNSUPPORTED_IMAGE_SIZE`
  - `--dry-run --run` 的 `estimatedCost` 与真实扣费同口径：panorama 会把后端注入的 `aspectRatio=2:1`、
    `resolution=4K` 计入报价（不带这两项会低估，实测 3 vs 11）
  - 输出统一为 `scene` / `sourceNodeId` / `nodeId` / `nodeType` / `connectionId` / `canvasVersion` /
    `preset` / `run`，新增 `DERIVE_PRESET_OUTPUT_FIELDS` 并登记到 `OUTPUT_FIELDS_REGISTRY`
    （`derive panorama` / `derive three-view` / `derive nine-grid` / `derive portrait-texture` 四条路径）
  - **建节点与建连线都没有幂等键**（后端不支持）：重复执行会产生重复节点/重复连线，需手工清理；
    `--client-request-id` / `--operation-id` 只作用于 `/generate` 提交
  - 不写 `derivationType`（与网页端一致）；不使用派生事务端点，因此没有 `operationId` 语义

- **`derive` 命令组（第一批）：`derive list` / `derive depth-capture` / `derive video-continuation`**
  - `derive list`：列出 12 个派生场景与支持状态（`scenes[].supported` / `command` / `endpoint` / `note`），
    未支持场景给出原因与替代方案（多数可用 `moliai run` 间接实现）
  - `derive depth-capture <节点> [canvasId]`：`POST /canvases/{c}/derivations/depth-capture`，
    创建 `depth_capture` 节点 + derivation 连线；源节点限定 `video` / `super_resolution(video)` / `depth_capture`
    且 `mediaUrl` 非空；`--resolution` 只接受小写 `480p` / `720p`
  - `derive video-continuation <节点> [canvasId] --model <provider::modelId>`：
    `POST /canvases/{c}/video-continuations`，创建 `mediaUrl` 为空的 `video` 占位节点 + 专属 derivation 连线；
    `--from/--to`（秒，支持小数）或 `--from-ms/--to-ms`，内部转毫秒；源全长与选段均需 4–30 秒
  - 幂等键对外暴露为 `--operation-id <uuid>`（`--client-request-id` 为其别名；后端字段是 `operationId`，
    不是 `clientRequestId`），省略时自动生成；同键不同请求体 → 409 并在 hint 中说明换新键
  - 两个命令默认**只创建节点、不提交生成**；`--run` 才提交生成任务（`apiType=depth` / `video`，会扣费），
    提交前打印预估消耗并落作业记录（可用 `moliai wait` 接续）；`--dry-run` 零网络写入、零扣费
  - 新增 `DERIVE_LIST_OUTPUT_FIELDS` / `DERIVE_DEPTH_CAPTURE_OUTPUT_FIELDS` /
    `DERIVE_VIDEO_CONTINUATION_OUTPUT_FIELDS` 并登记到 `OUTPUT_FIELDS_REGISTRY`，命令内调用
    `assertOutputFields` 做字段漂移自检
  - `CONFLICT_HINTS` 补充 `DEPTH_CAPTURE_RESOLUTION_INVALID` / `DEPTH_CAPTURE_OPERATION_CONFLICT` /
    `DEPTH_CAPTURE_CONNECTION_MISSING` / `VIDEO_CONTINUATION_OPERATION_CONFLICT`
  - 视频续写创建前复用 `reference-media/prepare` 取 `sourceExpectations`（后端写事务强制要求恰好 1 条
    NODE 期望，缺则 409 `CANVAS_REFERENCE_RELATION_REQUIRED`）

- **成本上限 `--max-cost`（`run` / `group run`）+ 环境变量 `MOLIAI_MAX_COST`**
  - `run --max-cost <n>`：预估消耗超过上限 → `MOLIAI_BUDGET_EXCEEDED`（退出码 5），**提交前拒绝**，
    `details.estimatedCost` / `details.maxCost`；无法预估（`estimatedCost: null`）同样拒绝，
    `details.source: "estimate-unavailable"`（无法校验上限时不做静默放行）
  - `group run --max-cost <n>`：整组闸门在任何节点提交之前判定，超限则**整组零提交**，
    `details.nodes` 列出每节点明细；组内任一节点无法预估时 `totalEstimatedCost` 记为 `null`（不当 0），
    `warnings` 注明「N 个节点无法预估成本，上限校验不完整」；**全部**节点无法预估 → 整组拒绝执行
  - 预览与执行输出新增 `maxCost` / `withinBudget`（`totalEstimatedCost` 改为 `number | null`）
  - 优先级：`--max-cost` > `MOLIAI_MAX_COST` > 不设上限；非法取值（负数/非数字）报 `MOLIAI_ARG_INVALID`
  - `run --dry-run` 输出新增 `maxCost`，便于确认生效取值

- **`whoami` 输出真实余额 `balance`**：调 `GET /user/balance`，映射为
  `total`（后端 `balance`）/ `general`（`generalMagicBalance`）/ `membership`（`membershipMagicBalance`）/
  `frozen`（`frozenAmount`）/ `totalSpent`（`totalSpent`）。查询失败不阻断 whoami：`balance: null` + warning，
  绝不伪造数字。原有 `quota` 占位字段保持不变（向后兼容）

### 修复

- **`node update` 单节点模式此前拒绝 `--dry-run`**（报「只在 --where 批量模式有效」）：现在单节点也支持
  零写入预演（`--dry-run [--diff]`），`--max-nodes` / `--yes` 仍在单节点模式显式拒绝
- **`connection create` 的本地连线校验与网页端规则不一致（数据正确性修复）**：旧实现按 12 个后端
  `nodeType` 各自建矩阵，与网页端的 7 个逻辑类型（`CanvasNodeType`）不是同一套分类，导致 10 类误放
  （CLI 放行、网页端拒绝，会写出网页端不认的边）+ 1 类误拦（`text → panorama_image` 等 4 个预设图）。
  现改为：
  - 新增 `FRONTEND_TYPE_BY_BACKEND_NODE_TYPE` 映射（对齐 `canvasSerializer.ts`：
    `image`/`panorama_image`/`portrait_texture`/`three_view`/`nine_grid` → `image`，
    `video`/`depth_capture` → `video`），矩阵逐字抄前端 `ALLOWED_CONNECTIONS`
  - 修复误拦：`text → panorama_image` / `three_view` / `nine_grid` / `portrait_texture` 全部放行
  - 修复误放：`text → super_resolution`、`image → 视频超分`、`video → 图片超分`、`audio → 图片超分`、
    `图片超分 → video_synthesis`、`视频超分 → text`、`depth_capture → text`、
    `panorama_image → video_synthesis` 等组合现按网页端拒绝
  - 新增语义层（对应前端 `isValidCanvasDataConnection` 的 R8/R9/R10）：超分目标的源语义必须与
    `superResolutionType` 一致（`audio`/`voice` 只允许视频超分）、图片超分不能连入视频合成、
    图片超分只能连 `text`/`image`/`video`、视频超分只能连 `video`
  - 新增超分单上游校验（对齐 `validateSuperResolutionUpstreamConnection`）：已有其它上游时拒绝第二条
  - 新增视频续写目标的源限制：`video_synthesis` 与文本语义不能连入 `video_continuation` 节点
  - 派生节点判据从「只看 `derivationType`」扩展为前端 7 条（含 `depth_capture` 非生成历史、
    `text` + `text-extraction`、`video` + `synthesis-editor-export`）
  - `nodeType` 未知（无法映射到逻辑类型）时仍跳过矩阵与语义判定，不新增拒绝

- **`derive list` 的 `super-resolution` 提示承诺了 `run` 做不到的事**：note 写「可用 moliai run 在
  `super_resolution` 节点上间接实现」，但 `run` 对 `super_resolution` 直接抛 `MOLIAI_UNSUPPORTED`。
  现改为「暂未支持，可在网页端操作（moliai run 对 super_resolution 节点会直接报 MOLIAI_UNSUPPORTED）」；
  同时把 `nine-grid` / `panorama` / `three-view` / `portrait-texture` 的状态改为 `supported: true`
  并给出对应命令（原先 `panorama / three-view / portrait-texture` 合并在一条 `supported: false` 里）

- **派生/提取节点落点相互重叠**：此前 `derive` 只按「源 `posX` + 源宽 + 80」落点、`extract` 固定 `+380`
  且同批 N 个节点 x 相同，导致同一源节点连续派生两次坐标完全重合、一次提取的多个结果节点互相叠放。
  现统一为「源锚定 + 簇内递增」避让（新增 `src/commands/canvas-placement.ts`，尺寸兜底逻辑从 `group.ts` 迁入）：
  - 从源节点右边缘 +80 开始排第一列，同源节点在一列内自上而下（行间距 = 节点高 + 40），
    一列试满 20 行后右移一列（列间距 = 节点宽 + 40），簇宽度有界
  - 画布上所有已知坐标节点作为占据矩形参与避让；尺寸缺失按 `nodeSize` / `predictNodeSize` 兜底
    （`depth_capture` 等无实测宽高的类型取前端默认 360×200）
  - `extract` 批量创建时每个节点创建后**立即占用槽位**，同批节点不再互相覆盖
  - 显式给全 `--x/--y` 时**不做避让**（尊重用户指定，允许有意重叠）；
    只给其中一个时该轴固定，另一轴在其所在列/行内找空位
  - 源节点右侧 50 列 × 20 行全被占用时显式失败 `MOLIAI_ARG_INVALID`
    （hint 提示显式指定坐标），绝不静默叠上去

- **`derive ... --run` 的作业记录永远停留在 `queued`**：`--run` 提交后只写入初始 `status=queued` / `done=false` /
  `mediaUrl=null` 的记录，轮询结束（含完成、失败）不再回写，导致 `moliai jobs` 把已完成的派生任务显示为未完成、
  `moliai wait <jobId>` 读到过期状态。现与 `run` 同口径：状态变化与终态都回写 `status` / `done` /
  `lastCheckedAt` / `mediaUrl` / `errorCode` / `errorMessage`，未知状态标记 `unknown` 而非猜成 `queued`；
  失败错误的 `details` 增加 `errorCode` / `errorMessage`，并带上真实服务端 traceId

- **`derive ... --run --dry-run` 不报价**：此前 dry-run 分支直接返回，调用方无法在扣费前看到金额。
  现在传了 `--run` 的 dry-run 会调用 `/billing/estimate`（零成本、零写入）并输出 `estimatedCost`
  （`apiType=depth` 取 `--resolution`，`apiType=video` 取选段秒数）；预估失败时 `estimatedCost: null` 并附
  `ESTIMATE_UNAVAILABLE` 警告，不编造金额

- **真实提交的估价口径与 `--dry-run` 不一致**：此前真实提交用 CLI 构造的 `built.model` + `built.body.options`
  计价，而 dry-run 用 `prepared.resolvedModelKey` + `prepared.parameters`。后端按 **resolve 后的模型** 与
  **prepare 归一化后的参数** 计费，因此同一节点可能出现「预览价」与「提交价」两套数字（也影响 `--max-cost`
  的判定口径）。现两条路径统一为 `resolvedModelKey ?? built.model` + `prepared.parameters`

- **`storyboard` 命令组（第一批：读取 + 两种建组）**：分镜组（`groupType=STORYBOARD`）的读与建
  - `storyboard list` / `storyboard show`：读 `GET /canvases/{canvasId}` 的 `groups[]`（后端无独立列表端点），
    输出 `storyboard` 配置（`rows` / `columns` / `cellAspectRatio*` / `cellLongSide` / `cellGap` / `padding` /
    `showNumbers` / `exportResolution` / `layoutVersion` / `imageCount`）与全量槽位
    （`slots[].index` / `nodeId` / `hasImage` / `placeholder`，含空尾槽）
  - `storyboard create --from-nodes <nodeRef...>`：框选未编组图片节点建分镜组
    （`POST storyboard-groups/from-nodes`；请求体只有 `clientRequestId`/`expectedCanvasVersion`/`nodeIds`）
  - `storyboard create --from-group <groupRef> [--add-nodes <nodeRef...>]`：普通组**原位**转分镜组
    （`POST groups/{groupId}/convert-to-storyboard`；保留 groupId / 名称 / 背景色 / frameX / frameY）
  - `create --dry-run`：零改动预览（成员顺序、类型检查结果、自动布局推算的 rows/columns），不调写端点
  - 建组端点不接受名称/颜色：`--name` / `--color` 在建组成功后追加一次 `PATCH /groups/{groupId}`，
    并给出 `GROUP_LABEL_APPLIED_IN_SECOND_WRITE` 警告
  - 本地前置校验：两个 `--from-*` 互斥/必填、`--add-nodes` 仅配 `--from-group`、节点重复、
    成员 > 25、类型白名单（`details.unsupported` 列出全部不支持节点）、`uploading`/`generating`、
    已属分镜组 / 已属普通组、目标已是分镜组、目标组为空、合并后超员、`--color`/`--client-request-id` 格式
  - `group` / `group list` / `group show` / `group add-member` / `group remove-member` 输出补上
    `storyboard` 字段（`groupType=NORMAL` 时为 `null`），`MOLIAI_UNSUPPORTED` 文案改为指向 `moliai storyboard`

- **`storyboard` 命令组（第二批：三个破坏性清理操作）**：让 CLI 对分镜组「能建也能删」，全部必须 `--yes`
  - `storyboard dissolve <groupRef>`：解组（`DELETE /canvases/{c}/storyboard-groups/{g}`，**DELETE 带 body**
    `{ clientRequestId, expectedCanvasVersion }`）——软删组 + 删成员关系，节点/连线/来源行全部保留，
    输出 `detachedNodeCount` + `detachedNodeIds`（取后端 `result.affectedNodeIds`）
  - `storyboard clear <groupRef>`：清空成员（`POST /canvases/{c}/groups/{g}/storyboard/clear`）——
    成员节点与组外关联连线软删，组 / 配置 / 来源行保留（仍是 STORYBOARD 空组），
    输出 `removedNodeCount` + `removedNodeIds`（取后端 `result.deletedNodeIds`）
  - `storyboard to-normal <groupRef>`：转普通组（`POST /canvases/{c}/groups/{g}/convert-to-normal`）——
    `groupType → NORMAL`、9 个分镜配置列清空、成员 `slotIndex` 置 NULL，成员节点保留；输出 `groupId` + `memberCount`
  - 三者统一：缺 `--yes` → `MOLIAI_CONFIRM_REQUIRED`（退出码 10），`details` 列出组名/成员数/成员节点名称与类型
    以及具体后果；`--expected-version` 省略时自动取当前画布版本；`--client-request-id` 支持幂等重试
  - 本地校验：目标必须是 `STORYBOARD` 组（普通组指路 `moliai group delete`）、`clear` 空组直接拒绝
  - **`group delete` 对分镜组的拒绝改为 `MOLIAI_ARG_INVALID` + hint 指向 `moliai storyboard dissolve`**
    （此前是 `MOLIAI_UNSUPPORTED`，没有告诉用户该用什么）
  - 修复：`storyboard` 响应解析改为按操作类型给出报错文案（`分镜解组响应缺少 …`），并多读
    `result.deletedNodeIds` / `result.affectedNodeIds`

- **`storyboard` 命令组（第三批：配置更新 + 拼接输入快照）**：补上「改配置」与「拼接前读基线」
  - `storyboard config <groupRef>`：`PATCH /canvases/{c}/groups/{g}/storyboard`，支持
    `--rows/--columns`（成对，`1..5`，`rows*columns >= 2`）、`--ratio 16:9` 或分离写法
    `--ratio-width/--ratio-height`（二选一）、`--show-numbers/--no-show-numbers`、`--export 2K|4K`、
    `--bg #RRGGBB`、`--move-to x,y`（组框新原点，全部成员同位移；后端禁止单独缩放组框）
  - **缩容脱组语义完整呈现**：容量小于成员数时后端按旧 `slotIndex` 升序保留前 `capacity` 个、
    其余原子脱组（不删节点/不丢图/保留来源行与连线）。`--dry-run` 明确打印
    `当前 N 个成员 → 新容量 M → 后 (N-M) 个会脱为普通节点` 并列出节点名；真跑不需要 `--yes`，
    但 `warnings` 同样写明脱组名单，`detachedNodeIds` 取后端 `result.detachedNodeIds`
  - `config` 本地校验 12 条：非分镜组、行列单给、越界、`1×1`（按**变更后的最终配置**判定，
    只改背景色也会复核当前网格）、比例格式/越界/成对/二选一、`--export` choices、`--bg` 格式、
    `--move-to` 格式、无任何配置项、`--client-request-id` 格式
  - `storyboard stitch-inputs <groupRef>`：`GET .../storyboard/stitch-inputs`（**只读，不推进画布版本**）——
    `inputs` 只含**有图成员**（按真实 `slotIndex` 升序、不重新编号；零有图成员时为空列表而不是错误），
    `config` 是冻结配置（可回传给 `stitches` 的 `inputSnapshot.config`），`slots` 是全容量槽位；
    `--out <path>` 把原始响应 JSON 落盘
  - `core/http.ts`：`CONFLICT_HINTS` 增补 `CANVAS_STORYBOARD_PLACEMENT_FAILED`（422，整笔回滚）与
    `CANVAS_STORYBOARD_INVALID_REQUEST`（400，如 1×1），并让 400 / 非 409 分支也按 `serverCode`
    命中已登记提示（此前 422 的既有提示永远取不到）

- **`storyboard` 命令组（第四批：成员操作 + 整组复制）**：补上 4-B 最后一批端点
  - `storyboard add-node <groupRef> <nodeRef...> --slot <n>`：已有图片节点入组
    （`POST .../storyboard/members`）。不复制节点、不写来源行、不建来源线，节点媒体/配置/已有连线全部保留；
    满组**自动扩容**（优先加行，行满加列，5×5 才 409 `CANVAS_STORYBOARD_GROUP_FULL`）
  - `storyboard fill <groupRef> --slot <n> -f <path>`：上传本地图片补到槽位
    （`POST .../storyboard/slot-images`，`source={kind:"UPLOAD_KEY", storageKey}`）。复用 `upload` 的
    四段式分片上传链路（已抽为 `uploadMediaFile()`）；服务端**新建**成员节点；满组**不扩容**
    （唯一「满组即拒」端点）。`--dry-run` 只本地校验并展示插入位置，**不上传、不调用后端**
  - `storyboard move <groupRef> <nodeRef> --from <n> --to <m>`：组内换位（`mode=WITHIN`）。
    **插入不是交换**：摘出后插到 `min(to, 剩余长度)`，其余顺延；no-op 判据是归一后位置等于当前槽位
    （输出 `changed=false`，画布版本不推进）
  - `storyboard detach <groupRef> <nodeRef> --from <n> --x <n> --y <n>`：拖出组（`mode=DETACH`）——
    删成员关系、节点移到指定坐标、**节点与连线保留**、后续槽位顺延压实
  - `storyboard transfer <groupRef> <nodeRef> --from <n> --to-group <ref> --slot <m>`：跨组迁移
    （`mode=TRANSFER`）——删旧行 + 建新行、两侧各自重排；目标组满时自动扩容一格（5×5 才 409 且来源组零变更）。
    输出 `targetGroupId` 取后端 `result.groupId`（**是目标组**），并给出两侧写后成员顺序
  - `storyboard duplicate <groupRef> --offset-x <n> --offset-y <n> [--connections none|all] --yes`：
    整组复制（`POST .../storyboard-duplications`）。`connectionMode` 后端必填无默认，CLI 默认 `none`；
    **`result.nodeIdMap` 方向是「新节点 ID → 源节点 ID」**（与普通组复制相反），CLI 写后自校验
    键 ∈ `createdNodeIds`、值 ∈ 源组成员，方向不符直接报协议错误
  - 多节点 `add-node`：后端单次只收一个 `nodeId`，CLI 逐个提交且**每个节点独立 `clientRequestId`**、
    每次提交前**重新读取画布版本**；多节点时 `--client-request-id` / `--expected-version` 直接被拒绝
    （只对单节点有意义）；节点依次落到 `--slot, --slot+1, …` 避免同位置插入导致顺序倒置；
    中途失败时报 `details.completed` 列出已成功节点（后端不回滚已完成部分）
  - 本地 16 条前置校验：组不存在/歧义、非分镜组、节点不在组内（列出实际 slotIndex）、
    `--from` 与实际槽位不符（直接报真实槽位）、目标槽位越界/负数、已是本组成员、已属其他编组、
    类型白名单、`uploading`/`generating`、文件不存在/非图片后缀/0 字节、`transfer` 目标非分镜组或同组、
    `duplicate` 缺 `--yes`（退出码 10）、`--connections` 非法值、`--client-request-id` 非 UUID
  - 新增输出字段清单 `STORYBOARD_ADD_NODE/FILL/MOVE/DETACH/TRANSFER/DUPLICATE_OUTPUT_FIELDS` 并登记
    到 `OUTPUT_FIELDS_REGISTRY`
  - `core/http.ts`：`CONFLICT_HINTS` 增补 `CANVAS_STORYBOARD_ALREADY_MEMBER` /
    `CANVAS_STORYBOARD_SLOT_CHANGED` / `CANVAS_STORYBOARD_GROUP_FULL`
  - 结构：`storyboard.ts` 的定位/准入/响应解析下沉到新模块 `storyboard-common.ts`
    （`storyboard.ts` 与 `storyboard-members.ts` 共用同一套口径），避免两套校验文案漂移
  - **已知限制（2026-11-19 实测）**：`fill` 复用的 `upload-multipart` 登记到 `media_objects` 的记录
    `sha256` 为空（`MediaObjectPersistenceService.persist` 从不写 sha256），而分镜资源解析
    （`CanvasStoryboardResourceResolver.toIdentity`）要求 sha256 非空，因此 `slot-images` 会返回
    422 `CANVAS_STORYBOARD_RESOURCE_INVALID`。CLI 请求体与契约一致（`kind=UPLOAD_KEY` + 画布绑定 key），
    需后端补齐 sha256（或放宽 UPLOAD_KEY 的身份校验）后 `fill` 才能真正写入

- **`doctor` 补齐连接环境检查（4 项 → 8 项）**：从「纯本机自检」扩展到「本机 + 连接环境能否用」
  - 新增 `gateway-reachable`：`GET /user/profile` 探测，输出 HTTP 状态与延迟；401/403 判 `warn`，
    其它异常状态/网络错误判 `fail` 并区分超时 / DNS / TLS / 连接被拒
  - 新增 `token-validity`：本地读凭据判断有无 token、是否过期、剩余有效期、`authChannel` 与来源；
    **不自动续期**，过期与未登录均判 `fail`
  - 新增 `canvas-access`：`GET /canvases/{id}` 只读判断存在性与可写性；404 判 `fail`，
    `readOnly=true` / `canvasPurpose=subject` 判 `warn`；**不创建任何探测节点**（画布内容体检仍归 `diagnose`）
  - 新增 `models-available`：`GET /user/models` 输出模型总数与各模态分布；顺带统计 `/cli/models`
    中 `schemaAvailable=true` 的模型数（`run` 的参数校验依赖它）
  - 新增 `--offline`：只跑原有 4 项本机检查，离线环境可用
  - 联网检查并行发起、单项 3 秒超时，整条命令 < 1 秒；输出结构（`checks[]` / `summary` / `healthy`）
    与原有 4 项名称保持不变
  - JWT 解码新增 `authChannel` 字段（`whoami` 等既有调用不受影响）

- **`group run <groupRef>`**：整组成员按顺序批量执行（预览 → 提交 → 轮询 → 汇总）
  - **默认只预览、零扣费**，`--execute` 才真正提交（与 `run` 相反；`run` 默认真跑、`--dry-run` 才预览）
  - **连线推导默认开启**：按网页端语义取「全图所有指向本节点的上游」写进提交体 `contextNodeIds`
    （后端不读画布连线表）；`editMode=direct` 的文本上游与 `derivationType != null` 的派生上游跳过并告警，
    组外上游保留；`--no-from-connections` 关闭（关闭后提交体不带 `contextNodeIds`）
  - 三种顺序策略：`--order position`（默认，posY→posX 行优先，同坐标按成员原序）、
    `member`、`topological`（只收两端都在组内的连线，Kahn 稳定排序，有环报错并给出环路径，不降级）
  - `STORYBOARD` 组自动强制 `member` 顺序（成员已按 slotIndex 升序），输出 `orderStrategyApplied` 标注
  - **提交节流 6 秒/次**（网关限流 10 次提交/分钟）：预览给出 `estimatedSubmitMinutes`，
    20 个节点约 2 分钟；`--concurrency > 1` 时提交仍由同一闸门串行
  - `--concurrency <n>`（1..10）与连线推导**互斥**：并发时上游产物未就绪，下游会拿到旧数据，
    冲突直接 `MOLIAI_ARG_INVALID` 并提示二选一
  - `--rerun-failed` 只跑失败的成员（远端 `status=failed` 或本地失败作业记录，详见下方「修复」）；
    `status=generating` 一律跳过；默认跑所有未完成成员
  - `--continue-on-error` 失败继续；默认首个失败即停，错误 `details` 带已完成/失败/跳过清单
  - `--client-request-id <uuid>` 是**前缀语义**：每节点用 `<prefix>-<序号>`，避免整组共用一个被后端幂等去重
  - 复用 `executeNodeRun`（一次调用跑一个节点）；每节点结束后重拉画布详情，保证下游拿到上游新产物
  - 本地前置校验：组不存在/名称歧义、成员为空、成员节点缺失、节点类型不在 run 白名单
    （`audio`/`voice`/`super_resolution`/`depth_capture` → `MOLIAI_UNSUPPORTED`，列出全部）、
    坐标缺失（`MOLIAI_INTERNAL_ERROR`）、任一节点构建失败（列出全部问题节点，整组不提交）
  - 新增输出字段清单 `GROUP_RUN_PREVIEW_OUTPUT_FIELDS` / `GROUP_RUN_EXECUTE_OUTPUT_FIELDS`，
    登记在 `OUTPUT_FIELDS_REGISTRY` 的 `group run`
- **`help --json` / `schema` 现在包含子命令**：反射改为展平命令树，命令名用完整键路径
  （如 `group run`、`canvas list`），顶层命令条目结构不变；`moliai schema "group run"` 可用
- **`group` 命令组**：画布编组（分组）的查询与 CRUD（不含 `group run`，见上方条目）
  - `group list` / `group show`：编组来自 `GET /canvases/{canvasId}` 的 `groups[]`（后端无独立列表端点）；
    `show` 支持 groupId 或**组名**，组名不唯一时显式报错并列出候选
  - `group create <nodeRefs...>`：成员 ≥ 2，frame 默认按「包围盒 + 28px」自动计算
    （padding 与网页端 `CANVAS_GROUP_FRAME_PADDING` 一致；节点宽高缺失按网页端兜底尺寸：
    text 300×209 / 无媒体图 360×200 / 有媒体 `calcNodeDimensions` / audio 320×144 或 300×171 /
    voice 320×76 或 320×170）；`--x/--y/--width/--height` 四项独立覆盖
  - `group update`：名称 / 颜色 / 编组框；`--clear-name` 走「显式传 null」清空名称
  - `group delete`：**默认只解组**（`DELETE groups/{id}`，版本走 query，成员节点保留）；
    `--with-members` 整组删（`POST group-deletions`，组 + 成员节点 + 关联连线，24h 可恢复）
  - `group add-member` / `group remove-member`：逐节点调用成员端点；移除走**带 body 的 DELETE**
    （`{ expectedCanvasVersion }`），节点本身保留在画布
  - `group merge`：合并 ≥2 个普通编组，`additionalNodeIds` 固定传 `[]`（后端 `@NotNull`），
    frame 按所有源组成员包围盒重算；合并接口无 `name` 字段，`--name` 会在成功后追加一次 PATCH 并告警
  - `group restore <restoreOperationId>`：24 小时内恢复整组删
  - 本地兜住 10 条规则：成员 < 2、节点 `uploading`/`generating`、节点已属其他组、节点属分镜组、
    颜色非 `#RRGGBB`、名称空/超 191、宽高 ≤ 0、分镜组写操作、合并源组 < 2、破坏性操作缺 `--yes`
  - 分镜组（`groupType=STORYBOARD`）写操作本地前置拒绝 `MOLIAI_UNSUPPORTED`；
    仅 `group update` 改名称/颜色放行（与后端一致）
- **`connection` 命令组**：连线创建 / 列出 / 更新 / 删除 / 恢复
  - `connection create <sourceRef> <targetRef>`：起点/终点支持 nodeId 或节点名称；`--label` / `--style` /
    `--color` / `--arrow` / `--no-arrow` / `--expected-version`；后端同 source+target+type 幂等，
    输出 `duplicate: true` 表示命中既有边（不推进画布版本）
  - `connection list`：`--source` / `--target`（nodeId 或节点名）/ `--type manual|derivation`
  - `connection update`：改 label / style / color / arrow，不涉及端点与类型
  - `connection delete`：单条走 `DELETE`（**非幂等**，普通边无恢复入口，输出 `deletionOperationId: null` 并附警告）；
    批量走 `connection-deletions`（幂等，`--client-request-id` 省略时自动生成 UUID v4，24 小时内可恢复）
  - `connection restore <deletionOperationId>`：恢复批量删除的连线，超期 410
  - 本地兜住后端不拦的规则：自环、节点 `uploading`/`generating`、网页端类型矩阵、voice 入线、
    `editMode=direct` 文本入线、派生节点入线、audio 双向特例、全图环检测（DFS 从 target 找回路）
  - `toConnectionView` 补齐 `style` / `color` / `arrow`，`connection list` 与 `canvas show` 同步受益
- **`extract` 命令**：从 text 节点正文提取角色 / 场景 / 物品（`--kind character|scene|item` 必填），
  把结果落成画布节点并连线，对齐网页端行为
  - 零成本预演 `--dry-run`（只走 prepare）；`--no-apply` 只输出结果不建节点（仍清理任务）
  - 结果节点：`提取角色/场景/物品-<名称>`、`sourceAssetType=text-extraction`、`derivedFromNodeId=源节点`、
    `origin=ai_generated`，位置在源节点右侧 380px、按 245px 纵向错开；连线 `manual` + `arrow=false`
  - 模型选择链：`--model` > 源节点 `modelKey` > `/user/models` 的 `llm[0]`（推断时给 `MODEL_INFERRED` 警告）
  - `--prompt` 作为附加要求传给后端（不传则为空，内容全部来自源节点正文）
  - 落地幂等：按 `taskId + sourceAssetType + derivedFromNodeId` 判重，重复执行不重复建点
  - 计费口径 `canvas-text`；后端 `/billing/estimate` 白名单不含该值，`estimatedCost` 为 `null` 并附警告
- **多环境凭据管理**：`credentials.json` 升级为 v2，每个 `baseUrl` 独立保存一份令牌，另有一个默认环境
  - `moliai env` 列出已登录环境、默认环境与本机实际会用的环境（`current` 已计入 `--base-url` / `MOLIAI_BASE_URL` 覆盖）
  - `moliai env use <baseUrl>` 切换默认环境，**不需要重新登录**
  - `moliai env remove <baseUrl>` 删除单环境凭据；删的是默认环境时自动切到剩下的一个
  - 新增全局选项 `--base-url <url>`：本次调用临时换环境，优先级最高
  - `login key` / `login token` 输出新增 `environment` 字段，标明凭据写到了哪个环境；登录新环境不会覆盖其它环境

### 变更

- **批量命令的通知改为整批汇总（一条）**：`group run` / `run --where --execute` / `apply --run`
  不再逐节点通知（原来 20 个节点 = 20 条），改为**整批结束后发一条汇总**
  `[group run] 18 成功 / 2 失败（耗时 320 秒）`（有跳过时追加 `/ N 跳过`）。新增 `MOLIAI_BATCH_SCOPE` /
  `MOLIAI_BATCH_SUCCEEDED` / `MOLIAI_BATCH_FAILED` / `MOLIAI_BATCH_SKIPPED` / `MOLIAI_BATCH_ELAPSED_SECONDS` /
  `MOLIAI_BATCH_JOB_IDS` / `MOLIAI_BATCH_FAILED_NODES`（`nodeId:errorCode`，逗号分隔）环境变量；
  批量模式下 `MOLIAI_JOB_ID` / `MOLIAI_TASK_ID` / `MOLIAI_NODE_ID` / `MOLIAI_MEDIA_URL` **显式置为空串**
  （不是「不设置」：空串可稳定判断，也不会把 shell 遗留旧值误读成本次作业）。fail-fast 中断时同样先发
  汇总再抛错，通知自身失败写 `BATCH_NOTIFY_FAILED` 警告（中断场景附在错误 `details.notifyWarnings`）。
  单节点 `run <node>` / `wait` 的通知行为不变
- **`node create` 支持 `--content`**：可在创建 text 节点时直接写入正文（原样提交，不 trim），
  避免「先建节点再 `node update --content`」两步操作
- **`node create` / `node update` 支持 `--edit-mode direct|ai`**：`direct`（后端默认）的文本节点
  **不接受上游连线**，此前 CLI 无法设置 `editMode`，「建 text 节点 → 连上游」这条路走不通；
  现在可在创建时直接 `--edit-mode ai`，或对已有节点 `node update <id> --edit-mode ai` 后立即生效
- **`node create` / `node update` 补齐其余可直接设置的节点字段**：
  `--fit-mode cover|contain|fill`（媒体填充模式）、`--prompt-preset` / `--layout-preset` /
  `--angle-preset`（生图预设，各 ≤512 字符，原样提交）、`--auto-link` / `--no-auto-link`
  （关键词自动链接开关，未传则不改动当前值）
- `node create` / `node update` 输出新增 `editMode` 字段；`node list` / `canvas show` 的节点视图
  同步补 `editMode`，便于连线前确认目标节点是否会拒绝上游入线
- 故意未暴露的 DTO 字段：`derivationType` / `taskId` / `status` / `origin`（系统内部维护）、
  `mediaUrl` / `mediaId`（已由 `--media-url` + `--media-id` 覆盖）、`modelKey` / `modelParams` /
  `generationPrompt`（属生成参数，走 `run` 命令；`node update` 明确「不含生成参数」）、
  `synthesis` / `sourceNodeIds`（由派生/提取链路维护）、`expectedCanvasVersion`（并发基线，非用户设置项）
- 环境解析优先级统一为：`--base-url` > `MOLIAI_BASE_URL` > `credentials.json` 的 `defaultEnvironment` > `MOLIAI_NOT_BOUND`
- `credentials.json` v1（顶层平铺 `baseUrl` + `token`）读取时自动迁移为 v2 并写回，`--verbose` 下打印迁移日志
- 当前环境没有凭据时报 `MOLIAI_NOT_BOUND`（退出码 2），hint 直接给出该环境的登录命令；不再触发 `MOLIAI_BASE_URL_MISMATCH`（该错误码保留在错误码表中，但已无触发路径）
- 完全未绑定任何环境时，原先的 `MOLIAI_AUTH_REQUIRED` 改为 `MOLIAI_NOT_BOUND`（缺少的是地址，不是凭据）
- `logout` 删除全部环境的凭据（语义不变，文档已明确）
- **文档补充视频续写的模型前置条件**：`derive video-continuation` 的创建端点依赖后端
  `capabilities.video.referenceLimits`（未命中再看路由组组级配置）。test 环境
  `wetoken::bytedance-seedance-2-0-260128` 只有定价、缺该配置，`--run` 会在创建阶段返回
  `500 SEEDANCE_REFERENCE_PROFILE_UNAVAILABLE`（不建节点、不扣费）；`--dry-run --run` 的
  `estimatedCost` 只读定价表，不代表创建能通过。README「已知限制」与测试交付说明同步记录

### 修复

- **`group run --rerun-failed` 现在能覆盖 prepare 阶段失败的节点**：这类失败（如 400
  `REFERENCE_MEDIA_UNAVAILABLE`）不会让后端节点变成 `failed`（远端仍是 `idle`），也不会返回 taskId，
  此前 `--rerun-failed` 永远匹配不上，用户只能全量重跑（把已完成节点重复扣费）。
  - 现在成员筛选同时参考**远端节点状态**与**本地作业记录**：远端 `failed` 或本地有该节点的
    `status=failed` 作业 → 重跑；远端 `completed` 且有 `mediaUrl` → 跳过（避免重复扣费）
  - `group run` 会把「提交/准备阶段失败」落盘为 `status=failed`、`taskId=null`、`failureStage=prepare|generate`
    的作业记录，只记录拿到了后端响应的失败（网络/本地错误不落盘，避免污染判定；`run` 单节点不写这类记录）
  - 新增 `skipped[].reason`（`already-completed` / `already-generating` / `not-failed`）与
    `skipped[].reasonDetail`；换机器（本地无作业记录）时在 `warnings` 里明确说明无法识别
  - `jobs show` 对这类无 taskId 的记录给出 `SUBMIT_FAILED` 警告；`wait` 直接报 `MOLIAI_TASK_FAILED`
- **409 不再映射为 `MOLIAI_INTERNAL_ERROR`**：新增错误码 `MOLIAI_CONFLICT`（退出码 **9**），
  hint 按 `serverCode` 细分（`CANVAS_VERSION_CONFLICT` / `CANVAS_NODE_ALREADY_GROUPED` /
  `CANVAS_STORYBOARD_GROUP_TYPE_CONFLICT` / `CANVAS_REFERENCE_RELATION_REQUIRED`），
  未登记的 serverCode 保留原文 + 「状态冲突，可能需重新读取最新数据后重试」。
  409 都是用户可自行修正的场景，不再提示「附 traceId 反馈」
- **错误信封固定带 traceId**：新增 `traceIdSource`（`server` / `local`），`traceId` 允许为 `null`
  但字段必存在；HTTP 错误取值回退到 `X-Trace-Id` / `X-Request-Id` 响应头（含 204 空响应），
  业务错误用最后一次轮询的 traceId；网络/本地错误如实为 `null`（**不伪造**）。
  stderr 追加一行可复制的「错误 traceId: …（可用于反馈或查询服务端日志）」/「本地错误，无服务端 traceId」。
  `--trace-id` 只影响成功信封
- **幂等重放不再写重复作业记录**：同一 `clientRequestId` 拿回同一 taskId 时就地刷新已有记录
  （`jobs` 里同一 taskId 只保留一条），此前会新建第二条
- **`group run` 查询节流**：`generations/prepare` 与 `billing/estimate` 走 500ms 间隔闸门（2 次/秒，
  网关查询限流 120 次/分钟）；`run` 单节点不经过该闸门，行为零变化

## [0.1.0] - 2026-11-18

首个公开版本。`moliai` 从一个内部验证原型转为可分发的命令行客户端：把 MoliAi 魔力画布的核心操作搬到终端，让脚本与 AI Agent 能在一条命令里完成「找画布 → 建节点 → 传素材 → 提交生成 → 下载产物」的闭环。

主要能力：

- **认证**：`login key` 用网页「开发者配置」里的 KEY 换令牌（KEY 只从 stdin 读、不落盘），`login token` 作为备用路径；凭据保存在 `~/.moliai/credentials.json`，令牌与登录地址绑定
- **身份与自检**：`whoami`、`status`、`doctor`、`help` / `schema`（结构化命令树与单命令参数契约）
- **项目与画布**：`project list`；`canvas list/show/create/use/unuse`，支持把画布绑定到当前目录，后续命令可省略画布参数
- **节点**：`node list/create/update/delete`，删除走幂等信封且 24 小时内可恢复
- **模型**：`model list/search/<modelKey>`，可直接查询参数契约，避免盲试参数
- **生成**：`run` 支持图片与视频节点，提交前自动做参数校验（有契约走服务端严格校验，无契约走本地能力校验），`--dry-run` 零成本预演并给出 `estimatedCost`；参考素材走两阶段准备并自动补提示词引用
- **素材**：`upload` 分片上传本地媒体；`download` 从 CDN 直链下载节点产物或任务产物，带完整性校验
- **任务与长任务**：`task list/get`；`run` 提交成功即落盘作业记录，`jobs` / `jobs show` / `jobs prune` / `wait` 支持跨会话接续，进程被中断也不丢 taskId
- **成本安全**：`run` 是唯一扣费命令；成本算不出来时显式给出 `estimatedCost: null` 与原因，不当作免费
- **Agent 集成**：`moliai setup` 把 Skill 安装到 `~/.agents/skills` 与 `~/.claude/skills`，并附带 `INSTALL-FOR-AGENTS.md` 作为 Agent 侧安装手册

安装与使用见 [README.md](./README.md)，Agent 侧安装流程见 [INSTALL-FOR-AGENTS.md](./INSTALL-FOR-AGENTS.md)。
