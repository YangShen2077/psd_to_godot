# PSD to Godot

PSD to Godot is a Godot 4.7 editor add-on that turns the leaf layers in a
Photoshop PSD or PSB document into PNG textures and a ready-to-open `Sprite2D`
scene.

This was entirely coded by ChatGPT Sol. It's really just a python wrapper around
[psd-tools.](https://github.com/psd-tools/psd-tools)

## Screenshots

![UI](screenshots/ui.png)

![Generated scene open](screenshots/complete.png)

## Features

- Select PSD and PSB files from an editor dock.
- Preserve layer positions, visibility, names, and stacking order.
- Optionally pad PNGs to the PSD canvas so every sprite uses position `(0, 0)`.

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
4. Select **Import PSD as Scene**.
5. When the import completes, select **Open Imported Scene**.

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

Add `--pad-to-canvas` to enable transparent canvas padding from the command line.

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
