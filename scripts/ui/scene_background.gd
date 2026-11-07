class_name SceneBackground
extends Control
## Fundo animado. "sky": céu de fim de tarde com morros e nuvens andando (menu).
## "night": noite azul com brilho no meio e estrelas piscando (partida).
## "hub": vila flutuante ao entardecer (menu Na Lata). "splash": tela de abertura.
## Usa a ilustração gerada (assets/art) e desenha por cima os brilhos animados.
## Sem a imagem, cai no desenho feito no código.

const ART := {"sky": "res://assets/art/home_bg.jpg", "night": "res://assets/art/game_bg.jpg", "splash": "res://assets/art/splash.jpg",
	"hub": "res://assets/art/hub_bg.jpg"}

var kind: String = "sky"
var _art: Texture2D
var _time: float = 0.0
var _stars: Array = []  # [posição relativa, tamanho, fase]


func _ready() -> void:
	if ART.has(kind) and ResourceLoader.exists(ART[kind]):
		_art = load(ART[kind])
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 70:
		_stars.append([Vector2(rng.randf(), rng.randf()), rng.randf_range(1.2, 3.4), rng.randf() * TAU])


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_time += delta
	queue_redraw()


func _draw() -> void:
	if _art:
		_draw_art()
		return
	if kind == "night":
		_draw_night()
	else:
		_draw_sky()


## Imagem cobrindo a tela toda (corta as sobras, sem deformar) e brilhinhos piscando por cima.
func _draw_art() -> void:
	var tex_size := _art.get_size()
	var k := maxf(size.x / tex_size.x, size.y / tex_size.y)
	var draw_size := tex_size * k
	draw_texture_rect(_art, Rect2((size - draw_size) * 0.5, draw_size), false)
	for s in _stars.slice(0, 14):
		var p: Vector2 = s[0] * size
		if kind == "sky":
			p.y = fposmod(p.y - _time * 14.0 * s[1], size.y)
		var tw := 0.5 + 0.5 * sin(_time * 1.8 + s[2])
		draw_colored_polygon(GameStyle.star_points(p, s[1] * 2.6 * tw + 1.0, s[1] * 0.5, 4), Color(1, 1, 0.9, 0.75 * tw))


func _draw_night() -> void:
	GameStyle.draw_vertical_gradient(self, Rect2(Vector2.ZERO, size), GameStyle.NIGHT_TOP, GameStyle.NIGHT_BOTTOM)
	var c := Vector2(size.x * 0.5, size.y * 0.42)
	for i in 6:
		draw_circle(c, size.x * (0.75 - i * 0.1), Color(0.35, 0.45, 1.0, 0.035))
	for s in _stars:
		var p: Vector2 = s[0] * size
		var tw := 0.45 + 0.55 * (0.5 + 0.5 * sin(_time * 1.6 + s[2]))
		var r: float = s[1]
		if r > 3.0:
			draw_colored_polygon(GameStyle.star_points(p, r * 2.4, r * 0.5, 4), Color(0.75, 0.85, 1.0, tw))
		else:
			draw_circle(p, r * 0.6, Color(0.7, 0.8, 1.0, tw * 0.8))


func _draw_sky() -> void:
	var w := size.x
	var h := size.y
	GameStyle.draw_vertical_gradient(self, Rect2(0, 0, w, h * 0.62), GameStyle.SKY_TOP, GameStyle.SKY_BOTTOM)
	# sol
	var sun := Vector2(w * 0.78, h * 0.34)
	for i in 5:
		draw_circle(sun, 70.0 + i * 26.0, Color(1, 0.9, 0.6, 0.10))
	draw_circle(sun, 56, Color("fff3b0"))
	# nuvens andando
	for i in 5:
		var speed := 8.0 + i * 3.0
		var x := fposmod(i * w * 0.31 + _time * speed, w + 360.0) - 180.0
		_cloud(Vector2(x, h * (0.12 + 0.07 * i)), 0.8 + 0.15 * (i % 3))
	# morros em camadas
	_hill(h * 0.50, Color("7fc36a"), 0.0, 60.0)
	_hill(h * 0.58, Color("5aae47"), 1.7, 80.0)
	_hill(h * 0.70, Color("3f9638"), 3.1, 70.0)
	draw_rect(Rect2(0, h * 0.78, w, h * 0.22), Color("3f9638"))
	# trilha
	var path := PackedVector2Array()
	for i in 21:
		var t := i / 20.0
		path.append(Vector2(w * 0.5 + sin(t * 5.0) * w * 0.18 * (1.0 - t * 0.5), h * (0.52 + t * 0.48)))
	draw_polyline(path, Color("e8cf8a"), 26.0, true)
	# brilhinhos subindo
	for s in _stars.slice(0, 18):
		var p: Vector2 = s[0] * size
		p.y = fposmod(p.y - _time * 18.0 * s[1], h)
		draw_colored_polygon(GameStyle.star_points(p, s[1] * 2.2, s[1] * 0.6, 4), Color(1, 1, 0.85, 0.5 + 0.4 * sin(_time * 2.0 + s[2])))


func _cloud(c: Vector2, k: float) -> void:
	var col := Color(1, 1, 1, 0.85)
	draw_circle(c, 34 * k, col)
	draw_circle(c + Vector2(40, 8) * k, 28 * k, col)
	draw_circle(c + Vector2(-40, 10) * k, 24 * k, col)
	draw_circle(c + Vector2(12, -18) * k, 30 * k, col)


func _hill(base_y: float, col: Color, phase: float, amp: float) -> void:
	var pts := PackedVector2Array()
	pts.append(Vector2(0, size.y))
	for i in 25:
		var x := size.x * i / 24.0
		pts.append(Vector2(x, base_y - amp * (0.5 + 0.5 * sin(i * 0.45 + phase))))
	pts.append(Vector2(size.x, size.y))
	draw_colored_polygon(pts, col)
