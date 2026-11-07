extends Control
## Tela inicial: os 20 desafios de HOJE (dias anteriores não podem ser jogados), o botão de jogar e o acesso ao ranking.

signal play_requested(date: String, index: int)
signal ranking_requested

## Dia mostrado: sempre hoje (atualizado em refresh; serve também para perceber a meia-noite).
var date: String = ""
var day_label: Label
var progress_label: Label
var play_button: Button
var month_label: Label
var countdown_label: Label
var grid: GridContainer


func _ready() -> void:
	theme = TropicalStyle.build_theme()
	TropicalStyle.add_background(self)
	_build()
	date = GameState.today()
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
	box.offset_left = 36
	box.offset_right = -36
	box.offset_top = 70
	box.offset_bottom = -50
	box.add_theme_constant_override("separation", 18)
	add_child(box)

	var logo := TropicalStyle.make_label("Na Lata", 132, true, TropicalStyle.ACCENT)
	logo.add_theme_color_override("font_outline_color", TropicalStyle.INK)
	logo.add_theme_constant_override("outline_size", 14)
	logo.add_theme_color_override("font_shadow_color", TropicalStyle.INK)
	logo.add_theme_constant_override("shadow_offset_x", 6)
	logo.add_theme_constant_override("shadow_offset_y", 6)
	box.add_child(logo)
	box.add_child(TropicalStyle.make_label("Separe as cores. Acerte em cheio.", 28))

	day_label = TropicalStyle.make_label("", 34, true)
	box.add_child(day_label)

	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", TropicalStyle.card_box())
	box.add_child(card)
	var card_box := VBoxContainer.new()
	card_box.add_theme_constant_override("separation", 14)
	card.add_child(card_box)
	var header := HBoxContainer.new()
	var h1 := TropicalStyle.make_label("Desafios do dia", 30)
	h1.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	h1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progress_label = TropicalStyle.make_label("", 30)
	header.add_child(h1)
	header.add_child(progress_label)
	card_box.add_child(header)
	grid = GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	card_box.add_child(grid)
	for i in Rules.DAILY_COUNT:
		var cell := Button.new()
		cell.custom_minimum_size = Vector2(108, 84)
		cell.add_theme_font_size_override("font_size", 30)
		cell.pressed.connect(func() -> void: play_requested.emit(date, i))
		grid.add_child(cell)
	var legend := HBoxContainer.new()
	legend.alignment = BoxContainer.ALIGNMENT_CENTER
	legend.add_theme_constant_override("separation", 26)
	for diff in [Rules.EASY, Rules.MEDIUM, Rules.HARD]:
		var item := HBoxContainer.new()
		item.add_theme_constant_override("separation", 8)
		var swatch := Panel.new()
		swatch.custom_minimum_size = Vector2(22, 22)
		swatch.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var sb := StyleBoxFlat.new()
		sb.bg_color = TropicalStyle.DIFFICULTY_COLORS[diff]
		sb.border_color = TropicalStyle.INK
		sb.set_border_width_all(3)
		sb.set_corner_radius_all(6)
		swatch.add_theme_stylebox_override("panel", sb)
		item.add_child(swatch)
		item.add_child(TropicalStyle.make_label("%s · %d pts" % [Rules.DIFFICULTY_NAMES[diff], Rules.FULL_POINTS[diff]], 22))
		legend.add_child(item)
	card_box.add_child(legend)

	play_button = TropicalStyle.make_button("", true, 40)
	play_button.add_theme_font_override("font", TropicalStyle.title_font())
	play_button.pressed.connect(_on_play_pressed)
	box.add_child(play_button)
	var ranking_button := TropicalStyle.make_button("Ranking do mês", false, 34)
	ranking_button.add_theme_font_override("font", TropicalStyle.title_font())
	ranking_button.pressed.connect(func() -> void: ranking_requested.emit())
	box.add_child(ranking_button)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(spacer)
	month_label = TropicalStyle.make_label("", 26)
	box.add_child(month_label)
	countdown_label = TropicalStyle.make_label("", 24)
	box.add_child(countdown_label)


## Primeiro desafio ainda não resolvido do dia (-1 se todos feitos).
func next_unsolved() -> int:
	for i in Rules.DAILY_COUNT:
		if not GameState.is_completed(ChallengeGenerator.key_for(date, i)):
			return i
	return -1


func refresh() -> void:
	if date == "":
		return
	date = GameState.today()  # só os desafios de hoje podem ser jogados
	day_label.text = "Hoje, " + Rules.pretty_date(date)
	var done := 0
	for i in Rules.DAILY_COUNT:
		var key := ChallengeGenerator.key_for(date, i)
		var r := GameState.result(key)
		var cell: Button = grid.get_child(i)
		var diff := Rules.difficulty_for(i)
		_style_cell(cell, TropicalStyle.DIFFICULTY_COLORS[diff], r.completed)
		if r.completed:
			done += 1
			cell.text = "%d pts" % r.best_points
			cell.add_theme_font_size_override("font_size", 22)
		else:
			cell.text = str(i + 1)
			cell.add_theme_font_size_override("font_size", 30)
	progress_label.text = "%d de %d" % [done, Rules.DAILY_COUNT]
	var next := next_unsolved()
	play_button.text = "Jogar desafio %d" % (next + 1) if next >= 0 else "Todos resolvidos!"
	play_button.disabled = next < 0
	var month := Rules.month_for(GameState.now_unix())
	var total := GameState.month_total(month)
	month_label.text = "Seus pontos em %s: %d" % [Rules.month_name(month), total.points]
	_update_countdown()


func _on_play_pressed() -> void:
	var next := next_unsolved()
	if next >= 0:
		play_requested.emit(date, next)


func _update_countdown() -> void:
	if date != "" and GameState.today() != date:
		refresh()  # virou o dia com o menu aberto: mostra os desafios novos
		return
	var secs := Rules.seconds_to_next_day(GameState.now_unix())
	countdown_label.text = "Novos desafios em %dh %02dmin" % [secs / 3600, (secs % 3600) / 60]


func _style_cell(cell: Button, fill: Color, done: bool) -> void:
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		var b := StyleBoxFlat.new()
		b.bg_color = fill.lerp(Color.WHITE, 0.55) if done else fill
		if state == "pressed":
			b.bg_color = b.bg_color.darkened(0.1)
		if state == "focus":
			b.draw_center = false
		b.border_color = TropicalStyle.INK if state != "focus" else Color(TropicalStyle.INK, 0.0)
		b.set_border_width_all(4)
		b.set_corner_radius_all(18)
		cell.add_theme_stylebox_override(state, b)
	cell.add_theme_color_override("font_color", TropicalStyle.INK)
	cell.add_theme_color_override("font_hover_color", TropicalStyle.INK)
	cell.add_theme_color_override("font_pressed_color", TropicalStyle.INK)
	cell.add_theme_color_override("font_focus_color", TropicalStyle.INK)
