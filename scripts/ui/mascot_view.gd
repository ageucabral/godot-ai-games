class_name MascotView
extends Control
## Mascote da tela inicial: uma garrafinha de suco sorridente que balança e pisca.

signal tapped

const SCALE: float = 2.3
const LAYERS: Array[int] = [5, 2, 4, 0]  # Anil, Manga, Limão, Acerola (do fundo para o topo)

var _time: float = 0.0
var _hop: float = 0.0
var _tween: Tween


func _ready() -> void:
	custom_minimum_size = TropicalStyle.DESIGN_SIZE * SCALE + Vector2(40, 60)
	mouse_filter = Control.MOUSE_FILTER_STOP


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return  # tela escondida (ex.: durante a partida): não redesenha à toa
	_time += delta
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		hop()
		tapped.emit()
		accept_event()


## Pulinho quando tocado.
func hop() -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween().set_trans(Tween.TRANS_SINE)
	_tween.tween_property(self, "_hop", 1.0, 0.14).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "_hop", 0.0, 0.3).set_ease(Tween.EASE_IN)


## Pisca por 0,15 s a cada 3,2 s.
static func eyes_open(t: float) -> float:
	var phase := fmod(t, 3.2)
	return 0.12 if phase > 3.05 else 1.0


func _draw() -> void:
	var bob := sin(_time * 2.2) * 6.0 + _hop * -40.0
	var tilt := sin(_time * 1.1) * 0.04
	var size_px := TropicalStyle.DESIGN_SIZE * SCALE
	var origin := Vector2((size.x - size_px.x) * 0.5, size.y - size_px.y - 24 + bob)

	# sombra no chão
	var shadow_w := 50.0 * (1.0 - _hop * 0.3)
	draw_set_transform(Vector2(size.x * 0.5, size.y - 22), 0.0, Vector2(1.0, 0.22))
	draw_circle(Vector2.ZERO, shadow_w, Color(TropicalStyle.INK, 0.14))

	var pivot := TropicalStyle.DESIGN_SIZE * 0.5
	var xf := Transform2D(0.0, origin + pivot * SCALE) * Transform2D(tilt, Vector2.ZERO) \
		* Transform2D(0.0, Vector2(SCALE, SCALE), 0.0, -pivot * SCALE)
	draw_set_transform_matrix(xf)
	var outline := TropicalStyle.bottle_outline()
	draw_colored_polygon(outline, TropicalStyle.GLASS)
	var h := TropicalStyle.layer_height(4)
	for i in LAYERS.size():
		var y_bottom := TropicalStyle.LIQUID_BOTTOM - i * h
		var y_top := y_bottom - h - (2.0 if i == LAYERS.size() - 1 else 0.0)
		for poly in TropicalStyle.band_polygons(y_top, y_bottom + 0.5):
			draw_colored_polygon(poly, TropicalStyle.liquid_color(LAYERS[i]))
	draw_rect(Rect2(12, 64, 4, 62), Color(1, 1, 1, 0.45))

	# rosto
	var open := eyes_open(_time)
	for x in [22.0, 38.0]:
		draw_set_transform_matrix(xf * Transform2D(0.0, Vector2(1.0, open), 0.0, Vector2(0, 92.0 * (1.0 - open))))
		draw_circle(Vector2(x, 92), 6.5, Color.WHITE)
		draw_circle(Vector2(x + 0.8, 93), 3.6, TropicalStyle.INK)
		draw_circle(Vector2(x + 2.0, 91.5), 1.2, Color.WHITE)
	draw_set_transform_matrix(xf)
	draw_circle(Vector2(15, 103), 4.0, Color(1, 0.55, 0.6, 0.6))
	draw_circle(Vector2(45, 103), 4.0, Color(1, 0.55, 0.6, 0.6))
	draw_arc(Vector2(30, 102), 7.5, 0.25, PI - 0.25, 12, TropicalStyle.INK, 2.4, true)

	var closed := outline.duplicate()
	closed.append(outline[0])
	draw_polyline(closed, TropicalStyle.INK, 2.6, true)
	draw_rect(Rect2(19, 1 - _hop * 6.0, 22, 8), TropicalStyle.ACCENT)
	draw_rect(Rect2(19, 1 - _hop * 6.0, 22, 8), TropicalStyle.INK, false, 2.2)
	draw_set_transform_matrix(Transform2D.IDENTITY)
