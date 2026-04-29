extends Node

func _EnsureSchema() -> void:
	if !GlobalSave.save_data.has("reward_chests") or typeof(GlobalSave.save_data.reward_chests) != TYPE_DICTIONARY:
		GlobalSave.save_data["reward_chests"] = {"queue": []}
		return

	if !GlobalSave.save_data.reward_chests.has("queue") or typeof(GlobalSave.save_data.reward_chests.queue) != TYPE_ARRAY:
		GlobalSave.save_data.reward_chests["queue"] = []
		

func MakeBossRewardChest(boss_id: String, boss_name: String, rewards: Dictionary) -> Dictionary:
	return {
		"chest_id": "boss_%s_%s" % [boss_id, str(Time.get_unix_time_from_system())],
		"source_type": "boss",
		"source_id": boss_id,
		"source_name": boss_name,
		"created_unix": Time.get_unix_time_from_system(),
		"rewards": {
			"coins": int(rewards.get("coins", 0)),
			"crystals": int(rewards.get("crystals", 0)),
			"energy": int(rewards.get("energy", 0)),
			"dust": int(rewards.get("dust", 0)),
			"relic_ids": rewards.get("relic_ids", []).duplicate(true)
		}
	}


func AddChest(chest_data: Dictionary) -> void:
	_EnsureSchema()
	GlobalSave.save_data.reward_chests.queue.append(chest_data)
	GlobalSave.SyncSave()


func GetAllChests() -> Array:
	_EnsureSchema()
	return GlobalSave.save_data.reward_chests.queue


func GetChestCount() -> int:
	_EnsureSchema()
	return GlobalSave.save_data.reward_chests.queue.size()


func HasChests() -> bool:
	return GetChestCount() > 0


func OpenChest(index: int = 0) -> Dictionary:
	_EnsureSchema()

	if index < 0 or index >= GlobalSave.save_data.reward_chests.queue.size():
		return {}

	var chest: Dictionary = GlobalSave.save_data.reward_chests.queue[index]
	GlobalSave.save_data.reward_chests.queue.remove_at(index)

	var rewards: Dictionary = chest.get("rewards", {})

	var coins := int(rewards.get("coins", 0))
	var crystals := int(rewards.get("crystals", 0))
	var energy := int(rewards.get("energy", 0))
	var dust := int(rewards.get("dust", 0))
	var relic_ids: Array = rewards.get("relic_ids", [])

	if coins > 0:
		GlobalSave.AddCurrency("coins", coins)
	if crystals > 0:
		GlobalSave.AddCurrency("crystals", crystals)
	if energy > 0:
		GlobalSave.AddCurrency("energy", energy)
	if dust > 0:
		GlobalSave.AddCurrency("dust", dust)

	for relic_id_value in relic_ids:
		var relic_id := str(relic_id_value)
		if relic_id == "":
			continue
		if !GlobalRelicDb.HasRelicData(relic_id):
			continue
		GlobalRelicDb.AddOwnedRelic(relic_id, 1)

	GlobalSave.SyncSave()
	return chest


func OpenAllChests() -> Array:
	_EnsureSchema()

	var opened: Array = []
	while !GlobalSave.save_data.reward_chests.queue.is_empty():
		var chest = OpenChest(0)
		if chest.is_empty():
			break
		opened.append(chest)

	return opened

func _EnsureRewardChestSchema() -> void:
	if !GlobalSave.save_data.has("reward_chests") or typeof(GlobalSave.save_data.reward_chests) != TYPE_DICTIONARY:
		GlobalSave.save_data["reward_chests"] = {"queue": []}
		return

	if !GlobalSave.save_data.reward_chests.has("queue") or typeof(GlobalSave.save_data.reward_chests.queue) != TYPE_ARRAY:
		GlobalSave.save_data.reward_chests["queue"] = []


func AddRewardChest(chest_data: Dictionary) -> void:
	_EnsureRewardChestSchema()

	GlobalSave.save_data.reward_chests.queue.append(chest_data)
	GlobalSave.SyncSave()


func GetRewardChestQueue() -> Array:
	_EnsureRewardChestSchema()
	return GlobalSave.save_data.reward_chests.queue


func GetRewardChestCount() -> int:
	_EnsureRewardChestSchema()
	return GlobalSave.save_data.reward_chests.queue.size()
