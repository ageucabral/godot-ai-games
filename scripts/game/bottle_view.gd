class_name BottleView
extends Control
## Desenha uma garrafinha com suas camadas de líquido e avisa quando é tocada.

signal tapped(index: int)

const LIFT: float = 34.0

var index: int = 0
var layers: Array = []:
	set(value):
		layers = value.duplicate()
		queue_redraw()
var capacity: int = SortPuzzle.CAPACITY
var selected: bool = false:
	set(value):
		if selected == value:
			return
		selected = value
		_animate_lift()

var _lift: float = 0.0:
	set(value):
		_lift = value
		queue_redraw()
var _tween: Tween


func _ready() -> void:
	custom_minimum_size = Vector2(108, 288 + LIFT)
	mouse_filter = Control.MOUSE_FILTER_STOP


func _gui_input(event: InputEvent) -> void:
	var pressed: bool = (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) \
		or (event is InputEventScreenTouch and event.pressed)
	if pressed:
		tapped.emit(index)
		accept_event()


## Balança de leve quando a jogada não é permitida.
func shake() -> void:
	var t := create_tween()
	for dx in [-10.0, 10.0, -6.0, 6.0, 0.0]:
		t.tween_property(self, "position:x", position.x + dx, 0.04)


func _animate_lift() -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "_lift", LIFT if selected else 0.0, 0.18)


func _draw() -> void:
	var s: float = minf(size.x / TropicalStyle.DESIGN_SIZE.x, (size.y - LIFT) / TropicalStyle.DESIGN_SIZE.y)
	var origin := Vector2((size.x - TropicalStyle.DESIGN_SIZE.x * s) * 0.5, LIFT - _lift)
	draw_set_transform(origin, 0.0, Vector2(s, s))
	var outline := TropicalStyle.bottle_outline()

	# sombra no chão
	if _lift < 1.0:
		draw_set_transform(origin + Vector2(0, 2 * s), 0.0, Vector2(s, s * 0.25))
		draw_circle(Vector2(30, 620), 26, Color(TropicalStyle.INK, 0.12))
		draw_set_transform(origin, 0.0, Vector2(s, s))

	draw_colored_polygon(outline, TropicalStyle.GLASS)
	for i in layers.size():
		var col: Color = TropicalStyle.liquid_color(layers[i])
		for poly in TropicalStyle.layer_polygons(i, capacity):
			draw_colored_polygon(poly, col)
	if not layers.is_empty():  # brilho na superfície do líquido
		var y: float = TropicalStyle.LIQUID_BOTTOM - TropicalStyle.layer_height(capacity) * layers.size()
		var shine := PackedVector2Array([Vector2(0, y), Vector2(60, y), Vector2(60, y + 3), Vector2(0, y + 3)])
		for poly in Geometry2D.intersect_polygons(shine, outline):
			draw_colored_polygon(poly, Color(1, 1, 1, 0.35))

	# reflexo do vidro
	draw_rect(Rect2(13, 64, 4, 62), Color(1, 1, 1, 0.45))
	draw_rect(Rect2(25, 10, 3, 18), Color(1, 1, 1, 0.45))

	var closed := outline.duplicate()
	closed.append(outline[0])
	draw_polyline(closed, TropicalStyle.INK, 2.6, true)

	# tampinha vermelha
	var cap := Rect2(19, 1, 22, 8)
	draw_rect(cap, TropicalStyle.ACCENT)
	draw_rect(cap, TropicalStyle.INK, false, 2.2)
	draw_set_transform(Vector2.ZERO)
