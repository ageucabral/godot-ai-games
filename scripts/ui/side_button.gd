class_name SideButton
extends Button
## Botão redondo da lateral do menu do jogo (Jogos, Ranking): círculo escuro translúcido
## com borda clara, ícone de linha branco (estilo moderno) e o nome embaixo.

const DIAMETER: float = 104.0

var icon_kind: String = "games"
var label: String = ""
var _font: Font = GameStyle.title_font()


func _init(kind: String = "games", caption: String = "") -> void:
	icon_kind = kind
	label = caption
	flat = true
	focus_mode = Control.FOCUS_NONE
	custom_minimum_size = Vector2(DIAMETER + 30, DIAMETER + 44)


func _draw() -> void:
	var sink := 3.0 if is_pressed() else 0.0
	var c := Vector2(size.x * 0.5, DIAMETER * 0.5 + 4 + sink)
	var r := DIAMETER * 0.5
	draw_circle(c + Vector2(0, 6), r, Color(0, 0, 0, 0.25))
	draw_circle(c, r, Color("231a52", 0.86))
	draw_circle(c + Vector2(0, -r * 0.35), r * 0.62, Color(1, 1, 1, 0.06))
	draw_arc(c, r - 2, 0, TAU, 48, Color(1, 1, 1, 0.55), 3.0, true)
	Icons.draw_line_icon(self, icon_kind, c, r * 0.48)
	var text := tr(label)
	var pos := Vector2(0, DIAMETER + 34 + sink)
	draw_string_outline(_font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, size.x, 24, 7, GameStyle.INK)
	draw_string(_font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, size.x, 24, Color.WHITE)
