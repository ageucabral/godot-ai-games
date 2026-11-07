extends "res://tests/test_case.gd"
## Toques na tela da partida: escolher, despejar, desfazer e vencer.

var screen: Control


func before_each() -> void:
	screen = load("res://scenes/game/game_screen.tscn").instantiate()
	add_child(screen)


func after_each() -> void:
	screen.free()


func test_tap_selects_then_pours() -> void:
	screen.tap_bottle(0)
	assert_eq(screen.selected, 0, "primeiro toque escolhe")
	screen.tap_bottle(5)
	assert_eq(screen.selected, -1, "segundo toque despeja")
	assert_eq(screen.puzzle.tubes[5], [3], "uva foi para a garrafa vazia")
	assert_eq(screen.get_node("%MovesValue").text, "1 / 15")


func test_empty_bottle_is_not_selected() -> void:
	screen.tap_bottle(6)
	assert_eq(screen.selected, -1)


func test_invalid_pour_keeps_puzzle() -> void:
	screen.tap_bottle(0)  # uva no topo
	screen.tap_bottle(1)  # hortelã no topo: não pode
	assert_eq(screen.puzzle.moves_used(), 0)
	assert_eq(screen.selected, 1, "passa a escolher a garrafa tocada")


func test_extra_moves_and_undo() -> void:
	screen.tap_bottle(0)
	screen.tap_bottle(5)
	screen.get_node("%ExtraButton").pressed.emit()
	assert_eq(screen.move_limit, 20)
	screen.get_node("%UndoButton").pressed.emit()
	assert_eq(screen.puzzle.moves_used(), 0)


func test_win_shows_overlay() -> void:
	screen.load_challenge([[0, 0, 0, 1], [1, 1, 1, 0], []], 3)
	screen.tap_bottle(0)
	screen.tap_bottle(2)
	screen.tap_bottle(1)
	screen.tap_bottle(0)
	screen.tap_bottle(2)
	screen.tap_bottle(1)
	assert_true(screen.puzzle.is_solved(), "resolvido")
	assert_true(screen.get_node("%WinOverlay").visible, "mostra Na Lata!")
	assert_eq(screen.get_node("%WinText").text, "Você fez 200 pontos\nem 3 jogadas.")
