extends Control
## Tela inicial do Poção de Cores, enxuta: pontos do mês e configurações em cima, nome do jogo,
## mascote, o botão verde "Nível N" e a barra de baixo (Jogos · Ranking · Início · Desafios · Perfil).
## Cada lugar tem um caminho só: ranking, desafios e perfil ficam na barra de baixo.

signal level_requested
signal daily_requested
signal ranking_requested
signal hub_requested

const GAME_NAME := "Poção de Cores"

var points_label: Label
var level_button: GlossButton
var mascot: MascotView
var settings_button: IconButton
var nav: NavBar
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

	nav = NavBar.new()
	nav.tab_pressed.connect(_on_tab)
	box.add_child(nav)


func _on_tab(tab: String) -> void:
	match tab:
		"games": hub_requested.emit()
		"ranking": ranking_requested.emit()
		"daily": daily_requested.emit()
		"profile": Menus.open_profile(dialog)


func refresh() -> void:
	_shown_day = GameState.today()
	var month := Rules.month_for(GameState.now_unix())
	points_label.text = str(GameState.month_total(month).points)
	level_button.text = tr("Nível %d") % GameState.current_level()
	nav.set_counter("daily", "%d/%d" % [Menus.daily_done(), Rules.DAILY_COUNT])


func _check_new_day() -> void:
	if _shown_day != "" and GameState.today() != _shown_day:
		refresh()  # virou o dia: zera a contagem dos desafios (refresh guarda o dia novo, sem repetir)
