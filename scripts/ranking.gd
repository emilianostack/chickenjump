class_name Ranking
extends Node
## Ranking online. Falhas de rede nunca afetam a partida: o recorde pendente e reenviado depois.

signal changed

const TOP_SIZE := 10
const MIN_NAME := 2
const MAX_NAME := 16

var backend = TaloBackend.new()
var player_id := ""
var player_name := ""
var synced_best := 0
var syncing := false


func is_available() -> bool:
	return backend.is_configured()


static func clean_name(text: String) -> String:
	var kept := ""
	for i in text.length():
		if text.unicode_at(i) >= 32 and text.unicode_at(i) != 127:
			kept += text[i]
	return kept.strip_edges().left(MAX_NAME).strip_edges()


func set_player_name(text: String) -> bool:
	var cleaned := clean_name(text)
	if cleaned.length() < MIN_NAME:
		return false
	player_name = cleaned
	changed.emit()
	return true


## Envia o recorde se ele ainda nao chegou ao servidor.
func sync(best: int) -> void:
	if syncing or not is_available() or player_name.is_empty() or best <= synced_best:
		return
	syncing = true
	if await _identify() and await backend.submit(best, player_name):
		synced_best = best
		changed.emit()
	syncing = false


## Retorna as linhas do ranking, ou null se nao conseguir buscar.
func fetch() -> Variant:
	if not is_available() or not await _identify():
		return null
	var rows: Variant = await backend.fetch_top(TOP_SIZE)
	return rows


func _identify() -> bool:
	if player_id.is_empty():
		player_id = Crypto.new().generate_random_bytes(16).hex_encode()
		changed.emit()
	return await backend.identify(player_id)
