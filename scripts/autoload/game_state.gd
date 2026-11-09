extends Node
## Progresso do jogador neste aparelho: nível, tentativas e melhor resultado de cada desafio.
## Disponível em qualquer script como `GameState`. Jogando pelo servidor (Android), as telas continuam
## lendo daqui: `apply_server_home` e `apply_server_result` copiam o que o servidor conferiu.

signal progress_changed

var save_path: String = "user://progress.cfg"
## Para testes: fixa o "agora" (segundos Unix). -1 = relógio de verdade.
var fixed_unix: int = -1

var _cfg := ConfigFile.new()
## Pontos e posição do mês vindos do servidor (Server.refresh_home): {id, game_points, game_position,
## global_points, global_position}. Vazio = jogando só no aparelho.
var server_month: Dictionary = {}
## Conta os resultados do servidor guardados (um menu que chega depois de um resultado é descartado).
var server_result_seq: int = 0
## Extras do GET /pocao/home (sequência, conquistas, frascos, evento, duelos). Vazio = jogando só no aparelho.
var extras: Dictionary = {}


const PLAYER := "player"
## Jogos do hub que somam pontos. O ranking global (o que vale prêmio) soma todos eles.
const GAME_IDS: Array[String] = ["potion"]


func _ready() -> void:
	load_progress()


func now_unix() -> int:
	return fixed_unix if fixed_unix >= 0 else int(Time.get_unix_time_from_system())


func today() -> String:
	return Rules.date_for(now_unix())


func load_progress() -> void:
	_cfg = ConfigFile.new()
	if FileAccess.file_exists(save_path):
		_cfg.load(save_path)
	I18n.apply(language())


func reset_all() -> void:
	_cfg = ConfigFile.new()
	server_month = {}
	extras = {}
	I18n.apply(language())
	_save()


## Apaga o progresso deste aparelho (conta apagada), mas guarda as escolhas (idioma, som).
func reset_progress() -> void:
	var keep := {}
	for key in ["language", "sound", "music", "reminders"]:
		if _cfg.has_section_key(PLAYER, key):
			keep[key] = _cfg.get_value(PLAYER, key)
	_cfg = ConfigFile.new()
	for key in keep:
		_cfg.set_value(PLAYER, key, keep[key])
	server_month = {}
	extras = {}
	_save()


## Escolha simples guardada no aparelho (ex.: "sound", "tutorial_done").
func get_setting(key: String, default: Variant) -> Variant:
	return _cfg.get_value(PLAYER, key, default)


func set_setting(key: String, value: Variant) -> void:
	_cfg.set_value(PLAYER, key, value)
	_save()


# ---------- idioma ----------

func language() -> String:
	return _cfg.get_value(PLAYER, "language", I18n.DEFAULT)


func set_language(code: String) -> void:
	_cfg.set_value(PLAYER, "language", code if I18n.is_supported(code) else I18n.DEFAULT)
	I18n.apply(language())
	_save()


# ---------- modo por níveis ----------

## Próximo nível a jogar (começa no 1 e nunca acaba).
func current_level() -> int:
	return _cfg.get_value(PLAYER, "level", 1)


## Guarda o nível resolvido (vale para o ranking do mês em que foi resolvido), as estrelas e libera o próximo.
## Só conta uma vez: resolver de novo um nível que já passou não muda nada.
func complete_level(level: int, points: int, moves: int, par: int = 0) -> void:
	if level != current_level():
		return
	var key := LevelGenerator.key_for(level)
	_cfg.set_value(key, "best_points", points)
	_cfg.set_value(key, "best_moves", moves)
	_cfg.set_value(key, "month", Rules.month_for(now_unix()))
	if par > 0:
		_cfg.set_value(key, "stars", Rules.stars_for(moves, par))
	_cfg.set_value(PLAYER, "level", level + 1)
	note_played()
	_save()


## Estrelas de um nível já resolvido (0 = ainda não).
func level_stars(level: int) -> int:
	return int(_cfg.get_value(LevelGenerator.key_for(level), "stars", 0))


# ---------- sequência de dias, frascos e fundos ----------

## Resolveu uma fase hoje: a sequência de dias (neste aparelho) soma 1 no primeiro acerto do dia.
func note_played() -> void:
	var last: String = _cfg.get_value(PLAYER, "streak_last", "")
	var count := Rules.next_streak(last, int(_cfg.get_value(PLAYER, "streak", 0)), today())
	_cfg.set_value(PLAYER, "streak", count)
	_cfg.set_value(PLAYER, "streak_last", today())
	_cfg.set_value(PLAYER, "streak_best", maxi(count, int(_cfg.get_value(PLAYER, "streak_best", 0))))


## Sequência de dias que vale hoje: {count, best, played_today, free_boosts}. Pelo servidor, a dele.
func streak() -> Dictionary:
	var s: Variant = extras.get("streak")
	if s is Dictionary:
		return {"count": int(s.get("count", 0)), "best": int(s.get("best", 0)), "played_today": bool(s.get("playedToday", false)),
			"free_boosts": int(s.get("freeBoosts", 0))}
	var last: String = _cfg.get_value(PLAYER, "streak_last", "")
	return {"count": Rules.live_streak(last, int(_cfg.get_value(PLAYER, "streak", 0)), today()),
		"best": int(_cfg.get_value(PLAYER, "streak_best", 0)), "played_today": last == today(), "free_boosts": 0}


## Gastou uma ajuda grátis (o servidor já descontou; aqui só atualiza a tela até o próximo menu).
func use_free_boost() -> void:
	var s: Variant = extras.get("streak")
	if s is Dictionary:
		s["freeBoosts"] = maxi(0, int(s.get("freeBoosts", 0)) - 1)


## Frasco e fundo escolhidos e os liberados ({skin, bg, skins, backgrounds}). Sem servidor, só os de sempre.
func looks() -> Dictionary:
	var l: Variant = extras.get("looks")
	if l is Dictionary:
		return l
	return {"skin": "classic", "bg": "night", "skins": ["classic"], "backgrounds": ["night"]}


func attempts(key: String) -> int:
	return _cfg.get_value(key, "attempts", 0)


## Começa uma tentativa nova do desafio. Devolve o número da tentativa (1 = a grátis).
func start_attempt(key: String) -> int:
	var n := attempts(key) + 1
	_cfg.set_value(key, "attempts", n)
	_save()
	return n


func is_completed(key: String) -> bool:
	return _cfg.get_value(key, "best_points", -1) >= 0


## {completed, best_points, best_moves, attempts}
func result(key: String) -> Dictionary:
	return {
		"completed": is_completed(key),
		"best_points": _cfg.get_value(key, "best_points", -1),
		"best_moves": _cfg.get_value(key, "best_moves", 0),
		"attempts": attempts(key),
	}


## Guarda um desafio resolvido. Vale sempre o melhor resultado
## (mais pontos; no empate, menos movimentos). Devolve true se melhorou.
func save_result(key: String, points: int, moves: int) -> bool:
	var best: int = _cfg.get_value(key, "best_points", -1)
	var best_moves: int = _cfg.get_value(key, "best_moves", 0)
	var better := points > best or (points == best and moves < best_moves)
	if better:
		_cfg.set_value(key, "best_points", points)
		_cfg.set_value(key, "best_moves", moves)
		note_played()
		_save()
	return better


## Soma do mês ("AAAA-MM"): pontos, movimentos (desempate), desafios e níveis resolvidos.
func month_total(month_key: String) -> Dictionary:
	var points := 0
	var moves := 0
	var completed := 0
	var levels := 0
	for key in _cfg.get_sections():
		if not is_completed(key):
			continue
		if key.begins_with(month_key):
			completed += 1
		elif key.begins_with("nivel#") and _cfg.get_value(key, "month", "") == month_key:
			levels += 1
		else:
			continue
		points += int(_cfg.get_value(key, "best_points"))
		moves += int(_cfg.get_value(key, "best_moves"))
	return {"points": points, "moves": moves, "completed": completed, "levels": levels}


## Pontos do mês num jogo só (ranking daquele jogo). Por enquanto todo o progresso é do Poção de Cores.
## Jogando pelo servidor, os pontos são os do servidor (é ele que confere as partidas).
func game_month_total(game_id: String, month_key: String) -> Dictionary:
	if game_id != "potion":
		return {"points": 0, "moves": 0, "completed": 0, "levels": 0}
	var t := month_total(month_key)
	if server_month.get("id", "") == month_key:
		t.points = int(server_month.game_points)
		t["position"] = server_month.game_position
	return t


## Ranking global do mês: soma os pontos e as jogadas de todos os jogos do hub.
func global_month_total(month_key: String) -> Dictionary:
	var points := 0
	var moves := 0
	var games := {}
	for id in GAME_IDS:
		var t := game_month_total(id, month_key)
		points += int(t.points)
		moves += int(t.moves)
		games[id] = int(t.points)
	var out := {"points": points, "moves": moves, "games": games}
	if server_month.get("id", "") == month_key:
		# o Ranking Global do servidor soma também os jogos do app antigo
		out.points = int(server_month.global_points)
		out["position"] = server_month.global_position
	return out


# ---------- servidor ----------

## Copia o que o servidor mandou (GET /pocao/home): nível atual, tentativas e melhor resultado dos
## desafios de hoje e os pontos do mês. Assim as telas continuam lendo tudo daqui.
func apply_server_home(home: Dictionary) -> void:
	var level: Dictionary = home.get("level", {})
	if level.has("number"):
		_cfg.set_value(PLAYER, "level", int(level.number))
	var date: String = str(home.get("date", ""))
	for d in home.get("daily", []):
		var key := ChallengeGenerator.key_for(date, int(d.get("index", 0)))
		_cfg.set_value(key, "attempts", int(d.get("attempts", 0)))
		var solved := bool(d.get("solved", false)) and d.get("bestPoints") != null
		_cfg.set_value(key, "best_points", int(d.bestPoints) if solved else -1)
		_cfg.set_value(key, "best_moves", int(d.bestMoves) if solved and d.get("bestMoves") != null else 0)
	for st in home.get("stars", []):
		if st is Dictionary:
			_cfg.set_value(LevelGenerator.key_for(int(st.get("level", 0))), "stars", int(st.get("stars", 0)))
	extras = {}
	for k in ["streak", "achievements", "looks", "event", "duels"]:
		if home.get(k) != null:
			extras[k] = home[k]
	var month: Dictionary = home.get("month", {})
	if month.has("id"):
		server_month = {
			"id": str(month.id),
			"game_points": int(month.get("gamePoints", 0)),
			"game_position": month.get("gamePosition"),
			"global_points": int(month.get("globalPoints", 0)),
			"global_position": month.get("globalPosition"),
		}
	_save()


## Resultado conferido pelo servidor (fim da partida): guarda no aparelho para as telas.
func apply_server_result(challenge: Dictionary, result: Dictionary) -> void:
	server_result_seq += 1
	if not bool(result.get("solved", false)) or bool(result.get("rejected", false)):
		return
	var points := int(result.get("points", 0))
	var moves := int(result.get("movesUsed", 0))
	var more: Variant = result.get("extras")
	if more is Dictionary and extras.get("streak") is Dictionary:
		# a sequência e as ajudas grátis mudam na hora (o menu do servidor confirma depois)
		extras.streak["count"] = int(more.get("streak", extras.streak.get("count", 0)))
		extras.streak["playedToday"] = true
		extras.streak["freeBoosts"] = int(extras.streak.get("freeBoosts", 0)) + int(more.get("freeBoostsGained", 0))
	var mode: String = challenge.get("mode", "")
	var ev: Variant = extras.get("event")
	if mode == "event" and ev is Dictionary and int(challenge.get("event_n", 0)) == int(ev.get("done", 0)) + 1:
		ev["done"] = int(challenge.event_n)  # a fase do evento contou: o botão do menu já mostra a próxima
	if mode == "level":
		complete_level(int(challenge.level), points, moves, int(challenge.get("par", 0)))
		if result.get("nextLevel") != null:
			_cfg.set_value(PLAYER, "level", int(result.nextLevel))
	elif mode not in ["event", "duel"]:  # evento e duelo não mexem no nível nem nos desafios do dia
		var key := ChallengeGenerator.key_for(str(challenge.get("date", "")), int(challenge.get("index", 0)))
		var best: Variant = result.get("best")
		if best is Dictionary:
			_cfg.set_value(key, "best_points", int(best.points))
			_cfg.set_value(key, "best_moves", int(best.moves))
		else:
			save_result(key, points, moves)
	if server_month.has("id") and result.get("gamePoints") != null:
		server_month.game_points = int(result.gamePoints)
		server_month.game_position = result.get("gamePosition")
	_save()


func _save() -> void:
	_cfg.save(save_path)
	progress_changed.emit()
