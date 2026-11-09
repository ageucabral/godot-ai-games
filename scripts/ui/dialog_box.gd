class_name DialogBox
extends ColorRect
## Janela de aviso sobre a tela (vitória, jogadas acabaram, pontuação zerada...).
## Também serve de formulário: depois de `open`, `add_input` põe campos de texto; com muitos botões
## (ex.: lista de países), os botões rolam.
## Três jeitos de mostrar o título: `open` (faixa roxa em cima), `open_card` (título colorido dentro do cartão,
## como na sequência e nas configurações) e `open_hero` (título grande sobre o fundo, acima do cartão, como na vitória).

## Título da janela (em qualquer um dos três jeitos o texto fica aqui).
var title_label: Label
var text_label: Label
var _header: PanelContainer
var _card_title: Label
var _hero_title: Label
var _buttons: VBoxContainer
var _scroll: ScrollContainer
var _inputs: VBoxContainer
var _card: PanelContainer
## Ação de cada botão aberto agora (trocável com `set_action`, ex.: para ler os campos do formulário).
var _actions: Array = []
## A partir de quantos botões a lista rola.
const SCROLL_FROM := 7
const SCROLL_HEIGHT := 700.0


func _init() -> void:
	color = Color(0.06, 0.03, 0.18, 0.62)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	center.add_child(column)
	_hero_title = GameStyle.make_title("", 92, GameStyle.GOLD)
	_hero_title.custom_minimum_size = Vector2(580, 0)
	_hero_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_hero_title)
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(580, 0)
	var card_style := GameStyle.card_box()
	card_style.content_margin_top = 0
	card_style.content_margin_left = 0
	card_style.content_margin_right = 0
	card_style.content_margin_bottom = 24
	card.add_theme_stylebox_override("panel", card_style)
	column.add_child(card)
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
	_header = header
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
	_card_title = GameStyle.make_title("", 54, GameStyle.PURPLE)
	_card_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_card_title)
	text_label = GameStyle.make_label("", 30)
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(text_label)
	_inputs = VBoxContainer.new()
	_inputs.add_theme_constant_override("separation", 12)
	box.add_child(_inputs)
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(_scroll)
	_buttons = VBoxContainer.new()
	_buttons.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_buttons.add_theme_constant_override("separation", 14)
	_scroll.add_child(_buttons)


## Botão que pede propaganda: ícone de vídeo + a recompensa em poucas palavras (ex.: "+1 frasco").
static func ad(text: String, action: Callable, main: bool = true) -> Array:
	return [text, action, main, not Server.ads_free()]  # sem anúncios (compra): botão comum, não há vídeo


## buttons: lista de [texto, ação (Callable), principal (bool), ícone de vídeo (bool, veja `ad`)].
func open(title: String, text: String, buttons: Array) -> void:
	_open("header", title, text, buttons)


## Título colorido dentro do cartão, sem a faixa roxa (sequência de dias, configurações).
func open_card(title: String, text: String, buttons: Array, title_color: Color = GameStyle.PURPLE) -> void:
	GameStyle.apply_title_look(_card_title, title_color, 0 if title_color == GameStyle.PURPLE else 8)
	_open("card", title, text, buttons)


## Título grande sobre o fundo, acima do cartão (vitória, duelo).
func open_hero(title: String, text: String, buttons: Array) -> void:
	_open("hero", title, text, buttons)


func _open(mode: String, title: String, text: String, buttons: Array) -> void:
	title_label.text = title
	_card_title.text = title
	_hero_title.text = title
	_header.visible = mode == "header"
	_card_title.visible = mode == "card"
	_hero_title.visible = mode == "hero"
	(_card.get_theme_stylebox("panel") as StyleBoxFlat).content_margin_top = 0 if mode == "header" else 26
	text_label.text = text
	for b in _buttons.get_children():
		b.queue_free()
	for c in _inputs.get_children():
		c.queue_free()
	_inputs.visible = false
	var many := buttons.size() > SCROLL_FROM
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO if many else ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.custom_minimum_size = Vector2(0, SCROLL_HEIGHT if many else 0.0)
	_scroll.scroll_vertical = 0
	_actions = []
	_buttons.add_theme_constant_override("separation", 14)
	for spec in buttons:
		var b := GameStyle.make_button(spec[0], spec[2] if spec.size() > 2 else false, 32)
		b.video_icon = spec.size() > 3 and bool(spec[3])
		b.custom_minimum_size = Vector2(0, 92)
		var index := _actions.size()
		_actions.append(spec[1])
		var actions := _actions
		b.pressed.connect(func() -> void:
			close()
			(actions[index] as Callable).call())
		_buttons.add_child(b)
	GameStyle.let_scroll(_buttons)
	text_label.visible = text != ""
	visible = true
	# entra com um pulinho
	if is_inside_tree():
		_card.scale = Vector2(0.85, 0.85)
		create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).tween_property(_card, "scale", Vector2.ONE, 0.22)


func close() -> void:
	visible = false


## Troca a ação do botão `index` do que está aberto (o formulário liga o "Enviar" depois de criar os campos).
func set_action(index: int, action: Callable) -> void:
	if index >= 0 and index < _actions.size():
		_actions[index] = action


## Campo de texto no formulário aberto agora. `kind`: "text", "number" ou "multiline" (mensagem).
## Devolve o campo (LineEdit ou TextEdit) para ler `.text` na hora de enviar.
func add_input(placeholder: String, value: String = "", kind: String = "text", max_length: int = 120) -> Control:
	_inputs.visible = true
	var field: Control
	if kind == "multiline":
		var te := TextEdit.new()
		te.placeholder_text = placeholder
		te.text = value
		te.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
		te.custom_minimum_size = Vector2(0, 220)
		field = te
	else:
		var le := LineEdit.new()
		le.placeholder_text = placeholder
		le.text = value
		le.max_length = max_length
		le.custom_minimum_size = Vector2(0, 84)
		if kind == "number":
			le.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER
		field = le
	field.add_theme_font_size_override("font_size", 30)
	field.add_theme_color_override("font_color", GameStyle.INK)
	field.add_theme_color_override("font_placeholder_color", Color(GameStyle.INK, 0.45))
	field.add_theme_color_override("caret_color", GameStyle.INK)
	for state in ["normal", "focus", "read_only"]:
		var box := StyleBoxFlat.new()
		box.bg_color = Color.WHITE
		box.border_color = GameStyle.PURPLE if state == "focus" else GameStyle.INK
		box.set_border_width_all(4)
		box.set_corner_radius_all(18)
		box.set_content_margin_all(16)
		field.add_theme_stylebox_override(state, box)
	_inputs.add_child(field)
	return field


## Põe um conteúdo próprio (ex.: as figuras do convite) no que está aberto, acima dos botões.
func add_content(control: Control) -> void:
	_inputs.visible = true
	_inputs.add_child(control)


## Campos abertos agora (útil nos testes).
func inputs() -> Array[Control]:
	var out: Array[Control] = []
	for c in _inputs.get_children():
		if not c.is_queued_for_deletion():
			out.append(c as Control)
	return out


## Põe uma linha própria (ex.: as linhas das configurações) junto dos botões. O nome dela para `press` e
## `button_texts` fica no meta "label" (a linha desenha o texto por conta própria).
func add_row(row: Control) -> void:
	_buttons.add_theme_constant_override("separation", 4)  # linhas coladas, como uma lista
	_buttons.add_child(row)


## Textos dos botões abertos agora (útil nos testes).
func button_texts() -> Array[String]:
	var out: Array[String] = []
	for b in _buttons.get_children():
		if b is Button and not b.is_queued_for_deletion():
			out.append(str(b.get_meta("label", (b as Button).text)))
	return out


## Aperta o botão com esse texto (útil nos testes).
func press(text: String) -> void:
	for b in _buttons.get_children():
		if b is Button and not b.is_queued_for_deletion() and str(b.get_meta("label", (b as Button).text)) == text:
			(b as Button).pressed.emit()
			return
	push_error("Botão não encontrado: " + text)
