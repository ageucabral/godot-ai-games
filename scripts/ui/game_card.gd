class_name GameCard
extends Button
## Cartão de um jogo no hub Na Lata: arte do jogo, nome e "Jogar" (ou "Em breve" com cadeado).

var game_name: String = ""
## Bloqueado ("Em breve"): também fica desligado, para não afundar ao ser tocado sem fazer nada.
var locked: bool = false:
	set(value):
		locked = value
		disabled = value
		queue_redraw()
## Ilustração do jogo (vazio = desenho dos frascos feito no código).
var art_path: String = "":
	set(value):
		art_path = value
		_art = load(value) if value != "" and ResourceLoader.exists(value) else null
		queue_redraw()
var _art: Texture2D
var _time: float = 0.0
## Caixas do desenho: criadas uma vez (o cartão liberado redesenha a cada quadro).
var _boxes: Dictionary = {}


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
	if _boxes.is_empty() or _boxes.locked != locked:
		_boxes = _make_boxes(locked)
	draw_style_box(_boxes.shadow, Rect2(Vector2(0, 12), Vector2(size.x, size.y - 12)))
	draw_style_box(_boxes.card, r)
	# janela da arte
	var art_rect := Rect2(r.position + Vector2(20, 20), Vector2(r.size.x * 0.46, r.size.y - 40))
	draw_style_box(_boxes.inner, art_rect)
	if locked:
		_draw_lock(art_rect.get_center())
	elif _art:
		_draw_art(art_rect)
	else:
		_draw_potions(art_rect)
	var font := GameStyle.title_font()
	var text_x := art_rect.end.x + 20
	var text_w := r.end.x - text_x - 20
	draw_string_outline(font, Vector2(text_x, r.position.y + 90), tr(game_name), HORIZONTAL_ALIGNMENT_CENTER, text_w, 44, 10, GameStyle.INK)
	draw_string(font, Vector2(text_x, r.position.y + 90), tr(game_name), HORIZONTAL_ALIGNMENT_CENTER, text_w, 44, Color.WHITE)
	var pill := Rect2(Vector2(text_x + 10, r.end.y - 110), Vector2(text_w - 20, 80))
	draw_style_box(_boxes.pill, pill)
	var label := tr("Jogar") if not locked else tr("Em breve")
	draw_string_outline(font, pill.position + Vector2(0, 50), label, HORIZONTAL_ALIGNMENT_CENTER, pill.size.x, 36, 9, GameStyle.INK)
	draw_string(font, pill.position + Vector2(0, 50), label, HORIZONTAL_ALIGNMENT_CENTER, pill.size.x, 36, Color.WHITE)


static func _make_boxes(is_locked: bool) -> Dictionary:
	var shadow := StyleBoxFlat.new()
	shadow.bg_color = Color(0, 0, 0, 0.3)
	shadow.set_corner_radius_all(36)
	var card := StyleBoxFlat.new()
	card.bg_color = Color("3b2a8f") if not is_locked else Color("5d5878")
	card.border_color = GameStyle.GOLD if not is_locked else Color("2b2840")
	card.set_border_width_all(6)
	card.set_corner_radius_all(36)
	var inner := StyleBoxFlat.new()
	inner.bg_color = GameStyle.NIGHT_TOP if not is_locked else Color("3a3750")
	inner.set_corner_radius_all(24)
	var pill := StyleBoxFlat.new()
	pill.bg_color = GameStyle.GREEN if not is_locked else Color("7d7896")
	pill.border_color = GameStyle.INK
	pill.set_border_width_all(4)
	pill.border_width_bottom = 10
	pill.set_corner_radius_all(26)
	return {"locked": is_locked, "shadow": shadow, "card": card, "inner": inner, "pill": pill}


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


## Ilustração recortada com cantos redondos e brilhinhos subindo por cima.
func _draw_art(area: Rect2) -> void:
	var pts := _rounded_rect(area, 24.0)
	var uvs := PackedVector2Array()
	for p in pts:
		uvs.append((p - area.position) / area.size)
	# a arte é quadrada: mostra o meio dela na janela (sem deformar)
	var k := area.size / maxf(area.size.x, area.size.y)
	for i in uvs.size():
		uvs[i] = Vector2(0.5, 0.5) + (uvs[i] - Vector2(0.5, 0.5)) * k
	draw_colored_polygon(pts, Color.WHITE, uvs, _art)
	for i in 5:
		var tt := fmod(_time * 0.35 + i * 0.2, 1.0)
		var p := area.position + Vector2(area.size.x * (0.15 + 0.17 * i), area.size.y * (0.85 - tt * 0.7))
		var a := sin(tt * PI)
		draw_colored_polygon(GameStyle.star_points(p, 9.0 * a + 2.0, 2.5, 4), Color(1, 1, 0.85, 0.85 * a))


static func _rounded_rect(r: Rect2, rad: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var corners := [[r.end - Vector2(rad, rad), 0.0], [Vector2(r.position.x + rad, r.end.y - rad), PI * 0.5],
		[r.position + Vector2(rad, rad), PI], [Vector2(r.end.x - rad, r.position.y + rad), PI * 1.5]]
	for c in corners:
		for j in 7:
			var a: float = c[1] + PI * 0.5 * j / 6.0
			pts.append(c[0] + Vector2(cos(a), sin(a)) * rad)
	return pts


func _draw_lock(c: Vector2) -> void:
	draw_arc(c + Vector2(0, -18), 26, PI, TAU, 16, Color("cfcbe0"), 12, true)
	var body := Rect2(c + Vector2(-38, -18), Vector2(76, 62))
	draw_rect(body, Color("cfcbe0"))
	draw_rect(body, GameStyle.INK, false, 4)
	draw_circle(c + Vector2(0, 10), 8, GameStyle.INK)
