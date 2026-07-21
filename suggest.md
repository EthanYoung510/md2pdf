# md2pdf 项目建议

本文记录超出当前产品规格、但值得人工评估的改进项。AI 维护时可追加或更新本文件；是否采纳由人工通过 issue / PR 决定。

## 建议清单

1. **补充自动化 fixtures**：增加中文、相对图片、Mermaid、目录递归、扁平化重名冲突等样例，便于在有 Docker 的环境中做端到端回归。
2. **发布版本 tag 与 release notes**：每次 `VERSION` 变化后创建同名 Git tag，例如 `v1.3`，并在 release notes 中记录依赖版本和已验证平台。
3. **增加 CI smoke test**：在支持 Docker 的 runner 中执行 `./build.sh`，再用最小 Markdown 生成 PDF，验证镜像构建和运行安全参数。
4. **评估非 root 容器运行**：当前主要依赖 Docker 安全参数隔离；后续可评估固定 UID/GID 与 `--user`，但需要确保 TeX、Chromium、Mermaid 临时目录仍可写。
5. **Mermaid 升级策略**：升级 `MERMAID_CLI_VERSION` 前先查官方 npm 包版本与 Puppeteer/Chromium 兼容性，再用 Mermaid fixture 做视觉回归。
6. **保留 `material.pdf` 再生成流程**：`material.pdf` 是明确交付物；建议在真实 Docker 环境中用 `./md2pdf.sh material.md .` 重新生成，避免手工 PDF 与源码不一致。
