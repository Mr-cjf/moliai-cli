# 更新日志

本文件记录 MoliAi CLI 的版本变更。格式参考 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)，版本号遵循语义化版本。

## [Unreleased]

### 新增

- **多环境凭据管理**：`credentials.json` 升级为 v2，每个 `baseUrl` 独立保存一份令牌，另有一个默认环境
  - `moliai env` 列出已登录环境、默认环境与本机实际会用的环境（`current` 已计入 `--base-url` / `MOLIAI_BASE_URL` 覆盖）
  - `moliai env use <baseUrl>` 切换默认环境，**不需要重新登录**
  - `moliai env remove <baseUrl>` 删除单环境凭据；删的是默认环境时自动切到剩下的一个
  - 新增全局选项 `--base-url <url>`：本次调用临时换环境，优先级最高
  - `login key` / `login token` 输出新增 `environment` 字段，标明凭据写到了哪个环境；登录新环境不会覆盖其它环境

### 变更

- 环境解析优先级统一为：`--base-url` > `MOLIAI_BASE_URL` > `credentials.json` 的 `defaultEnvironment` > `MOLIAI_NOT_BOUND`
- `credentials.json` v1（顶层平铺 `baseUrl` + `token`）读取时自动迁移为 v2 并写回，`--verbose` 下打印迁移日志
- 当前环境没有凭据时报 `MOLIAI_NOT_BOUND`（退出码 2），hint 直接给出该环境的登录命令；不再触发 `MOLIAI_BASE_URL_MISMATCH`（该错误码保留在错误码表中，但已无触发路径）
- 完全未绑定任何环境时，原先的 `MOLIAI_AUTH_REQUIRED` 改为 `MOLIAI_NOT_BOUND`（缺少的是地址，不是凭据）
- `logout` 删除全部环境的凭据（语义不变，文档已明确）

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
