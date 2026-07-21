# md2pdf AI 自强化总提示词

## 目标

本项目由人工触发 AI 迭代。AI 必须基于最新官方软件版本、当前实现技术和项目历史，自行提出、实现、测试并提交候选改进，减少人工参与，但不得绕过人工审批。

## 版本分区

项目目录必须长期保持至少三个区域：

1. `history/`：历史版本。保存旧需求、旧文档、旧实现摘要或快照，用于追踪演进。
2. `current/`：现行版本。保存当前可运行代码、容器脚本、需求和已批准交付物。
3. `pending/`：待审批版本。保存 AI 本轮生成但尚未人工批准的候选方案、迁移说明和风险清单。

根目录只保留治理入口：`prompt.md`、`README.md`、`material.md` 和必要的薄入口脚本。

## 每次迭代必须执行

1. 阅读并理解：`prompt.md`、`README.md`、`material.md`、`current/requirements.md` 和最近一个 `history/` 版本。
2. 查询最新官方资料：Debian、Pandoc、TeX Live、Noto CJK、Mermaid CLI、Chromium、Docker 安全参数。只把确定有价值的变更写入候选方案。
3. 对比 `current/` 与最新资料，识别：安全风险、离线运行风险、依赖过期风险、脚本行为偏差、文档不一致。
4. 在 `pending/v-next/` 输出候选版本资料，不直接覆盖 `current/`，除非人工明确要求“批准并应用”。
5. 如人工要求实现，则更新 `current/`，并把被替换内容归档到 `history/`。
6. 更新 `material.md`，让培训材料覆盖所有实际使用技术，而不是只讲项目用法。
7. 更新 `README.md`，描述项目架构、运行方式、审批流程和安全边界。
8. 运行可用测试；不可用的 Docker、网络、TeX 或系统依赖要明确标记为环境限制。
9. 提交 git commit，并创建 PR 元数据。

## 现行功能基线

现行版本是离线运行的 Docker Markdown 转 PDF 工具：

- 基础镜像：`debian:bookworm-slim`。
- 镜像名：`md2pdf:latest`。
- PDF 引擎：Pandoc + XeLaTeX。
- 字体：`Noto Serif CJK SC`、`Noto Sans CJK SC`、`lmodern`。
- 页面：A4、12pt、上/下/外侧 0 cm、内侧 3 cm。
- 页脚：`当前页 / 总页数`。
- Mermaid：普通 `mermaid` 代码围栏预渲染为高清 PNG。
- 输入：`./md2pdf.sh [INPUT] [OUTPUT_DIR]`，文件或递归目录。
- 输出：省略输出目录时写回源目录；指定输出目录时扁平写入并检测重名。
- 运行安全：禁用网络、只读根文件系统、受限临时目录、`no-new-privileges`。

## 审批规则

- `pending/` 中的内容是建议，不代表已发布。
- 未经人工明确批准，不得删除 `history/`。
- 未经人工明确批准，不得把实验性依赖加入 `current/`。
- 如果最新版本会破坏离线运行、中文排版或安全边界，必须保留旧方案并说明原因。

## 代码策略

代码可以精简，不以教学可读性为目标；教学和架构解释必须写在独立 `README.md` 与 `material.md` 中。任何复杂实现都应优先被文档解释，而不是在脚本中保留大量注释。
- 包含 Dockerfile、宿主机脚本、容器转换脚本、README.md.
- 重新整理简明的需求文档,更新文件本文件( prompt.md).这个需求要求在新文件中保留。
- 整个项目使用全部技术的培训教材,(不是项目本身的教材),要结合各项技术的权威知识 material.md
- 用该项目脚本生成的material.pdf
