extends "res://tests/test_case.gd"
## Caminho do jogador: menu → desafio → menu, e nova tentativa pedindo propaganda.

var main: Control


func before_each() -> void:
	GameState.save_path = "user://test_progress_main.cfg"
	GameState.reset_all()
	GameState.fixed_unix = 1794063600  # 7/11/2026 meio-dia em Brasília
	Ads.instant = true
	main = load("res://scenes/main/main.tscn").instantiate()
	add_child(main)


func after_each() -> void:
	main.free()
	GameState.fixed_unix = -1
	Ads.instant = false


func test_daily_shows_20_challenges() -> void:
	main.get_node("Home").daily_requested.emit()
	var home: Control = main.get_node("Daily")
	assert_true(home.visible)
	assert_eq(home.grid.get_child_count(), 20)
	assert_eq(home.day_label.text, "Hoje, 7 de novembro")
	assert_eq(home.play_button.text, "Jogar desafio 1")


func test_first_attempt_is_free() -> void:
	main.get_node("Daily").play_button.pressed.emit()
	assert_true(main.get_node("Game").visible, "abriu a partida")
	assert_eq(GameState.attempts("2026-11-07#0"), 1)
	assert_false(main.dialog.visible, "sem propaganda")


func test_second_attempt_asks_for_ad() -> void:
	main.request_play("2026-11-07", 0)
	main.get_node("Game").back_requested.emit()
	assert_true(main.get_node("Daily").visible, "voltou aos desafios do dia")
	main.request_play("2026-11-07", 0)
	assert_true(main.dialog.visible, "pede propaganda")
	main.dialog.press("Assistir e jogar")
	assert_eq(GameState.attempts("2026-11-07#0"), 2)
	assert_true(main.get_node("Game").visible)


func test_ranking_shows_month_points() -> void:
	GameState.save_result("2026-11-02#0", 10, 6)
	main.get_node("Home").ranking_requested.emit()
	var ranking: Control = main.get_node("Ranking")
	assert_true(ranking.visible)
	assert_eq(ranking.title_label.text, "Ranking de novembro")
	assert_eq(ranking.points_label.text, "10 pts")


func test_declining_ad_returns_to_menu() -> void:
	main.request_play("2026-11-07", 0)
	main.request_play("2026-11-07", 0)
	assert_true(main.dialog.visible, "pede propaganda")
	main.dialog.press("Voltar")
	assert_true(main.get_node("Daily").visible, "não fica preso na partida")


func test_daily_follows_midnight() -> void:
	var home: Control = main.get_node("Daily")
	GameState.fixed_unix += 86400
	home._update_countdown()
	assert_eq(home.day_label.text, "Hoje, 8 de novembro")


func test_past_days_cannot_be_played() -> void:
	main.request_play("2026-11-06", 0)
	assert_true(main.dialog.visible, "avisa que acabou")
	assert_eq(main.dialog.title_label.text, "Desafio encerrado")
	assert_false(main.get_node("Game").visible, "não abre a partida")
	assert_eq(GameState.attempts("2026-11-06#0"), 0)


func test_home_shows_level_and_daily_buttons() -> void:
	var home: Control = main.get_node("Home")
	assert_eq(home.level_button.text, "Nível 1")
	assert_eq(home.daily_button.text, "Desafios do dia · 0/20")
	assert_eq(home.podium.countdown, "23d 12h", "ranking acaba no fim de novembro")


func test_home_follows_midnight_without_looping() -> void:
	var home: Control = main.get_node("Home")
	GameState.save_result("2026-11-07#0", 10, 5)
	assert_eq(home.daily_button.text, "Desafios do dia · 1/20")
	# meia-noite em ponto: antes, refresh e a contagem se chamavam sem fim
	GameState.fixed_unix = 1794106800
	home.refresh()
	assert_eq(home.daily_button.text, "Desafios do dia · 0/20")
	# app volta do segundo plano já depois da meia-noite: também percebe o dia novo
	GameState.fixed_unix = 1794106800 + 86400 + 1800
	home._update_countdown()
	assert_eq(home._shown_day, "2026-11-09")


func test_level_button_opens_current_level() -> void:
	main.get_node("Home").level_requested.emit()
	var game: Control = main.get_node("Game")
	assert_true(game.visible, "abriu a partida")
	assert_true(game.is_level())
	assert_eq(game.challenge.level, 1)
	assert_eq(game.challenge.full_points, Rules.LEVEL_POINTS)
	game.back_requested.emit()
	assert_true(main.get_node("Home").visible, "Menu da partida volta ao início")


func test_finishing_level_unlocks_next_and_counts_in_ranking() -> void:
	main.get_node("Home").level_requested.emit()
	var game: Control = main.get_node("Game")
	game.animate = false
	_solve(game)
	assert_eq(GameState.current_level(), 2)
	assert_true(game.dialog.visible, "mostra a vitória")
	assert_eq(game.dialog.button_texts()[0], "Próximo nível")
	assert_eq(GameState.month_total("2026-11").points, Rules.LEVEL_POINTS)
	assert_eq(GameState.month_total("2026-11").levels, 1)
	game.dialog.press("Próximo nível")
	assert_eq(game.challenge.level, 2)
	assert_eq(main.get_node("Home").level_button.text, "Nível 2")


func test_settings_language_switch() -> void:
	var home: Control = main.get_node("Home")
	home.open_settings()
	assert_true(home.dialog.visible)
	home.open_language()
	home.dialog.press("English")
	assert_eq(GameState.language(), "en")
	assert_eq(home.level_button.text, "Level 1")
	assert_eq(Rules.pretty_date("2026-11-07"), "November 7")
	GameState.set_language("pt")
	assert_eq(home.level_button.text, "Nível 1")
	assert_eq(Rules.pretty_date("2026-11-07"), "7 de novembro")


## Resolve o nível aberto seguindo a solução mais curta (busca simples, níveis iniciais são pequenos).
func _solve(game: Control) -> void:
	var path := _shortest_path(game.puzzle.tubes)
	assert_true(path.size() > 0, "achou solução")
	for move in path:
		game.tap_bottle(move[0])
		game.tap_bottle(move[1])


func _shortest_path(start: Array) -> Array:
	var queue: Array = [[SortPuzzle.copy_tubes(start), []]]
	var seen := {str(start): true}
	while not queue.is_empty():
		var item: Array = queue.pop_front()
		var state: Array = item[0]
		if SortPuzzle.is_solved_state(state):
			return item[1]
		for a in state.size():
			for b in state.size():
				if SortPuzzle.can_pour_in(state, a, b):
					var next := SortPuzzle.copy_tubes(state)
					SortPuzzle.pour_in(next, a, b)
					if not seen.has(str(next)):
						seen[str(next)] = true
						var moves: Array = (item[1] as Array).duplicate()
						moves.append([a, b])
						queue.append([next, moves])
	return []


func test_leaving_level_resumes_same_game() -> void:
	main.get_node("Home").level_requested.emit()
	var game: Control = main.get_node("Game")
	game.animate = false
	for i in game.puzzle.tubes.size():
		if not (game.puzzle.tubes[i] as Array).is_empty():
			for j in game.puzzle.tubes.size():
				if game.puzzle.can_pour(i, j):
					game.tap_bottle(i)
					game.tap_bottle(j)
					break
			break
	assert_eq(game.puzzle.moves_used(), 1)
	game.back_requested.emit()
	main.get_node("Home").level_requested.emit()
	assert_eq(game.puzzle.moves_used(), 1, "voltar pelo Menu não recomeça de graça")
