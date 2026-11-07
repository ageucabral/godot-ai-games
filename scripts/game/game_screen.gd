extends Control
## Tela da partida: liga as regras (SortPuzzle + Rules) às garrafinhas, ao placar e aos botões.

signal back_requested
signal next_requested(date: String, index: int)
signal next_level_requested

const POUR_MOVE_TIME: float = 0.22
const POUR_FLOW_TIME: float = 0.38
const POUR_ANGLE_DEG: float = 72.0
## Cor dos pontos no placar: normal e quando já passou do número exato de jogadas.
const POINTS_COLOR := Color("6b3d10")
const POINTS_OVER_COLOR := Color("e0303f")

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
## Nos níveis: o jogador escolheu "Continuar sem pontos" (não mostra o aviso de novo).
var _zero_accepted: bool = false
var _pour_tween: Tween
## Pontos mostrados no placar (para perceber quando caem e animar o "-1").
var _shown_points: int = -1


func _ready() -> void:
	theme = GameStyle.build_theme()
	var bg := GameStyle.add_background(self, "night")
	move_child(bg, 0)
	_style_hud()
	dialog = DialogBox.new()
	add_child(dialog)
	_menu_button.pressed.connect(_open_pause)
	_restart_button.pressed.connect(_on_restart_pressed)
	_extra_button.pressed.connect(_on_extra_moves_pressed)


func _style_hud() -> void:
	var pill := GameStyle.pill_box()
	pill.content_margin_left = 8
	%PointsPill.add_theme_stylebox_override("panel", pill)
	_points_value.add_theme_font_override("font", GameStyle.title_font())
	_points_value.add_theme_color_override("font_color", POINTS_COLOR)
	%LevelPlate.add_theme_stylebox_override("panel", GameStyle.plate_box())
	GameStyle.apply_title_look(_challenge_value, Color.WHITE, 10)
	_subtitle.add_theme_font_override("font", GameStyle.title_font())
	_subtitle.add_theme_color_override("font_color", Color("c9d4ff"))
	var chip := GameStyle.plate_box()
	chip.bg_color = Color(0.1, 0.1, 0.3, 0.8)
	chip.border_color = Color("4b4fa8")
	chip.set_border_width_all(3)
	chip.content_margin_left = 26
	chip.content_margin_right = 26
	%MovesChip.add_theme_stylebox_override("panel", chip)
	%Caption.add_theme_color_override("font_color", Color("9aa6e8"))
	GameStyle.apply_title_look(_moves_value, Color.WHITE, 8)
	var bar := GameStyle.plate_box()
	bar.bg_color = Color("2e2470")
	bar.border_color = Color("5a3fc0")
	bar.set_corner_radius_all(44)
	bar.content_margin_left = 36
	bar.content_margin_right = 36
	bar.content_margin_top = 18
	bar.content_margin_bottom = 18
	%BoosterBar.add_theme_stylebox_override("panel", bar)
	(_extra_button as BoosterButton).icon_kind = "plus"


## Pausa (engrenagem): continuar, recomeçar ou voltar ao menu.
func _open_pause() -> void:
	if busy:
		return
	dialog.open("Pausa", "", [
		["Continuar jogando", func() -> void: pass, true],
		["Recomeçar", _on_restart_pressed],
		["Menu", func() -> void: back_requested.emit()],
	])


## Abre um desafio do dia e começa uma tentativa nova.
## (Quem chama decide se a tentativa precisa de propaganda; veja main.gd.)
func open_challenge(date: String, index: int) -> void:
	if _show_if_closed(date):
		return  # o dia virou (ex.: durante a propaganda): não abre nem gasta tentativa
	var data := ChallengeGenerator.generate(date, index)
	if data.is_empty():
		# o gerador falhou: volta ao menu sem gastar a tentativa
		back_requested.emit()
		return
	open_with(data)
	GameState.start_attempt(key())


## Abre um nível do modo por níveis (sem tentativas contadas).
func open_level(level: int) -> void:
	var data := LevelGenerator.generate(level)
	if data.is_empty():
		back_requested.emit()
		return
	open_with(data)


## A partida aberta é este nível, ainda sem terminar (dá para continuar de onde parou).
func can_resume_level(level: int) -> bool:
	return is_level() and challenge.level == level and not _finished and puzzle != null


func is_level() -> bool:
	return challenge.get("mode", "daily") == "level"


## Monta a tela com um desafio já pronto (usado também pelos testes).
func open_with(data: Dictionary) -> void:
	if _pour_tween and _pour_tween.is_valid():
		_pour_tween.kill()  # um despejo da partida anterior não pode mexer na nova
	challenge = data
	puzzle = SortPuzzle.new(data.tubes, data.get("hidden", false), data.get("covers", []))
	move_limit = data.par
	selected = -1
	busy = false
	_finished = false
	_zero_accepted = false
	_shown_points = -1
	dialog.close()
	_build_bottles()
	_refresh()


func key() -> String:
	if is_level():
		return LevelGenerator.key_for(challenge.level)
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
	if puzzle.is_covered(i):
		_bottles[i].shake()  # coberta: só abre ao completar a cor do selo
		selected = -1
		_refresh()
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
	src.stream_color = GameStyle.liquid_color(color)
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
	elif current_points() == 0 and not _zero_accepted:
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
		_bottles[i].cover_key = SortPuzzle.cover_color(puzzle.covers[i])
		_bottles[i].set_covered(puzzle.is_covered(i), animate)
	var used: int = puzzle.moves_used()
	_moves_value.text = "%d / %d" % [used, move_limit]
	_moves_value.add_theme_color_override("font_color", Color("ff7a8a") if used > challenge.par else Color.WHITE)
	_show_points(current_points())
	if is_level():
		_challenge_value.text = tr("Nível %d") % challenge.level
	else:
		_challenge_value.text = tr("Desafio %d / %d") % [challenge.get("index", 0) + 1, Rules.DAILY_COUNT]
	var diff: String = challenge.difficulty
	_subtitle.text = tr("%s · vale %d pontos") % [tr(Rules.DIFFICULTY_NAMES[diff]), challenge.full_points]
	_extra_button.disabled = not out_of_moves()


## Placar ao vivo: quando passa do número exato de jogadas, cada jogada a mais tira 1 ponto
## na hora; o placar fica vermelho, dá um pulinho e sobe um "-1".
func _show_points(points: int) -> void:
	var dropped := _shown_points >= 0 and points < _shown_points
	var lost := _shown_points - points
	_shown_points = points
	_points_value.text = str(points)
	var over: bool = puzzle.moves_used() > int(challenge.par)
	_points_value.add_theme_color_override("font_color", POINTS_OVER_COLOR if over else POINTS_COLOR)
	if not dropped or not animate or not is_inside_tree():
		return
	var pill: Control = %PointsPill
	pill.pivot_offset = pill.size * 0.5
	var t := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(pill, "scale", Vector2(1.15, 1.15), 0.1)
	t.tween_property(pill, "scale", Vector2.ONE, 0.2)
	var minus := GameStyle.make_title("-%d" % lost, 44, Color("ff5a6e"))
	minus.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	add_child(minus)
	minus.position = pill.global_position - global_position + Vector2(pill.size.x - 30, pill.size.y - 10)
	var f := create_tween().set_parallel()
	f.tween_property(minus, "position:y", minus.position.y + 70, 0.8)
	f.tween_property(minus, "modulate:a", 0.0, 0.8).set_delay(0.3)
	f.chain().tween_callback(minus.queue_free)


# ---------- botões e avisos ----------

func _on_restart_pressed() -> void:
	if busy:
		return
	var text := "Recomeçar pede uma propaganda." if is_level() else "Cada nova tentativa pede uma propaganda.\nVale sempre o seu melhor resultado."
	dialog.open("Recomeçar?", tr(text), [
		["Assistir e recomeçar", _restart_with_ad, true],
		["Continuar jogando", func() -> void: pass],
	])


func _restart_with_ad() -> void:
	if is_level():
		var level: int = challenge.level
		Ads.show_rewarded(func() -> void: open_level(level))
		return
	if _show_if_closed(challenge.date):
		return  # não pede propaganda para um desafio que já encerrou
	Ads.show_rewarded(func() -> void: open_challenge(challenge.date, challenge.index))


func _on_extra_moves_pressed() -> void:
	Ads.show_rewarded(func() -> void:
		move_limit += Rules.EXTRA_MOVES
		_refresh())


func _show_out_of_moves() -> void:
	dialog.open("Acabaram as jogadas", tr("Assista a uma propaganda para ganhar +%d jogadas.\nCada jogada além de %d tira 1 ponto.") % [Rules.EXTRA_MOVES, challenge.par], [
		[tr("+%d jogadas") % Rules.EXTRA_MOVES, _on_extra_moves_pressed, true],
		["Recomeçar", _restart_with_ad],
		["Menu", func() -> void: back_requested.emit()],
	])


func _show_zero_points() -> void:
	if is_level():
		# nos níveis dá para terminar sem pontos e seguir em frente
		dialog.open("Pontuação zerada", "Assista a uma propaganda para recomeçar este nível, ou termine sem pontos.", [
			["Recomeçar", _restart_with_ad, true],
			["Continuar sem pontos", func() -> void: _zero_accepted = true],
			["Menu", func() -> void: back_requested.emit()],
		])
		return
	dialog.open("Pontuação zerada", "Assista a uma propaganda para recomeçar este desafio.", [
		["Recomeçar", _restart_with_ad, true],
		["Menu", func() -> void: back_requested.emit()],
	])


## Só os desafios de hoje podem ser jogados. Se o desafio é de outro dia, avisa e devolve true.
func _show_if_closed(date: String) -> bool:
	if date == GameState.today():
		return false
	dialog.open("Desafio encerrado", tr("Este desafio era de %s. Agora só valem os desafios de hoje.") % Rules.pretty_date(date), [
		["Ver desafios de hoje", func() -> void: back_requested.emit(), true],
	])
	return true


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
	if is_level():
		GameState.complete_level(challenge.level, points, used)
		var level_text := tr("+%d pontos em %d jogadas.") % [points, used]
		if points < challenge.full_points:
			level_text += tr("\nDava para fazer em %d jogadas.") % challenge.par
		_celebrate()
		dialog.open(win_title(points, challenge.full_points), level_text, [
			["Próximo nível", func() -> void: next_level_requested.emit(), true],
			["Menu", func() -> void: back_requested.emit()],
		])
		return
	var improved := GameState.save_result(key(), points, used)
	var best: Dictionary = GameState.result(key())
	var text := tr("+%d pontos em %d jogadas.") % [points, used]
	if not improved:
		text += tr("\nSeu melhor continua %d pontos.") % best.best_points
	elif points < challenge.full_points:
		text += tr("\nDava para fazer em %d jogadas.") % challenge.par
	var buttons: Array = []
	var next_index := next_unsolved_after(challenge.date, challenge.index)
	if next_index >= 0:
		buttons.append(["Próximo desafio", func() -> void: next_requested.emit(challenge.date, next_index), true])
	if points < challenge.full_points:
		buttons.append(["Tentar melhorar", _restart_with_ad])
	buttons.append(["Menu", func() -> void: back_requested.emit()])
	_celebrate()
	dialog.open(win_title(points, challenge.full_points), text, buttons)


## "Perfeito!" com a pontuação cheia; senão "Muito bem!".
static func win_title(points: int, full_points: int) -> String:
	return "Perfeito!" if points >= full_points else "Muito bem!"


## Confete colorido caindo do alto da tela.
func _celebrate() -> void:
	if not animate or not is_inside_tree():
		return
	var p := CPUParticles2D.new()
	p.position = Vector2(size.x * 0.5, -20)
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(size.x * 0.5, 10)
	p.amount = 90
	p.lifetime = 2.6
	p.one_shot = true
	p.explosiveness = 0.85
	p.direction = Vector2(0, 1)
	p.spread = 25
	p.initial_velocity_min = 260
	p.initial_velocity_max = 520
	p.gravity = Vector2(0, 420)
	p.angular_velocity_min = -360
	p.angular_velocity_max = 360
	p.scale_amount_min = 8
	p.scale_amount_max = 16
	var ramp := Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 0.2, 0.4, 0.6, 0.8, 1.0])
	ramp.colors = PackedColorArray([GameStyle.LIQUIDS[0], GameStyle.LIQUIDS[1], GameStyle.LIQUIDS[2], GameStyle.LIQUIDS[3], GameStyle.LIQUIDS[4], GameStyle.LIQUIDS[5]])
	p.color_initial_ramp = ramp
	p.z_index = 50
	add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)
