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


func test_home_shows_20_challenges() -> void:
	var home: Control = main.get_node("Home")
	assert_eq(home.grid.get_child_count(), 20)
	assert_eq(home.day_label.text, "Hoje, 7 de novembro")
	assert_eq(home.play_button.text, "Jogar desafio 1")


func test_first_attempt_is_free() -> void:
	main.get_node("Home").play_button.pressed.emit()
	assert_true(main.get_node("Game").visible, "abriu a partida")
	assert_eq(GameState.attempts("2026-11-07#0"), 1)
	assert_false(main.dialog.visible, "sem propaganda")


func test_second_attempt_asks_for_ad() -> void:
	main.request_play("2026-11-07", 0)
	main.get_node("Game").back_requested.emit()
	assert_true(main.get_node("Home").visible, "voltou ao menu")
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
