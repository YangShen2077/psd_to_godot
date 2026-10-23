@tool
extends VBoxContainer

const HELPER_FILENAME := "psd_importer.py"
const METADATA_SECTION := "psd_to_godot"
const CLEAR_OUTPUT_TEXT := "Clear output folder before export"
const CLEAR_OUTPUT_WARNING := (
	"Clear output folder before export - DELETES existing files in it!"
)

var _editor_interface: EditorInterface
var _thread: Thread
var _shutting_down := false

var _python_edit: LineEdit
var _psd_edit: LineEdit
var _output_edit: LineEdit
var _pad_to_canvas_check: CheckBox
var _include_groups_check: CheckBox
var _skip_hidden_check: CheckBox
var _sequential_index_check: CheckBox
var _group_nodes_check: CheckBox
var _clear_output_check: CheckBox
var _check_button: Button
var _import_button: Button
var _open_button: Button
var _status: TextEdit
var _psd_dialog: FileDialog
var _output_dialog: FileDialog
var _last_scene_path := ""


func setup(editor_interface: EditorInterface) -> void:
	_editor_interface = editor_interface
	name = "PSD to Godot"
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	_build_interface()
	_load_settings()


func shutdown() -> void:
	_shutting_down = true
	if _thread != null:
		_thread.wait_to_finish()
		_thread = null


func _build_interface() -> void:
	var heading := Label.new()
	heading.text = "PSD to Godot"
	heading.add_theme_font_size_override("font_size", 18)
	add_child(heading)

	var introduction := Label.new()
	introduction.text = (
		"Export visible and hidden PSD/PSB leaf layers to PNG files and "
		+ "assemble them as a Sprite2D scene."
	)
	introduction.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(introduction)

	add_child(HSeparator.new())
	_add_field_label("Python executable")
	var python_row := HBoxContainer.new()
	_python_edit = LineEdit.new()
	_python_edit.name = "PythonExecutable"
	_python_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_python_edit.placeholder_text = "python3"
	_python_edit.tooltip_text = "Python 3.10 or newer. Missing dependencies are installed automatically."
	_python_edit.text_changed.connect(_on_python_changed)
	python_row.add_child(_python_edit)
	_check_button = Button.new()
	_check_button.name = "CheckInstallButton"
	_check_button.text = "Check / Install"
	_check_button.pressed.connect(_check_setup)
	python_row.add_child(_check_button)
	add_child(python_row)

	_add_field_label("Photoshop document")
	var psd_row := HBoxContainer.new()
	_psd_edit = LineEdit.new()
	_psd_edit.name = "PhotoshopDocument"
	_psd_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_psd_edit.placeholder_text = "/path/to/artwork.psd"
	_psd_edit.text_changed.connect(_on_psd_changed)
	psd_row.add_child(_psd_edit)
	var psd_browse := Button.new()
	psd_browse.text = "Browse…"
	psd_browse.pressed.connect(_browse_for_psd)
	psd_row.add_child(psd_browse)
	add_child(psd_row)

	_add_field_label("Generated files folder")
	var output_row := HBoxContainer.new()
	_output_edit = LineEdit.new()
	_output_edit.name = "OutputFolder"
	_output_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_output_edit.placeholder_text = "res://art/generated"
	_output_edit.tooltip_text = "The generated scene gets its own subfolder here."
	_output_edit.text_changed.connect(_on_output_changed)
	output_row.add_child(_output_edit)
	var output_browse := Button.new()
	output_browse.text = "Browse…"
	output_browse.pressed.connect(_browse_for_output)
	output_row.add_child(output_browse)
	add_child(output_row)

	_pad_to_canvas_check = CheckBox.new()
	_pad_to_canvas_check.name = "PadToCanvas"
	_pad_to_canvas_check.text = "Pad PNGs to PSD canvas"
	_pad_to_canvas_check.tooltip_text = (
		"Use transparent padding to preserve layer placement with every sprite at (0, 0). "
		+ "Images match the PSD canvas size; artwork outside the canvas is clipped."
	)
	_pad_to_canvas_check.toggled.connect(_on_pad_to_canvas_changed)
	add_child(_pad_to_canvas_check)

	_include_groups_check = CheckBox.new()
	_include_groups_check.name = "IncludeGroups"
	_include_groups_check.text = "Include group names in file names"
	_include_groups_check.tooltip_text = (
		"Include the PSD group path in exported PNG names.\n"
		+ "Enabled: 001_Buttons__Play.png\n"
		+ "Disabled: 001_Play.png"
	)
	_include_groups_check.toggled.connect(_on_include_groups_changed)
	add_child(_include_groups_check)

	_skip_hidden_check = CheckBox.new()
	_skip_hidden_check.name = "SkipHidden"
	_skip_hidden_check.text = "Skip hidden layers"
	_skip_hidden_check.tooltip_text = (
		"Leave layers that are hidden in the PSD out of the export, including "
		+ "layers inside hidden groups. Hidden layers are exported by default."
	)
	_skip_hidden_check.toggled.connect(_on_skip_hidden_changed)
	add_child(_skip_hidden_check)

	_sequential_index_check = CheckBox.new()
	_sequential_index_check.name = "SequentialIndex"
	_sequential_index_check.text = "Number layers by export order"
	_sequential_index_check.tooltip_text = (
		"Number file names and scene nodes 000, 001, ... in export order. "
		+ "Disabled keeps each layer's PSD index, so skipped layers leave gaps."
	)
	_sequential_index_check.toggled.connect(_on_sequential_index_changed)
	add_child(_sequential_index_check)

	_group_nodes_check = CheckBox.new()
	_group_nodes_check.name = "GroupNodes"
	_group_nodes_check.text = "Preserve PSD groups as nodes"
	_group_nodes_check.tooltip_text = (
		"Turn PSD groups into empty Node2D parents so the scene keeps the document hierarchy. "
		+ "Sprites keep their document coordinates, so draw order and placement do not change."
	)
	_group_nodes_check.toggled.connect(_on_group_nodes_changed)
	add_child(_group_nodes_check)

	_clear_output_check = CheckBox.new()
	_clear_output_check.name = "ClearOutput"
	_clear_output_check.text = CLEAR_OUTPUT_TEXT
	_clear_output_check.tooltip_text = (
		"Delete files left over from a previous export before writing the new ones. "
		+ "Only runs when the export folder contains the generated layers.json, "
		+ "so unrelated folders are never emptied. Sub-folders are kept."
	)
	_clear_output_check.toggled.connect(_on_clear_output_changed)
	add_child(_clear_output_check)

	_import_button = Button.new()
	_import_button.name = "ImportButton"
	_import_button.text = "Import PSD as Scene"
	_import_button.pressed.connect(_import_psd)
	add_child(_import_button)

	_open_button = Button.new()
	_open_button.name = "OpenSceneButton"
	_open_button.text = "Open Imported Scene"
	_open_button.visible = false
	_open_button.pressed.connect(_open_imported_scene)
	add_child(_open_button)

	_add_field_label("Status")
	_status = TextEdit.new()
	_status.name = "StatusOutput"
	_status.custom_minimum_size = Vector2(0, 150)
	_status.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_status.editable = false
	_status.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_status.text = "Choose a Python executable and click Check / Install."
	add_child(_status)

	_psd_dialog = FileDialog.new()
	_psd_dialog.title = "Choose a Photoshop document"
	_psd_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_psd_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_psd_dialog.filters = PackedStringArray([
		"*.psd, *.psb ; Photoshop documents",
	])
	_psd_dialog.file_selected.connect(_on_psd_selected)
	add_child(_psd_dialog)

	_output_dialog = FileDialog.new()
	_output_dialog.title = "Choose the generated files folder"
	_output_dialog.access = FileDialog.ACCESS_RESOURCES
	_output_dialog.file_mode = FileDialog.FILE_MODE_OPEN_DIR
	_output_dialog.dir_selected.connect(_on_output_selected)
	add_child(_output_dialog)


func _add_field_label(text: String) -> void:
	var label := Label.new()
	label.text = text
	add_child(label)


func _load_settings() -> void:
	var settings := _editor_interface.get_editor_settings()
	var default_python := "python" if OS.get_name() == "Windows" else "python3"
	_python_edit.text = settings.get_project_metadata(
		METADATA_SECTION, "python_executable", default_python
	)
	_psd_edit.text = settings.get_project_metadata(
		METADATA_SECTION, "last_psd", ""
	)
	_output_edit.text = settings.get_project_metadata(
		METADATA_SECTION, "output_folder", "res://art/generated"
	)
	_include_groups_check.set_pressed_no_signal(
		settings.get_project_metadata(METADATA_SECTION, "include_groups", true)
	)
	_skip_hidden_check.set_pressed_no_signal(
		settings.get_project_metadata(METADATA_SECTION, "skip_hidden", false)
	)
	_sequential_index_check.set_pressed_no_signal(
		settings.get_project_metadata(METADATA_SECTION, "sequential_index", false)
	)
	_group_nodes_check.set_pressed_no_signal(
		settings.get_project_metadata(METADATA_SECTION, "group_nodes", false)
	)
	_clear_output_check.set_pressed_no_signal(
		settings.get_project_metadata(METADATA_SECTION, "clear_existing", false)
	)
	_update_clear_output_text(
		settings.get_project_metadata(METADATA_SECTION, "clear_existing", false)
	)
	_pad_to_canvas_check.set_pressed_no_signal(
		settings.get_project_metadata(METADATA_SECTION, "pad_to_canvas", false)
	)


func _save_setting(key: String, value: Variant) -> void:
	if _editor_interface == null:
		return
	_editor_interface.get_editor_settings().set_project_metadata(
		METADATA_SECTION, key, value
	)


func _on_python_changed(value: String) -> void:
	_save_setting("python_executable", value)


func _on_psd_changed(value: String) -> void:
	_save_setting("last_psd", value)


func _on_output_changed(value: String) -> void:
	_save_setting("output_folder", value)


func _on_include_groups_changed(value: bool) -> void:
	_save_setting("include_groups", value)


func _on_skip_hidden_changed(value: bool) -> void:
	_save_setting("skip_hidden", value)


func _on_sequential_index_changed(value: bool) -> void:
	_save_setting("sequential_index", value)


func _on_group_nodes_changed(value: bool) -> void:
	_save_setting("group_nodes", value)


func _on_clear_output_changed(value: bool) -> void:
	_save_setting("clear_existing", value)
	_update_clear_output_text(value)


func _update_clear_output_text(enabled: bool) -> void:
	_clear_output_check.text = (
		CLEAR_OUTPUT_WARNING if enabled else CLEAR_OUTPUT_TEXT
	)


func _on_pad_to_canvas_changed(value: bool) -> void:
	_save_setting("pad_to_canvas", value)


func _browse_for_psd() -> void:
	if not _psd_edit.text.is_empty():
		_psd_dialog.current_path = _psd_edit.text
	_psd_dialog.popup_centered_ratio(0.75)


func _browse_for_output() -> void:
	if _output_edit.text.begins_with("res://"):
		_output_dialog.current_dir = _output_edit.text
	_output_dialog.popup_centered_ratio(0.75)


func _on_psd_selected(path: String) -> void:
	_psd_edit.text = path
	_on_psd_changed(path)


func _on_output_selected(path: String) -> void:
	_output_edit.text = path
	_on_output_changed(path)


func _check_setup() -> void:
	if not _validate_python():
		return
	var arguments := PackedStringArray([
		ProjectSettings.globalize_path(_helper_path()),
		"--check",
	])
	_start_command("check", arguments)


func _import_psd() -> void:
	if not _validate_python():
		return

	var psd_path := _psd_edit.text.strip_edges()
	if psd_path.is_empty() or not FileAccess.file_exists(psd_path):
		_set_status("Choose an existing PSD or PSB file first.")
		return

	var output_path := _output_edit.text.strip_edges()
	if not output_path.begins_with("res://"):
		_set_status("The generated files folder must be inside the project (res://).")
		return

	var arguments := PackedStringArray([
		ProjectSettings.globalize_path(_helper_path()),
		"--project-root",
		ProjectSettings.globalize_path("res://"),
		"--output-dir",
		ProjectSettings.globalize_path(output_path),
		psd_path,
	])
	if not _include_groups_check.button_pressed:
		arguments.append("--exclude-groups")
	if _skip_hidden_check.button_pressed:
		arguments.append("--skip-hidden")
	if _sequential_index_check.button_pressed:
		arguments.append("--sequential-index")
	if _group_nodes_check.button_pressed:
		arguments.append("--group-nodes")
	if _clear_output_check.button_pressed:
		arguments.append("--clear-output")
	if _pad_to_canvas_check.button_pressed:
		arguments.append("--pad-to-canvas")
	_start_command("import", arguments)


func _helper_path() -> String:
	return get_script().resource_path.get_base_dir().path_join(HELPER_FILENAME)


func _validate_python() -> bool:
	if _python_edit.text.strip_edges().is_empty():
		_set_status("Enter a Python executable, such as python3 or C:\\Python312\\python.exe.")
		return false
	return true


func _start_command(kind: String, arguments: PackedStringArray) -> void:
	if _thread != null:
		return

	_set_busy(true)
	_set_status(
		"Checking dependencies… Missing packages will be installed automatically."
		if kind == "check"
		else "Importing layers… Missing packages will be installed automatically."
	)
	_last_scene_path = ""
	_open_button.visible = false

	_thread = Thread.new()
	var error := _thread.start(
		_execute_command.bind(
			kind,
			_python_edit.text.strip_edges(),
			arguments
		)
	)
	if error != OK:
		_thread = null
		_set_busy(false)
		_set_status("Could not start the importer thread (error %d)." % error)


func _execute_command(
	kind: String,
	executable: String,
	arguments: PackedStringArray
) -> void:
	var output: Array = []
	var exit_code := OS.execute(executable, arguments, output, true)
	var combined_output := ""
	for chunk in output:
		combined_output += str(chunk)
	if not _shutting_down:
		call_deferred("_command_finished", kind, exit_code, combined_output)


func _command_finished(kind: String, exit_code: int, output: String) -> void:
	if _thread != null:
		_thread.wait_to_finish()
		_thread = null
	if _shutting_down:
		return

	_set_busy(false)
	if exit_code != 0:
		var message := output.strip_edges()
		if message.is_empty():
			message = (
				"Could not run '%s'. Set the full path to a Python executable."
				% _python_edit.text.strip_edges()
			)
		_set_status(
			"Setup check failed:\n%s" % message
			if kind == "check"
			else "Import failed:\n%s" % message
		)
		return

	if kind == "check":
		_set_status("Setup is ready.\n%s" % output.strip_edges())
		return

	var generated_summary := ""
	var notices := PackedStringArray()
	for line in output.split("\n"):
		if line.begins_with("SCENE_PATH="):
			_last_scene_path = line.trim_prefix("SCENE_PATH=").strip_edges()
		elif line.begins_with("Generated "):
			generated_summary = line.strip_edges()
		elif line.begins_with("Skipping ") or line.begins_with("Could not render "):
			notices.append(line.strip_edges())

	_editor_interface.get_resource_filesystem().scan()
	_open_button.visible = not _last_scene_path.is_empty()
	var status_message := "Import completed."
	if not generated_summary.is_empty():
		status_message += "\n%s" % generated_summary
	if not _last_scene_path.is_empty():
		status_message += "\nScene: %s" % _last_scene_path
	if not notices.is_empty():
		status_message += "\n\nNotices:\n%s" % "\n".join(notices)
	_set_status(status_message)


func _set_busy(busy: bool) -> void:
	_check_button.disabled = busy
	_import_button.disabled = busy
	_include_groups_check.disabled = busy
	_skip_hidden_check.disabled = busy
	_sequential_index_check.disabled = busy
	_group_nodes_check.disabled = busy
	_clear_output_check.disabled = busy
	_pad_to_canvas_check.disabled = busy


func _set_status(message: String) -> void:
	_status.text = message


func _open_imported_scene() -> void:
	if _last_scene_path.is_empty():
		return
	_editor_interface.open_scene_from_path(_last_scene_path)
