# md2pdf 自强化项目

本仓库是一个由人工触发、AI 执行迭代的 Markdown 转 PDF 离线工具项目。根目录只保留项目治理入口、总览文档和培训材料；可运行代码、历史快照和待审批方案分别放在独立目录中，降低人工维护成本。

## 目录架构

```text
.
├── prompt.md              # AI 迭代总提示词：定义人工触发、自检、升级和审批规则
├── README.md              # 本文件：项目架构、工作流和使用说明
├── material.md            # 所用技术培训材料
├── md2pdf.sh              # 根入口薄封装，转发到 current/md2pdf.sh
├── current/               # 现行版本：当前可运行实现
│   ├── Dockerfile
│   ├── md2pdf.sh
│   ├── docker/convert.sh
│   ├── requirements.md
│   └── material.pdf
├── history/               # 历史版本：已归档的需求、说明和实现快照
│   └── v1.1/
└── pending/               # 待审批版本：AI 生成但尚未人工确认的下一版方案
    └── v-next/
```

## 三段式版本区

- `history/`：存放已经完成或被替换的版本资料，用于回溯、对比和审计。
- `current/`：存放现行可用版本，根入口 `./md2pdf.sh` 会调用这里的实现。
- `pending/`：存放 AI 在一次迭代中生成的候选方案、风险说明和待审批清单。人工确认后，候选内容再合并到 `current/`，旧现行版本归档到 `history/`。

## 使用现行版本

构建镜像：

```bash
cd current
docker build -t md2pdf:latest .
```

转换文档：

```bash
./md2pdf.sh [INPUT] [OUTPUT_DIR]
# md2pdf

离线 Markdown 转 PDF Docker 工具。运行阶段禁用网络，使用 Pandoc、XeLaTeX、Noto CJK 字体和预装的 Mermaid CLI 生成适合打印的 PDF。

## 构建镜像

```bash
docker build -t md2pdf:latest .
```

## 使用

```bash
./md2pdf.sh [INPUT] [OUTPUT_DIR]
```

示例：

```bash
./md2pdf.sh README.md
./md2pdf.sh docs dist-pdf
./md2pdf.sh
```

规则：

- `INPUT` 默认为当前目录。
- 文件输入只接受 `.md`。
- 目录输入会递归转换所有 `.md`。
- 不指定 `OUTPUT_DIR` 时，PDF 写在源 Markdown 同目录。
- 指定 `OUTPUT_DIR` 时，所有 PDF 扁平写入该目录；同名冲突会报错。
- 相对图片路径按源 Markdown 所在目录解析。

## 人工触发 AI 迭代流程

1. 人工在 issue、PR 或对话中触发：`根据 prompt.md 迭代项目`。
2. AI 阅读根目录 `prompt.md`、`current/requirements.md`、`README.md` 和 `material.md`。
3. AI 检查上游软件版本、官方文档和安全变化，并在 `pending/v-next/` 生成候选方案。
4. AI 执行可用测试；环境限制必须记录为 warning。
5. 人工审批后，AI 将 `current/` 归档到 `history/`，把已批准候选合并为新的 `current/`。

## 安全与离线原则

现行版本在运行容器时默认使用：
- 不指定 `OUTPUT_DIR` 时，PDF 写在源文件目录。
- 指定 `OUTPUT_DIR` 时，所有 PDF 扁平写入该目录；同名冲突会报错。
- 相对图片路径按源 Markdown 所在目录解析。

## Mermaid

普通代码围栏会在容器内预渲染为高清 PNG：

````markdown
```mermaid
flowchart LR
  A[Markdown] --> B[PDF]
```
````

## 安全默认值

`md2pdf.sh` 使用以下 Docker 运行参数：

- `--network none`
- `--read-only`
- `--tmpfs /tmp:rw,nosuid,nodev,noexec,size=512m`
- `--tmpfs /run:rw,nosuid,nodev,noexec,size=64m`
- `--security-opt no-new-privileges`

构建阶段可以联网安装依赖；运行阶段不得下载字体、浏览器、npm 包或 TeX 包。
