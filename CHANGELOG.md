All notable changes to PSD to Godot are documented here.

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
