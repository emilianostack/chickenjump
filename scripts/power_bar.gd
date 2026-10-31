class_name PowerBar
extends HBoxContainer
## Mostra no HUD os buffs que o jogador tem no momento.

const ICONS := {
	"ammo": preload("res://assets/items/bullet.svg"),
	"heart": preload("res://assets/items/heart.svg"),
	"bomb": preload("res://assets/items/bomb.svg"),
	"shield": preload("res://assets/items/shield.svg"),
	"triple": preload("res://assets/items/triple.svg"),
}
const ICON_SIZE := 32.0

var slots := {}
var reload_meter := ProgressBar.new()


func _ready() -> void:
	for key in ICONS:
		var slot := HBoxContainer.new()
		slot.add_theme_constant_override("separation", 2)
		var icon := TextureRect.new()
		icon.texture = ICONS[key]
		icon.custom_minimum_size = Vector2.ONE * ICON_SIZE
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		slot.add_child(icon)
		var label := Label.new()
		label.add_theme_font_size_override("font_size", 22)
		label.add_theme_constant_override("outline_size", 8)
		label.add_theme_color_override("font_outline_color", Color(0.12, 0.16, 0.27))
		slot.add_child(label)
		add_child(slot)
		slots[key] = {"root": slot, "label": label}
		slot.hide()
	_setup_reload_meter()


## Com `active` falso o espaco do buff some da barra.
func set_slot(key: String, active: bool, value := "") -> void:
	slots[key].root.visible = active
	slots[key].label.text = value


## Mostra quanto falta para o proximo tiro; some com a municao cheia.
func set_reload(active: bool, progress: float) -> void:
	reload_meter.visible = active
	reload_meter.value = progress


func _setup_reload_meter() -> void:
	reload_meter.show_percentage = false
	reload_meter.max_value = 1.0
	reload_meter.custom_minimum_size = Vector2(38.0, 10.0)
	reload_meter.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	reload_meter.add_theme_stylebox_override("background", _meter_style(Color(0.12, 0.16, 0.27)))
	reload_meter.add_theme_stylebox_override("fill", _meter_style(Color(1.0, 0.8, 0.2)))
	slots["ammo"].root.add_child(reload_meter)


func _meter_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(5)
	return style
