class_name SplashOverlay
extends Control
## Tela de abertura do Poção de Cores (ilustração + nome + "Carregando"), por cima do menu.
## Some sozinha depois de `duration` segundos (ou ao tocar).

var duration: float = 1.6
var _bar: ProgressBar


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	GameStyle.add_background(self, "splash")
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_top = 70
	box.offset_bottom = -90
	box.offset_left = 60
	box.offset_right = -60
	add_child(box)
	var small := GameStyle.make_title("Na Lata", 36, GameStyle.GOLD)
	small.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	box.add_child(small)
	var logo := GameStyle.make_title("Poção de Cores", 84)
	logo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(logo)
	var space := Control.new()
	space.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(space)
	box.add_child(GameStyle.make_title("Carregando", 44))
	_bar = ProgressBar.new()
	_bar.show_percentage = false
	_bar.custom_minimum_size = Vector2(0, 34)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.1, 0.06, 0.25, 0.8)
	bg.border_color = GameStyle.INK
	bg.set_border_width_all(4)
	bg.set_corner_radius_all(17)
	var fill := StyleBoxFlat.new()
	fill.bg_color = GameStyle.GOLD
	fill.set_corner_radius_all(14)
	_bar.add_theme_stylebox_override("background", bg)
	_bar.add_theme_stylebox_override("fill", fill)
	box.add_child(_bar)
	var t := create_tween()
	t.tween_property(_bar, "value", 100.0, duration).set_trans(Tween.TRANS_SINE)
	t.tween_property(self, "modulate:a", 0.0, 0.3)
	t.tween_callback(close)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		close()


func close() -> void:
	if is_queued_for_deletion():
		return
	queue_free()
