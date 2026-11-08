class_name GlossButton
extends Button
## Botão "de bala": base escura embaixo (efeito 3D), corpo colorido, metade de cima mais clara e um brilho.
## Ao apertar, o corpo afunda. Com `pulse`, respira de leve para chamar atenção.

const DEPTH: float = 10.0

var fill: Color = GameStyle.PURPLE:
	set(value):
		fill = value
		queue_redraw()
var radius: float = -1.0  # -1 = automático (bem redondo)
## Desenha o texto (os botões só com desenho, como os de ajuda, desligam).
var show_label: bool = true
var pulse: bool = false:
	set(value):
		pulse = value
		_update_pulse()

var _pulse_tween: Tween


func _init() -> void:
	focus_mode = Control.FOCUS_NONE
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		var e := StyleBoxEmpty.new()
		e.content_margin_left = 38
		e.content_margin_right = 38
		e.content_margin_top = 14 + (DEPTH * 0.6 if state == "pressed" else 0.0)
		e.content_margin_bottom = DEPTH + 12 - (DEPTH * 0.6 if state == "pressed" else 0.0)
		add_theme_stylebox_override(state, e)
	# o Button desenha o texto ANTES do nosso _draw (ficaria escondido atrás do corpo):
	# o texto dele fica invisível e nós desenhamos o nosso por cima
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color", "font_disabled_color"]:
		add_theme_color_override(c, Color(0, 0, 0, 0))
	add_theme_constant_override("outline_size", 0)
	resized.connect(func() -> void: pivot_offset = size * 0.5)
	pressed.connect(func() -> void: Sfx.play("click", -6.0))


func _update_pulse() -> void:
	if _pulse_tween:
		_pulse_tween.kill()
		_pulse_tween = null
	scale = Vector2.ONE
	if pulse and is_inside_tree():
		_pulse_tween = create_tween().set_loops().set_trans(Tween.TRANS_SINE)
		_pulse_tween.tween_property(self, "scale", Vector2(1.04, 1.04), 0.7)
		_pulse_tween.tween_property(self, "scale", Vector2.ONE, 0.7)


func _enter_tree() -> void:
	if pulse:
		_update_pulse.call_deferred()


## Cor usada agora (apagada quando desligado).
func current_fill() -> Color:
	if disabled:
		return fill.lerp(Color("8a8aa0"), 0.65)
	if is_hovered() and not is_pressed():
		return fill.lightened(0.06)
	return fill


func _draw() -> void:
	var col := current_fill()
	var pressed := get_draw_mode() == DRAW_PRESSED or get_draw_mode() == DRAW_HOVER_PRESSED
	var sink := DEPTH * 0.6 if pressed else 0.0
	var r := radius if radius >= 0.0 else minf(30.0, size.y * 0.42)
	# sombra no chão
	draw_style_box(_box(Color(0, 0, 0, 0.22), r), Rect2(Vector2(2, 6), size))
	# base (lado escuro) com contorno
	draw_style_box(_box(col.darkened(0.45), r, 4), Rect2(Vector2.ZERO, size))
	# corpo
	var body := Rect2(Vector2(4, 4 + sink), Vector2(size.x - 8, size.y - DEPTH - 8))
	draw_style_box(_box(col, r - 3), body)
	# metade de cima mais clara
	var top := Rect2(body.position + Vector2(5, 4), Vector2(body.size.x - 10, body.size.y * 0.46))
	draw_style_box(_box(col.lightened(0.22), r - 6), top)
	# brilho
	var shine_w := minf(body.size.x * 0.22, 60.0)
	draw_style_box(_box(Color(1, 1, 1, 0.55), 6), Rect2(body.position + Vector2(r * 0.55 + 4, 7), Vector2(shine_w, 7)))
	if show_label and text != "":
		_draw_label(body)


## Texto branco com contorno escuro, centrado no corpo do botão.
func _draw_label(body: Rect2) -> void:
	var font := get_theme_font("font")
	var font_size := get_theme_font_size("font_size")
	var shown := tr(text) if auto_translate_mode != Node.AUTO_TRANSLATE_MODE_DISABLED else text
	var asc := font.get_ascent(font_size)
	var desc := font.get_descent(font_size)
	var baseline := body.position.y + (body.size.y + asc - desc) * 0.5
	var pos := Vector2(body.position.x, baseline)
	var col := Color(1, 1, 1, 0.8) if disabled else Color.WHITE
	draw_string_outline(font, pos, shown, HORIZONTAL_ALIGNMENT_CENTER, body.size.x, font_size, maxi(8, font_size / 5), GameStyle.INK)
	draw_string(font, pos, shown, HORIZONTAL_ALIGNMENT_CENTER, body.size.x, font_size, col)


static func _box(color: Color, r: float, border: int = 0) -> StyleBoxFlat:
	var b := StyleBoxFlat.new()
	b.bg_color = color
	b.set_corner_radius_all(int(maxf(r, 0.0)))
	b.anti_aliasing = true
	if border > 0:
		b.border_color = GameStyle.INK
		b.set_border_width_all(border)
	return b
