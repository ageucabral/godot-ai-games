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
	"REWARD_NOT_VERIFIED": "A propaganda não terminou ou não foi confirmada. Tente de novo.",
	"GOOGLE_FAILED": "Não deu para entrar com o Google agora. Tente de novo.",
	"NO_GOOGLE": "Entrar com Google só funciona no app do celular.",
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
	"INVALID_AGE": "Digite uma idade válida.",
	"COUNTRY_INVALID": "Escolha um país da lista.",
	"GUEST": "Entre com Google para continuar.",
	"FX_UNAVAILABLE": "Não deu para calcular o valor agora. Tente mais tarde.",
	"EXPIRED": "O prazo para resgatar este prêmio terminou.",
	"ALREADY_SUBMITTED": "Seus dados já foram enviados.",
}

## Número do projeto Google Cloud do Na Lata (o mesmo do login com Google): vai no pedido do Play Integrity.
const CLOUD_PROJECT_NUMBER := 969286539124
## Páginas fixas (o painel pode trocar pelo GET /config › links).
const DEFAULT_LINKS := {
	"privacy": "https://nalatagame.tech/privacidade",
	"terms": "https://nalatagame.tech/termos",
	"regulationFull": "https://nalatagame.tech/regulamento",
	"playStore": "https://play.google.com/store/apps/details?id=app.nalata.android",
}
const DEFAULT_SUPPORT_EMAIL := "suporte@nalatagame.tech"
## Assuntos aceitos pelo POST /support (o texto vai assim para o servidor).
const SUPPORT_TOPICS := ["Dúvida", "Problema técnico", "Prêmio e pagamento", "Outro"]
## País para "meu país não está na lista": joga, mas não concorre a prêmios.
const NO_COUNTRY := "XX"


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
	var out := error_result(status, str(err.get("code", "HTTP_%d" % status)), str(err.get("message", "")))
	out["error"] = err  # campos extras (ex.: a cotação nova em QUOTE_EXPIRED)
	return out


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
## com `match_id` e as regras gravadas (`params`).
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
	}
	if m.get("level") != null:
		data["level"] = int(m.level)
	if m.get("date") != null:
		data["date"] = str(m.date)
	if m.get("index") != null:
		data["index"] = int(m.index)
	return data


## Estado da partida devolvido pelo servidor depois de uma ajuda (só o que a tela usa), com inteiros.
static func state_from_match(m: Dictionary) -> Dictionary:
	var s: Dictionary = m.get("state", {})
	return {
		"tubes": to_ints(s.get("tubes", [])),
		"move_limit": int(s.get("moveLimit", 0)),
		"shuffles_left": int(s.get("shufflesLeft", 0)),
		"flasks_left": int(s.get("flasksLeft", 0)),
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
				nick = TranslationServer.translate("Visitante")
			out.append([pos, nick, int(r.get("points", 0)), bool(r.get("isMe", false))])
	out.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	return out


## "1.2.10" é menor que "1.3.0"? Compara número a número (o que faltar conta como 0).
static func version_less(a: String, b: String) -> bool:
	var pa := a.strip_edges().split(".")
	var pb := b.strip_edges().split(".")
	for i in maxi(pa.size(), pb.size()):
		var x := int(pa[i]) if i < pa.size() else 0
		var y := int(pb[i]) if i < pb.size() else 0
		if x != y:
			return x < y
	return false


## Nonce do Play Integrity: base64 web-safe (sem "=") de "nalata:<aparelho>:<ms>" (o servidor lê igual).
static func integrity_nonce(device_hash: String, at_ms: int) -> String:
	var b64 := Marshalls.utf8_to_base64("nalata:%s:%d" % [device_hash, at_ms])
	return b64.replace("+", "-").replace("/", "_").replace("=", "")


## Código de convite que veio no link da Play ("code=ABC123&utm_…" → "ABC123"; "" se não tiver).
static func invite_code_from_referrer(referrer: String) -> String:
	for part in referrer.uri_decode().split("&"):
		var kv := part.split("=", true, 1)
		if kv.size() == 2 and kv[0].strip_edges() == "code":
			return kv[1].strip_edges().to_upper()
	return ""


## Aviso de manutenção no idioma do jogador (cai no português e depois no texto geral).
static func maintenance_text(config: Dictionary, lang: String) -> String:
	var msgs: Variant = config.get("maintenanceMessage")
	if msgs is Dictionary:
		for l in [lang, "pt"]:
			var t := str((msgs as Dictionary).get(l, "")).strip_edges()
			if not t.is_empty():
				return t
	var text := str(config.get("maintenanceText", "")).strip_edges()
	return text if not text.is_empty() else "Estamos fazendo uma manutenção rápida. Voltamos já!"


## Link do painel (GET /config › links) ou o fixo.
static func link(config: Dictionary, key: String) -> String:
	var links: Variant = config.get("links")
	if links is Dictionary:
		var v := str((links as Dictionary).get(key, "")).strip_edges()
		if v.begins_with("https://"):
			return v
	return DEFAULT_LINKS.get(key, "")


## Prêmios do mês (GET /ranking › prizes) em linhas: "1º lugar: US$ 100", "4º ao 10º: US$ 5 cada".
static func prize_lines(prizes: Variant) -> Array[String]:
	var out: Array[String] = []
	if not prizes is Array:
		return out
	for p in prizes:
		if not p is Dictionary:
			continue
		var from := int(p.get("posFrom", 0))
		var to := int(p.get("posTo", from))
		var amount := str(p.get("amountLabel", ""))
		if from <= 0 or amount.is_empty():
			continue
		if to > from:
			out.append(TranslationServer.translate("%dº ao %dº: %s cada") % [from, to, amount])
		else:
			out.append(TranslationServer.translate("%dº lugar: %s") % [from, amount])
	return out


## País da região do idioma do aparelho ("pt_BR" → "BR"; "" se não tiver).
static func locale_country(locale: String) -> String:
	var parts := locale.replace("-", "_").split("_")
	return parts[1].to_upper() if parts.size() > 1 else ""


## País sugerido: o do chip, senão o da região do idioma do aparelho ("pt_BR" → "BR"), se estiver na lista.
static func suggested_country(codes: Array, sim_country: String, locale: String) -> String:
	for c in [sim_country.to_upper(), locale_country(locale)]:
		if not c.is_empty() and codes.has(c):
			return c
	return ""


## Nome do país no idioma do jogo (GET /countries › names).
static func country_name(country: Dictionary, lang: String) -> String:
	var names: Variant = country.get("names")
	if names is Dictionary:
		var n := str((names as Dictionary).get(lang, (names as Dictionary).get("pt", "")))
		if not n.is_empty():
			return n
	return str(country.get("code", ""))


## Regra dos prêmios para o jogador (GET /ranking › me.tag, regras do GET /config). "" se não estiver no ranking.
static func rule_text(me: Dictionary, rules: Variant) -> String:
	var r: Dictionary = rules if rules is Dictionary else {}
	match str(me.get("tag", "")):
		"no_country":
			return TranslationServer.translate("Prêmios ainda não estão disponíveis no seu país. Você segue no ranking normalmente.")
		"eligible":
			return TranslationServer.translate("Você já cumpre a regra para receber prêmios.")
		"missing":
			return TranslationServer.translate("Para receber prêmio, convide %d amigos que joguem pelo menos %d dias.") % [
				int(r.get("friends", 3)), int(r.get("days", 3))]
	return ""
