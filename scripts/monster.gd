class_name Monster
extends Node2D

enum Variant { SPIKY, BAT }

const RADIUS := 26.0
const TEXTURE_SPIKY := preload("res://assets/monsters/spiky.svg")
const TEXTURE_BAT_UP := preload("res://assets/monsters/bat_up.svg")
const TEXTURE_BAT_DOWN := preload("res://assets/monsters/bat_down.svg")

var variant := Variant.SPIKY
var direction := 1.0
var speed := 0.0
var base_y := 0.0
var time := 0.0
var sprite := Sprite2D.new()


func setup(difficulty: float, monster_variant: Variant) -> void:
	variant = monster_variant
	base_y = position.y
	speed = lerpf(50.0, 130.0, difficulty)
	direction = 1.0 if randf() < 0.5 else -1.0
	time = randf() * TAU
	sprite.scale = Cfg.ART_SCALE
	sprite.texture = TEXTURE_SPIKY if variant == Variant.SPIKY else TEXTURE_BAT_UP
	add_child(sprite)


func _physics_process(delta: float) -> void:
	time += delta
	position.x += direction * speed * delta
	if position.x < RADIUS or position.x > Cfg.VIEW_W - RADIUS:
		position.x = clampf(position.x, RADIUS, Cfg.VIEW_W - RADIUS)
		direction = -direction
	position.y = base_y + sin(time * 3.0) * 10.0
	if variant == Variant.SPIKY:
		sprite.rotation = sin(time * 2.0) * 0.15
	else:
		sprite.texture = TEXTURE_BAT_UP if fmod(time, 0.3) < 0.15 else TEXTURE_BAT_DOWN
