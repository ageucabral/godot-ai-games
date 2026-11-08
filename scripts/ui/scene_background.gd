class_name SceneBackground
extends Control
## Fundo animado: a ilustração gerada (assets/art) cobrindo a tela e brilhinhos piscando por cima.
## "sky": céu de fim de tarde (menu do jogo; os brilhos sobem). "night": noite estrelada (partida).
## "hub": vila flutuante ao entardecer (menu Na Lata). "splash": tela de abertura.

const ART := {"sky": "res://assets/art/home_bg.jpg", "night": "res://assets/art/game_bg.jpg", "splash": "res://assets/art/splash.jpg",
	"hub": "res://assets/art/hub_bg.jpg"}

var kind: String = "sky"
var _art: Texture2D
var _time: float = 0.0
var _stars: Array = []  # [posição relativa, tamanho, fase]


func _ready() -> void:
	if ART.has(kind):
		_art = load(ART[kind])
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 14:
		_stars.append([Vector2(rng.randf(), rng.randf()), rng.randf_range(1.2, 3.4), rng.randf() * TAU])


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_time += delta
	queue_redraw()


## Imagem cobrindo a tela toda (corta as sobras, sem deformar) e brilhinhos piscando por cima.
func _draw() -> void:
	if not _art:
		return
	var tex_size := _art.get_size()
	var k := maxf(size.x / tex_size.x, size.y / tex_size.y)
	var draw_size := tex_size * k
	draw_texture_rect(_art, Rect2((size - draw_size) * 0.5, draw_size), false)
	for s: Array in _stars:
		var p: Vector2 = s[0] * size
		if kind == "sky":
			p.y = fposmod(p.y - _time * 14.0 * s[1], size.y)
		var tw := 0.5 + 0.5 * sin(_time * 1.8 + s[2])
		draw_colored_polygon(GameStyle.star_points(p, s[1] * 2.6 * tw + 1.0, s[1] * 0.5, 4), Color(1, 1, 0.9, 0.75 * tw))
