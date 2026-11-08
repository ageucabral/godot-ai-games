extends Node
## Propagandas premiadas. No Android com o plugin (android/plugin) é o AdMob de verdade, com a
## confirmação do Google ao servidor (SSV). Sem o plugin (Web, computador, testes) é uma SIMULAÇÃO:
## uma tela de 3 segundos que entrega a recompensa.
## Disponível em qualquer script como `Ads`.

signal ad_finished

## Para testes: entrega a recompensa na hora, sem mostrar nada.
var instant: bool = false
var duration: float = 3.0
var showing: bool = false


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
		ad_finished.emit()
		return true
	var plugin: Object = Server.native() if Server.enabled else null
	var unit: String = Server.rewarded_unit_id()
	if plugin and unit.is_empty():
		# o GET /config da abertura falhou ou ainda não chegou: sem o bloco, a simulação nunca seria conferida
		showing = true
		await Server.load_config()
		showing = false
		unit = Server.rewarded_unit_id()
	if plugin and not unit.is_empty():
		showing = true
		plugin.showRewarded(unit, str(Server.profile.get("id", "")), custom_data)
		var out: Array = await Server.wait_signal(Signal(plugin, "rewarded_finished"), Server.NATIVE_TIMEOUT_S, [false, "timeout"])
		showing = false
		ad_finished.emit()
		return bool(out[0])
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
	ad_finished.emit()
	return true
