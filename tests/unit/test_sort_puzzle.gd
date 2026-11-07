extends "res://tests/test_case.gd"
## Regras de despejar, vitória, desfazer e o resolvedor de menor número de jogadas.

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


func test_moves_are_recorded() -> void:
	var p := SortPuzzle.new([[0, 1, 1], []])
	p.pour(0, 1)
	assert_eq(p.moves, [[0, 1]], "lista de jogadas para o servidor conferir")


func test_hidden_layers_reveal_when_on_top() -> void:
	var p := SortPuzzle.new([[0, 1, 2], []], true)
	assert_eq(p.hidden, [[true, true, false], []], "só o topo aparece")
	p.pour(0, 1)
	assert_eq(p.hidden, [[true, false], [false]], "a camada de baixo aparece ao virar topo")


func test_solved() -> void:
	assert_true(SortPuzzle.is_solved_state([[1, 1, 1, 1], [], [0, 0, 0, 0]]))
	assert_false(SortPuzzle.is_solved_state([[1, 1, 1], [1], [0, 0, 0, 0]]))


func test_min_moves_small() -> void:
	assert_eq(SortPuzzle.min_moves([[0, 0, 0, 0]]), 0, "já resolvido")
	assert_eq(SortPuzzle.min_moves([[0, 0, 0, 1], [1, 1, 1, 0], []]), 3)
