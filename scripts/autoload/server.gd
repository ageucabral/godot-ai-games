extends Node
## Ligação com o servidor do Na Lata (o mesmo do app antigo: contas, pontos, ranking, propagandas).
## Disponível em qualquer script como `Server`. Ligado só no Android: na versão Web (teste no GitHub
## Pages) e nos testes o jogo continua só no aparelho, como antes.
## Toda chamada usa `await`: `var res := await Server.call_api("GET", "/pocao/home")`.

signal home_updated

var session_path: String = "user://session.cfg"
const TIMEOUT_S := 15.0
## Cliente "Web" do projeto Google Cloud do Na Lata (o mesmo do app antigo; o servidor confere o idToken com ele).
const GOOGLE_WEB_CLIENT_ID := "969286539124-r78meetsuprdbo5irje9fdj79fm4rdlh.apps.googleusercontent.com"
## Nome do plugin Android (android/plugin, Kotlin): login com Google e AdMob.
const NATIVE_SINGLETON := "NaLata"
## A propaganda pode ser confirmada pelo AdMob uns segundos depois de acabar: tenta de novo algumas vezes.
const REWARD_RETRIES := 4
const REWARD_RETRY_WAIT_S := 3.0

var enabled: bool = OS.has_feature("android")
var base_url: String = ApiClient.BASE_URL
## Para testes: Callable(method, path, body) -> {ok, status, data, code, message} no lugar da rede.
var transport: Callable
var token: String = ""
var device_hash: String = ""
var profile: Dictionary = {}
## Último GET /pocao/home (nível, desafios de hoje, pontos e posição do mês).
var home: Dictionary = {}
## Espera máxima por uma resposta do plugin (propaganda ou escolha de conta).
const NATIVE_TIMEOUT_S := 180.0
## Para testes: um plugin de mentira no lugar do Android.
var native_override: Object = null
## GET /config (regras, blocos do AdMob, links). Os blocos de propaganda vêm do painel.
var config: Dictionary = {}
## Espera usada entre tentativas de confirmar a propaganda (os testes zeram).
var retry_wait_s: float = REWARD_RETRY_WAIT_S

var _cfg := ConfigFile.new()
var _logging_in: bool = false


func _ready() -> void:
	_load_session()


## O jogo está jogando pelo servidor (ligado e com sessão).
func online() -> bool:
	return enabled and not token.is_empty()


func _load_session() -> void:
	_cfg = ConfigFile.new()
	if FileAccess.file_exists(session_path):
		_cfg.load(session_path)
	token = _cfg.get_value("session", "token", "")
	profile = _cfg.get_value("session", "profile", {})
	device_hash = _cfg.get_value("session", "device_hash", "")
	if device_hash.is_empty():
		device_hash = _new_device_hash()
		_cfg.set_value("session", "device_hash", device_hash)
		_cfg.save(session_path)


func _save_session() -> void:
	_cfg.set_value("session", "token", token)
	_cfg.set_value("session", "profile", profile)
	_cfg.set_value("session", "device_hash", device_hash)
	_cfg.save(session_path)


## Identificador aleatório deste aparelho (o servidor aceita 1 visitante por aparelho).
static func _new_device_hash() -> String:
	var bytes := Crypto.new().generate_random_bytes(16)
	return "gd-" + bytes.hex_encode()


## O plugin Android (null na Web, no computador e nos testes).
func native() -> Object:
	if native_override:
		return native_override
	return Engine.get_singleton(NATIVE_SINGLETON) if Engine.has_singleton(NATIVE_SINGLETON) else null


## Ainda é visitante (não entrou com Google).
func is_guest() -> bool:
	return bool(profile.get("guest", true))


## Dá para entrar com Google neste aparelho (Android com o plugin).
func can_sign_in_google() -> bool:
	return enabled and native() != null


## Bloco da propaganda premiada (do painel; com o "modo de teste" ligado, o bloco de teste do Google).
func rewarded_unit_id() -> String:
	var ads: Variant = config.get("ads")
	if not ads is Dictionary:
		return ""
	var units: Variant = (ads as Dictionary).get("unitIds")
	if not units is Dictionary:
		return ""
	var unit: Variant = (units as Dictionary).get("rewarded")
	return "" if unit == null else str(unit)


## Busca o GET /config e liga o AdMob do plugin.
func load_config() -> bool:
	var res: Dictionary = await _send("GET", "/config", null, false)
	if not res.ok:
		return false
	if not res.data is Dictionary:
		return false
	config = res.data
	var plugin := native()
	if plugin:
		plugin.adsInit()
	return true


## Entra com a conta Google: o plugin abre a escolha de conta e o servidor confere o idToken.
## O progresso do visitante deste aparelho passa para a conta. Devolve {ok, code}.
func sign_in_google() -> Dictionary:
	var plugin := native()
	if not enabled or plugin == null:
		return ApiClient.error_result(0, "NO_GOOGLE", "")
	plugin.googleSignIn(GOOGLE_WEB_CLIENT_ID)
	var out: Array = await wait_signal(Signal(plugin, "google_signed_in"), NATIVE_TIMEOUT_S, ["", "timeout"])
	var id_token: String = str(out[0])
	if id_token.is_empty():
		return ApiClient.error_result(0, "GOOGLE_CANCELLED" if out[1] == "cancelled" else "GOOGLE_FAILED", str(out[1]))
	var body := _login_body()
	body["idToken"] = id_token
	var res: Dictionary = await _send("POST", "/auth/google", body, false)
	if not res.ok:
		return res
	token = str(res.data.get("token", ""))
	profile = res.data.get("profile", {})
	_save_session()
	refresh_home()
	return res


func _login_body() -> Dictionary:
	return {
		"deviceHash": device_hash,
		"lang": GameState.language(),
		"tz": "America/Sao_Paulo",
		"device": {"model": OS.get_model_name().left(80), "os": ("%s %s" % [OS.get_name(), OS.get_version()]).left(80)},
	}


func sign_out() -> void:
	var plugin := native()
	if plugin and not is_guest():
		plugin.googleSignOut()
	token = ""
	profile = {}
	home = {}
	_save_session()


## Entra como visitante se ainda não tem sessão. Devolve true se ficou com sessão.
## (O login com Google entra na etapa do plugin Android; o progresso do visitante migra para a conta.)
func ensure_session() -> bool:
	if not enabled:
		return false
	if not token.is_empty():
		return true
	if _logging_in:
		while _logging_in:
			await get_tree().process_frame
		return not token.is_empty()
	if not is_guest() and can_sign_in_google():
		# a sessão de quem entrou com Google venceu (30 dias): entra com Google de novo, nunca como visitante
		_logging_in = true
		var g: Dictionary = await sign_in_google()
		_logging_in = false
		return g.ok
	_logging_in = true
	var res: Dictionary = await _send("POST", "/auth/guest", _login_body(), false)
	_logging_in = false
	if not token.is_empty():
		return true  # entrou com Google enquanto esperava: não troca a conta pelo visitante
	if not res.ok:
		return false
	token = str(res.data.get("token", ""))
	profile = res.data.get("profile", {})
	_save_session()
	return not token.is_empty()


## Chamada com sessão. Se a sessão venceu (401), entra de novo e repete uma vez.
func call_api(method: String, path: String, body: Variant = null) -> Dictionary:
	if not await ensure_session():
		return ApiClient.error_result(0, "NETWORK", "")
	var res: Dictionary = await _send(method, path, body, true)
	if res.status == 401:
		token = ""
		if await ensure_session():
			res = await _send(method, path, body, true)
	return res


func _send(method: String, path: String, body: Variant, auth: bool) -> Dictionary:
	if transport.is_valid():
		return transport.call(method, path, body)
	var headers := PackedStringArray(["Accept: application/json"])
	if auth and not token.is_empty():
		headers.append("Authorization: Bearer " + token)
	var payload := ""
	if body != null:
		headers.append("Content-Type: application/json")
		payload = JSON.stringify(body)
	var http := HTTPRequest.new()
	http.timeout = TIMEOUT_S
	add_child(http)
	var methods := {"GET": HTTPClient.METHOD_GET, "POST": HTTPClient.METHOD_POST, "PATCH": HTTPClient.METHOD_PATCH, "DELETE": HTTPClient.METHOD_DELETE}
	var err := http.request(base_url + path, headers, methods.get(method, HTTPClient.METHOD_GET), payload)
	if err != OK:
		http.queue_free()
		return ApiClient.error_result(0, "NETWORK", "")
	var out: Array = await http.request_completed
	http.queue_free()
	return ApiClient.parse_response(out[0], out[1], out[3])


## Atualiza o menu do Poção (nível, desafios de hoje, pontos do mês) e passa para o GameState.
func refresh_home() -> bool:
	var seq: int = GameState.server_result_seq
	var res: Dictionary = await call_api("GET", "/pocao/home")  # call_api já entra como visitante
	if not res.ok:
		return false
	if seq != GameState.server_result_seq:
		# uma partida terminou enquanto esperava: esta resposta é mais velha que o resultado; pede de novo
		seq = GameState.server_result_seq
		res = await call_api("GET", "/pocao/home")
		if not res.ok or seq != GameState.server_result_seq:
			return false
	home = res.data
	GameState.apply_server_home(home)
	home_updated.emit()
	return true


## Propaganda premiada conferida pelo servidor: cria a recompensa, mostra o anúncio e devolve o
## `rewardId` para usar na ajuda. Devolve "" se não deu (sem internet ou o anúncio não terminou).
## `extra` = {"matchId": …} para as ajudas, {"mode": "AAAA-MM-DD#n"} para nova tentativa.
func rewarded(kind: String, extra: Dictionary = {}) -> String:
	var body := {"kind": ApiClient.REWARD_KINDS.get(kind, kind)}
	body.merge(extra)
	var res: Dictionary = await call_api("POST", "/rewards", body)
	if not res.ok:
		return ""
	var reward_id := str(res.data.get("rewardId", ""))
	if not await Ads.play(str(res.data.get("ssvCustomData", reward_id))):
		return ""
	return reward_id


## Usa uma recompensa: repete enquanto o servidor ainda espera a confirmação do AdMob.
func call_with_reward(method: String, path: String, body: Dictionary) -> Dictionary:
	var res: Dictionary = {}
	for i in REWARD_RETRIES:
		res = await call_api(method, path, body)
		if res.ok or res.code != "REWARD_NOT_VERIFIED":
			return res
		if retry_wait_s > 0.0:
			await get_tree().create_timer(retry_wait_s).timeout
	return res


## Espera um sinal (de até 2 valores) por no máximo `timeout_s` segundos; sem resposta, devolve `fallback`.
func wait_signal(sig: Signal, timeout_s: float, fallback: Array) -> Array:
	var box := {"out": null}
	var on_emit := func(a: Variant = null, b: Variant = null) -> void:
		if box.out == null:
			box.out = [a, b]
	sig.connect(on_emit, CONNECT_ONE_SHOT)
	var deadline := Time.get_ticks_msec() + int(timeout_s * 1000.0)
	while box.out == null and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	if sig.is_connected(on_emit):
		sig.disconnect(on_emit)
	return box.out if box.out != null else fallback
