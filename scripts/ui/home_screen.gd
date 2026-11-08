extends Control
## Tela inicial do Poção de Cores, enxuta: pontos do mês e configurações em cima, nome do jogo,
## mascote, o botão verde "Nível N", logo abaixo o botão laranja dos desafios do dia (com quantos já
## foram feitos) e, na lateral direita, os ícones Jogos · Ranking
## (Ageu, 8/11/2026: sem barra embaixo; o perfil fica dentro da engrenagem).

signal level_requested
signal daily_requested
signal ranking_requested
signal hub_requested

const GAME_NAME := "Poção de Cores"
## Ícones da lateral: [nome, texto, ícone].
const SIDE_ITEMS: Array = [["games", "Jogos", "games"], ["ranking", "Ranking", "trophy"]]
## Cor do botão dos desafios: laranja enquanto faltam; roxo quando o dia está completo.
const DAILY_COLOR := Color("ff8a1f")

var points_label: Label
var level_button: GlossButton
var daily_button: GlossButton
var mascot: MascotView
var settings_button: IconButton
## Ícones da lateral, por nome: "games", "ranking".
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
	var buttons := VBoxContainer.new()
	buttons.add_theme_constant_override("separation", 22)
	button_margin.add_child(buttons)
	level_button = GameStyle.make_button("", true, 60)
	level_button.custom_minimum_size = Vector2(0, 128)
	level_button.pulse = true
	level_button.pressed.connect(func() -> void: level_requested.emit())
	buttons.add_child(level_button)
	# desafios do dia, logo abaixo: mostra quantos já foram feitos
	daily_button = GameStyle.make_button("", false, 38, DAILY_COLOR)
	daily_button.custom_minimum_size = Vector2(0, 100)
	daily_button.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	daily_button.pressed.connect(func() -> void: daily_requested.emit())
	buttons.add_child(daily_button)

	box.add_child(_spacer(44))

	# ícones da lateral direita, bem espaçados, na altura do mascote
	var rail := VBoxContainer.new()
	rail.anchor_left = 1.0
	rail.anchor_right = 1.0
	rail.anchor_top = 0.27
	rail.anchor_bottom = 0.72
	rail.offset_left = -150
	rail.offset_right = -14
	rail.alignment = BoxContainer.ALIGNMENT_CENTER
	rail.add_theme_constant_override("separation", 34)
	add_child(rail)
	for item: Array in SIDE_ITEMS:
		var id: String = item[0]
		var b := SideButton.new(item[2], item[1])
		b.pressed.connect(func() -> void: _on_tab(id))
		rail.add_child(b)
		side_buttons[id] = b


func _on_tab(tab: String) -> void:
	match tab:
		"games": hub_requested.emit()
		"ranking": ranking_requested.emit()


func refresh() -> void:
	_shown_day = GameState.today()
	var month := Rules.month_for(GameState.now_unix())
	points_label.text = str(GameState.game_month_total("potion", month).points)
	level_button.text = tr("Nível %d") % GameState.current_level()
	var done := Menus.daily_done()
	daily_button.text = daily_text(done)
	daily_button.fill = GameStyle.PURPLE if done >= Rules.DAILY_COUNT else DAILY_COLOR
	daily_button.queue_redraw()


## Texto do botão dos desafios: "Desafios do dia 3/20"; com o dia completo, "Desafios feitos! 20/20".
func daily_text(done: int) -> String:
	var label := tr("Desafios feitos!") if done >= Rules.DAILY_COUNT else tr("Desafios do dia")
	return "%s  %d/%d" % [label, done, Rules.DAILY_COUNT]


func _check_new_day() -> void:
	if _shown_day != "" and GameState.today() != _shown_day:
		refresh()  # virou o dia: zera a contagem dos desafios (refresh guarda o dia novo, sem repetir)


static func _spacer(h: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c
