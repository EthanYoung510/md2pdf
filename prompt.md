# Markdown 转 PDF 离线镜像 1.1

- 实现一个可离线运行的 Docker 工具，将 Markdown 转换为适合打印的 PDF
- 并提供宿主机入口脚本 `md2pdf.sh`。

## 输入与输出

- 命令格式：`./md2pdf.sh [INPUT] [OUTPUT_DIR]`。
- `INPUT` 为 `.md` 文件时生成同名 `.pdf`；为目录时递归转换全部 `.md`; 默认是`./`。
- 省略 `OUTPUT_DIR` 时，每个 PDF 写入其源 Markdown 同目录。
- 指定 `OUTPUT_DIR` 时，全部 PDF 直接写入该目录，不保留输入目录结构；扁平化重名必须报错。
- Markdown 中的相对图片以源文件所在目录为基准并可正常嵌入。


## 转换与版式

- 基础镜像：`debian:bookworm-slim`；镜像名：`md2pdf:latest`。
- PDF 引擎：Pandoc + XeLaTeX。
- 安装中文 TeX、Noto CJK 和 `lmodern`。
- 正文使用 `Noto Serif CJK SC`，无衬线使用 `Noto Sans CJK SC`。
- 默认 A4、12pt；上/下/外侧边距 0 cm，内侧边距 3 cm。
- 在页脚增加页码格式如： 1 / 20
- 支持普通 `mermaid` 代码围栏,预渲染为高清图片，中文可用，再嵌入 PDF。
- 运行时不得下载字体、浏览器、npm 包或 TeX 包。

## 安全

- Docker 默认禁用网络
- 同时启用只读根文件系统、受限临时目录

## 交付物

- 包含 Dockerfile、宿主机脚本、容器转换脚本、README.md.
- 重新整理简明的需求文档,更新文件本文件( prompt.md).这个需求要求在新文件中保留。
- 整个项目使用全部技术的培训教材,(不是项目本身的教材),要结合各项技术的权威知识 material.md
- 用该项目脚本生成的material.pdf


## 实施状态

本仓库已按上述需求补充 Dockerfile、宿主机入口脚本、容器转换脚本、README、独立需求文档、技术培训教材和 PDF 交付物。原始需求另整理保存在 `requirements.md`。
