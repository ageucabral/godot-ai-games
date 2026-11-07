class_name IconButton
extends GlossButton
## Botão quadrado roxo e brilhante com um ícone no meio ("gear", "avatar"...).

var kind: String = "gear"


func _init(icon_kind: String = "gear") -> void:
	super()
	kind = icon_kind
	custom_minimum_size = Vector2(100, 100)
	radius = 26.0


func _draw() -> void:
	super()
	var sink := DEPTH * 0.6 if is_pressed() else 0.0
	Icons.draw(self, kind, Vector2(size.x * 0.5, (size.y - DEPTH) * 0.5 + sink), 30.0)
