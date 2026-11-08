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
	draw_icon(self, icon_kind, c, r * 0.48)
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


## Ícones de linha: "games" (4 quadradinhos), "trophy" (taça), "calendar" (calendário com visto).
## `s` = metade do tamanho do ícone.
static func draw_icon(ci: CanvasItem, kind: String, c: Vector2, s: float) -> void:
	var w := maxf(3.0, s * 0.16)
	var col := Color.WHITE
	match kind:
		"games":
			var g := s * 0.82
			var gap := s * 0.16
			var tiles := [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]
			for i in tiles.size():
				var t: Vector2 = tiles[i]
				var ox: float = -g - gap * 0.5 if t.x < 0 else gap * 0.5
				var oy: float = -g - gap * 0.5 if t.y < 0 else gap * 0.5
				var rect := Rect2(c + Vector2(ox, oy), Vector2(g, g))
				var sb := StyleBoxFlat.new()
				sb.set_corner_radius_all(int(g * 0.3))
				sb.anti_aliasing = true
				if i == 1:
					sb.bg_color = GameStyle.GOLD
				else:
					sb.bg_color = Color(0, 0, 0, 0)
					sb.border_color = col
					sb.set_border_width_all(int(w))
				ci.draw_style_box(sb, rect)
		"trophy":
			var top := c + Vector2(0, -s * 0.75)
			var cup := PackedVector2Array()
			for i in 13:
				var a := PI * i / 12.0
				cup.append(c + Vector2(cos(a) * s * 0.62, -s * 0.75 + sin(a) * s * 0.95))
			cup.append(cup[0])
			ci.draw_polyline(cup, col, w, true)
			ci.draw_line(top + Vector2(-s * 0.62, 0), top + Vector2(s * 0.62, 0), col, w, true)
			ci.draw_arc(c + Vector2(-s * 0.68, -s * 0.38), s * 0.26, PI * 0.5, PI * 1.5, 10, col, w, true)
			ci.draw_arc(c + Vector2(s * 0.68, -s * 0.38), s * 0.26, -PI * 0.5, PI * 0.5, 10, col, w, true)
			ci.draw_line(c + Vector2(0, s * 0.2), c + Vector2(0, s * 0.6), col, w, true)
			ci.draw_line(c + Vector2(-s * 0.45, s * 0.75), c + Vector2(s * 0.45, s * 0.75), col, w * 1.2, true)
			ci.draw_colored_polygon(GameStyle.star_points(c + Vector2(0, -s * 0.38), s * 0.26, s * 0.11, 5), GameStyle.GOLD)
		"calendar":
			var rect := Rect2(c + Vector2(-s * 0.85, -s * 0.65), Vector2(s * 1.7, s * 1.5))
			var sb := StyleBoxFlat.new()
			sb.bg_color = Color(0, 0, 0, 0)
			sb.border_color = col
			sb.set_border_width_all(int(w))
			sb.set_corner_radius_all(int(s * 0.3))
			sb.anti_aliasing = true
			ci.draw_style_box(sb, rect)
			ci.draw_line(rect.position + Vector2(0, s * 0.45), Vector2(rect.end.x, rect.position.y + s * 0.45), col, w, true)
			for x in [-0.4, 0.4]:
				ci.draw_line(c + Vector2(s * x, -s * 0.9), c + Vector2(s * x, -s * 0.45), col, w, true)
			ci.draw_polyline(PackedVector2Array([c + Vector2(-s * 0.4, s * 0.3), c + Vector2(-s * 0.08, s * 0.58), c + Vector2(s * 0.45, s * 0.05)]), GameStyle.GOLD, w * 1.1, true)


static func _make_counter_box() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("ff5a6e")
	sb.set_corner_radius_all(15)
	sb.border_color = GameStyle.INK
	sb.set_border_width_all(2)
	return sb
