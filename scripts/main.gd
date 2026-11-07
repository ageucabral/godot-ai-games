extends Node2D
## Cena inicial provisória. Será substituída quando o jogo definitivo começar.

@onready var label: Label = $CanvasLayer/Label


func _ready() -> void:
	label.text = build_welcome_text(Engine.get_version_info())


static func build_welcome_text(version_info: Dictionary) -> String:
	return "Projeto pronto! Godot %s.%s.%s" % [
		version_info.get("major", 0),
		version_info.get("minor", 0),
		version_info.get("patch", 0),
	]
