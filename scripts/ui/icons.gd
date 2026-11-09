class_name Icons
extends RefCounted
## Desenhos simples dos ícones (engrenagem e troféu), feitos no código para qualquer tamanho;
## `draw_line_icon` tem a versão de linha (lateral do menu). `c` = centro, `s` = tamanho (cerca de 1/2 da largura).

const WHITE := Color.WHITE


static func draw(ci: CanvasItem, kind: String, c: Vector2, s: float, col: Color = WHITE) -> void:
	match kind:
		"gear": _gear(ci, c, s, col)
		"trophy": _trophy(ci, c, s)
		"back": _back(ci, c, s, col)


## Seta de voltar ("‹").
static func _back(ci: CanvasItem, c: Vector2, s: float, col: Color) -> void:
	var pts := PackedVector2Array([c + Vector2(s * 0.25, -s * 0.55), c + Vector2(-s * 0.3, 0), c + Vector2(s * 0.25, s * 0.55)])
	ci.draw_polyline(pts, GameStyle.INK, s * 0.42, true)
	ci.draw_polyline(pts, col, s * 0.22, true)


static func _gear(ci: CanvasItem, c: Vector2, r: float, col: Color) -> void:
	var pts := PackedVector2Array()
	var teeth := 8
	for i in teeth * 4:
		var a := TAU * i / (teeth * 4.0)
		var rr := r if (i % 4) in [0, 1] else r * 0.76
		pts.append(c + Vector2(cos(a), sin(a)) * rr)
	var outline := pts.duplicate()
	outline.append(pts[0])
	ci.draw_polyline(outline, GameStyle.INK, r * 0.28, true)
	ci.draw_colored_polygon(pts, col)
	ci.draw_circle(c, r * 0.36, GameStyle.PURPLE)
	ci.draw_arc(c, r * 0.36, 0, TAU, 20, GameStyle.INK, r * 0.1, true)


static func _trophy(ci: CanvasItem, c: Vector2, s: float) -> void:
	var gold := GameStyle.GOLD
	ci.draw_arc(c + Vector2(-s * 0.55, -s * 0.35), s * 0.3, PI * 0.5, PI * 1.5, 12, GameStyle.INK, s * 0.16, true)
	ci.draw_arc(c + Vector2(s * 0.55, -s * 0.35), s * 0.3, -PI * 0.5, PI * 0.5, 12, GameStyle.INK, s * 0.16, true)
	var cup := PackedVector2Array([c + Vector2(-s * 0.6, -s * 0.75), c + Vector2(s * 0.6, -s * 0.75),
		c + Vector2(s * 0.45, -s * 0.05), c + Vector2(0, s * 0.2), c + Vector2(-s * 0.45, -s * 0.05)])
	ci.draw_colored_polygon(cup, gold)
	var closed := cup.duplicate()
	closed.append(cup[0])
	ci.draw_polyline(closed, GameStyle.INK, s * 0.1, true)
	ci.draw_rect(Rect2(c + Vector2(-s * 0.12, s * 0.15), Vector2(s * 0.24, s * 0.35)), gold.darkened(0.2))
	var base := Rect2(c + Vector2(-s * 0.45, s * 0.48), Vector2(s * 0.9, s * 0.25))
	ci.draw_rect(base, gold)
	ci.draw_rect(base, GameStyle.INK, false, s * 0.08)
	ci.draw_colored_polygon(GameStyle.star_points(c + Vector2(0, -s * 0.4), s * 0.24, s * 0.1, 5), Color.WHITE)


## Ícones de linha (botões da lateral do menu): "games" (4 quadradinhos) e "trophy" (taça).
## `s` = metade do tamanho do ícone.
static func draw_line_icon(ci: CanvasItem, kind: String, c: Vector2, s: float) -> void:
	var w := maxf(3.0, s * 0.16)
	var col := Color.WHITE
	match kind:
		"games":
			var g := s * 0.82
			var gap := s * 0.16
			var tiles: Array[Vector2] = [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]
			for i in tiles.size():
				var t: Vector2 = tiles[i]
				var ox: float = -g - gap * 0.5 if t.x < 0 else gap * 0.5
				var oy: float = -g - gap * 0.5 if t.y < 0 else gap * 0.5
				var rect := Rect2(c + Vector2(ox, oy), Vector2(g, g))
				# o segundo quadradinho é cheio (dourado); os outros, só a borda
				var sb := _round_box(int(g * 0.3), 0, GameStyle.GOLD) if i == 1 else _round_box(int(g * 0.3), int(w), col)
				ci.draw_style_box(sb, rect)
		"trophy":
			var cup := PackedVector2Array()
			for i in 13:
				var a := PI * i / 12.0
				cup.append(c + Vector2(cos(a) * s * 0.62, -s * 0.75 + sin(a) * s * 0.95))
			cup.append(cup[0])  # fecha a boca da taça
			ci.draw_polyline(cup, col, w, true)
			ci.draw_arc(c + Vector2(-s * 0.68, -s * 0.38), s * 0.26, PI * 0.5, PI * 1.5, 10, col, w, true)
			ci.draw_arc(c + Vector2(s * 0.68, -s * 0.38), s * 0.26, -PI * 0.5, PI * 0.5, 10, col, w, true)
			ci.draw_line(c + Vector2(0, s * 0.2), c + Vector2(0, s * 0.6), col, w, true)
			ci.draw_line(c + Vector2(-s * 0.45, s * 0.75), c + Vector2(s * 0.45, s * 0.75), col, w * 1.2, true)
			ci.draw_colored_polygon(GameStyle.star_points(c + Vector2(0, -s * 0.38), s * 0.26, s * 0.11, 5), GameStyle.GOLD)


## Caixinha de cantos redondos dos ícones de linha: com `border` > 0 é só a borda; com 0 é cheia.
## Guardada para reaproveitar (o desenho roda de novo a cada toque).
static var _round_boxes: Dictionary = {}


static func _round_box(radius: int, border: int, col: Color) -> StyleBoxFlat:
	var key := "%d/%d/%s" % [radius, border, col.to_html()]
	if not _round_boxes.has(key):
		var sb := StyleBoxFlat.new()
		sb.set_corner_radius_all(radius)
		sb.anti_aliasing = true
		if border > 0:
			sb.bg_color = Color(0, 0, 0, 0)
			sb.border_color = col
			sb.set_border_width_all(border)
		else:
			sb.bg_color = col
		_round_boxes[key] = sb
	return _round_boxes[key]
