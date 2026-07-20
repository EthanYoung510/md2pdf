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
