# Release notes

## v1.5.0

### 变更

- 新增 `--single-sided` 与 `--double-sided` 打印版式选项，默认保持双面打印。
- 单面版式使用上、下、左侧 2 cm、右侧 1 cm 边距，并把页码固定在右下角。
- 新增 `--front-matter`，自动生成独立封面和目录；标题依次取 YAML `title`、首个一级标题和文件名。
- smoke test 同时执行默认双面转换和带封面目录的单面转换。

### 固定依赖

- Pandoc 官方镜像：`pandoc/extra:3.10.0-ubuntu`（Pandoc 3.10.0）
- Node.js 官方镜像：`node:22.23.1-bookworm-slim`（仅复制 Node.js 运行时）
- Mermaid CLI：11.16.0
- Puppeteer：24.43.1
- PDF 引擎：Pandoc 官方镜像内置 XeTeX 0.999998 / TeX Live 2026
- 浏览器：Chrome for Testing 148.0.7778.97（由固定的 Puppeteer 版本选择，仅在构建阶段下载）

### 验证平台

- Linux x86_64 + Podman 4.9.4 Docker 兼容层：已验证 `linux/amd64` 完整镜像构建、默认双面转换、带封面目录的单面转换，以及带封面目录的双面转换。

## v1.4.1

### 变更

- Docker 构建上下文忽略 macOS Finder 生成的 `.DS_Store`。
- 删除已被全局 `*.pdf` 规则覆盖的冗余 `material.pdf` 忽略项。

### 固定依赖

- Pandoc 官方镜像：`pandoc/extra:3.10.0-ubuntu`（Pandoc 3.10.0）
- Node.js 官方镜像：`node:22.23.1-bookworm-slim`（仅复制 Node.js 运行时）
- Mermaid CLI：11.16.0
- Puppeteer：24.43.1
- PDF 引擎：Pandoc 官方镜像内置 XeTeX 0.999998 / TeX Live 2026
- 浏览器：Chrome for Testing 148.0.7778.97（由固定的 Puppeteer 版本选择，仅在构建阶段下载）

### 验证平台

- GitHub Actions `ubuntu-24.04` + Docker：由 `.github/workflows/smoke.yml` 执行完整镜像构建和中文/Mermaid PDF 转换。

## v1.4.0

### 变更

- 项目版本规范化为 `MAJOR.MINOR.PATCH`，并以单行 `VERSION` 作为唯一真源。
- 构建脚本从 `VERSION` 派生版本化镜像 tag 和 OCI version label；CI 校验镜像元数据及发布 tag 一致性。
- 构建脚本显式使用 `linux/amd64` 目标平台，使 ARM 宿主机可通过 Docker 平台模拟构建受 Chrome for Testing 架构限制的镜像。
- 基础镜像迁移到 Pandoc 官方 Ubuntu 镜像，并固定为 `pandoc/extra:3.10.0-ubuntu`。
- 增加 GitHub Actions Docker smoke test，真实构建镜像并转换包含中文和 Mermaid 的最小文档。
- AI 维护约束由 `prompt.md` 迁移到标准的 `AGENTS.md`。
- 修正规格漂移：打印边距恢复为上/下/内侧 2 cm、外侧 1 cm，页码置于页脚外侧。

### 固定依赖

- Pandoc 官方镜像：`pandoc/extra:3.10.0-ubuntu`（Pandoc 3.10.0）
- Node.js 官方镜像：`node:22.23.1-bookworm-slim`（仅复制 Node.js 运行时）
- Mermaid CLI：11.16.0
- Puppeteer：24.43.1
- PDF 引擎：Pandoc 官方镜像内置 XeTeX 0.999998 / TeX Live 2026
- 浏览器：Chrome for Testing 148.0.7778.97（由固定的 Puppeteer 版本选择，仅在构建阶段下载）

### 验证平台

- Linux x86_64 + Podman 4.9.4 Docker 兼容层：已验证完整构建，以及禁网、只读根文件系统和受限 tmpfs 下的中文/Mermaid PDF 转换。
- GitHub Actions `ubuntu-24.04` + Docker：由 `.github/workflows/smoke.yml` 在 push 和 pull request 时持续验证。
