class_name BottleView
extends Control
## Desenha uma garrafinha com suas camadas de líquido e avisa quando é tocada.
## Também sabe se inclinar e derramar (usado pela animação de despejo).

signal tapped(index: int)

const LIFT: float = 34.0
const MOUTH := Vector2(30, 6)       # boca da garrafa na grade 60 x 160
const PIVOT := Vector2(30, 80)      # centro de giro ao inclinar

var index: int = 0
var capacity: int = SortPuzzle.CAPACITY
## Camadas do fundo para o topo: [cor, quantidade (1.0 = camada cheia), escondida].
var segments: Array = []:
	set(value):
		segments = value
		queue_redraw()
var selected: bool = false:
	set(value):
		if selected == value:
			return
		selected = value
		_animate_lift()
## Deslocamento e giro usados durante o despejo.
var pour_offset: Vector2 = Vector2.ZERO:
	set(value):
		pour_offset = value
		queue_redraw()
var pour_angle: float = 0.0:
	set(value):
		pour_angle = value
		queue_redraw()
## Filete de líquido caindo da boca até `stream_end` (posição global).
var stream_on: bool = false:
	set(value):
		stream_on = value
		queue_redraw()
var stream_color: Color = Color.WHITE
## Sem tampinha (enquanto recebe ou derrama líquido).
var cap_open: bool = false:
	set(value):
		cap_open = value
		queue_redraw()
var stream_end: Vector2 = Vector2.ZERO

var _lift: float = 0.0:
	set(value):
		_lift = value
		queue_redraw()
var _tween: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	if custom_minimum_size == Vector2.ZERO:
		set_bottle_width(108.0)


func set_bottle_width(w: float) -> void:
	custom_minimum_size = Vector2(w, w * TropicalStyle.DESIGN_SIZE.y / TropicalStyle.DESIGN_SIZE.x + LIFT)


## Monta as camadas a partir de uma garrafa do quebra-cabeça.
static func segments_from(tube: Array, hidden: Array) -> Array:
	var out: Array = []
	for i in tube.size():
		out.append([tube[i], 1.0, hidden[i] if i < hidden.size() else false])
	return out


## Só o clique conta. No celular o toque vira clique sozinho (emulate_mouse_from_touch);
## contar o toque E o clique fazia a garrafa ser escolhida e solta no mesmo instante.
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		tapped.emit(index)
		accept_event()


## Balança de leve quando a jogada não é permitida.
func shake() -> void:
	var t := create_tween()
	for dx in [-10.0, 10.0, -6.0, 6.0, 0.0]:
		t.tween_property(self, "pour_offset:x", dx, 0.04)


func _animate_lift() -> void:
	if _tween:
		_tween.kill()
	if not is_inside_tree():
		_lift = LIFT if selected else 0.0
		return
	_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "_lift", LIFT if selected else 0.0, 0.18)


func design_scale() -> float:
	return minf(size.x / TropicalStyle.DESIGN_SIZE.x, (size.y - LIFT) / TropicalStyle.DESIGN_SIZE.y)


## Transformação da grade 60 x 160 para a posição local (com elevação, giro e deslocamento).
func design_transform(angle: float = pour_angle, offset: Vector2 = pour_offset, lift: float = _lift) -> Transform2D:
	var s := design_scale()
	var origin := Vector2((size.x - TropicalStyle.DESIGN_SIZE.x * s) * 0.5, LIFT - lift)
	var pivot := PIVOT * s
	return Transform2D(0.0, origin + pivot + offset) * Transform2D(angle, Vector2.ZERO) \
		* Transform2D(0.0, -pivot) * Transform2D(0.0, Vector2(s, s), 0.0, Vector2.ZERO)


## Posição global da boca da garrafa para um giro/deslocamento.
func mouth_global(angle: float = 0.0, offset: Vector2 = Vector2.ZERO, lift: float = _lift) -> Vector2:
	return get_global_transform() * (design_transform(angle, offset, lift) * MOUTH)


## Posição global da superfície do líquido (onde o filete encosta).
func surface_global() -> Vector2:
	var level := 0.0
	for seg in segments:
		level += seg[1]
	var y := TropicalStyle.LIQUID_BOTTOM - level * layer_height()
	return get_global_transform() * (design_transform(0.0, Vector2.ZERO, 0.0) * Vector2(30, y))


func layer_height() -> float:
	return (TropicalStyle.LIQUID_BOTTOM - TropicalStyle.LIQUID_TOP) / float(capacity)


func _draw() -> void:
	var xf := design_transform()
	draw_set_transform_matrix(xf)
	var outline := TropicalStyle.bottle_outline()

	# sombra no chão (só parada)
	if _lift < 1.0 and pour_angle == 0.0:
		draw_set_transform_matrix(xf * Transform2D(0.0, Vector2(1, 0.25), 0.0, Vector2.ZERO))
		draw_circle(Vector2(30, 620), 26, Color(TropicalStyle.INK, 0.12))
		draw_set_transform_matrix(xf)

	draw_colored_polygon(outline, TropicalStyle.GLASS)
	var h := layer_height()
	var level := 0.0
	var font := get_theme_default_font()
	for seg in segments:
		var amount: float = seg[1]
		if amount <= 0.001:
			continue
		var y_bottom := TropicalStyle.LIQUID_BOTTOM - level * h
		var y_top := TropicalStyle.LIQUID_BOTTOM - (level + amount) * h
		if level + amount >= capacity - 0.01:
			y_top -= 2.0  # cobre a curva dos ombros
		var col: Color = TropicalStyle.HIDDEN_LAYER if seg[2] else TropicalStyle.liquid_color(seg[0])
		for poly in TropicalStyle.band_polygons(y_top, y_bottom + 0.5):
			draw_colored_polygon(poly, col)
		if seg[2] and amount > 0.6:
			draw_string(font, Vector2(0, (y_top + y_bottom) * 0.5 + 6), "?", HORIZONTAL_ALIGNMENT_CENTER, 60, 17, Color.WHITE)
		level += amount
	if level > 0.01:  # brilho na superfície do líquido
		var y := TropicalStyle.LIQUID_BOTTOM - level * h
		for poly in TropicalStyle.band_polygons(y, y + 3):
			draw_colored_polygon(poly, Color(1, 1, 1, 0.35))

	# reflexo do vidro
	draw_rect(Rect2(13, 64, 4, 62), Color(1, 1, 1, 0.45))
	draw_rect(Rect2(25, 10, 3, 18), Color(1, 1, 1, 0.45))

	var closed := outline.duplicate()
	closed.append(outline[0])
	draw_polyline(closed, TropicalStyle.INK, 2.6, true)

	# tampinha vermelha (sai durante o despejo)
	if pour_angle == 0.0 and not cap_open:
		var cap := Rect2(19, 1, 22, 8)
		draw_rect(cap, TropicalStyle.ACCENT)
		draw_rect(cap, TropicalStyle.INK, false, 2.2)

	draw_set_transform_matrix(Transform2D.IDENTITY)
	if stream_on:
		var from := xf * MOUTH
		var to := get_global_transform().affine_inverse() * stream_end
		var w := 7.0 * design_scale()
		draw_line(from, Vector2(from.x, to.y), stream_color, w, true)
		draw_circle(from, w * 0.5, stream_color)
