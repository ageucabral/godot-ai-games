extends Control
## Tela inicial do Poção de Cores, como na proposta aprovada (Ageu, 9/11/2026): pontos do mês, a sequência de dias e
## configurações em cima, nome do jogo, o mapa de níveis (os já feitos com estrelas, o de agora em verde e os próximos),
## o botão verde "Nível N" (roxo com "difícil" a cada 10 níveis), logo abaixo o cartão dos desafios do dia (menor,
## com a barra 3/20; trancado até o nível Rules.unlock_level("daily")) e, na lateral
## direita, os ícones Jogos · Ranking (Ageu, 8/11/2026: sem barra embaixo; o perfil fica dentro da engrenagem).
## O evento fica no hub Na Lata (cartão com a trilha de prêmios).

signal level_requested
signal daily_requested
signal ranking_requested
signal hub_requested

const GAME_NAME := "Poção de Cores"
## Ícones da lateral: [nome, texto, ícone].
const SIDE_ITEMS: Array = [["games", "Jogos", "games"], ["ranking", "Ranking", "trophy"], ["missions", "Missões", "missions"]]
## Cor do botão dos desafios: laranja enquanto faltam; roxo quando o dia está completo.
const DAILY_COLOR := Color("ff8a1f")

var points_label: Label
var streak_label: Label
var streak_flame: Extras.FlameIcon
var level_map: LevelMap
var level_button: GlossButton
var daily_button: DailyCard
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
	# desafios do dia, logo abaixo, menor que o nível: cartão com a barra de quantos já foram feitos
	daily_button = DailyCard.new()
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
		"missions": Extras.open_missions(dialog)


func refresh() -> void:
	_shown_day = GameState.today()
	var month := Rules.month_for(GameState.now_unix())
	points_label.text = str(GameState.game_month_total("potion", month).points)
	var level := GameState.current_level()
	var hard := Rules.is_hard_level(level)
	level_button.text = tr("Nível %d · difícil") % level if hard else tr("Nível %d") % level
	level_button.fill = GameStyle.PURPLE if hard else GameStyle.GREEN
	daily_button.set_state(Menus.daily_done(), 0 if Rules.unlocked("daily", level) else Rules.unlock_level("daily"))
	# missões: só pelo servidor e depois de liberadas por nível
	side_buttons["missions"].visible = Rules.unlocked("missions", level) and not GameState.extras.is_empty()
	var s := GameState.streak()
	streak_label.text = str(s.count)
	streak_flame.lit = bool(s.played_today)
	streak_flame.queue_redraw()
	level_map.set_level(GameState.current_level())


func _check_new_day() -> void:
	if _shown_day != "" and GameState.today() != _shown_day:
		refresh()  # virou o dia: zera a contagem dos desafios (refresh guarda o dia novo, sem repetir)


static func _spacer(h: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c


## Cartão dos desafios do dia: claro, menor que o botão do nível, com o nome à esquerda, "3/20" à direita e a barra
## de progresso embaixo. Trancado ("Abre no nível 5") antes de liberar.
class DailyCard extends Button:
	var done: int = 0
	## Nível que libera (0 = liberado).
	var locked_at: int = 0
	## Cor da contagem e da barra: laranja enquanto faltam, roxa com o dia completo.
	var fill: Color = DAILY_COLOR
	var _title: String = ""
	var _count: String = ""
	var _box: StyleBoxFlat = GameStyle.card_box()
	var _track: StyleBoxFlat = _pill(Color("e4dcf5"))
	var _bar: StyleBoxFlat = _pill(DAILY_COLOR)

	func _init() -> void:
		flat = true
		focus_mode = Control.FOCUS_NONE
		auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		custom_minimum_size = Vector2(0, 96)
		_box.set_content_margin_all(0)
		GlossButton.setup_drawn(self)  # o texto é desenhado no _draw (nome à esquerda, contagem à direita)

	## `done_count` desafios de hoje feitos; `lock_level` = nível que libera (0 = liberado). `text` guarda a frase inteira.
	func set_state(done_count: int, lock_level: int) -> void:
		done = done_count
		locked_at = lock_level
		disabled = locked_at > 0
		var complete := done >= Rules.DAILY_COUNT
		_title = tr("Desafios feitos!") if complete else tr("Desafios do dia")
		_count = "%d/%d" % [done, Rules.DAILY_COUNT]
		text = "%s  %s" % [_title, _count]
		fill = GameStyle.PURPLE if complete else DAILY_COLOR
		_bar.bg_color = fill
		_box.bg_color = Color("e8e4f3") if disabled else GameStyle.PAPER
		queue_redraw()

	func _draw() -> void:
		var sink := 3.0 if is_pressed() else 0.0
		var r := Rect2(Vector2(0, sink), Vector2(size.x, size.y - 4))
		draw_style_box(_box, r)
		var font := GameStyle.title_font()
		var y := r.position.y + 42
		var width := size.x - 56
		draw_string(font, Vector2(28, y), _title, HORIZONTAL_ALIGNMENT_LEFT, width, 30, Color(GameStyle.INK, 0.55) if disabled else GameStyle.INK)
		if disabled:
			draw_string(font, Vector2(28, y), tr("Abre no nível %d") % locked_at, HORIZONTAL_ALIGNMENT_RIGHT, width, 26, Color(GameStyle.PURPLE, 0.9))
			return
		draw_string(font, Vector2(28, y), _count, HORIZONTAL_ALIGNMENT_RIGHT, width, 32, fill)
		var bar := Rect2(28, r.position.y + 60, width, 14)
		draw_style_box(_track, bar)
		if done > 0:
			draw_style_box(_bar, Rect2(bar.position, Vector2(maxf(14.0, bar.size.x * minf(1.0, float(done) / Rules.DAILY_COUNT)), bar.size.y)))

	static func _pill(color: Color) -> StyleBoxFlat:
		var b := StyleBoxFlat.new()
		b.set_corner_radius_all(7)
		b.bg_color = color
		return b


## Mapa dos níveis: um caminho de bolinhas subindo a tela, os 2 últimos feitos (dourados, com as estrelas), o de
## agora (verde, maior, pulsando) e os 2 próximos (apagados). Tocar no de agora joga.
class LevelMap extends Control:
	signal play
	## Posição de cada bolinha, de baixo para cima (fração da largura e da altura).
	const SPOTS := [Vector2(0.58, 0.88), Vector2(0.32, 0.68), Vector2(0.56, 0.48), Vector2(0.32, 0.28), Vector2(0.48, 0.09)]
	const PAST := Color("ffc72e")
	const FUTURE := Color("5b5a8c")
	var current: int = 1
	var first: int = 1
	var stars: Dictionary = {}
	## Só a bolinha de agora pulsa: fica num filho que cresce e encolhe (o caminho é desenhado uma vez só).
	var _pulse: Control

	func _init() -> void:
		custom_minimum_size = Vector2(0, 360)
		_pulse = Control.new()
		_pulse.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_pulse.draw.connect(_draw_pulse)
		add_child(_pulse)
		resized.connect(_place_pulse)

	func _ready() -> void:
		var tw := create_tween().set_loops().set_trans(Tween.TRANS_SINE)
		tw.tween_property(_pulse, "scale", Vector2.ONE * 1.04, 1.05)
		tw.tween_property(_pulse, "scale", Vector2.ONE * 0.96, 1.05)

	func set_level(level: int) -> void:
		current = level
		first = maxi(1, level - 2)
		stars = {}
		for n in range(first, level):
			stars[n] = GameState.level_stars(n)
		_place_pulse()
		queue_redraw()

	func _place_pulse() -> void:
		var r := _radius(current) + 14
		_pulse.size = Vector2.ONE * r * 2
		_pulse.pivot_offset = _pulse.size * 0.5
		_pulse.position = _spot(current - first) - _pulse.pivot_offset
		_pulse.queue_redraw()

	func _spot(i: int) -> Vector2:
		var s: Vector2 = SPOTS[i]
		return Vector2(size.x * s.x, size.y * s.y)

	func _radius(n: int) -> float:
		return minf(66.0, size.y * 0.1) if n == current else minf(48.0, size.y * 0.075)

	## Caminho do mapa: uma estrada sinuosa passando por todas as bolinhas (curva suave de Catmull-Rom),
	## com borda escura, chão claro e tracinhos no meio; a parte já percorrida fica dourada.
	func _path_points() -> PackedVector2Array:
		var pts: Array[Vector2] = []
		for i in SPOTS.size():
			pts.append(_spot(i))
		# entra por baixo e sai por cima da tela, para o caminho não "nascer" na primeira bolinha
		pts.push_front(pts[0] * 2.0 - pts[1])  # continua a direção do primeiro trecho
		pts.append(pts[pts.size() - 1] * 2.0 - pts[pts.size() - 2])
		var out := PackedVector2Array()
		for i in range(1, pts.size() - 2):
			var p0 := pts[i - 1]
			var p1 := pts[i]
			var p2 := pts[i + 1]
			var p3 := pts[i + 2]
			for k in 16:
				var t := k / 16.0
				var t2 := t * t
				var t3 := t2 * t
				out.append(0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3))
		out.append(pts[pts.size() - 2])
		return out

	func _draw() -> void:
		var road := _path_points()
		var w := minf(38.0, size.y * 0.1)
		draw_polyline(road, Color(GameStyle.INK, 0.9), w + 10.0, true)
		draw_polyline(road, Color("f6e7c1"), w, true)
		# trecho já percorrido (até a bolinha de agora) fica dourado
		var done := PackedVector2Array()
		var here := _spot(current - first)
		for q in road:
			done.append(q)
			if q.distance_to(here) < 4.0 or (done.size() > 16 and q.y <= here.y):
				break
		if done.size() > 1:
			draw_polyline(done, Color(PAST, 0.85), w, true)
		# tracinhos no meio da estrada
		var acc := 0.0
		for i in road.size() - 1:
			var seg := road[i + 1] - road[i]
			var len := seg.length()
			var t := 0.0
			while t < len:
				var phase := fmod(acc + t, 28.0)
				if phase < 12.0:
					var a := road[i] + seg * (t / len)
					var e := road[i] + seg * (minf(t + 12.0 - phase, len) / len)
					draw_line(a, e, Color(1, 1, 1, 0.8), 4.0, true)
					t += 12.0 - phase
				else:
					t += 28.0 - phase
			acc += len
		for i in SPOTS.size():
			var n := first + i
			if n != current:
				_draw_node(self, _spot(i), n)

	func _draw_pulse() -> void:
		var c := _pulse.size * 0.5
		_pulse.draw_circle(c, _radius(current) + 12, Color(1, 1, 1, 0.35))
		_draw_node(_pulse, c, current)

	## Uma bolinha com o número (e as estrelas, se já foi feita).
	func _draw_node(on: CanvasItem, c: Vector2, n: int) -> void:
		var r := _radius(n)
		on.draw_circle(c, r + 6, GameStyle.INK)
		on.draw_circle(c, r, GameStyle.GREEN if n == current else (PAST if n < current else FUTURE))
		on.draw_circle(c + Vector2(-r * 0.3, -r * 0.35), r * 0.3, Color(1, 1, 1, 0.25))
		var font := GameStyle.title_font()
		var label := str(n)
		var fs := int(r * 0.8)
		var w := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var pos := c + Vector2(-w * 0.5, fs * 0.36)
		on.draw_string_outline(font, pos, label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 6, GameStyle.INK)
		on.draw_string(font, pos, label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.WHITE if n <= current else Color("d9d6f5"))
		if n < current:
			for k in 3:
				GameStyle.draw_star(on, c + Vector2((k - 1) * 22.0, -r - 16.0), 11.0, k < int(stars.get(n, 0)), Color(0, 0, 0, 0.3))

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			var i := current - first
			if i >= 0 and i < SPOTS.size() and event.position.distance_to(_spot(i)) <= _radius(current) + 14:
				play.emit()
