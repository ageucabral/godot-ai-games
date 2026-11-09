class_name PageView
extends Control
## Página inteira por cima da tela (Conquistas, Meus frascos): o fundo do jogo, o botão de voltar, o título e um
## cartão claro que rola. Com `tabs`, duas abas no topo trocam o conteúdo (cada aba é um Callable que monta o cartão).

signal closed

var title_label: Label
## Conteúdo do cartão (limpo a cada troca de aba).
var body: VBoxContainer
var tab_buttons: Dictionary = {}
var _tabs: Dictionary = {}
var tab: String = ""


func _init(title: String, bg_kind: String = "sky") -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = GameStyle.build_theme()
	GameStyle.add_background(self, bg_kind)
	var shade := ColorRect.new()
	shade.color = Color(0.06, 0.03, 0.18, 0.35)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 26
	box.offset_right = -26
	box.offset_top = 40
	box.offset_bottom = -40
	box.add_theme_constant_override("separation", 18)
	add_child(box)
	var head := HBoxContainer.new()
	box.add_child(head)
	var back := IconButton.new("back")
	back.custom_minimum_size = Vector2(84, 84)
	back.pressed.connect(close)
	head.add_child(back)
	title_label = GameStyle.make_title(title, 56)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title_label)
	var balance := Control.new()
	balance.custom_minimum_size = Vector2(84, 0)
	head.add_child(balance)
	var tabs := HBoxContainer.new()
	tabs.name = "Tabs"
	tabs.visible = false
	tabs.add_theme_constant_override("separation", 12)
	box.add_child(tabs)
	var card := PanelContainer.new()
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var style := GameStyle.card_box()
	style.set_content_margin_all(22)
	card.add_theme_stylebox_override("panel", style)
	box.add_child(card)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	card.add_child(scroll)
	body = VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 16)
	scroll.add_child(body)


## Abas no topo: [[id, nome, Callable que monta o cartão]]. Abre a primeira (ou `open_id`).
func set_tabs(list: Array, open_id: String = "") -> void:
	var bar: HBoxContainer = find_child("Tabs", true, false)
	bar.visible = true
	for t: Array in list:
		var id: String = t[0]
		_tabs[id] = t[2]
		var b := GameStyle.make_button(t[1], false, 26)
		b.custom_minimum_size = Vector2(0, 72)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(func() -> void: show_tab(id))
		bar.add_child(b)
		tab_buttons[id] = b
	show_tab(open_id if _tabs.has(open_id) else str(list[0][0]))


## Troca para a aba `id` (ou remonta a aberta) e redesenha o cartão.
func show_tab(id: String) -> void:
	tab = id
	title_label.text = tr((tab_buttons[id] as GlossButton).text) if tab_buttons.has(id) else title_label.text
	for k: String in tab_buttons:
		var b: GlossButton = tab_buttons[k]
		b.fill = GameStyle.PURPLE if k == id else Color("3a2f7a")
		b.queue_redraw()
	for c in body.get_children():
		body.remove_child(c)
		c.queue_free()
	(_tabs[id] as Callable).call(body)
	GameStyle.let_scroll(body)


func close() -> void:
	closed.emit()
	queue_free()
