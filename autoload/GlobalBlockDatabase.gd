extends Node
class_name BlockDatabase

const ARCHETYPES_PATH := "res://data/blocks/block_archetypes.json"
const DEPTH_BANDS_PATH := "res://data/blocks/depth_bands.json"

var archetypes: Dictionary = {}
var depth_bands: Array = []

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	load_data()


func load_data() -> void:
	archetypes.clear()
	depth_bands.clear()

	archetypes = _load_json_dictionary(ARCHETYPES_PATH)
	depth_bands = _load_json_array(DEPTH_BANDS_PATH)

	_validate_archetypes()
	_validate_depth_bands()
	_validate_depth_band_ranges()


func reload_data() -> void:
	load_data()


func is_loaded() -> bool:
	return not archetypes.is_empty() and not depth_bands.is_empty()


func get_archetype(block_id: String) -> Dictionary:
	if not archetypes.has(block_id):
		push_warning("BlockDatabase: Missing archetype for id '%s'" % block_id)
		return {}
	return archetypes[block_id]


func get_band_for_depth(depth: int) -> Dictionary:
	for band in depth_bands:
		var min_depth: int = int(band.get("min_depth", 0))
		var max_depth: int = int(band.get("max_depth", -1))

		if depth >= min_depth and depth <= max_depth:
			return band

	# Fallback: if depth is beyond all defined bands, use the last valid band
	if depth_bands.size() > 0:
		return depth_bands[depth_bands.size() - 1]

	push_error("BlockDatabase: No depth band found and no fallback available.")
	return {}


func spawn_block(depth: int, lane_index: int = -1) -> Dictionary:
	if not is_loaded():
		load_data()

	var band := get_band_for_depth(depth)
	if band.is_empty():
		return {}

	var spawn_pool: Array = band.get("spawn_pool", [])
	if spawn_pool.is_empty():
		push_error("BlockDatabase: spawn_pool is empty for depth %d" % depth)
		return {}

	var block_id := roll_block_id(spawn_pool)
	if block_id.is_empty():
		push_error("BlockDatabase: Failed to roll block id for depth %d" % depth)
		return {}

	var archetype := get_archetype(block_id)
	if archetype.is_empty():
		return {}

	return _BuildRuntimeBlock(depth, lane_index, block_id, archetype, band)


func get_next_block_uid(depth: int, lane_index: int) -> String:
	GlobalSave.save_data.meta.block_uid_serial += 1
	return "%s_%s_%s" % [str(depth), str(lane_index), str(GlobalSave.save_data.meta.block_uid_serial)]
	
func roll_block_id(spawn_pool: Array) -> String:
	if spawn_pool.is_empty():
		return ""

	var total_weight: int = 0

	for entry in spawn_pool:
		if typeof(entry) != TYPE_DICTIONARY:
			continue

		var weight: int = int(entry.get("weight", 0))
		if weight > 0:
			total_weight += weight

	if total_weight <= 0:
		push_error("BlockDatabase: spawn_pool total_weight <= 0")
		return ""

	var roll: int = _rng.randi_range(1, total_weight)
	var running_total: int = 0

	for entry in spawn_pool:
		if typeof(entry) != TYPE_DICTIONARY:
			continue

		var weight: int = int(entry.get("weight", 0))
		if weight <= 0:
			continue

		running_total += weight
		if roll <= running_total:
			return String(entry.get("id", ""))

	push_warning("BlockDatabase: Weighted roll fell through. Using last valid entry.")
	for i in range(spawn_pool.size() - 1, -1, -1):
		var entry = spawn_pool[i]
		if typeof(entry) == TYPE_DICTIONARY and int(entry.get("weight", 0)) > 0:
			return String(entry.get("id", ""))

	return ""


func preview_blocks_for_depth(depth: int, count: int = 10) -> Array:
	var results: Array = []
	for i in count:
		results.append(spawn_block(depth))
	return results


func get_depth_band_index(depth: int) -> int:
	for i in depth_bands.size():
		var band: Dictionary = depth_bands[i]
		var min_depth: int = int(band.get("min_depth", 0))
		var max_depth: int = int(band.get("max_depth", -1))
		if depth >= min_depth and depth <= max_depth:
			return i

	if depth_bands.size() > 0:
		return depth_bands.size() - 1

	return -1
	
func _validate_depth_band_ranges() -> void:
	for i in range(depth_bands.size()):
		var band = depth_bands[i]
		var min_depth := int(band.get("min_depth", 0))
		var max_depth := int(band.get("max_depth", -1))

		if min_depth > max_depth:
			push_error("Depth band %d has min_depth > max_depth" % i)

		if i > 0:
			var prev = depth_bands[i - 1]
			var prev_max := int(prev.get("max_depth", -1))
			if min_depth > prev_max + 1:
				push_warning("Gap between depth bands %d and %d" % [i - 1, i])
			elif min_depth <= prev_max:
				push_error("Overlap between depth bands %d and %d" % [i - 1, i])

func _validate_archetypes() -> void:
	for block_id in archetypes.keys():
		var data = archetypes[block_id]

		if typeof(data) != TYPE_DICTIONARY:
			push_error("BlockDatabase: Archetype '%s' is not a dictionary." % block_id)
			continue

		if not data.has("name"):
			push_warning("BlockDatabase: Archetype '%s' missing 'name'." % block_id)
		if not data.has("hp_multiplier"):
			push_warning("BlockDatabase: Archetype '%s' missing 'hp_multiplier'." % block_id)
		if not data.has("rarity"):
			push_warning("BlockDatabase: Archetype '%s' missing 'rarity'." % block_id)


func _validate_depth_bands() -> void:
	if depth_bands.is_empty():
		push_error("BlockDatabase: depth_bands is empty.")
		return

	for i in depth_bands.size():
		var band = depth_bands[i]

		if typeof(band) != TYPE_DICTIONARY:
			push_error("BlockDatabase: Depth band at index %d is not a dictionary." % i)
			continue

		if not band.has("min_depth"):
			push_warning("BlockDatabase: Depth band %d missing 'min_depth'." % i)
		if not band.has("max_depth"):
			push_warning("BlockDatabase: Depth band %d missing 'max_depth'." % i)
		if not band.has("base_hp"):
			push_warning("BlockDatabase: Depth band %d missing 'base_hp'." % i)
		if not band.has("reward_multiplier"):
			push_warning("BlockDatabase: Depth band %d missing 'reward_multiplier'." % i)
		if not band.has("spawn_pool"):
			push_warning("BlockDatabase: Depth band %d missing 'spawn_pool'." % i)

		var spawn_pool: Array = band.get("spawn_pool", [])
		for j in spawn_pool.size():
			var entry = spawn_pool[j]
			if typeof(entry) != TYPE_DICTIONARY:
				push_error("BlockDatabase: spawn_pool entry %d in band %d is not a dictionary." % [j, i])
				continue

			var block_id: String = String(entry.get("id", ""))
			if block_id.is_empty():
				push_warning("BlockDatabase: spawn_pool entry %d in band %d missing 'id'." % [j, i])
				continue

			if not archetypes.has(block_id):
				push_error("BlockDatabase: spawn_pool entry references missing archetype '%s'." % block_id)


func _load_json_dictionary(path: String) -> Dictionary:
	var data = _load_json(path)
	if typeof(data) != TYPE_DICTIONARY:
		push_error("BlockDatabase: Expected dictionary JSON at %s" % path)
		return {}
	return data


func _load_json_array(path: String) -> Array:
	var data = _load_json(path)
	if typeof(data) != TYPE_ARRAY:
		push_error("BlockDatabase: Expected array JSON at %s" % path)
		return []
	return data


func _load_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		push_error("BlockDatabase: File does not exist: %s" % path)
		return null

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("BlockDatabase: Failed to open file: %s" % path)
		return null

	var text := file.get_as_text()
	file.close()

	var json := JSON.new()
	var error := json.parse(text)

	if error != OK:
		push_error(
			"BlockDatabase: JSON parse error in %s at line %d: %s" %
			[path, json.get_error_line(), json.get_error_message()]
		)
		return null

	return json.data

func CreateBlockForLane(depth: int, lane_index: int) -> Dictionary:
	if not is_loaded():
		load_data()

	var band := get_band_for_depth(depth)
	if band.is_empty():
		push_error("No depth band found for depth %d" % depth)
		return {}

	var spawn_pool: Array = band.get("spawn_pool", [])
	if spawn_pool.is_empty():
		push_error("spawn_pool is empty for depth %d" % depth)
		return {}

	var block_id := _PickBlockIdFromSpawnPool(spawn_pool)
	if block_id == "":
		push_error("Failed picking block id for depth %d" % depth)
		return {}

	var archetype: Dictionary = archetypes.get(block_id, {})
	if archetype.is_empty():
		push_error("Missing archetype for id: %s" % block_id)
		return {}

	return _BuildRuntimeBlock(depth, lane_index, block_id, archetype, band)
	
func _GetDepthBand(depth: int) -> Dictionary:
	return get_band_for_depth(depth)


func _PickBlockIdFromSpawnPool(spawn_pool: Array) -> String:
	if spawn_pool.is_empty():
		return ""

	var total_weight := 0
	for entry in spawn_pool:
		total_weight += int(entry.weight)

	if total_weight <= 0:
		return ""

	var roll := randi_range(1, total_weight)
	var running := 0

	for entry in spawn_pool:
		running += int(entry.weight)
		if roll <= running:
			return str(entry.id)

	return str(spawn_pool[0].id)

func _BuildBlockUid(depth: int, lane_index: int) -> String:
	GlobalSave.save_data.meta.block_uid_serial = int(GlobalSave.save_data.meta.get("block_uid_serial", 0)) + 1
	return "%s_%s_%s" % [
		str(depth),
		str(lane_index),
		str(GlobalSave.save_data.meta.block_uid_serial)
	]
	
func RollBlockDrops(block_data: Dictionary, reward_mult: float = 1.0) -> Dictionary:
	var result := {
		"coins": 0,
		"crystals": 0,
		"energy": 0
	}

	var block_id := str(block_data.get("id", ""))
	if block_id == "":
		return result

	var archetype: Dictionary = archetypes.get(block_id, {})
	if archetype.is_empty():
		return result

	var drops: Dictionary = archetype.get("drops", {})
	if drops.is_empty():
		return result

	for currency in drops.keys():
		var drop_data: Dictionary = drops.get(currency, {})
		var weight := float(drop_data.get("weight", 0.0))
		if weight <= 0.0:
			continue

		if _rng.randf() > weight:
			continue

		var min_amount := int(drop_data.get("min", 0))
		var max_amount := int(drop_data.get("max", min_amount))
		var rolled_amount := _rng.randi_range(min_amount, max_amount)

		if currency == "coins":
			var reward_multiplier := float(block_data.get("reward_multiplier", 1.0))
			rolled_amount = int(round(float(rolled_amount) * reward_multiplier))

		rolled_amount = int(round(float(rolled_amount) * reward_mult))

		if rolled_amount > 0:
			result[currency] = int(result.get(currency, 0)) + rolled_amount

	return result
	

func GetAverageCoinsForDepth(depth: int) -> float:
	if not is_loaded():
		load_data()

	var band := get_band_for_depth(depth)
	if band.is_empty():
		return 0.0

	var spawn_pool: Array = band.get("spawn_pool", [])
	if spawn_pool.is_empty():
		return 0.0

	var band_reward_multiplier := float(band.get("reward_multiplier", 1.0))

	var total_weight := 0.0
	var weighted_coin_sum := 0.0

	for entry in spawn_pool:
		if typeof(entry) != TYPE_DICTIONARY:
			continue

		var spawn_weight := float(entry.get("weight", 0.0))
		if spawn_weight <= 0.0:
			continue

		var block_id := String(entry.get("id", "")).strip_edges()
		if block_id == "":
			continue

		var archetype: Dictionary = get_archetype(block_id)
		if archetype.is_empty():
			continue

		var drops: Dictionary = archetype.get("drops", {})
		var coin_drop: Dictionary = drops.get("coins", {})
		if coin_drop.is_empty():
			total_weight += spawn_weight
			continue

		var coin_chance := float(coin_drop.get("weight", 0.0))
		var min_amount := float(coin_drop.get("min", 0))
		var max_amount := float(coin_drop.get("max", min_amount))
		var avg_amount := (min_amount + max_amount) * 0.5

		var expected_coin_reward := coin_chance * avg_amount * band_reward_multiplier

		total_weight += spawn_weight
		weighted_coin_sum += expected_coin_reward * spawn_weight

	if total_weight <= 0.0:
		return 0.0

	return weighted_coin_sum / total_weight

func _GetExpectedDropAmount(archetype: Dictionary, currency: String, reward_multiplier: float = 1.0) -> float:
	var drops: Dictionary = archetype.get("drops", {})
	if drops.is_empty():
		return 0.0

	var drop_data: Dictionary = drops.get(currency, {})
	if drop_data.is_empty():
		return 0.0

	var chance := clampf(float(drop_data.get("weight", 0.0)), 0.0, 1.0)
	if chance <= 0.0:
		return 0.0

	var min_amount := float(drop_data.get("min", 0))
	var max_amount := float(drop_data.get("max", min_amount))
	var avg_amount := (min_amount + max_amount) * 0.5

	var expected := chance * avg_amount
	if currency == "coins":
		expected *= reward_multiplier

	return expected

func _GetContinuousBandBaseHp(band_index: int) -> float:
	var band_base := float(depth_bands[band_index].get("base_hp", 1.0))
	if band_index <= 0:
		return band_base

	var prev_band = depth_bands[band_index - 1]
	var prev_base := _GetContinuousBandBaseHp(band_index - 1)
	var prev_steps := int(prev_band.get("max_depth", 0)) - int(prev_band.get("min_depth", 0)) + 1
	var prev_growth := float(prev_band.get("depth_growth", 1.01))
	var prev_tail_base := prev_base * pow(prev_growth, prev_steps)

	return max(band_base, prev_tail_base)

func _BuildRuntimeBlock(depth: int, lane_index: int, block_id: String, archetype: Dictionary, band: Dictionary) -> Dictionary:
	var band_index := get_depth_band_index(depth)
	var carried_base := _GetContinuousBandBaseHp(band_index)
	var base_hp := float(band.get("base_hp", 1.0))
	var effective_base_hp := lerpf(base_hp, carried_base, 0.35)
	var hp_multiplier := float(archetype.get("hp_multiplier", 1.0))
	var reward_multiplier := float(band.get("reward_multiplier", 1.0))

	var band_start_depth := int(band.get("min_depth", depth))
	var depth_in_band = max(0, depth - band_start_depth)
	var depth_growth := float(band.get("depth_growth", 1.01))
	var min_hit_damage := float(band.get("min_hit_damage", 0.0))

	var final_hp = max(1, roundi(
	effective_base_hp * hp_multiplier * pow(depth_growth, depth_in_band)
	))
	# Compatibility fields for older code paths / boss generation.
	var base_coin_reward := _GetExpectedDropAmount(archetype, "coins", 1.0)
	var final_coin_reward := _GetExpectedDropAmount(archetype, "coins", reward_multiplier)

	return {
		"uid": _BuildBlockUid(depth, lane_index),
		"id": block_id,
		"name": str(archetype.get("name", block_id)),
		"depth": depth,
		"lane_index": lane_index,

		"base_hp": base_hp,
		"hp_multiplier": hp_multiplier,
		"max_hp": final_hp,
		"hp": final_hp,

		# Keep these only for compatibility until all callers are migrated.
		"reward_type": "coins",
		"base_reward_amount": base_coin_reward,
		"reward_multiplier": reward_multiplier,
		"reward_amount": max(1, roundi(final_coin_reward)),

		# New source of truth
		"drops": archetype.get("drops", {}).duplicate(true),

		"rarity": str(archetype.get("rarity", "common")),
		"color": str(archetype.get("color", "gray")),
		"tags": archetype.get("tags", []).duplicate(true),
		"depth_growth": depth_growth,
		"min_hit_damage": min_hit_damage
	}
