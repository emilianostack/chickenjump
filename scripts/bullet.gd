class_name Bullet
extends Sprite2D

const SPEED := 950.0
const RADIUS := 7.0

var drift := 0.0


func _init() -> void:
	texture = preload("res://assets/items/bullet.svg")
	scale = Cfg.ART_SCALE


func _physics_process(delta: float) -> void:
	position += Vector2(drift, -SPEED) * delta
