class_name Icons
extends RefCounted
## Desenhos simples dos ícones (engrenagem, troféu, casa, calendário, jogos, perfil, pódio),
## feitos no código para qualquer tamanho; `draw_line_icon` tem a versão de linha (lateral do menu). `c` = centro, `s` = tamanho (cerca de 1/2 da largura).

const WHITE := Color.WHITE


static func draw(ci: CanvasItem, kind: String, c: Vector2, s: float, col: Color = WHITE) -> void:
	match kind:
		"gear": _gear(ci, c, s, col)
		"trophy": _trophy(ci, c, s)
		"home": _home(ci, c, s)
		"calendar": _calendar(ci, c, s)
		"games": _games(ci, c, s)
		"avatar": _avatar(ci, c, s)
		"podium": _podium(ci, c, s)


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


static func _home(ci: CanvasItem, c: Vector2, s: float) -> void:
	var walls := Rect2(c + Vector2(-s * 0.55, -s * 0.15), Vector2(s * 1.1, s * 0.85))
	ci.draw_rect(walls, Color("ffe6a8"))
	ci.draw_rect(walls, GameStyle.INK, false, s * 0.09)
	var roof := PackedVector2Array([c + Vector2(-s * 0.8, -s * 0.1), c + Vector2(0, -s * 0.85), c + Vector2(s * 0.8, -s * 0.1)])
	ci.draw_colored_polygon(roof, Color("a05ff5"))
	var closed := roof.duplicate()
	closed.append(roof[0])
	ci.draw_polyline(closed, GameStyle.INK, s * 0.09, true)
	ci.draw_rect(Rect2(c + Vector2(-s * 0.16, s * 0.25), Vector2(s * 0.32, s * 0.45)), Color("6b3d10"))


static func _calendar(ci: CanvasItem, c: Vector2, s: float) -> void:
	var r := Rect2(c + Vector2(-s * 0.7, -s * 0.6), Vector2(s * 1.4, s * 1.3))
	ci.draw_rect(r, Color.WHITE)
	ci.draw_rect(Rect2(r.position, Vector2(r.size.x, s * 0.35)), Color("3b6fe0"))
	ci.draw_rect(r, GameStyle.INK, false, s * 0.09)
	for row in 2:
		for col in 3:
			ci.draw_rect(Rect2(r.position + Vector2(s * 0.15 + col * s * 0.42, s * 0.5 + row * s * 0.35), Vector2(s * 0.3, s * 0.24)), Color("3b6fe0"))
	for x in [-0.35, 0.35]:
		ci.draw_rect(Rect2(c + Vector2(s * x - s * 0.06, -s * 0.78), Vector2(s * 0.12, s * 0.3)), GameStyle.INK)


static func _games(ci: CanvasItem, c: Vector2, s: float) -> void:
	var cols := [GameStyle.LIQUIDS[0], GameStyle.LIQUIDS[1], GameStyle.LIQUIDS[4], GameStyle.LIQUIDS[3]]
	for i in 4:
		var p := c + Vector2((i % 2) * s * 0.75 - s * 0.68, (i / 2) * s * 0.75 - s * 0.68)
		var r := Rect2(p, Vector2(s * 0.6, s * 0.6))
		ci.draw_rect(r, cols[i])
		ci.draw_rect(r, GameStyle.INK, false, s * 0.08)


## Frasco de poção sorridente (perfil).
static func _avatar(ci: CanvasItem, c: Vector2, s: float) -> void:
	var k := s / 46.0
	var xf := Transform2D(0.0, Vector2(k, k), 0.0, c - GameStyle.DESIGN_SIZE * k * 0.5)
	ci.draw_set_transform_matrix(xf)
	var outline := GameStyle.bottle_outline()
	ci.draw_colored_polygon(outline, Color(1, 1, 1, 0.5))
	for poly in GameStyle.band_polygons(64, 152.5):
		ci.draw_colored_polygon(poly, GameStyle.LIQUIDS[2])
	ci.draw_circle(Vector2(22, 100), 6, Color.WHITE)
	ci.draw_circle(Vector2(38, 100), 6, Color.WHITE)
	ci.draw_circle(Vector2(23, 101), 3, GameStyle.INK)
	ci.draw_circle(Vector2(39, 101), 3, GameStyle.INK)
	ci.draw_arc(Vector2(30, 112), 8, 0.2, PI - 0.2, 10, GameStyle.INK, 3.5, true)
	var closed := outline.duplicate()
	closed.append(outline[0])
	ci.draw_polyline(closed, GameStyle.INK, 6.0, true)
	ci.draw_set_transform_matrix(Transform2D.IDENTITY)


static func _podium(ci: CanvasItem, c: Vector2, s: float) -> void:
	var font := GameStyle.title_font()
	var w := s * 0.62
	var blocks := [[-w * 1.5, s * 0.75, Color("b9a7f0"), "2"], [-w * 0.5, s * 1.1, GameStyle.GOLD, "1"], [w * 0.5, s * 0.55, Color("f4a261"), "3"]]
	for b in blocks:
		var r := Rect2(c + Vector2(b[0], s * 0.6 - b[1]), Vector2(w, b[1]))
		ci.draw_rect(r, b[2])
		ci.draw_rect(r, GameStyle.INK, false, s * 0.07)
		ci.draw_string(font, r.position + Vector2(0, s * 0.45), b[3], HORIZONTAL_ALIGNMENT_CENTER, w, int(s * 0.45), GameStyle.INK)


## Ícones de linha (botões da lateral do menu): "games" (4 quadradinhos), "trophy" (taça), "calendar" (calendário com visto).
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
		"calendar":
			var rect := Rect2(c + Vector2(-s * 0.85, -s * 0.65), Vector2(s * 1.7, s * 1.5))
			ci.draw_style_box(_round_box(int(s * 0.3), int(w), col), rect)
			ci.draw_line(rect.position + Vector2(0, s * 0.45), Vector2(rect.end.x, rect.position.y + s * 0.45), col, w, true)
			for x: float in [-0.4, 0.4]:
				ci.draw_line(c + Vector2(s * x, -s * 0.9), c + Vector2(s * x, -s * 0.45), col, w, true)
			ci.draw_polyline(PackedVector2Array([c + Vector2(-s * 0.4, s * 0.3), c + Vector2(-s * 0.08, s * 0.58), c + Vector2(s * 0.45, s * 0.05)]), GameStyle.GOLD, w * 1.1, true)


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
