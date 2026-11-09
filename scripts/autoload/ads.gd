extends Node
## Propagandas: a premiada (ajudas, com a confirmação do Google ao servidor — SSV) e o anúncio entre níveis
## (intersticial, regras do painel). No Android com o plugin (android/plugin) é o AdMob de verdade. Sem o plugin
## (Web, computador, testes) é uma SIMULAÇÃO: uma tela de 3 segundos que entrega a recompensa.
## Disponível em qualquer script como `Ads`.

## Para testes: entrega a recompensa na hora, sem mostrar nada.
var instant: bool = false
var duration: float = 3.0
var showing: bool = false
## Quando o último anúncio (de qualquer tipo) apareceu, e o que aconteceu desde o último intersticial.
var last_ad_unix: int = 0
var levels_since_inter: int = 0
var rewarded_since_inter: bool = false


## Mostra a propaganda e chama `on_reward` quando ela termina.
func show_rewarded(on_reward: Callable) -> void:
	if showing:
		return
	if await play():
		on_reward.call()


## Mostra a propaganda e espera ela acabar (use com `await`). Devolve true se a recompensa foi ganha.
## `custom_data` vai para a confirmação do AdMob ao servidor (SSV); a simulação ignora.
func play(custom_data: String = "") -> bool:
	if showing:
		return false
	if instant:
		return true
	var plugin: Object = Server.native() if Server.enabled else null
	var unit: String = Server.rewarded_unit_id()
	if plugin and unit.is_empty():
		# o GET /config da abertura falhou ou ainda não chegou: sem o bloco, a simulação nunca seria conferida
		showing = true
		await Server.load_config()
		showing = false
		unit = Server.rewarded_unit_id()
		if unit.is_empty() and not custom_data.is_empty():
			return false  # sem o bloco do AdMob: a simulação nunca seria confirmada pelo servidor
	if plugin and not unit.is_empty():
		showing = true
		plugin.showRewarded(unit, str(Server.profile.get("id", "")), custom_data)
		var out: Array = await Server.wait_signal(Signal(plugin, "rewarded_finished"), Server.NATIVE_TIMEOUT_S, [false, "timeout"])
		showing = false
		if bool(out[0]):
			_mark_ad(true)
		return bool(out[0])
	await _simulate()
	_mark_ad(true)
	return true


## Resolveu um nível e vai para o próximo: mostra o anúncio entre níveis se as regras do painel mandarem (a contagem
## de níveis começa no nível da regra; um vídeo premiado vale como o anúncio da rodada). Só com o plugin do AdMob
## (Android): sem ele não há anúncio nenhum. Use com `await`; volta quando o anúncio fecha (ou na hora).
func maybe_interstitial(solved_level: int) -> void:
	var from := Server.rule_int("pcInterFrom", 0)
	if from <= 0 or solved_level < from:
		levels_since_inter = 0
		return
	levels_since_inter += 1
	if rewarded_since_inter:
		rewarded_since_inter = false
		levels_since_inter = 0
		return
	if showing:
		return
	var due := Rules.interstitial_due(levels_since_inter, GameState.now_unix() - last_ad_unix,
		Server.rule_int("pcInterEvery", 3), Server.rule_int("pcInterGapSec", 90))
	if instant:
		if due:
			_mark_ad(false)
		return
	var plugin: Object = Server.native_with("interstitial_finished") if Server.enabled else null
	var unit := Server.ad_unit_id("interstitial")
	if plugin == null or unit.is_empty():
		return
	if not due:
		plugin.preloadInterstitial(unit)  # já deixa o próximo pronto (o plugin não baixa de novo se já tem)
		return
	showing = true
	plugin.showInterstitial(unit)
	var out: Array = await Server.wait_signal(Signal(plugin, "interstitial_finished"), Server.NATIVE_TIMEOUT_S, [false])
	showing = false
	if bool(out[0]):
		_mark_ad(false)
		Server.track("interstitial_shown", {"level": solved_level})


## Um anúncio acabou de fechar: é dele que conta o intervalo mínimo até o próximo.
func _mark_ad(rewarded: bool) -> void:
	last_ad_unix = GameState.now_unix()
	if rewarded:
		rewarded_since_inter = true
	else:
		levels_since_inter = 0


## Tela escura de `duration` segundos no lugar do AdMob (Web, computador, testes).
func _simulate() -> void:
	showing = true
	var layer := CanvasLayer.new()
	layer.layer = 100
	get_tree().root.add_child(layer)

	var shade := ColorRect.new()
	shade.color = Color(0.08, 0.05, 0.03, 0.92)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(shade)

	var label := Label.new()
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_override("font", GameStyle.body_font(800))
	label.add_theme_font_size_override("font_size", 34)
	label.add_theme_color_override("font_color", Color.WHITE)
	shade.add_child(label)

	var left := duration
	while left > 0.0:
		label.text = tr("PROPAGANDA\n(simulação)\n\nAqui vai aparecer o anúncio do AdMob.\n\n%d") % ceili(left)
		await get_tree().create_timer(minf(1.0, left)).timeout
		left -= 1.0
	layer.queue_free()
	showing = false
