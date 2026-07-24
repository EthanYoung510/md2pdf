# md2pdf 技术培训材料

本材料解释项目使用的技术体系，而不是复制命令帮助。产品规格见 `SPEC.md`，项目用法和架构见 `README.md`，AI 迭代规则见 `AGENTS.md`。

## 1. 为什么不用目录管理版本

在 Git 仓库中，用 `history/`、`current/`、`pending/` 目录表达版本通常弊大于利。Git 已经用 commit、branch、tag 和 PR 解决历史、当前和待审批问题。目录复制会让同一文件出现多份副本，AI 和人都会不确定应该改哪一份，也会让构建入口、文档和测试范围变复杂。

更好的做法是：根目录永远表示当前版本；历史通过 Git 查询；候选修改通过分支和 PR 审批；重大架构决策写 ADR 或 issue。

项目根目录的 `VERSION` 是项目版本的唯一真源，只保存不带 `v` 前缀的 `MAJOR.MINOR.PATCH`。构建脚本从它派生版本化镜像 tag 和 OCI version label；正式发布再创建 `v<VERSION>` annotated Git tag。版本说明、固定依赖和验证平台属于 `RELEASE_NOTES.md`，不应塞入 `VERSION`。

## 2. Docker 与离线运行

Docker 镜像把操作系统包、字体、浏览器、Node 工具、TeX 发行版和转换脚本封装为同一运行环境。离线运行的核心原则是：构建阶段可以下载依赖，运行阶段不得下载依赖。这样可以让转换行为可复现，并减少运行时供应链风险。

本项目基于固定的 Pandoc 官方 `pandoc/extra:3.10.0-ubuntu`，复用其 Pandoc、XeLaTeX、TeX Live 和推荐字体，再加入 Noto CJK 字体、固定版本 Mermaid CLI、Puppeteer 及其配套 Chrome for Testing。宿主机脚本用 `--network none` 禁止运行时网络访问，用 `--read-only` 限制根文件系统写入，并仅开放受限 `tmpfs` 和输出目录。

## 3. Pandoc 文档转换模型

Pandoc 会先把 Markdown 解析成内部文档结构，再输出为 LaTeX、HTML、DOCX、PDF 等格式。生成 PDF 时，常见流程是 Markdown → LaTeX → PDF 引擎。本项目使用 `--pdf-engine=xelatex`，因为 XeLaTeX 对 Unicode 和系统字体支持更适合中文排版。

关键参数包括：

- `--from markdown+fenced_code_blocks+implicit_figures`：启用 Markdown、围栏代码块和隐式图片图注。
- `--resource-path`：指定相对图片和预渲染 Mermaid 图片的查找路径。
- `--metadata papersize=a4` 与 `--metadata fontsize=12pt`：设置纸张和字号。
- `--variable geometry:*`：控制 LaTeX 页面边距。
- `--include-in-header`：注入字体、页脚和宏包配置。

## 4. XeLaTeX、TeX Live 与 CJK 字体

XeLaTeX 是 TeX 排版引擎，支持 Unicode 和系统字体。中文排版通常依赖 `xeCJK` 宏包处理 CJK 字符、字体选择和断行。Pandoc 官方 extra 镜像的 TeX Live 提供 `fancyhdr`、`zref-lastpage`、`xeCJK` 和 Base 35 推荐字体；项目用它们实现中文排版、总页数页脚，并避免 XeTeX/hyperref 在生成链接符号字体时缺少 `pzdr`。

本项目的版式基线：

- 正文：`Noto Serif CJK SC`
- 无衬线：`Noto Sans CJK SC`
- 纸张：A4
- 字号：12pt
- 双面边距：上、下、内侧 2 cm，外侧 1 cm
- 单面边距：上、下、左侧 2 cm，右侧 1 cm
- 页脚：双面位于外侧，单面位于右下，均显示 `当前页 / 总页数`

双面版式通过 LaTeX `twoside` 文档类选项、geometry 的 `inner` / `outer` 边距和 fancyhdr 的偶数页左侧/奇数页右侧页脚实现。单面版式不启用 `twoside`，改用 geometry 的 `left` / `right` 固定边距和右侧页脚。

可选的封面与目录功能使用 Pandoc 内置 Lua filter 处理文档结构：优先读取 YAML `title`，缺少时把首个一级标题提升为文档标题，再缺少时使用文件名。LaTeX `titlepage` 文档类选项让 Pandoc 的标题块独占封面页，`--toc` 根据标题层级生成目录。整个过程只使用镜像内已有的 Pandoc 和 XeLaTeX，不引入运行时下载。

## 5. Mermaid、Chromium 与 Puppeteer

Mermaid 用文本描述流程图、时序图、状态图等图形。PDF 引擎不能直接渲染 Mermaid 代码，因此项目先用 Mermaid CLI 将普通 `mermaid` 围栏渲染为 PNG，再由 Pandoc 嵌入 PDF。

Mermaid CLI 使用固定的 Puppeteer 驱动与它配套的 Chrome for Testing。浏览器在镜像构建时下载到 `/opt/puppeteer`，运行时无需网络。由于容器以只读根文件系统运行，`HOME`、`XDG_CACHE_HOME` 和 `XDG_CONFIG_HOME` 指向 `/tmp` 下的可写目录。Puppeteer 官方 Linux Chrome 二进制只支持 amd64，所以当前构建也明确限定为 amd64。

## 6. Bash 宿主机入口

宿主机入口负责解析单双面、封面目录选项和输入文件列表，并为每个 Markdown 文件启动一个隔离容器。每项功能同时提供便于交互输入的短参数（`-s`、`-d`、`-f`）和语义清晰的长参数。目录输入使用 `find` 递归查找 `.md` 文件；指定输出目录时进行扁平化输出，因此必须预先检测同名 PDF 冲突，避免覆盖。打印模式和是否生成封面目录作为经过校验的值传入容器入口。

脚本安全边界包括：输入目录只读挂载，输出目录可写挂载，容器禁网，只读根文件系统，受限临时目录和 `no-new-privileges`。

## 7. 维护风险清单

- Pandoc 官方镜像升级可能同时改变 Pandoc、TeX Live 和 Ubuntu 包；升级前必须查官方发行信息。
- Pandoc 模板变量变化可能影响 LaTeX 输出。
- TeX Live 宏包变化可能影响页脚、字体或 geometry 配置。
- Mermaid CLI 和 Chromium 的版本耦合可能导致渲染参数失效；CLI 版本应显式固定并逐次升级。
- Docker 安全参数过严可能影响 Chromium 或 TeX 临时文件写入。
- 运行阶段联网会破坏离线可复现和供应链边界。

## 8. 构建脚本与版本 tag

`build.sh` 将镜像构建入口固化为项目交付物。脚本校验根目录 `VERSION` 的三段式发布版本格式，默认构建 `md2pdf:latest`，并额外打 `md2pdf:<VERSION>` tag，同时写入一致的 OCI version label。这样可以同时满足日常使用的稳定镜像名和版本追溯需求。

脚本对 pull 和 build 显式使用 `linux/amd64`，让 ARM 宿主机通过 Docker 平台模拟构建 Chrome for Testing 支持的镜像。它保留 `MD2PDF_PLATFORM`、`PANDOC_BASE_IMAGE`、`NODE_BASE_IMAGE`、`MERMAID_CLI_VERSION` 与 `PUPPETEER_VERSION` 环境变量覆盖能力，让维护者可以在不修改脚本的情况下验证平台或依赖升级；但发布默认值必须固定，运行阶段仍必须坚持禁网和不下载依赖。

## 9. CI smoke test

GitHub Actions 在 `ubuntu-24.04` Docker runner 上执行 `build.sh`，然后用真实宿主机入口转换包含中文和 Mermaid 的最小 Markdown。测试同时检查 PDF 非空、文件类型、两个镜像 tag、OCI version label、tag 与 `VERSION` 的发布一致性，以及宿主机脚本中的禁网、只读根文件系统、受限 tmpfs 和 `no-new-privileges` 参数。这个测试是对构建链路和安全运行入口的端到端验收。
