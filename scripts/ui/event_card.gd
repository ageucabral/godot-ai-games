class_name EventCard
extends Button
## Cartão do evento no hub Na Lata (como na proposta aprovada, Ageu 9/11/2026): ícone do tema, nome, "Evento ·
## termina em 2d 4h", selo NOVO antes da 1ª fase, a trilha de prêmios (ajuda grátis, frasco, moldura e o fundo do tema,
## acesos quando alcançados) e "7 de 15 fases do evento". Tocar abre a próxima fase. Os dados vêm de
## `GameState.extras.event` (com `rewards` do servidor).

var event: Dictionary = {}
var countdown: String = ""
var _name: Label
var _sub: Label
var _new: Control
var _count: Label
var _trail: Trail


func _init() -> void:
	flat = true
	focus_mode = Control.FOCUS_NONE
	custom_minimum_size = Vector2(0, 300)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 28
	box.offset_right = -28
	box.offset_top = 22
	box.offset_bottom = -26
	box.add_theme_constant_override("separation", 10)
	add_child(box)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 14)
	box.add_child(head)
	var icon := GameStyle.make_label("", 64)
	icon.name = "Icon"
	icon.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	head.add_child(icon)
	var texts := VBoxContainer.new()
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texts.add_theme_constant_override("separation", -4)
	head.add_child(texts)
	_name = GameStyle.make_title("", 40)
	_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_name.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	texts.add_child(_name)
	_sub = GameStyle.make_label("", 22, true, Color.WHITE)
	_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_sub.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	texts.add_child(_sub)
	_new = Menus.Row._new_pill()
	_new.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	head.add_child(_new)
	_trail = Trail.new()
	box.add_child(_trail)
	_count = GameStyle.make_label("", 22, true, Color.WHITE)
	_count.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	box.add_child(_count)
	Extras._ignore_mouse(self)


## Mostra o evento (`GameState.extras.event`); some sem evento no ar.
func set_event(ev: Variant) -> void:
	visible = ev is Dictionary
	if not visible:
		return
	event = ev
	var theme := str(event.get("theme", ""))
	(find_child("Icon", true, false) as Label).text = Extras.event_icon(theme)
	_name.text = str(event.get("name", ""))
	var done := int(event.get("done", 0))
	var levels := int(event.get("levels", 0))
	_new.visible = done == 0
	# evento completo: o cartão fica só para ver a trilha (o servidor recusaria a próxima fase com EVENT_DONE)
	disabled = levels > 0 and done >= levels
	_count.text = tr("Evento completo!") if done >= levels else tr("%d de %d fases do evento") % [done, levels]
	_trail.rewards = event.get("rewards", [])
	_trail.done = done
	_trail.theme_icon = Extras.event_icon(theme)
	_trail.queue_redraw()
	update_countdown()
	queue_redraw()


func update_countdown() -> void:
	if event.is_empty():
		return
	var left := Rules.unix_from_iso(str(event.get("endsAt", ""))) - GameState.now_unix()
	_sub.text = tr("Evento · termina em %s") % Rules.short_countdown(maxi(0, left))


func _draw() -> void:
	var sink := 6.0 if is_pressed() else 0.0
	var color := Extras.event_color(str(event.get("theme", "")))
	var shadow := StyleBoxFlat.new()
	shadow.bg_color = Color(0, 0, 0, 0.3)
	shadow.set_corner_radius_all(34)
	draw_style_box(shadow, Rect2(Vector2(0, 12), size - Vector2(0, 12)))
	var r := Rect2(Vector2(0, sink), size - Vector2(0, 12))
	var base := StyleBoxFlat.new()
	base.bg_color = GameStyle.INK
	base.set_corner_radius_all(34)
	draw_style_box(base, r)
	# corpo com degradê da cor do tema para o roxo
	var body := r.grow(-6)
	var pts := _rounded(body, 28.0)
	var cols := PackedColorArray()
	for p in pts:
		cols.append(color.lerp(Color("7a2fd6"), clampf((p.x - body.position.x) / body.size.x * 0.9 + (p.y - body.position.y) / body.size.y * 0.2, 0, 1)))
	draw_polygon(pts, cols)
	var gloss := StyleBoxFlat.new()
	gloss.bg_color = Color(1, 1, 1, 0.14)
	gloss.set_corner_radius_all(22)
	draw_style_box(gloss, Rect2(body.position + Vector2(10, 8), Vector2(body.size.x - 20, body.size.y * 0.36)))


## Contorno de um retângulo de cantos redondos (para pintar com degradê).
static func _rounded(rect: Rect2, radius: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var corners := [rect.position + Vector2(rect.size.x - radius, radius), rect.position + rect.size - Vector2(radius, radius),
		rect.position + Vector2(radius, rect.size.y - radius), rect.position + Vector2(radius, radius)]
	for k in 4:
		for i in 7:
			var a := -PI * 0.5 + PI * 0.5 * k + PI * 0.5 * i / 6.0
			pts.append(corners[k] + Vector2(cos(a), sin(a)) * radius)
	return pts


## Trilha de prêmios do evento: bolinhas ligadas por uma linha; acesas (com borda dourada) quando alcançadas.
class Trail extends Control:
	var rewards: Array = []
	var done: int = 0
	var theme_icon: String = "🎉"

	func _init() -> void:
		custom_minimum_size = Vector2(0, 92)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		if rewards.is_empty():
			return
		var n := rewards.size()
		var step := size.x / n
		var y := size.y * 0.5
		draw_line(Vector2(step * 0.5, y), Vector2(size.x - step * 0.5, y), Color(1, 1, 1, 0.45), 8.0)
		var font := GameStyle.body_font()
		for i in n:
			var r: Dictionary = rewards[i]
			var c := Vector2(step * (i + 0.5), y)
			var got := done >= int(r.get("at", 0))
			draw_circle(c, 40, GameStyle.GOLD if got else GameStyle.INK)
			draw_circle(c, 34, Color("fff4dc") if got else Color("f3eefc"))
			var icon: String = Extras.EVENT_REWARD_ICONS.get(str(r.get("kind", "")), theme_icon)
			var w := font.get_string_size(icon, HORIZONTAL_ALIGNMENT_LEFT, -1, 38).x
			draw_string(font, c + Vector2(-w * 0.5, 14), icon, HORIZONTAL_ALIGNMENT_LEFT, -1, 38, Color.WHITE if got else Color(1, 1, 1, 0.6))
