class_name Sfx
extends Node
## Efeitos sonoros gerados por codigo, sem arquivos de audio.

const MIX_RATE := 22050

var players := {}


func _ready() -> void:
	_add("jump", _tone(320.0, 640.0, 0.12))
	_add("spring", _tone(300.0, 1300.0, 0.25))
	_add("break", _tone(240.0, 70.0, 0.14))
	_add("shoot", _tone(1000.0, 420.0, 0.1, 0.2))
	_add("stomp", _tone(500.0, 120.0, 0.18))
	_add("jetpack", _tone(160.0, 500.0, 0.7, 0.25))
	_add("lose", _tone(520.0, 80.0, 0.7))
	_add("reload", _tone(880.0, 1180.0, 0.08, 0.2))
	_add("empty", _tone(170.0, 130.0, 0.1, 0.25))
	_add("item", _tone(660.0, 1320.0, 0.18))
	_add("shield", _tone(900.0, 300.0, 0.3))
	_add("revive", _tone(260.0, 1040.0, 0.5))
	_add("bomb", _tone(180.0, 40.0, 0.6, 0.45))


func play(sound: String) -> void:
	players[sound].play()


func _add(sound: String, stream: AudioStreamWAV) -> void:
	var player := AudioStreamPlayer.new()
	player.stream = stream
	add_child(player)
	players[sound] = player


func _tone(from_hz: float, to_hz: float, duration: float, volume := 0.3) -> AudioStreamWAV:
	var count := int(MIX_RATE * duration)
	var data := PackedByteArray()
	data.resize(count * 2)
	var phase := 0.0
	for i in count:
		var t := float(i) / count
		phase += TAU * lerpf(from_hz, to_hz, t) / MIX_RATE
		var sample := sin(phase) * volume * (1.0 - t)
		data.encode_s16(i * 2, int(sample * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.data = data
	return stream
