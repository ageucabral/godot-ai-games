extends Control
## Tela da partida: liga as regras (SortPuzzle) às garrafinhas, ao placar e aos botões.

## Desafio de exemplo (médio, 5 cores, 2 garrafas vazias). Números = cores de TropicalStyle.LIQUIDS.
const SAMPLE_TUBES: Array = [[0, 1, 2, 3], [4, 0, 3, 1], [2, 4, 1, 0], [3, 2, 4, 4], [1, 3, 0, 2], [], []]
## Menor número de jogadas para resolver o exemplo (conferido por teste com o resolvedor).
const SAMPLE_PAR: int = 15
const SAMPLE_POINTS: int = 200
const EXTRA_MOVES: int = 5

@onready var _row_top: HBoxContainer = %RowTop
@onready var _row_bottom: HBoxContainer = %RowBottom
@onready var _challenge_value: Label = %ChallengeValue
@onready var _moves_value: Label = %MovesValue
@onready var _points_value: Label = %PointsValue
@onready var _subtitle: Label = %Subtitle
@onready var _undo_button: Button = %UndoButton
@onready var _restart_button: Button = %RestartButton
@onready var _extra_button: Button = %ExtraButton
@onready var _win_overlay: Control = %WinOverlay
@onready var _win_title: Label = %WinTitle
@onready var _win_text: Label = %WinText
@onready var _play_again_button: Button = %PlayAgainButton

var puzzle: SortPuzzle
var move_limit: int = SAMPLE_PAR
var selected: int = -1
var _bottles: Array[BottleView] = []


func _ready() -> void:
	theme = TropicalStyle.build_theme()
	for l: Label in [_subtitle, _win_title]:
		l.add_theme_font_override("font", TropicalStyle.title_font())
	_undo_button.pressed.connect(_on_undo)
	_restart_button.pressed.connect(start)
	_extra_button.pressed.connect(_on_extra_moves)
	_play_again_button.pressed.connect(start)
	start()


func start() -> void:
	load_challenge(SAMPLE_TUBES, SAMPLE_PAR)


## Monta um desafio: as garrafas iniciais e o limite de jogadas.
func load_challenge(tubes: Array, par: int) -> void:
	puzzle = SortPuzzle.new(tubes)
	move_limit = par
	selected = -1
	_win_overlay.visible = false
	_build_bottles()
	_refresh()


## Pontos: cada jogada além do limite custa 1 ponto, nunca abaixo de zero.
static func score_for(base_points: int, moves_used: int, limit: int) -> int:
	return maxi(0, base_points - maxi(0, moves_used - limit))


## Toque numa garrafa: a primeira escolhe, a segunda recebe o líquido.
func tap_bottle(i: int) -> void:
	if _win_overlay.visible:
		return
	if selected == -1:
		if not (puzzle.tubes[i] as Array).is_empty():
			selected = i
	elif selected == i:
		selected = -1
	elif puzzle.pour(selected, i) > 0:
		selected = -1
	else:
		_bottles[i].shake()
		selected = i if not (puzzle.tubes[i] as Array).is_empty() else -1
	_refresh()
	if puzzle.is_solved():
		_show_win()


func _build_bottles() -> void:
	for b in _bottles:
		b.queue_free()
	_bottles.clear()
	var count: int = puzzle.tubes.size()
	var top_count: int = ceili(count / 2.0)
	for i in count:
		var b := BottleView.new()
		b.index = i
		b.tapped.connect(tap_bottle)
		(_row_top if i < top_count else _row_bottom).add_child(b)
		_bottles.append(b)


func _refresh() -> void:
	for i in _bottles.size():
		_bottles[i].layers = puzzle.tubes[i]
		_bottles[i].selected = (i == selected)
	var used: int = puzzle.moves_used()
	_moves_value.text = "%d / %d" % [used, move_limit]
	_moves_value.add_theme_color_override("font_color", TropicalStyle.ACCENT if used > move_limit else TropicalStyle.INK)
	_points_value.text = str(score_for(SAMPLE_POINTS, used, move_limit))
	_challenge_value.text = "Exemplo"
	_undo_button.disabled = not puzzle.can_undo()


func _on_undo() -> void:
	puzzle.undo()
	selected = -1
	_refresh()


## Por enquanto dá as jogadas direto; depois vira o anúncio premiado (AdMob).
func _on_extra_moves() -> void:
	move_limit += EXTRA_MOVES
	_refresh()


func _show_win() -> void:
	var used: int = puzzle.moves_used()
	_win_text.text = "Você fez %d pontos\nem %d jogadas." % [score_for(SAMPLE_POINTS, used, move_limit), used]
	_win_overlay.visible = true
