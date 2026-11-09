extends "res://tests/test_case.gd"
## Conta, prêmios, ajuda, manutenção, medição, sons e primeira partida guiada.
## Usa um servidor "de mentira" (Server.transport), como o test_server_flow.

var dialog: DialogBox
## Chamadas recebidas: [método, caminho, corpo].
var calls: Array = []
## Respostas por caminho (a 1ª da lista sai primeiro; a última fica valendo).
var replies: Dictionary = {}


func before_each() -> void:
	GameState.save_path = "user://test_progress_account.cfg"
	GameState.reset_all()
	GameState.fixed_unix = 1794063600  # 7/11/2026 meio-dia em Brasília
	Server.session_path = "user://test_session_account.cfg"
	Server.sign_out()
	Server.age_blocked = 0
	Server.invite_code = ""
	Server.events_now = true
	Server.enabled = true
	Server.config = {}
	Account.gate_open = false
	Server.transport = _fake
	calls = []
	replies = {}
	dialog = DialogBox.new()
	add_child(dialog)


func after_each() -> void:
	dialog.free()
	Server.enabled = false
	Server.transport = Callable()
	Server.native_override = null
	Server.config = {}
	Server.events_now = false
	Server.sign_out()
	Server.age_blocked = 0
	GameState.fixed_unix = -1
	Sfx.set_enabled(true)


func _ok(data: Variant) -> Dictionary:
	return {"ok": true, "status": 200, "data": data, "code": "", "message": ""}


func _err(status: int, code: String, extra: Dictionary = {}) -> Dictionary:
	var e := {"code": code, "message": "x"}
	e.merge(extra)
	return {"ok": false, "status": status, "data": {}, "code": code, "message": "x", "error": e}


func _fake(method: String, path: String, body: Variant) -> Dictionary:
	calls.append([method, path, body])
	if replies.has(path):
		var list: Array = replies[path]
		return list.pop_front() if list.size() > 1 else list[0]
	match path:
		"/auth/guest":
			return _ok({"token": "tok", "profile": {"id": "u1", "guest": true, "age": null, "country": null, "nickname": "Visitante"}})
		"/events", "/support":
			return _ok({"ok": true})
	return _err(404, "NOT_FOUND")


func _last(path: String) -> Array:
	for i in range(calls.size() - 1, -1, -1):
		if calls[i][1] == path:
			return calls[i]
	return []


func _google_profile(extra: Dictionary = {}) -> Dictionary:
	var p := {"id": "u1", "guest": false, "age": 30, "country": "BR", "nickname": "Ageu", "email": "a@b.com",
		"countryNames": {"pt": "Brasil", "en": "Brazil", "es": "Brasil"}}
	p.merge(extra, true)
	return p


func _login(profile: Dictionary) -> void:
	replies["/auth/guest"] = [_ok({"token": "tok", "profile": profile})]
	await Server.ensure_session()


# ---------- funções puras ----------

func test_version_compare() -> void:
	assert_true(ApiClient.version_less("1.3.0", "1.3.1"))
	assert_true(ApiClient.version_less("1.2.10", "1.3.0"))
	assert_true(ApiClient.version_less("1.3", "1.3.1"))
	assert_false(ApiClient.version_less("1.3.0", "1.3.0"))
	assert_false(ApiClient.version_less("1.10.0", "1.9.9"))
	assert_true(ApiClient.version_less("1.3.1-rc2", "1.3.2"), "o sufixo não vira dígito (1-rc2 não é 12)")
	assert_false(ApiClient.version_less(" 1.3.1 ", "1.3.1"))


func test_version_matches_export_presets() -> void:
	# a versão que o aviso de atualizar compara é a do Menus.VERSION: tem que ser a mesma que vai para a Play
	var presets := ConfigFile.new()
	assert_eq(presets.load("res://export_presets.cfg"), OK, "leu o export_presets.cfg")
	var checked := 0
	for section in presets.get_sections():
		if section.ends_with(".options") and presets.has_section_key(section, "version/name"):
			assert_eq(str(presets.get_value(section, "version/name")), Menus.VERSION, section)
			checked += 1
	assert_true(checked >= 2, "conferiu os presets Android e Android Play")


func test_integrity_nonce_matches_server_format() -> void:
	var n := ApiClient.integrity_nonce("gd-abc", 1800000000000)
	assert_false(n.contains("=") or n.contains("+") or n.contains("/"), "base64 web-safe sem '='")
	var std := n.replace("-", "+").replace("_", "/")
	while std.length() % 4 != 0:
		std += "="
	assert_eq(Marshalls.base64_to_utf8(std), "nalata:gd-abc:1800000000000")


func test_invite_code_from_play_referrer() -> void:
	assert_eq(ApiClient.invite_code_from_referrer("code=abc123"), "ABC123")
	assert_eq(ApiClient.invite_code_from_referrer("utm_source=x&code%3DXYZ9"), "XYZ9")
	assert_eq(ApiClient.invite_code_from_referrer("utm_source=google-play&utm_medium=organic"), "")


func test_maintenance_text_by_language() -> void:
	var cfg := {"maintenanceText": "Geral", "maintenanceMessage": {"pt": "Em pt", "en": "", "es": "En es"}}
	assert_eq(ApiClient.maintenance_text(cfg, "es"), "En es")
	assert_eq(ApiClient.maintenance_text(cfg, "en"), "Em pt", "sem inglês: cai no português")
	assert_eq(ApiClient.maintenance_text({"maintenanceText": "Geral"}, "en"), "Geral")


func test_rule_text() -> void:
	assert_eq(ApiClient.prize_chips(null), [])
	assert_eq(ApiClient.rule_text({"tag": "missing"}, {"friends": 3, "days": 3}),
		"Para receber prêmio, convide 3 amigos que joguem pelo menos 3 dias.")
	assert_eq(ApiClient.rule_text({"tag": "eligible"}, {}), "Você já cumpre a regra para receber prêmios.")
	assert_eq(ApiClient.rule_text({}, {}), "")


func test_suggested_country() -> void:
	assert_eq(ApiClient.suggested_country(["AR", "BR"], "", "pt_BR"), "BR")
	assert_eq(ApiClient.suggested_country(["AR", "BR"], "ar", "pt_BR"), "AR", "o chip vem antes do idioma")
	assert_eq(ApiClient.suggested_country(["AR"], "", "en_US"), "")


func test_brl_and_claim_body() -> void:
	assert_eq(Prizes.brl(10802), "R$ 108,02")
	assert_eq(Prizes.brl(123456789), "R$ 1.234.567,89")
	var pix := Prizes.claim_body({"method": "pix", "pixType": "cpf", "fullName": "Ana Lima", "cpf": "529.982.247-25",
		"quote": {"quoteId": "q1"}})
	assert_eq(pix, {"method": "pix", "fullName": "Ana Lima", "accepted": true, "cpf": "529.982.247-25",
		"pixType": "cpf", "pixKey": "529.982.247-25", "quoteId": "q1"})
	var usdt := Prizes.claim_body({"method": "usdt", "usdtNetwork": "TRC-20", "usdtAddress": "T1", "fullName": "Juan Pérez"})
	assert_eq(usdt, {"method": "usdt", "fullName": "Juan Pérez", "accepted": true, "usdtNetwork": "TRC-20", "usdtAddress": "T1"})


func test_invite_text() -> void:
	var t := Prizes.invite_text({"code": "ABC", "eligibility": {"required": 3, "days": 3, "valid": 1},
		"friends": [{"nickname": "Bia", "daysValid": 3, "valid": true}, {"nickname": "Caio", "daysValid": 1, "valid": false}]})
	assert_true(t.contains("convide 3 amigos"), t)
	assert_true(t.contains("Você tem 1 de 3."), t)
	assert_true(t.contains("✓ Bia: 3 de 3 dias"), t)
	assert_true(t.contains("• Caio: 1 de 3 dias"), t)
	assert_true(t.contains("Seu código: ABC"), t)
	assert_true(Prizes.invite_text({"eligibility": {"eligible": true}}).contains("Você já pode receber prêmios!"))


func test_hint_move_leads_to_solution() -> void:
	var tubes := [[0, 0, 0, 1], [1, 1, 1, 0], []]
	var move := SortPuzzle.hint_move(tubes)
	assert_eq(move.size(), 2)
	var state := SortPuzzle.copy_tubes(tubes)
	SortPuzzle.pour_in(state, move[0], move[1])
	assert_eq(SortPuzzle.min_moves(state), SortPuzzle.min_moves(tubes) - 1, "a dica está num caminho mais curto")
	assert_eq(SortPuzzle.hint_move([[0, 0, 0, 0], []]), [], "resolvido: sem dica")


# ---------- manutenção e versão mínima ----------

func test_old_version_blocks_with_update_button() -> void:
	Server.config = {"minAppVersion": "99.0.0"}
	assert_true(Account.check_gate(dialog))
	assert_eq(dialog.title_label.text, "Atualize o app")
	assert_eq(dialog.button_texts(), ["Atualizar"])


func test_saved_min_version_blocks_without_config() -> void:
	# abriu sem internet (o /config não chegou): a última versão mínima guardada continua valendo
	replies["/config"] = [_ok({"minAppVersion": "99.0.0"})]
	assert_true(await Server.load_config())
	Server.config = {}
	assert_true(Account.check_gate(dialog))
	assert_eq(dialog.title_label.text, "Atualize o app")
	replies["/config"] = [_ok({"minAppVersion": Menus.VERSION})]
	assert_true(await Server.load_config())
	Server.config = {}
	assert_false(Account.check_gate(dialog), "o painel baixou a versão mínima: libera")
	assert_eq(Server.saved_min_version(), Menus.VERSION)


func test_resume_clears_stale_gate_and_connects() -> void:
	# a abertura parou no aviso de manutenção; voltou para o app depois que o painel desligou a manutenção
	Server.config = {"minAppVersion": Menus.VERSION, "maintenance": true}
	assert_true(Account.check_gate(dialog))
	replies["/config"] = [_ok({"maintenance": false, "minAppVersion": Menus.VERSION})]
	await Account.recheck_gate(dialog)
	await wait_physics_frames(3)
	assert_true(Server.online(), "seguiu a entrada que a abertura deixou parada")
	assert_eq(dialog.title_label.text, "Sua idade")
	assert_false(Account.gate_open)


func test_maintenance_blocks_until_it_ends() -> void:
	Server.config = {"minAppVersion": Menus.VERSION, "maintenance": true, "maintenanceMessage": {"pt": "Volto às 15h"}}
	assert_true(Account.check_gate(dialog))
	assert_eq(dialog.title_label.text, "Em manutenção")
	assert_eq(dialog.text_label.text, "Volto às 15h")
	replies["/config"] = [_ok({"maintenance": false, "minAppVersion": Menus.VERSION})]
	await _login({"id": "u1", "guest": true, "age": 20})
	dialog.press("Tentar de novo")
	await wait_physics_frames(3)
	assert_false(dialog.visible, "acabou a manutenção: libera o jogo")
	assert_false(Account.check_gate(dialog))


func test_maintenance_end_connects_a_new_player() -> void:
	# primeira abertura durante a manutenção: ao liberar, entra no servidor e pergunta a idade
	Server.config = {"minAppVersion": Menus.VERSION, "maintenance": true}
	assert_true(Account.check_gate(dialog))
	replies["/config"] = [_ok({"maintenance": false, "minAppVersion": Menus.VERSION})]
	dialog.press("Tentar de novo")
	await wait_physics_frames(3)
	assert_true(Server.online(), "entrou como visitante")
	assert_eq(dialog.title_label.text, "Sua idade")


# ---------- idade, país, apelido ----------

func test_age_is_asked_once_with_invite_code() -> void:
	Server.invite_code = "AMIGO1"
	await Server.ensure_session()
	Account.onboarding(dialog)
	assert_eq(dialog.title_label.text, "Sua idade")
	var fields := dialog.inputs()
	assert_eq((fields[1] as LineEdit).text, "AMIGO1", "o código do link da Play já vem preenchido")
	(fields[0] as LineEdit).text = "abc"
	dialog.press("Continuar")
	assert_true(dialog.text_label.text.begins_with("Digite uma idade válida."))
	replies["/me/age"] = [_ok({"blocked": false, "profile": {"id": "u1", "guest": true, "age": 16}})]
	(dialog.inputs()[0] as LineEdit).text = "16"
	dialog.press("Continuar")
	await wait_physics_frames(2)
	assert_eq(_last("/me/age")[2], {"age": 16, "inviteCode": "AMIGO1"})
	assert_eq(int(Server.profile.age), 16)
	assert_false(dialog.visible, "visitante: depois da idade, joga")


func test_too_young_blocks_the_device() -> void:
	await Server.ensure_session()
	Account.ask_age(dialog)
	replies["/me/age"] = [_ok({"blocked": true, "minAge": 13})]
	(dialog.inputs()[0] as LineEdit).text = "9"
	dialog.press("Continuar")
	await wait_physics_frames(2)
	assert_eq(dialog.title_label.text, "Não dá para jogar")
	assert_eq(Server.age_blocked, 13)
	assert_false(Server.online())
	dialog.press("Entendi")
	assert_true(dialog.visible, "não dá para fechar")
	assert_false(await Server.ensure_session(), "não cria outra conta neste aparelho")


func test_google_account_picks_country_then_nickname() -> void:
	await _login(_google_profile({"country": null}))
	replies["/countries"] = [_ok([
		{"code": "AR", "names": {"pt": "Argentina", "en": "Argentina", "es": "Argentina"}},
		{"code": "BR", "names": {"pt": "Brasil", "en": "Brazil", "es": "Brasil"}}])]
	replies["/me/country"] = [_ok(_google_profile())]
	Account.onboarding(dialog)
	await wait_physics_frames(2)
	assert_eq(dialog.title_label.text, "Seu país")
	assert_true("Meu país não está na lista" in dialog.button_texts())
	dialog.press("Brasil")
	assert_eq(dialog.title_label.text, "Confirmar país")
	dialog.press("Confirmar")
	await wait_physics_frames(2)
	assert_eq(_last("/me/country")[2].code, "BR")
	assert_eq(dialog.title_label.text, "Seu apelido", "depois do país, o apelido")
	replies["/me/nickname"] = [_ok(_google_profile({"nickname": "Ageu#123", "suffixed": true}))]
	(dialog.inputs()[0] as LineEdit).text = "Ageu"
	dialog.press("Salvar")
	await wait_physics_frames(2)
	assert_eq(_last("/me/nickname")[2], {"nickname": "Ageu"})
	assert_true(dialog.text_label.text.contains("Ageu#123"), "avisa o sufixo")
	dialog.press("Ok")
	assert_false(dialog.visible, "pronto: nada mais a perguntar")


func test_no_country_option_explains_no_prizes() -> void:
	await _login(_google_profile({"country": null}))
	replies["/countries"] = [_ok([{"code": "BR", "names": {"pt": "Brasil"}}])]
	Account.ask_country(dialog, func() -> void: pass)
	await wait_physics_frames(2)
	dialog.press("Meu país não está na lista")
	assert_true(dialog.text_label.text.contains("não concorre a prêmios"))
	replies["/me/country"] = [_ok(_google_profile({"country": "XX"}))]
	dialog.press("Confirmar")
	await wait_physics_frames(2)
	assert_eq(_last("/me/country")[2].code, "XX")


# ---------- Sua conta ----------

func test_delete_account_from_the_app() -> void:
	await _login(_google_profile())
	GameState.complete_level(1, 10, 5)
	GameState.set_language("es")
	Account.open_account(dialog)
	assert_true("Apagar conta" in dialog.button_texts())
	dialog.press("Apagar conta")
	assert_eq(dialog.title_label.text, "Apagar conta?")
	replies["/me"] = [_ok({"ok": true})]
	dialog.press("Apagar para sempre")
	await wait_physics_frames(2)
	assert_eq(_last("/me")[0], "DELETE")
	assert_eq(dialog.title_label.text, "Conta apagada")
	assert_eq(Server.token, "", "esqueceu a sessão")
	assert_eq(GameState.current_level(), 1, "progresso do aparelho apagado")
	assert_eq(GameState.language(), "es", "o idioma fica")
	GameState.set_language("pt")


func test_account_shows_nickname_and_country() -> void:
	await _login(_google_profile())
	Account.open_account(dialog)
	assert_true(dialog.text_label.text.contains("Apelido: Ageu"), dialog.text_label.text)
	assert_true(dialog.text_label.text.contains("País: Brasil"), dialog.text_label.text)
	assert_eq(dialog.button_texts(), ["Meus prêmios", "Trocar apelido", "Apagar conta", "Voltar"])


# ---------- ajuda ----------

func test_help_has_legal_links_and_support() -> void:
	Account.open_help(dialog)
	assert_eq(dialog.button_texts(), ["Fale conosco", "Política de privacidade", "Termos de uso", "Regulamento dos prêmios", "Voltar"])
	assert_eq(ApiClient.link({}, "privacy"), "https://nalatagame.tech/privacidade")
	assert_eq(ApiClient.link({"links": {"terms": "https://x.dev/t"}}, "terms"), "https://x.dev/t", "o painel pode trocar")


func test_guest_support_needs_email() -> void:
	await _login({"id": "u1", "guest": true, "age": 20})
	Account.open_support(dialog)
	dialog.press("Problema técnico")
	assert_eq(dialog.inputs().size(), 2, "mensagem e e-mail")
	(dialog.inputs()[0] as TextEdit).text = "O jogo travou no nível 3."
	dialog.press("Enviar")
	assert_true(dialog.text_label.text.begins_with("Coloque seu e-mail"))
	(dialog.inputs()[1] as LineEdit).text = "eu@mail.com"
	dialog.press("Enviar")
	await wait_physics_frames(2)
	var sent: Dictionary = _last("/support")[2]
	assert_eq(sent.topic, "Problema técnico")
	assert_true(str(sent.message).contains("eu@mail.com"))
	assert_eq(sent.appVersion, Menus.VERSION)
	assert_eq(dialog.title_label.text, "Mensagem enviada")


# ---------- prêmios ----------

func test_claim_pix_with_quote() -> void:
	await _login(_google_profile())
	replies["/payouts/p1"] = [_ok({"id": "p1", "status": "pending", "amountLabel": "US$ 20", "country": "BR",
		"methods": ["pix", "usdt"], "usdtNetworks": ["TRC-20"], "minor": false})]
	replies["/payouts/p1/quote"] = [_ok({"quoteId": "q1", "brlCents": 10802})]
	replies["/payouts/p1/claim"] = [_err(409, "QUOTE_EXPIRED", {"quote": {"quoteId": "q2", "brlCents": 11000}}), _ok({"ok": true})]
	Prizes.open_claim(dialog, "p1")
	await wait_physics_frames(2)
	assert_eq(dialog.title_label.text, "Como quer receber?")
	dialog.press("Pix (em reais)")
	dialog.press("E-mail")
	await wait_physics_frames(2)
	assert_true(dialog.text_label.text.contains("R$ 108,02"), dialog.text_label.text)
	var f := dialog.inputs()
	assert_eq(f.size(), 3, "nome, CPF e a chave")
	(f[0] as LineEdit).text = "Ana Lima"
	(f[1] as LineEdit).text = "52998224725"
	(f[2] as LineEdit).text = "ana@mail.com"
	dialog.press("Enviar")
	await wait_physics_frames(2)
	assert_true(dialog.text_label.text.contains("R$ 110,00"), "valor novo depois da cotação vencida")
	assert_eq((dialog.inputs()[0] as LineEdit).text, "Ana Lima", "volta preenchido")
	dialog.press("Enviar")
	await wait_physics_frames(2)
	var body: Dictionary = _last("/payouts/p1/claim")[2]
	assert_eq(body.quoteId, "q2")
	assert_eq(body.pixKey, "ana@mail.com")
	assert_eq(dialog.title_label.text, "Prêmio pedido!")


func test_pending_payout_announcement() -> void:
	Server.home = {"payouts": [{"id": "p1", "status": "pending", "amountLabel": "US$ 20", "monthLabel": "outubro de 2026",
		"deadlineAt": "2026-11-20T02:59:59.000Z"}, {"id": "p2", "status": "submitted"}]}
	assert_eq(Prizes.pending_payouts().size(), 1)
	Prizes.announce(dialog, Prizes.pending_payouts()[0])
	assert_eq(dialog.title_label.text, "Você ganhou!")
	assert_true(dialog.text_label.text.contains("US$ 20"))
	assert_true(dialog.text_label.text.contains("19 de novembro"), "prazo no horário de Brasília")
	Server.home = {}


# ---------- medição, Play Integrity e sons ----------

func test_events_are_sent_only_online() -> void:
	Server.track("app_open")
	assert_true(_last("/events").is_empty(), "sem sessão não manda")
	await _login({"id": "u1", "guest": true, "age": 20})
	await Server.track("tutorial_done", {"x": 1})
	assert_eq(_last("/events")[2], {"events": [{"name": "tutorial_done", "props": {"x": 1}}]})


class IntegrityPlugin extends RefCounted:
	signal integrity_token(token: String, error: String)
	var nonce: String = ""

	func integrityToken(n: String, _project: int) -> void:
		nonce = n
		integrity_token.emit.call_deferred("int-tok", "")


func test_login_sends_play_integrity_token() -> void:
	var plugin := IntegrityPlugin.new()
	Server.native_override = plugin
	await Server.ensure_session()
	assert_eq(_last("/auth/guest")[2].integrityToken, "int-tok")
	assert_true(plugin.nonce.length() > 16)


func test_sound_toggle() -> void:
	Sfx.played.clear()
	Sfx.play("pour")
	assert_eq(Sfx.played, ["pour"])
	Sfx.set_enabled(false)
	Sfx.play("pour")
	assert_eq(Sfx.played, ["pour"], "desligado: não toca")
	Menus.open_settings(dialog)
	assert_true("Som: desligado" in dialog.button_texts())


# ---------- primeira partida guiada ----------

func test_first_level_is_guided() -> void:
	Server.enabled = false
	var game: Control = load("res://scenes/game/game_screen.tscn").instantiate()
	game.animate = false
	add_child(game)
	game.open_level(1)
	assert_eq(game.dialog.title_label.text, "Primeira partida")
	game.dialog.press("Começar")
	var hinted: Array = []
	for b in game._bottles:
		if b.hint:
			hinted.append(b.index)
	assert_eq(hinted.size(), 1, "uma setinha")
	# segue as setinhas até o fim
	for _step in 40:
		if game._finished:
			break
		var move := SortPuzzle.hint_move(game.puzzle.tubes, game.puzzle.covers)
		game.tap_bottle(move[0])
		assert_true(game._bottles[move[1]].hint, "depois de escolher, a setinha vai para onde despejar")
		game.tap_bottle(move[1])
	assert_true(game._finished)
	assert_true(bool(GameState.get_setting("tutorial_done", false)))
	game.open_level(1)
	assert_ne(game.dialog.title_label.text, "Primeira partida", "não aparece de novo")
	game.free()
