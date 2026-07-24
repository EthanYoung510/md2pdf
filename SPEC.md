# md2pdf 产品规格

## 目标

构建一个可在离线运行阶段使用的 Docker 工具，把 Markdown 转换为适合打印的 PDF，并提供宿主机入口脚本 `md2pdf.sh`,和build脚本。

## 命令行

```bash
./md2pdf.sh [OPTIONS] [INPUT] [OUTPUT_DIR]
```

- 默认使用双面打印版式；`-d`、`--double-sided` 可显式选择双面版式。
- `-s`、`--single-sided` 选择单面打印版式。
- `-f`、`--front-matter` 自动添加封面和目录。
- `INPUT` 省略时默认为当前目录 `./`。
- `INPUT` 是 `.md` 文件时，生成同名 `.pdf`。
- `INPUT` 是目录时，递归转换目录下所有 `.md` 文件。
- `OUTPUT_DIR` 省略时，PDF 写入源 Markdown 所在目录。
- `OUTPUT_DIR` 指定时，所有 PDF 直接写入该目录，不保留输入目录结构。
- 扁平化输出时如出现 PDF 文件名重名，必须报错并停止。

## 转换能力

- 基础镜像使用 Pandoc 官方 Ubuntu 变体
- 默认构建目标平台为 `linux/amd64`，在 ARM 宿主机上使用 Docker 平台模拟。
- `VERSION` 是项目版本的唯一真源，只包含不带 `v` 前缀的 `MAJOR.MINOR.PATCH` 发布版本号。
- 镜像名约定为 `md2pdf:latest`；构建时还必须生成 `md2pdf:<VERSION>`，并把相同版本写入 OCI `org.opencontainers.image.version` label。
- 使用 Pandoc + XeLaTeX 生成 PDF。
- 使用官方镜像中的 TeX Live、`lmodern` 和推荐字体，额外安装 Noto CJK 系统字体；构建时校验 `zref-lastpage` 和 `pzdr`。
- 安装主流字体。
- 正文字体为 `Noto Serif CJK SC`，无衬线字体为 `Noto Sans CJK SC`。
- 默认页面为 A4、12pt。
- 双面打印时，上、下、内侧边距为 2 cm，外侧边距为 1 cm；页脚外侧显示 `当前页 / 总页数`。
- 单面打印时，上、下、左侧边距为 2 cm，右侧边距为 1 cm；页码固定在右下角，格式为 `当前页 / 总页数`。
- 启用封面和目录时，封面标题依次取 Markdown YAML `title`、首个一级标题、源文件名；使用首个一级标题时，从正文移除该标题以避免重复。YAML 中的 `author` 和 `date` 由 Pandoc 一并排入封面。
- Markdown 中的相对图片路径以源文件所在目录为基准解析。
- 支持普通 `mermaid` 代码围栏，转换前预渲染为高清 PNG 图片后嵌入 PDF；Mermaid CLI 版本在 Dockerfile 中显式固定。
- 运行容器时不得下载字体、浏览器、npm 包或 TeX 包。

## 安全约束

- 宿主机脚本运行 Docker 容器时默认禁用网络。
- 容器根文件系统只读。
- 使用受限临时目录。
- 启用 `no-new-privileges`。

## 交付物

- `VERSION`
- `Dockerfile`
- `md2pdf.sh`
- `build.sh` 需要校验 `VERSION`，同时打 `md2pdf:latest` 和 `md2pdf:<VERSION>` tag，并写入一致的 OCI version label
- `docker/convert.sh`
- `README.md`
- `SPEC.md`
- 项目评价和超出需求的建议 `suggest.md`
- AI 维护约束 `AGENTS.md`
- 技术培训教材 `material.md`
- 依赖和已验证平台记录 `RELEASE_NOTES.md`
- GitHub Actions Docker smoke test，必须执行真实镜像构建和最小 PDF 转换
