extends Control
## Tela da partida: liga as regras (SortPuzzle + Rules) às garrafinhas, ao placar e aos botões.

signal back_requested
signal next_requested(date: String, index: int)

const POUR_MOVE_TIME: float = 0.22
const POUR_FLOW_TIME: float = 0.38
const POUR_ANGLE_DEG: float = 72.0

@onready var _row_top: HBoxContainer = %RowTop
@onready var _row_bottom: HBoxContainer = %RowBottom
@onready var _challenge_value: Label = %ChallengeValue
@onready var _moves_value: Label = %MovesValue
@onready var _points_value: Label = %PointsValue
@onready var _subtitle: Label = %Subtitle
@onready var _menu_button: Button = %MenuButton
@onready var _restart_button: Button = %RestartButton
@onready var _extra_button: Button = %ExtraButton

## Desliga a animação (os testes usam para as jogadas acontecerem na hora).
var animate: bool = true
var challenge: Dictionary = {}
var puzzle: SortPuzzle
var move_limit: int = 0
var selected: int = -1
var busy: bool = false
var dialog: DialogBox
var _bottles: Array[BottleView] = []
var _finished: bool = false
var _pour_tween: Tween


func _ready() -> void:
	theme = TropicalStyle.build_theme()
	_subtitle.add_theme_font_override("font", TropicalStyle.title_font())
	dialog = DialogBox.new()
	add_child(dialog)
	_menu_button.pressed.connect(func() -> void: back_requested.emit())
	_restart_button.pressed.connect(_on_restart_pressed)
	_extra_button.pressed.connect(_on_extra_moves_pressed)


## Abre um desafio do dia e começa uma tentativa nova.
## (Quem chama decide se a tentativa precisa de propaganda; veja main.gd.)
func open_challenge(date: String, index: int) -> void:
	var data := ChallengeGenerator.generate(date, index)
	if data.is_empty():
		# o gerador falhou: volta ao menu sem gastar a tentativa
		back_requested.emit()
		return
	open_with(data)
	GameState.start_attempt(key())


## Monta a tela com um desafio já pronto (usado também pelos testes).
func open_with(data: Dictionary) -> void:
	if _pour_tween and _pour_tween.is_valid():
		_pour_tween.kill()  # um despejo da partida anterior não pode mexer na nova
	challenge = data
	puzzle = SortPuzzle.new(data.tubes, data.get("hidden", false))
	move_limit = data.par
	selected = -1
	busy = false
	_finished = false
	dialog.close()
	_build_bottles()
	_refresh()


func key() -> String:
	return ChallengeGenerator.key_for(challenge.get("date", ""), challenge.get("index", 0))


func current_points() -> int:
	return Rules.score_for(challenge.full_points, challenge.par, puzzle.moves_used())


func out_of_moves() -> bool:
	return puzzle.moves_used() >= move_limit and not puzzle.is_solved()


## Toque numa garrafa: a primeira escolhe, a segunda recebe o líquido.
func tap_bottle(i: int) -> void:
	if busy or _finished or dialog.visible:
		return
	if out_of_moves():
		_show_out_of_moves()
		return
	if selected == -1:
		if not (puzzle.tubes[i] as Array).is_empty():
			selected = i
	elif selected == i:
		selected = -1
	elif puzzle.can_pour(selected, i):
		_do_pour(selected, i)
		return
	else:
		_bottles[i].shake()
		selected = i if not (puzzle.tubes[i] as Array).is_empty() else -1
	_refresh()


func _do_pour(from: int, to: int) -> void:
	var src_before := BottleView.segments_from(puzzle.tubes[from], puzzle.hidden[from])
	var dst_before := BottleView.segments_from(puzzle.tubes[to], puzzle.hidden[to])
	var color: int = puzzle.tubes[from][-1]
	var amount := puzzle.pour(from, to)
	selected = -1
	if not animate or not is_inside_tree():
		_after_pour()
		return
	busy = true
	_animate_pour(_bottles[from], _bottles[to], src_before, dst_before, color, amount)


func _animate_pour(src: BottleView, dst: BottleView, src_before: Array, dst_before: Array, color: int, amount: int) -> void:
	var dir: float = 1.0 if dst.global_position.x >= src.global_position.x else -1.0
	var angle := deg_to_rad(POUR_ANGLE_DEG) * dir
	var dst_mouth := dst.mouth_global(0.0, Vector2.ZERO, 0.0)
	var target := dst_mouth + Vector2(-dir * 4.0, -40.0)
	var offset := target - src.mouth_global(angle, Vector2.ZERO)
	src.z_index = 10
	dst.cap_open = true
	src.stream_color = TropicalStyle.liquid_color(color)
	src.stream_end = dst.surface_global()

	var t := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_pour_tween = t
	t.tween_property(src, "pour_offset", offset, POUR_MOVE_TIME)
	t.parallel().tween_property(src, "pour_angle", angle, POUR_MOVE_TIME)
	t.tween_callback(func() -> void: src.stream_on = true)
	t.tween_method(func(p: float) -> void:
		_set_flow(src, dst, src_before, dst_before, color, amount, p), 0.0, 1.0, POUR_FLOW_TIME)
	t.tween_callback(func() -> void: src.stream_on = false)
	t.tween_property(src, "pour_offset", Vector2.ZERO, POUR_MOVE_TIME)
	t.parallel().tween_property(src, "pour_angle", 0.0, POUR_MOVE_TIME)
	t.tween_callback(func() -> void:
		src.z_index = 0
		dst.cap_open = false
		busy = false
		_after_pour())


## Meio do despejo: o topo da origem esvazia enquanto o destino enche.
static func flow_segments(src_before: Array, dst_before: Array, color: int, amount: int, p: float) -> Array:
	var src_now: Array = []
	for i in src_before.size():
		var seg: Array = (src_before[i] as Array).duplicate()
		if i >= src_before.size() - amount:
			seg[1] = 1.0 - p
		src_now.append(seg)
	var dst_now: Array = []
	for seg in dst_before:
		dst_now.append((seg as Array).duplicate())
	dst_now.append([color, amount * p, false])
	return [src_now, dst_now]


func _set_flow(src: BottleView, dst: BottleView, src_before: Array, dst_before: Array, color: int, amount: int, p: float) -> void:
	var segs := flow_segments(src_before, dst_before, color, amount, p)
	src.segments = segs[0]
	dst.segments = segs[1]
	src.stream_end = dst.surface_global()


func _after_pour() -> void:
	_refresh()
	if puzzle.is_solved():
		_finish()
	elif current_points() == 0:
		_show_zero_points()
	elif out_of_moves():
		_show_out_of_moves()


func _build_bottles() -> void:
	for b in _bottles:
		b.queue_free()
	_bottles.clear()
	var count: int = puzzle.tubes.size()
	var top_count: int = ceili(count / 2.0)
	var width := minf(108.0, (640.0 - (top_count - 1) * 24.0) / top_count)
	for i in count:
		var b := BottleView.new()
		b.index = i
		b.set_bottle_width(width)
		b.tapped.connect(tap_bottle)
		(_row_top if i < top_count else _row_bottom).add_child(b)
		_bottles.append(b)


func _refresh() -> void:
	for i in _bottles.size():
		_bottles[i].segments = BottleView.segments_from(puzzle.tubes[i], puzzle.hidden[i])
		_bottles[i].selected = (i == selected)
	var used: int = puzzle.moves_used()
	_moves_value.text = "%d / %d" % [used, move_limit]
	_moves_value.add_theme_color_override("font_color", TropicalStyle.ACCENT if used > challenge.par else TropicalStyle.INK)
	_points_value.text = str(current_points())
	_challenge_value.text = "%d / %d" % [challenge.get("index", 0) + 1, Rules.DAILY_COUNT]
	var diff: String = challenge.difficulty
	_subtitle.text = "%s · vale %d pontos" % [Rules.DIFFICULTY_NAMES[diff], challenge.full_points]
	_extra_button.disabled = not out_of_moves()


# ---------- botões e avisos ----------

func _on_restart_pressed() -> void:
	if busy:
		return
	dialog.open("Recomeçar?", "Cada nova tentativa pede uma propaganda.\nVale sempre o seu melhor resultado.", [
		["Assistir e recomeçar", _restart_with_ad, true],
		["Continuar jogando", func() -> void: pass],
	])


func _restart_with_ad() -> void:
	Ads.show_rewarded(func() -> void: open_challenge(challenge.date, challenge.index))


func _on_extra_moves_pressed() -> void:
	Ads.show_rewarded(func() -> void:
		move_limit += Rules.EXTRA_MOVES
		_refresh())


func _show_out_of_moves() -> void:
	dialog.open("Acabaram as jogadas", "Assista a uma propaganda para ganhar +%d jogadas.\nCada jogada além de %d tira 1 ponto." % [Rules.EXTRA_MOVES, challenge.par], [
		["+%d jogadas" % Rules.EXTRA_MOVES, _on_extra_moves_pressed, true],
		["Recomeçar", _restart_with_ad],
		["Menu", func() -> void: back_requested.emit()],
	])


func _show_zero_points() -> void:
	dialog.open("Pontuação zerada", "Assista a uma propaganda para recomeçar este desafio.", [
		["Recomeçar", _restart_with_ad, true],
		["Menu", func() -> void: back_requested.emit()],
	])


## Próximo desafio ainda não resolvido do mesmo dia, depois deste (dá a volta). -1 se não houver.
static func next_unsolved_after(date: String, index: int) -> int:
	for step in range(1, Rules.DAILY_COUNT):
		var i := (index + step) % Rules.DAILY_COUNT
		if not GameState.is_completed(ChallengeGenerator.key_for(date, i)):
			return i
	return -1


func _finish() -> void:
	_finished = true
	var points := current_points()
	var used := puzzle.moves_used()
	var improved := GameState.save_result(key(), points, used)
	var best: Dictionary = GameState.result(key())
	var text := "+%d pontos em %d jogadas." % [points, used]
	if not improved:
		text += "\nSeu melhor continua %d pontos." % best.best_points
	elif points < challenge.full_points:
		text += "\nDava para fazer em %d jogadas." % challenge.par
	var buttons: Array = []
	var next_index := next_unsolved_after(challenge.date, challenge.index)
	if next_index >= 0:
		buttons.append(["Próximo desafio", func() -> void: next_requested.emit(challenge.date, next_index), true])
	if points < challenge.full_points:
		buttons.append(["Tentar melhorar", _restart_with_ad])
	buttons.append(["Menu", func() -> void: back_requested.emit()])
	dialog.open("Na Lata!", text, buttons)
