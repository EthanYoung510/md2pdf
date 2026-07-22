# md2pdf AI 迭代提示词

## 核心目标

维护一个可离线运行的 Docker 工具，将 Markdown 转换为适合打印的 PDF，并用尽量少的项目结构承载实现、文档和培训材料。

- `SPEC.md` 是产品规格，要严格遵循，回答“要做什么”；
- `AGENTS.md` 是 AI 维护提示词，回答“怎么迭代”。不要把两者合并成一个大 prompt。
- `suggest.md` 汇总超出需求的功能和项目优化建议，由 AI 维护供人工采纳。

## 版本管理原则

- 发布版本：创建 Git tag，并在 release notes 中记录依赖版本和已验证平台。
- 历史版本：commit、tag、release。
- 现行版本：仓库根目录工作树。
- 待审批版本：branch、PR、issue。
- 重要决策：必要时写 ADR，而不是复制整个项目目录。

AI 迭代必须直接面向当前工作树

## 每次迭代必须执行

1. 阅读 `AGENTS.md`、`SPEC.md` 和相关脚本。
2. 如问题涉及最新软件版本、安全规则、包名或 Docker 行为，必须查询官方资料。
3. 保持运行阶段离线：不得在容器运行时下载任何内容。
4. 优先精简项目结构；代码可以短，但行为必须可靠。
5. 文档必须解释架构和技术细节；不要依赖目录复制表达流程。
6. 运行可用测试；环境限制要明确标注。
7. 提交 git commit，并创建 PR 元数据。

## 功能基线

- 命令：`./md2pdf.sh [INPUT] [OUTPUT_DIR]`。
- `INPUT` 默认为当前目录。
- `.md` 文件输入生成同名 `.pdf`。
- 目录输入递归转换全部 `.md` 文件。
- 省略 `OUTPUT_DIR` 时写回源文件目录。
- 指定 `OUTPUT_DIR` 时扁平输出，重名必须报错。
- Markdown 相对图片以源文件所在目录为基准。
- 基础镜像：固定为 Pandoc 官方 `pandoc/extra:3.10.0-ubuntu`。
- 镜像名：`md2pdf:latest`；项目版本记录在 `VERSION`；构建脚本必须同时打 `latest` 和版本号 tag。
- PDF 引擎：Pandoc + XeLaTeX。
- 字体：`Noto Serif CJK SC`、`Noto Sans CJK SC`、`lmodern`、TeX Live 推荐字体。
- 页面：A4、12pt、上/下/内侧 2 cm、外侧 1 cm。
- 页脚外侧：`当前页 / 总页数`。
- Mermaid：普通 `mermaid` 围栏预渲染为高清 PNG 后嵌入 PDF，CLI 版本必须显式固定。
- 安全：禁用网络、只读根文件系统、受限临时目录、`no-new-privileges`。

## 维护建议

- 如果 AI 发现需求、代码和文档冲突，优先修正文档与脚本的一致性。
- 若发现依赖升级会破坏离线运行、中文排版或安全边界，应保留当前稳定方案并说明原因。
