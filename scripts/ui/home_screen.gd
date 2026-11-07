extends Control
## Tela inicial: perfil, pontos do mês, configurações, mascote, ranking e os botões
## "Nível N" (modo por níveis, sem fim) e "Desafios do dia".

signal level_requested
signal daily_requested
signal ranking_requested

const VERSION := "0.4"

var points_label: Label
var level_button: Button
var daily_button: Button
var countdown_label: Label
var podium: PodiumButton
var mascot: MascotView
var avatar_button: IconButton
var settings_button: IconButton
var dialog: DialogBox


func _ready() -> void:
	theme = TropicalStyle.build_theme()
	TropicalStyle.add_background(self)
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
	box.offset_left = 32
	box.offset_right = -32
	box.offset_top = 44
	box.offset_bottom = -56
	box.add_theme_constant_override("separation", 18)
	add_child(box)

	# barra de cima: perfil · pontos do mês · configurações
	var top := HBoxContainer.new()
	box.add_child(top)
	avatar_button = IconButton.new("avatar")
	avatar_button.pressed.connect(open_profile)
	top.add_child(avatar_button)
	var left_space := Control.new()
	left_space.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(left_space)
	var pill := PanelContainer.new()
	pill.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var pill_box := TropicalStyle.card_box()
	pill_box.set_corner_radius_all(40)
	pill_box.content_margin_left = 26
	pill_box.content_margin_right = 30
	pill.add_theme_stylebox_override("panel", pill_box)
	top.add_child(pill)
	var pill_row := HBoxContainer.new()
	pill_row.add_theme_constant_override("separation", 10)
	pill.add_child(pill_row)
	var drop := _DropIcon.new()
	pill_row.add_child(drop)
	points_label = TropicalStyle.make_label("0", 40, true)
	points_label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	pill_row.add_child(points_label)
	var right_space := Control.new()
	right_space.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(right_space)
	settings_button = IconButton.new("gear")
	settings_button.pressed.connect(open_settings)
	top.add_child(settings_button)

	var logo := TropicalStyle.make_label("Na Lata", 150, true, TropicalStyle.ACCENT)
	logo.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	logo.add_theme_color_override("font_outline_color", TropicalStyle.INK)
	logo.add_theme_constant_override("outline_size", 16)
	logo.add_theme_color_override("font_shadow_color", TropicalStyle.INK)
	logo.add_theme_constant_override("shadow_offset_x", 7)
	logo.add_theme_constant_override("shadow_offset_y", 7)
	box.add_child(logo)
	box.add_child(TropicalStyle.make_label("Separe as cores. Acerte em cheio.", 28))

	# meio: mascote no centro e o pódio do ranking à esquerda
	var middle := Control.new()
	middle.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(middle)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	middle.add_child(center)
	mascot = MascotView.new()
	center.add_child(mascot)
	podium = PodiumButton.new()
	podium.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	podium.offset_top = -120
	podium.offset_bottom = 30
	podium.offset_right = 150
	podium.pressed.connect(func() -> void: ranking_requested.emit())
	middle.add_child(podium)

	level_button = TropicalStyle.make_button("", true, 54)
	level_button.add_theme_font_override("font", TropicalStyle.title_font())
	level_button.custom_minimum_size = Vector2(0, 120)
	level_button.pressed.connect(func() -> void: level_requested.emit())
	box.add_child(level_button)
	daily_button = TropicalStyle.make_button("", false, 36)
	daily_button.add_theme_font_override("font", TropicalStyle.title_font())
	daily_button.custom_minimum_size = Vector2(0, 100)
	daily_button.pressed.connect(func() -> void: daily_requested.emit())
	box.add_child(daily_button)
	countdown_label = TropicalStyle.make_label("", 24)
	box.add_child(countdown_label)


## Desafios de hoje já resolvidos.
func daily_done() -> int:
	var today := GameState.today()
	var done := 0
	for i in Rules.DAILY_COUNT:
		if GameState.is_completed(ChallengeGenerator.key_for(today, i)):
			done += 1
	return done


func refresh() -> void:
	var month := Rules.month_for(GameState.now_unix())
	points_label.text = str(GameState.month_total(month).points)
	level_button.text = tr("Nível %d") % GameState.current_level()
	daily_button.text = tr("Desafios do dia · %d/%d") % [daily_done(), Rules.DAILY_COUNT]
	_update_countdown()


func _update_countdown() -> void:
	var now := GameState.now_unix()
	var secs := Rules.seconds_to_next_day(now)
	countdown_label.text = tr("Novos desafios em %dh %02dmin") % [secs / 3600, (secs % 3600) / 60]
	podium.countdown = Rules.short_countdown(Rules.seconds_to_month_end(now))
	if secs >= 86399:
		refresh()  # acabou de virar o dia: zera a contagem dos desafios


# ---------- janelas: perfil e configurações ----------

func open_profile() -> void:
	var month := Rules.month_for(GameState.now_unix())
	var text := tr("Nível atual: %d\nPontos em %s: %d\nDesafios de hoje: %d de %d") % [
		GameState.current_level(), Rules.month_name(month), GameState.month_total(month).points,
		daily_done(), Rules.DAILY_COUNT]
	dialog.open("Seu perfil", text, [["Fechar", func() -> void: pass, true]])


func open_settings() -> void:
	dialog.open("Configurações", tr("Versão %s") % VERSION, [
		[tr("Idioma: %s") % I18n.language_name(GameState.language()), open_language],
		["Salvar progresso", open_save_progress],
		["Como jogar", open_how_to_play],
		["Fechar", func() -> void: pass, true],
	])


func open_language() -> void:
	var buttons: Array = []
	for lang in I18n.LANGUAGES:
		var code: String = lang[0]
		buttons.append([lang[1], func() -> void: GameState.set_language(code), code == GameState.language()])
	buttons.append(["Voltar", open_settings])
	dialog.open("Idioma", "Escolha o idioma do jogo.", buttons)


func open_save_progress() -> void:
	dialog.open("Salvar progresso",
		"Em breve você poderá entrar com Google ou Facebook para guardar seu progresso e aparecer no ranking com todos os jogadores.", [
		["Voltar", open_settings, true],
	])


func open_how_to_play() -> void:
	dialog.open("Como jogar", tr("Toque numa garrafa e depois em outra para despejar. Só dá para despejar em cima da mesma cor ou numa garrafa vazia. Deixe cada garrafa com uma cor só.\n\nNíveis: sem fim, cada vez mais difíceis, valem %d pontos cada.\nDesafios do dia: 20 novos à meia-noite, valem 10, 25 ou 50 pontos.\nCada jogada além do número exato tira 1 ponto.") % Rules.LEVEL_POINTS, [
		["Entendi", func() -> void: pass, true],
	])


## Gotinha de suco ao lado dos pontos.
class _DropIcon extends Control:
	func _init() -> void:
		custom_minimum_size = Vector2(34, 44)
		size_flags_vertical = Control.SIZE_SHRINK_CENTER

	func _draw() -> void:
		var pts := PackedVector2Array()
		var c := Vector2(17, 28)
		pts.append(Vector2(17, 2))
		for i in range(0, 13):
			var a := -0.35 + (PI + 0.7) * i / 12.0
			pts.append(c + Vector2(cos(a), sin(a)) * 13.0)
		draw_colored_polygon(pts, TropicalStyle.LIQUIDS[0])
		var closed := pts.duplicate()
		closed.append(pts[0])
		draw_polyline(closed, TropicalStyle.INK, 3.0, true)
		draw_circle(Vector2(12, 28), 3.0, Color(1, 1, 1, 0.7))
