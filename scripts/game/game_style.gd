class_name GameStyle
extends RefCounted
## Visual do Poção de Cores (hub Na Lata): colorido e brilhante, com botões "de bala" (com brilho em
## cima e sombra embaixo), céu de fim de tarde no menu e noite estrelada na partida.
## Cores, letras, tema, botões e o desenho do frasco ficam aqui.

const INK := Color("2b1458")          # contorno roxo-escuro
const PAPER := Color("fff6e8")        # fundo dos cartões
const ACCENT := Color("8b45f0")       # roxo dos títulos
const GOLD := Color("ffc72e")
const GREEN := Color("5ccf2f")
const PURPLE := Color("7d43e8")
const CREAM := Color("fff1d6")
const NIGHT_TOP := Color("0d1440")
const NIGHT_BOTTOM := Color("1c2a78")
const SKY_TOP := Color("6a5ad8")
const SKY_BOTTOM := Color("ffc58a")
const GLASS := Color(0.55, 0.75, 1.0, 0.16)
const GLASS_EDGE := Color("9fd0ff")
const HIDDEN_LAYER := Color("15122e")  # camada escondida ("?")
## Cores da dificuldade nos quadradinhos do menu.
const DIFFICULTY_COLORS := {Rules.EASY: Color("6bd43c"), Rules.MEDIUM: Color("ffb52e"), Rules.HARD: Color("ff5a6e")}

## Cores das poções, na ordem dos números usados nos desafios.
const LIQUIDS: Array[Color] = [
	Color("e8322c"),  # 0 Rubi
	Color("2b5ce6"),  # 1 Safira
	Color("f27bd6"),  # 2 Fada
	Color("8bc53a"),  # 3 Musgo
	Color("f5c233"),  # 4 Sol
	Color("ec6a25"),  # 5 Brasa
	Color("8a86d6"),  # 6 Lavanda (só nos níveis mais altos)
]
const LIQUID_NAMES: Array[String] = ["Rubi", "Safira", "Fada", "Musgo", "Sol", "Brasa", "Lavanda"]
## Os desafios do dia usam só as 6 primeiras cores (assim continuam iguais aos já sorteados).
const DAILY_LIQUIDS: int = 6

const TITLE_FONT_PATH := "res://assets/fonts/LilitaOne-Regular.ttf"
const BODY_FONT_PATH := "res://assets/fonts/Nunito-Variable.ttf"

# Frasco desenhado numa grade de 60 x 160.
const DESIGN_SIZE := Vector2(60, 160)
const LIQUID_TOP: float = 46.0
const LIQUID_BOTTOM: float = 152.0


static func liquid_color(index: int) -> Color:
	return LIQUIDS[index % LIQUIDS.size()]


static func title_font() -> Font:
	return load(TITLE_FONT_PATH)


static func body_font(weight: int = 800) -> Font:
	var v := FontVariation.new()
	v.base_font = load(BODY_FONT_PATH)
	v.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): weight}
	return v


## Contorno do frasco de poção: gargalo curto com borda, ombros redondos e corpo reto, na grade 60 x 160.
static func bottle_outline() -> PackedVector2Array:
	var p := PackedVector2Array()
	p.append(Vector2(19, 4))
	p.append(Vector2(41, 4))
	p.append(Vector2(41, 12))
	p.append(Vector2(38, 14))
	p.append(Vector2(38, 22))
	_cubic(p, Vector2(38, 22), Vector2(38, 30), Vector2(55, 30), Vector2(55, 42))
	p.append(Vector2(55, 140))
	_quad(p, Vector2(55, 140), Vector2(55, 154), Vector2(41, 154))
	p.append(Vector2(19, 154))
	_quad(p, Vector2(19, 154), Vector2(5, 154), Vector2(5, 140))
	p.append(Vector2(5, 42))
	_cubic(p, Vector2(5, 42), Vector2(5, 30), Vector2(22, 30), Vector2(22, 22))
	p.append(Vector2(22, 14))
	p.append(Vector2(19, 12))
	return p


## Altura de cada camada de líquido na grade 60 x 160.
static func layer_height(capacity: int) -> float:
	return (LIQUID_BOTTOM - LIQUID_TOP) / float(capacity)


## Faixa de líquido entre duas alturas (grade 60 x 160), recortada pelo formato do frasco.
static func band_polygons(y_top: float, y_bottom: float) -> Array[PackedVector2Array]:
	var band := PackedVector2Array([Vector2(0, y_top), Vector2(60, y_top), Vector2(60, y_bottom), Vector2(0, y_bottom)])
	return Geometry2D.intersect_polygons(band, bottle_outline())


## Fundo animado ocupando a tela toda: "sky" (céu do menu) ou "night" (noite da partida).
static func add_background(parent: Control, kind: String = "sky") -> SceneBackground:
	var bg := SceneBackground.new()
	bg.kind = kind
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(bg)
	return bg


static func make_label(text: String, font_size: int, title: bool = false, color: Color = INK) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	if title:
		l.add_theme_font_override("font", title_font())
	return l


## Título branco com contorno roxo (como nas placas dos exemplos).
static func make_title(text: String, font_size: int, color: Color = Color.WHITE) -> Label:
	var l := make_label(text, font_size, true, color)
	l.add_theme_color_override("font_outline_color", INK)
	l.add_theme_constant_override("outline_size", maxi(6, font_size / 7))
	l.add_theme_color_override("font_shadow_color", Color(INK, 0.6))
	l.add_theme_constant_override("shadow_offset_x", 0)
	l.add_theme_constant_override("shadow_offset_y", maxi(3, font_size / 16))
	return l


## Botão "de bala". main = verde (ação principal); senão roxo. color força outra cor.
static func make_button(text: String, main: bool = false, font_size: int = 30, color: Color = Color(0, 0, 0, 0)) -> GlossButton:
	var b := GlossButton.new()
	b.text = text
	b.fill = color if color.a > 0.0 else (GREEN if main else PURPLE)
	b.add_theme_font_size_override("font_size", font_size)
	b.add_theme_font_override("font", title_font())
	return b


## Tema: letras, cores e caixas. Os botões comuns (Button) também ganham o visual roxo.
static func build_theme() -> Theme:
	var t := Theme.new()
	t.default_font = body_font(800)
	t.default_font_size = 28
	t.set_color("font_color", "Label", INK)
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		t.set_stylebox(state, "Button", _flat_button_box(state))
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		t.set_color(c, "Button", Color.WHITE)
	t.set_color("font_disabled_color", "Button", Color(1, 1, 1, 0.55))
	t.set_color("font_outline_color", "Button", INK)
	t.set_constant("outline_size", "Button", 8)
	t.set_stylebox("panel", "PanelContainer", card_box())
	return t


static func card_box() -> StyleBoxFlat:
	var b := StyleBoxFlat.new()
	b.bg_color = PAPER
	b.border_color = INK
	b.set_border_width_all(5)
	b.set_corner_radius_all(30)
	b.set_content_margin_all(16)
	b.shadow_color = Color(0, 0, 0, 0.25)
	b.shadow_size = 8
	b.shadow_offset = Vector2(0, 6)
	return b


## Placa escura com borda roxa (ex.: "Nível 32" na partida).
static func plate_box() -> StyleBoxFlat:
	var b := StyleBoxFlat.new()
	b.bg_color = Color("1a1a4a")
	b.border_color = Color("8a5cff")
	b.set_border_width_all(5)
	b.set_corner_radius_all(26)
	b.content_margin_left = 40
	b.content_margin_right = 40
	b.content_margin_top = 8
	b.content_margin_bottom = 8
	b.shadow_color = Color(0, 0, 0, 0.35)
	b.shadow_size = 6
	b.shadow_offset = Vector2(0, 5)
	return b


## Pílula creme dos contadores (moedas, pontos).
static func pill_box() -> StyleBoxFlat:
	var b := StyleBoxFlat.new()
	b.bg_color = CREAM
	b.border_color = Color("c99a5b")
	b.set_border_width_all(3)
	b.set_corner_radius_all(24)
	b.content_margin_left = 54
	b.content_margin_right = 24
	b.content_margin_top = 4
	b.content_margin_bottom = 4
	b.shadow_color = Color(0, 0, 0, 0.25)
	b.shadow_size = 4
	b.shadow_offset = Vector2(0, 4)
	return b


static func _flat_button_box(state: String) -> StyleBox:
	var b := StyleBoxFlat.new()
	b.bg_color = PURPLE.lightened(0.08) if state == "hover" else PURPLE
	if state == "disabled":
		b.bg_color = Color(PURPLE, 0.5)
	b.border_color = INK
	b.set_border_width_all(4)
	b.border_width_bottom = 4 if state == "pressed" else 9
	b.set_corner_radius_all(24)
	b.content_margin_left = 22
	b.content_margin_right = 22
	b.content_margin_top = 12 + (5 if state == "pressed" else 0)
	b.content_margin_bottom = 12
	if state == "focus":
		b.draw_center = false
		b.border_color = Color(INK, 0.0)
	return b


## Polígono com cor por vértice: degradê vertical num retângulo.
static func draw_vertical_gradient(ci: CanvasItem, rect: Rect2, top: Color, bottom: Color) -> void:
	ci.draw_polygon(
		PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]),
		PackedColorArray([top, top, bottom, bottom]))


## Moeda dourada com estrela (contador de pontos).
static func draw_coin(ci: CanvasItem, c: Vector2, r: float) -> void:
	ci.draw_circle(c + Vector2(0, r * 0.12), r, Color("c4801a"))
	ci.draw_circle(c, r, GOLD)
	ci.draw_circle(c, r * 0.74, Color("ffdb5c"))
	ci.draw_colored_polygon(star_points(c, r * 0.5, r * 0.22, 5), Color("e59a12"))
	ci.draw_arc(c, r, 0, TAU, 32, Color("8a5208"), maxf(2.0, r * 0.1), true)


static func star_points(c: Vector2, outer: float, inner: float, tips: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in tips * 2:
		var a := -PI / 2 + PI * i / tips
		pts.append(c + Vector2(cos(a), sin(a)) * (outer if i % 2 == 0 else inner))
	return pts


static func _cubic(out: PackedVector2Array, a: Vector2, b: Vector2, c: Vector2, d: Vector2, steps: int = 10) -> void:
	for i in range(1, steps + 1):
		out.append(a.bezier_interpolate(b, c, d, float(i) / steps))


static func _quad(out: PackedVector2Array, a: Vector2, b: Vector2, c: Vector2, steps: int = 6) -> void:
	for i in range(1, steps + 1):
		var t: float = float(i) / steps
		out.append(a.lerp(b, t).lerp(b.lerp(c, t), t))
