class_name Menus
extends RefCounted
## Janelas usadas no hub e na tela do jogo: configurações (conta, conquistas e frascos, idioma, sons e avisos,
## como jogar, ajuda e termos).
## A conta e a ajuda ficam em `scripts/ui/account.gd`.

const VERSION := "1.3.2"  # igual a version/name em export_presets.cfg (presets Android e Android Play)


## Desafios de hoje já resolvidos.
static func daily_done() -> int:
	var today := GameState.today()
	var done := 0
	for i in Rules.DAILY_COUNT:
		if GameState.is_completed(ChallengeGenerator.key_for(today, i)):
			done += 1
	return done


static func open_settings(dialog: DialogBox) -> void:
	var buttons: Array = [["Sua conta", func() -> void: Account.open_account(dialog)]]
	if not GameState.extras.is_empty():
		buttons.append(["Conquistas e frascos", func() -> void: Extras.open_achievements(dialog)])
	buttons.append_array([
		[I18n.t("Idioma: %s") % I18n.language_name(GameState.language()), func() -> void: open_language(dialog)],
		["Sons e avisos", func() -> void: open_sounds(dialog)],
		["Como jogar", func() -> void: open_how_to_play(dialog)],
		["Ajuda e termos", func() -> void: Account.open_help(dialog)],
		["Fechar", func() -> void: pass, true],
	])
	dialog.open("Configurações", I18n.t("Versão %s") % VERSION, buttons)


## Som, música e o aviso do dia no celular (este só no app do Android).
static func open_sounds(dialog: DialogBox) -> void:
	var buttons: Array = [
		[I18n.t("Som: ligado") if Sfx.enabled() else I18n.t("Som: desligado"), func() -> void:
			Sfx.set_enabled(not Sfx.enabled())
			open_sounds(dialog)],
		[I18n.t("Música: ligada") if Sfx.music_enabled() else I18n.t("Música: desligada"), func() -> void:
			Sfx.set_music_enabled(not Sfx.music_enabled())
			open_sounds(dialog)],
	]
	if Reminders.plugin() != null:
		buttons.append([I18n.t("Avisos no celular: ligados") if Reminders.enabled() else I18n.t("Avisos no celular: desligados"), func() -> void:
			await Reminders.set_enabled(not Reminders.enabled())
			open_sounds(dialog)])
	buttons.append(["Voltar", func() -> void: open_settings(dialog), true])
	dialog.open("Sons e avisos", "", buttons)


static func open_language(dialog: DialogBox) -> void:
	var buttons: Array = []
	for lang in I18n.LANGUAGES:
		var code: String = lang[0]
		buttons.append([lang[1], func() -> void: GameState.set_language(code), code == GameState.language()])
	buttons.append(["Voltar", func() -> void: open_settings(dialog)])
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
