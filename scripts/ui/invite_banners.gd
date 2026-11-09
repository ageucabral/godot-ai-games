class_name InviteBanners
extends RefCounted
## As 3 figuras do convite (Ageu, 9/11/2026): cada uma com a arte do jogo, uma chamada curta e o código
## do jogador bem grande. O jogador escolhe uma e ela vai junto com o texto do convite no "compartilhar".
## São desenhadas no próprio aparelho (SubViewport) e guardadas em user:// para o Android anexar.

const SIZE := Vector2i(1080, 1350)
## [fundo, chamada, mostra o mascote]
const STYLES := [
	["res://assets/art/hub_bg.jpg", "Jogue comigo e concorra a prêmios!", false],
	["res://assets/art/home_bg.jpg", "Duvido você me passar no ranking!", true],
	["res://assets/art/game_bg.jpg", "Separe as cores e ganhe pontos!", false],
]


## Caminho do arquivo da figura `style` (o Android lê daqui para anexar).
static func file_path(style: int) -> String:
	return "user://invite_banner_%d.png" % style


## Desenha a figura `style` com o código e devolve a imagem (null se o aparelho não desenha, como nos testes).
static func render(host: Node, style: int, code: String) -> Image:
	if DisplayServer.get_name() == "headless":
		return null
	var vp := SubViewport.new()
	vp.size = SIZE
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	vp.transparent_bg = false
	vp.add_child(build(style, code))
	host.add_child(vp)
	await RenderingServer.frame_post_draw
	if not is_instance_valid(vp):
		return null  # o convite fechou enquanto desenhava
	var img := vp.get_texture().get_image()
	vp.queue_free()
	return img


## Monta a figura (fundo, "Na Lata", chamada, mascote e o código).
static func build(style: int, code: String) -> Control:
	var spec: Array = STYLES[clampi(style, 0, STYLES.size() - 1)]
	var root := Control.new()
	root.size = Vector2(SIZE)
	root.theme = GameStyle.build_theme()
	var bg := TextureRect.new()
	bg.texture = load(spec[0])
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.size = Vector2(SIZE)
	root.add_child(bg)
	# escurece embaixo para o código ficar legível
	var shade := TextureRect.new()
	var grad := Gradient.new()
	grad.set_color(0, Color(0, 0, 0, 0))
	grad.set_color(1, Color(GameStyle.INK, 0.85))
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.fill_from = Vector2(0, 0.35)
	gt.fill_to = Vector2(0, 1)
	shade.texture = gt
	shade.size = Vector2(SIZE)
	root.add_child(shade)

	var logo := GameStyle.make_title("Na Lata", 150, GameStyle.GOLD)
	logo.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	logo.position = Vector2(0, 60)
	logo.size = Vector2(SIZE.x, 190)
	root.add_child(logo)
	var game_name := GameStyle.make_title(I18n.t("Poção de Cores"), 60)
	game_name.position = Vector2(0, 240)
	game_name.size = Vector2(SIZE.x, 80)
	root.add_child(game_name)

	if spec[2]:
		var mascot := TextureRect.new()
		mascot.texture = load("res://assets/art/mascot.png")
		mascot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		mascot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		mascot.position = Vector2(290, 340)
		mascot.size = Vector2(500, 500)
		root.add_child(mascot)

	var headline := GameStyle.make_title(I18n.t(spec[1]), 72)
	headline.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	headline.position = Vector2(70, 820)
	headline.size = Vector2(SIZE.x - 140, 200)
	headline.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	root.add_child(headline)

	# o código numa pílula creme
	var pill := PanelContainer.new()
	var box := StyleBoxFlat.new()
	box.bg_color = GameStyle.CREAM
	box.border_color = GameStyle.INK
	box.set_border_width_all(8)
	box.border_width_bottom = 16
	box.set_corner_radius_all(48)
	box.set_content_margin_all(18)
	pill.add_theme_stylebox_override("panel", box)
	pill.position = Vector2(140, 1060)
	pill.size = Vector2(SIZE.x - 280, 170)
	root.add_child(pill)
	var pill_box := VBoxContainer.new()
	pill_box.alignment = BoxContainer.ALIGNMENT_CENTER
	pill.add_child(pill_box)
	pill_box.add_child(GameStyle.make_label(I18n.t("Use meu código"), 34, false, GameStyle.ACCENT))
	var code_label := GameStyle.make_label(code, 84, true, GameStyle.INK)
	code_label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	pill_box.add_child(code_label)

	var store := GameStyle.make_label(I18n.t("Grátis na Google Play"), 34, true, Color.WHITE)
	store.position = Vector2(0, 1262)
	store.size = Vector2(SIZE.x, 60)
	root.add_child(store)
	return root


## As 3 miniaturas lado a lado no convite; a escolhida fica com borda dourada.
class Picker extends HBoxContainer:
	var images: Array = [null, null, null]
	var selected: int = 0
	var _buttons: Array[Button] = []

	func _init() -> void:
		alignment = BoxContainer.ALIGNMENT_CENTER
		add_theme_constant_override("separation", 14)
		for i in STYLES.size():
			var b := Button.new()
			b.custom_minimum_size = Vector2(176, 220)
			b.expand_icon = true
			b.focus_mode = Control.FOCUS_NONE
			b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
			b.pressed.connect(func() -> void: select(i))
			add_child(b)
			_buttons.append(b)
		select(0)

	## Desenha as 3 figuras com o código (uma por vez, para não pesar).
	func fill(code: String) -> void:
		for i in STYLES.size():
			var img: Image = await InviteBanners.render(self, i, code)
			if img == null or not is_inside_tree():
				return
			images[i] = img
			var thumb := img.duplicate() as Image
			thumb.resize(176, 220, Image.INTERPOLATE_BILINEAR)
			_buttons[i].icon = ImageTexture.create_from_image(thumb)

	func select(i: int) -> void:
		selected = i
		for j in _buttons.size():
			var box := StyleBoxFlat.new()
			box.bg_color = GameStyle.CREAM
			box.border_color = GameStyle.GOLD if j == i else GameStyle.INK
			box.set_border_width_all(8 if j == i else 3)
			box.set_corner_radius_all(18)
			box.set_content_margin_all(6)
			for state in ["normal", "hover", "pressed", "focus"]:
				_buttons[j].add_theme_stylebox_override(state, box)

	## A figura escolhida (null se ainda não ficou pronta).
	func chosen() -> Image:
		return images[selected]
