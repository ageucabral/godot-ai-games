class_name BoosterButton
extends GlossButton
## Botão quadrado de ajuda na partida (recomeçar, +5 jogadas), com desenho e um selo vermelho.

var icon_kind: String = "restart"
var badge: String = "":
	set(value):
		badge = value
		queue_redraw()


func _init() -> void:
	super()
	custom_minimum_size = Vector2(120, 120)
	radius = 30.0
	show_label = false  # o texto (ex.: "Recomeçar") fica só para testes: o desenho é que aparece


func _draw() -> void:
	super()
	var c := Vector2(size.x * 0.5, (size.y - DEPTH) * 0.5 + (DEPTH * 0.6 if is_pressed() else 0.0))
	var white := Color(1, 1, 1, 0.55 if disabled else 1.0)
	if icon_kind == "restart":
		draw_arc(c, 26, 0.6, TAU - 0.3, 24, GameStyle.INK, 15, true)
		draw_arc(c, 26, 0.6, TAU - 0.3, 24, white, 9, true)
		var tip := c + Vector2(cos(0.6), sin(0.6)) * 26
		draw_colored_polygon(PackedVector2Array([tip + Vector2(-16, -2), tip + Vector2(10, -6), tip + Vector2(0, 16)]), white)
	else:
		var font := GameStyle.title_font()
		draw_string_outline(font, c + Vector2(-50, 16), "+5", HORIZONTAL_ALIGNMENT_CENTER, 100, 48, 12, GameStyle.INK)
		draw_string(font, c + Vector2(-50, 16), "+5", HORIZONTAL_ALIGNMENT_CENTER, 100, 48, white)
	if badge != "":
		var bc := Vector2(size.x - 14, size.y - 22)
		draw_circle(bc, 22, GameStyle.INK)
		draw_circle(bc, 18, Color("e8324a"))
		draw_string(GameStyle.title_font(), bc + Vector2(-20, 9), badge, HORIZONTAL_ALIGNMENT_CENTER, 40, 24, Color.WHITE)
