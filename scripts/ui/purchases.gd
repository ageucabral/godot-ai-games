class_name Purchases
extends RefCounted
## "Remover anúncios": compra única pelo Google Play (plugin Android), confirmada pelo servidor (`POST /purchases`) e
## guardada na conta. Sem anúncio entre níveis, e as ajudas pulam o vídeo (continuam custando pontos). Nunca vende
## vantagem no jogo (o ranking tem prêmio em dinheiro).

const PRODUCT := "remove_ads"

## Preço formatado pela Play ("R$ 19,90"); vazio enquanto a loja não respondeu.
static var price: String = ""
## Janela que abriu a compra (para mostrar o resultado nela).
static var _dialog: DialogBox = null


## O plugin com a loja (null na Web, nos testes sem plugin e em plugins antigos).
static func plugin() -> Object:
	return Server.native_with("billing_ready") if Server.enabled else null


## Dá para oferecer a compra: loja pronta, servidor no ar e ainda não comprou.
static func available() -> bool:
	return plugin() != null and Server.online() and not Server.ads_free() and not price.is_empty()


## Liga a loja depois de entrar no servidor: pega o preço e restaura uma compra já feita neste Google (`purchase_found`).
static func start() -> void:
	var p := plugin()
	if p == null:
		return
	if not p.billing_ready.is_connected(_on_billing_ready):
		p.billing_ready.connect(_on_billing_ready)
		p.purchase_found.connect(_on_purchase_found)
		p.purchase_done.connect(_on_purchase_done)
	p.billingInit(PRODUCT)


static func _on_billing_ready(ok: bool, text: String) -> void:
	price = text if ok else ""


static func open(dialog: DialogBox) -> void:
	_dialog = dialog
	dialog.open_card("Remover anúncios", I18n.t("Sem anúncio entre níveis, e as ajudas não pedem mais vídeo (continuam custando pontos).\nCompra única, guardada na sua conta."), [
		[I18n.t("Comprar por %s") % price, func() -> void: _buy(dialog), true],
		["Voltar", func() -> void: _done(); Menus.open_settings(dialog)],
	])


static func _buy(dialog: DialogBox) -> void:
	dialog.open("Remover anúncios", "Abrindo a loja do Google Play…", [["Voltar", func() -> void: _done(); Menus.open_settings(dialog)]])
	plugin().buy(PRODUCT, str(Server.profile.get("id", "")))


## O fluxo de compra acabou: um resultado que chegue depois (pagamento pendente que concluiu) não abre janela nenhuma.
static func _done() -> void:
	_dialog = null


## Compra já feita neste Google (ao abrir o app, ou "já comprado" ao tentar comprar de novo): manda ao servidor.
static func _on_purchase_found(product: String, token: String) -> void:
	if _dialog == null and Server.ads_free():
		return  # já está restaurada; não vale a pena pedir ao servidor de novo a cada abertura
	_confirm(product, token, _dialog)


static func _on_purchase_done(product: String, token: String, error: String) -> void:
	var dialog := _dialog
	match error:
		"":
			_confirm(product, token, dialog)
		"owned":
			plugin().billingInit(PRODUCT)  # já tinha comprado: a loja avisa com `purchase_found` e o servidor restaura
		"cancelled":
			_done()
			if dialog:
				Menus.open_settings(dialog)
		"pending":
			_done()
			if dialog:
				dialog.open("Quase lá", "Pagamento pendente. Quando o Google Play confirmar, os anúncios somem sozinhos.", [["Fechar", func() -> void: pass, true]])
		_:
			_done()
			if dialog:
				dialog.open("Ops!", "Não deu para concluir a compra. Tente de novo mais tarde.", [["Fechar", func() -> void: pass, true]])


## Manda o token ao servidor; aceito, confirma para a Play e atualiza o menu (`adsFree` no /pocao/home).
static func _confirm(product: String, token: String, dialog: DialogBox) -> void:
	var res: Dictionary = await Server.call_api("POST", "/purchases", {"productId": product, "purchaseToken": token})
	_done()
	if res.ok:
		plugin().acknowledgePurchase(token)
		await Server.refresh_home()
		if dialog:
			dialog.open("Pronto!", "Sem anúncios. Bom jogo!", [["Legal!", func() -> void: pass, true]])
	elif dialog:
		var text := "Não deu para confirmar a compra. Tente de novo em instantes: ela fica guardada no Google Play."
		if res.code == "PURCHASE_TAKEN":
			text = "Esta compra já está em outra conta do Na Lata. Entre com a conta que comprou para ficar sem anúncios."
		dialog.open("Ops!", text, [["Fechar", func() -> void: pass, true]])
