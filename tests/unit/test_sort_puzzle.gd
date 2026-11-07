extends "res://tests/test_case.gd"
## Regras de despejar, vitória, desfazer e o resolvedor de menor número de jogadas.

const GameScreenScript := preload("res://scripts/game/game_screen.gd")


func test_pour_into_empty() -> void:
	var p := SortPuzzle.new([[0, 1], []])
	assert_eq(p.pour(0, 1), 1, "move uma camada")
	assert_eq(p.tubes, [[0], [1]])
	assert_eq(p.moves_used(), 1)


func test_pour_moves_whole_top_run() -> void:
	var p := SortPuzzle.new([[0, 1, 1], [1]])
	assert_eq(p.pour(0, 1), 2, "as duas camadas iguais do topo")
	assert_eq(p.tubes, [[0], [1, 1, 1]])


func test_pour_limited_by_space() -> void:
	var p := SortPuzzle.new([[2, 2, 2], [0, 2, 2]])
	assert_eq(p.pour(0, 1), 1, "só cabe uma")
	assert_eq(p.tubes, [[2, 2], [0, 2, 2, 2]])


func test_cannot_pour_on_other_color_or_full() -> void:
	var p := SortPuzzle.new([[0], [1], [2, 2, 2, 2]])
	assert_false(p.can_pour(0, 1), "cor diferente")
	assert_false(p.can_pour(0, 2), "garrafa cheia")
	assert_false(p.can_pour(0, 0), "mesma garrafa")
	assert_eq(p.pour(0, 1), 0, "jogada inválida não muda nada")
	assert_eq(p.moves_used(), 0)


func test_undo() -> void:
	var p := SortPuzzle.new([[0, 1, 1], []])
	p.pour(0, 1)
	assert_true(p.undo())
	assert_eq(p.tubes, [[0, 1, 1], []])
	assert_eq(p.moves_used(), 0)
	assert_false(p.undo(), "nada para desfazer")


func test_solved() -> void:
	assert_true(SortPuzzle.is_solved_state([[1, 1, 1, 1], [], [0, 0, 0, 0]]))
	assert_false(SortPuzzle.is_solved_state([[1, 1, 1], [1], [0, 0, 0, 0]]))


func test_min_moves_small() -> void:
	assert_eq(SortPuzzle.min_moves([[0, 0, 0, 0]]), 0, "já resolvido")
	assert_eq(SortPuzzle.min_moves([[0, 0, 0, 1], [1, 1, 1, 0], []]), 3)


func test_sample_par_matches_solver() -> void:
	assert_eq(SortPuzzle.min_moves(GameScreenScript.SAMPLE_TUBES), GameScreenScript.SAMPLE_PAR, "limite de jogadas do exemplo")


func test_score_for() -> void:
	assert_eq(GameScreenScript.score_for(200, 15, 15), 200, "dentro do limite")
	assert_eq(GameScreenScript.score_for(200, 18, 15), 197, "3 jogadas a mais")
	assert_eq(GameScreenScript.score_for(5, 30, 15), 0, "nunca negativo")
