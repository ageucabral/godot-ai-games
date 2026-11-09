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
## `ice` (Ageu, 9/11/2026): garrafa de gelo, presa até a jogada número `ice[i]` (0 = sem gelo); presa não dá nem recebe.
## `only`: garrafa de uma cor só (selo no fundo): só recebe a cor `only[i]` (-1 = qualquer cor).
## Esta classe não depende da árvore de cenas: dá para testar sozinha.

const CAPACITY: int = 4
## Limite da busca que confere se um embaralhado tem solução (mesmo limite do gerador de desafios).
const SHUFFLE_MAX_STATES: int = 150000

var tubes: Array = []
var hidden: Array = []
var covers: Array = []
var ice: Array = []
var only: Array = []
## Garrafas que abriram na última jogada (a tela confere `is_covered`; isto ajuda os testes).
var last_revealed: Array = []
## Lista de jogadas feitas, cada uma [de, para]. Pelo servidor, vai junto nas ajudas e no fim da partida.
var moves: Array = []


func _init(start_tubes: Array = [], hide_lower_layers: bool = false, start_covers: Array = [], start_ice: Array = [], start_only: Array = []) -> void:
	tubes = copy_tubes(start_tubes)
	covers = normalized_covers(start_covers, tubes.size())
	ice = normalized_list(start_ice, tubes.size(), 0)
	only = normalized_list(start_only, tubes.size(), -1)
	for t in tubes:
		var flags: Array = []
		for i in (t as Array).size():
			flags.append(hide_lower_layers and i < (t as Array).size() - 1)
		hidden.append(flags)


## Quantas jogadas (despejos) já foram feitas nesta tentativa.
func moves_used() -> int:
	return moves.size()


func can_pour(from: int, to: int) -> bool:
	return can_pour_in(tubes, from, to, covers, ice_left(), only)


## Quantas jogadas faltam para cada garrafa de gelo derreter (0 = livre).
func ice_left() -> Array:
	return ice_left_at(ice, moves.size())


func is_frozen(i: int) -> bool:
	return i < ice.size() and int(ice[i]) > moves.size()


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
	ice.append(0)
	only.append(-1)


## Embaralhar: mistura as camadas à mostra das garrafas abertas que ainda não estão completas,
## mantendo quanto cada uma tem. As camadas "?" ficam onde estão (senão o embaralhar revelaria
## cores escondidas e esconderia cores já vistas). Só aceita um embaralhado diferente e com solução.
## Devolve false se não achou.
func shuffle(rng: RandomNumberGenerator, tries: int = 10) -> bool:
	var candidate := shuffled_state(rng, tries)
	if candidate.is_empty():
		return false
	apply_shuffled(candidate)
	return true


## Troca as garrafas por um embaralhado já calculado por `shuffled_state`.
func apply_shuffled(state: Array) -> void:
	tubes = copy_tubes(state)
	last_revealed = reveal_in(tubes, covers)  # o embaralhado pode completar a cor de um pano


## Calcula um embaralhado (sem aplicar). Devolve [] se não achou um diferente e com solução.
func shuffled_state(rng: RandomNumberGenerator, tries: int = 10) -> Array:
	var spots: Array = []
	var pool: Array = []
	var left := ice_left()
	for i in tubes.size():
		# presa no gelo ou de uma cor só: fica como está
		if is_covered(i) or is_complete(tubes[i]) or int(left[i]) > 0 or int(only[i]) >= 0:
			continue
		for j in (tubes[i] as Array).size():
			if hidden[i][j]:
				continue
			spots.append([i, j])
			pool.append(tubes[i][j])
	if pool.size() < 2:
		return []
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
		var candidate_covers: Array = covers.duplicate()
		reveal_in(candidate, candidate_covers)
		if min_moves(candidate, SHUFFLE_MAX_STATES, candidate_covers, left, only) < 0:
			continue
		return candidate
	return []


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
	return normalized_list(src, count, -1)


## Uma entrada por garrafa (`fill` onde faltar).
static func normalized_list(src: Array, count: int, fill: int) -> Array:
	var out: Array = []
	for i in count:
		out.append(int(src[i]) if i < src.size() else fill)
	return out


## Gelo que ainda falta derreter em cada garrafa depois de `moves_made` jogadas.
static func ice_left_at(ice_state: Array, moves_made: int) -> Array:
	var out: Array = []
	for v in ice_state:
		out.append(maxi(0, int(v) - moves_made))
	return out


static func _has_locks(ice_state: Array, only_state: Array) -> bool:
	return ice_state.any(func(v) -> bool: return int(v) > 0) or only_state.any(func(v) -> bool: return int(v) >= 0)


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


static func can_pour_in(state: Array, from: int, to: int, cover_state: Array = [], ice_state: Array = [], only_state: Array = []) -> bool:
	if from == to or from < 0 or to < 0 or from >= state.size() or to >= state.size():
		return false
	if is_covered_in(cover_state, from) or is_covered_in(cover_state, to):
		return false
	if (from < ice_state.size() and int(ice_state[from]) > 0) or (to < ice_state.size() and int(ice_state[to]) > 0):
		return false
	var a: Array = state[from]
	var b: Array = state[to]
	if a.is_empty() or b.size() >= CAPACITY:
		return false
	if to < only_state.size() and int(only_state[to]) >= 0 and int(only_state[to]) != int(a[-1]):
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
static func min_moves(start: Array, max_states: int = 400000, start_covers: Array = [], start_ice: Array = [], start_only: Array = []) -> int:
	return int(_shortest(start, start_covers, max_states, start_ice, start_only)[0])


## Primeira jogada de um caminho mais curto até resolver ([de, para]); [] se não achar.
## Usada na primeira partida guiada (fases pequenas).
static func hint_move(start: Array, start_covers: Array = [], max_states: int = 60000, start_ice: Array = [], start_only: Array = []) -> Array:
	return _shortest(start, start_covers, max_states, start_ice, start_only)[1]


## Busca em largura do caminho mais curto. Devolve [jogadas, primeira jogada]: [0, []] se já está
## resolvido; [-1, []] se não há solução ou se passou de `max_states` estados.
## Gelo: `start_ice[i]` = jogadas até a garrafa soltar (conta a partir deste estado); `start_only` = cor aceita.
static func _shortest(start: Array, start_covers: Array, max_states: int, start_ice: Array = [], start_only: Array = []) -> Array:
	var first: Array = copy_tubes(start)
	var first_covers: Array = normalized_covers(start_covers, first.size())
	var ice0: Array = normalized_list(start_ice, first.size(), 0)
	var only0: Array = normalized_list(start_only, first.size(), -1)
	var locked := _has_locks(ice0, only0)
	if is_solved_state(first):
		return [0, []]
	var seen: Dictionary = {_key(first, first_covers, ice0, only0): true}
	var frontier: Array = [[first, first_covers, []]]
	var depth: int = 0
	while not frontier.is_empty():
		depth += 1
		var next: Array = []
		var ice_now: Array = ice_left_at(ice0, depth - 1) if locked else []
		var ice_child: Array = ice_left_at(ice0, depth) if locked else []
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
					if not can_pour_in(state, from, to, cov, ice_now, only0):
						continue
					# mover uma garrafa inteira de uma cor para uma vazia não ajuda (só entre garrafas comuns)
					if (state[to] as Array).is_empty() and top_run(src) == src.size() and (not locked or (int(only0[from]) < 0 and int(only0[to]) < 0)):
						continue
					var child: Array = copy_tubes(state)
					var child_cov: Array = cov.duplicate()
					pour_in(child, from, to)
					reveal_in(child, child_cov)
					var k: String = _key(child, child_cov, ice_child, only0)
					if seen.has(k):
						continue
					var first_move: Array = node[2] if depth > 1 else [from, to]
					if is_solved_state(child):
						return [depth, first_move]
					seen[k] = true
					next.append([child, child_cov, first_move])
					if seen.size() > max_states:
						return [-1, []]
		frontier = next
	return [-1, []]


## Chave do estado: as garrafas descobertas são intercambiáveis (sem ordem); as cobertas entram
## na ordem, com a cor que as abre (a ordem decide qual abre primeiro). Garrafas presas no gelo ou de uma
## cor só também entram na ordem (só quando a fase tem alguma; sem elas a chave é a de sempre).
static func _key(state: Array, cover_state: Array = [], ice_state: Array = [], only_state: Array = []) -> String:
	var parts: PackedStringArray = []
	var covered: PackedStringArray = []
	var locked: PackedStringArray = []
	for i in state.size():
		if is_covered_in(cover_state, i):
			covered.append("%d:%s" % [cover_state[i], str(state[i])])
		elif (i < ice_state.size() and int(ice_state[i]) > 0) or (i < only_state.size() and int(only_state[i]) >= 0):
			locked.append("%d/%d/%d:%s" % [i, int(ice_state[i]) if i < ice_state.size() else 0, int(only_state[i]) if i < only_state.size() else -1, str(state[i])])
		else:
			parts.append(str(state[i]))
	parts.sort()
	var key := "|".join(parts) + "#" + "|".join(covered)
	return key + "#" + "|".join(locked) if not locked.is_empty() else key
