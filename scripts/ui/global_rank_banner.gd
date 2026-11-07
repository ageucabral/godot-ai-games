class_name GlobalRankBanner
extends Button
## Faixa dourada do Ranking Global no hub Na Lata: troféu, "Ranking Global", "Vale prêmios!",
## quanto falta para o mês acabar e os pontos do jogador somando todos os jogos.
## Tem um brilho que passa de tempos em tempos e o troféu balança de leve.

var points: int = 0:
	set(value):
		points = value
		queue_redraw()
var countdown: String = "":
	set(value):
		countdown = value
		queue_redraw()
var _time: float = 0.0
## Caixas do desenho: criadas uma vez (a faixa redesenha a cada quadro por causa do brilho).
var _boxes: Dictionary = _make_boxes()


func _init() -> void:
	flat = true
	focus_mode = Control.FOCUS_NONE
	custom_minimum_size = Vector2(0, 210)


func _process(delta: float) -> void:
	if is_visible_in_tree():
		_time += delta
		queue_redraw()


func _draw() -> void:
	var sink := 6.0 if is_pressed() else 0.0
	var r := Rect2(Vector2(0, sink), Vector2(size.x, size.y - 12))
	draw_style_box(_boxes.shadow, Rect2(Vector2(0, 12), Vector2(size.x, size.y - 12)))
	draw_style_box(_boxes.base, r)
	var body := Rect2(r.position + Vector2(6, 6), r.size - Vector2(12, 18))
	draw_style_box(_boxes.body, body)
	draw_style_box(_boxes.top, Rect2(body.position + Vector2(8, 6), Vector2(body.size.x - 16, body.size.y * 0.45)))
	_draw_shine(body)

	# troféu num círculo
	var c := Vector2(body.position.x + 92, body.get_center().y + sin(_time * 2.2) * 4.0)
	draw_circle(c + Vector2(0, 5), 66, Color(0, 0, 0, 0.2))
	draw_circle(c, 66, GameStyle.INK)
	draw_circle(c, 60, Color("ff8a1f"))
	draw_circle(c, 50, Color("7a2fd6"))
	draw_circle(c + Vector2(0, -14), 38, Color(1, 1, 1, 0.12))
	Icons.draw(self, "trophy", c + Vector2(0, 4), 42.0)
	for i in 3:
		var a := _time * 1.4 + i * TAU / 3.0
		var p := c + Vector2(cos(a), sin(a)) * 74.0
		var tw := 0.5 + 0.5 * sin(_time * 3.0 + i)
		draw_colored_polygon(GameStyle.star_points(p, 9.0 + 5.0 * tw, 3.0, 4), Color(1, 1, 1, 0.6 + 0.4 * tw))

	# textos
	var font := GameStyle.title_font()
	var x := c.x + 84
	var w := body.end.x - x - 20
	_outlined(font, Vector2(x, body.position.y + 66), tr("Ranking Global"), w, 50, Color.WHITE, 11)
	_outlined(font, Vector2(x, body.position.y + 106), tr("Vale prêmios!"), w, 30, Color("fff3a8"), 8)
	var pill := Rect2(Vector2(x, body.end.y - 66), Vector2(w, 52))
	draw_style_box(_boxes.pill, pill)
	var line := tr("%d pts") % points
	if countdown != "":
		line = "%s  ·  %s" % [line, countdown]
	draw_string(GameStyle.title_font(), pill.position + Vector2(0, 37), line, HORIZONTAL_ALIGNMENT_CENTER, pill.size.x, 28, GameStyle.INK)


## Faixa de luz inclinada que atravessa a faixa a cada 3,5 s.
func _draw_shine(body: Rect2) -> void:
	var t := fmod(_time, 3.5) / 1.2
	if t > 1.0:
		return
	var x := lerpf(body.position.x + 16, body.end.x - 116, t)
	var pts := PackedVector2Array([
		Vector2(x + 50, body.position.y + 8), Vector2(x + 100, body.position.y + 8),
		Vector2(x + 50, body.end.y - 8), Vector2(x, body.end.y - 8)])
	draw_colored_polygon(pts, Color(1, 1, 1, 0.28 * sin(t * PI)))


func _outlined(font: Font, pos: Vector2, text_value: String, width: float, font_size: int, col: Color, outline: int) -> void:
	draw_string_outline(font, pos, text_value, HORIZONTAL_ALIGNMENT_LEFT, width, font_size, outline, GameStyle.INK)
	draw_string(font, pos, text_value, HORIZONTAL_ALIGNMENT_LEFT, width, font_size, col)


static func _make_boxes() -> Dictionary:
	var shadow := StyleBoxFlat.new()
	shadow.bg_color = Color(0, 0, 0, 0.3)
	shadow.set_corner_radius_all(38)
	var base := StyleBoxFlat.new()
	base.bg_color = Color("b35a0c")
	base.border_color = GameStyle.INK
	base.set_border_width_all(5)
	base.set_corner_radius_all(38)
	var body := StyleBoxFlat.new()
	body.bg_color = Color("ffab1f")
	body.set_corner_radius_all(32)
	var top := StyleBoxFlat.new()
	top.bg_color = Color("ffd24a")
	top.set_corner_radius_all(28)
	var pill := StyleBoxFlat.new()
	pill.bg_color = GameStyle.CREAM
	pill.border_color = GameStyle.INK
	pill.set_border_width_all(3)
	pill.set_corner_radius_all(24)
	return {"shadow": shadow, "base": base, "body": body, "top": top, "pill": pill}
