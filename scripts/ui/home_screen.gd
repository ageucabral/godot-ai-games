extends Control
## Tela inicial do Poção de Cores, enxuta: pontos do mês, a sequência de dias e configurações em cima, nome do jogo,
## mascote, o caminho dos últimos níveis com as estrelas, o botão verde "Nível N", logo abaixo o botão laranja dos
## desafios do dia (com quantos já foram feitos), o botão do evento (só com um evento no ar) e, na lateral direita,
## os ícones Jogos · Ranking (Ageu, 8/11/2026: sem barra embaixo; o perfil fica dentro da engrenagem).

signal level_requested
signal daily_requested
signal ranking_requested
signal hub_requested
signal event_requested

const GAME_NAME := "Poção de Cores"
## Ícones da lateral: [nome, texto, ícone].
const SIDE_ITEMS: Array = [["games", "Jogos", "games"], ["ranking", "Ranking", "trophy"]]
## Cor do botão dos desafios: laranja enquanto faltam; roxo quando o dia está completo.
const DAILY_COLOR := Color("ff8a1f")

var points_label: Label
var streak_label: Label
var streak_flame: Extras.FlameIcon
var level_path: LevelPath
var event_button: GlossButton
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
	top.add_theme_constant_override("separation", 14)
	top.add_child(_make_streak_chip())
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
	level_path = LevelPath.new()
	buttons.add_child(level_path)
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
	# evento de tempo limitado (só aparece com um evento no ar e fases a fazer)
	event_button = GameStyle.make_button("", false, 32, Color("e04fd0"))
	event_button.custom_minimum_size = Vector2(0, 84)
	event_button.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	event_button.pressed.connect(func() -> void: event_requested.emit())
	buttons.add_child(event_button)

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


## Pílula da sequência de dias (chama + número); tocar explica as recompensas.
func _make_streak_chip() -> PanelContainer:
	var pill := PanelContainer.new()
	pill.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var style := GameStyle.pill_box()
	style.content_margin_left = 12
	pill.add_theme_stylebox_override("panel", style)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 6)
	pill.add_child(row)
	streak_flame = Extras.FlameIcon.new(20.0)
	row.add_child(streak_flame)
	streak_label = GameStyle.make_label("0", 38, true, Color("6b3d10"))
	streak_label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	row.add_child(streak_label)
	pill.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and not e.pressed:
			Extras.open_streak(dialog))
	return pill


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
	var s := GameState.streak()
	streak_label.text = str(s.count)
	streak_flame.lit = bool(s.played_today)
	streak_flame.queue_redraw()
	level_path.set_levels(GameState.current_level())
	var ev: Variant = GameState.extras.get("event")
	event_button.visible = ev is Dictionary and int(ev.get("done", 0)) < int(ev.get("levels", 0))
	if event_button.visible:
		event_button.text = "%s  %d/%d" % [str(ev.get("name", "")), int(ev.get("done", 0)), int(ev.get("levels", 0))]
		event_button.fill = Extras.EVENT_COLORS.get(str(ev.get("theme", "")), Color("e04fd0"))
		event_button.queue_redraw()


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


## Caminho dos últimos níveis: bolinhas com o número e as estrelas de cada um, terminando no nível de agora.
class LevelPath extends Control:
	const SHOWN := 5
	var current: int = 1
	var stars: Array[int] = []

	func _init() -> void:
		custom_minimum_size = Vector2(0, 96)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func set_levels(level: int) -> void:
		current = level
		stars = []
		for n in range(maxi(1, level - SHOWN + 1), level):
			stars.append(GameState.level_stars(n))
		visible = level > 1
		queue_redraw()

	func _draw() -> void:
		var count := stars.size() + 1
		var first := current - stars.size()
		var step := size.x / SHOWN
		var x0 := (size.x - step * (count - 1)) * 0.5
		var y := 34.0
		draw_line(Vector2(x0, y), Vector2(x0 + step * (count - 1), y), Color(1, 1, 1, 0.55), 6.0, true)
		var font := GameStyle.title_font()
		for i in count:
			var c := Vector2(x0 + step * i, y)
			var now := i == count - 1
			var r := 30.0 if now else 24.0
			draw_circle(c, r + 4, GameStyle.INK)
			draw_circle(c, r, GameStyle.GREEN if now else Color("7d43e8"))
			var label := str(first + i)
			var fs := 26 if now else 22
			var w := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			draw_string(font, c + Vector2(-w * 0.5, fs * 0.36), label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.WHITE)
			if now:
				continue
			for k in 3:
				var sc := c + Vector2((k - 1) * 18.0, 42.0)
				var pts := GameStyle.star_points(sc, 9.0, 4.3, 5)
				draw_colored_polygon(pts, GameStyle.GOLD if k < stars[i] else Color(0, 0, 0, 0.3))
				var ring := pts.duplicate()
				ring.append(pts[0])
				draw_polyline(ring, GameStyle.INK, 2.0, true)
