extends "res://tests/test_case.gd"
## Jogo pelo servidor, com um servidor "de mentira" no lugar da rede (Server.transport):
## entrar como visitante, abrir fases, ajudas com propaganda conferida, fim com os pontos do servidor.

const TUBES := [[0, 0, 0, 1], [1, 1, 1, 0], []]
const SOLUTION := [[0, 2], [1, 0], [2, 1]]
const TODAY := "2026-11-07"

var main: Control
var game: Control
## Chamadas recebidas: [método, caminho, corpo].
var calls: Array = []
## Respostas forçadas para o próximo pedido a um caminho: caminho → lista de respostas (a 1ª sai primeiro).
var forced: Dictionary = {}
var server_points: int = 99
var level_number: int = 4


func before_each() -> void:
	GameState.save_path = "user://test_progress_server.cfg"
	GameState.reset_all()
	GameState.set_setting("tutorial_done", true)  # a partida guiada tem testes próprios
	GameState.fixed_unix = 1794063600  # 7/11/2026 meio-dia em Brasília
	Ads.instant = true
	calls = []
	forced = {}
	Server.session_path = "user://test_session.cfg"
	Server.sign_out()
	Server.age_blocked = 0
	Server.invite_code = ""
	Server.events_now = true
	Server.enabled = true
	Server.retry_wait_s = 0.0
	Server.transport = _fake
	main = load("res://scenes/main/main.tscn").instantiate()
	add_child(main)
	game = main.get_node("Game")
	game.animate = false
	await wait_physics_frames(2)


func after_each() -> void:
	main.free()
	Server.enabled = false
	Server.transport = Callable()
	Server.native_override = null
	Server.config = {}
	Server.sign_out()
	Server.retry_wait_s = Server.REWARD_RETRY_WAIT_S
	GameState.fixed_unix = -1
	Ads.instant = false


func _ok(data: Dictionary) -> Dictionary:
	return {"ok": true, "status": 200, "data": data, "code": "", "message": ""}


func _match(body: Dictionary) -> Dictionary:
	var level: bool = body.get("mode", "") == "level"
	return {
		"id": "m-1", "mode": body.get("mode"), "key": ("nivel#%d" % level_number) if level else "%s#%d" % [TODAY, body.get("index", 0)],
		"date": null if level else TODAY, "index": null if level else body.get("index"), "level": level_number if level else null,
		"difficulty": "easy", "tubes": TUBES, "covers": [-1.0, -1.0, -1.0], "hidden": false, "par": 3.0, "fullPoints": 6.0,
		"params": {"shuffles": 3.0, "flasks": 1.0, "boostCost": 2.0, "extraMoves": 7.0}, "attempt": null,
		"boosts": [], "moves": [],
		"state": {"tubes": TUBES, "movesUsed": 0, "moveLimit": 3.0, "points": 6, "shufflesLeft": 3, "flasksLeft": 1, "solved": false},
	}


func _fake(method: String, path: String, body: Variant) -> Dictionary:
	calls.append([method, path, body])
	if forced.has(path) and not (forced[path] as Array).is_empty():
		return (forced[path] as Array).pop_front()
	match path:
		"/auth/guest":
			return _ok({"token": "tok", "profile": {"id": "u1", "age": 30}})
		"/pocao/home":
			return _ok({"date": TODAY, "level": {"number": level_number}, "daily": [
				{"index": 0, "attempts": 1, "solved": true, "bestPoints": 5, "bestMoves": 4},
				{"index": 1, "attempts": 0, "solved": false, "bestPoints": null, "bestMoves": null},
			], "month": {"id": "2026-11", "gamePoints": 40, "gamePosition": 7, "globalPoints": 120, "globalPosition": 12}})
		"/pocao/matches":
			return _ok({"match": _match(body)})
		"/rewards":
			return _ok({"rewardId": "r-%d" % calls.size(), "ssvCustomData": "r-%d" % calls.size()})
		"/pocao/matches/m-1/boost":
			var m := _match({"mode": "level"})
			m.state = {"tubes": [[0, 0, 1, 0], [1, 1, 0, 1], []], "movesUsed": 0, "moveLimit": 10, "points": 4,
				"shufflesLeft": 2, "flasksLeft": 0, "solved": false}
			return _ok({"match": m})
		"/pocao/matches/m-1/finish":
			return _ok({"matchId": "m-1", "solved": true, "rejected": false, "movesUsed": 3, "par": 3, "fullPoints": 6,
				"points": server_points, "credited": server_points, "best": null, "newBest": true, "nextLevel": level_number + 1,
				"gamePoints": 140, "gamePosition": 2})
		"/config":
			return _ok({"ads": {"unitIds": {"rewarded": "unit-rw"}}})
		"/auth/google":
			return _ok({"token": "tok-g", "profile": {"id": "u1", "guest": false, "nickname": "Ageu", "age": 30, "country": "BR"}, "merged": null})
		"/ranking":
			return _ok({"podium": [{"position": 1, "nickname": "Ana", "points": 900}], "rows": [
				{"position": 12, "nickname": "Eu", "points": 120, "isMe": true}]})
	return {"ok": false, "status": 404, "data": {}, "code": "NOT_FOUND", "message": ""}


## Plugin Android de mentira: responde na hora seguinte, como o de verdade (por sinal).
class FakePlugin extends RefCounted:
	signal rewarded_finished(earned: bool, error: String)
	signal google_signed_in(id_token: String, error: String)
	signal ads_initialized(ok: bool)
	var shown: Array = []
	var earn: bool = true
	var id_token: String = "id-tok"

	func adsInit() -> void:
		pass

	func showRewarded(unit_id: String, user_id: String, custom_data: String) -> void:
		shown.append([unit_id, user_id, custom_data])
		rewarded_finished.emit.call_deferred(earn, "" if earn else "closed")

	func googleSignIn(_client_id: String) -> void:
		google_signed_in.emit.call_deferred(id_token, "" if not id_token.is_empty() else "cancelled")

	func googleSignOut() -> void:
		pass


func _paths() -> Array:
	return calls.map(func(c: Array) -> String: return c[1])


func _last(path: String) -> Array:
	for i in range(calls.size() - 1, -1, -1):
		if calls[i][1] == path:
			return calls[i]
	return []


func _solve() -> void:
	for pair in SOLUTION:
		game.tap_bottle(pair[0])
		game.tap_bottle(pair[1])


# ---------- funções puras ----------

func test_parse_response() -> void:
	var ok := ApiClient.parse_response(HTTPRequest.RESULT_SUCCESS, 200, '{"a": 1}'.to_utf8_buffer())
	assert_true(ok.ok)
	assert_eq(int(ok.data.a), 1)
	var err := ApiClient.parse_response(HTTPRequest.RESULT_SUCCESS, 409, '{"error": {"code": "NO_BOOSTS", "message": "x"}}'.to_utf8_buffer())
	assert_false(err.ok)
	assert_eq(err.code, "NO_BOOSTS")
	assert_eq(ApiClient.error_text(err), "Acabaram as ajudas desta fase.")
	var net := ApiClient.parse_response(HTTPRequest.RESULT_CANT_CONNECT, 0, PackedByteArray())
	assert_eq(net.code, "NETWORK")


func test_challenge_from_match_uses_ints() -> void:
	var c := ApiClient.challenge_from_match(_match({"mode": "daily", "index": 2.0}))
	assert_eq(c.match_id, "m-1")
	assert_eq(c.index, 2)
	assert_eq(typeof(c.tubes[0][0]), TYPE_INT, "cores como número inteiro")
	assert_eq(c.params.boost_cost, 2)
	assert_eq(c.params.extra_moves, 7)


func test_ranking_rows_join_podium_and_rows() -> void:
	var rows := ApiClient.ranking_rows({"podium": [{"position": 1, "nickname": "Ana", "points": 9}, null],
		"rows": [{"position": 5, "nickname": "", "guest": true, "points": 2, "isMe": true}]})
	assert_eq(rows, [[1, "Ana", 9, false], [5, "Visitante", 2, true]])


# ---------- partidas pelo servidor ----------

func test_logs_in_as_guest_and_syncs_home() -> void:
	assert_true(Server.online(), "entrou como visitante")
	assert_eq(_paths().filter(func(p: String) -> bool: return p != "/config").slice(0, 2), ["/auth/guest", "/pocao/home"])
	assert_ne(str(_last("/auth/guest")[2].deviceHash), "", "manda o identificador do aparelho")
	assert_eq(GameState.current_level(), 4, "nível vem do servidor")
	assert_eq(GameState.attempts("2026-11-07#0"), 1)
	assert_eq(int(GameState.result("2026-11-07#0").best_points), 5)
	assert_eq(int(GameState.game_month_total("potion", "2026-11").points), 40, "pontos do mês do servidor")
	assert_eq(int(GameState.global_month_total("2026-11").points), 120)


func test_level_is_scored_by_the_server() -> void:
	main.play_level()
	await wait_physics_frames(1)
	assert_true(game.is_online(), "partida aberta pelo servidor")
	assert_eq(_last("/pocao/matches")[2], {"mode": "level"})
	assert_eq(game.challenge.level, 4)
	_solve()
	await wait_physics_frames(1)
	var fin: Array = _last("/pocao/matches/m-1/finish")
	assert_eq(fin[2].moves, SOLUTION, "manda todas as jogadas")
	assert_eq(fin[2].claimed, {"moves": 3, "points": 6, "solved": true})
	assert_true(game.dialog.visible)
	assert_true(game.dialog.text_label.text.begins_with("+99 pontos"), "mostra os pontos do servidor")
	assert_eq(GameState.current_level(), 5, "libera o próximo nível")
	assert_eq(int(GameState.game_month_total("potion", "2026-11").points), 140)


func test_flask_needs_server_reward() -> void:
	main.play_level()
	await wait_physics_frames(1)
	game.tap_bottle(0)
	game.tap_bottle(2)
	game._boost_online("flask")
	await wait_physics_frames(1)
	var reward: Array = _last("/rewards")
	assert_eq(reward[2], {"kind": "pflask", "matchId": "m-1"})
	var boost: Array = _last("/pocao/matches/m-1/boost")
	assert_eq(boost[2].kind, "flask")
	assert_eq(boost[2].moves, [[0, 2]], "manda as jogadas feitas até a ajuda")
	assert_eq(game.puzzle.tubes.size(), 4, "ganhou o frasco")
	assert_eq(game.bottles_left, 0)
	assert_eq(game.current_points(), 4, "custo da ajuda vem das regras da partida (2)")


func test_shuffle_uses_server_tubes() -> void:
	main.play_level()
	await wait_physics_frames(1)
	game._boost_online("shuffle")
	await wait_physics_frames(1)
	assert_eq(game.puzzle.tubes, [[0, 0, 1, 0], [1, 1, 0, 1], []], "embaralhado sorteado pelo servidor")
	assert_eq(game.shuffles_left, 2)


func test_reward_waits_for_admob_confirmation() -> void:
	main.play_level()
	await wait_physics_frames(1)
	var not_yet := {"ok": false, "status": 403, "data": {}, "code": "REWARD_NOT_VERIFIED", "message": ""}
	forced["/pocao/matches/m-1/boost"] = [not_yet, not_yet]
	game._boost_online("moves")
	await wait_physics_frames(1)
	var tries := _paths().filter(func(p: String) -> bool: return p == "/pocao/matches/m-1/boost")
	assert_eq(tries.size(), 3, "tentou de novo até confirmar")
	assert_eq(game.move_limit, 10)


func test_daily_retry_sends_reward() -> void:
	main.request_play(TODAY, 0)  # já tentou uma vez (veio do servidor)
	assert_true(main.dialog.visible, "pede propaganda")
	main.dialog.press("Assistir e jogar")
	await wait_physics_frames(1)
	assert_eq(_last("/rewards")[2], {"kind": "pretry", "mode": "2026-11-07#0"})
	var start: Array = _last("/pocao/matches")
	assert_eq(start[2].mode, "daily")
	assert_eq(start[2].index, 0)
	assert_true(str(start[2].get("rewardId", "")).begins_with("r-"), "manda a propaganda assistida")
	assert_true(game.visible and game.is_online())


func test_first_daily_attempt_is_free_online() -> void:
	main.request_play(TODAY, 1)
	await wait_physics_frames(1)
	assert_eq(_last("/pocao/matches")[2], {"mode": "daily", "index": 1})
	assert_false("/rewards" in _paths(), "sem propaganda")


func test_no_connection_goes_back() -> void:
	forced["/pocao/matches"] = [ApiClient.error_result(0, "NETWORK", "")]
	main.play_level()
	await wait_physics_frames(1)
	assert_false(game.is_online())
	assert_true(game.dialog.visible)
	assert_eq(game.dialog.button_texts(), ["Tentar de novo", "Menu"])
	game.dialog.press("Tentar de novo")
	await wait_physics_frames(1)
	assert_true(game.is_online(), "abriu na 2ª tentativa")


func test_finish_without_connection_can_retry() -> void:
	main.play_level()
	await wait_physics_frames(1)
	forced["/pocao/matches/m-1/finish"] = [ApiClient.error_result(0, "NETWORK", "")]
	_solve()
	await wait_physics_frames(1)
	assert_eq(game.dialog.button_texts(), ["Tentar de novo", "Menu"])
	game.dialog.press("Tentar de novo")
	await wait_physics_frames(1)
	assert_true(game.dialog.text_label.text.begins_with("+99 pontos"))


func test_global_ranking_lists_players() -> void:
	main.open_global_ranking()
	await wait_physics_frames(1)
	var ranking: Control = main.get_node("Ranking")
	assert_true(ranking.top_card.visible, "mostra a lista")
	assert_eq(ranking.top_list.get_child_count(), 2)
	assert_eq(ranking.points_label.text, "120 pts")
	assert_eq(ranking.detail_label.text, "12º lugar")


func test_real_ad_sends_reward_id_for_ssv() -> void:
	var plugin := FakePlugin.new()
	Server.native_override = plugin
	Ads.instant = false
	await Server.load_config()
	main.play_level()
	await wait_physics_frames(1)
	game._boost_online("flask")
	await wait_physics_frames(10)
	assert_eq(plugin.shown.size(), 1, "mostrou a propaganda do AdMob")
	assert_eq(plugin.shown[0][0], "unit-rw", "bloco vem do painel")
	assert_eq(plugin.shown[0][1], "u1", "id do jogador vai na confirmação")
	assert_true(str(plugin.shown[0][2]).begins_with("r-"), "rewardId vai como customData")
	assert_eq(game.puzzle.tubes.size(), 4)


func test_closed_ad_gives_nothing() -> void:
	var plugin := FakePlugin.new()
	plugin.earn = false
	Server.native_override = plugin
	Ads.instant = false
	await Server.load_config()
	main.play_level()
	await wait_physics_frames(1)
	game._boost_online("flask")
	await wait_physics_frames(10)
	assert_false("/pocao/matches/m-1/boost" in _paths(), "sem recompensa, não pede a ajuda")
	assert_eq(game.puzzle.tubes.size(), 3)
	assert_true(game.dialog.visible, "avisa")


func test_google_sign_in_keeps_device() -> void:
	var plugin := FakePlugin.new()
	Server.native_override = plugin
	assert_true(Server.is_guest())
	var res: Dictionary = await Server.sign_in_google()
	assert_true(res.ok)
	var call: Array = _last("/auth/google")
	assert_eq(call[2].idToken, "id-tok")
	assert_eq(call[2].deviceHash, Server.device_hash, "mesmo aparelho: o progresso do visitante passa para a conta")
	assert_false(Server.is_guest())
	assert_eq(Server.token, "tok-g")


func test_google_cancelled() -> void:
	var plugin := FakePlugin.new()
	plugin.id_token = ""
	Server.native_override = plugin
	var res: Dictionary = await Server.sign_in_google()
	assert_eq(res.code, "GOOGLE_CANCELLED")
	assert_true(Server.is_guest())
	assert_false("/auth/google" in _paths())


func test_account_menu_signs_in() -> void:
	var plugin := FakePlugin.new()
	Server.native_override = plugin
	await Server.ensure_session()
	Server.set_flag("nick_asked")
	Account.open_account(main.dialog)
	assert_eq(main.dialog.button_texts(), ["Entrar com Google", "Apagar conta", "Voltar"])
	main.dialog.press("Entrar com Google")
	await wait_physics_frames(10)
	assert_false(Server.is_guest())
	assert_true(main.dialog.text_label.text.contains("Ageu"), "mostra a conta")


func test_account_without_plugin_has_no_google_button() -> void:
	await Server.ensure_session()
	Account.open_account(main.dialog)
	assert_eq(main.dialog.button_texts(), ["Apagar conta", "Voltar"])


func test_real_ad_reloads_missing_config() -> void:
	var plugin := FakePlugin.new()
	Server.native_override = plugin
	Ads.instant = false
	Server.config = {}  # o GET /config da abertura não chegou
	main.play_level()
	await wait_physics_frames(1)
	game._boost_online("flask")
	await wait_physics_frames(10)
	assert_eq(plugin.shown.size(), 1, "pediu o /config de novo e mostrou o AdMob, não a simulação")
	assert_eq(game.puzzle.tubes.size(), 4)


func test_guest_login_does_not_replace_google_session() -> void:
	Server.sign_out()
	# o Google termina de entrar enquanto a resposta do visitante ainda está a caminho
	Server.transport = func(method: String, path: String, body: Variant) -> Dictionary:
		if path == "/auth/guest":
			Server.token = "tok-g"
			Server.profile = {"id": "u1", "guest": false}
			return _ok({"token": "tok-guest", "profile": {"id": "g1", "guest": true}})
		return _fake(method, path, body)
	assert_true(await Server.ensure_session())
	assert_eq(Server.token, "tok-g", "o visitante que chegou depois não troca a conta Google")
	assert_false(Server.is_guest())


func test_expired_google_session_signs_in_with_google_again() -> void:
	var plugin := FakePlugin.new()
	Server.native_override = plugin
	await Server.sign_in_google()
	forced["/pocao/home"] = [{"ok": false, "status": 401, "data": {}, "code": "UNAUTHORIZED", "message": ""}]
	var before := _paths().filter(func(p: String) -> bool: return p == "/auth/guest").size()
	await Server.refresh_home()
	assert_eq(_paths().filter(func(p: String) -> bool: return p == "/auth/guest").size(), before, "não vira visitante")
	assert_eq(_paths().filter(func(p: String) -> bool: return p == "/auth/google").size(), 2, "entrou com Google de novo")
	assert_false(Server.is_guest())


func test_wait_signal_gives_up() -> void:
	var plugin := FakePlugin.new()
	var out: Array = await Server.wait_signal(Signal(plugin, "rewarded_finished"), 0.05, [false, "timeout"])
	assert_eq(out, [false, "timeout"])


func test_real_ad_without_unit_does_not_simulate() -> void:
	var plugin := FakePlugin.new()
	Server.native_override = plugin
	Ads.instant = false
	Server.config = {}
	forced["/config"] = [ApiClient.error_result(0, "NETWORK", "")]  # o /config continua sem chegar
	main.play_level()
	await wait_physics_frames(1)
	game._boost_online("flask")
	await wait_physics_frames(10)
	assert_eq(plugin.shown.size(), 0, "sem bloco do AdMob, não mostra nada")
	assert_false(Ads.showing, "não ficou presa na simulação")
	assert_false("/pocao/matches/m-1/boost" in _paths(), "sem propaganda, não pede a ajuda")
	assert_eq(game.puzzle.tubes.size(), 3)


func test_local_ad_without_unit_still_simulates() -> void:
	# sem internet no Android: as ajudas do jogo no aparelho (sem servidor) continuam com a simulação
	var plugin := FakePlugin.new()
	Server.native_override = plugin
	Ads.instant = false
	Ads.duration = 0.0
	Server.config = {}
	forced["/config"] = [ApiClient.error_result(0, "NETWORK", "")]
	var ok: bool = await Ads.play()
	Ads.duration = 3.0
	assert_true(ok, "jogo local: a simulação entrega a recompensa")
	assert_eq(plugin.shown.size(), 0, "não chama o AdMob sem bloco")
	assert_false(Ads.showing)


func test_prize_is_announced_once_and_claim_button_shows() -> void:
	Server.home = {"payouts": [{"id": "p9", "status": "pending", "amountLabel": "US$ 5", "monthLabel": "outubro de 2026",
		"deadlineAt": "2026-11-20T02:59:59.000Z"}]}
	main._on_server_home()
	assert_eq(main.dialog.title_label.text, "Você ganhou!")
	main.dialog.press("Depois")
	main._on_server_home()
	assert_false(main.dialog.visible, "avisa uma vez só")
	main.open_global_ranking()
	var ranking: Control = main.get_node("Ranking")
	Server.home = {"payouts": [{"id": "p9", "status": "pending"}]}
	ranking.refresh()
	assert_true(ranking.claim_button.visible, "botão de resgatar no Ranking Global")
	assert_true(ranking.invite_button.visible, "convite no Ranking Global")


func test_leaving_a_level_midway_is_measured() -> void:
	main.play_level()
	await wait_physics_frames(1)
	game.tap_bottle(SOLUTION[0][0])
	game.tap_bottle(SOLUTION[0][1])
	main._leave_game()
	await wait_physics_frames(2)
	var names: Array = []
	for c in calls:
		if c[1] == "/events":
			for e in c[2].events:
				names.append(e.name)
	assert_true("match_quit" in names, str(names))
