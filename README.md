# PSD to Godot

> **Fork note / 分支说明** — this version builds on the original 1.0.2 add-on and
> adds export options for international layer names, file naming and output
> cleanup. Every added option defaults to the original behavior, so an existing
> project exports exactly the same way until you change a toggle.
> 本版本在原版 1.0.2 基础上补充了导出选项（国际化图层名、文件命名、输出清理）。
> 新增开关默认全部沿用原版行为，未改动前导出结果与原先一致。

PSD to Godot is a Godot 4.7 editor add-on that turns the leaf layers in a
Photoshop PSD or PSB document into PNG textures and a ready-to-open `Sprite2D`
scene.

This was entirely coded by ChatGPT Sol. It's really just a python wrapper around
[psd-tools.](https://github.com/psd-tools/psd-tools)

## Differences from the original version / 与原版的区别

### English

- **International layer names are kept.** `clean_name()` used an ASCII whitelist,
  so every Chinese (or otherwise non-ASCII) layer name collapsed to `Layer` and
  179 of 181 exported files ended up named like `002_Layer__Layer.png`. Cleaning
  now uses a blacklist instead and only replaces characters that are invalid in
  paths or meaningful to Godot. Long fragments are truncated (48 characters per
  part, 120 per joined hierarchy).
- **Include group names in file names** (on by default, `--exclude-groups`).
  Enabled keeps the PSD group path: `001_Buttons__Play.png`. Disabled uses the
  leaf name only: `001_Play.png`. Scene node names always use the leaf name.
- **Skip hidden layers** (off by default, `--skip-hidden`). The original always
  exported hidden layers and only applied `visible = false` to the generated
  node. With this option they are left out entirely, including layers inside
  hidden groups (`Layer.is_visible()` is used, which accounts for parent groups).
- **Number layers by export order** (off by default, `--sequential-index`).
  Enabled numbers exported layers `000`, `001`, ... so skipped layers do not
  leave gaps. Disabled keeps each layer's PSD index, which keeps file names
  stable when you change the other toggles.
- **Clear output folder before export** (off by default, `--clear-output`).
  Deletes leftover files of a previous export before writing the new ones. Two
  safety rules: it only runs when the folder contains the generated
  `layers.json`, and it only removes top-level files, never sub-directories. The
  checkbox switches to a warning text while it is enabled.
- **File and node numbering always agree.** Previously PNG names used the PSD
  index while scene nodes used the position in the export list, so the same
  layer could appear as `002_xxx.png` and node `000_xxx`.

The manifest records the new export flags `include_groups`, `skip_hidden`,
`clear_existing` and `sequential_index`, and each layer now carries `index` (used
for naming) plus `psd_index` (the original PSD position, metadata only).

### 中文

- **保留国际化图层名。** 原 `clean_name()` 用的是 ASCII 白名单，中文图层名会被整段清洗成 `Layer`，
  实测 181 层里有 179 层导出成 `002_Layer__Layer.png`。现改为黑名单：只替换文件系统非法字符与
  Godot 里有特殊含义的字符，中文原样保留；超长片段截断（单段 48 字符，整条层级路径 120 字符）。
- **文件名包含图层组路径**（默认开启，`--exclude-groups`）。开启保留 PSD 组路径：
  `001_Buttons__Play.png`；关闭只用叶子图层名：`001_Play.png`。场景节点名始终只用叶子名。
- **跳过隐藏图层**（默认关闭，`--skip-hidden`）。原版会把隐藏图层也导出，仅在节点上写 `visible = false`；
  开启后彻底不导出，包含位于隐藏组内的图层（使用 `Layer.is_visible()`，会连带父组状态一起判断）。
- **按导出结果编号**（默认关闭，`--sequential-index`）。开启后按导出顺序编号 `000`、`001`……，
  被跳过的层不占号；关闭则沿用图层在 PSD 中的原始序号，好处是切换其他开关时文件名保持不变。
- **导出前清空输出目录**（默认关闭，`--clear-output`）。写入新成品前删除上一次导出的残留文件。
  两条安全规则：目录里必须存在生成的 `layers.json` 才执行；只删顶层文件，不递归子目录。
  勾选后复选框文案会切换为警告样式。
- **文件名与节点名编号始终一致。** 之前 PNG 用 PSD 序号、场景节点用导出列表下标，
  同一个图层会出现 `002_xxx.png` 对应节点 `000_xxx` 的错位。

清单文件新增 `include_groups`、`skip_hidden`、`clear_existing`、`sequential_index` 四个导出标志，
每层记录 `index`（用于命名）与 `psd_index`（PSD 原始位置，仅元数据）。

## Screenshots

![UI](screenshots/ui.png)

![Generated scene open](screenshots/complete.png)

## Features

- Select PSD and PSB files from an editor dock.
- Preserve layer positions, visibility, names, and stacking order.
- Keep international (non-ASCII) layer names in file and node names.
- Optionally pad PNGs to the PSD canvas so every sprite uses position `(0, 0)`.
- Toggle group names in file names, hidden layers, numbering mode, and export
  cleanup. See [Differences from the original
  version](#differences-from-the-original-version--与原版的区别).

## Requirements

- Godot 4.7 or newer.
- Python 3.10 or newer.
- An internet connection the first time `psd-tools` needs to be installed.

Select **Check / Install** in the dock. If `psd-tools` is missing, the add-on
installs it automatically into a writable per-user dependency folder. It does
not require administrator privileges or modify the Godot project.

You can alternatively install it manually for the selected interpreter:

```bash
python3 -m pip install "psd-tools>=1.10,<2"
```

For additional compositing support, manually install the optional dependencies
with `python3 -m pip install "psd-tools[composite]>=1.10,<2"`. On Windows,
replace `python3` with `python` or the full path to `python.exe`.

## Installation

1. Copy `addons/psd_to_godot` into your Godot project.
2. In Godot, open **Project > Project Settings > Plugins**.
3. Enable **PSD to Godot**.
4. Open the **PSD to Godot** editor dock.
5. Enter the Python executable and select **Check / Install**.

## Usage

1. Choose a PSD or PSB document.
2. Choose a generated-files folder inside `res://`.
3. Optionally enable **Pad PNGs to PSD canvas**. This choice is remembered per project.
4. Optionally adjust the other export toggles: **Include group names in file
   names**, **Skip hidden layers**, **Number layers by export order** and
   **Clear output folder before export**. All of them are remembered per project
   too.
5. Select **Import PSD as Scene**.
6. When the import completes, select **Open Imported Scene**.

With padding enabled, every PNG has the PSD document's width and height. Each
layer's artwork is placed within that image at its original document coordinates,
with transparent pixels around it. All generated sprites use position `(0, 0)`,
`centered = false`, and no offset; the scene origin remains the canvas's top-left
corner. Relative layer placement is preserved without individual transforms.
Pixels outside the PSD canvas are clipped, and full-canvas textures use more
texture memory than smaller layer images. Hidden layers retain their visibility.

Padding is off by default, preserving the existing export behavior. Changing the
option requires reimporting, which replaces the generated textures and scene.
The manifest records `pad_to_canvas`, `canvas_size`, and each layer's
`original_bounds` as `[left, top, right, bottom]`; layer positions and dimensions
describe the exported sprites and PNGs.

For `menu.psd` and the default output folder, the add-on creates:

```text
res://art/generated/menu/
├── 000_Background.png
├── 001_Buttons__Play.png
├── layers.json
└── menu.tscn
```

The bundled importer can also be called directly:

```bash
python addons/psd_to_godot/psd_importer.py \
  --project-root . \
  --output-dir art/generated \
  path/to/menu.psd
```

Every dock toggle has a command-line equivalent. Add `--pad-to-canvas` to enable
transparent canvas padding, and any combination of:

| Flag | Effect |
| --- | --- |
| `--exclude-groups` | Leave PSD group names out of file names (groups are included by default) |
| `--skip-hidden` | Do not export layers that are hidden in the PSD |
| `--sequential-index` | Number exported layers `000`, `001`, ... instead of using PSD indices |
| `--clear-output` | Delete leftover files in the export folder before writing new ones |

## Limitations

- Layers are rasterized. Text, shape, and smart-object editability is not
  retained in Godot.
- Leaf layers become a flat list of `Sprite2D` nodes. PSD groups are retained in
  filenames and manifest metadata, but do not become Godot nodes.
- Photoshop features unsupported by `psd-tools` may render differently from
  Photoshop. Some layer effects have limited support.
- Python is an external dependency and is not included in the add-on archive.
- Importing is an editor workflow and is not supported in exported games.

## Privacy

The add-on processes documents locally and never uploads artwork. If
`psd-tools` is missing, Python's package installer connects to its configured
package index to download it and its dependencies.

## License

MIT. See [LICENSE](LICENSE).
