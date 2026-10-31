class_name Platform
extends Node2D

enum Kind { NORMAL, MOVING, BREAKABLE, VANISHING }
enum Item { NONE, JETPACK, SHIELD, HEART, BOMB, TRIPLE }

const WIDTH := 72.0
const HEIGHT := 16.0
const SPRING_HEIGHT := 12.0
const SPRING_HALF_WIDTH := 16.0
const ITEM_Y := -HEIGHT * 0.5 - 24.0
const ITEM_BOB := 4.0
# Nos SVGs de plataforma (80x34) a superficie fica na linha y=3.
const ART_OFFSET := Vector2(0.0, 6.0)
const TEXTURES := {
	Kind.NORMAL: preload("res://assets/platforms/grass.svg"),
	Kind.MOVING: preload("res://assets/platforms/moving.svg"),
	Kind.VANISHING: preload("res://assets/platforms/cloud.svg"),
}
const TEXTURE_BREAK_LEFT := preload("res://assets/platforms/break_left.svg")
const TEXTURE_BREAK_RIGHT := preload("res://assets/platforms/break_right.svg")
const TEXTURE_SPRING := preload("res://assets/items/spring_idle.svg")
const TEXTURE_SPRING_UP := preload("res://assets/items/spring_up.svg")
const ITEM_TEXTURES := {
	Item.JETPACK: preload("res://assets/items/jetpack.svg"),
	Item.SHIELD: preload("res://assets/items/shield.svg"),
	Item.HEART: preload("res://assets/items/heart.svg"),
	Item.BOMB: preload("res://assets/items/bomb.svg"),
	Item.TRIPLE: preload("res://assets/items/triple.svg"),
}

var kind := Kind.NORMAL
var solid := true
var has_spring := false
var spring_x := 0.0
var spring_used := 0.0
var item := Item.NONE
var item_time := 0.0
var direction := 1.0
var speed := 0.0
var fall_speed := 0.0

var left_half: Sprite2D
var right_half: Sprite2D
var spring: Sprite2D
var item_sprite: Sprite2D


func setup(platform_kind: Kind, difficulty: float) -> void:
	kind = platform_kind
	if kind == Kind.BREAKABLE:
		left_half = _add_sprite(TEXTURE_BREAK_LEFT, ART_OFFSET)
		right_half = _add_sprite(TEXTURE_BREAK_RIGHT, ART_OFFSET)
	else:
		_add_sprite(TEXTURES[kind], ART_OFFSET)
	if kind == Kind.MOVING:
		speed = lerpf(70.0, 170.0, difficulty) * randf_range(0.8, 1.2)
		direction = 1.0 if randf() < 0.5 else -1.0


func add_spring() -> void:
	has_spring = true
	spring_x = randf_range(-22.0, 22.0)
	spring = _add_sprite(TEXTURE_SPRING, Vector2(spring_x, -HEIGHT * 0.5 - 15.0))


func add_item(new_item: Item) -> void:
	item = new_item
	item_time = randf() * TAU
	item_sprite = _add_sprite(ITEM_TEXTURES[item], Vector2(0.0, ITEM_Y))
	# Fica na frente de outra plataforma que passe por cima do icone.
	item_sprite.z_index = 1


func top_y() -> float:
	return position.y - HEIGHT * 0.5


func hits_spring(x: float) -> bool:
	return has_spring and absf(x - (position.x + spring_x)) <= SPRING_HALF_WIDTH


func use_spring() -> void:
	spring_used = 1.0
	spring.texture = TEXTURE_SPRING_UP


func item_position() -> Vector2:
	return position + Vector2(0.0, ITEM_Y)


func take_item() -> void:
	item = Item.NONE
	item_sprite.queue_free()


func break_apart() -> void:
	solid = false
	fall_speed = 200.0


func vanish() -> void:
	solid = false


func _add_sprite(texture: Texture2D, offset: Vector2) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.scale = Cfg.ART_SCALE
	sprite.position = offset
	add_child(sprite)
	return sprite


func _physics_process(delta: float) -> void:
	if kind == Kind.MOVING:
		position.x += direction * speed * delta
		var margin := WIDTH * 0.5
		if position.x < margin or position.x > Cfg.VIEW_W - margin:
			position.x = clampf(position.x, margin, Cfg.VIEW_W - margin)
			direction = -direction
	if item != Item.NONE:
		item_time += delta
		item_sprite.position.y = ITEM_Y + sin(item_time * 3.0) * ITEM_BOB
	if solid:
		if spring_used > 0.0:
			spring_used = maxf(spring_used - delta * 3.0, 0.0)
			if spring_used == 0.0:
				spring.texture = TEXTURE_SPRING
		return
	if kind == Kind.BREAKABLE:
		fall_speed += Cfg.GRAVITY * delta
		position.y += fall_speed * delta
		left_half.position.x -= 60.0 * delta
		left_half.rotation -= 2.5 * delta
		right_half.position.x += 60.0 * delta
		right_half.rotation += 2.5 * delta
	else:
		scale += Vector2.ONE * 1.5 * delta
		modulate.a -= 5.0 * delta
		if modulate.a <= 0.0:
			queue_free()
