extends Node
## Base para todos os testes. Cada teste é um arquivo tests/unit/test_*.gd que
## começa com:  extends "res://tests/test_case.gd"
## e tem funções chamadas test_alguma_coisa().

var _failures: Array[String] = []


## Executado antes de cada teste. Pode ser sobrescrito.
func before_each() -> void:
	pass


## Executado depois de cada teste. Pode ser sobrescrito.
func after_each() -> void:
	pass


func fail(message: String) -> void:
	_failures.append(message)


func assert_true(condition: bool, message: String = "esperava verdadeiro") -> void:
	if not condition:
		fail(message)


func assert_false(condition: bool, message: String = "esperava falso") -> void:
	if condition:
		fail(message)


func assert_eq(actual: Variant, expected: Variant, message: String = "") -> void:
	if actual != expected:
		fail("%s esperado=%s obtido=%s" % [message, var_to_str(expected), var_to_str(actual)])


func assert_ne(actual: Variant, not_expected: Variant, message: String = "") -> void:
	if actual == not_expected:
		fail("%s não esperava %s" % [message, var_to_str(actual)])


func assert_not_null(value: Variant, message: String = "esperava valor não nulo") -> void:
	if value == null:
		fail(message)


func assert_almost_eq(actual: float, expected: float, tolerance: float = 0.0001, message: String = "") -> void:
	if absf(actual - expected) > tolerance:
		fail("%s esperado≈%s obtido=%s" % [message, expected, actual])


## Espera N quadros de física (útil para testar movimento).
func wait_physics_frames(count: int) -> void:
	for i in count:
		await get_tree().physics_frame
