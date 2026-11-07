class_name PodiumButton
extends Button
## Botão do ranking: um pódio 2-1-3 desenhado, com a contagem até o fim do mês embaixo.

var countdown: String = "":
	set(value):
		countdown = value
		queue_redraw()


func _init() -> void:
	custom_minimum_size = Vector2(150, 150)
	flat = true
	focus_mode = Control.FOCUS_NONE


func _draw() -> void:
	var font := TropicalStyle.title_font()
	var base_y := 96.0
	# [x, altura, cor, número]
	var blocks := [[22.0, 46.0, Color("b9a7f0"), "2"], [56.0, 66.0, Color("ffc93a"), "1"], [90.0, 36.0, Color("f4a261"), "3"]]
	for b in blocks:
		var r := Rect2(b[0], base_y - b[1], 38, b[1])
		draw_rect(r, b[2])
		draw_rect(r, TropicalStyle.INK, false, 3.0)
		draw_string(font, Vector2(b[0], base_y - b[1] + 30), b[3], HORIZONTAL_ALIGNMENT_CENTER, 38, 26, TropicalStyle.INK)
	if countdown != "":
		var pill := Rect2(6, base_y + 8, 138, 40)
		draw_style_box(_pill_box(), pill)
		draw_string(TropicalStyle.body_font(800), Vector2(6, base_y + 37), countdown, HORIZONTAL_ALIGNMENT_CENTER, 138, 22, Color.WHITE)


static func _pill_box() -> StyleBoxFlat:
	var b := StyleBoxFlat.new()
	b.bg_color = Color(TropicalStyle.INK, 0.85)
	b.set_corner_radius_all(20)
	return b
