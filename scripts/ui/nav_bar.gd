class_name NavBar
extends Control
## Barra de baixo da tela do jogo: Jogos · Ranking · Início · Desafios · Perfil.
## A aba ativa fica maior e mais alta, com o nome embaixo.

signal tab_pressed(tab: String)

const TABS: Array = [["games", "Jogos", "games"], ["ranking", "Ranking", "trophy"], ["home", "Início", "home"],
	["daily", "Desafios", "calendar"], ["profile", "Perfil", "avatar"]]

var active: String = "home"
var buttons: Dictionary = {}


func _init() -> void:
	custom_minimum_size = Vector2(0, 150)


func _ready() -> void:
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.add_theme_constant_override("separation", 0)
	add_child(row)
	for t in TABS:
		var b := _Tab.new()
		b.tab = t[0]
		b.label = t[1]
		b.icon_kind = t[2]
		b.is_active = t[0] == active
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.size_flags_stretch_ratio = 1.4 if t[0] == active else 1.0
		var id: String = t[0]
		b.pressed.connect(func() -> void: tab_pressed.emit(id))
		row.add_child(b)
		buttons[id] = b


func _draw() -> void:
	var bar := Rect2(Vector2(0, 30), Vector2(size.x, size.y - 30))
	GameStyle.draw_vertical_gradient(self, bar, Color("7b4ff0"), Color("4b25b8"))
	draw_rect(Rect2(bar.position, Vector2(size.x, 6)), GameStyle.GOLD)
	draw_line(bar.position, Vector2(size.x, bar.position.y), GameStyle.INK, 3.0)


class _Tab extends Button:
	var tab: String = ""
	var label: String = ""
	var icon_kind: String = ""
	var is_active: bool = false

	func _init() -> void:
		flat = true
		focus_mode = Control.FOCUS_NONE

	func _draw() -> void:
		var font := GameStyle.title_font()
		if is_active:
			var r := Rect2(Vector2(6, 0), Vector2(size.x - 12, size.y))
			var sb := StyleBoxFlat.new()
			sb.bg_color = Color("9a6bff")
			sb.border_color = GameStyle.GOLD
			sb.set_border_width_all(5)
			sb.corner_radius_top_left = 30
			sb.corner_radius_top_right = 30
			draw_style_box(sb, r)
			Icons.draw(self, icon_kind, Vector2(size.x * 0.5, 62), 34.0)
			var text := tr(label)
			draw_string_outline(font, Vector2(0, size.y - 18), text, HORIZONTAL_ALIGNMENT_CENTER, size.x, 30, 8, GameStyle.INK)
			draw_string(font, Vector2(0, size.y - 18), text, HORIZONTAL_ALIGNMENT_CENTER, size.x, 30, Color.WHITE)
		else:
			draw_line(Vector2(size.x, 44), Vector2(size.x, size.y - 10), Color(0, 0, 0, 0.25), 3.0)
			Icons.draw(self, icon_kind, Vector2(size.x * 0.5, 90 + (4.0 if is_pressed() else 0.0)), 28.0)
