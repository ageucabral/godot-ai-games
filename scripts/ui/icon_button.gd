class_name IconButton
extends Button
## Botão quadrado com um desenho no meio: "gear" (configurações) ou "avatar" (perfil).

var kind: String = "gear"


func _init(icon_kind: String = "gear") -> void:
	kind = icon_kind
	custom_minimum_size = Vector2(96, 96)
	focus_mode = Control.FOCUS_NONE


func _draw() -> void:
	var c := Vector2(size.x * 0.5, size.y * 0.5 - 3)
	if kind == "gear":
		_draw_gear(c, 26.0)
	else:
		_draw_avatar(c)


func _draw_gear(c: Vector2, r: float) -> void:
	var pts := PackedVector2Array()
	var teeth := 8
	for i in teeth * 4:
		var a := TAU * i / (teeth * 4.0)
		var rr := r if (i % 4) in [0, 1] else r * 0.74
		pts.append(c + Vector2(cos(a), sin(a)) * rr)
	draw_colored_polygon(pts, TropicalStyle.INK)
	draw_circle(c, r * 0.36, TropicalStyle.PAPER)


## Mini garrafinha sorridente (o mascote).
func _draw_avatar(c: Vector2) -> void:
	var s := 0.42
	var xf := Transform2D(0.0, Vector2(s, s), 0.0, c - TropicalStyle.DESIGN_SIZE * s * 0.5)
	draw_set_transform_matrix(xf)
	var outline := TropicalStyle.bottle_outline()
	draw_colored_polygon(outline, TropicalStyle.GLASS)
	for poly in TropicalStyle.band_polygons(70, 154.5):
		draw_colored_polygon(poly, TropicalStyle.LIQUIDS[2])
	draw_circle(Vector2(23, 100), 5, Color.WHITE)
	draw_circle(Vector2(37, 100), 5, Color.WHITE)
	draw_circle(Vector2(23, 101), 2.6, TropicalStyle.INK)
	draw_circle(Vector2(37, 101), 2.6, TropicalStyle.INK)
	draw_arc(Vector2(30, 112), 7, 0.2, PI - 0.2, 10, TropicalStyle.INK, 3.0, true)
	var closed := outline.duplicate()
	closed.append(outline[0])
	draw_polyline(closed, TropicalStyle.INK, 5.0, true)
	draw_rect(Rect2(19, 0, 22, 9), TropicalStyle.ACCENT)
	draw_rect(Rect2(19, 0, 22, 9), TropicalStyle.INK, false, 4.0)
	draw_set_transform_matrix(Transform2D.IDENTITY)
