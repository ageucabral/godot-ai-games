extends Control
## Tela inicial do Poção de Cores, como na proposta aprovada (Ageu, 9/11/2026): pontos do mês, a sequência de dias e
## configurações em cima, nome do jogo, o mapa de níveis (os já feitos com estrelas, o de agora em verde e os próximos),
## o botão verde "Nível N", logo abaixo o botão laranja dos desafios do dia (com quantos já foram feitos) e, na lateral
## direita, os ícones Jogos · Ranking (Ageu, 8/11/2026: sem barra embaixo; o perfil fica dentro da engrenagem).
## O evento fica no hub Na Lata (cartão com a trilha de prêmios).

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
var streak_label: Label
var streak_flame: Extras.FlameIcon
var level_map: LevelMap
var level_button: GlossButton
var daily_button: GlossButton
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
	box.add_child(GameStyle.make_title(GAME_NAME, 66))

	# meio: o mapa dos níveis (tocar no de agora joga)
	level_map = LevelMap.new()
	level_map.size_flags_vertical = Control.SIZE_EXPAND_FILL
	level_map.play.connect(func() -> void: level_requested.emit())
	box.add_child(level_map)

	var button_margin := MarginContainer.new()
	button_margin.add_theme_constant_override("margin_left", 30)
	button_margin.add_theme_constant_override("margin_right", 30)
	button_margin.add_theme_constant_override("margin_bottom", 10)
	box.add_child(button_margin)
	var buttons := VBoxContainer.new()
	buttons.add_theme_constant_override("separation", 18)
	button_margin.add_child(buttons)
	level_button = GameStyle.make_button("", true, 52)
	level_button.custom_minimum_size = Vector2(0, 112)
	level_button.pulse = true
	level_button.pressed.connect(func() -> void: level_requested.emit())
	buttons.add_child(level_button)
	# desafios do dia, logo abaixo: mostra quantos já foram feitos
	daily_button = GameStyle.make_button("", false, 34, DAILY_COLOR)
	daily_button.custom_minimum_size = Vector2(0, 88)
	daily_button.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	daily_button.pressed.connect(func() -> void: daily_requested.emit())
	buttons.add_child(daily_button)

	box.add_child(_spacer(36))

	# ícones da lateral direita, bem espaçados, na altura do mapa
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
	level_map.set_level(GameState.current_level())


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


## Mapa dos níveis: um caminho de bolinhas subindo a tela, os 2 últimos feitos (dourados, com as estrelas), o de
## agora (verde, maior, pulsando) e os 2 próximos (apagados). Tocar no de agora joga.
class LevelMap extends Control:
	signal play
	const SHOWN := 5
	## Posição de cada bolinha, de baixo para cima (fração da largura e da altura).
	const SPOTS := [Vector2(0.58, 0.88), Vector2(0.32, 0.68), Vector2(0.56, 0.48), Vector2(0.32, 0.28), Vector2(0.48, 0.09)]
	const PAST := Color("ffc72e")
	const FUTURE := Color("5b5a8c")
	var current: int = 1
	var first: int = 1
	var stars: Dictionary = {}
	var _time: float = 0.0

	func _init() -> void:
		custom_minimum_size = Vector2(0, 360)

	func set_level(level: int) -> void:
		current = level
		first = maxi(1, level - 2)
		stars = {}
		for n in range(first, level):
			stars[n] = GameState.level_stars(n)
		queue_redraw()

	func _process(delta: float) -> void:
		if not is_visible_in_tree():
			return  # com o menu escondido (partida, ranking) não precisa redesenhar
		_time += delta
		queue_redraw()

	func _spot(i: int) -> Vector2:
		var s: Vector2 = SPOTS[i]
		return Vector2(size.x * s.x, size.y * s.y)

	func _radius(n: int) -> float:
		return minf(66.0, size.y * 0.1) if n == current else minf(48.0, size.y * 0.075)

	func _draw() -> void:
		# trilha de pontinhos brancos entre as bolinhas (curva suave)
		for i in SHOWN - 1:
			var a := _spot(i)
			var b := _spot(i + 1)
			var ctrl := (a + b) * 0.5 + Vector2((b.y - a.y) * 0.35, 0)
			var length := a.distance_to(b)
			var dots := int(length / 24.0)
			for k in range(1, dots):
				var t := float(k) / dots
				var p := a.lerp(ctrl, t).lerp(ctrl.lerp(b, t), t)
				draw_circle(p, 6.0, Color(1, 1, 1, 0.85))
		var font := GameStyle.title_font()
		for i in SHOWN:
			var n := first + i
			var c := _spot(i)
			var r := _radius(n)
			if n == current:
				r *= 1.0 + 0.04 * sin(_time * 3.0)
				draw_circle(c, r + 12, Color(1, 1, 1, 0.35))
			draw_circle(c, r + 6, GameStyle.INK)
			draw_circle(c, r, GameStyle.GREEN if n == current else (PAST if n < current else FUTURE))
			draw_circle(c + Vector2(-r * 0.3, -r * 0.35), r * 0.3, Color(1, 1, 1, 0.25))
			var label := str(n)
			var fs := int(r * 0.8)
			var w := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			var pos := c + Vector2(-w * 0.5, fs * 0.36)
			draw_string_outline(font, pos, label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 6, GameStyle.INK)
			draw_string(font, pos, label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.WHITE if n <= current else Color("d9d6f5"))
			if n < current:
				for k in 3:
					GameStyle.draw_star(self, c + Vector2((k - 1) * 22.0, -r - 16.0), 11.0, k < int(stars.get(n, 0)), Color(0, 0, 0, 0.3))

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			var i := current - first
			if i >= 0 and i < SHOWN and event.position.distance_to(_spot(i)) <= _radius(current) + 14:
				play.emit()
