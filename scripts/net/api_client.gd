class_name ApiClient
extends RefCounted
## Conversas com o servidor do Na Lata (api.nalatagame.tech, repositório na-lata-web): funções puras
## que montam e leem as mensagens. Quem faz a chamada de rede é o autoload `Server`.
## O servidor confere cada partida do Poção de Cores e é ele que dá os pontos e o ranking.

const BASE_URL := "https://api.nalatagame.tech/v1"
## Nome do Poção de Cores no servidor (no jogo ele se chama "potion").
const SERVER_GAME_ID := "pocao"

## Tipo de recompensa do servidor para cada ajuda da partida.
const REWARD_KINDS := {"shuffle": "pshuffle", "flask": "pflask", "moves": "pmoves", "retry": "pretry"}

## Recados curtos para os erros que o jogador pode ver.
const ERROR_TEXTS := {
	"NETWORK": "Sem conexão com o servidor. Confira a internet e tente de novo.",
	"GAME_UNAVAILABLE": "O Poção de Cores está em manutenção. Tente mais tarde.",
	"PUZZLE_UNAVAILABLE": "Esta fase não abriu agora. Tente de novo em instantes.",
	"RETRY_NEEDS_AD": "Uma nova tentativa pede uma propaganda.",
	"REWARD_NOT_VERIFIED": "A propaganda não foi confirmada. Tente de novo.",
	"REWARD_USED": "Esta propaganda já foi usada.",
	"CHALLENGE_CLOSED": "Este desafio já encerrou. Agora só valem os desafios de hoje.",
	"NO_BOOSTS": "Acabaram as ajudas desta fase.",
	"BOOST_BLOCKED": "Esta ajuda zeraria seus pontos neste desafio.",
	"SHUFFLE_UNAVAILABLE": "Não deu para embaralhar agora. Nada foi cobrado.",
	"MATCH_ENDED": "Esta partida já terminou.",
	"MATCH_SOLVED": "Esta fase já foi resolvida.",
	"MOVES_DIVERGED": "A partida ficou diferente da do servidor. Abra a fase de novo.",
	"INVALID_MOVES": "A partida ficou diferente da do servidor. Abra a fase de novo.",
	"RATE_LIMIT": "Muitas tentativas seguidas. Espere um pouco.",
	"BLOCKED": "Sua conta está bloqueada. Fale com o suporte.",
}


## Lê a resposta HTTP. Devolve {ok, status, data, code, message}.
## `code` = código de erro do servidor ("NETWORK" quando nem chegou lá).
static func parse_response(result: int, status: int, body: PackedByteArray) -> Dictionary:
	if result != HTTPRequest.RESULT_SUCCESS or status == 0:
		return error_result(0, "NETWORK", "")
	var text := body.get_string_from_utf8()
	var data: Variant = JSON.parse_string(text) if not text.is_empty() else {}
	if data == null:
		data = {}
	if status >= 200 and status < 300:
		return {"ok": true, "status": status, "data": data, "code": "", "message": ""}
	var err: Dictionary = {}
	if data is Dictionary and (data as Dictionary).get("error") is Dictionary:
		err = data.error
	return error_result(status, str(err.get("code", "HTTP_%d" % status)), str(err.get("message", "")))


static func error_result(status: int, code: String, message: String) -> Dictionary:
	return {"ok": false, "status": status, "data": {}, "code": code, "message": message}


## Texto para mostrar ao jogador: o nosso recado, ou o do servidor, ou um genérico.
static func error_text(res: Dictionary) -> String:
	var code: String = res.get("code", "")
	if ERROR_TEXTS.has(code):
		return ERROR_TEXTS[code]
	var msg: String = res.get("message", "")
	return msg if not msg.is_empty() else "Algo deu errado. Tente de novo."


## O JSON chega com números "quebrados" (1.0): volta tudo para inteiro, inclusive dentro das listas.
static func to_ints(value: Variant) -> Variant:
	if value is float:
		return int(value)
	if value is Array:
		var out: Array = []
		for v in value:
			out.append(to_ints(v))
		return out
	return value


## Partida do servidor (PocaoMatch) → o formato que a tela da partida usa (o mesmo dos geradores),
## com `match_id`, as regras gravadas (`params`) e o estado atual (`state`).
static func challenge_from_match(m: Dictionary) -> Dictionary:
	var params: Dictionary = m.get("params", {})
	var data := {
		"match_id": str(m.get("id", "")),
		"mode": str(m.get("mode", "daily")),
		"key": str(m.get("key", "")),
		"difficulty": str(m.get("difficulty", "easy")),
		"tubes": to_ints(m.get("tubes", [])),
		"covers": to_ints(m.get("covers", [])),
		"hidden": bool(m.get("hidden", false)),
		"par": int(m.get("par", 0)),
		"full_points": int(m.get("fullPoints", 0)),
		"params": {
			"shuffles": int(params.get("shuffles", Rules.SHUFFLES_PER_STAGE)),
			"flasks": int(params.get("flasks", Rules.EXTRA_BOTTLES_PER_STAGE)),
			"boost_cost": int(params.get("boostCost", Rules.BOOST_COST)),
			"extra_moves": int(params.get("extraMoves", Rules.EXTRA_MOVES)),
		},
		"moves": to_ints(m.get("moves", [])),
		"boosts": m.get("boosts", []),
	}
	if m.get("level") != null:
		data["level"] = int(m.level)
	if m.get("date") != null:
		data["date"] = str(m.date)
	if m.get("index") != null:
		data["index"] = int(m.index)
	if m.get("attempt") != null:
		data["attempt"] = int(m.attempt)
	return data


## Estado da partida devolvido pelo servidor depois de uma ajuda (tubes, moveLimit, points…), com inteiros.
static func state_from_match(m: Dictionary) -> Dictionary:
	var s: Dictionary = m.get("state", {})
	return {
		"tubes": to_ints(s.get("tubes", [])),
		"covers": to_ints(s.get("covers", [])),
		"moves_used": int(s.get("movesUsed", 0)),
		"move_limit": int(s.get("moveLimit", 0)),
		"points": int(s.get("points", 0)),
		"shuffles_left": int(s.get("shufflesLeft", 0)),
		"flasks_left": int(s.get("flasksLeft", 0)),
		"solved": bool(s.get("solved", false)),
	}


## Corpo do fim da partida: todas as jogadas e o que o jogo acha que deu (o servidor refaz e confere).
static func finish_body(moves: Array, points: int, solved: bool) -> Dictionary:
	return {"moves": moves, "claimed": {"moves": moves.size(), "points": points, "solved": solved}}


## Linhas de um ranking do servidor (`rows` e, no Global, também o pódio) em [posição, apelido, pontos, sou_eu].
static func ranking_rows(data: Dictionary) -> Array:
	var out: Array = []
	var seen := {}
	var lists: Array = []
	if data.get("podium") is Array:
		lists.append(data.podium)
	if data.get("rows") is Array:
		lists.append(data.rows)
	for list in lists:
		for r in list:
			if not (r is Dictionary):
				continue
			var pos := int(r.get("position", 0))
			if seen.has(pos):
				continue
			seen[pos] = true
			var nick: String = str(r.get("nickname", ""))
			if bool(r.get("guest", false)) and nick.is_empty():
				nick = "Visitante"
			out.append([pos, nick, int(r.get("points", 0)), bool(r.get("isMe", false))])
	out.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	return out
