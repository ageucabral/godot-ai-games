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
	GameState.fixed_unix = 1794063600  # 7/11/2026 meio-dia em Brasília
	Ads.instant = true
	calls = []
	forced = {}
	Server.session_path = "user://test_session.cfg"
	Server.sign_out()
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
			return _ok({"token": "tok", "profile": {"id": "u1"}})
		"/pocao/home":
			return _ok({"date": TODAY, "level": {"number": level_number}, "daily": [
				{"index": 0, "attempts": 1, "solved": true, "bestPoints": 5, "bestMoves": 4},
				{"index": 1, "attempts": 0, "solved": false, "bestPoints": null, "bestMoves": null},
			], "month": {"id": "2026-11", "gamePoints": 40, "gamePosition": 7, "globalPoints": 120, "globalPosition": 12}})
		"/pocao/matches":
			return _ok({"match": _match(body)})
		"/rewards":
			return _ok({"rewardId": "r-%d" % calls.size(), "ssvCustomData": "x"})
		"/pocao/matches/m-1/boost":
			var m := _match({"mode": "level"})
			m.state = {"tubes": [[0, 0, 1, 0], [1, 1, 0, 1], []], "movesUsed": 0, "moveLimit": 10, "points": 4,
				"shufflesLeft": 2, "flasksLeft": 0, "solved": false}
			return _ok({"match": m})
		"/pocao/matches/m-1/finish":
			return _ok({"matchId": "m-1", "solved": true, "rejected": false, "movesUsed": 3, "par": 3, "fullPoints": 6,
				"points": server_points, "credited": server_points, "best": null, "newBest": true, "nextLevel": level_number + 1,
				"gamePoints": 140, "gamePosition": 2})
		"/ranking":
			return _ok({"podium": [{"position": 1, "nickname": "Ana", "points": 900}], "rows": [
				{"position": 12, "nickname": "Eu", "points": 120, "isMe": true}]})
	return {"ok": false, "status": 404, "data": {}, "code": "NOT_FOUND", "message": ""}


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
	assert_eq(_paths().slice(0, 2), ["/auth/guest", "/pocao/home"])
	assert_ne(str(calls[0][2].deviceHash), "", "manda o identificador do aparelho")
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
	assert_eq(game.dialog.button_texts(), ["Menu"])


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
