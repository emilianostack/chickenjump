extends "res://tests/bot.gd"
## Grava jogabilidade real do robo para os videos de previa, sem acelerar nada.
## Uso: godot --path . --resolution 720x1200 --fixed-fps 30 --write-movie saida.avi --script res://tests/trailer.gd

const LENGTH_FRAMES := 19 * 60


func _initialize() -> void:
	await super()
	main.language = 1
	main._apply_language()
	main._update_best_label()


func _physics_process(delta: float) -> bool:
	var done: bool = super(delta)
	return done or frame >= LENGTH_FRAMES
