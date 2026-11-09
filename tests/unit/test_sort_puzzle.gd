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


func test_ice_melts_with_moves() -> void:
	var p := SortPuzzle.new([[0, 0, 1], [1, 1, 0], [0, 1], [], []], false, [], [2, 0, 0, 0, 0])
	assert_true(p.is_frozen(0))
	assert_false(p.can_pour(0, 3), "congelada não despeja")
	assert_false(p.can_pour(2, 0), "nem recebe")
	assert_eq(p.ice_left(), [2, 0, 0, 0, 0])
	assert_eq(p.pour(2, 3), 1)
	assert_eq(p.pour(2, 4), 1)
	assert_eq(p.ice_left(), [0, 0, 0, 0, 0], "derreteu depois de 2 jogadas")
	assert_true(p.can_pour(0, 3))


func test_only_bottle_takes_one_color() -> void:
	var p := SortPuzzle.new([[0, 1], [1, 0], []], false, [], [], [-1, -1, 0])
	assert_true(p.can_pour(1, 2), "a cor certa entra")
	assert_false(p.can_pour(0, 2), "outra cor não entra")
	p.add_empty_tube()
	assert_eq(p.only, [-1, -1, 0, -1])
	assert_eq(p.ice, [0, 0, 0, 0])


func test_solver_respects_ice_and_only() -> void:
	var tubes := [[0, 0, 0, 1], [1, 1, 1, 0], []]
	var plain := SortPuzzle.min_moves(tubes)
	assert_true(SortPuzzle.min_moves(tubes, 400000, [], [], [-1, -1, 1]) >= plain, "frasco de uma cor nunca deixa mais curto")
	var iced := SortPuzzle.min_moves(tubes, 400000, [], [3, 0, 0])
	assert_true(iced == -1 or iced >= plain, "gelo nunca deixa mais curto")


func test_undo_restores_state_and_counts_the_move() -> void:
	var p := SortPuzzle.new([[0, 1, 1], [1], []])
	assert_false(p.can_undo())
	assert_false(p.undo(), "nada para desfazer")
	p.pour(0, 1)
	assert_eq(p.tubes, [[0], [1, 1, 1], []])
	assert_true(p.undo())
	assert_eq(p.tubes, [[0, 1, 1], [1], []], "voltou como estava")
	assert_eq(p.moves, [[0, 1], SortPuzzle.UNDO], "a jogada e o desfazer ficam na lista")
	assert_eq(p.moves_used(), 2, "o desfazer conta como jogada")
	assert_false(p.can_undo(), "um desfazer por despejo")
	# desfazer também volta um pano que tinha aberto
	var c := SortPuzzle.new([[0, 0, 0], [0], [2, 2, 2, 2]], false, [-1, -1, 0])
	c.pour(1, 0)
	assert_false(c.is_covered(2), "completou o azul: abriu o pano")
	c.undo()
	assert_true(c.is_covered(2), "o pano fecha de novo")
	# frasco extra zera o histórico (o estado antigo tinha menos garrafas)
	c.pour(1, 0)
	c.add_empty_tube()
	assert_false(c.can_undo())
