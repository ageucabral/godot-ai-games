extends "res://tests/test_case.gd"
## Caminho do jogador: menu → desafio → menu, e nova tentativa pedindo propaganda.

var main: Control


func before_each() -> void:
	GameState.save_path = "user://test_progress_main.cfg"
	GameState.reset_all()
	GameState.set_setting("tutorial_done", true)  # a partida guiada tem testes próprios
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
	main.dialog.press("Jogar de novo")
	assert_eq(GameState.attempts("2026-11-07#0"), 2)
	assert_true(main.get_node("Game").visible)


func test_game_ranking_button_opens_global() -> void:
	GameState.save_result("2026-11-02#0", 10, 6)
	main.get_node("Home").ranking_requested.emit()
	var ranking: Control = main.get_node("Ranking")
	assert_true(ranking.visible)
	assert_eq(ranking.title_label.text, "Ranking Global", "só existe o ranking global")
	assert_eq(ranking.points_label.text, "10 pts")
	ranking.back_requested.emit()
	assert_true(main.get_node("Home").visible, "volta ao menu do jogo")


func test_global_ranking_opens_from_hub() -> void:
	GameState.save_result("2026-11-02#0", 10, 6)
	var hub: Control = main.get_node("Hub")
	assert_eq(hub.rank_banner.countdown, "23d 12h")
	hub.rank_banner.pressed.emit()
	var ranking: Control = main.get_node("Ranking")
	assert_true(ranking.visible)
	assert_eq(ranking.title_label.text, "Ranking Global")
	assert_eq(ranking.points_label.text, "10 pts")
	ranking.back_requested.emit()
	assert_true(hub.visible, "volta ao hub")


func test_hub_banner_countdown_turns_with_month() -> void:
	var hub: Control = main.get_node("Hub")
	GameState.fixed_unix = 1794063600 + 24 * 86400  # 1/12/2026 meio-dia em Brasília
	hub._update_countdown()
	assert_eq(hub._month, "2026-12", "mês novo")


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
	assert_eq(home.daily_button.text, "Desafios do dia  0/20")


func test_home_follows_midnight_without_looping() -> void:
	var home: Control = main.get_node("Home")
	GameState.save_result("2026-11-07#0", 10, 5)
	assert_eq(home.daily_button.text, "Desafios do dia  1/20")
	# meia-noite em ponto: antes, refresh e a contagem se chamavam sem fim
	GameState.fixed_unix = 1794106800
	home.refresh()
	assert_eq(home.daily_button.text, "Desafios do dia  0/20")
	# app volta do segundo plano já depois da meia-noite: também percebe o dia novo
	GameState.fixed_unix = 1794106800 + 86400 + 1800
	home._check_new_day()
	assert_eq(home._shown_day, "2026-11-09")


func test_level_button_opens_current_level() -> void:
	main.get_node("Home").level_requested.emit()
	var game: Control = main.get_node("Game")
	assert_true(game.visible, "abriu a partida")
	assert_true(game.is_level())
	assert_eq(game.challenge.level, 1)
	assert_eq(game.challenge.full_points, Rules.full_points_for(game.challenge.par))
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
	assert_eq(GameState.month_total("2026-11").points, Rules.full_points_for(LevelGenerator.generate(1).par))
	assert_eq(GameState.month_total("2026-11").levels, 1)
	game.dialog.press("Próximo nível")
	assert_eq(game.challenge.level, 2)
	assert_eq(main.get_node("Home").level_button.text, "Nível 2")


func test_settings_language_switch() -> void:
	var home: Control = main.get_node("Home")
	Menus.open_settings(home.dialog)
	assert_true(home.dialog.visible)
	Menus.open_language(home.dialog)
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


func test_app_opens_on_hub_and_enters_game() -> void:
	assert_true(main.get_node("Hub").visible, "abre no hub Na Lata")
	main.get_node("Hub").cards["potion"].pressed.emit()
	assert_true(main.get_node("Home").visible, "entra no Poção de Cores")
	var splash: Node = null
	for c in main.get_children():
		if c is SplashOverlay:
			splash = c
	assert_not_null(splash, "mostra a tela de abertura")
	splash.close()
	main.get_node("Home").side_buttons["games"].pressed.emit()
	assert_true(main.get_node("Hub").visible, "aba Jogos volta ao hub")


func test_pause_menu_returns_home() -> void:
	main.get_node("Home").level_requested.emit()
	var game: Control = main.get_node("Game")
	game.get_node("%MenuButton").pressed.emit()
	assert_eq(game.dialog.title_label.text, "Pausa")
	game.dialog.press("Menu")
	assert_true(main.get_node("Home").visible)


func test_home_has_side_icons_and_no_profile_tab() -> void:
	var home: Control = main.get_node("Home")
	assert_eq(home.side_buttons.keys(), ["games", "ranking"], "Jogos e Ranking na lateral")
	home.side_buttons["ranking"].pressed.emit()
	assert_true(main.get_node("Ranking").visible)


func test_daily_button_below_level_shows_progress() -> void:
	var home: Control = main.get_node("Home")
	assert_eq(home.daily_button.get_parent(), home.level_button.get_parent(), "embaixo do botão do nível")
	assert_true(home.daily_button.get_index() > home.level_button.get_index())
	for i in Rules.DAILY_COUNT:
		GameState.save_result("2026-11-07#%d" % i, 10, 5)
	assert_eq(home.daily_button.text, "Desafios feitos!  20/20")
	assert_eq(home.daily_button.fill, GameStyle.PURPLE, "muda de cor quando termina o dia")
	home.daily_button.pressed.emit()
	assert_true(main.get_node("Daily").visible, "abre os desafios do dia")


func test_profile_lives_in_settings() -> void:
	var home: Control = main.get_node("Home")
	Menus.open_settings(home.dialog)
	assert_true("Sua conta" in home.dialog.button_texts())
	home.dialog.press("Sua conta")
	assert_eq(home.dialog.title_label.text, "Sua conta")
