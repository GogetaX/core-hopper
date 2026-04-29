extends Node

const BOSS_DB_PATH := "res://data/bosses/boss_db.json"

const RANDOM_RELIC_DROP_ID := "random_relic"

var boss_db: Dictionary = {}
var boss_depth_map: Dictionary = {}


func _ready() -> void:
	LoadBossDatabase()
	GenerateSpawnMap()

func GenerateSpawnMap():
	boss_depth_map.clear()
	for x in boss_db:
		boss_depth_map[int(boss_db[x].spawn_depth)] = x

func LoadBossDatabase(path: String = BOSS_DB_PATH) -> bool:
	boss_db.clear()
	
	if !FileAccess.file_exists(path):
		push_warning("LoadBossDatabase: file not found -> " + path)
		return false

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("LoadBossDatabase: failed to open -> " + path)
		return false

	var text := file.get_as_text()
	file.close()

	var json := JSON.new()
	var err := json.parse(text)
	if err != OK:
		push_warning("LoadBossDatabase: invalid json -> " + path)
		return false

	var data = json.data
	if typeof(data) != TYPE_DICTIONARY:
		push_warning("LoadBossDatabase: root must be a dictionary")
		return false

	# load bosses list
	if data.has("bosses") and typeof(data.bosses) == TYPE_ARRAY:
		for boss in data.bosses:
			if typeof(boss) != TYPE_DICTIONARY:
				continue
			var boss_id := str(boss.get("id", ""))
			if boss_id == "":
				continue
			boss_db[boss_id] = boss.duplicate(true)

	return true


func IsBossDatabaseLoaded() -> bool:
	return !boss_db.is_empty()


func GetBossDataByID(boss_id: String) -> Dictionary:
	if boss_db.has(boss_id):
		return boss_db[boss_id].duplicate(true)
	return {}


func HasBossAtDepth(depth: int) -> bool:
	return boss_depth_map.has(depth)


func GetBossIDAtDepth(depth: int) -> String:
	if boss_depth_map.has(depth):
		return str(boss_depth_map[depth])
	return ""


func GetBossDataAtDepth(depth: int) -> Dictionary:
	var boss_id := GetBossIDAtDepth(depth)
	if boss_id == "":
		return {}
	return GetBossDataByID(boss_id)


func _EnsureBossProgress() -> void:
	if !GlobalSave.save_data.has("boss_progress") or typeof(GlobalSave.save_data.boss_progress) != TYPE_DICTIONARY:
		GlobalSave.save_data["boss_progress"] = {
			"killed_depths": [],
			"killed_ids": []
		}
		return

	if !GlobalSave.save_data.boss_progress.has("killed_depths") or typeof(GlobalSave.save_data.boss_progress.killed_depths) != TYPE_ARRAY:
		GlobalSave.save_data.boss_progress["killed_depths"] = []

	if !GlobalSave.save_data.boss_progress.has("killed_ids") or typeof(GlobalSave.save_data.boss_progress.killed_ids) != TYPE_ARRAY:
		GlobalSave.save_data.boss_progress["killed_ids"] = []


func HasBossBeenKilledAtDepth(depth: int) -> bool:
	_EnsureBossProgress()
	return depth in GlobalSave.save_data.boss_progress.killed_depths


func HasBossBeenKilledByID(boss_id: String) -> bool:
	_EnsureBossProgress()

	var id := boss_id.strip_edges()
	
	if id == "":
		return false

	var killed_ids = GlobalSave.save_data.get("boss_progress", {}).get("killed_ids", [])

	if typeof(killed_ids) != TYPE_ARRAY:
		return false

	return killed_ids.has(id)


func MarkBossKilled(depth: int, boss_id: String) -> void:
	_EnsureBossProgress()
	if !(depth in GlobalSave.save_data.boss_progress.killed_depths):
		GlobalSave.save_data.boss_progress.killed_depths.append(depth)

	if boss_id != "" and !(boss_id in GlobalSave.save_data.boss_progress.killed_ids):
		GlobalSave.save_data.boss_progress.killed_ids.append(boss_id)


func CanSpawnBossAtDepth(depth: int) -> bool:
	if !HasBossAtDepth(depth):
		return false
	if HasBossBeenKilledAtDepth(depth):
		return false
	return true


func _MakeBossUID(lane_index: int, depth: int, boss_id: String) -> String:
	return "boss_%s_%s_%s" % [str(lane_index), str(depth), boss_id]


func GenerateBossBlock(depth: int, lane_index: int, normal_block_hp, normal_coin_reward: int = 0) -> Dictionary:
	var boss_id := GetBossIDAtDepth(depth)

	if boss_id == "":
		return {}

	return GenerateBossBlockByID(
		boss_id,
		depth,
		lane_index,
		normal_block_hp,
		normal_coin_reward
	)


func TryGenerateBossBlock(depth: int, lane_index: int, normal_block_hp, normal_coin_reward: int = 0) -> Dictionary:
	if !CanSpawnBossAtDepth(depth):
		return {}

	return GenerateBossBlock(depth, lane_index, normal_block_hp, normal_coin_reward)

func IsBossBlock(block_data: Dictionary) -> bool:
	return bool(block_data.get("is_boss", false))


func GetBossRewardsByID(boss_id: String) -> Dictionary:
	var boss_data := GetBossDataByID(boss_id)

	if boss_data.is_empty():
		return {
			"coins": 0,
			"crystals": 0,
			"energy": 0,
			"dust": 0,
			"drop_table": [],
			"unlocks_on_kill": []
		}

	var guaranteed_rewards = boss_data.get("guaranteed_rewards", {})

	return {
		"coins": int(guaranteed_rewards.get("coins", 0)),
		"crystals": int(guaranteed_rewards.get("crystals", 0)),
		"energy": int(guaranteed_rewards.get("energy", 0)),
		"dust": int(guaranteed_rewards.get("dust", 0)),
		"drop_table": boss_data.get("drop_table", []).duplicate(true),
		"unlocks_on_kill": []
	}

func GetBossRewardsFromBlock(block_data: Dictionary) -> Dictionary:
	if !IsBossBlock(block_data):
		return {
			"coins": 0,
			"crystals": 0,
			"energy": 0,
			"dust": 0,
			"drop_table": [],
			"unlocks_on_kill": []
		}

	var boss_id := str(block_data.get("boss_id", ""))
	var rewards := GetBossRewardsByID(boss_id)

	# add scaled coin reward from block itself
	rewards["coins"] += int(block_data.get("reward_coins", 0))
	rewards["crystals"] = int(rewards["crystals"] * GlobalStats.GetBossRewardCrystalMulti())
	
	#boss_reward_mult
	rewards["coins"] = int(rewards["coins"] * GlobalStats.GetBossRewardMulti())
	rewards["energy"] = int(rewards["energy"] * GlobalStats.GetBossRewardMulti())
	rewards["crystals"] = int(rewards["crystals"] * GlobalStats.GetBossRewardMulti())
	rewards["dust"] = int(rewards.get("dust", 0) * GlobalStats.GetBossRewardMulti())
	return rewards


func OnBossKilled(block_data: Dictionary) -> Dictionary:
	if !IsBossBlock(block_data):
		return {}

	var depth := int(block_data.get("depth", -1))
	var boss_id := str(block_data.get("boss_id", ""))

	MarkBossKilled(depth, boss_id)

	return GetBossRewardsFromBlock(block_data)

func GetNextBossDepth(from_depth: int) -> int:
	var next_depth := -1

	for depth in boss_depth_map.keys():
		var d := int(depth)
		if d > from_depth:
			if next_depth == -1 or d < next_depth:
				next_depth = d

	return next_depth

func GetBossIcon(boss_id):
	var boss_data = GlobalBossDb.GetBossDataByID(boss_id)
	return load("res://data/boss_icons/"+boss_data.boss_icon+".tres")

func _RollBossRelicDrop(drop_table: Array) -> String:
	if drop_table.is_empty():
		return ""

	var valid_entries: Array = []

	for entry_value in drop_table:
		var entry := str(entry_value).strip_edges()

		if entry == "":
			continue

		if entry == RANDOM_RELIC_DROP_ID:
			valid_entries.append(entry)
			continue

		# Backward compatibility if you ever put a specific relic id again.
		if GlobalRelicDb.HasRelicData(entry):
			valid_entries.append(entry)

	if valid_entries.is_empty():
		return ""

	var rolled_entry := str(valid_entries[randi() % valid_entries.size()])

	if rolled_entry == RANDOM_RELIC_DROP_ID:
		return GlobalRelicDb.GetRandomRelicID()

	return rolled_entry
	

func GenerateBossBlockByID(
	boss_id: String,
	depth: int,
	lane_index: int,
	normal_block_hp,
	normal_coin_reward: int = 0
) -> Dictionary:
	boss_id = boss_id.strip_edges()

	if boss_id == "":
		return {}

	var boss_data := GetBossDataByID(boss_id)

	if boss_data.is_empty():
		return {}

	var hp_multiplier := float(boss_data.get("hp_multiplier", 10.0))
	var coin_mult := float(boss_data.get("coin_reward_multiplier", 1.0))

	var boss_hp := GlobalBigNumber.MulFloat(
		GlobalBigNumber.ToBig(normal_block_hp),
		hp_multiplier
	)

	var reward_coins := int(round(float(normal_coin_reward) * coin_mult))

	return {
		"uid": _MakeBossUID(lane_index, depth, boss_id),
		"type": "boss",
		"is_boss": true,
		"boss_id": boss_id,
		"name": str(boss_data.get("name", boss_id)),
		"depth": depth,
		"lane_index": lane_index,
		"hp": boss_hp.duplicate(true),
		"max_hp": boss_hp.duplicate(true),
		"reward_coin_multiplier": coin_mult,
		"reward_coins": reward_coins,
		"icon_key": str(boss_data.get("icon_key", "")),
		"special_type": str(boss_data.get("special_type", "none")),
		"special_values": boss_data.get("special_values", {}).duplicate(true)
	}
