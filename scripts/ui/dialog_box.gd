class_name DialogBox
extends ColorRect
## Janela de aviso sobre a tela (vitória, jogadas acabaram, pontuação zerada...).

var title_label: Label
var text_label: Label
var _buttons: VBoxContainer


func _init() -> void:
	color = Color(0.227, 0.133, 0.075, 0.55)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(560, 0)
	card.add_theme_stylebox_override("panel", TropicalStyle.card_box())
	center.add_child(card)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	card.add_child(box)
	title_label = TropicalStyle.make_label("", 64, true, TropicalStyle.ACCENT)
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(title_label)
	text_label = TropicalStyle.make_label("", 30)
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
		var b := TropicalStyle.make_button(spec[0], spec[2] if spec.size() > 2 else false)
		var action: Callable = spec[1]
		b.pressed.connect(func() -> void:
			close()
			action.call())
		_buttons.add_child(b)
	visible = true


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
