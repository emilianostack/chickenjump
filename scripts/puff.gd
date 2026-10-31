class_name Puff
extends CPUParticles2D
## Explosao curta de particulas que se remove sozinha.

const TEXTURE := preload("res://assets/items/puff.svg")


func _init(tint: Color, count := 8) -> void:
	texture = TEXTURE
	amount = count
	one_shot = true
	explosiveness = 1.0
	lifetime = 0.45
	spread = 180.0
	initial_velocity_min = 30.0
	initial_velocity_max = 120.0
	gravity = Vector2(0.0, 160.0)
	scale_amount_min = 0.12
	scale_amount_max = 0.3
	color = tint
	var fade := Gradient.new()
	fade.colors = PackedColorArray([Color.WHITE, Color(1, 1, 1, 0)])
	color_ramp = fade
	finished.connect(queue_free)
