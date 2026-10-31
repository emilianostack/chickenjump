class_name TouchControls
extends Node2D
## Botoes de toque, usando as mesmas acoes do teclado. So aparecem em telas sensiveis ao toque.

const SIZE := 96.0
const MARGIN := 14.0
const LAYOUT := [
	["move_left", "res://assets/touch/left.svg", Vector2(MARGIN, Cfg.VIEW_H - SIZE - MARGIN)],
	["move_right", "res://assets/touch/right.svg", Vector2(MARGIN * 2.0 + SIZE, Cfg.VIEW_H - SIZE - MARGIN)],
	["shoot", "res://assets/touch/shoot.svg", Vector2(Cfg.VIEW_W - SIZE - MARGIN, Cfg.VIEW_H - SIZE - MARGIN)],
	["bomb", "res://assets/touch/bomb.svg", Vector2(Cfg.VIEW_W - SIZE - MARGIN, Cfg.VIEW_H - SIZE * 2.0 - MARGIN * 2.0)],
]
const OPACITY := 0.6


func _ready() -> void:
	modulate.a = OPACITY
	for entry: Array in LAYOUT:
		var button := TouchScreenButton.new()
		button.action = entry[0]
		button.name = entry[0]
		button.texture_normal = load(entry[1])
		button.position = entry[2]
		button.scale = Cfg.ART_SCALE
		button.visibility_mode = TouchScreenButton.VISIBILITY_TOUCHSCREEN_ONLY
		add_child(button)
