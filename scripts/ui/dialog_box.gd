class_name DialogBox
extends ColorRect
## Janela de aviso sobre a tela (vitória, jogadas acabaram, pontuação zerada...).

var title_label: Label
var text_label: Label
var _buttons: VBoxContainer
var _card: PanelContainer


func _init() -> void:
	color = Color(0.06, 0.03, 0.18, 0.62)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(580, 0)
	var card_style := GameStyle.card_box()
	card_style.content_margin_top = 0
	card_style.content_margin_left = 0
	card_style.content_margin_right = 0
	card_style.content_margin_bottom = 24
	card.add_theme_stylebox_override("panel", card_style)
	center.add_child(card)
	_card = card
	card.resized.connect(func() -> void: card.pivot_offset = card.size * 0.5)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 18)
	card.add_child(outer)
	var header := PanelContainer.new()
	var head_style := StyleBoxFlat.new()
	head_style.bg_color = GameStyle.PURPLE
	head_style.corner_radius_top_left = 26
	head_style.corner_radius_top_right = 26
	head_style.border_color = GameStyle.INK
	head_style.border_width_bottom = 5
	head_style.content_margin_top = 14
	head_style.content_margin_bottom = 14
	head_style.content_margin_left = 20
	head_style.content_margin_right = 20
	header.add_theme_stylebox_override("panel", head_style)
	outer.add_child(header)
	title_label = GameStyle.make_title("", 58)
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	header.add_child(title_label)
	var margin := MarginContainer.new()
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 28)
	outer.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	margin.add_child(box)
	text_label = GameStyle.make_label("", 30)
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(text_label)
	_buttons = VBoxContainer.new()
	_buttons.add_theme_constant_override("separation", 14)
	box.add_child(_buttons)


## buttons: lista de [texto, ação (Callable), principal (bool)].
func open(title: String, text: String, buttons: Array) -> void:
	title_label.text = title
	text_label.text = text
	for b in _buttons.get_children():
		b.queue_free()
	for spec in buttons:
		var b := GameStyle.make_button(spec[0], spec[2] if spec.size() > 2 else false, 32)
		b.custom_minimum_size = Vector2(0, 92)
		var action: Callable = spec[1]
		b.pressed.connect(func() -> void:
			close()
			action.call())
		_buttons.add_child(b)
	text_label.visible = text != ""
	visible = true
	# entra com um pulinho
	if is_inside_tree():
		_card.scale = Vector2(0.85, 0.85)
		create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).tween_property(_card, "scale", Vector2.ONE, 0.22)


func close() -> void:
	visible = false


## Textos dos botões abertos agora (útil nos testes).
func button_texts() -> Array[String]:
	var out: Array[String] = []
	for b in _buttons.get_children():
		if not b.is_queued_for_deletion():
			out.append((b as Button).text)
	return out


## Aperta o botão com esse texto (útil nos testes).
func press(text: String) -> void:
	for b in _buttons.get_children():
		if not b.is_queued_for_deletion() and (b as Button).text == text:
			(b as Button).pressed.emit()
			return
	push_error("Botão não encontrado: " + text)
