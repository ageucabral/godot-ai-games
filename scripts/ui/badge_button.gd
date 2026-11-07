class_name BadgeButton
extends Button
## Selo redondo na tela inicial (ex.: ranking, desafios do dia): ícone num círculo, uma faixa
## com o texto embaixo e, se houver, a contagem num balão. Balança de leve.

var icon_kind: String = "podium"
var caption: String = "":
	set(value):
		caption = value
		queue_redraw()
var counter: String = "":
	set(value):
		counter = value
		queue_redraw()
var ring: Color = Color("f2a93b")
var _time: float = 0.0
## Faixa do texto: criada uma vez (o selo redesenha a cada quadro por causa do balanço).
var _caption_box: StyleBoxFlat = _make_caption_box()


func _init(kind: String = "podium") -> void:
	icon_kind = kind
	flat = true
	focus_mode = Control.FOCUS_NONE
	custom_minimum_size = Vector2(150, 160)


func _process(delta: float) -> void:
	if is_visible_in_tree():
		_time += delta
		queue_redraw()


func _draw() -> void:
	var bob := sin(_time * 2.0) * 3.0
	var c := Vector2(size.x * 0.5, 62 + bob)
	draw_circle(c + Vector2(0, 5), 58, Color(0, 0, 0, 0.25))
	draw_circle(c, 58, GameStyle.INK)
	draw_circle(c, 53, ring)
	draw_circle(c, 44, Color("5b3cc4"))
	draw_circle(c + Vector2(0, -12), 34, Color(1, 1, 1, 0.12))
	Icons.draw(self, icon_kind, c + Vector2(0, 4), 30.0)
	var font := GameStyle.title_font()
	if counter != "":
		var bc := c + Vector2(0, 16)
		draw_string_outline(font, bc + Vector2(-60, 10), counter, HORIZONTAL_ALIGNMENT_CENTER, 120, 28, 8, GameStyle.INK)
		draw_string(font, bc + Vector2(-60, 10), counter, HORIZONTAL_ALIGNMENT_CENTER, 120, 28, Color.WHITE)
	if caption != "":
		var r := Rect2(Vector2(6, 104 + bob), Vector2(size.x - 12, 40))
		draw_style_box(_caption_box, r)
		draw_string_outline(font, r.position + Vector2(0, 29), caption, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 24, 6, GameStyle.INK)
		draw_string(font, r.position + Vector2(0, 29), caption, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 24, Color.WHITE)


static func _make_caption_box() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("3d5bd9")
	sb.border_color = GameStyle.INK
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(12)
	return sb
