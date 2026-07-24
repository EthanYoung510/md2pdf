# md2pdf

`md2pdf` 是一个离线 Markdown 转 PDF Docker 工具：以固定版本的 Pandoc 官方 Ubuntu 镜像为基础，在构建阶段加入中文字体、Mermaid CLI 和 Puppeteer 配套浏览器；运行阶段禁用网络，只读取 Markdown 和本地资源，输出适合打印的 PDF。

推荐模型：

- 历史版本：使用 Git commit、tag、release notes。
- 现行版本：仓库根目录就是当前版本。
- 待审批版本：使用 branch / PR / issue，而不是提交到 `pending/` 目录。
- 决策记录：只在需要时写入 `docs/adr/`，避免复制整套项目。

## 项目结构

```text
.
├── VERSION                 # 项目版本的唯一真源
├── Dockerfile              # 离线运行镜像定义
├── md2pdf.sh               # 宿主机入口脚本
├── build.sh                # 镜像构建脚本，同时打 latest 和版本号 tag
├── docker/convert.sh       # 容器内转换脚本
├── SPEC.md                 # 产品规格：功能、版式、安全和交付要求
├── AGENTS.md               # AI 迭代约束：维护流程和行为基线
├── README.md               # 架构、使用和维护说明
├── material.md             # 技术培训材料
├── RELEASE_NOTES.md        # 发布变更、固定依赖与验证平台
├── .github/workflows/      # Docker 构建与转换冒烟测试
└── suggest.md              # 超出需求的优化建议
```

## 构建镜像

```bash
./build.sh
```

构建脚本会校验并读取 `VERSION`，同时打 `md2pdf:latest` 与 `md2pdf:<VERSION>` 两个 tag，并把相同版本写入镜像的 OCI version label。

构建前脚本会为 `linux/amd64` 拉取固定的 `pandoc/extra:3.10.0-ubuntu`，再同时生成 `md2pdf:latest` 和版本化镜像。如需手工查看 Pandoc 官方当前 Ubuntu 镜像，可执行：

```bash
docker pull pandoc/extra:latest-ubuntu
```

项目不直接使用浮动的 `latest-ubuntu` 构建，而是固定到当前已验证版本。如需评估新版，可显式覆盖 `PANDOC_BASE_IMAGE`，但应在验证后同步更新默认值和发布记录。

Mermaid 的 Chrome for Testing 官方 Linux 二进制仅支持 amd64，因此当前镜像构建平台限定为 `linux/amd64`。`build.sh` 会显式向 Docker 的 pull 和 build 传入该平台，在 Apple Silicon 等 ARM 宿主机上使用 Docker 提供的平台模拟；维护者可用 `MD2PDF_PLATFORM` 做显式兼容性试验，但发布值保持 `linux/amd64`。

## 版本与发布

`VERSION` 只保存不带 `v` 前缀的 `MAJOR.MINOR.PATCH` 发布版本号，例如 `2.3.4`。它是项目版本的唯一真源；README、SPEC 和 Dockerfile 不再硬编码当前项目版本。

- 兼容性缺陷修复增加 PATCH。
- 向后兼容的新功能增加 MINOR，并把 PATCH 归零。
- 不兼容的命令行或输出行为变更增加 MAJOR，并把 MINOR、PATCH 归零。

发布前更新 `VERSION` 和 `RELEASE_NOTES.md`，测试并合并变更，再创建 annotated tag：

```bash
version=$(<VERSION)
git tag -a "v${version}" -m "md2pdf v${version}"
git push origin "v${version}"
```

GitHub Actions 会在 tag 构建时检查 tag 是否严格等于 `v<VERSION>`。`latest` 是方便日常使用的可变 tag；`md2pdf:<VERSION>` 和 Git tag 用于不可变版本追溯。

## 使用

```bash
./md2pdf.sh [OPTIONS] [INPUT] [OUTPUT_DIR]
```

规则：

- 默认使用双面打印版式。可在位置参数之前使用 `--single-sided` 或 `--double-sided` 显式选择版式。
- 使用 `--front-matter` 时自动添加独立封面和目录。
- `INPUT` 省略时默认为当前目录。
- `INPUT` 是 `.md` 文件时生成同名 `.pdf`。
- `INPUT` 是目录时递归转换全部 `.md` 文件。
- 省略 `OUTPUT_DIR` 时，PDF 写入源 Markdown 同目录。
- 指定 `OUTPUT_DIR` 时，所有 PDF 扁平写入该目录；如果不同源文件生成同名 PDF，脚本会报错退出。
- Markdown 中的相对图片路径以源文件所在目录为基准解析。

例如，生成带封面和目录的单面打印 PDF：

```bash
./md2pdf.sh --single-sided --front-matter report.md output
```

封面标题按以下顺序自动确定：

1. Markdown YAML 元数据中的 `title`；
2. 正文的首个一级标题；
3. Markdown 文件名。

如果标题来自首个一级标题，该标题会从正文移除，避免在封面和正文重复。YAML 中的 `author`、`date` 会由 Pandoc 一并显示在封面上。例如：

```markdown
---
title: 项目报告
author: 张三
date: 2026-07-24
---
```

## 转换链路

1. 宿主机脚本解析输入文件列表和输出路径。
2. Docker 以禁网、只读根文件系统和受限临时目录启动容器。
3. 容器脚本扫描普通 `mermaid` 代码围栏。
4. Mermaid CLI 通过 Puppeteer 配套的 Chrome for Testing 把图渲染为高清 PNG。
5. Pandoc 调用 XeLaTeX，把处理后的 Markdown 转成 PDF。
6. LaTeX header 设置 Noto CJK 字体、A4、12pt，并按单双面模式设置边距与页脚。
7. 启用 `--front-matter` 时，Pandoc Lua filter 自动补齐标题，LaTeX `titlepage` 与 Pandoc TOC 生成封面和目录。

双面模式使用上/下/内侧 2 cm、外侧 1 cm，并把页码放在页脚外侧。单面模式使用上/下/左侧 2 cm、右侧 1 cm，并把页码固定在右下角。两种模式的页码格式均为 `当前页 / 总页数`。

## 安全边界

运行容器默认使用：

- `--network none`
- `--read-only`
- `--tmpfs /tmp:rw,nosuid,nodev,noexec,size=512m`
- `--tmpfs /run:rw,nosuid,nodev,noexec,size=64m`
- `--security-opt no-new-privileges`

构建阶段可以联网安装依赖；运行阶段不得下载字体、浏览器、npm 包或 TeX 包。


## 故障处理

### `Font \XeTeXLink@font=pzdr ... not loadable`

该错误表示 XeTeX/hyperref 需要 Zapf Dingbats / Base 35 相关 TeX 字体指标。当前镜像直接使用 Pandoc 官方 extra 镜像的 TeX Live，并在构建时用 `kpsewhich` 校验 `pzdr` 和 `zref-lastpage` 页数宏包；校验失败时构建会立即停止。如果仍使用旧镜像，请重新构建：

```bash
./build.sh
```

构建脚本会读取 `VERSION`，并同时打 `md2pdf:latest` 与 `md2pdf:<VERSION>` 两个 tag。

Podman 提示 `Emulate Docker CLI using podman` 不是本错误原因；真正失败点是 TeX 缺少 `pzdr` 字体指标。

## 文档职责

- `SPEC.md`：描述产品必须满足什么，包括输入输出、PDF 版式、离线和安全要求。
- `AGENTS.md`：描述 AI 应该如何维护项目，包括查资料、改代码、测试、提交和创建 PR。
- `README.md`：描述项目架构、使用方式和维护建议。
- `material.md`：作为技术培训材料，解释 Docker、Pandoc、XeLaTeX、Mermaid 等技术。
- `suggest.md`：记录超出当前需求的优化建议，供人工决定是否立项。

不建议把产品规格全部塞进 `AGENTS.md`，否则人类读需求和 AI 读流程会互相干扰。


## 清理策略

仓库只保留源代码、产品规格、维护提示词、培训材料和明确要求交付的 `material.pdf`。普通转换输出属于生成物，默认由 `.gitignore` 忽略；Docker 构建上下文通过 `.dockerignore` 排除 Git 元数据、文档和 PDF，避免把无关文件发送进镜像构建过程。

## 进一步建议

- 增加 `tests/fixtures/`：覆盖中文、相对图片、Mermaid、目录递归和扁平化重名冲突。
- 扩展 smoke test 的 fixture，覆盖相对图片和多页页脚。
- Mermaid CLI 已固定版本；后续升级时先查官方 npm 版本和 Chromium/Puppeteer 兼容性，再修改 Dockerfile。
- 重新生成 `material.pdf`：在真实 Docker 环境中用本项目脚本从 `material.md` 生成，避免手工或环境替代产物。
- 考虑拆出 `examples/`：放最小 Markdown、图片和 Mermaid 样例，方便人工验收。

## AI 迭代建议

人工触发 AI 迭代时，让 AI 直接修改当前工作树并提交到分支。不要让 AI 复制 `current/` 或维护 `pending/` 目录。每次迭代应：

1. 阅读 `AGENTS.md`、`SPEC.md`、`README.md`、`material.md` 和相关脚本。
2. 如涉及最新版本或安全事实，查询官方资料。
3. 修改根目录当前实现。
4. 更新 README / material / SPEC。
5. 运行可用测试。
6. 提交 commit，并通过 PR 让人工审批。
