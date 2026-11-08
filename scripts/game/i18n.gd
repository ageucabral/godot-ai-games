class_name I18n
extends RefCounted
## Idiomas do jogo. O texto em português é a "chave"; aqui ficam as versões em inglês e espanhol.
## Os textos fixos das telas traduzem sozinhos; textos montados com números usam tr("...") % valores.

const DEFAULT := "pt"
## [código, nome mostrado na lista]
const LANGUAGES: Array = [["pt", "Português"], ["en", "English"], ["es", "Español"]]

## "texto em português": [inglês, espanhol]
const STRINGS := {
	# servidor
	"Entrando…": ["Signing in…", "Entrando…"],
	"Entrar com Google": ["Sign in with Google", "Entrar con Google"],
	"Seu progresso está guardado na conta Google.": ["Your progress is saved in your Google account.", "Tu progreso está guardado en la cuenta de Google."],
	"Seu progresso está guardado na conta Google (%s).": ["Your progress is saved in your Google account (%s).", "Tu progreso está guardado en la cuenta de Google (%s)."],
	"Entre com Google para guardar seu progresso em qualquer celular e poder receber prêmios. O que você já fez aqui vai junto.": [
		"Sign in with Google to keep your progress on any phone and be able to get prizes. What you did here comes along.",
		"Entra con Google para guardar tu progreso en cualquier celular y poder recibir premios. Lo que ya hiciste aquí va contigo."],
	"A propaganda não terminou ou não foi confirmada. Tente de novo.": ["The ad didn't finish or wasn't confirmed. Try again.", "El anuncio no terminó o no se confirmó. Inténtalo de nuevo."],
	"Não deu para entrar com o Google agora. Tente de novo.": ["Couldn't sign in with Google now. Try again.", "No se pudo entrar con Google ahora. Inténtalo de nuevo."],
	"Entrar com Google só funciona no app do celular.": ["Google sign-in only works in the phone app.", "Entrar con Google solo funciona en la app del celular."],
	"Carregando…": ["Loading…", "Cargando…"],
	"Conferindo…": ["Checking…", "Verificando…"],
	"Sem conexão": ["No connection", "Sin conexión"],
	"Ops!": ["Oops!", "¡Uy!"],
	"Tentar de novo": ["Try again", "Intentar de nuevo"],
	"Partida não conferida": ["Game not verified", "Partida no verificada"],
	"O servidor não conseguiu conferir esta partida, então ela ficou sem pontos.": [
		"The server couldn't verify this game, so it scored no points.",
		"El servidor no pudo verificar esta partida, así que quedó sin puntos."],
	"Visitante": ["Guest", "Invitado"],
	"Jogue para entrar no ranking": ["Play to enter the ranking", "Juega para entrar en el ranking"],
	"%dº lugar": ["#%d", "%dº lugar"],
	"Empate: fica na frente quem usou menos jogadas.": [
		"Tie: fewer moves goes first.",
		"Empate: va primero quien usó menos jugadas."],
	"Sem conexão com o servidor. Confira a internet e tente de novo.": [
		"No connection to the server. Check your internet and try again.",
		"Sin conexión con el servidor. Revisa internet e inténtalo de nuevo."],
	"O Poção de Cores está em manutenção. Tente mais tarde.": [
		"Color Potion is under maintenance. Try again later.",
		"Poción de Colores está en mantenimiento. Inténtalo más tarde."],
	"Esta fase não abriu agora. Tente de novo em instantes.": [
		"This stage didn't open. Try again in a moment.",
		"Esta fase no abrió. Inténtalo de nuevo en un momento."],
	"Uma nova tentativa pede uma propaganda.": ["A new try needs an ad.", "Un nuevo intento pide un anuncio."],
	"Esta propaganda já foi usada.": ["This ad was already used.", "Este anuncio ya se usó."],
	"Este desafio já encerrou. Agora só valem os desafios de hoje.": [
		"This challenge is over. Only today's challenges count now.",
		"Este desafío terminó. Ahora solo valen los desafíos de hoy."],
	"Acabaram as ajudas desta fase.": ["No more helps in this stage.", "Se acabaron las ayudas de esta fase."],
	"Esta ajuda zeraria seus pontos neste desafio.": ["This help would zero your points in this challenge.", "Esta ayuda dejaría tus puntos en cero en este desafío."],
	"Esta partida já terminou.": ["This game is already over.", "Esta partida ya terminó."],
	"Esta fase já foi resolvida.": ["This stage is already solved.", "Esta fase ya fue resuelta."],
	"A partida ficou diferente da do servidor. Abra a fase de novo.": [
		"The game got out of sync with the server. Open the stage again.",
		"La partida quedó distinta de la del servidor. Abre la fase de nuevo."],
	"Muitas tentativas seguidas. Espere um pouco.": ["Too many tries in a row. Wait a bit.", "Demasiados intentos seguidos. Espera un poco."],
	"Sua conta está bloqueada. Fale com o suporte.": ["Your account is blocked. Contact support.", "Tu cuenta está bloqueada. Habla con soporte."],
	"Algo deu errado. Tente de novo.": ["Something went wrong. Try again.", "Algo salió mal. Inténtalo de nuevo."],
	# conta, prêmios, ajuda, sons e primeira partida
	"Ok": ["OK", "Ok"],
	"Depois": ["Later", "Después"],
	"Enviar": ["Send", "Enviar"],
	"Salvar": ["Save", "Guardar"],
	"Confirmar": ["Confirm", "Confirmar"],
	"Cancelar": ["Cancel", "Cancelar"],
	"Continuar": ["Continue", "Continuar"],
	"Atualizar": ["Update", "Actualizar"],
	"E-mail": ["Email", "Correo"],
	"Telefone": ["Phone", "Teléfono"],
	"CPF": ["CPF (Brazilian ID)", "CPF (documento de Brasil)"],
	"Idade": ["Age", "Edad"],
	"Apelido": ["Nickname", "Apodo"],
	"%s: %d de %d dias": ["%s: %d of %d days", "%s: %d de %d días"],
	"%dº ao %dº: %s cada": ["#%d to #%d: %s each", "%dº al %dº: %s cada uno"],
	"%dº lugar: %s": ["#%d: %s", "%dº lugar: %s"],
	"Abrir e-mail": ["Open email", "Abrir correo"],
	"Agora não": ["Not now", "Ahora no"],
	"Ajuda e termos": ["Help and terms", "Ayuda y términos"],
	"Ao enviar, você aceita o regulamento.": ["By sending, you accept the prize rules.", "Al enviar, aceptas el reglamento."],
	"Apagando…": ["Deleting…", "Borrando…"],
	"Apagar conta": ["Delete account", "Borrar cuenta"],
	"Apagar conta?": ["Delete account?", "¿Borrar cuenta?"],
	"Apagar para sempre": ["Delete forever", "Borrar para siempre"],
	"Apelido: %s": ["Nickname: %s", "Apodo: %s"],
	"Atualize o app": ["Update the app", "Actualiza la app"],
	"Chave Pix": ["Pix key", "Clave Pix"],
	"Chave aleatória": ["Random key", "Clave aleatoria"],
	"Coloque seu e-mail para podermos responder.": ["Add your email so we can reply.", "Pon tu correo para que podamos responder."],
	"Começar": ["Start", "Empezar"],
	"Como quer receber?": ["How do you want to get it?", "¿Cómo quieres recibirlo?"],
	"Como você tem menos de 18 anos, use os dados de um responsável.": ["Since you are under 18, use a parent's or guardian's details.", "Como tienes menos de 18 años, usa los datos de un responsable."],
	"Compartilhar convite": ["Share invite", "Compartir invitación"],
	"Confirmar país": ["Confirm country", "Confirmar país"],
	"Conta apagada": ["Account deleted", "Cuenta borrada"],
	"Conte o que aconteceu. Respondemos pelo e-mail.": ["Tell us what happened. We reply by email.", "Cuéntanos qué pasó. Respondemos por correo."],
	"Convidar amigos": ["Invite friends", "Invitar amigos"],
	"Convite copiado": ["Invite copied", "Invitación copiada"],
	"Código de convite (se tiver)": ["Invite code (if you have one)", "Código de invitación (si tienes)"],
	"Digite uma idade válida.": ["Enter a valid age.", "Escribe una edad válida."],
	"Dúvida": ["Question", "Duda"],
	"E-mail da chave Pix": ["Pix key email", "Correo de la clave Pix"],
	"Em manutenção": ["Under maintenance", "En mantenimiento"],
	"Endereço da carteira (%s)": ["Wallet address (%s)", "Dirección de la billetera (%s)"],
	"Entre com Google para continuar.": ["Sign in with Google to continue.", "Entra con Google para continuar."],
	"Entre com Google para resgatar o prêmio.": ["Sign in with Google to claim the prize.", "Entra con Google para cobrar el premio."],
	"Enviando…": ["Sending…", "Enviando…"],
	"Escolha um país da lista.": ["Pick a country from the list.", "Elige un país de la lista."],
	"Escolher país": ["Choose country", "Elegir país"],
	"Escreva para %s.": ["Write to %s.", "Escribe a %s."],
	"Escreva pelo menos 10 caracteres.": ["Write at least 10 characters.", "Escribe al menos 10 caracteres."],
	"Esse apelido já tinha dono, então ficou %s.": ["That nickname was taken, so it became %s.", "Ese apodo ya tenía dueño, así que quedó %s."],
	"Estamos fazendo uma manutenção rápida. Voltamos já!": ["We're doing quick maintenance. Back soon!", "Estamos haciendo un mantenimiento rápido. ¡Volvemos ya!"],
	"Fale conosco": ["Contact us", "Contáctanos"],
	"Jogue o Na Lata comigo e concorra a prêmios! Meu código: %s": ["Play Na Lata with me and compete for prizes! My code: %s", "¡Juega Na Lata conmigo y compite por premios! Mi código: %s"],
	"Ler o regulamento": ["Read the prize rules", "Leer el reglamento"],
	"Mensagem enviada": ["Message sent", "Mensaje enviado"],
	"Meu país não está na lista": ["My country isn't listed", "Mi país no está en la lista"],
	"Nome completo": ["Full name", "Nombre completo"],
	"Não deu para calcular o valor agora. Tente mais tarde.": ["Couldn't calculate the amount now. Try later.", "No se pudo calcular el valor ahora. Inténtalo más tarde."],
	"Não dá para jogar": ["You can't play", "No se puede jugar"],
	"O Na Lata é para quem tem %d anos ou mais. Sua conta foi apagada.": ["Na Lata is for people aged %d or older. Your account was deleted.", "Na Lata es para quien tiene %d años o más. Tu cuenta fue borrada."],
	"O convite foi copiado. Cole numa conversa para mandar aos amigos.": ["The invite was copied. Paste it in a chat to send to friends.", "La invitación se copió. Pégala en un chat para mandarla a tus amigos."],
	"O prazo para resgatar este prêmio terminou.": ["The deadline to claim this prize is over.", "El plazo para cobrar este premio terminó."],
	"O valor foi atualizado. Confira e envie de novo.": ["The amount was updated. Check it and send again.", "El valor se actualizó. Revísalo y envía de nuevo."],
	"Obrigado! Vamos responder pelo e-mail.": ["Thanks! We'll reply by email.", "¡Gracias! Responderemos por correo."],
	"Os prêmios dependem do país. Não dá para trocar depois.": ["Prizes depend on the country. You can't change it later.", "Los premios dependen del país. No se puede cambiar después."],
	"Outro país": ["Other country", "Otro país"],
	"Outro país (sem prêmios)": ["Other country (no prizes)", "Otro país (sin premios)"],
	"Para receber prêmio, convide %d amigos que joguem pelo menos %d dias.": ["To get a prize, invite %d friends who play at least %d days.", "Para recibir premio, invita a %d amigos que jueguen al menos %d días."],
	"País: %s": ["Country: %s", "País: %s"],
	"País: %s.\nNão dá para trocar depois.": ["Country: %s.\nYou can't change it later.", "País: %s.\nNo se puede cambiar después."],
	"Pix (em reais)": ["Pix (in reais)", "Pix (en reales)"],
	"Política de privacidade": ["Privacy policy", "Política de privacidad"],
	"Primeira partida": ["First game", "Primera partida"],
	"Problema técnico": ["Technical problem", "Problema técnico"],
	"Prêmio e pagamento": ["Prize and payment", "Premio y pago"],
	"Outro": ["Other", "Otro"],
	"Prêmio pedido!": ["Prize requested!", "¡Premio pedido!"],
	"Prêmio: %s": ["Prize: %s", "Premio: %s"],
	"Prêmios ainda não estão disponíveis no seu país. Você segue no ranking normalmente.": ["Prizes aren't available in your country yet. You stay in the ranking as usual.", "Los premios aún no están disponibles en tu país. Sigues en el ranking normalmente."],
	"Prêmios do mês": ["This month's prizes", "Premios del mes"],
	"Quantos anos você tem? Ninguém mais vê essa resposta.": ["How old are you? Nobody else sees this answer.", "¿Cuántos años tienes? Nadie más ve esta respuesta."],
	"Recebemos seus dados. O pagamento sai em breve.": ["We got your details. Payment is on its way soon.", "Recibimos tus datos. El pago sale pronto."],
	"Rede da carteira": ["Wallet network", "Red de la billetera"],
	"Regulamento dos prêmios": ["Prize rules", "Reglamento de premios"],
	"Resgatar prêmio": ["Claim prize", "Cobrar premio"],
	"Saiu uma versão nova do Na Lata. Atualize na Play Store para continuar jogando.": ["A new version of Na Lata is out. Update it on the Play Store to keep playing.", "Salió una versión nueva de Na Lata. Actualízala en Play Store para seguir jugando."],
	"Seu apelido": ["Your nickname", "Tu apodo"],
	"Seu código: %s": ["Your code: %s", "Tu código: %s"],
	"Seu e-mail (para a resposta)": ["Your email (for the reply)", "Tu correo (para la respuesta)"],
	"Seu país": ["Your country", "Tu país"],
	"Seus dados foram apagados. Se quiser, pode continuar jogando como um jogador novo.": ["Your data was deleted. If you want, you can keep playing as a new player.", "Tus datos fueron borrados. Si quieres, puedes seguir jugando como un jugador nuevo."],
	"Seus dados já foram enviados.": ["Your details were already sent.", "Tus datos ya fueron enviados."],
	"Seus pontos, seu nível, seus convites e os prêmios ainda não pagos somem para sempre. Não dá para desfazer.": ["Your points, level, invites and unpaid prizes are gone forever. This can't be undone.", "Tus puntos, tu nivel, tus invitaciones y los premios no pagados se pierden para siempre. No se puede deshacer."],
	"Sobre o que você quer falar?": ["What do you want to talk about?", "¿Sobre qué quieres hablar?"],
	"Som: desligado": ["Sound: off", "Sonido: apagado"],
	"Som: ligado": ["Sound: on", "Sonido: encendido"],
	"Sua conta": ["Your account", "Tu cuenta"],
	"Sua idade": ["Your age", "Tu edad"],
	"Sua mensagem": ["Your message", "Tu mensaje"],
	"Telefone da chave Pix": ["Pix key phone", "Teléfono de la clave Pix"],
	"Termos de uso": ["Terms of use", "Términos de uso"],
	"Tipo da chave Pix": ["Pix key type", "Tipo de clave Pix"],
	"Toque numa garrafa e depois em outra para despejar. Só dá para despejar em cima da mesma cor ou numa garrafa vazia. Siga a setinha!": ["Tap a bottle and then another to pour. You can only pour onto the same color or into an empty bottle. Follow the arrow!", "Toca una botella y luego otra para verter. Solo puedes verter sobre el mismo color o en una botella vacía. ¡Sigue la flechita!"],
	"Trocar apelido": ["Change nickname", "Cambiar apodo"],
	"USDT (cripto)": ["USDT (crypto)", "USDT (cripto)"],
	"Use a mesma rede da sua carteira USDT.": ["Use the same network as your USDT wallet.", "Usa la misma red de tu billetera USDT."],
	"Você está jogando como visitante.": ["You're playing as a guest.", "Estás jugando como invitado."],
	"Você ganhou %s no Ranking Global de %s. Resgate até %s.": ["You won %s in the %s Global Ranking. Claim it by %s.", "Ganaste %s en el Ranking Global de %s. Cóbralo hasta el %s."],
	"Você ganhou!": ["You won!", "¡Ganaste!"],
	"Você joga e aparece no ranking normalmente, mas não concorre a prêmios. Não dá para trocar depois.": ["You play and show up in the ranking as usual, but don't compete for prizes. You can't change it later.", "Juegas y apareces en el ranking normalmente, pero no compites por premios. No se puede cambiar después."],
	"Você já cumpre a regra para receber prêmios.": ["You already meet the rule to get prizes.", "Ya cumples la regla para recibir premios."],
	"Você já pode receber prêmios!": ["You can already get prizes!", "¡Ya puedes recibir premios!"],
	"Você recebe %s no Pix (cotação de hoje).": ["You get %s via Pix (today's rate).", "Recibes %s por Pix (cotización de hoy)."],
	"Você tem %d de %d.": ["You have %d of %d.", "Tienes %d de %d."],
	"É o nome que aparece no ranking.": ["It's the name shown in the ranking.", "Es el nombre que aparece en el ranking."],
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
	"Empate: fica na frente quem usou menos jogadas. A lista com todos os jogadores está no app da Play Store.": [
		"Tie: fewer moves goes first. The list with every player is in the Play Store app.",
		"Empate: va primero quien usó menos jugadas. La lista con todos los jugadores está en la app de Play Store."],
	"Os prêmios saem do Ranking Global, no menu do Na Lata.": [
		"Prizes come from the Global Ranking, in the Na Lata menu.",
		"Los premios salen del Ranking Global, en el menú de Na Lata."],
	"Fácil": ["Easy", "Fácil"],
	"Médio": ["Medium", "Medio"],
	"Difícil": ["Hard", "Difícil"],
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
	"No app da Play Store você pode entrar com Google para guardar seu progresso e aparecer no ranking com todos os jogadores.": [
		"In the Play Store app you can sign in with Google to keep your progress and appear in the ranking with every player.",
		"En la app de Play Store puedes entrar con Google para guardar tu progreso y aparecer en el ranking con todos los jugadores."],
	"Como jogar": ["How to play", "Cómo jugar"],
	"Toque numa garrafa e depois em outra para despejar. Só dá para despejar em cima da mesma cor ou numa garrafa vazia. Deixe cada garrafa com uma cor só.\n\nCada fase vale o dobro das jogadas necessárias: se pede 11 jogadas, vale 22 pontos.\nCada jogada além disso tira 1 ponto, e você vê o placar caindo na hora.\n\nNíveis: sem fim, cada vez mais difíceis.\nDesafios do dia: 20 novos à meia-noite.": [
		"Tap a bottle, then another one to pour. You can only pour onto the same color or into an empty bottle. Leave each bottle with a single color.\n\nEach stage is worth twice the moves it needs: if it needs 11 moves, it is worth 22 points.\nEach extra move costs 1 point, and you see the score drop right away.\n\nLevels: endless, harder and harder.\nDaily challenges: 20 new ones at midnight.",
		"Toca una botella y luego otra para verter. Solo puedes verter sobre el mismo color o en una botella vacía. Deja cada botella con un solo color.\n\nCada fase vale el doble de las jugadas necesarias: si pide 11 jugadas, vale 22 puntos.\nCada jugada de más quita 1 punto, y ves el marcador bajar al instante.\n\nNiveles: infinitos, cada vez más difíciles.\nDesafíos del día: 20 nuevos a medianoche."],
	"Fechar": ["Close", "Cerrar"],
	"Entendi": ["Got it", "Entendido"],
	# partida
	"Menu": ["Menu", "Menú"],
	"JOGADAS": ["MOVES", "JUGADAS"],
	"Recomeçar": ["Restart", "Reiniciar"],
	"+5 jogadas": ["+5 moves", "+5 jugadas"],
	"+%d jogadas": ["+%d moves", "+%d jugadas"],
	"PONTOS": ["POINTS", "PUNTOS"],
	"Embaralhar": ["Shuffle", "Mezclar"],
	"Frasco extra": ["Extra bottle", "Frasco extra"],
	"Embaralhar?": ["Shuffle?", "¿Mezclar?"],
	"Frasco extra?": ["Extra bottle?", "¿Frasco extra?"],
	"Mistura de novo as cores das garrafas abertas.\nPede uma propaganda e custa %s.": [
		"Mixes the colors of the open bottles again.\nNeeds an ad and costs %s.",
		"Mezcla de nuevo los colores de las botellas abiertas.\nPide un anuncio y cuesta %s."],
	"Ganha uma garrafa vazia a mais.\nPede uma propaganda e custa %s.": [
		"Get one more empty bottle.\nNeeds an ad and costs %s.",
		"Gana una botella vacía más.\nPide un anuncio y cuesta %s."],
	"1 ponto": ["1 point", "1 punto"],
	"%d pontos": ["%d points", "%d puntos"],
	"Assistir e embaralhar": ["Watch and shuffle", "Ver y mezclar"],
	"Assistir e ganhar": ["Watch and get it", "Ver y ganar"],
	"Não deu para embaralhar agora. Nada foi cobrado.": ["Couldn't shuffle right now. Nothing was charged.", "No se pudo mezclar ahora. No se cobró nada."],
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
	"Desafios feitos!": ["Challenges done!", "¡Desafíos hechos!"],
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
