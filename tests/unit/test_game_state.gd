extends "res://tests/test_case.gd"
## Exemplo de teste de lógica: o placar global.

const GameStateScript := preload("res://scripts/autoload/game_state.gd")

var state: Node


func before_each() -> void:
	state = GameStateScript.new()
	add_child(state)


func after_each() -> void:
	state.free()


func test_starts_at_zero() -> void:
	assert_eq(state.score, 0)


func test_add_points() -> void:
	state.add_points(10)
	state.add_points(5)
	assert_eq(state.score, 15)


func test_score_never_negative() -> void:
	state.add_points(-50)
	assert_eq(state.score, 0)


func test_emits_signal() -> void:
	var received: Array[int] = []
	state.score_changed.connect(func(v: int) -> void: received.append(v))
	state.add_points(3)
	assert_eq(received, [3] as Array[int])


func test_autoload_is_registered() -> void:
	assert_true(ProjectSettings.has_setting("autoload/GameState"), "GameState registrado como autoload")
