extends Control
## Tela inicial do Poção de Cores: pontos do mês, configurações, selos de ranking e desafios do dia,
## mascote, o botão verde "Nível N" e a barra de baixo (Jogos · Ranking · Início · Desafios · Perfil).

signal level_requested
signal daily_requested
signal ranking_requested
signal hub_requested

const GAME_NAME := "Poção de Cores"

var points_label: Label
var level_button: GlossButton
var daily_badge: BadgeButton
var ranking_badge: BadgeButton
var mascot: MascotView
var avatar_button: IconButton
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
	timer.timeout.connect(_update_countdown)
	add_child(timer)


func _build() -> void:
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_top = 40
	box.add_theme_constant_override("separation", 10)
	add_child(box)

	# barra de cima: perfil · moedas (pontos do mês) · configurações
	var top_margin := MarginContainer.new()
	top_margin.add_theme_constant_override("margin_left", 26)
	top_margin.add_theme_constant_override("margin_right", 26)
	box.add_child(top_margin)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 18)
	top_margin.add_child(top)
	avatar_button = IconButton.new("avatar")
	avatar_button.pressed.connect(func() -> void: Menus.open_profile(dialog))
	top.add_child(avatar_button)
	var out: Array = []
	top.add_child(Menus.make_coin_pill(out))
	points_label = out[0]
	var space := Control.new()
	space.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(space)
	settings_button = IconButton.new("gear")
	settings_button.pressed.connect(func() -> void: Menus.open_settings(dialog))
	top.add_child(settings_button)

	# selos: ranking (esquerda) e desafios do dia (direita)
	var badges := HBoxContainer.new()
	box.add_child(badges)
	var badge_margin := Control.new()
	badge_margin.custom_minimum_size = Vector2(14, 0)
	badges.add_child(badge_margin)
	ranking_badge = BadgeButton.new("podium")
	ranking_badge.pressed.connect(func() -> void: ranking_requested.emit())
	badges.add_child(ranking_badge)
	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_box.add_theme_constant_override("separation", -10)
	badges.add_child(title_box)
	var hub_label := GameStyle.make_title("Na Lata", 30, GameStyle.GOLD)
	hub_label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	title_box.add_child(hub_label)
	var logo := GameStyle.make_title(GAME_NAME, 54)
	logo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_box.add_child(logo)
	daily_badge = BadgeButton.new("calendar")
	daily_badge.ring = Color("5bc0ff")
	daily_badge.pressed.connect(func() -> void: daily_requested.emit())
	badges.add_child(daily_badge)
	var badge_margin2 := Control.new()
	badge_margin2.custom_minimum_size = Vector2(14, 0)
	badges.add_child(badge_margin2)

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
	daily_badge.counter = "%d/%d" % [Menus.daily_done(), Rules.DAILY_COUNT]
	_update_countdown()


func _update_countdown() -> void:
	var now := GameState.now_unix()
	var secs := Rules.seconds_to_next_day(now)
	daily_badge.caption = "%dh %02dm" % [secs / 3600, (secs % 3600) / 60]
	ranking_badge.caption = Rules.short_countdown(Rules.seconds_to_month_end(now))
	if _shown_day != "" and GameState.today() != _shown_day:
		refresh()  # virou o dia: zera a contagem dos desafios (refresh guarda o dia novo, sem repetir)
