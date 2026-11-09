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
## Músicas de fundo enviadas pelo painel (`config.music`), baixadas uma vez e guardadas aqui.
var music_dir: String = "user://music"
## Para testes: (url, arquivo de destino) -> bool; grava o arquivo no lugar do download de verdade.
var music_download: Callable
const MUSIC_TIMEOUT_S := 90.0
## Espera usada entre tentativas de confirmar a propaganda (os testes zeram).
var retry_wait_s: float = REWARD_RETRY_WAIT_S

## Espera máxima pelo token do Play Integrity (sem ele o login segue; o servidor decide o que fazer).
const INTEGRITY_TIMEOUT_S := 10.0
## Código de convite que veio no link da Play (install referrer), para a tela da idade.
var invite_code: String = ""
## Idade mínima que bloqueou este aparelho (a conta foi apagada pelo servidor); 0 = livre.
var age_blocked: int = 0
## Para testes: manda os eventos na hora (sem esperar juntar).
var events_now: bool = false
## Duelo que chegou por link (ou pelo link da Play) e ainda não foi mostrado.
var pending_duel: String = ""

var _cfg := ConfigFile.new()
var _logging_in: bool = false
var _events: Array = []
var _events_flushing: bool = false


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
	invite_code = _cfg.get_value("session", "invite_code", "")
	age_blocked = _cfg.get_value("session", "age_blocked", 0)
	if device_hash.is_empty():
		device_hash = _new_device_hash()
		_cfg.set_value("session", "device_hash", device_hash)
		_cfg.save(session_path)


func _save_session() -> void:
	_cfg.set_value("session", "token", token)
	_cfg.set_value("session", "profile", profile)
	_cfg.set_value("session", "device_hash", device_hash)
	_cfg.set_value("session", "invite_code", invite_code)
	_cfg.set_value("session", "age_blocked", age_blocked)
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


## O plugin, se ele tiver o sinal `signal_name` (null se não). No Android o `has_method` não enxerga as
## funções do plugin Java (elas não ficam no ClassDB), mas os sinais, sim. `share` e `simCountry` vieram
## na mesma versão do plugin que o sinal "install_referrer".
func native_with(signal_name: String) -> Object:
	var plugin := native()
	return plugin if plugin != null and plugin.has_signal(signal_name) else null


## Ainda é visitante (não entrou com Google).
func is_guest() -> bool:
	return bool(profile.get("guest", true))


## Dá para entrar com Google neste aparelho (Android com o plugin).
func can_sign_in_google() -> bool:
	return enabled and native() != null


## Bloco da propaganda premiada (do painel; com o "modo de teste" ligado, o bloco de teste do Google).
func rewarded_unit_id() -> String:
	return ad_unit_id("rewarded")


## Bloco de anúncio do AdMob pelo tipo ("rewarded", "interstitial"), do GET /config; "" se não veio.
func ad_unit_id(kind: String) -> String:
	var ads: Variant = config.get("ads")
	if not ads is Dictionary:
		return ""
	var units: Variant = (ads as Dictionary).get("unitIds")
	if not units is Dictionary:
		return ""
	var unit: Variant = (units as Dictionary).get(kind)
	return "" if unit == null else str(unit)


## Regra numérica do painel (`config.rules`), ou `default` se o /config não trouxe.
func rule_int(key: String, default: int) -> int:
	var rules: Variant = config.get("rules")
	if not rules is Dictionary:
		return default
	var v: Variant = (rules as Dictionary).get(key)
	return default if v == null else int(v)


## Busca o GET /config e liga o AdMob do plugin.
func load_config() -> bool:
	var res: Dictionary = await _send("GET", "/config", null, false)
	if not res.ok:
		return false
	if not res.data is Dictionary:
		return false
	config = res.data
	# guarda a versão mínima no aparelho: se o /config não chegar numa abertura, o aviso de atualizar continua
	var min_version := str(config.get("minAppVersion", "")).strip_edges()
	if min_version != saved_min_version():
		_cfg.set_value("config", "min_app_version", min_version)
		_cfg.save(session_path)
	var plugin := native()
	if plugin:
		plugin.adsInit()
	# já deixa uma propaganda carregada: o toque em "assistir" abre na hora (plugin novo, com o sinal "rewarded_ready")
	var preload_plugin := native_with("rewarded_ready")
	var rewarded_unit := rewarded_unit_id()
	if preload_plugin and not rewarded_unit.is_empty():
		preload_plugin.preloadRewarded(rewarded_unit)
	# o anúncio entre níveis só para quem já chegou ao nível da regra (quem não chegou não baixa à toa)
	var inter_plugin := native_with("interstitial_finished")
	var inter_unit := ad_unit_id("interstitial")
	var inter_from := rule_int("pcInterFrom", 0)
	if inter_plugin and not inter_unit.is_empty() and inter_from > 0 and GameState.current_level() >= inter_from:
		inter_plugin.preloadInterstitial(inter_unit)
	return true


## Baixa as músicas do painel que ainda não estão no aparelho, apaga as que saíram e passa a lista para o `Sfx`
## (com alguma, toca essas no lugar das do app). Sem o /config (sem internet), usa as que já estão guardadas.
func sync_music() -> void:
	var list: Variant = config.get("music")
	if list is Array:
		DirAccess.make_dir_recursive_absolute(music_dir)
		var keep: Array[String] = []
		for m: Variant in list:
			var file := ApiClient.music_file_name(m)
			if file.is_empty():
				continue
			var path := music_dir.path_join(file)
			if not FileAccess.file_exists(path):
				# baixa num arquivo temporário e só renomeia completo: um arquivo cortado nunca fica com o nome final
				var part := path + ".part"
				if not await _download_music(str(m.get("url", "")), part) or DirAccess.rename_absolute(part, path) != OK:
					DirAccess.remove_absolute(part)
					continue
			keep.append(file)
		for file in _music_files():
			if not file in keep:
				DirAccess.remove_absolute(music_dir.path_join(file))
	Sfx.set_custom_tracks(_music_files().map(func(f: String) -> String: return music_dir.path_join(f)))


## Arquivos de música guardados, em ordem de vaga ("1-…", "2-…", "3-…").
func _music_files() -> Array[String]:
	var files: Array[String] = []
	if not DirAccess.dir_exists_absolute(music_dir):
		return files
	for f in DirAccess.get_files_at(music_dir):
		if f.get_extension() in ["ogg", "mp3"]:
			files.append(f)
	files.sort()
	return files


## Baixa `url` (caminho da API, ex. "/pocao/music/1?v=…") direto para o arquivo `dest`, sem guardar na memória.
func _download_music(url: String, dest: String) -> bool:
	if music_download.is_valid():
		return music_download.call(url, dest)
	var http := HTTPRequest.new()
	http.timeout = MUSIC_TIMEOUT_S
	http.download_file = dest
	add_child(http)
	if url.is_empty() or http.request(base_url + url) != OK:
		http.queue_free()
		return false
	var out: Array = await http.request_completed
	http.queue_free()
	return out[0] == HTTPRequest.RESULT_SUCCESS and out[1] == 200


## Última versão mínima que o servidor mandou ("" = nenhuma), guardada no aparelho.
func saved_min_version() -> String:
	return str(_cfg.get_value("config", "min_app_version", ""))


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
	var body: Dictionary = await _login_body()
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
	var body := {
		"deviceHash": device_hash,
		"lang": GameState.language(),
		"tz": "America/Sao_Paulo",
		"device": {"model": OS.get_model_name().left(80), "os": ("%s %s" % [OS.get_name(), OS.get_version()]).left(80)},
	}
	var integrity: String = await integrity_token()
	if not integrity.is_empty():
		body["integrityToken"] = integrity
	return body


## Token do Play Integrity para o login ("" sem o plugin ou se o Google não respondeu).
func integrity_token() -> String:
	var plugin := native_with("integrity_token")
	if plugin == null:
		return ""
	var nonce := ApiClient.integrity_nonce(device_hash, int(Time.get_unix_time_from_system() * 1000.0))
	plugin.integrityToken(nonce, ApiClient.CLOUD_PROJECT_NUMBER)
	var out: Array = await wait_signal(Signal(plugin, "integrity_token"), INTEGRITY_TIMEOUT_S, ["", "timeout"])
	return str(out[0])


## Lê uma vez o código de convite do link da Play (só no Android com o plugin).
func load_install_referrer() -> void:
	var plugin := native_with("install_referrer")
	if plugin == null or _cfg.get_value("session", "referrer_checked", false):
		return
	plugin.installReferrer()
	var out: Array = await wait_signal(Signal(plugin, "install_referrer"), 15.0, [null, null])
	if out[0] == null:
		return  # sem resposta: tenta de novo na próxima abertura
	var code := ApiClient.invite_code_from_referrer(str(out[0]))
	if not code.is_empty():
		invite_code = code
	var duel := ApiClient.duel_code_from(str(out[0]))
	if not duel.is_empty():
		pending_duel = duel
	_cfg.set_value("session", "referrer_checked", true)
	_save_session()


## Link de duelo que abriu o app (nalata://duelo/CÓDIGO): o plugin guarda e entrega uma vez.
func take_launch_link() -> void:
	var plugin := native_with("notifications_allowed")
	if plugin == null:
		return
	var code := ApiClient.duel_code_from(str(plugin.takeLink()))
	if not code.is_empty():
		pending_duel = code


## Marca guardada na sessão deste aparelho (ex.: "nick_asked").
func get_flag(key: String) -> bool:
	return bool(_cfg.get_value("flags", key, false))


func set_flag(key: String, value: bool = true) -> void:
	_cfg.set_value("flags", key, value)
	_save_session()


## Troca o perfil guardado (resposta de /me/age, /me/country, /me/nickname).
func set_profile(p: Dictionary) -> void:
	profile = p
	_save_session()


## Apaga a conta no servidor (DELETE /me) e esquece a sessão. Devolve {ok, code}.
func delete_account() -> Dictionary:
	var res: Dictionary = await call_api("DELETE", "/me")
	if res.ok:
		sign_out()
	return res


## O servidor apagou a conta por causa da idade: o aparelho fica bloqueado.
func block_by_age(min_age: int) -> void:
	token = ""
	profile = {}
	home = {}
	age_blocked = maxi(min_age, 1)
	_save_session()


## Medição (POST /events): junta alguns eventos e manda de uma vez. Só jogando pelo servidor.
func track(event_name: String, props: Dictionary = {}) -> void:
	if not online():
		return
	_events.append({"name": event_name, "props": props})
	if events_now:
		await flush_events()
		return
	if _events_flushing:
		return
	_events_flushing = true
	await get_tree().create_timer(3.0).timeout
	# manda em lotes de até 20, incluindo os que chegaram enquanto o lote anterior ia para o servidor
	while not _events.is_empty() and online():
		await flush_events()
	_events_flushing = false


func flush_events() -> void:
	if _events.is_empty() or not online():
		return
	var batch := _events.slice(0, 20)
	_events = _events.slice(20)
	await call_api("POST", "/events", {"events": batch})


func sign_out() -> void:
	var plugin := native()
	if plugin and not is_guest():
		plugin.googleSignOut()
	token = ""
	profile = {}
	home = {}
	if _cfg.has_section("flags"):
		_cfg.erase_section("flags")
	_save_session()


## Entra como visitante se ainda não tem sessão. Devolve true se ficou com sessão.
## Quem já entrou com Google e perdeu a sessão entra com Google de novo (nunca vira visitante).
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
	if age_blocked > 0:
		return false  # a conta deste aparelho foi apagada pela idade: não cria outra
	_logging_in = true
	var guest_body: Dictionary = await _login_body()
	var res: Dictionary = await _send("POST", "/auth/guest", guest_body, false)
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
	var methods := {"GET": HTTPClient.METHOD_GET, "POST": HTTPClient.METHOD_POST, "PATCH": HTTPClient.METHOD_PATCH, "PUT": HTTPClient.METHOD_PUT, "DELETE": HTTPClient.METHOD_DELETE}
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
