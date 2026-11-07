extends Node
## Progresso do jogador neste aparelho: tentativas e melhor resultado de cada desafio.
## Disponível em qualquer script como `GameState`. (O servidor passa a valer na etapa de contas.)

signal progress_changed

var save_path: String = "user://progress.cfg"
## Para testes: fixa o "agora" (segundos Unix). -1 = relógio de verdade.
var fixed_unix: int = -1

var _cfg := ConfigFile.new()


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


func reset_all() -> void:
	_cfg = ConfigFile.new()
	_save()


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
		_save()
	return better


## Soma do mês ("AAAA-MM"): pontos, movimentos (desempate) e desafios resolvidos.
func month_total(month_key: String) -> Dictionary:
	var points := 0
	var moves := 0
	var completed := 0
	for key in _cfg.get_sections():
		if not key.begins_with(month_key) or not is_completed(key):
			continue
		points += int(_cfg.get_value(key, "best_points"))
		moves += int(_cfg.get_value(key, "best_moves"))
		completed += 1
	return {"points": points, "moves": moves, "completed": completed}


func _save() -> void:
	_cfg.save(save_path)
	progress_changed.emit()
