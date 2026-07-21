# Codex CLI 软件开发中文教程

## 1. Codex CLI 是什么

Codex CLI 是运行在终端中的软件开发智能体。它不只是回答编程问题，还可以：

- 阅读和理解整个代码仓库
- 修改、新建和重构文件
- 执行测试、构建、格式化和 Git 命令
- 分析错误日志和定位故障
- 审查未提交代码、Commit 或分支差异
- 通过 `codex exec` 接入脚本和 CI
- 通过 `AGENTS.md` 长期遵守项目规范

官方入口：[Codex CLI 概览](https://learn.chatgpt.com/docs/codex/cli)

---

## 2. 安装 Codex CLI

### macOS / Linux：官方安装器

```bash
curl -fsSL https://chatgpt.com/codex/install.sh | sh
```

升级时可以再次运行同一条命令。

### 使用 npm

如果已经安装 Node.js：

```bash
npm install -g @openai/codex
```

### macOS 使用 Homebrew

```bash
brew install --cask codex
```

安装后检查：

```bash
codex --version
codex --help
```

Windows 用户可以使用原生 Windows 版本；如果开发环境本身位于 Linux，使用 WSL 通常更方便。

---

## 3. 登录

最简单的方法是运行：

```bash
codex login
```

浏览器会打开 ChatGPT 登录页面。也可以直接在项目目录执行 `codex`，首次运行时按提示登录。

检查登录状态：

```bash
codex login status
```

退出登录：

```bash
codex logout
```

Codex 支持两种主要认证方式：

- ChatGPT 登录：使用 ChatGPT 套餐中的 Codex 权益
- API Key：按 OpenAI API 用量计费

通过 API Key 登录时，不要直接把密钥写入命令历史。可通过标准输入传入：

```bash
printenv OPENAI_API_KEY | codex login --with-api-key
```

认证说明见：[官方认证文档](https://learn.chatgpt.com/docs/auth#codex-cli)

---

## 4. 第一次启动

进入一个 Git 项目：

```bash
cd ~/projects/my-app
git status
codex
```

然后直接用中文输入任务：

```text
请先阅读这个项目，不要修改代码。告诉我：

1. 项目使用了哪些技术
2. 程序从哪里启动
3. 主要目录分别负责什么
4. 如何安装依赖和运行测试
5. 目前可能存在的风险
```

Codex 会读取项目文件并回答。输入 `?` 可以查看终端快捷键，输入 `/` 可以查看所有斜杠命令。

官方建议在任务前后建立 Git 检查点，方便审查和回滚：

```bash
git status
git add .
git commit -m "checkpoint before codex task"
```

---

## 5. 最重要的斜杠命令

| 命令 | 用途 |
|---|---|
| `/init` | 为当前项目生成 `AGENTS.md` |
| `/status` | 查看目录、模型、权限和会话状态 |
| `/permissions` | 设置 Codex 可以执行哪些操作 |
| `/model` | 选择模型和推理强度 |
| `/review` | 审查当前代码变更 |
| `/plan` | 先制定实施计划 |
| `/compact` | 压缩较长的会话上下文 |
| `/diff` | 查看 Codex 造成的代码变化 |
| `/mcp` | 查看外部工具连接 |
| `/exit` | 退出 CLI |

此外：

- 输入 `@` 可以搜索并引用项目文件。
- 输入 `!命令` 可以执行本地命令，例如 `!git status`。
- Codex 工作时按 `Enter` 可以补充当前任务的指令。
- 按 `Tab` 可以排队下一条任务。
- `Ctrl+C` 可以中断当前操作。

完整列表见：[Codex CLI 命令参考](https://learn.chatgpt.com/docs/developer-commands?surface=cli)

---

## 6. 理解权限和沙箱

这是使用 Codex CLI 最重要的安全概念。

Codex 有两层控制：

- 沙箱：技术上允许它访问什么
- 审批策略：执行某些操作之前是否需要你确认

### 推荐的日常开发模式

```bash
codex \
  --sandbox workspace-write \
  --ask-for-approval on-request
```

这也是官方推荐的 Auto 模式：

- 可以读取项目
- 可以修改当前工作区
- 可以执行常规开发命令
- 访问工作区之外的文件或网络时需要审批

### 只读分析

```bash
codex \
  --sandbox read-only \
  --ask-for-approval on-request
```

适合代码审查、架构分析或者第一次接触陌生项目。

进入 Codex 后，也可以随时运行：

```text
/permissions
```

然后选择 `Auto` 或 `Read Only`。

### 不建议使用

```bash
codex --yolo
```

它等价于绕过审批和沙箱，只应在完全隔离、可以随时销毁的容器或虚拟机中使用。详见：[Agent 审批与安全](https://learn.chatgpt.com/docs/agent-approvals-security)

---

## 7. 使用 AGENTS.md 固化项目规则

在项目根目录运行：

```text
/init
```

Codex 会生成 `AGENTS.md`。你可以把它改成：

```markdown
# AGENTS.md

## 项目说明

这是一个 TypeScript 后端项目，使用 Node.js、PostgreSQL 和 Vitest。

## 开发要求

- 修改前先阅读相关代码和测试。
- 保持现有架构，不随意引入新的框架。
- 使用 pnpm，不使用 npm 或 yarn。
- 修改 TypeScript 后运行 `pnpm lint`。
- 完成任务后运行 `pnpm test`。
- 不得修改生产环境密钥或部署配置。
- 添加生产依赖前必须先说明理由。
- 最终报告列出修改文件、测试结果和剩余风险。

## 编码规范

- 新增公共函数必须有类型定义。
- 优先写小函数，避免超过 50 行。
- 错误信息必须包含必要的上下文。
- 修复 Bug 时应添加回归测试。
```

Codex 每次启动时都会读取这些规则。子目录也可以有自己的 `AGENTS.md` 或 `AGENTS.override.md`，越靠近当前目录的规则优先级越高。

详细机制见：[AGENTS.md 官方文档](https://learn.chatgpt.com/docs/agent-configuration/agents-md)

---

## 8. 一套可靠的日常开发流程

### 第一步：理解问题

```text
请分析登录接口偶尔返回 500 的问题。

先不要修改代码。请：
1. 找到请求入口和完整调用链
2. 检查相关日志、异常处理和数据库操作
3. 给出最可能的根因
4. 指出你的结论分别来自哪些文件
```

### 第二步：制定计划

```text
根据刚才的分析，提出一个最小修改方案。

要求：
- 不改变公开 API
- 不添加新依赖
- 包含回归测试
- 列出准备修改的文件
- 先等我确认，不要立即实施
```

### 第三步：实施

```text
按这个方案实施。完成后运行相关测试和类型检查。
如果测试失败，先定位原因；不要为了让测试通过而删除或弱化测试。
```

### 第四步：审查

```text
/review
```

也可以明确要求：

```text
审查刚才的修改，重点检查：

- 是否真正修复根因
- 是否引入并发或事务问题
- 错误处理是否完整
- 测试是否能在修复前失败、修复后通过
- 是否存在不必要的改动
```

### 第五步：人工检查

退出 Codex 后检查：

```bash
git status
git diff
```

确认无误后再提交：

```bash
git add .
git commit -m "fix: handle login transaction failure"
```

---

## 9. 如何写好任务提示

推荐使用下面的结构：

```text
目标：
修复用户资料页面首次加载时重复请求的问题。

范围：
只修改 frontend/profile 目录。

约束：
- 不添加新依赖
- 不改变后端 API
- 保持现有组件接口
- 遵循 AGENTS.md

验收标准：
- 首次加载只发送一次请求
- 切换用户时仍能重新加载
- 添加回归测试
- npm test 和 npm run lint 通过

工作方式：
先定位根因并解释，再实施最小修改。
完成后总结修改内容、验证结果和剩余风险。
```

关键原则是：提供目标、范围、约束、验收标准和验证方式，而不是只说“帮我修一下”。

---

## 10. 恢复之前的会话

查看并恢复当前项目最近的会话：

```bash
codex resume
```

恢复最近一次：

```bash
codex resume --last
```

你可以继续说：

```text
继续上次的登录故障修复。先检查工作区现状和测试结果，然后完成剩余工作。
```

---

## 11. 非交互模式：codex exec

`codex exec` 适合脚本、自动分析和 CI：

```bash
codex exec "总结这个仓库的目录结构和主要风险"
```

默认使用只读沙箱。允许修改工作区：

```bash
codex exec \
  --sandbox workspace-write \
  "修复失败的单元测试，完成后运行测试"
```

输出 JSON Lines：

```bash
codex exec --json "分析仓库结构"
```

不保存这次会话：

```bash
codex exec --ephemeral "检查是否存在明显的安全问题"
```

继续上一次非交互任务：

```bash
codex exec resume --last "修复你发现的问题"
```

官方说明：[codex exec 非交互模式](https://learn.chatgpt.com/docs/non-interactive-mode)

---

## 12. 推荐配置

个人配置文件位于：

```text
~/.codex/config.toml
```

适合初学者的保守配置：

```toml
approval_policy = "on-request"
sandbox_mode = "workspace-write"
web_search = "cached"

# 推荐把登录凭据保存在操作系统凭据库中
cli_auth_credentials_store = "keyring"
```

项目也可以包含：

```text
项目根目录/.codex/config.toml
```

配置优先级大致是：

1. 命令行参数
2. 项目 `.codex/config.toml`
3. 选中的 Profile
4. 用户 `~/.codex/config.toml`
5. 系统配置
6. 内置默认值

完整说明见：[Codex 配置基础](https://learn.chatgpt.com/docs/config-file/config-basic)

---

## 13. 初学者练习路线

建议依次完成下面五个练习：

1. 让 Codex 解释一个现有小项目，不允许修改文件。
2. 用 `/init` 创建 `AGENTS.md`。
3. 让 Codex添加一个小功能，并要求同时添加测试。
4. 人为制造一个测试失败，让 Codex先诊断、再修复。
5. 使用 `/review` 审查未提交修改。

当你能够稳定完成这五步，就已经掌握了 Codex CLI 最重要的开发循环：

```text
理解项目 → 定义任务 → 制定计划 → 修改代码 → 运行验证 → 审查差异 → Git 提交
```

最值得收藏的三个官方入口：

- [Codex CLI 快速入门](https://learn.chatgpt.com/docs/codex/cli)
- [CLI 完整命令参考](https://learn.chatgpt.com/docs/developer-commands?surface=cli)
- [审批、沙箱与安全](https://learn.chatgpt.com/docs/agent-approvals-security)
