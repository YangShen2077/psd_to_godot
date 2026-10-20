All notable changes to PSD to Godot are documented here.
PSD to Godot 的所有重要变更都记录在此。

## Unreleased / 未发布

### Added / 新增

- **Include group names in file names** export option, on by default. Disabled
  keeps only the leaf layer name. Remembers the choice per project and exposes
  `--exclude-groups`.
- 新增导出选项「**文件名包含图层组路径**」（默认开启）。关闭后只使用叶子图层名。
  按项目记忆勾选状态，命令行参数为 `--exclude-groups`。

- **Skip hidden layers** export option, off by default. Leaves layers that are
  hidden in the PSD out of the export, including layers inside hidden groups.
  The original behavior of exporting them with `visible = false` is unchanged
  when the option is off. Exposes `--skip-hidden`.
- 新增导出选项「**跳过隐藏图层**」（默认关闭）。勾选后不导出 PSD 中隐藏的图层，
  包含位于隐藏组内的图层；不勾选时仍按原版行为导出并写入 `visible = false`。
  命令行参数为 `--skip-hidden`。

- **Number layers by export order** export option, off by default. Enabled
  renumbers exported layers `000`, `001`, ... while disabled keeps each layer's
  PSD index so file names stay stable across option changes. Exposes
  `--sequential-index`, and the manifest now records a per-layer `psd_index`.
- 新增导出选项「**按导出结果编号**」（默认关闭）。开启后按导出顺序编号 `000`、`001`……；
  关闭则保留图层在 PSD 中的原始序号，切换其他选项时文件名不变。
  命令行参数为 `--sequential-index`，清单中新增每层的 `psd_index` 字段。

- **Clear output folder before export** export option, off by default. Deletes
  leftover files of a previous export first, but only when the folder contains
  the generated `layers.json`, and only for top-level files. The checkbox shows
  a warning label while enabled. Exposes `--clear-output`.
- 新增导出选项「**导出前清空输出目录**」（默认关闭）。先删除上一次导出的残留文件，
  但仅当目录内存在生成的 `layers.json` 时才执行，且只删除顶层文件；勾选后复选框显示警告文案。
  命令行参数为 `--clear-output`。

- International layer names are preserved in file names and node names.
- 文件名与场景节点名保留中文等非 ASCII 图层名。

### Fixed / 修复

- Layer names are no longer reduced to `Layer`. Cleaning used an ASCII whitelist,
  which turned any non-ASCII name into underscores and then into the `Layer`
  fallback; it now uses a blacklist of path-invalid characters and truncates
  long fragments (48 characters per part, 120 per hierarchy).
- 图层名不再被清洗成 `Layer`。原先使用 ASCII 白名单，会把所有非 ASCII 名称替换成下划线并最终回退为
  `Layer`；现改为路径非法字符黑名单，并对超长片段截断（单段 48 字符、整条层级 120 字符）。

- Scene node numbering matches file numbering. PNG names used the PSD index while
  nodes used the export list position, so the same layer could be exported as
  `002_xxx.png` while its node was named `000_xxx`.
- 场景节点编号与文件编号保持一致。此前 PNG 使用 PSD 序号、节点使用导出列表下标，
  同一图层会出现 `002_xxx.png` 对应节点 `000_xxx` 的错位。

## 1.0.2 - 2026-10-01

- Add an optional **Pad PNGs to PSD canvas** export setting, remembered per project.
- Preserve layer placement with transparent padding and all sprites at `(0, 0)`.
- Support `--pad-to-canvas` in the command-line importer and record the export
  mode, canvas size, and original layer bounds in the manifest.

## 1.0.1 - 2026-09-02

- Install `psd-tools` automatically when it is missing.
- Add setup and completed-import screenshots.
- Improve successful-import status output and long-path wrapping.
- Export hidden layer pixels while preserving their initial Godot visibility.

## 1.0.0 - 2026-09-02
  First version. Be nice
