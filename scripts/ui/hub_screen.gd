extends Control
## Hub Na Lata: a lista de jogos. O primeiro é o Poção de Cores; os outros chegam depois.

signal game_requested(game_id: String)

## [id, nome, liberado]
const GAMES: Array = [["potion", "Poção de Cores", true], ["soon_1", "Novo jogo", false], ["soon_2", "Novo jogo", false]]

var points_label: Label
var cards: Dictionary = {}
var dialog: DialogBox


func _ready() -> void:
	theme = GameStyle.build_theme()
	GameStyle.add_background(self, "night")
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 28
	box.offset_right = -28
	box.offset_top = 40
	box.offset_bottom = -40
	box.add_theme_constant_override("separation", 22)
	add_child(box)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 18)
	box.add_child(top)
	var avatar := IconButton.new("avatar")
	avatar.pressed.connect(func() -> void: Menus.open_profile(dialog))
	top.add_child(avatar)
	var out: Array = []
	top.add_child(Menus.make_coin_pill(out))
	points_label = out[0]
	var space := Control.new()
	space.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(space)
	var gear := IconButton.new("gear")
	gear.pressed.connect(func() -> void: Menus.open_settings(dialog))
	top.add_child(gear)

	var logo := GameStyle.make_title("Na Lata", 150, GameStyle.GOLD)
	logo.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	box.add_child(logo)
	box.add_child(GameStyle.make_title("Escolha um jogo", 34))

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 26)
	scroll.add_child(list)
	for g in GAMES:
		var card := GameCard.new()
		card.game_name = g[1]
		card.locked = not g[2]
		var id: String = g[0]
		if g[2]:
			card.pressed.connect(func() -> void: game_requested.emit(id))
		list.add_child(card)
		cards[id] = card

	dialog = DialogBox.new()
	add_child(dialog)
	GameState.progress_changed.connect(refresh)
	refresh()


func refresh() -> void:
	points_label.text = str(GameState.month_total(Rules.month_for(GameState.now_unix())).points)
	for c in cards.values():
		c.queue_redraw()
