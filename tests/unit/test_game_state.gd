extends "res://tests/test_case.gd"
## Progresso salvo: tentativas, melhor resultado e soma do mês.

const GameStateScript := preload("res://scripts/autoload/game_state.gd")

var state: Node


func before_each() -> void:
	state = GameStateScript.new()
	state.save_path = "user://test_progress_state.cfg"
	add_child(state)
	state.reset_all()


func after_each() -> void:
	state.free()


func test_attempts_count_up() -> void:
	assert_eq(state.attempts("2026-11-07#0"), 0)
	assert_eq(state.start_attempt("2026-11-07#0"), 1, "primeira tentativa")
	assert_eq(state.start_attempt("2026-11-07#0"), 2)


func test_best_result_wins() -> void:
	assert_true(state.save_result("2026-11-07#0", 7, 12), "primeiro resultado")
	assert_false(state.save_result("2026-11-07#0", 5, 9), "pior não substitui")
	assert_true(state.save_result("2026-11-07#0", 7, 10), "mesmos pontos com menos jogadas")
	var r: Dictionary = state.result("2026-11-07#0")
	assert_eq([r.best_points, r.best_moves, r.completed], [7, 10, true])


func test_zero_points_still_counts_as_completed() -> void:
	state.save_result("2026-11-07#3", 0, 40)
	assert_true(state.is_completed("2026-11-07#3"))


func test_month_total_only_counts_month() -> void:
	state.save_result("2026-11-01#0", 10, 8)
	state.save_result("2026-11-07#9", 25, 14)
	state.save_result("2026-10-31#0", 50, 20)
	assert_eq(state.month_total("2026-11"), {"points": 35, "moves": 22, "completed": 2})


func test_progress_is_saved_to_disk() -> void:
	state.save_result("2026-11-07#1", 9, 9)
	var other := GameStateScript.new()
	other.save_path = state.save_path
	other.load_progress()
	assert_eq(other.result("2026-11-07#1").best_points, 9)
	other.free()


func test_autoloads_are_registered() -> void:
	assert_true(ProjectSettings.has_setting("autoload/GameState"), "GameState")
	assert_true(ProjectSettings.has_setting("autoload/Ads"), "Ads")
