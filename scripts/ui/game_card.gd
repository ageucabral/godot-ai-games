class_name GameCard
extends Button
## Cartão de um jogo no hub Na Lata: arte do jogo, nome e "Jogar" (ou "Em breve" com cadeado).

var game_name: String = ""
var locked: bool = false
var art: String = "potion"
var _time: float = 0.0


func _init() -> void:
	flat = true
	focus_mode = Control.FOCUS_NONE
	custom_minimum_size = Vector2(0, 300)


func _process(delta: float) -> void:
	if is_visible_in_tree() and not locked:
		_time += delta
		queue_redraw()


func _draw() -> void:
	var sink := 6.0 if is_pressed() else 0.0
	var r := Rect2(Vector2(0, sink), Vector2(size.x, size.y - 12))
	var shadow := StyleBoxFlat.new()
	shadow.bg_color = Color(0, 0, 0, 0.3)
	shadow.set_corner_radius_all(36)
	draw_style_box(shadow, Rect2(Vector2(0, 12), Vector2(size.x, size.y - 12)))
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("3b2a8f") if not locked else Color("5d5878")
	sb.border_color = GameStyle.GOLD if not locked else Color("2b2840")
	sb.set_border_width_all(6)
	sb.set_corner_radius_all(36)
	draw_style_box(sb, r)
	# janela da arte
	var art_rect := Rect2(r.position + Vector2(20, 20), Vector2(r.size.x * 0.46, r.size.y - 40))
	var inner := StyleBoxFlat.new()
	inner.bg_color = GameStyle.NIGHT_TOP if not locked else Color("3a3750")
	inner.set_corner_radius_all(24)
	draw_style_box(inner, art_rect)
	if locked:
		_draw_lock(art_rect.get_center())
	else:
		_draw_potions(art_rect)
	var font := GameStyle.title_font()
	var text_x := art_rect.end.x + 20
	var text_w := r.end.x - text_x - 20
	draw_string_outline(font, Vector2(text_x, r.position.y + 90), tr(game_name), HORIZONTAL_ALIGNMENT_CENTER, text_w, 44, 10, GameStyle.INK)
	draw_string(font, Vector2(text_x, r.position.y + 90), tr(game_name), HORIZONTAL_ALIGNMENT_CENTER, text_w, 44, Color.WHITE)
	var pill := Rect2(Vector2(text_x + 10, r.end.y - 110), Vector2(text_w - 20, 80))
	var pb := StyleBoxFlat.new()
	pb.bg_color = GameStyle.GREEN if not locked else Color("7d7896")
	pb.border_color = GameStyle.INK
	pb.set_border_width_all(4)
	pb.border_width_bottom = 10
	pb.set_corner_radius_all(26)
	draw_style_box(pb, pill)
	var label := tr("Jogar") if not locked else tr("Em breve")
	draw_string_outline(font, pill.position + Vector2(0, 50), label, HORIZONTAL_ALIGNMENT_CENTER, pill.size.x, 36, 9, GameStyle.INK)
	draw_string(font, pill.position + Vector2(0, 50), label, HORIZONTAL_ALIGNMENT_CENTER, pill.size.x, 36, Color.WHITE)


func _draw_potions(area: Rect2) -> void:
	var cols := [[0, 1, 0, 2], [2, 2, 1, 4], [4, 0, 3, 3]]
	for i in 3:
		var k := area.size.y / 200.0
		var bob := sin(_time * 2.0 + i) * 5.0
		var origin := area.position + Vector2(18 + i * area.size.x * 0.3, 20 + bob)
		var xf := Transform2D(0.0, Vector2(k, k), 0.0, origin)
		draw_set_transform_matrix(xf)
		var outline := GameStyle.bottle_outline()
		draw_colored_polygon(outline, GameStyle.GLASS)
		var h := GameStyle.layer_height(4)
		for j in 4:
			var yb := GameStyle.LIQUID_BOTTOM - j * h
			for poly in GameStyle.band_polygons(yb - h, yb + 0.5):
				draw_colored_polygon(poly, GameStyle.liquid_color(cols[i][j]))
		var closed := outline.duplicate()
		closed.append(outline[0])
		draw_polyline(closed, GameStyle.GLASS_EDGE, 2.5, true)
	draw_set_transform_matrix(Transform2D.IDENTITY)


func _draw_lock(c: Vector2) -> void:
	draw_arc(c + Vector2(0, -18), 26, PI, TAU, 16, Color("cfcbe0"), 12, true)
	var body := Rect2(c + Vector2(-38, -18), Vector2(76, 62))
	draw_rect(body, Color("cfcbe0"))
	draw_rect(body, GameStyle.INK, false, 4)
	draw_circle(c + Vector2(0, 10), 8, GameStyle.INK)
