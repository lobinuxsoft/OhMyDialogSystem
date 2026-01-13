@tool
class_name ModelExportPlugin
extends EditorExportPlugin
## Export plugin that copies GGUF models alongside the exported executable.
##
## GGUF models cannot be loaded from inside the .pck file because llama.cpp
## uses native OS file access (fopen/mmap), not Godot's virtual filesystem.
## This plugin automatically copies the models/ directory to the export location.


const MODELS_SOURCE_DIR := "res://models"


func _get_name() -> String:
	return "OhMyDialogModelExporter"


func _export_begin(features: PackedStringArray, is_debug: bool,
				   path: String, flags: int) -> void:
	# Get export directory from executable path
	var export_dir := path.get_base_dir()
	var models_dest := export_dir.path_join("models")

	# Check if source models directory exists
	if not DirAccess.dir_exists_absolute(MODELS_SOURCE_DIR):
		print("ModelExportPlugin: No models directory found at ", MODELS_SOURCE_DIR)
		return

	# Check if there are any .gguf files to copy
	var gguf_files := _get_gguf_files(MODELS_SOURCE_DIR)
	if gguf_files.is_empty():
		print("ModelExportPlugin: No .gguf files found in ", MODELS_SOURCE_DIR)
		return

	print("ModelExportPlugin: Copying ", gguf_files.size(), " model(s) to ", models_dest)

	# Create destination directory
	var err := DirAccess.make_dir_recursive_absolute(models_dest)
	if err != OK:
		push_error("ModelExportPlugin: Failed to create directory: ", models_dest)
		return

	# Copy each .gguf file
	for file_name in gguf_files:
		var src_path := MODELS_SOURCE_DIR.path_join(file_name)
		var dst_path := models_dest.path_join(file_name)

		print("ModelExportPlugin: Copying ", file_name, "...")

		if not _copy_file(src_path, dst_path):
			push_error("ModelExportPlugin: Failed to copy ", file_name)
		else:
			print("ModelExportPlugin: Copied ", file_name)

	print("ModelExportPlugin: Model export complete")


## Returns a list of .gguf files in the given directory.
func _get_gguf_files(dir_path: String) -> PackedStringArray:
	var files := PackedStringArray()
	var dir := DirAccess.open(dir_path)

	if not dir:
		return files

	dir.list_dir_begin()
	var file_name := dir.get_next()

	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".gguf"):
			files.append(file_name)
		file_name = dir.get_next()

	dir.list_dir_end()
	return files


## Copies a file from source to destination using Godot's FileAccess.
## Returns true on success, false on failure.
func _copy_file(src_path: String, dst_path: String) -> bool:
	# Use globalize_path to handle res:// paths
	var global_src := ProjectSettings.globalize_path(src_path)

	# Read source file
	var src_file := FileAccess.open(src_path, FileAccess.READ)
	if not src_file:
		push_error("ModelExportPlugin: Cannot read ", src_path, " - ", FileAccess.get_open_error())
		return false

	var file_size := src_file.get_length()

	# Open destination file
	var dst_file := FileAccess.open(dst_path, FileAccess.WRITE)
	if not dst_file:
		src_file.close()
		push_error("ModelExportPlugin: Cannot write ", dst_path, " - ", FileAccess.get_open_error())
		return false

	# Copy in chunks to avoid memory issues with large files
	const CHUNK_SIZE := 1024 * 1024 * 10  # 10 MB chunks
	var bytes_copied := 0

	while bytes_copied < file_size:
		var chunk_size := mini(CHUNK_SIZE, file_size - bytes_copied)
		var buffer := src_file.get_buffer(chunk_size)
		dst_file.store_buffer(buffer)
		bytes_copied += chunk_size

	src_file.close()
	dst_file.close()

	return true
