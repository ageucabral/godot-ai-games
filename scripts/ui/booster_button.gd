class_name BoosterButton
extends GlossButton
## Botão quadrado de ajuda na partida (desfazer, dica, frasco extra), com desenho e um selo no canto: o número de
## ajudas grátis (verde) ou, sem nenhuma, o ícone de vídeo (a ajuda pede propaganda), como nos jogos do gênero.

var icon_kind: String = "undo"
## Texto do selo ("2" = ajudas grátis). "" = sem selo.
var badge: String = "":
	set(value):
		badge = value
		queue_redraw()
## Selo com o ícone de vídeo (quando não há ajuda grátis).
var video_badge: bool = false:
	set(value):
		video_badge = value
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
	if icon_kind == "undo":
		# seta curva voltando para a esquerda
		draw_arc(c + Vector2(0, 4), 24, PI * 1.15, TAU + PI * 0.5, 24, GameStyle.INK, 15, true)
		draw_arc(c + Vector2(0, 4), 24, PI * 1.15, TAU + PI * 0.5, 24, white, 9, true)
		var tip := c + Vector2(0, 4) + Vector2(cos(PI * 1.15), sin(PI * 1.15)) * 24
		draw_colored_polygon(PackedVector2Array([tip + Vector2(-14, 4), tip + Vector2(10, -14), tip + Vector2(12, 8)]), white)
	elif icon_kind == "hint":
		# lâmpada acesa
		draw_circle(c + Vector2(0, -8), 24, GameStyle.INK)
		draw_circle(c + Vector2(0, -8), 19, white)
		draw_rect(Rect2(c + Vector2(-13, 10), Vector2(26, 20)), GameStyle.INK)
		draw_rect(Rect2(c + Vector2(-9, 13), Vector2(18, 7)), white)
		draw_rect(Rect2(c + Vector2(-9, 23), Vector2(18, 5)), white)
		for a in [-0.9, 0.0, 0.9]:
			var d := Vector2(sin(a), -cos(a))
			draw_line(c + Vector2(0, -8) + d * 30, c + Vector2(0, -8) + d * 40, white, 5, true)
	elif icon_kind == "bottle":
		# "+" e uma garrafinha
		var b := Rect2(c + Vector2(-2, -22), Vector2(26, 44))
		draw_rect(b.grow(3), GameStyle.INK)
		draw_rect(b, white)
		draw_rect(Rect2(b.position + Vector2(7, -10), Vector2(12, 12)), white)
		draw_rect(Rect2(c + Vector2(-30, -4), Vector2(22, 8)), white)
		draw_rect(Rect2(c + Vector2(-23, -11), Vector2(8, 22)), white)
	var bc := Vector2(size.x - 14, size.y - 22)
	if badge != "":
		draw_circle(bc, 22, GameStyle.INK)
		draw_circle(bc, 18, GameStyle.GREEN)
		draw_string(GameStyle.title_font(), bc + Vector2(-20, 9), badge, HORIZONTAL_ALIGNMENT_CENTER, 40, 24, Color.WHITE)
	elif video_badge:
		Icons.draw(self, "video", bc, 34, Color.WHITE if not disabled else Color(1, 1, 1, 0.6))
