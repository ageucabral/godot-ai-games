class_name SortPuzzle
extends RefCounted
## Regras do quebra-cabeça de separar cores.
## Cada garrafa é um Array de cores (números), do fundo (índice 0) para o topo.
## `hidden` guarda, para cada camada, se ela ainda aparece como "?" (desafios difíceis).
## `covers` guarda, para cada garrafa, se ela está coberta por um pano (Ageu, 7/11/2026):
##   -1 = descoberta desde o começo; c >= 0 = coberta, abre quando uma garrafa da cor c ficar completa;
##   -(c + 2) = era coberta pela cor c e já abriu. Garrafa coberta não dá nem recebe líquido.
##   Com duas garrafas cobertas pela mesma cor, a primeira abre na 1ª garrafa completa dessa cor
##   e a segunda só na 2ª (por isso existem cores repetidas, com 8 camadas).
## Esta classe não depende da árvore de cenas: dá para testar sozinha.

const CAPACITY: int = 4

var tubes: Array = []
var hidden: Array = []
var covers: Array = []
## Garrafas que abriram na última jogada (a tela confere `is_covered`; isto ajuda os testes).
var last_revealed: Array = []
## Lista de jogadas feitas, cada uma [de, para]. Vai para o servidor conferir no futuro.
var moves: Array = []


func _init(start_tubes: Array = [], hide_lower_layers: bool = false, start_covers: Array = []) -> void:
	tubes = copy_tubes(start_tubes)
	covers = normalized_covers(start_covers, tubes.size())
	for t in tubes:
		var flags: Array = []
		for i in (t as Array).size():
			flags.append(hide_lower_layers and i < (t as Array).size() - 1)
		hidden.append(flags)


## Quantas jogadas (despejos) já foram feitas nesta tentativa.
func moves_used() -> int:
	return moves.size()


func can_pour(from: int, to: int) -> bool:
	return can_pour_in(tubes, from, to, covers)


func is_covered(i: int) -> bool:
	return is_covered_in(covers, i)


## Despeja do topo de `from` em `to`. Devolve quantas camadas mudaram (0 = jogada inválida).
func pour(from: int, to: int) -> int:
	if not can_pour(from, to):
		return 0
	var amount: int = pour_in(tubes, from, to)
	for i in amount:
		hidden[from].pop_back()
		hidden[to].append(false)
	if not (hidden[from] as Array).is_empty():
		hidden[from][-1] = false  # a camada que ficou no topo aparece
	moves.append([from, to])
	last_revealed = reveal_in(tubes, covers)
	return amount


## Frasco extra: uma garrafa vazia a mais, no fim da fila.
func add_empty_tube() -> void:
	tubes.append([])
	hidden.append([])
	covers.append(-1)


## Embaralhar: mistura as camadas das garrafas abertas que ainda não estão completas, mantendo
## quanto cada uma tem. Só aceita um embaralhado diferente e com solução. Devolve false se não achou.
func shuffle(rng: RandomNumberGenerator, tries: int = 10) -> bool:
	var spots: Array = []
	var pool: Array = []
	for i in tubes.size():
		if is_covered(i) or is_complete(tubes[i]):
			continue
		for j in (tubes[i] as Array).size():
			spots.append([i, j])
			pool.append(tubes[i][j])
	if pool.size() < 2:
		return false
	for _t in tries:
		var mixed: Array = pool.duplicate()
		for k in range(mixed.size() - 1, 0, -1):
			var r := rng.randi_range(0, k)
			var tmp = mixed[k]
			mixed[k] = mixed[r]
			mixed[r] = tmp
		if mixed == pool:
			continue
		var candidate: Array = copy_tubes(tubes)
		for n in spots.size():
			candidate[spots[n][0]][spots[n][1]] = mixed[n]
		if is_solved_state(candidate):
			continue
		if min_moves(candidate, 150000, covers) < 0:
			continue
		tubes = candidate
		return true
	return false


func is_solved() -> bool:
	return is_solved_state(tubes)


# ---------- funções estáticas (usadas também pelo gerador e pelo resolvedor) ----------

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


## Uma entrada de `covers` por garrafa (-1 onde faltar).
static func normalized_covers(src: Array, count: int) -> Array:
	var out: Array = []
	for i in count:
		out.append(int(src[i]) if i < src.size() else -1)
	return out


## Cor do selo de uma entrada de `covers` (coberta ou já aberta); -1 se nunca teve pano.
static func cover_color(value: int) -> int:
	if value >= 0:
		return value
	return -2 - value if value <= -2 else -1


static func is_covered_in(cover_state: Array, i: int) -> bool:
	return i < cover_state.size() and int(cover_state[i]) >= 0


## Garrafa cheia de uma cor só.
static func is_complete(tube: Array) -> bool:
	return tube.size() == CAPACITY and top_run(tube) == CAPACITY


## Abre as garrafas cobertas cuja cor já foi completada. Cada garrafa completa de uma cor abre
## uma coberta daquela cor (a primeira da esquerda). Devolve as garrafas que abriram agora.
static func reveal_in(state: Array, cover_state: Array) -> Array:
	var opened: Array = []
	if not cover_state.any(func(v) -> bool: return int(v) >= 0):
		return opened  # nenhuma garrafa coberta: nada a abrir (caminho rápido do resolvedor)
	var complete := {}
	for i in state.size():
		if not is_covered_in(cover_state, i) and is_complete(state[i]):
			var c: int = state[i][0]
			complete[c] = int(complete.get(c, 0)) + 1
	for c in complete:
		var already := cover_state.count(-(c + 2))
		for i in cover_state.size():
			if already >= complete[c]:
				break
			if int(cover_state[i]) == c:
				cover_state[i] = -(c + 2)
				already += 1
				opened.append(i)
	opened.sort()
	return opened


static func can_pour_in(state: Array, from: int, to: int, cover_state: Array = []) -> bool:
	if from == to or from < 0 or to < 0 or from >= state.size() or to >= state.size():
		return false
	if is_covered_in(cover_state, from) or is_covered_in(cover_state, to):
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


## Menor número de jogadas para resolver (busca em largura), respeitando as garrafas cobertas.
## Devolve -1 se não houver solução ou se passar de `max_states` estados.
static func min_moves(start: Array, max_states: int = 400000, start_covers: Array = []) -> int:
	var first: Array = copy_tubes(start)
	var first_covers: Array = normalized_covers(start_covers, first.size())
	if is_solved_state(first):
		return 0
	var seen: Dictionary = {_key(first, first_covers): true}
	var frontier: Array = [[first, first_covers]]
	var depth: int = 0
	while not frontier.is_empty():
		depth += 1
		var next: Array = []
		for node in frontier:
			var state: Array = node[0]
			var cov: Array = node[1]
			for from in state.size():
				var src: Array = state[from]
				if src.is_empty() or is_covered_in(cov, from):
					continue
				# garrafa já completa de uma cor: não mexe
				if is_complete(src):
					continue
				for to in state.size():
					if not can_pour_in(state, from, to, cov):
						continue
					# mover uma garrafa inteira de uma cor para uma vazia não ajuda
					if (state[to] as Array).is_empty() and top_run(src) == src.size():
						continue
					var child: Array = copy_tubes(state)
					var child_cov: Array = cov.duplicate()
					pour_in(child, from, to)
					reveal_in(child, child_cov)
					var k: String = _key(child, child_cov)
					if seen.has(k):
						continue
					if is_solved_state(child):
						return depth
					seen[k] = true
					next.append([child, child_cov])
					if seen.size() > max_states:
						return -1
		frontier = next
	return -1


## Chave do estado: as garrafas descobertas são intercambiáveis (sem ordem); as cobertas entram
## na ordem, com a cor que as abre (a ordem decide qual abre primeiro).
static func _key(state: Array, cover_state: Array = []) -> String:
	var parts: PackedStringArray = []
	var covered: PackedStringArray = []
	for i in state.size():
		if is_covered_in(cover_state, i):
			covered.append("%d:%s" % [cover_state[i], str(state[i])])
		else:
			parts.append(str(state[i]))
	parts.sort()
	return "|".join(parts) + "#" + "|".join(covered)
