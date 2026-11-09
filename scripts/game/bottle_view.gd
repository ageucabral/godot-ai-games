class_name BottleView
extends Control
## Desenha uma garrafinha com suas camadas de líquido e avisa quando é tocada.
## Também sabe se inclinar e derramar (usado pela animação de despejo).

signal tapped(index: int)

const LIFT: float = 34.0
const MOUTH := Vector2(30, 4)       # boca do frasco na grade 60 x 160
const PIVOT := Vector2(30, 80)      # centro de giro ao inclinar
const SPARK_CENTER := Vector2(30, 90)  # de onde saem as estrelinhas do frasco completo
const SURFACE_MAX_Y: float = 138.0  # abaixo daqui o fundo do frasco começa a arredondar

var index: int = 0
var capacity: int = SortPuzzle.CAPACITY
## Camadas do fundo para o topo: [cor, quantidade (1.0 = camada cheia), escondida].
var segments: Array = []:
	set(value):
		segments = value
		queue_redraw()
var selected: bool = false:
	set(value):
		if selected == value:
			return
		selected = value
		_animate_lift()
## Deslocamento e giro usados durante o despejo.
var pour_offset: Vector2 = Vector2.ZERO:
	set(value):
		pour_offset = value
		queue_redraw()
var pour_angle: float = 0.0:
	set(value):
		pour_angle = value
		queue_redraw()
## Filete de líquido caindo da boca até `stream_end` (posição global).
var stream_on: bool = false:
	set(value):
		stream_on = value
		queue_redraw()
var stream_color: Color = Color.WHITE
var stream_end: Vector2 = Vector2.ZERO

## Pano por cima da garrafa coberta: cor que a abre (-1 = sem pano) e quanto do pano ainda aparece
## (1 = cobre tudo, 0 = já saiu). Ao abrir, o pano sobe e some.
var cover_key: int = -1:
	set(value):
		cover_key = value
		queue_redraw()
var cover_amount: float = 0.0:
	set(value):
		cover_amount = value
		queue_redraw()
var _cover_tween: Tween

## Garrafa de gelo: quantas jogadas faltam para derreter (0 = sem gelo).
var ice_left: int = 0:
	set(value):
		ice_left = value
		queue_redraw()
## Garrafa de uma cor só: a cor que ela aceita (-1 = qualquer).
var only_color: int = -1:
	set(value):
		only_color = value
		queue_redraw()

## Frasco escolhido pelo jogador (formato e borda; veja GameStyle.SKIN_EDGES).
var skin: String = "classic":
	set(value):
		skin = value if GameStyle.SKIN_EDGES.has(value) else "classic"
		queue_redraw()

## Setinha "toque aqui" em cima do frasco (primeira partida guiada). Balança sozinha.
var hint: bool = false:
	set(value):
		hint = value
		set_process(hint)
		queue_redraw()
var _hint_time: float = 0.0

var _lift: float = 0.0:
	set(value):
		_lift = value
		queue_redraw()
var _tween: Tween
## Festa de frasco completo (0 → 1): brilho da cor, pulinho e estrelinhas saindo da boca.
var _done_t: float = -1.0:
	set(value):
		_done_t = value
		queue_redraw()
var _done_color: Color = Color.WHITE


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_process(hint)
	if custom_minimum_size == Vector2.ZERO:
		set_bottle_width(108.0)


func _process(delta: float) -> void:
	_hint_time += delta
	queue_redraw()


func set_bottle_width(w: float) -> void:
	custom_minimum_size = Vector2(w, w * GameStyle.DESIGN_SIZE.y / GameStyle.DESIGN_SIZE.x + LIFT)


## Monta as camadas a partir de uma garrafa do quebra-cabeça.
static func segments_from(tube: Array, hidden: Array) -> Array:
	var out: Array = []
	for i in tube.size():
		out.append([tube[i], 1.0, hidden[i] if i < hidden.size() else false])
	return out


## Só o clique conta. No celular o toque vira clique sozinho (emulate_mouse_from_touch);
## contar o toque E o clique fazia a garrafa ser escolhida e solta no mesmo instante.
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		tapped.emit(index)
		accept_event()


## Cobre (true) ou descobre (false) a garrafa. Descobrir anima o pano subindo, se `animated`.
func set_covered(covered: bool, animated: bool = true) -> void:
	if covered:
		if _cover_tween:
			_cover_tween.kill()
		cover_amount = 1.0
		return
	if cover_amount <= 0.0 or (_cover_tween and _cover_tween.is_running()):
		return
	if not animated or not is_inside_tree():
		cover_amount = 0.0
		return
	_cover_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_cover_tween.tween_property(self, "cover_amount", 0.0, 0.6)


## Frasco ficou completo: pulinho, brilho da cor do líquido e estrelinhas saindo da boca.
func celebrate(color: int) -> void:
	_done_color = GameStyle.liquid_color(color)
	if not is_inside_tree():
		return
	z_index = 5  # estrelinhas por cima dos frascos vizinhos
	var t := create_tween()
	t.tween_property(self, "_done_t", 1.0, 0.9).from(0.0)
	t.tween_property(self, "_done_t", -1.0, 0.0)
	t.tween_property(self, "z_index", 0, 0.0)
	# o pulinho usa o mesmo `_tween` da subida: tocar no frasco no meio dele não deixa os dois brigando pelo `_lift`
	if _tween:
		_tween.kill()
	_tween = create_tween().set_trans(Tween.TRANS_SINE)
	_tween.tween_property(self, "_lift", LIFT * 0.6, 0.14).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "_lift", 0.0, 0.32).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)


## Posição (grade 60 x 160) e tamanho da estrelinha `i` de `n` no instante `t` da festa: saem do meio do frasco
## para todos os lados (ficam em volta dele, sem invadir o placar lá em cima).
static func done_spark(i: int, n: int, t: float) -> Array:
	var a := -PI * 0.5 + TAU * float(i) / n
	var dist := 24.0 + 46.0 * ease(t, 0.4)
	return [SPARK_CENTER + Vector2(cos(a) * 0.9, sin(a) * 1.3) * dist, 10.0 * (1.0 - t * 0.6)]


## Balança de leve quando a jogada não é permitida.
func shake() -> void:
	var t := create_tween()
	for dx in [-10.0, 10.0, -6.0, 6.0, 0.0]:
		t.tween_property(self, "pour_offset:x", dx, 0.04)


func _animate_lift() -> void:
	if _tween:
		_tween.kill()
	if not is_inside_tree():
		_lift = LIFT if selected else 0.0
		return
	_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "_lift", LIFT if selected else 0.0, 0.18)


func design_scale() -> float:
	return minf(size.x / GameStyle.DESIGN_SIZE.x, (size.y - LIFT) / GameStyle.DESIGN_SIZE.y)


## Transformação da grade 60 x 160 para a posição local (com elevação, giro e deslocamento).
func design_transform(angle: float = pour_angle, offset: Vector2 = pour_offset, lift: float = _lift) -> Transform2D:
	var s := design_scale()
	var origin := Vector2((size.x - GameStyle.DESIGN_SIZE.x * s) * 0.5, LIFT - lift)
	var pivot := PIVOT * s
	return Transform2D(0.0, origin + pivot + offset) * Transform2D(angle, Vector2.ZERO) \
		* Transform2D(0.0, -pivot) * Transform2D(0.0, Vector2(s, s), 0.0, Vector2.ZERO)


## Posição global da boca da garrafa para um giro/deslocamento.
func mouth_global(angle: float = 0.0, offset: Vector2 = Vector2.ZERO, lift: float = _lift) -> Vector2:
	return get_global_transform() * (design_transform(angle, offset, lift) * MOUTH)


## Posição global da superfície do líquido (onde o filete encosta).
func surface_global() -> Vector2:
	var level := 0.0
	for seg in segments:
		level += seg[1]
	var y := GameStyle.LIQUID_BOTTOM - level * layer_height()
	return get_global_transform() * (design_transform(0.0, Vector2.ZERO, 0.0) * Vector2(30, y))


func layer_height() -> float:
	return (GameStyle.LIQUID_BOTTOM - GameStyle.LIQUID_TOP) / float(capacity)


func _draw() -> void:
	var xf := design_transform()
	draw_set_transform_matrix(xf)
	var outline := GameStyle.bottle_outline(skin)

	# brilho azul atrás do frasco escolhido
	if _lift > 1.0:
		draw_circle(Vector2(30, 96), 40, Color(0.55, 0.8, 1.0, 0.10 * _lift / LIFT))

	if _done_t >= 0.0:
		# brilho da cor do líquido atrás do frasco, que acende e apaga
		var glow := sin(_done_t * PI)
		draw_circle(Vector2(30, 92), 58, Color(_done_color, 0.22 * glow))
		draw_circle(Vector2(30, 92), 42, Color(_done_color.lightened(0.3), 0.25 * glow))
	draw_colored_polygon(outline, GameStyle.GLASS)
	var h := layer_height()
	var level := 0.0
	var font := GameStyle.title_font()
	var top_col: Color = Color.WHITE
	for seg in segments:
		var amount: float = seg[1]
		if amount <= 0.001:
			continue
		var y_bottom := GameStyle.LIQUID_BOTTOM - level * h
		var y_top := GameStyle.LIQUID_BOTTOM - (level + amount) * h
		var col: Color = GameStyle.HIDDEN_LAYER if seg[2] else GameStyle.liquid_color(seg[0])
		top_col = col  # cor da camada de cima que aparece de verdade (ignora as vazias do despejo)
		var band := GameStyle.band_polygons(y_top, y_bottom + 0.5, skin)
		for poly in band:
			draw_colored_polygon(poly, col)
		# sombra na lateral direita (volume)
		for poly in band:
			var shade := PackedVector2Array()
			for v in poly:
				shade.append(Vector2(maxf(v.x, 44.0), v.y))
			draw_colored_polygon(shade, Color(0, 0, 0, 0.14))
		if seg[2] and amount > 0.6:
			draw_string(font, Vector2(0, (y_top + y_bottom) * 0.5 + 8), "?", HORIZONTAL_ALIGNMENT_CENTER, 60, 22, Color("c9c3ff"))
		level += amount
	var surface_y := GameStyle.LIQUID_BOTTOM - level * h
	# superfície do líquido (elipse clara, dá a ideia de cilindro); perto do fundo arredondado
	# a elipse sairia para fora do vidro, então só aparece onde o corpo do frasco é reto
	if level > 0.01 and surface_y <= SURFACE_MAX_Y:
		var y := surface_y
		draw_set_transform_matrix(xf * Transform2D(0.0, Vector2(1.0, 0.22), 0.0, Vector2(0, y * 0.78)))
		draw_circle(Vector2(30, y), 23, top_col.lightened(0.28))
		draw_set_transform_matrix(xf)

	# reflexos do vidro
	draw_rect(Rect2(11, 50, 4, 70), Color(1, 1, 1, 0.35))
	draw_rect(Rect2(11, 126, 4, 10), Color(1, 1, 1, 0.25))
	draw_rect(Rect2(24, 6, 3, 14), Color(1, 1, 1, 0.35))

	var closed := outline.duplicate()
	closed.append(outline[0])
	var skin_edge: Color = GameStyle.SKIN_EDGES[skin]
	var edge: Color = skin_edge if only_color < 0 else GameStyle.liquid_color(only_color).lightened(0.25)
	draw_polyline(closed, Color(edge, 0.35), 6.0, true)
	draw_polyline(closed, edge, 2.4 if only_color < 0 else 3.6, true)
	if only_color >= 0:
		# selo da cor aceita, no pé do frasco
		draw_circle(Vector2(30, 150), 9, GameStyle.liquid_color(only_color))
		draw_arc(Vector2(30, 150), 9, 0, TAU, 20, GameStyle.INK, 2.5, true)
	# borda do gargalo
	draw_rect(Rect2(18, 3, 24, 6), Color("8a5a10") if skin == "golden" else Color("2a3a7a"))
	draw_rect(Rect2(18, 3, 24, 6), skin_edge, false, 2.0)
	if skin == "heart":
		# coraçãozinho no gargalo
		draw_circle(Vector2(27.5, 30), 3.2, skin_edge)
		draw_circle(Vector2(32.5, 30), 3.2, skin_edge)
		draw_colored_polygon(PackedVector2Array([Vector2(24.4, 31), Vector2(35.6, 31), Vector2(30, 37)]), skin_edge)

	if _done_t >= 0.0:
		var glow := sin(_done_t * PI)
		draw_polyline(closed, Color(_done_color.lightened(0.45), glow), 6.0, true)
		const SPARKS := 7
		for i in SPARKS:
			var sp := done_spark(i, SPARKS, _done_t)
			GameStyle.draw_star(self, sp[0], sp[1], true, Color(0, 0, 0, 0))
	if cover_amount > 0.0 and cover_key >= 0:
		_draw_cover(xf)
	if ice_left > 0:
		_draw_ice()

	draw_set_transform_matrix(Transform2D.IDENTITY)
	if hint:
		var tip := xf * MOUTH + Vector2(0, -14.0 - 10.0 * absf(sin(_hint_time * 4.0)))
		var s := 20.0 * design_scale()
		var arrow := PackedVector2Array([tip, tip + Vector2(-s, -s * 1.1), tip + Vector2(-s * 0.4, -s * 1.1),
			tip + Vector2(-s * 0.4, -s * 2.2), tip + Vector2(s * 0.4, -s * 2.2), tip + Vector2(s * 0.4, -s * 1.1), tip + Vector2(s, -s * 1.1)])
		draw_colored_polygon(arrow, GameStyle.GOLD)
		var ring := arrow.duplicate()
		ring.append(arrow[0])
		draw_polyline(ring, GameStyle.INK, 4.0, true)
	if stream_on:
		var from := xf * MOUTH
		var to := get_global_transform().affine_inverse() * stream_end
		var w := 7.0 * design_scale()
		draw_line(from, Vector2(from.x, to.y), stream_color, w, true)
		draw_circle(from, w * 0.5, stream_color)


## Gelo por cima do frasco, com o número de jogadas que faltam para derreter.
func _draw_ice() -> void:
	var ice := PackedVector2Array()
	for p in GameStyle.bottle_outline(skin):
		ice.append(Vector2(30 + (p.x - 30) * 1.08, p.y))
	draw_colored_polygon(ice, Color(0.82, 0.94, 1.0, 0.78))
	for x in [14.0, 26.0, 40.0]:
		draw_line(Vector2(x, 46), Vector2(x + 8, 70), Color(1, 1, 1, 0.8), 2.0, true)
	var closed := ice.duplicate()
	closed.append(ice[0])
	draw_polyline(closed, Color("6fb6ff"), 2.4, true)
	var font := GameStyle.title_font()
	var y := 104.0
	draw_string_outline(font, Vector2(0, y), str(ice_left), HORIZONTAL_ALIGNMENT_CENTER, 60, 34, 6, Color.WHITE)
	draw_string(font, Vector2(0, y), str(ice_left), HORIZONTAL_ALIGNMENT_CENTER, 60, 34, Color("1b4f9a"))


## Pano claro por cima do frasco, com dobras e um selo com a garrafinha da cor que o abre.
## Ao sair, sobe e fica transparente.
func _draw_cover(xf: Transform2D) -> void:
	var a := cover_amount
	var rise := (1.0 - a) * -50.0
	draw_set_transform_matrix(xf * Transform2D(0.0, Vector2(0, rise)))
	var cloth := PackedVector2Array()
	for p in GameStyle.bottle_outline(skin):
		cloth.append(Vector2(30 + (p.x - 30) * 1.12, p.y - 2))
	draw_colored_polygon(cloth, Color(0.96, 0.9, 0.93, a))
	# dobras do pano
	for x in [16.0, 30.0, 44.0]:
		draw_line(Vector2(x, 40), Vector2(x + 2, 150), Color(0.8, 0.68, 0.75, 0.7 * a), 2.0, true)
	var closed := cloth.duplicate()
	closed.append(cloth[0])
	draw_polyline(closed, Color(0.55, 0.42, 0.55, a), 2.0, true)
	# selo com a garrafinha da cor-chave
	var c := Vector2(30, 92)
	draw_circle(c, 17, Color(1, 1, 1, a))
	draw_arc(c, 17, 0, TAU, 24, Color(GameStyle.INK, a), 2.5, true)
	draw_set_transform_matrix(xf * Transform2D(0.0, Vector2(0, rise)) * Transform2D(0.0, Vector2(0.17, 0.17), 0.0, c - Vector2(30, 80) * 0.17))
	var icon := GameStyle.bottle_outline()
	var col := GameStyle.liquid_color(cover_key)
	draw_colored_polygon(icon, Color(col, a))
	var icon_closed := icon.duplicate()
	icon_closed.append(icon[0])
	draw_polyline(icon_closed, Color(GameStyle.INK, a), 10.0, true)
	draw_set_transform_matrix(xf)
