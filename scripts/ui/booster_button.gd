class_name BoosterButton
extends GlossButton
## Botão quadrado de ajuda na partida (recomeçar, embaralhar, frasco extra), com desenho e um selo vermelho.

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
	clip_text = true  # o texto escondido não pode alargar o botão


func _draw() -> void:
	super()
	var c := Vector2(size.x * 0.5, (size.y - DEPTH) * 0.5 + (DEPTH * 0.6 if is_pressed() else 0.0))
	var white := Color(1, 1, 1, 0.55 if disabled else 1.0)
	if icon_kind == "restart":
		draw_arc(c, 26, 0.6, TAU - 0.3, 24, GameStyle.INK, 15, true)
		draw_arc(c, 26, 0.6, TAU - 0.3, 24, white, 9, true)
		var tip := c + Vector2(cos(0.6), sin(0.6)) * 26
		draw_colored_polygon(PackedVector2Array([tip + Vector2(-16, -2), tip + Vector2(10, -6), tip + Vector2(0, 16)]), white)
	elif icon_kind == "shuffle":
		# duas setas que se cruzam
		for k in [-1.0, 1.0]:
			var pts := PackedVector2Array()
			for i in 13:
				var t := i / 12.0
				pts.append(c + Vector2(lerpf(-26, 22, t), k * 18.0 * cos(t * PI)))
			draw_polyline(pts, GameStyle.INK, 15, true)
			draw_polyline(pts, white, 9, true)
			var tip := c + Vector2(30, -k * 18.0)
			draw_colored_polygon(PackedVector2Array([tip, tip + Vector2(-14, -10), tip + Vector2(-14, 10)]), white)
	elif icon_kind == "bottle":
		# "+" e uma garrafinha
		var b := Rect2(c + Vector2(-2, -22), Vector2(26, 44))
		draw_rect(b.grow(3), GameStyle.INK)
		draw_rect(b, white)
		draw_rect(Rect2(b.position + Vector2(7, -10), Vector2(12, 12)), white)
		draw_rect(Rect2(c + Vector2(-30, -4), Vector2(22, 8)), white)
		draw_rect(Rect2(c + Vector2(-23, -11), Vector2(8, 22)), white)
	if badge != "":
		var bc := Vector2(size.x - 14, size.y - 22)
		draw_circle(bc, 22, GameStyle.INK)
		draw_circle(bc, 18, Color("e8324a"))
		draw_string(GameStyle.title_font(), bc + Vector2(-20, 9), badge, HORIZONTAL_ALIGNMENT_CENTER, 40, 24, Color.WHITE)
