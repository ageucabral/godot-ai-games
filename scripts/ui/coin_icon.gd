class_name CoinIcon
extends Control
## Moedinha dourada com estrela (ao lado dos pontos).

var radius: float = 24.0


func _init(r: float = 24.0) -> void:
	radius = r
	custom_minimum_size = Vector2(r * 2 + 4, r * 2 + 6)
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	GameStyle.draw_coin(self, Vector2(radius + 2, radius + 2), radius)
