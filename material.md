# md2pdf 技术培训材料

本材料面向维护者，解释项目使用的技术体系，而不是重复脚本参数说明。项目自身说明见 `README.md`，迭代治理规则见 `prompt.md`。

## 1. Docker 与离线运行

Docker 镜像把操作系统包、字体、浏览器、Node 工具、TeX 发行版和转换脚本封装为同一运行环境。离线运行的核心原则是：构建阶段可以下载依赖，运行阶段不得下载依赖。这样可以让转换行为可复现，并减少运行时供应链风险。

本项目的现行镜像基于 `debian:bookworm-slim`，在镜像内预装 Pandoc、XeLaTeX、中文 TeX、Noto CJK 字体、Chromium 与 Mermaid CLI。宿主机脚本用 `--network none` 禁止运行时网络访问，用 `--read-only` 限制根文件系统写入，并仅开放受限 `tmpfs` 和输出目录。

## 2. Pandoc 文档转换模型

Pandoc 会先把 Markdown 解析成内部文档结构，再输出为 LaTeX、HTML、DOCX、PDF 等格式。生成 PDF 时，Pandoc 常见流程是：Markdown → LaTeX → PDF 引擎。本项目使用 `--pdf-engine=xelatex`，因为 XeLaTeX 对 Unicode 和系统字体支持更适合中文排版。

关键参数包括：

- `--from markdown+fenced_code_blocks+implicit_figures`：启用 Markdown、围栏代码块和隐式图片图注。
- `--resource-path`：指定相对图片和预渲染 Mermaid 图片的查找路径。
- `--metadata papersize=a4` 与 `--metadata fontsize=12pt`：设置纸张和字号。
- `--variable geometry:*`：控制 LaTeX 页面边距。
- `--include-in-header`：注入字体、页脚和宏包配置。

## 3. XeLaTeX、TeX Live 与 CJK 字体

XeLaTeX 是 TeX 排版引擎，支持 Unicode 和系统字体。中文排版通常依赖 `xeCJK` 宏包处理 CJK 字符、字体选择和断行。TeX Live 提供 LaTeX 宏包生态，`texlive-lang-chinese` 提供中文排版相关支持，`texlive-latex-extra` 提供 `fancyhdr`、`lastpage` 等常用宏包。

本项目的版式基线：

- 正文：`Noto Serif CJK SC`
- 无衬线：`Noto Sans CJK SC`
- 纸张：A4
- 字号：12pt
- 边距：上、下、外侧 0 cm，内侧 3 cm
- 页脚：`当前页 / 总页数`

## 4. Mermaid、Chromium 与 Puppeteer

Mermaid 用文本描述流程图、时序图、状态图等图形。PDF 引擎不能直接渲染 Mermaid 代码，因此项目先用 Mermaid CLI 将普通 `mermaid` 围栏渲染为 PNG，再由 Pandoc 嵌入 PDF。

Mermaid CLI 使用 Puppeteer 驱动 Chromium。由于容器以只读根文件系统运行，`HOME`、`XDG_CACHE_HOME` 和 `XDG_CONFIG_HOME` 应指向 `/tmp` 下的可写目录。Chromium 运行参数需要避免沙箱与容器限制冲突，同时不能在运行阶段下载浏览器。

## 5. Bash 宿主机入口

宿主机入口负责把用户输入解析为文件列表，并为每个 Markdown 文件启动一个隔离容器。目录输入使用 `find` 递归查找 `.md` 文件；指定输出目录时进行扁平化输出，因此必须预先检测同名 PDF 冲突，避免覆盖。

脚本安全边界包括：输入目录只读挂载，输出目录可写挂载，容器禁网，只读根文件系统，受限临时目录和 `no-new-privileges`。

## 6. AI 自强化工作流

项目采用三段式目录：

- `history/` 保存历史版本。
- `current/` 保存现行版本。
- `pending/` 保存待审批候选版本。

AI 每轮迭代应先读取根目录提示词和现行需求，再查询官方最新资料，提出候选方案并放入 `pending/`。只有人工明确批准后，候选才进入 `current/`，旧版本归档到 `history/`。这种流程让项目能跟随技术更新自我强化，同时保留人工最终控制权。

## 7. 维护风险清单

- Debian 基础镜像升级可能改变包名或 Chromium 行为。
- Pandoc 模板变量变化可能影响 LaTeX 输出。
- TeX Live 宏包变化可能影响页脚、字体或 geometry 配置。
- Mermaid CLI 和 Chromium 的版本耦合可能导致渲染参数失效。
- Docker 安全参数过严可能影响 Chromium 或 TeX 临时文件写入。
- 运行阶段联网会破坏离线可复现和供应链边界。
# Markdown 转 PDF 技术培训教材

## 1. Docker 离线交付

Docker 镜像把系统依赖、字体、渲染引擎和脚本打包成同一个运行单元。离线运行的关键是把运行时需要的二进制、字体、npm 包和 TeX 包都放进镜像构建阶段，实际转换时只读取输入文件并写出 PDF。

本项目使用 `debian:bookworm-slim` 作为基础镜像，安装 Pandoc、XeLaTeX、中文 TeX 支持、Noto CJK 字体、Chromium 和 Mermaid CLI。宿主机脚本通过 `--network none` 禁止运行时网络访问，并通过只读根文件系统和受限 `tmpfs` 降低容器运行风险。

## 2. Pandoc

Pandoc 是通用文档转换器，可把 Markdown 解析为抽象语法树，再输出为 LaTeX、HTML、PDF 等格式。生成 PDF 时，Pandoc 通常先生成 LaTeX，再调用指定 PDF 引擎排版。

常用要点：

- `--from markdown+fenced_code_blocks` 启用 Markdown 和围栏代码块。
- `--pdf-engine=xelatex` 指定 XeLaTeX。
- `--resource-path` 控制图片等资源的搜索路径。
- `--metadata` 和 `--variable` 可设置纸张、字号和模板变量。
- `--include-in-header` 可注入 LaTeX 宏包和页眉页脚设置。

## 3. XeLaTeX 与中文排版

XeLaTeX 是支持 Unicode 和系统字体的 TeX 引擎，适合中文 PDF。中文排版通常配合 `xeCJK` 宏包，让 CJK 字符选择正确字体并处理断行。

本项目设置：

- 正文字体：`Noto Serif CJK SC`
- 无衬线字体：`Noto Sans CJK SC`
- 纸张：A4
- 字号：12pt
- 页脚：`当前页 / 总页数`
- 边距：上、下、外侧 0 cm，内侧 3 cm

## 4. Mermaid 预渲染

Mermaid 用文本描述流程图、时序图等图形。PDF 引擎不能直接理解 Mermaid 代码围栏，因此转换前需要先把普通 `mermaid` 围栏渲染为图片，再让 Pandoc 嵌入图片。

本项目流程：

1. Python 扫描 Markdown 中的 `mermaid` 围栏。
2. 将 Mermaid 源码写入临时 `.mmd` 文件。
3. 使用预装的 `mmdc` 和 Chromium 生成高清 PNG。
4. 用图片 Markdown 语法替换原代码围栏。
5. 调用 Pandoc 生成最终 PDF。

## 5. 宿主机入口脚本

`md2pdf.sh` 负责把用户输入映射为容器内路径，并设置安全运行参数。它支持文件和目录输入，目录输入时递归查找 `.md` 文件。

指定输出目录时，脚本采用扁平化输出。由于不同目录中可能存在同名 Markdown 文件，脚本会提前检测最终 PDF 名称是否冲突，发现冲突即报错，避免覆盖结果。

## 6. 安全运行实践

容器运行阶段的主要安全措施包括：

- 禁止网络：避免运行时下载依赖或外连。
- 只读根文件系统：减少容器内持久化修改面。
- 只挂载必要输入输出目录：输入只读，输出可写。
- 受限临时目录：只允许临时工作文件写入 `/tmp` 和 `/run`。
- `no-new-privileges`：阻止进程获得额外权限。

## 7. 常见问题排查

- 找不到图片：确认图片路径相对 Markdown 文件所在目录，而不是执行脚本的目录。
- Mermaid 渲染失败：确认语法正确，并重新构建镜像确保 Chromium 与 Mermaid CLI 已安装。
- 中文字体异常：确认镜像内存在 Noto CJK 字体，且 XeLaTeX 能读取系统字体缓存。
- 输出目录冲突：重命名源 Markdown 文件，或分别转换不同目录。
