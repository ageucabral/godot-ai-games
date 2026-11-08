class_name Prizes
extends RefCounted
## Prêmios pelo servidor: convidar amigos (regra para concorrer), aviso de prêmio ganho e o resgate
## (Pix ou USDT). Os valores e as regras vêm do painel.

const PIX_TYPES := [["cpf", "CPF"], ["email", "E-mail"], ["phone", "Telefone"], ["random", "Chave aleatória"]]


# ---------- convite ----------

static func open_invite(dialog: DialogBox) -> void:
	dialog.open("Carregando…", "", [])
	var res: Dictionary = await Server.call_api("GET", "/challenge")
	if not res.ok:
		Account.show_error(dialog, res, func() -> void: open_invite(dialog))
		return
	var d: Dictionary = res.data
	var code := str(d.get("code", ""))
	var link := str(d.get("link", ""))
	dialog.open("Convidar amigos", invite_text(d), [
		["Compartilhar convite", func() -> void: share_invite(dialog, code, link), true],
		["Voltar", func() -> void: pass],
	])


## Texto da tela de convite (função pura, testada).
static func invite_text(d: Dictionary) -> String:
	var e: Dictionary = d.get("eligibility", {}) if d.get("eligibility") is Dictionary else {}
	var required := int(e.get("required", 3))
	var days := int(e.get("days", 3))
	var valid := int(e.get("valid", 0))
	var lines: Array[String] = []
	if bool(e.get("noPrizeCountry", false)):
		lines.append(I18n.t("Prêmios ainda não estão disponíveis no seu país. Você segue no ranking normalmente."))
	elif bool(e.get("eligible", false)):
		lines.append(I18n.t("Você já pode receber prêmios!"))
	else:
		lines.append(I18n.t("Para receber prêmio, convide %d amigos que joguem pelo menos %d dias.") % [required, days])
		lines.append(I18n.t("Você tem %d de %d.") % [mini(valid, required), required])
	var friends: Variant = d.get("friends")
	if friends is Array and not (friends as Array).is_empty():
		lines.append("")
		for f in (friends as Array).slice(0, 8):
			if f is Dictionary:
				var nick := str(f.get("nickname", "")) if f.get("nickname") != null else I18n.t("Visitante")
				var mark := "✓ " if bool(f.get("valid", false)) else "• "
				lines.append(mark + I18n.t("%s: %d de %d dias") % [nick, mini(int(f.get("daysValid", 0)), days), days])
	lines.append("")
	lines.append(I18n.t("Seu código: %s") % str(d.get("code", "")))
	return "\n".join(lines)


static func share_invite(dialog: DialogBox, code: String, link: String) -> void:
	var text := I18n.t("Jogue o Na Lata comigo e concorra a prêmios! Meu código: %s") % code
	if not link.is_empty():
		text += "\n" + link
	Server.track("invite_shared")
	var plugin := Server.native_with("install_referrer")
	if plugin:
		plugin.share(text)
		return
	DisplayServer.clipboard_set(text)
	dialog.open("Convite copiado", I18n.t("O convite foi copiado. Cole numa conversa para mandar aos amigos."), [
		["Ok", func() -> void: pass, true],
	])


# ---------- prêmio ganho ----------

## Prêmios a resgatar (pendentes) do último menu do servidor.
static func pending_payouts() -> Array:
	var out: Array = []
	var list: Variant = Server.home.get("payouts")
	if list is Array:
		for p in list:
			if p is Dictionary and str(p.get("status", "")) == "pending":
				out.append(p)
	return out


## Aviso "Você ganhou!" com o botão de resgatar.
static func announce(dialog: DialogBox, payout: Dictionary) -> void:
	dialog.open("Você ganhou!", I18n.t("Você ganhou %s no Ranking Global de %s. Resgate até %s.") % [
		str(payout.get("amountLabel", "")), str(payout.get("monthLabel", "")), _short_date(str(payout.get("deadlineAt", "")))], [
		["Resgatar prêmio", func() -> void: open_claim(dialog, str(payout.get("id", ""))), true],
		["Depois", func() -> void: pass],
	])


static func _short_date(iso: String) -> String:
	if iso.length() < 19:
		return iso
	return Rules.pretty_date(Rules.date_for(int(Time.get_unix_time_from_datetime_string(iso.left(19)))))


# ---------- resgate ----------

## Abre o resgate de um prêmio: confere país e forma de receber e mostra o formulário.
static func open_claim(dialog: DialogBox, payout_id: String) -> void:
	if Server.is_guest():
		dialog.open("Resgatar prêmio", I18n.t("Entre com Google para resgatar o prêmio."), [["Ok", func() -> void: pass, true]])
		return
	dialog.open("Carregando…", "", [])
	var res: Dictionary = await Server.call_api("GET", "/payouts/" + payout_id)
	if not res.ok:
		Account.show_error(dialog, res, func() -> void: open_claim(dialog, payout_id))
		return
	var info: Dictionary = res.data
	if str(info.get("status", "")) != "pending":
		dialog.open("Resgatar prêmio", I18n.t("Recebemos seus dados. O pagamento sai em breve."), [["Ok", func() -> void: pass, true]])
		return
	if info.get("country") == null:
		Account.ask_country(dialog, func() -> void: open_claim(dialog, payout_id))
		return
	var methods: Array = info.get("methods", []) if info.get("methods") is Array else []
	if methods.is_empty():
		dialog.open("Resgatar prêmio", I18n.t("Prêmios ainda não estão disponíveis no seu país. Você segue no ranking normalmente."), [
			["Ok", func() -> void: pass, true]])
		return
	if methods.size() == 1:
		_choose_details(dialog, info, str(methods[0]))
		return
	dialog.open("Como quer receber?", I18n.t("Prêmio: %s") % str(info.get("amountLabel", "")), [
		["Pix (em reais)", func() -> void: _choose_details(dialog, info, "pix"), true],
		["USDT (cripto)", func() -> void: _choose_details(dialog, info, "usdt")],
		["Voltar", func() -> void: pass],
	])


## Pix: tipo de chave; USDT: rede. Depois o formulário.
static func _choose_details(dialog: DialogBox, info: Dictionary, method: String) -> void:
	var buttons: Array = []
	var title := "Rede da carteira"
	var text := I18n.t("Use a mesma rede da sua carteira USDT.")
	if method == "pix":
		title = "Tipo da chave Pix"
		text = ""
		for t in PIX_TYPES:
			var kind: String = t[0]
			buttons.append([t[1], func() -> void: _quote_and_form(dialog, info, {"method": "pix", "pixType": kind})])
	else:
		var networks: Array = info.get("usdtNetworks", []) if info.get("usdtNetworks") is Array else []
		for n in networks:
			var net := str(n)
			buttons.append([net, func() -> void: claim_form(dialog, info, {"method": "usdt", "usdtNetwork": net})])
	buttons.append(["Voltar", func() -> void: open_claim(dialog, str(info.id))])
	dialog.open(title, text, buttons)


## Pix: pega a cotação (vale 30 min) antes do formulário.
static func _quote_and_form(dialog: DialogBox, info: Dictionary, form: Dictionary) -> void:
	dialog.open("Carregando…", "", [])
	var q: Dictionary = await Server.call_api("POST", "/payouts/%s/quote" % str(info.id))
	if not q.ok:
		Account.show_error(dialog, q, func() -> void: _quote_and_form(dialog, info, form), "Voltar",
				func() -> void: open_claim(dialog, str(info.id)))
		return
	form["quote"] = q.data
	claim_form(dialog, info, form)


## Valor em reais: 10802 → "R$ 108,02".
static func brl(cents: int) -> String:
	var s := str(absi(cents) / 100)
	var grouped := ""
	while s.length() > 3:
		grouped = "." + s.right(3) + grouped
		s = s.left(s.length() - 3)
	return "R$ %s%s,%02d" % [s, grouped, absi(cents) % 100]


## Formulário do resgate. `form` guarda o que já foi escolhido/digitado (volta preenchido se der erro).
static func claim_form(dialog: DialogBox, info: Dictionary, form: Dictionary, error: String = "") -> void:
	var lines: Array[String] = [I18n.t("Prêmio: %s") % str(info.get("amountLabel", ""))]
	if form.get("quote") is Dictionary:
		lines.append(I18n.t("Você recebe %s no Pix (cotação de hoje).") % brl(int(form.quote.get("brlCents", 0))))
	if bool(info.get("minor", false)):
		lines.append(I18n.t("Como você tem menos de 18 anos, use os dados de um responsável."))
	lines.append(I18n.t("Ao enviar, você aceita o regulamento."))
	dialog.open("Resgatar prêmio", Account.with_error("\n".join(lines), error), [
		["Enviar", func() -> void: pass, true],
		["Ler o regulamento", func() -> void: pass],
		["Cancelar", func() -> void: pass],
	])
	var name_field := dialog.add_input(I18n.t("Nome completo"), str(form.get("fullName", "")), "text", 120) as LineEdit
	var cpf_field: LineEdit = null
	if str(info.get("country", "")) == "BR":
		cpf_field = dialog.add_input(I18n.t("CPF"), str(form.get("cpf", "")), "number", 14) as LineEdit
	var key_field: LineEdit = null
	if form.method == "pix" and form.get("pixType") != "cpf":
		var hint := {"email": "E-mail da chave Pix", "phone": "Telefone da chave Pix", "random": "Chave aleatória"}
		key_field = dialog.add_input(I18n.t(hint.get(form.pixType, "Chave Pix")), str(form.get("pixKey", "")), "text", 120) as LineEdit
	elif form.method == "usdt":
		key_field = dialog.add_input(I18n.t("Endereço da carteira (%s)") % str(form.usdtNetwork), str(form.get("usdtAddress", "")), "text", 120) as LineEdit
	# guarda o que foi digitado (para enviar ou para voltar preenchido depois de ler o regulamento)
	var keep := func() -> void:
		form["fullName"] = name_field.text.strip_edges()
		if cpf_field:
			form["cpf"] = cpf_field.text.strip_edges()
		if key_field:
			form["pixKey" if form.method == "pix" else "usdtAddress"] = key_field.text.strip_edges()
	dialog.set_action(0, func() -> void:
		keep.call()
		_send_claim(dialog, info, form))
	dialog.set_action(1, func() -> void:
		keep.call()
		OS.shell_open(ApiClient.link(Server.config, "regulationFull"))
		claim_form(dialog, info, form))


## Corpo do POST /payouts/:id/claim (função pura, testada).
static func claim_body(form: Dictionary) -> Dictionary:
	var body := {"method": form.method, "fullName": str(form.get("fullName", "")), "accepted": true}
	if form.has("cpf"):
		body["cpf"] = form.cpf
	if form.method == "pix":
		body["pixType"] = form.pixType
		body["pixKey"] = str(form.get("cpf" if form.pixType == "cpf" else "pixKey", ""))
		if form.get("quote") is Dictionary:
			body["quoteId"] = str(form.quote.get("quoteId", ""))
	else:
		body["usdtNetwork"] = form.usdtNetwork
		body["usdtAddress"] = str(form.get("usdtAddress", ""))
	return body


static func _send_claim(dialog: DialogBox, info: Dictionary, form: Dictionary) -> void:
	dialog.open("Enviando…", "", [])
	var res: Dictionary = await Server.call_api("POST", "/payouts/%s/claim" % str(info.id), claim_body(form))
	if res.ok:
		Server.refresh_home()
		dialog.open("Prêmio pedido!", I18n.t("Recebemos seus dados. O pagamento sai em breve."), [["Ok", func() -> void: pass, true]])
		return
	if res.code == "QUOTE_EXPIRED" and res.get("error", {}).get("quote") is Dictionary:
		form["quote"] = res.error.quote
		claim_form(dialog, info, form, "O valor foi atualizado. Confira e envie de novo.")
		return
	if res.code in ["EXPIRED", "ALREADY_SUBMITTED"]:
		dialog.open("Resgatar prêmio", I18n.t(ApiClient.error_text(res)), [["Ok", func() -> void: pass, true]])
		return
	claim_form(dialog, info, form, ApiClient.error_text(res))
