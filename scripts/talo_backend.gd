class_name TaloBackend
extends RefCounted
## Liga o ranking do jogo ao servico Talo.

const BOARD := "chicken-best"
const SERVICE := "chicken"
const NAME_PROP := "name"


func is_configured() -> bool:
	return not Talo.settings.access_key.is_empty()


func identify(player_id: String) -> bool:
	if Talo.has_identity():
		return true
	return await Talo.players.identify(SERVICE, player_id) != null


func submit(score: int, player_name: String) -> bool:
	var props: Dictionary[String, Variant] = {NAME_PROP: player_name}
	var result := await Talo.leaderboards.add_entry(BOARD, score, props)
	return result.success


## Retorna as linhas do ranking, ou null se nao conseguir buscar.
func fetch_top(limit: int) -> Variant:
	var result := await Talo.leaderboards.get_top_entries(BOARD, limit)
	if result == null:
		return null
	var rows: Array[Dictionary] = []
	for entry in result.top_entries:
		rows.append(_row(entry))
	for entry in result.player_entries:
		rows.append(_row(entry))
	return rows


func _row(entry: TaloLeaderboardEntry) -> Dictionary:
	return {
		"position": entry.position + 1,
		"name": entry.get_prop(NAME_PROP, "?"),
		"score": int(entry.score),
		"mine": entry.player_alias.id == Talo.current_alias.id,
	}
