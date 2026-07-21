# md2pdf

`md2pdf` 是一个离线 Markdown 转 PDF Docker 工具：构建阶段把 Pandoc、XeLaTeX、中文字体、Chromium 和 Mermaid CLI 打入镜像；运行阶段禁用网络，只读取 Markdown 和本地资源，输出适合打印的 PDF。

## 结论：不要用目录管理版本

本项目不再使用 `history/`、`current/`、`pending/` 这类目录表达版本状态。原因很简单：Git 已经提供提交历史、分支、标签和 PR 审批；再用目录复制版本，会导致重复代码、过期文档、构建入口混乱和 AI 修改范围扩大。

推荐模型：

- 历史版本：使用 Git commit、tag、release notes。
- 现行版本：仓库根目录就是当前版本。
- 待审批版本：使用 branch / PR / issue，而不是提交到 `pending/` 目录。
- 决策记录：只在需要时写入 `docs/adr/`，避免复制整套项目。

## 项目结构

```text
.
├── Dockerfile              # 离线运行镜像定义
├── md2pdf.sh               # 宿主机入口脚本
├── docker/convert.sh       # 容器内转换脚本
├── SPEC.md                 # 产品规格：功能、版式、安全和交付要求
├── prompt.md               # AI 迭代提示词：维护流程和约束
├── README.md               # 架构、使用和维护说明
├── material.md             # 技术培训材料
└── material.pdf            # 培训材料 PDF 交付物
```

## 构建镜像

```bash
docker build -t md2pdf:latest .
```

## 使用

```bash
./md2pdf.sh [INPUT] [OUTPUT_DIR]
```

规则：

- `INPUT` 省略时默认为当前目录。
- `INPUT` 是 `.md` 文件时生成同名 `.pdf`。
- `INPUT` 是目录时递归转换全部 `.md` 文件。
- 省略 `OUTPUT_DIR` 时，PDF 写入源 Markdown 同目录。
- 指定 `OUTPUT_DIR` 时，所有 PDF 扁平写入该目录；如果不同源文件生成同名 PDF，脚本会报错退出。
- Markdown 中的相对图片路径以源文件所在目录为基准解析。

## 转换链路

1. 宿主机脚本解析输入文件列表和输出路径。
2. Docker 以禁网、只读根文件系统和受限临时目录启动容器。
3. 容器脚本扫描普通 `mermaid` 代码围栏。
4. Mermaid CLI 通过 Chromium 把图渲染为高清 PNG。
5. Pandoc 调用 XeLaTeX，把处理后的 Markdown 转成 PDF。
6. LaTeX header 设置 Noto CJK 字体、A4、12pt、内侧 3cm 边距和 `当前页 / 总页数` 页脚。

## 安全边界

运行容器默认使用：

- `--network none`
- `--read-only`
- `--tmpfs /tmp:rw,nosuid,nodev,noexec,size=512m`
- `--tmpfs /run:rw,nosuid,nodev,noexec,size=64m`
- `--security-opt no-new-privileges`

构建阶段可以联网安装依赖；运行阶段不得下载字体、浏览器、npm 包或 TeX 包。

## 文档职责

- `SPEC.md`：描述产品必须满足什么，包括输入输出、PDF 版式、离线和安全要求。
- `prompt.md`：描述 AI 应该如何维护项目，包括查资料、改代码、测试、提交和创建 PR。
- `README.md`：描述项目架构、使用方式和维护建议。
- `material.md`：作为技术培训材料，解释 Docker、Pandoc、XeLaTeX、Mermaid 等技术。


## 清理策略

仓库只保留源代码、产品规格、维护提示词、培训材料和明确要求交付的 `material.pdf`。普通转换输出属于生成物，默认由 `.gitignore` 忽略；Docker 构建上下文通过 `.dockerignore` 排除 Git 元数据、文档和 PDF，避免把无关文件发送进镜像构建过程。


## AI 迭代建议

人工触发 AI 迭代时，让 AI 直接修改当前工作树并提交到分支。每次迭代应：

1. 阅读 `prompt.md`、`SPEC.md`、`README.md`、`material.md` 和相关脚本。
2. 如涉及最新版本或安全事实，查询官方资料。
3. 修改根目录当前实现。
4. 更新 README / material / SPEC。
5. 运行可用测试。
6. 提交 commit，并通过 PR 让人工审批。
