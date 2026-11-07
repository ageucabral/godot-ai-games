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


func test_cover_opens_when_key_color_completes() -> void:
	var p := SortPuzzle.new([[0, 0, 0], [0], [1, 1, 1, 1]], false, [-1, -1, 0])
	assert_false(p.can_pour(1, 2), "coberta não recebe")
	assert_false(p.can_pour(2, 1), "coberta não dá")
	p.pour(1, 0)
	assert_false(p.is_covered(2), "completou a cor 0: abriu")
	assert_eq(p.last_revealed, [2])


func test_two_covers_same_color_open_one_at_a_time() -> void:
	var covers := [-1, -1, -1, -1, 0, 0]
	var p := SortPuzzle.new([[0, 0, 0], [0], [0, 0, 0], [0], [2], [3]], false, covers)
	p.pour(1, 0)
	assert_eq(p.last_revealed, [4], "1ª garrafa completa abre o 1º pano")
	assert_true(p.is_covered(5))
	p.pour(3, 2)
	assert_eq(p.last_revealed, [5], "2ª garrafa completa abre o 2º pano")


func test_solver_respects_covers() -> void:
	# com o pano, a garrafa coberta só entra no jogo depois de completar a cor 0
	var tubes := [[0, 0, 0, 1], [1, 1, 1, 0], []]
	assert_eq(SortPuzzle.min_moves([[0, 0, 0], [0], [1, 1, 1, 1]], 1000, [-1, -1, 0]), 1)
	assert_eq(SortPuzzle.min_moves([[0, 0, 0], [1], [1, 1, 1, 0]], 1000, [-1, -1, 0]), -1, "a chave está debaixo do pano")
	assert_true(SortPuzzle.min_moves(tubes) > 0)


func test_shuffle_keeps_covered_and_complete_bottles() -> void:
	var p := SortPuzzle.new([[0, 1, 0, 1], [1, 0, 1, 3], [2, 2, 2, 2], [3, 3, 3, 0], [], []], false, [-1, -1, -1, 2, -1, -1])
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	assert_true(p.shuffle(rng))
	assert_eq(p.tubes[2], [2, 2, 2, 2], "garrafa completa fica igual")
	assert_eq(p.tubes[3], [3, 3, 3, 0], "garrafa coberta fica igual")
	assert_eq(p.moves_used(), 0, "embaralhar não conta como jogada")


func test_shuffle_keeps_hidden_layers_in_place() -> void:
	var p := SortPuzzle.new([[0, 1, 0, 1], [1, 0, 1, 0], [], []], true)
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var before: Array = SortPuzzle.copy_tubes(p.tubes)
	p.shuffle(rng)
	for i in 2:
		for j in 3:
			assert_eq(p.tubes[i][j], before[i][j], "camada \"?\" não muda de lugar")


func test_shuffle_same_seed_same_result() -> void:
	var tubes := [[0, 1, 2, 0], [1, 2, 0, 1], [2, 0, 1, 2], [], []]
	var a := SortPuzzle.new(tubes)
	var b := SortPuzzle.new(tubes)
	var r1 := RandomNumberGenerator.new()
	r1.seed = 42
	var r2 := RandomNumberGenerator.new()
	r2.seed = 42
	assert_eq(a.shuffled_state(r1), b.shuffled_state(r2), "a semente refaz o mesmo embaralhado")
