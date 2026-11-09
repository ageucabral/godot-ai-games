class_name Menus
extends RefCounted
## Janelas usadas no hub e na tela do jogo: configurações (conta, conquistas e frascos, idioma, sons e avisos,
## como jogar, ajuda e termos).
## A conta e a ajuda ficam em `scripts/ui/account.gd`.

const VERSION := "1.3.3"  # igual a version/name em export_presets.cfg (presets Android e Android Play)


## Desafios de hoje já resolvidos.
static func daily_done() -> int:
	var today := GameState.today()
	var done := 0
	for i in Rules.DAILY_COUNT:
		if GameState.is_completed(ChallengeGenerator.key_for(today, i)):
			done += 1
	return done


## Configurações como na proposta: uma lista com ícone, nome e, à direita, "›", o idioma ou uma chave de liga/desliga.
## As chaves mudam na hora, sem fechar a janela. "NOVO" marca as entradas da versão 1.3.2.
static func open_settings(dialog: DialogBox) -> void:
	dialog.open_card("Configurações", "", [])
	dialog.add_row(Row.new("👤", "Sua conta", func() -> void: Account.open_account(dialog)))
	if not GameState.extras.is_empty():
		dialog.add_row(Row.new("🏅", "Conquistas e frascos", func() -> void: Extras.open_collection(dialog), true))
	dialog.add_row(Row.new("🌐", "Idioma", func() -> void: open_language(dialog)).with_value(I18n.language_name(GameState.language())))
	dialog.add_row(Row.new("🎵", "Música", Sfx.set_music_enabled, true).with_switch(Sfx.music_enabled()))
	dialog.add_row(Row.new("🔊", "Sons", Sfx.set_enabled).with_switch(Sfx.enabled()))
	if OS.has_feature("mobile"):
		dialog.add_row(Row.new("📳", "Vibração", Sfx.set_vibration_enabled, true).with_switch(Sfx.vibration_enabled()))
	if Reminders.plugin() != null:
		dialog.add_row(Row.new("🔔", "Avisos no celular", Reminders.set_enabled, true).with_switch(Reminders.enabled()))
	dialog.add_row(Row.new("❓", "Como jogar", func() -> void: open_how_to_play(dialog)))
	dialog.add_row(Row.new("📄", "Ajuda e termos", func() -> void: Account.open_help(dialog)))
	var close := GameStyle.make_button("Fechar", true, 30)
	close.custom_minimum_size = Vector2(0, 84)
	close.pressed.connect(dialog.close)
	dialog.add_row(close)
	var version := GameStyle.make_label(I18n.t("Versão %s") % VERSION, 20, false, Color(GameStyle.INK, 0.5))
	version.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	dialog.add_row(version)


static func open_language(dialog: DialogBox) -> void:
	var buttons: Array = []
	for lang in I18n.LANGUAGES:
		var code: String = lang[0]
		buttons.append([lang[1], func() -> void: GameState.set_language(code), code == GameState.language()])
	buttons.append(["Voltar", func() -> void: open_settings(dialog), true])
	dialog.open("Idioma", "Escolha o idioma do jogo.", buttons)


static func open_how_to_play(dialog: DialogBox) -> void:
	dialog.open("Como jogar", I18n.t("Toque numa garrafa e depois em outra para despejar. Só dá para despejar em cima da mesma cor ou numa garrafa vazia. Deixe cada garrafa com uma cor só.\n\nCada fase vale o dobro das jogadas necessárias: se pede 11 jogadas, vale 22 pontos.\nCada jogada além disso tira 1 ponto, e você vê o placar caindo na hora.\n\nNíveis: sem fim, cada vez mais difíceis.\nDesafios do dia: 20 novos à meia-noite."), [
		["Entendi", func() -> void: pass, true],
	])


## Pílula creme com moedinha e um número (pontos do mês).
static func make_coin_pill(label_out: Array) -> PanelContainer:
	var pill := PanelContainer.new()
	pill.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var style := GameStyle.pill_box()
	style.content_margin_left = 6
	pill.add_theme_stylebox_override("panel", style)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	pill.add_child(row)
	row.add_child(CoinIcon.new(26.0))
	var l := GameStyle.make_label("0", 38, true, Color("6b3d10"))
	l.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	l.custom_minimum_size = Vector2(110, 0)
	row.add_child(l)
	label_out.append(l)
	return pill


## Uma linha das configurações. Sem chave: tocar fecha a janela e chama `action`. Com chave (`with_switch`):
## tocar vira a chave na hora e chama `action(ligada)`, sem fechar.
class Row extends Button:
	var action: Callable
	var _right: HBoxContainer
	var _switch: Switch

	func _init(icon: String, label: String, on_press: Callable, is_new: bool = false) -> void:
		action = on_press
		set_meta("label", label)
		flat = true
		focus_mode = Control.FOCUS_NONE
		custom_minimum_size = Vector2(0, 76)
		for st in ["normal", "hover", "pressed"]:
			var box := StyleBoxFlat.new()
			box.bg_color = Color(GameStyle.INK, 0.06) if st == "pressed" else Color(0, 0, 0, 0)
			box.border_color = Color(GameStyle.INK, 0.12)
			box.border_width_bottom = 2
			add_theme_stylebox_override(st, box)
		var row := HBoxContainer.new()
		row.set_anchors_preset(Control.PRESET_FULL_RECT)
		row.offset_left = 6
		row.offset_right = -6
		row.add_theme_constant_override("separation", 12)
		add_child(row)
		var ic := GameStyle.make_label(icon, 30)
		ic.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		row.add_child(ic)
		var name := GameStyle.make_label(label, 28, true)
		name.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		row.add_child(name)
		if is_new:
			row.add_child(_new_pill())
		var space := Control.new()
		space.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(space)
		_right = HBoxContainer.new()
		row.add_child(_right)
		_right.add_child(GameStyle.make_label("›", 40, true, Color(GameStyle.INK, 0.6)))
		for c in row.get_children():
			(c as Control).size_flags_vertical = Control.SIZE_SHRINK_CENTER
		Extras._ignore_mouse(self)
		pressed.connect(_on_pressed)

	## Mostra um valor à direita (ex.: o idioma) no lugar do "›".
	func with_value(text: String) -> Row:
		_right.get_child(0).queue_free()
		var v := GameStyle.make_label(text, 26, true, GameStyle.ACCENT)
		v.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		_right.add_child(v)
		return self

	## Troca o "›" por uma chave de liga/desliga.
	func with_switch(on: bool) -> Row:
		_right.get_child(0).queue_free()
		_switch = Switch.new()
		_switch.on = on
		_right.add_child(_switch)
		return self

	func _on_pressed() -> void:
		if _switch != null:
			_switch.on = not _switch.on
			_switch.queue_redraw()
			action.call(_switch.on)
			return
		var dialog := get_parent()
		while dialog != null and not dialog is DialogBox:
			dialog = dialog.get_parent()
		if dialog != null:
			(dialog as DialogBox).close()
		action.call()

	static func _new_pill() -> Control:
		var p := PanelContainer.new()
		var st := StyleBoxFlat.new()
		st.bg_color = Color("ff4f6d")
		st.set_corner_radius_all(14)
		st.content_margin_left = 10
		st.content_margin_right = 10
		st.content_margin_top = 1
		st.content_margin_bottom = 1
		p.add_theme_stylebox_override("panel", st)
		p.add_child(GameStyle.make_label("NOVO", 18, true, Color.WHITE))
		return p


## Chave verde de liga/desliga.
class Switch extends Control:
	var on: bool = false

	func _init() -> void:
		custom_minimum_size = Vector2(92, 52)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	static var _on_box := _box(GameStyle.GREEN)
	static var _off_box := _box(Color("cfc8dc"))

	static func _box(color: Color) -> StyleBoxFlat:
		var st := StyleBoxFlat.new()
		st.bg_color = color
		st.border_color = GameStyle.INK
		st.set_border_width_all(4)
		st.set_corner_radius_all(26)
		return st

	func _draw() -> void:
		var r := size.y * 0.5
		draw_style_box(_on_box if on else _off_box, Rect2(Vector2.ZERO, size))
		var knob := Vector2(size.x - r if on else r, r)
		draw_circle(knob, r - 9, Color.WHITE)
