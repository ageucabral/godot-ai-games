extends Node
## Propagandas premiadas. Por enquanto é uma SIMULAÇÃO: mostra uma tela de 3 segundos
## e entrega a recompensa. Na etapa do Android com AdMob, só esta parte muda.
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
	if instant:
		on_reward.call()
		ad_finished.emit()
		return
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
	label.add_theme_font_override("font", TropicalStyle.body_font(800))
	label.add_theme_font_size_override("font_size", 34)
	label.add_theme_color_override("font_color", Color.WHITE)
	shade.add_child(label)

	var left := duration
	while left > 0.0:
		label.text = "PROPAGANDA\n(simulação)\n\nAqui vai aparecer o anúncio do AdMob.\n\n%d" % ceili(left)
		await get_tree().create_timer(minf(1.0, left)).timeout
		left -= 1.0
	layer.queue_free()
	showing = false
	on_reward.call()
	ad_finished.emit()
