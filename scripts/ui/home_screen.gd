extends Control
## Tela inicial do Poção de Cores, enxuta: pontos do mês e configurações em cima, nome do jogo,
## mascote, o botão verde "Nível N" e, na lateral direita, os ícones Jogos · Ranking · Desafios
## (Ageu, 8/11/2026: sem barra embaixo; o perfil fica dentro da engrenagem).

signal level_requested
signal daily_requested
signal ranking_requested
signal hub_requested

const GAME_NAME := "Poção de Cores"

var points_label: Label
var level_button: GlossButton
var mascot: MascotView
var settings_button: IconButton
## Ícones da lateral, por nome: "games", "ranking", "daily".
var side_buttons: Dictionary = {}
var dialog: DialogBox
## Dia mostrado nos botões (serve para perceber a meia-noite, mesmo se o app ficou em segundo plano).
var _shown_day: String = ""


func _ready() -> void:
	theme = GameStyle.build_theme()
	GameStyle.add_background(self, "sky")
	_build()
	dialog = DialogBox.new()
	add_child(dialog)
	GameState.progress_changed.connect(refresh)
	refresh()
	var timer := Timer.new()
	timer.wait_time = 1.0
	timer.autostart = true
	timer.timeout.connect(_check_new_day)
	add_child(timer)


func _build() -> void:
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_top = 40
	box.add_theme_constant_override("separation", 10)
	add_child(box)

	# barra de cima: moedas (pontos do mês) · configurações
	var top_margin := MarginContainer.new()
	top_margin.add_theme_constant_override("margin_left", 26)
	top_margin.add_theme_constant_override("margin_right", 26)
	box.add_child(top_margin)
	var top := HBoxContainer.new()
	top_margin.add_child(top)
	var out: Array = []
	top.add_child(Menus.make_coin_pill(out))
	points_label = out[0]
	var space := Control.new()
	space.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(space)
	settings_button = IconButton.new("gear")
	settings_button.pressed.connect(func() -> void: Menus.open_settings(dialog))
	top.add_child(settings_button)

	# nome do jogo
	var title_box := VBoxContainer.new()
	title_box.add_theme_constant_override("separation", -12)
	box.add_child(title_box)
	var hub_label := GameStyle.make_title("Na Lata", 30, GameStyle.GOLD)
	hub_label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	title_box.add_child(hub_label)
	title_box.add_child(GameStyle.make_title(GAME_NAME, 66))

	# meio: mascote
	var middle := CenterContainer.new()
	middle.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(middle)
	mascot = MascotView.new()
	middle.add_child(mascot)

	var button_margin := MarginContainer.new()
	button_margin.add_theme_constant_override("margin_left", 110)
	button_margin.add_theme_constant_override("margin_right", 110)
	button_margin.add_theme_constant_override("margin_bottom", 18)
	box.add_child(button_margin)
	level_button = GameStyle.make_button("", true, 60)
	level_button.custom_minimum_size = Vector2(0, 136)
	level_button.pulse = true
	level_button.pressed.connect(func() -> void: level_requested.emit())
	button_margin.add_child(level_button)

	box.add_child(_spacer(24))

	# ícones da lateral direita, bem espaçados, na altura do mascote
	var rail := VBoxContainer.new()
	rail.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	rail.anchor_top = 0.27
	rail.anchor_bottom = 0.72
	rail.offset_left = -150
	rail.offset_right = -14
	rail.offset_top = 0
	rail.offset_bottom = 0
	rail.alignment = BoxContainer.ALIGNMENT_CENTER
	rail.add_theme_constant_override("separation", 34)
	add_child(rail)
	for item in [["games", "Jogos"], ["ranking", "Ranking"], ["daily", "Desafios"]]:
		var b := SideButton.new("trophy" if item[0] == "ranking" else ("calendar" if item[0] == "daily" else "games"), item[1])
		var id: String = item[0]
		b.pressed.connect(func() -> void: _on_tab(id))
		rail.add_child(b)
		side_buttons[id] = b


func _on_tab(tab: String) -> void:
	match tab:
		"games": hub_requested.emit()
		"ranking": ranking_requested.emit()
		"daily": daily_requested.emit()


func refresh() -> void:
	_shown_day = GameState.today()
	var month := Rules.month_for(GameState.now_unix())
	points_label.text = str(GameState.month_total(month).points)
	level_button.text = tr("Nível %d") % GameState.current_level()
	side_buttons["daily"].counter = "%d/%d" % [Menus.daily_done(), Rules.DAILY_COUNT]


func _check_new_day() -> void:
	if _shown_day != "" and GameState.today() != _shown_day:
		refresh()  # virou o dia: zera a contagem dos desafios (refresh guarda o dia novo, sem repetir)


static func _spacer(h: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c
