extends Node
## Estado global do jogo (pontuação etc.). Disponível em qualquer script como `GameState`.

signal score_changed(new_score: int)

var score: int = 0:
	set(value):
		score = maxi(value, 0)
		score_changed.emit(score)


func add_points(amount: int) -> void:
	score += amount


func reset() -> void:
	score = 0
