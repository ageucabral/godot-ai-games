class_name SortPuzzle
extends RefCounted
## Regras do quebra-cabeça de separar cores.
## Cada garrafa é um Array[int] de cores, do fundo (índice 0) para o topo.
## Esta classe não depende da árvore de cenas: dá para testar sozinha.

const CAPACITY: int = 4

var tubes: Array = []
var _history: Array = []  # cada item: [de, para, quantidade]


func _init(start_tubes: Array = []) -> void:
	tubes = copy_tubes(start_tubes)


## Quantas jogadas (despejos) valem neste momento. Desfazer devolve a jogada.
func moves_used() -> int:
	return _history.size()


func can_pour(from: int, to: int) -> bool:
	return can_pour_in(tubes, from, to)


## Despeja do topo de `from` em `to`. Devolve quantas camadas mudaram (0 = jogada inválida).
func pour(from: int, to: int) -> int:
	if not can_pour(from, to):
		return 0
	var amount: int = pour_in(tubes, from, to)
	_history.append([from, to, amount])
	return amount


func can_undo() -> bool:
	return not _history.is_empty()


func undo() -> bool:
	if _history.is_empty():
		return false
	var last: Array = _history.pop_back()
	for i in last[2]:
		tubes[last[0]].append(tubes[last[1]].pop_back())
	return true


func is_solved() -> bool:
	return is_solved_state(tubes)


# ---------- funções estáticas (usadas também pelo resolvedor) ----------

static func copy_tubes(src: Array) -> Array:
	var out: Array = []
	for t in src:
		out.append((t as Array).duplicate())
	return out


## Quantas camadas da mesma cor estão juntas no topo da garrafa.
static func top_run(tube: Array) -> int:
	if tube.is_empty():
		return 0
	var color: int = tube[-1]
	var n: int = 0
	for i in range(tube.size() - 1, -1, -1):
		if tube[i] != color:
			break
		n += 1
	return n


static func can_pour_in(state: Array, from: int, to: int) -> bool:
	if from == to or from < 0 or to < 0 or from >= state.size() or to >= state.size():
		return false
	var a: Array = state[from]
	var b: Array = state[to]
	if a.is_empty() or b.size() >= CAPACITY:
		return false
	return b.is_empty() or b[-1] == a[-1]


## Despeja o máximo que cabe (todas as camadas iguais do topo, se houver espaço).
static func pour_in(state: Array, from: int, to: int) -> int:
	var a: Array = state[from]
	var b: Array = state[to]
	var amount: int = mini(top_run(a), CAPACITY - b.size())
	for i in amount:
		b.append(a.pop_back())
	return amount


static func is_solved_state(state: Array) -> bool:
	for t in state:
		var tube: Array = t
		if tube.is_empty():
			continue
		if tube.size() != CAPACITY or top_run(tube) != CAPACITY:
			return false
	return true


## Menor número de jogadas para resolver (busca em largura).
## Devolve -1 se não houver solução ou se passar de `max_states` estados.
static func min_moves(start: Array, max_states: int = 200000) -> int:
	var first: Array = copy_tubes(start)
	if is_solved_state(first):
		return 0
	var seen: Dictionary = {_key(first): true}
	var frontier: Array = [first]
	var depth: int = 0
	while not frontier.is_empty():
		depth += 1
		var next: Array = []
		for state in frontier:
			for from in state.size():
				var src: Array = state[from]
				if src.is_empty():
					continue
				# garrafa já completa de uma cor: não mexe
				if src.size() == CAPACITY and top_run(src) == CAPACITY:
					continue
				for to in state.size():
					if not can_pour_in(state, from, to):
						continue
					# mover uma garrafa inteira de uma cor para uma vazia não ajuda
					if (state[to] as Array).is_empty() and top_run(src) == src.size():
						continue
					var child: Array = copy_tubes(state)
					pour_in(child, from, to)
					var k: String = _key(child)
					if seen.has(k):
						continue
					if is_solved_state(child):
						return depth
					seen[k] = true
					next.append(child)
					if seen.size() > max_states:
						return -1
		frontier = next
	return -1


## Chave do estado sem ordem de garrafas (garrafas são intercambiáveis).
static func _key(state: Array) -> String:
	var parts: PackedStringArray = []
	for t in state:
		parts.append(",".join((t as Array).map(func(c: int) -> String: return str(c))))
	parts.sort()
	return "|".join(parts)
