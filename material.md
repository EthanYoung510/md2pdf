# md2pdf 技术培训材料

本材料解释项目使用的技术体系，而不是复制命令帮助。产品规格见 `SPEC.md`，项目用法和架构见 `README.md`，AI 迭代规则见 `prompt.md`。

## 1. 为什么不用目录管理版本

在 Git 仓库中，用 `history/`、`current/`、`pending/` 目录表达版本通常弊大于利。Git 已经用 commit、branch、tag 和 PR 解决历史、当前和待审批问题。目录复制会让同一文件出现多份副本，AI 和人都会不确定应该改哪一份，也会让构建入口、文档和测试范围变复杂。

更好的做法是：根目录永远表示当前版本；历史通过 Git 查询；候选修改通过分支和 PR 审批；重大架构决策写 ADR 或 issue。

## 2. Docker 与离线运行

Docker 镜像把操作系统包、字体、浏览器、Node 工具、TeX 发行版和转换脚本封装为同一运行环境。离线运行的核心原则是：构建阶段可以下载依赖，运行阶段不得下载依赖。这样可以让转换行为可复现，并减少运行时供应链风险。

本项目 v1.2.1 默认镜像基于 `debian:trixie-slim`，预装 Pandoc、XeLaTeX、中文 TeX、Noto CJK 字体、TeX 推荐字体、Chromium 与固定版本 Mermaid CLI。宿主机脚本用 `--network none` 禁止运行时网络访问，用 `--read-only` 限制根文件系统写入，并仅开放受限 `tmpfs` 和输出目录。

## 3. Pandoc 文档转换模型

Pandoc 会先把 Markdown 解析成内部文档结构，再输出为 LaTeX、HTML、DOCX、PDF 等格式。生成 PDF 时，常见流程是 Markdown → LaTeX → PDF 引擎。本项目使用 `--pdf-engine=xelatex`，因为 XeLaTeX 对 Unicode 和系统字体支持更适合中文排版。

关键参数包括：

- `--from markdown+fenced_code_blocks+implicit_figures`：启用 Markdown、围栏代码块和隐式图片图注。
- `--resource-path`：指定相对图片和预渲染 Mermaid 图片的查找路径。
- `--metadata papersize=a4` 与 `--metadata fontsize=12pt`：设置纸张和字号。
- `--variable geometry:*`：控制 LaTeX 页面边距。
- `--include-in-header`：注入字体、页脚和宏包配置。

## 4. XeLaTeX、TeX Live 与 CJK 字体

XeLaTeX 是 TeX 排版引擎，支持 Unicode 和系统字体。中文排版通常依赖 `xeCJK` 宏包处理 CJK 字符、字体选择和断行。TeX Live 提供 LaTeX 宏包生态，`texlive-lang-chinese` 提供中文排版相关支持，`texlive-latex-extra` 提供 `fancyhdr`、`lastpage` 等常用宏包，`texlive-fonts-recommended` 提供 Base 35 等推荐字体，避免 XeTeX/hyperref 在生成链接符号字体时缺少 `pzdr`。

本项目的版式基线：

- 正文：`Noto Serif CJK SC`
- 无衬线：`Noto Sans CJK SC`
- 纸张：A4
- 字号：12pt
- 边距：上、下、外侧 0 cm，内侧 3 cm
- 页脚：`当前页 / 总页数`

## 5. Mermaid、Chromium 与 Puppeteer

Mermaid 用文本描述流程图、时序图、状态图等图形。PDF 引擎不能直接渲染 Mermaid 代码，因此项目先用 Mermaid CLI 将普通 `mermaid` 围栏渲染为 PNG，再由 Pandoc 嵌入 PDF。

Mermaid CLI 使用 Puppeteer 驱动 Chromium。由于容器以只读根文件系统运行，`HOME`、`XDG_CACHE_HOME` 和 `XDG_CONFIG_HOME` 应指向 `/tmp` 下的可写目录。Chromium 运行参数需要避免沙箱与容器限制冲突，同时不能在运行阶段下载浏览器。

## 6. Bash 宿主机入口

宿主机入口负责把用户输入解析为文件列表，并为每个 Markdown 文件启动一个隔离容器。目录输入使用 `find` 递归查找 `.md` 文件；指定输出目录时进行扁平化输出，因此必须预先检测同名 PDF 冲突，避免覆盖。

脚本安全边界包括：输入目录只读挂载，输出目录可写挂载，容器禁网，只读根文件系统，受限临时目录和 `no-new-privileges`。

## 7. 维护风险清单

- Debian 基础镜像升级可能改变包名或 Chromium 行为；升级前必须查官方发行信息。
- Pandoc 模板变量变化可能影响 LaTeX 输出。
- TeX Live 宏包变化可能影响页脚、字体或 geometry 配置。
- Mermaid CLI 和 Chromium 的版本耦合可能导致渲染参数失效；CLI 版本应显式固定并逐次升级。
- Docker 安全参数过严可能影响 Chromium 或 TeX 临时文件写入。
- 运行阶段联网会破坏离线可复现和供应链边界。
