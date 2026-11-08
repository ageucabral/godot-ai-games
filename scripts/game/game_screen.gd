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
@onready var _shuffle_button: BoosterButton = %ShuffleButton
@onready var _bottle_button: BoosterButton = %BottleButton

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
## Pontos tirados pelas ajudas usadas nesta tentativa: cada uma pede propaganda e tira `boost_cost` (Ageu, 7/11/2026).
var _penalty: int = 0
var shuffles_left: int = 0
var bottles_left: int = 0
## Pontos mostrados no placar (para perceber quando caem e animar o "-1").
var _shown_points: int = -1
## Regras desta partida (no servidor, as gravadas quando ela começou; valores do painel).
var boost_cost: int = Rules.BOOST_COST
var extra_moves: int = Rules.EXTRA_MOVES


func _ready() -> void:
	theme = GameStyle.build_theme()
	var bg := GameStyle.add_background(self, "night")
	move_child(bg, 0)
	_style_hud()
	dialog = DialogBox.new()
	add_child(dialog)
	_menu_button.pressed.connect(_open_pause)
	_restart_button.pressed.connect(_on_restart_pressed)
	_shuffle_button.pressed.connect(_on_shuffle_pressed)
	_bottle_button.pressed.connect(_on_bottle_pressed)


func _style_hud() -> void:
	# placar único da fase: moeda + pontos que ela ainda vale (caem ao vivo depois do número exato)
	var pill := GameStyle.pill_box()
	pill.content_margin_left = 10
	pill.content_margin_right = 26
	pill.border_color = GameStyle.GOLD.darkened(0.2)
	pill.set_border_width_all(4)
	%PointsPill.add_theme_stylebox_override("panel", pill)
	(%PointsPill.get_node("Row/Coin") as CoinIcon).radius = 28.0
	(%PointsPill.get_node("Row/Coin") as CoinIcon).custom_minimum_size = Vector2(62, 64)
	_points_value.add_theme_font_override("font", GameStyle.title_font())
	_points_value.add_theme_color_override("font_color", POINTS_COLOR)
	%PointsCaption.add_theme_color_override("font_color", Color("a0743a"))
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
	_shuffle_button.icon_kind = "shuffle"
	_bottle_button.icon_kind = "bottle"


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
## (Quem chama decide se a tentativa precisa de propaganda; veja main.gd. Pelo servidor, a partir da
## 2ª tentativa vai junto o `reward_id` da propaganda assistida.)
func open_challenge(date: String, index: int, reward_id: String = "") -> void:
	if _show_if_closed(date):
		return  # o dia virou (ex.: durante a propaganda): não abre nem gasta tentativa
	if Server.online():
		var body := {"mode": "daily", "index": index}
		if not reward_id.is_empty():
			body["rewardId"] = reward_id
		if await _open_online(body):
			GameState.start_attempt(key())
		return
	var data := ChallengeGenerator.generate(date, index)
	if data.is_empty():
		# o gerador falhou: volta ao menu sem gastar a tentativa
		back_requested.emit()
		return
	open_with(data)
	GameState.start_attempt(key())


## Abre um nível do modo por níveis (sem tentativas contadas).
func open_level(level: int) -> void:
	if Server.online():
		await _open_online({"mode": "level"})  # o servidor sabe qual é o nível do jogador
		return
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


## Esta partida foi aberta pelo servidor (ele confere as jogadas e dá os pontos).
func is_online() -> bool:
	return not str(challenge.get("match_id", "")).is_empty()


## Pede a partida ao servidor. Sem resposta, avisa e volta ao menu. Devolve true se abriu.
func _open_online(body: Dictionary) -> bool:
	busy = true
	dialog.open("Carregando…", "", [])
	var res: Dictionary
	if body.has("rewardId"):
		res = await Server.call_with_reward("POST", "/pocao/matches", body)
	else:
		res = await Server.call_api("POST", "/pocao/matches", body)
	busy = false
	if not res.ok:
		if res.get("code", "") == "NETWORK":
			dialog.open("Sem conexão", tr(ApiClient.error_text(res)), [
				["Tentar de novo", func() -> void: _open_online(body), true],
				["Menu", func() -> void: back_requested.emit()],
			])
		else:
			_show_server_error(res, true)
		return false
	open_with(ApiClient.challenge_from_match(res.data.get("match", {})))
	return true


## Erro do servidor: recado curto. `leave` = só dá para voltar ao menu.
func _show_server_error(res: Dictionary, leave: bool = false) -> void:
	var title := "Sem conexão" if res.get("code", "") == "NETWORK" else "Ops!"
	var buttons: Array = [["Menu", func() -> void: back_requested.emit(), true]]
	if not leave:
		buttons = [["Continuar jogando", func() -> void: pass, true], buttons[0]]
	dialog.open(title, tr(ApiClient.error_text(res)), buttons)


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
	_penalty = 0
	var params: Dictionary = data.get("params", {})
	shuffles_left = int(params.get("shuffles", Rules.SHUFFLES_PER_STAGE))
	bottles_left = int(params.get("flasks", Rules.EXTRA_BOTTLES_PER_STAGE))
	boost_cost = int(params.get("boost_cost", Rules.BOOST_COST))
	extra_moves = int(params.get("extra_moves", Rules.EXTRA_MOVES))
	dialog.close()
	_build_bottles()
	_refresh()


func key() -> String:
	if not str(challenge.get("key", "")).is_empty():
		return challenge.key
	if is_level():
		return LevelGenerator.key_for(challenge.level)
	return ChallengeGenerator.key_for(challenge.get("date", ""), challenge.get("index", 0))


func current_points() -> int:
	return maxi(0, Rules.score_for(challenge.full_points, challenge.par, puzzle.moves_used()) - _penalty)


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
	# a dificuldade só aparece nos desafios do dia (nos níveis, o número do nível já diz tudo)
	_subtitle.visible = not is_level()
	_subtitle.text = tr(Rules.DIFFICULTY_NAMES[challenge.difficulty])
	_shuffle_button.badge = str(shuffles_left)
	var boost_ok: bool = not _finished and can_use_boost()
	_shuffle_button.disabled = shuffles_left <= 0 or not boost_ok
	_bottle_button.badge = str(bottles_left)
	_bottle_button.disabled = bottles_left <= 0 or not boost_ok


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
	if is_online():
		_retry_daily_online()
		return
	Ads.show_rewarded(func() -> void: open_challenge(challenge.date, challenge.index))


## Nova tentativa de um desafio pelo servidor: a propaganda vira um `rewardId` conferido por ele.
func _retry_daily_online() -> void:
	var date: String = challenge.date
	var index: int = challenge.index
	busy = true
	var reward_id: String = await Server.rewarded("retry", {"mode": key()})
	busy = false
	if reward_id.is_empty():
		_show_server_error({"code": "REWARD_NOT_VERIFIED"})
		return
	open_challenge(date, index, reward_id)


## Embaralhar: mistura de novo o líquido das garrafas abertas (sempre com solução).
## Pede propaganda e tira `boost_cost` ponto(s). Até Rules.SHUFFLES_PER_STAGE vezes por fase.
func _on_shuffle_pressed() -> void:
	if busy or _finished or shuffles_left <= 0 or not can_use_boost():
		return
	var action: Callable
	if is_online():
		# o servidor sorteia o embaralhado
		action = func() -> void: _boost_online("shuffle")
	else:
		# calcula o embaralhado ANTES da propaganda: se não der, o jogador não assiste à toa
		var rng := RandomNumberGenerator.new()
		rng.randomize()
		var mixed: Array = puzzle.shuffled_state(rng)
		if mixed.is_empty():
			dialog.open("Embaralhar", "Não deu para embaralhar agora. Nada foi cobrado.", [["Fechar", func() -> void: pass, true]])
			return
		var at: int = puzzle.moves_used()
		action = func() -> void: Ads.show_rewarded(func() -> void: apply_shuffle(mixed, at))
	dialog.open("Embaralhar?", tr("Mistura de novo as cores das garrafas abertas.\nPede uma propaganda e custa %s.") % boost_cost_text(), [
		["Assistir e embaralhar", action, true],
		["Voltar", func() -> void: pass],
	])


## Frasco extra: uma garrafa vazia a mais. Pede propaganda e tira `boost_cost` ponto(s). 1 por fase.
func _on_bottle_pressed() -> void:
	if busy or _finished or bottles_left <= 0 or not can_use_boost():
		return
	dialog.open("Frasco extra?", tr("Ganha uma garrafa vazia a mais.\nPede uma propaganda e custa %s.") % boost_cost_text(), [
		["Assistir e ganhar", func() -> void:
			if is_online():
				_boost_online("flask")
			else:
				Ads.show_rewarded(apply_extra_bottle), true],
		["Voltar", func() -> void: pass],
	])


## Aplica um embaralhado calculado antes da propaganda (`at` = jogadas feitas naquele momento:
## se a partida mudou nesse meio-tempo, não aplica).
func apply_shuffle(mixed: Array, at: int) -> void:
	if _finished or shuffles_left <= 0 or puzzle.moves_used() != at:
		return
	puzzle.apply_shuffled(mixed)
	shuffles_left -= 1
	_use_boost()


func apply_extra_bottle() -> void:
	if _finished or bottles_left <= 0:
		return
	puzzle.add_empty_tube()
	bottles_left -= 1
	_build_bottles()
	_use_boost()


## Quanto cada ajuda custa, em texto ("1 ponto", "2 pontos"): no servidor vem das regras da partida.
func boost_cost_text() -> String:
	return tr("1 ponto") if boost_cost == 1 else tr("%d pontos") % boost_cost


## Nos desafios do dia, uma ajuda que zeraria os pontos obrigaria a recomeçar: não deixa usar.
## (Nos níveis dá para seguir sem pontos.)
func can_use_boost() -> bool:
	return is_level() or current_points() > boost_cost


## Ajuda pelo servidor: propaganda conferida → o servidor confere as jogadas até aqui, aplica a ajuda
## e devolve o estado novo. kind = "shuffle" | "flask" | "moves".
func _boost_online(kind: String) -> void:
	if busy or _finished:
		return
	busy = true
	var at: int = puzzle.moves_used()
	var reward_id: String = await Server.rewarded(kind, {"matchId": challenge.match_id})
	if reward_id.is_empty():
		busy = false
		_show_server_error({"code": "REWARD_NOT_VERIFIED"})
		return
	var body := {"kind": kind, "rewardId": reward_id, "moves": puzzle.moves.duplicate(true)}
	var res: Dictionary = await Server.call_with_reward("POST", "/pocao/matches/%s/boost" % challenge.match_id, body)
	busy = false
	if not res.ok:
		_show_server_error(res, res.code in ["MOVES_DIVERGED", "INVALID_MOVES", "MATCH_ENDED", "CHALLENGE_CLOSED"])
		return
	if _finished or puzzle.moves_used() != at:
		return
	var st := ApiClient.state_from_match(res.data.get("match", {}))
	match kind:
		"shuffle":
			puzzle.apply_shuffled(st.tubes)
			shuffles_left = st.shuffles_left
			_use_boost()
		"flask":
			puzzle.add_empty_tube()
			bottles_left = st.flasks_left
			_build_bottles()
			_use_boost()
		"moves":
			move_limit = st.move_limit
			_refresh()


## Cada ajuda usada tira `boost_cost` ponto(s) da fase.
func _use_boost() -> void:
	_penalty += boost_cost
	selected = -1
	_refresh()
	if current_points() == 0 and not _zero_accepted:
		_show_zero_points()


func _on_extra_moves_pressed() -> void:
	if is_online():
		_boost_online("moves")
		return
	Ads.show_rewarded(func() -> void:
		move_limit += extra_moves
		_refresh())


func _show_out_of_moves() -> void:
	dialog.open("Acabaram as jogadas", tr("Assista a uma propaganda para ganhar +%d jogadas.\nCada jogada além de %d tira 1 ponto.") % [extra_moves, challenge.par], [
		[tr("+%d jogadas") % extra_moves, _on_extra_moves_pressed, true],
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
	if is_online():
		_finish_online()
		return
	var points := current_points()
	var used := puzzle.moves_used()
	if is_level():
		GameState.complete_level(challenge.level, points, used)
		_show_level_win(points, used)
		return
	var improved := GameState.save_result(key(), points, used)
	_show_daily_win(points, used, improved, int(GameState.result(key()).best_points))


## Fim pelo servidor: ele refaz a partida inteira e devolve os pontos que valem. Sem internet, dá
## para tentar de novo (o servidor guarda a partida aberta).
func _finish_online() -> void:
	busy = true
	dialog.open("Conferindo…", "", [])
	var body := ApiClient.finish_body(puzzle.moves.duplicate(true), current_points(), puzzle.is_solved())
	var res: Dictionary = await Server.call_api("POST", "/pocao/matches/%s/finish" % challenge.match_id, body)
	busy = false
	if not res.ok:
		# só vale tentar de novo quando a mensagem nem chegou (ou o servidor falhou); recusas são finais
		if res.code == "NETWORK" or int(res.get("status", 0)) >= 500:
			dialog.open("Sem conexão" if res.code == "NETWORK" else "Ops!", tr(ApiClient.error_text(res)), [
				["Tentar de novo", _finish_online, true],
				["Menu", func() -> void: back_requested.emit()],
			])
		else:
			_show_server_error(res, true)
		return
	var r: Dictionary = res.data
	GameState.apply_server_result(challenge, r)
	if bool(r.get("rejected", false)) or not bool(r.get("solved", false)):
		dialog.open("Partida não conferida", "O servidor não conseguiu conferir esta partida, então ela ficou sem pontos.", [
			["Menu", func() -> void: back_requested.emit(), true],
		])
		return
	var points := int(r.get("points", 0))
	var used := int(r.get("movesUsed", puzzle.moves_used()))
	if is_level():
		_show_level_win(points, used)
		return
	var best: Variant = r.get("best")
	var best_points: int = int(best.points) if best is Dictionary else points
	_show_daily_win(points, used, bool(r.get("newBest", true)), best_points)


func _show_level_win(points: int, used: int) -> void:
	var level_text := tr("+%d pontos em %d jogadas.") % [points, used]
	if points < challenge.full_points:
		level_text += tr("\nDava para fazer em %d jogadas.") % challenge.par
	_celebrate()
	dialog.open(win_title(points, challenge.full_points), level_text, [
		["Próximo nível", func() -> void: next_level_requested.emit(), true],
		["Menu", func() -> void: back_requested.emit()],
	])


func _show_daily_win(points: int, used: int, improved: bool, best_points: int) -> void:
	var text := tr("+%d pontos em %d jogadas.") % [points, used]
	if not improved:
		text += tr("\nSeu melhor continua %d pontos.") % best_points
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
