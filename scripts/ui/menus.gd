class_name Menus
extends RefCounted
## Janelas usadas no hub e na tela do jogo: perfil e configurações (idioma, salvar progresso, como jogar).

const VERSION := "0.5.0"  # igual a version/name em export_presets.cfg


## Desafios de hoje já resolvidos.
static func daily_done() -> int:
	var today := GameState.today()
	var done := 0
	for i in Rules.DAILY_COUNT:
		if GameState.is_completed(ChallengeGenerator.key_for(today, i)):
			done += 1
	return done


static func open_profile(dialog: DialogBox) -> void:
	var month := Rules.month_for(GameState.now_unix())
	var text := I18n.t("Nível atual: %d\nPontos em %s: %d\nDesafios de hoje: %d de %d") % [
		GameState.current_level(), Rules.month_name(month), GameState.month_total(month).points,
		daily_done(), Rules.DAILY_COUNT]
	dialog.open("Seu perfil", text, [["Fechar", func() -> void: pass, true]])


static func open_settings(dialog: DialogBox) -> void:
	dialog.open("Configurações", I18n.t("Versão %s") % VERSION, [
		[I18n.t("Idioma: %s") % I18n.language_name(GameState.language()), func() -> void: open_language(dialog)],
		["Salvar progresso", func() -> void: open_save_progress(dialog)],
		["Como jogar", func() -> void: open_how_to_play(dialog)],
		["Fechar", func() -> void: pass, true],
	])


static func open_language(dialog: DialogBox) -> void:
	var buttons: Array = []
	for lang in I18n.LANGUAGES:
		var code: String = lang[0]
		buttons.append([lang[1], func() -> void: GameState.set_language(code), code == GameState.language()])
	buttons.append(["Voltar", func() -> void: open_settings(dialog)])
	dialog.open("Idioma", "Escolha o idioma do jogo.", buttons)


static func open_save_progress(dialog: DialogBox) -> void:
	dialog.open("Salvar progresso",
		"Em breve você poderá entrar com Google ou Facebook para guardar seu progresso e aparecer no ranking com todos os jogadores.", [
		["Voltar", func() -> void: open_settings(dialog), true],
	])


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
