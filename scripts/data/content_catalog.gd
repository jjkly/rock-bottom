extends RefCounted
## ============================================================================
## ContentCatalog — list .tres content in a res:// directory, editor or export.
##
## In an exported PCK, DirAccess returns "lean_tuna.tres.remap"; in the editor
## it returns "lean_tuna.tres". Strip the remap suffix before filtering so the
## same code works in both.
## ============================================================================


static func tres_files(dir_path: String) -> PackedStringArray:
	var out := PackedStringArray()
	for file in DirAccess.get_files_at(dir_path):
		var name := String(file).trim_suffix(".remap")
		if name.ends_with(".tres") and not out.has(name):
			out.append(name)
	return out
