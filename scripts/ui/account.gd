class_name Account
extends RefCounted
## Telas da conta pelo servidor (só no Android, jogando pelo servidor):
## - primeira abertura: idade (com o código de convite, se veio pelo link da Play);
## - depois de entrar com Google: país e apelido (precisa deles para concorrer a prêmios);
## - "Sua conta" (engrenagem): apelido, país, apagar conta;
## - "Ajuda e termos": fale conosco, privacidade, termos e regulamento;
## - aviso de manutenção e de versão antiga (não deixa jogar).
## Os prêmios (convite e resgate) ficam em `scripts/ui/prizes.gd`.


# ---------- manutenção e versão mínima ----------

## Mostra o aviso que não deixa jogar (versão antiga ou manutenção). Devolve true se bloqueou.
static func check_gate(dialog: DialogBox) -> bool:
	var cfg: Dictionary = Server.config
	if cfg.is_empty():
		return false
	var min_version := str(cfg.get("minAppVersion", ""))
	if not min_version.is_empty() and ApiClient.version_less(Menus.VERSION, min_version):
		var store := ApiClient.link(cfg, "playStore")
		dialog.open("Atualize o app", I18n.t("Saiu uma versão nova do Na Lata. Atualize na Play Store para continuar jogando."), [
			["Atualizar", func() -> void:
				OS.shell_open(store)
				check_gate(dialog), true],
		])
		return true
	if bool(cfg.get("maintenance", false)):
		dialog.open("Em manutenção", I18n.t(ApiClient.maintenance_text(cfg, GameState.language())), [
			["Tentar de novo", func() -> void: _retry_gate(dialog), true],
		])
		return true
	return false


static func _retry_gate(dialog: DialogBox) -> void:
	dialog.open("Conferindo…", "", [])
	await Server.load_config()
	if not check_gate(dialog):
		dialog.close()
		connect_and_onboard(dialog)  # o que a abertura do app não fez enquanto o aviso estava na tela


## Depois do aviso de manutenção/versão: lê o convite do link da Play, entra no servidor e segue para
## os passos da conta. O convite é lido junto com a entrada (só a pergunta da idade precisa dele).
static func connect_and_onboard(dialog: DialogBox) -> void:
	var referrer := {"done": false}
	var read_referrer := func() -> void:
		await Server.load_install_referrer()
		referrer.done = true
	read_referrer.call()
	if not Server.online() and await Server.ensure_session():
		Server.refresh_home()
	while not referrer.done:
		await Server.get_tree().process_frame
	Server.track("app_open", {"version": Menus.VERSION})
	if not dialog.visible:
		onboarding(dialog)


# ---------- primeira abertura ----------

## Passos que faltam na conta, um de cada vez: idade → (com Google) país → apelido.
static func onboarding(dialog: DialogBox) -> void:
	if Server.age_blocked > 0:
		show_age_blocked(dialog)
		return
	if not Server.online():
		return
	var p: Dictionary = Server.profile
	if p.get("age") == null:
		ask_age(dialog)
	elif Server.is_guest():
		return
	elif p.get("country") == null:
		ask_country(dialog, func() -> void: onboarding(dialog))
	elif not Server.get_flag("nick_asked"):
		ask_nickname(dialog, func() -> void: onboarding(dialog))


static func show_age_blocked(dialog: DialogBox) -> void:
	dialog.open("Não dá para jogar", I18n.t("O Na Lata é para quem tem %d anos ou mais. Sua conta foi apagada.") % Server.age_blocked, [
		["Entendi", func() -> void: show_age_blocked(dialog), true],
	])


static func ask_age(dialog: DialogBox, error: String = "") -> void:
	var text := I18n.t("Quantos anos você tem? Ninguém mais vê essa resposta.")
	if not error.is_empty():
		text = I18n.t(error) + "\n\n" + text
	dialog.open("Sua idade", text, [["Continuar", func() -> void: pass, true]])
	var age_field := dialog.add_input(I18n.t("Idade"), "", "number", 3) as LineEdit
	var code_field := dialog.add_input(I18n.t("Código de convite (se tiver)"), Server.invite_code, "text", 20) as LineEdit
	dialog.set_action(0, func() -> void: _send_age(dialog, age_field.text, code_field.text))


static func _send_age(dialog: DialogBox, age_text: String, code: String) -> void:
	var age := int(age_text.strip_edges()) if age_text.strip_edges().is_valid_int() else 0
	if age < 1 or age > 120:
		ask_age(dialog, "Digite uma idade válida.")
		return
	dialog.open("Conferindo…", "", [])
	var body := {"age": age}
	if not code.strip_edges().is_empty():
		body["inviteCode"] = code.strip_edges()
	var res: Dictionary = await Server.call_api("POST", "/me/age", body)
	if not res.ok:
		if res.code == "AGE_ALREADY_SET":
			await _reload_profile()
			onboarding(dialog)
		elif res.code == "NETWORK":
			dialog.close()  # pergunta de novo na próxima abertura
		else:
			ask_age(dialog, ApiClient.error_text(res))
		return
	if bool(res.data.get("blocked", false)):
		Server.block_by_age(int(res.data.get("minAge", 13)))
		show_age_blocked(dialog)
		return
	Server.set_profile(res.data.get("profile", Server.profile))
	dialog.close()
	onboarding(dialog)


static func _reload_profile() -> void:
	var me: Dictionary = await Server.call_api("GET", "/me")
	if me.ok and me.data is Dictionary:
		Server.set_profile(me.data)


# ---------- país ----------

## Escolha do país (uma vez só). `then` roda depois de escolher.
static func ask_country(dialog: DialogBox, then: Callable) -> void:
	dialog.open("Carregando…", "", [])
	var res: Dictionary = await Server.call_api("GET", "/countries")
	if not res.ok or not res.data is Array:
		dialog.open("Ops!", I18n.t(ApiClient.error_text(res)), [
			["Tentar de novo", func() -> void: ask_country(dialog, then), true],
			["Agora não", func() -> void: pass],
		])
		return
	var countries: Array = res.data
	var codes: Array = countries.map(func(c: Variant) -> String: return str((c as Dictionary).get("code", "")))
	var sim := _sim_country()
	var suggested := ApiClient.suggested_country(codes, sim, OS.get_locale())
	var lang := GameState.language()
	var buttons: Array = []
	var ordered := countries.duplicate()
	ordered.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if str(a.code) == suggested or str(b.code) == suggested:
			return str(a.code) == suggested
		return ApiClient.country_name(a, lang) < ApiClient.country_name(b, lang))
	for c in ordered:
		var code := str(c.code)
		var label := ApiClient.country_name(c, lang)
		buttons.append([label, func() -> void: _confirm_country(dialog, code, label, sim, suggested, then), code == suggested])
	buttons.append(["Meu país não está na lista", func() -> void:
		_confirm_country(dialog, ApiClient.NO_COUNTRY, I18n.t("Outro país"), sim, suggested, then)])
	dialog.open("Seu país", I18n.t("Os prêmios dependem do país. Não dá para trocar depois."), buttons)


static func _confirm_country(dialog: DialogBox, code: String, label: String, sim: String, suggested: String, then: Callable) -> void:
	var text := I18n.t("País: %s.\nNão dá para trocar depois.") % label
	if code == ApiClient.NO_COUNTRY:
		text = I18n.t("Você joga e aparece no ranking normalmente, mas não concorre a prêmios. Não dá para trocar depois.")
	dialog.open("Confirmar país", text, [
		["Confirmar", func() -> void: _send_country(dialog, code, sim, suggested, then), true],
		["Voltar", func() -> void: ask_country(dialog, then)],
	])


static func _send_country(dialog: DialogBox, code: String, sim: String, suggested: String, then: Callable) -> void:
	dialog.open("Conferindo…", "", [])
	var parts := OS.get_locale().replace("-", "_").split("_")
	var res: Dictionary = await Server.call_api("POST", "/me/country", {
		"code": code, "simCountry": sim if not sim.is_empty() else null,
		"localeCountry": parts[1].to_upper() if parts.size() > 1 else null,
		"suggested": suggested if not suggested.is_empty() else null,
	})
	if not res.ok:
		if res.code == "COUNTRY_ALREADY_SET":
			await _reload_profile()
			then.call()
			return
		dialog.open("Ops!", I18n.t(ApiClient.error_text(res)), [
			["Tentar de novo", func() -> void: ask_country(dialog, then), true],
			["Agora não", func() -> void: pass],
		])
		return
	if bool(res.data.get("blocked", false)):
		Server.block_by_age(int(res.data.get("minAge", 13)))
		show_age_blocked(dialog)
		return
	Server.set_profile(res.data)
	dialog.close()
	then.call()


static func _sim_country() -> String:
	var plugin := Server.native_with("install_referrer")
	if plugin:
		return str(plugin.simCountry()).to_upper()
	return ""


# ---------- apelido ----------

static func ask_nickname(dialog: DialogBox, then: Callable, error: String = "") -> void:
	Server.set_flag("nick_asked")
	var text := I18n.t("É o nome que aparece no ranking.")
	if not error.is_empty():
		text = I18n.t(error) + "\n\n" + text
	dialog.open("Seu apelido", text, [
		["Salvar", func() -> void: pass, true],
		["Agora não", func() -> void: then.call()],
	])
	var field := dialog.add_input(I18n.t("Apelido"), str(Server.profile.get("nickname", "")), "text", 20) as LineEdit
	dialog.set_action(0, func() -> void: _send_nickname(dialog, field.text, then))


static func _send_nickname(dialog: DialogBox, nick: String, then: Callable) -> void:
	dialog.open("Conferindo…", "", [])
	var res: Dictionary = await Server.call_api("POST", "/me/nickname", {"nickname": nick.strip_edges()})
	if not res.ok:
		ask_nickname(dialog, then, ApiClient.error_text(res))
		return
	Server.set_profile(res.data)
	if bool(res.data.get("suffixed", false)):
		dialog.open("Seu apelido", I18n.t("Esse apelido já tinha dono, então ficou %s.") % str(res.data.get("nickname", "")), [
			["Ok", func() -> void: then.call(), true],
		])
		return
	dialog.close()
	then.call()


# ---------- Sua conta ----------

static func open_account(dialog: DialogBox) -> void:
	var month := Rules.month_for(GameState.now_unix())
	var stats := I18n.t("Nível atual: %d\nPontos em %s: %d\nDesafios de hoje: %d de %d") % [
		GameState.current_level(), Rules.month_name(month), GameState.game_month_total("potion", month).points,
		Menus.daily_done(), Rules.DAILY_COUNT]
	var back := ["Voltar", func() -> void: Menus.open_settings(dialog)]
	if not Server.online():
		var note := "No app da Play Store você pode entrar com Google para guardar seu progresso e aparecer no ranking com todos os jogadores."
		if Server.enabled:
			note = "Sem conexão com o servidor. Confira a internet e tente de novo."
		dialog.open("Sua conta", stats + "\n\n" + I18n.t(note), [back])
		return
	var p: Dictionary = Server.profile
	var buttons: Array = []
	var who := ""
	if Server.is_guest():
		who = I18n.t("Você está jogando como visitante.")
		if Server.can_sign_in_google():
			who += " " + I18n.t("Entre com Google para guardar seu progresso em qualquer celular e poder receber prêmios. O que você já fez aqui vai junto.")
			buttons.append(["Entrar com Google", func() -> void: _sign_in_google(dialog), true])
	else:
		who = I18n.t("Apelido: %s") % str(p.get("nickname", ""))
		if p.get("country") != null:
			who += "\n" + I18n.t("País: %s") % _country_label(p)
		else:
			buttons.append(["Escolher país", func() -> void: ask_country(dialog, func() -> void: open_account(dialog)), true])
		if str(p.get("email", "")).contains("@"):
			who += "\n" + str(p.email)
		buttons.append(["Trocar apelido", func() -> void: ask_nickname(dialog, func() -> void: open_account(dialog))])
	buttons.append(["Apagar conta", func() -> void: confirm_delete(dialog)])
	buttons.append(back)
	dialog.open("Sua conta", who + "\n\n" + stats, buttons)


static func _country_label(p: Dictionary) -> String:
	if str(p.get("country", "")) == ApiClient.NO_COUNTRY:
		return I18n.t("Outro país (sem prêmios)")
	var names: Variant = p.get("countryNames")
	if names is Dictionary:
		return str((names as Dictionary).get(GameState.language(), (names as Dictionary).get("pt", p.country)))
	return str(p.get("country", ""))


static func _sign_in_google(dialog: DialogBox) -> void:
	dialog.open("Entrando…", "", [])
	var res: Dictionary = await Server.sign_in_google()
	if res.ok:
		dialog.close()
		onboarding(dialog)
		if not dialog.visible:
			open_account(dialog)
	elif res.code == "GOOGLE_CANCELLED":
		open_account(dialog)
	else:
		dialog.open("Sua conta", I18n.t(ApiClient.error_text(res)), [
			["Tentar de novo", func() -> void: _sign_in_google(dialog), true],
			["Voltar", func() -> void: open_account(dialog)],
		])


static func confirm_delete(dialog: DialogBox) -> void:
	dialog.open("Apagar conta?", I18n.t("Seus pontos, seu nível, seus convites e os prêmios ainda não pagos somem para sempre. Não dá para desfazer."), [
		["Apagar para sempre", func() -> void: _delete(dialog), false],
		["Cancelar", func() -> void: open_account(dialog), true],
	])


static func _delete(dialog: DialogBox) -> void:
	dialog.open("Apagando…", "", [])
	var res: Dictionary = await Server.delete_account()
	if not res.ok:
		dialog.open("Ops!", I18n.t(ApiClient.error_text(res)), [
			["Tentar de novo", func() -> void: _delete(dialog), true],
			["Voltar", func() -> void: open_account(dialog)],
		])
		return
	GameState.reset_progress()
	dialog.open("Conta apagada", I18n.t("Seus dados foram apagados. Se quiser, pode continuar jogando como um jogador novo."), [
		["Ok", func() -> void: _restart(dialog), true],
	])


static func _restart(dialog: DialogBox) -> void:
	if await Server.ensure_session():
		Server.refresh_home()
		onboarding(dialog)


# ---------- ajuda e termos ----------

static func open_help(dialog: DialogBox) -> void:
	dialog.open("Ajuda e termos", "", [
		["Fale conosco", func() -> void: open_support(dialog), true],
		["Política de privacidade", func() -> void: _open_link(dialog, "privacy")],
		["Termos de uso", func() -> void: _open_link(dialog, "terms")],
		["Regulamento dos prêmios", func() -> void: _open_link(dialog, "regulationFull")],
		["Voltar", func() -> void: Menus.open_settings(dialog)],
	])


static func _open_link(dialog: DialogBox, key: String) -> void:
	OS.shell_open(ApiClient.link(Server.config, key))
	open_help(dialog)


static func support_email() -> String:
	var e := str(Server.config.get("supportEmail", "")).strip_edges()
	return e if e.contains("@") else ApiClient.DEFAULT_SUPPORT_EMAIL


static func open_support(dialog: DialogBox) -> void:
	if not Server.online():
		var email := support_email()
		dialog.open("Fale conosco", I18n.t("Escreva para %s.") % email, [
			["Abrir e-mail", func() -> void:
				OS.shell_open("mailto:" + email)
				open_help(dialog), true],
			["Voltar", func() -> void: open_help(dialog)],
		])
		return
	var buttons: Array = []
	for topic in ApiClient.SUPPORT_TOPICS:
		var t: String = topic
		buttons.append([t, func() -> void: support_form(dialog, t)])
	buttons.append(["Voltar", func() -> void: open_help(dialog)])
	dialog.open("Fale conosco", I18n.t("Sobre o que você quer falar?"), buttons)


static func support_form(dialog: DialogBox, topic: String, error: String = "", message: String = "", email: String = "") -> void:
	var text := I18n.t("Conte o que aconteceu. Respondemos pelo e-mail.")
	if not error.is_empty():
		text = I18n.t(error) + "\n\n" + text
	dialog.open(I18n.t(topic), text, [
		["Enviar", func() -> void: pass, true],
		["Voltar", func() -> void: open_support(dialog)],
	])
	var msg_field := dialog.add_input(I18n.t("Sua mensagem"), message, "multiline") as TextEdit
	var email_field: LineEdit = null
	if Server.is_guest():
		email_field = dialog.add_input(I18n.t("Seu e-mail (para a resposta)"), email, "text", 120) as LineEdit
	dialog.set_action(0, func() -> void:
		_send_support(dialog, topic, msg_field.text, email_field.text if email_field else ""))


static func _send_support(dialog: DialogBox, topic: String, message: String, email: String) -> void:
	var msg := message.strip_edges()
	if msg.length() < 10:
		support_form(dialog, topic, "Escreva pelo menos 10 caracteres.", message, email)
		return
	if Server.is_guest():
		if not email.contains("@"):
			support_form(dialog, topic, "Coloque seu e-mail para podermos responder.", message, email)
			return
		msg += "\n\nE-mail para resposta: " + email.strip_edges()
	dialog.open("Enviando…", "", [])
	var res: Dictionary = await Server.call_api("POST", "/support", {
		"topic": topic, "message": msg.left(5000), "appVersion": Menus.VERSION,
		"device": ("%s · %s %s" % [OS.get_model_name(), OS.get_name(), OS.get_version()]).left(120),
	})
	if not res.ok:
		support_form(dialog, topic, ApiClient.error_text(res), message, email)
		return
	dialog.open("Mensagem enviada", I18n.t("Obrigado! Vamos responder pelo e-mail."), [
		["Ok", func() -> void: pass, true],
	])
