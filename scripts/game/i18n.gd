class_name I18n
extends RefCounted
## Idiomas do jogo. O texto em português é a "chave"; aqui ficam as versões em inglês e espanhol.
## Os textos fixos das telas traduzem sozinhos; textos montados com números usam tr("...") % valores.

const DEFAULT := "pt"
## [código, nome mostrado na lista]
const LANGUAGES: Array = [["pt", "Português"], ["en", "English"], ["es", "Español"]]

## "texto em português": [inglês, espanhol]
const STRINGS := {
	# menu e telas
	"Nível %d": ["Level %d", "Nivel %d"],
	"Desafios do dia": ["Daily challenges", "Desafíos del día"],
	"Hoje, %s": ["Today, %s", "Hoy, %s"],
	"%d de %d": ["%d of %d", "%d de %d"],
	"Jogar desafio %d": ["Play challenge %d", "Jugar desafío %d"],
	"Todos resolvidos!": ["All solved!", "¡Todos resueltos!"],
	"Seus pontos em %s: %d": ["Your points in %s: %d", "Tus puntos en %s: %d"],
	"Novos desafios em %dh %02dmin": ["New challenges in %dh %02dmin", "Nuevos desafíos en %dh %02dmin"],
	"Voltar": ["Back", "Volver"],
	"Ranking Global": ["Global Ranking", "Ranking Global"],
	"Ranking do %s": ["%s ranking", "Ranking de %s"],
	"%s · termina em %d dias · zera no dia 1": ["%s · ends in %d days · resets on day 1", "%s · termina en %d días · se reinicia el día 1"],
	"Vale prêmios!": ["Win prizes!", "¡Gana premios!"],
	"Vale prêmios! Soma os pontos de todos os jogos do Na Lata.": [
		"Win prizes! Adds up your points from every Na Lata game.",
		"¡Gana premios! Suma los puntos de todos los juegos de Na Lata."],
	"Você": ["You", "Tú"],
	"%d pts": ["%d pts", "%d pts"],
	"%d jogadas no mês": ["%d moves this month", "%d jugadas en el mes"],
	"Pontos por jogo": ["Points per game", "Puntos por juego"],
	"%d desafios e %d níveis · %d jogadas": ["%d challenges and %d levels · %d moves", "%d desafíos y %d niveles · %d jugadas"],
	"Empate: fica na frente quem usou menos jogadas. A lista com todos os jogadores chega com as contas.": [
		"Tie: fewer moves goes first. The list with every player arrives with accounts.",
		"Empate: va primero quien usó menos jugadas. La lista con todos los jugadores llega con las cuentas."],
	"Os prêmios saem do Ranking Global, no menu do Na Lata.": [
		"Prizes come from the Global Ranking, in the Na Lata menu.",
		"Los premios salen del Ranking Global, en el menú de Na Lata."],
	"Fácil": ["Easy", "Fácil"],
	"Médio": ["Medium", "Medio"],
	"Difícil": ["Hard", "Difícil"],
	"%s · %d pts": ["%s · %d pts", "%s · %d pts"],
	# perfil e configurações
	"Seu perfil": ["Your profile", "Tu perfil"],
	"Nível atual: %d\nPontos em %s: %d\nDesafios de hoje: %d de %d": [
		"Current level: %d\nPoints in %s: %d\nToday's challenges: %d of %d",
		"Nivel actual: %d\nPuntos en %s: %d\nDesafíos de hoy: %d de %d"],
	"Configurações": ["Settings", "Ajustes"],
	"Versão %s": ["Version %s", "Versión %s"],
	"Idioma: %s": ["Language: %s", "Idioma: %s"],
	"Idioma": ["Language", "Idioma"],
	"Escolha o idioma do jogo.": ["Choose the game language.", "Elige el idioma del juego."],
	"Salvar progresso": ["Save progress", "Guardar progreso"],
	"Em breve você poderá entrar com Google ou Facebook para guardar seu progresso e aparecer no ranking com todos os jogadores.": [
		"Soon you will be able to sign in with Google or Facebook to keep your progress and appear in the ranking with every player.",
		"Pronto podrás entrar con Google o Facebook para guardar tu progreso y aparecer en el ranking con todos los jugadores."],
	"Entrar com Google (em breve)": ["Sign in with Google (soon)", "Entrar con Google (pronto)"],
	"Entrar com Facebook (em breve)": ["Sign in with Facebook (soon)", "Entrar con Facebook (pronto)"],
	"Como jogar": ["How to play", "Cómo jugar"],
	"Toque numa garrafa e depois em outra para despejar. Só dá para despejar em cima da mesma cor ou numa garrafa vazia. Deixe cada garrafa com uma cor só.\n\nNíveis: sem fim, cada vez mais difíceis, valem %d pontos cada.\nDesafios do dia: 20 novos à meia-noite, valem 10, 25 ou 50 pontos.\nCada jogada além do número exato tira 1 ponto.": [
		"Tap a bottle, then another one to pour. You can only pour onto the same color or into an empty bottle. Leave each bottle with a single color.\n\nLevels: endless, harder and harder, worth %d points each.\nDaily challenges: 20 new ones at midnight, worth 10, 25 or 50 points.\nEach move beyond the exact number costs 1 point.",
		"Toca una botella y luego otra para verter. Solo puedes verter sobre el mismo color o en una botella vacía. Deja cada botella con un solo color.\n\nNiveles: infinitos, cada vez más difíciles, valen %d puntos cada uno.\nDesafíos del día: 20 nuevos a medianoche, valen 10, 25 o 50 puntos.\nCada jugada más allá del número exacto quita 1 punto."],
	"Fechar": ["Close", "Cerrar"],
	"Entendi": ["Got it", "Entendido"],
	# partida
	"Menu": ["Menu", "Menú"],
	"DESAFIO": ["CHALLENGE", "DESAFÍO"],
	"NÍVEL": ["LEVEL", "NIVEL"],
	"JOGADAS": ["MOVES", "JUGADAS"],
	"PONTOS": ["POINTS", "PUNTOS"],
	"Recomeçar": ["Restart", "Reiniciar"],
	"+5 jogadas": ["+5 moves", "+5 jugadas"],
	"+%d jogadas": ["+%d moves", "+%d jugadas"],
	"%s · vale %d pontos": ["%s · worth %d points", "%s · vale %d puntos"],
	"Recomeçar?": ["Restart?", "¿Reiniciar?"],
	"Cada nova tentativa pede uma propaganda.\nVale sempre o seu melhor resultado.": [
		"Each new attempt needs an ad.\nYour best result always counts.",
		"Cada nuevo intento pide un anuncio.\nSiempre vale tu mejor resultado."],
	"Recomeçar pede uma propaganda.": ["Restarting needs an ad.", "Reiniciar pide un anuncio."],
	"Assistir e recomeçar": ["Watch and restart", "Ver y reiniciar"],
	"Continuar jogando": ["Keep playing", "Seguir jugando"],
	"Acabaram as jogadas": ["Out of moves", "Se acabaron las jugadas"],
	"Assista a uma propaganda para ganhar +%d jogadas.\nCada jogada além de %d tira 1 ponto.": [
		"Watch an ad to get +%d moves.\nEach move beyond %d costs 1 point.",
		"Mira un anuncio para ganar +%d jugadas.\nCada jugada más allá de %d quita 1 punto."],
	"Pontuação zerada": ["Score is zero", "Puntuación en cero"],
	"Assista a uma propaganda para recomeçar este desafio.": ["Watch an ad to restart this challenge.", "Mira un anuncio para reiniciar este desafío."],
	"Assista a uma propaganda para recomeçar este nível, ou termine sem pontos.": [
		"Watch an ad to restart this level, or finish it without points.",
		"Mira un anuncio para reiniciar este nivel, o termínalo sin puntos."],
	"Continuar sem pontos": ["Continue without points", "Seguir sin puntos"],
	"Desafio encerrado": ["Challenge closed", "Desafío cerrado"],
	"Este desafio era de %s. Agora só valem os desafios de hoje.": [
		"This challenge was from %s. Only today's challenges count now.",
		"Este desafío era del %s. Ahora solo valen los desafíos de hoy."],
	"Ver desafios de hoje": ["See today's challenges", "Ver desafíos de hoy"],
	"Na Lata!": ["Nailed it!", "¡En el blanco!"],
	"+%d pontos em %d jogadas.": ["+%d points in %d moves.", "+%d puntos en %d jugadas."],
	"\nSeu melhor continua %d pontos.": ["\nYour best is still %d points.", "\nTu mejor sigue siendo %d puntos."],
	"\nDava para fazer em %d jogadas.": ["\nIt could be done in %d moves.", "\nSe podía hacer en %d jugadas."],
	"Próximo desafio": ["Next challenge", "Siguiente desafío"],
	"Próximo nível": ["Next level", "Siguiente nivel"],
	"Tentar melhorar": ["Try to improve", "Intentar mejorar"],
	"Desafio %d": ["Challenge %d", "Desafío %d"],
	"Você já tentou este desafio.": ["You already tried this challenge.", "Ya intentaste este desafío."],
	"Seu melhor aqui: %d pontos em %d jogadas.": ["Your best here: %d points in %d moves.", "Tu mejor aquí: %d puntos en %d jugadas."],
	"\nUma nova tentativa pede uma propaganda.": ["\nA new attempt needs an ad.", "\nUn nuevo intento pide un anuncio."],
	"Assistir e jogar": ["Watch and play", "Ver y jugar"],
	"PROPAGANDA\n(simulação)\n\nAqui vai aparecer o anúncio do AdMob.\n\n%d": [
		"AD\n(simulation)\n\nThe AdMob ad will show here.\n\n%d",
		"ANUNCIO\n(simulación)\n\nAquí aparecerá el anuncio de AdMob.\n\n%d"],
	# hub e visual novo
	"Poção de Cores": ["Color Potion", "Poción de Colores"],
	"Jogar": ["Play", "Jugar"],
	"Em breve": ["Coming soon", "Muy pronto"],
	"Mais jogos em breve": ["More games coming soon", "Más juegos muy pronto"],
	"Jogos": ["Games", "Juegos"],
	"Ranking": ["Ranking", "Ranking"],
	"Início": ["Home", "Inicio"],
	"Desafios": ["Challenges", "Desafíos"],
	"Perfil": ["Profile", "Perfil"],
	"Pausa": ["Pause", "Pausa"],
	"Perfeito!": ["Perfect!", "¡Perfecto!"],
	"Muito bem!": ["Well done!", "¡Muy bien!"],
	"Desafio %d / %d": ["Challenge %d / %d", "Desafío %d / %d"],
	# datas
	"{day} de {month}": ["{month} {day}", "{day} de {month}"],
	"janeiro": ["January", "enero"], "fevereiro": ["February", "febrero"], "março": ["March", "marzo"],
	"abril": ["April", "abril"], "maio": ["May", "mayo"], "junho": ["June", "junio"],
	"julho": ["July", "julio"], "agosto": ["August", "agosto"], "setembro": ["September", "septiembre"],
	"outubro": ["October", "octubre"], "novembro": ["November", "noviembre"], "dezembro": ["December", "diciembre"],
}

static var _ready: bool = false


## Registra as traduções no motor (uma vez só).
static func setup() -> void:
	if _ready:
		return
	_ready = true
	# o português também precisa estar registrado, senão o motor cai no inglês (idioma reserva)
	var pt := Translation.new()
	pt.locale = "pt"
	var en := Translation.new()
	en.locale = "en"
	var es := Translation.new()
	es.locale = "es"
	for key in STRINGS:
		pt.add_message(key, key)
		en.add_message(key, STRINGS[key][0])
		es.add_message(key, STRINGS[key][1])
	TranslationServer.add_translation(pt)
	TranslationServer.add_translation(en)
	TranslationServer.add_translation(es)


static func is_supported(code: String) -> bool:
	for l in LANGUAGES:
		if l[0] == code:
			return true
	return false


static func language_name(code: String) -> String:
	for l in LANGUAGES:
		if l[0] == code:
			return l[1]
	return code


static func apply(code: String) -> void:
	setup()
	TranslationServer.set_locale(code if is_supported(code) else DEFAULT)


## Tradução fora de um nó (funções estáticas).
static func t(text: String) -> String:
	return String(TranslationServer.translate(text))
