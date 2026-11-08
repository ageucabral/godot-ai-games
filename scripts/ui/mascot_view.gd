class_name MascotView
extends Control
## Mascote da tela inicial: a coruja alquimista (ilustração gerada em assets/art/mascot.png).
## Flutua de leve, inclina, solta brilhinhos e dá um pulinho quando tocada.

const ART_PATH := "res://assets/art/mascot.png"
const HEIGHT: float = 470.0

var _time: float = 0.0
var _hop: float = 0.0
var _tween: Tween
var _art: Texture2D


func _ready() -> void:
	_art = load(ART_PATH)
	var k := HEIGHT / _art.get_size().y
	custom_minimum_size = _art.get_size() * k + Vector2(40, 40)
	pivot_offset = custom_minimum_size * 0.5
	mouse_filter = Control.MOUSE_FILTER_STOP


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return  # tela escondida (ex.: durante a partida): não redesenha à toa
	_time += delta
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		hop()
		accept_event()


## Pulinho quando tocado.
func hop() -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween().set_trans(Tween.TRANS_SINE)
	_tween.tween_property(self, "_hop", 1.0, 0.14).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "_hop", 0.0, 0.3).set_ease(Tween.EASE_IN)


## Altura da flutuação (px) num instante: sobe e desce devagar, mais o pulinho.
static func float_offset(t: float, hop_amount: float) -> float:
	return sin(t * 2.0) * 10.0 - hop_amount * 50.0


func _draw() -> void:
	if not _art:
		return
	var k := HEIGHT / _art.get_size().y
	var art_size := _art.get_size() * k
	var c := size * 0.5
	# sombra no chão
	var shadow_k := 1.0 - _hop * 0.3 - (sin(_time * 2.0) + 1.0) * 0.06
	draw_set_transform(Vector2(c.x, size.y - 24), 0.0, Vector2(1.0, 0.2))
	draw_circle(Vector2.ZERO, art_size.x * 0.32 * shadow_k, Color(0, 0, 0, 0.22))
	var tilt := sin(_time * 1.2) * 0.04
	draw_set_transform(c + Vector2(0, float_offset(_time, _hop)), tilt, Vector2.ONE)
	draw_texture_rect(_art, Rect2(-art_size * 0.5, art_size), false)
	draw_set_transform_matrix(Transform2D.IDENTITY)
	# brilhinhos em volta
	for i in 6:
		var a := _time * 0.8 + i * TAU / 6.0
		var p := c + Vector2(cos(a) * art_size.x * 0.6, sin(a * 1.3) * art_size.y * 0.45)
		var b := 0.5 + 0.5 * sin(_time * 3.0 + i)
		draw_colored_polygon(GameStyle.star_points(p, 10.0 * b + 3.0, 2.5, 4), Color(1, 1, 0.8, 0.85 * b))
