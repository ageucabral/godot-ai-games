class_name SideButton
extends Button
## Botão redondo da lateral do menu do jogo (Jogos, Ranking, Desafios): círculo escuro translúcido
## com borda clara, ícone de linha branco (estilo moderno) e o nome embaixo. Pode mostrar um contador.

const DIAMETER: float = 104.0

var icon_kind: String = "games"
var label: String = ""
var counter: String = "":
	set(value):
		counter = value
		queue_redraw()
var _font: Font = GameStyle.title_font()
var _counter_box: StyleBoxFlat = _make_counter_box()


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
	if counter != "":
		var w := _font.get_string_size(counter, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x + 18
		var box := Rect2(Vector2(c.x + r * 0.35, c.y - r - 4), Vector2(w, 30))
		box.position.x = minf(box.position.x, size.x - w)
		draw_style_box(_counter_box, box)
		draw_string(_font, box.position + Vector2(0, 22), counter, HORIZONTAL_ALIGNMENT_CENTER, w, 20, Color.WHITE)


static func _make_counter_box() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("ff5a6e")
	sb.set_corner_radius_all(15)
	sb.border_color = GameStyle.INK
	sb.set_border_width_all(2)
	return sb
