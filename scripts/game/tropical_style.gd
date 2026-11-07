class_name TropicalStyle
extends RefCounted
## Estilo visual "Feira Tropical": cores, letras, tema dos botões e o desenho da garrafinha.

const INK := Color("3a2213")          # contorno marrom-escuro
const PAPER := Color("fff8e6")        # fundo dos cartões
const SAND := Color("ffe7b0")         # fundo da tela
const ACCENT := Color("e8432f")       # vermelho dos botões principais
const GLASS := Color(1, 1, 1, 0.55)

## Cores dos líquidos, na ordem dos números usados nos desafios.
const LIQUIDS: Array[Color] = [
	Color("e63946"),  # 0 Acerola
	Color("2a9d8f"),  # 1 Hortelã
	Color("f4a261"),  # 2 Manga
	Color("6a4c93"),  # 3 Uva
	Color("8ac926"),  # 4 Limão
	Color("1d5fa8"),  # 5 Anil
]
const LIQUID_NAMES: Array[String] = ["Acerola", "Hortelã", "Manga", "Uva", "Limão", "Anil"]

const TITLE_FONT_PATH := "res://assets/fonts/LilitaOne-Regular.ttf"
const BODY_FONT_PATH := "res://assets/fonts/Nunito-Variable.ttf"

# Garrafinha desenhada numa grade de 60 x 160 (mesma do painel de estilos).
const DESIGN_SIZE := Vector2(60, 160)
const LIQUID_TOP: float = 58.0
const LIQUID_BOTTOM: float = 154.0


static func liquid_color(index: int) -> Color:
	return LIQUIDS[index % LIQUIDS.size()]


static func title_font() -> Font:
	return load(TITLE_FONT_PATH)


static func body_font(weight: int = 800) -> Font:
	var v := FontVariation.new()
	v.base_font = load(BODY_FONT_PATH)
	v.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): weight}
	return v


## Contorno da garrafinha (pescoço, ombros arredondados e corpo), na grade 60 x 160.
static func bottle_outline() -> PackedVector2Array:
	var p := PackedVector2Array()
	p.append(Vector2(22, 6))
	p.append(Vector2(38, 6))
	p.append(Vector2(38, 28))
	_cubic(p, Vector2(38, 28), Vector2(38, 42), Vector2(54, 44), Vector2(54, 60))
	p.append(Vector2(54, 142))
	_quad(p, Vector2(54, 142), Vector2(54, 154), Vector2(42, 154))
	p.append(Vector2(18, 154))
	_quad(p, Vector2(18, 154), Vector2(6, 154), Vector2(6, 142))
	p.append(Vector2(6, 60))
	_cubic(p, Vector2(6, 60), Vector2(6, 44), Vector2(22, 42), Vector2(22, 28))
	return p


## Altura de cada camada de líquido na grade 60 x 160.
static func layer_height(capacity: int) -> float:
	return (LIQUID_BOTTOM - LIQUID_TOP) / float(capacity)


## Polígono(s) de uma camada: a faixa horizontal recortada pelo formato da garrafa.
static func layer_polygons(layer_index: int, capacity: int) -> Array[PackedVector2Array]:
	var h: float = layer_height(capacity)
	var y1: float = LIQUID_BOTTOM - h * (layer_index + 1)
	var y2: float = LIQUID_BOTTOM - h * layer_index
	if layer_index == capacity - 1:
		y1 -= 2.0  # cobre a curva dos ombros
	var band := PackedVector2Array([Vector2(0, y1), Vector2(60, y1), Vector2(60, y2 + 0.5), Vector2(0, y2 + 0.5)])
	return Geometry2D.intersect_polygons(band, bottle_outline())


## Tema com as letras e os botões do estilo (borda escura e "sombra dura" embaixo).
static func build_theme() -> Theme:
	var t := Theme.new()
	t.default_font = body_font(800)
	t.default_font_size = 28
	t.set_color("font_color", "Label", INK)
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		t.set_stylebox(state, "Button", _button_box(PAPER, state))
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		t.set_color(c, "Button", INK)
	t.set_color("font_disabled_color", "Button", Color(INK, 0.4))
	t.set_type_variation("MainButton", "Button")
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		t.set_stylebox(state, "MainButton", _button_box(ACCENT, state))
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		t.set_color(c, "MainButton", Color.WHITE)
	t.set_stylebox("panel", "PanelContainer", card_box())
	return t


static func card_box() -> StyleBoxFlat:
	var b := StyleBoxFlat.new()
	b.bg_color = PAPER
	b.border_color = INK
	b.set_border_width_all(4)
	b.set_corner_radius_all(22)
	b.set_content_margin_all(12)
	return b


static func _button_box(fill: Color, state: String) -> StyleBox:
	var b := StyleBoxFlat.new()
	b.bg_color = fill.darkened(0.08) if state == "hover" else fill
	if state == "disabled":
		b.bg_color = Color(fill, 0.5)
	b.border_color = INK
	b.set_border_width_all(4)
	b.border_width_bottom = 4 if state == "pressed" else 10
	b.set_corner_radius_all(22)
	b.content_margin_left = 22
	b.content_margin_right = 22
	b.content_margin_top = 14 + (6 if state == "pressed" else 0)
	b.content_margin_bottom = 12
	if state == "focus":
		b.draw_center = false
		b.border_color = Color(INK, 0.0)
	return b


static func _cubic(out: PackedVector2Array, a: Vector2, b: Vector2, c: Vector2, d: Vector2, steps: int = 10) -> void:
	for i in range(1, steps + 1):
		out.append(a.bezier_interpolate(b, c, d, float(i) / steps))


static func _quad(out: PackedVector2Array, a: Vector2, b: Vector2, c: Vector2, steps: int = 6) -> void:
	for i in range(1, steps + 1):
		var t: float = float(i) / steps
		out.append(a.lerp(b, t).lerp(b.lerp(c, t), t))
