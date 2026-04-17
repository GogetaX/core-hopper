extends Node
const MAX_ACTIVE_RELIC_SLOTS = 4
const RELIC_DB_PATH := "res://data/relics/relic_db.json"

var relic_db: Dictionary = {}

func _ready() -> void:
	LoadRelicDatabase()


func LoadRelicDatabase(path: String = RELIC_DB_PATH) -> bool:
	relic_db.clear()

	if !FileAccess.file_exists(path):
		push_warning("LoadRelicDatabase: file not found -> " + path)
		return false

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("LoadRelicDatabase: failed to open -> " + path)
		return false

	var text := file.get_as_text()
	file.close()

	var json := JSON.new()
	var err := json.parse(text)
	if err != OK:
		push_warning("LoadRelicDatabase: invalid json -> " + path)
		return false

	var data = json.data
	if typeof(data) != TYPE_DICTIONARY:
		push_warning("LoadRelicDatabase: root must be a dictionary")
		return false

	var relics_data = data.get("relics", {})
	if typeof(relics_data) != TYPE_DICTIONARY:
		relics_data = data

	if typeof(relics_data) != TYPE_DICTIONARY:
		push_warning("LoadRelicDatabase: missing relics dictionary")
		return false

	for relic_id_value in relics_data:
		var relic_id := str(relic_id_value)
		var relic_data = relics_data[relic_id_value]

		if typeof(relic_data) != TYPE_DICTIONARY:
			continue

		relic_db[relic_id] = relic_data.duplicate(true)
		relic_db[relic_id]["id"] = relic_id

	return true


func IsRelicDatabaseLoaded() -> bool:
	return !relic_db.is_empty()


func HasRelicData(relic_id: String) -> bool:
	return relic_db.has(relic_id)


func GetRelicDataByID(relic_id: String) -> Dictionary:
	if relic_db.has(relic_id):
		return relic_db[relic_id].duplicate(true)
	return {}


func GetRelicRankData(relic_id: String, rank: int = -1) -> Dictionary:
	var relic_data := GetRelicDataByID(relic_id)
	if relic_data.is_empty():
		return {}

	var rank_data = relic_data.get("rank_data", {})
	if typeof(rank_data) != TYPE_DICTIONARY:
		return {}

	var use_rank := rank
	if use_rank < 0:
		use_rank = GetOwnedRelicRank(relic_id)

	var rank_key := str(use_rank)
	if rank_data.has(rank_key) and typeof(rank_data[rank_key]) == TYPE_DICTIONARY:
		return rank_data[rank_key].duplicate(true)

	return {}


func _BuildCleanRelicInventory() -> Dictionary:
	return {
		"equipped_ids": [],
		"owned": {},
		"dust": 0,
		"unlocked_slots": 2
	}


func SyncRelicInv():
	_EnsureRelicInventory()
	
func _EnsureRelicInventory() -> void:
	if !GlobalSave.save_data.has("relic_inv") or typeof(GlobalSave.save_data.relic_inv) != TYPE_DICTIONARY:
		GlobalSave.save_data["relic_inv"] = _BuildCleanRelicInventory()
		return

	if !GlobalSave.save_data.relic_inv.has("equipped_ids") or typeof(GlobalSave.save_data.relic_inv.equipped_ids) != TYPE_ARRAY:
		GlobalSave.save_data.relic_inv["equipped_ids"] = []

	if !GlobalSave.save_data.relic_inv.has("owned") or typeof(GlobalSave.save_data.relic_inv.owned) != TYPE_DICTIONARY:
		GlobalSave.save_data.relic_inv["owned"] = {}


	if !GlobalSave.save_data.relic_inv.has("unlocked_slots") or typeof(GlobalSave.save_data.relic_inv.unlocked_slots) != TYPE_INT:
		GlobalSave.save_data.relic_inv["unlocked_slots"] = 2


func GetRelicInventory() -> Dictionary:
	_EnsureRelicInventory()
	return GlobalSave.save_data.relic_inv





func IsRelicOwned(relic_id: String) -> bool:
	_EnsureRelicInventory()
	return GlobalSave.save_data.relic_inv.owned.has(relic_id)


func GetOwnedRelicSaveData(relic_id: String) -> Dictionary:
	_EnsureRelicInventory()

	if !GlobalSave.save_data.relic_inv.owned.has(relic_id):
		return {}

	var owned_data = GlobalSave.save_data.relic_inv.owned[relic_id]
	if typeof(owned_data) != TYPE_DICTIONARY:
		return {}

	return owned_data.duplicate(true)


func GetOwnedRelicRank(relic_id: String) -> int:
	var owned_data := GetOwnedRelicSaveData(relic_id)
	if owned_data.is_empty():
		return 1
	return maxi(1, int(owned_data.get("rank", 1)))


func GetEquippedRelicIds() -> Array:
	_EnsureRelicInventory()

	var result: Array = []
	var max_slots := GlobalStats.GetUnlockedRelicSlots()

	for relic_id_value in GlobalSave.save_data.relic_inv.equipped_ids:
		if result.size() >= max_slots:
			break

		var relic_id := str(relic_id_value)
		if relic_id == "":
			continue
		if !IsRelicOwned(relic_id):
			continue
		if !HasRelicData(relic_id):
			continue
		if relic_id in result:
			continue

		result.append(relic_id)

	return result


func GetAllOwnedRelics() -> Array:
	_EnsureRelicInventory()

	var result: Array = []
	var equipped_ids := GetEquippedRelicIds()

	for relic_id_value in GlobalSave.save_data.relic_inv.owned:
		var relic_id := str(relic_id_value)
		var save_entry = GlobalSave.save_data.relic_inv.owned[relic_id_value]

		if typeof(save_entry) != TYPE_DICTIONARY:
			continue
		if !HasRelicData(relic_id):
			continue

		result.append({
			"id": relic_id,
			"db_data": GetRelicDataByID(relic_id),
			"save_data": save_entry.duplicate(true),
			"rank": maxi(1, int(save_entry.get("rank", 1))),
			"dupes": maxi(0, int(save_entry.get("dupes", 0))),
			"is_equipped": relic_id in equipped_ids
		})

	return result


func GetAllEquippedRelics() -> Array:
	var result: Array = []

	for relic_id in GetEquippedRelicIds():
		var save_entry := GetOwnedRelicSaveData(relic_id)

		result.append({
			"id": relic_id,
			"db_data": GetRelicDataByID(relic_id),
			"save_data": save_entry,
			"is_equipped":true,
			"rank": maxi(1, int(save_entry.get("rank", 1))),
			"dupes": maxi(0, int(save_entry.get("dupes", 0))),
			"rank_data": GetRelicRankData(relic_id)
		})

	return result
	


func GetEffectStr(relic_id: String, rank: int) -> String:
	var relic_rank_data := GetRelicRankData(relic_id, rank)
	var relic_data := GetRelicDataByID(relic_id)

	if relic_rank_data.is_empty() or relic_data.is_empty():
		return ""

	var effect_value: float = float(relic_rank_data.get("effect_value", 0.0))
	var effect_format: String = str(relic_data.get("effect_format", ""))
	var result_value: float = 0.0

	match effect_format:
		"multiplier":
			# 1.10 => +10%
			result_value = (effect_value - 1.0) * 100.0

		"flat":
			# 0.02 => +2%
			result_value = effect_value * 100.0

		"value":
			# raw number, no %
			return _FormatRelicNumber(effect_value)

		_:
			return str(effect_value)

	var start_sign = "+"
	if result_value < 0.0:
		start_sign = ""

	return start_sign + _FormatRelicNumber(result_value) + "%"
	
	
func _FormatRelicNumber(value: float) -> String:
	var rounded := snappedf(value, 0.1)

	if is_equal_approx(rounded, round(rounded)):
		return str(int(round(rounded)))

	return str(rounded)

func GetRelicIcon(relic_icon_str)->Texture2D:
	return load("res://art/relics/"+relic_icon_str+".tres")

func IsRelicEquipped(relic_id: String) -> bool:
	return relic_id in GetEquippedRelicIds()


func CanEquipRelic(relic_id: String) -> bool:
	if relic_id == "":
		return false
	if !IsRelicOwned(relic_id):
		return false
	if !HasRelicData(relic_id):
		return false
	if IsRelicEquipped(relic_id):
		return false

	var equipped_ids := GetEquippedRelicIds()
	return equipped_ids.size() < GlobalStats.GetUnlockedRelicSlots()


func EquipRelic(relic_id: String) -> bool:
	_EnsureRelicInventory()

	if !CanEquipRelic(relic_id):
		return false

	GlobalSave.save_data.relic_inv.equipped_ids.append(relic_id)
	return true


func UnequipRelic(relic_id: String) -> bool:
	_EnsureRelicInventory()

	var equipped_ids: Array = GlobalSave.save_data.relic_inv.equipped_ids
	var index := equipped_ids.find(relic_id)

	if index == -1:
		return false

	equipped_ids.remove_at(index)
	return true


func ToggleRelicEquipped(relic_id: String) -> bool:
	if IsRelicEquipped(relic_id):
		return UnequipRelic(relic_id)
	return EquipRelic(relic_id)


func UnequipAllRelics() -> void:
	_EnsureRelicInventory()
	GlobalSave.save_data.relic_inv.equipped_ids.clear()


func GetAllRelicIDs() -> Array:
	var result: Array = []

	for relic_id in relic_db.keys():
		result.append(str(relic_id))

	return result


func GetRandomRelicID() -> String:
	var relic_ids := GetAllRelicIDs()
	if relic_ids.is_empty():
		return ""

	return str(relic_ids[randi() % relic_ids.size()])


func AddOwnedRelic(relic_id: String, amount: int = 1) -> Dictionary:
	_EnsureRelicInventory()

	if relic_id == "" or amount <= 0:
		return {}

	if !HasRelicData(relic_id):
		return {}

	if !GlobalSave.save_data.relic_inv.owned.has(relic_id):
		GlobalSave.save_data.relic_inv.owned[relic_id] = {
			"rank": 1,
			"dupes": 0
		}

		var extra_dupes := maxi(0, amount - 1)
		if extra_dupes > 0:
			GlobalSave.save_data.relic_inv.owned[relic_id]["dupes"] = extra_dupes

		return {
			"relic_id": relic_id,
			"is_new": true,
			"added_dupes": extra_dupes
		}

	var current_dupes := int(GlobalSave.save_data.relic_inv.owned[relic_id].get("dupes", 0))
	GlobalSave.save_data.relic_inv.owned[relic_id]["dupes"] = current_dupes + amount

	return {
		"relic_id": relic_id,
		"is_new": false,
		"added_dupes": amount
	}

func GetEffectTypeDescription(effect_type: String) -> String:
	match effect_type.strip_edges().to_lower():
		"bot_damage_mult":
			return "Bot Damage"
		"tap_damage_mult":
			return "Tap Damage"
		"crit_chance_flat":
			return "Crit Chance"
		"boss_damage_mult":
			return "Boss Damage"
		"offline_gain_mult":
			return "Offline Rewards"
		_:
			return "Unknown Effect"

func GetOwnedRelicUpgradeCost(relic_id: String) -> Dictionary:
	if !IsRelicOwned(relic_id):
		return {}

	if !HasRelicData(relic_id):
		return {}

	var relic_data := GetRelicDataByID(relic_id)
	var current_rank := GetOwnedRelicRank(relic_id)
	var max_rank := maxi(1, int(relic_data.get("max_rank", 1)))

	if current_rank >= max_rank:
		return {}

	var current_rank_data := GetRelicRankData(relic_id, current_rank)
	if current_rank_data.is_empty():
		return {}

	var upgrade_cost = current_rank_data.get("upgrade_cost", {})
	if typeof(upgrade_cost) != TYPE_DICTIONARY:
		return {}

	return upgrade_cost.duplicate(true)


func _CanAffordRelicCost(cost: Dictionary) -> bool:
	for currency_key in cost:
		var currency_type := str(currency_key)
		var needed := maxi(0, int(cost[currency_key]))

		if needed <= 0:
			continue

		if GlobalSave.GetCurrency(currency_type) < needed:
			return false

	return true


func _ConsumeRelicCost(cost: Dictionary) -> void:
	for currency_key in cost:
		var currency_type := str(currency_key)
		var needed := maxi(0, int(cost[currency_key]))

		if needed <= 0:
			continue

		match currency_type:
			"dust":
				_EnsureRelicInventory()
				GlobalSave.save_data.relic_inv["dust"] = maxi(
					0,
					int(GlobalSave.save_data.relic_inv.get("dust", 0)) - needed
				)
			_:
				GlobalSave.RemoveCurrency(currency_type, needed)


func CanUpgradeOwned(relic_id: String) -> bool:
	if !IsRelicOwned(relic_id):
		print("1")
		return false

	if !HasRelicData(relic_id):
		print("2")
		return false

	var relic_data := GetRelicDataByID(relic_id)
	var owned_data := GetOwnedRelicSaveData(relic_id)

	if relic_data.is_empty() or owned_data.is_empty():
		print("3")
		return false

	var current_rank := maxi(1, int(owned_data.get("rank", 1)))
	var current_dupes := maxi(0, int(owned_data.get("dupes", 0)))
	var max_rank := maxi(1, int(relic_data.get("max_rank", 1)))

	if current_rank >= max_rank:
		print("4")
		return false

	var current_rank_data := GetRelicRankData(relic_id, current_rank)
	if current_rank_data.is_empty():
		print("5")
		return false

	var dupes_required := maxi(0, int(current_rank_data.get("dupes_required", 0)))
	if current_dupes < dupes_required:
		print("6")
		return false

	var upgrade_cost = current_rank_data.get("upgrade_cost", {})
	if typeof(upgrade_cost) != TYPE_DICTIONARY:
		upgrade_cost = {}

	return _CanAffordRelicCost(upgrade_cost)


func UpgradeRelicByID(relic_id: String) -> bool:
	_EnsureRelicInventory()

	if !CanUpgradeOwned(relic_id):
		return false

	var relic_data := GetRelicDataByID(relic_id)
	var owned_data := GetOwnedRelicSaveData(relic_id)

	if relic_data.is_empty() or owned_data.is_empty():
		return false

	var current_rank := maxi(1, int(owned_data.get("rank", 1)))
	var max_rank := maxi(1, int(relic_data.get("max_rank", 1)))
	var current_rank_data := GetRelicRankData(relic_id, current_rank)

	if current_rank_data.is_empty():
		return false

	var dupes_required := maxi(0, int(current_rank_data.get("dupes_required", 0)))
	var upgrade_cost = current_rank_data.get("upgrade_cost", {})
	if typeof(upgrade_cost) != TYPE_DICTIONARY:
		upgrade_cost = {}

	_ConsumeRelicCost(upgrade_cost)

	owned_data["dupes"] = maxi(0, int(owned_data.get("dupes", 0)) - dupes_required)
	owned_data["rank"] = mini(current_rank + 1, max_rank)

	GlobalSave.save_data.relic_inv.owned[relic_id] = owned_data
	return true
