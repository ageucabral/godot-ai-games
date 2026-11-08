@tool
extends EditorPlugin
## Liga o plugin Android do Na Lata na exportação (código Kotlin em android/plugin).

var _export: EditorExportPlugin


func _enter_tree() -> void:
	_export = preload("res://addons/nalata_android/export_plugin.gd").new()
	add_export_plugin(_export)


func _exit_tree() -> void:
	remove_export_plugin(_export)
	_export = null
