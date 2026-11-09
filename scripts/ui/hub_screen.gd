extends Control
## Hub Na Lata: o cartão do evento no ar (com a trilha de prêmios), a faixa da competição do mês (abre o Ranking
## Global, o que vale prêmios) e a lista de jogos. O primeiro jogo é o Poção de Cores; os outros chegam depois.

signal game_requested(game_id: String)
signal global_ranking_requested
signal event_requested

## [id, nome, liberado, ilustração]. Um jogo não liberado aparece com cadeado ("Em breve"); embaixo da
## lista fica sempre o aviso discreto "Mais jogos em breve".
const GAMES: Array = [["potion", "Poção de Cores", true, "res://assets/art/potion_card.jpg"]]

var rank_banner: GlobalRankBanner
var event_card: EventCard
var cards: Dictionary = {}
var dialog: DialogBox
## Mês mostrado agora: quando vira o mês, os pontos voltam a zero junto com a contagem.
var _month: String = ""


func _ready() -> void:
	theme = GameStyle.build_theme()
	GameStyle.add_background(self, "hub")
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 28
	box.offset_right = -28
	box.offset_top = 40
	box.offset_bottom = -40
	box.add_theme_constant_override("separation", 18)
	add_child(box)

	# só a engrenagem em cima
	var gear := IconButton.new("gear")
	gear.size_flags_horizontal = Control.SIZE_SHRINK_END
	gear.pressed.connect(func() -> void: Menus.open_settings(dialog))
	box.add_child(gear)

	var logo := GameStyle.make_title("Na Lata", 140, GameStyle.GOLD)
	logo.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	box.add_child(logo)

	event_card = EventCard.new()
	event_card.visible = false
	event_card.pressed.connect(func() -> void: event_requested.emit())
	box.add_child(event_card)

	rank_banner = GlobalRankBanner.new()
	rank_banner.pressed.connect(func() -> void: global_ranking_requested.emit())
	box.add_child(rank_banner)
	box.add_child(GameStyle.make_title("Jogos", 38))

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
		card.art_path = g[3]
		var id: String = g[0]
		if g[2]:
			card.pressed.connect(func() -> void: game_requested.emit(id))
		list.add_child(card)
		cards[id] = card
	var soon := GameStyle.make_label("Mais jogos em breve", 26, false, Color(1, 1, 1, 0.75))
	list.add_child(soon)

	dialog = DialogBox.new()
	add_child(dialog)
	GameState.progress_changed.connect(refresh)
	refresh()
	var timer := Timer.new()
	timer.wait_time = 1.0
	timer.autostart = true
	timer.timeout.connect(_update_countdown)
	add_child(timer)


## A faixa mostra quanto falta para o mês (e a competição) acabar.
func refresh() -> void:
	_month = Rules.month_for(GameState.now_unix())
	var ev: Variant = GameState.extras.get("event")
	event_card.set_event(ev if ev is Dictionary and Server.online() else null)
	_update_countdown()
	for c in cards.values():
		c.queue_redraw()


func _update_countdown() -> void:
	if Rules.month_for(GameState.now_unix()) != _month:
		refresh()
		return
	rank_banner.countdown = Rules.short_countdown(Rules.seconds_to_month_end(GameState.now_unix()))
	if event_card.visible:
		event_card.update_countdown()
