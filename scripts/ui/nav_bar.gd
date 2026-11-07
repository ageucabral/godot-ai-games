class_name NavBar
extends Control
## Barra de baixo do menu do jogo: Jogos · Ranking · Início · Desafios · Perfil.
## Visual limpo: barra escura de cantos redondos, ícone com o nome embaixo; a aba ativa ganha um
## círculo roxo. Uma aba pode mostrar um contador pequeno (ex.: desafios do dia "3/20").

signal tab_pressed(tab: String)

const TABS: Array = [["games", "Jogos", "games"], ["ranking", "Ranking", "trophy"], ["home", "Início", "home"],
	["daily", "Desafios", "calendar"], ["profile", "Perfil", "avatar"]]

var active: String = "home"
var buttons: Dictionary = {}
var _bar_box: StyleBoxFlat = _make_bar_box()


func _init() -> void:
	custom_minimum_size = Vector2(0, 132)


func _ready() -> void:
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 12
	row.offset_right = -12
	row.add_theme_constant_override("separation", 0)
	add_child(row)
	for t in TABS:
		var b := _Tab.new()
		b.label = t[1]
		b.icon_kind = t[2]
		b.is_active = t[0] == active
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var id: String = t[0]
		b.pressed.connect(func() -> void: tab_pressed.emit(id))
		row.add_child(b)
		buttons[id] = b


## Contador pequeno sobre o ícone de uma aba ("" esconde).
func set_counter(tab: String, text: String) -> void:
	if buttons.has(tab):
		buttons[tab].counter = text


func counter(tab: String) -> String:
	return buttons[tab].counter if buttons.has(tab) else ""


func _draw() -> void:
	draw_style_box(_bar_box, Rect2(Vector2(0, 14), Vector2(size.x, size.y - 14)))


static func _make_bar_box() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("24164f", 0.94)
	sb.corner_radius_top_left = 36
	sb.corner_radius_top_right = 36
	sb.shadow_color = Color(0, 0, 0, 0.3)
	sb.shadow_size = 12
	return sb


class _Tab extends Button:
	var label: String = ""
	var icon_kind: String = ""
	var is_active: bool = false
	var counter: String = "":
		set(value):
			counter = value
			queue_redraw()
	var _counter_box: StyleBoxFlat
	var _font: Font = GameStyle.body_font(800)

	func _init() -> void:
		flat = true
		focus_mode = Control.FOCUS_NONE
		_counter_box = StyleBoxFlat.new()
		_counter_box.bg_color = Color("ff5a6e")
		_counter_box.set_corner_radius_all(14)

	func _draw() -> void:
		var c := Vector2(size.x * 0.5, 62 + (3.0 if is_pressed() else 0.0))
		if is_active:
			draw_circle(c, 40, GameStyle.PURPLE)
			draw_circle(c + Vector2(0, -6), 30, Color(1, 1, 1, 0.1))
		Icons.draw(self, icon_kind, c, 26.0 if is_active else 22.0)
		var font := _font
		var col := GameStyle.GOLD if is_active else Color(1, 1, 1, 0.7)
		draw_string(font, Vector2(0, size.y - 10), tr(label), HORIZONTAL_ALIGNMENT_CENTER, size.x, 20, col)
		if counter != "":
			var w := font.get_string_size(counter, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x + 16
			var r := Rect2(c + Vector2(14, -44), Vector2(w, 26))
			draw_style_box(_counter_box, r)
			draw_string(font, r.position + Vector2(0, 19), counter, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 18, Color.WHITE)
