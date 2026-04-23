extends Node

const OFFLINE_MIN_SECONDS := 60
const OFFLINE_BASE_CAP_SECONDS := 7200
const OFFLINE_MAX_EFFICIENCY := 0.85

const SLOT_EASY_COINS := "easy_coins"
const SLOT_RECOMMENDED := "recommended"
const SLOT_TOO_HARD := "too_hard"

const RECOMMENDED_MAX_CLEAR_SECONDS := 6.0
const TOO_HARD_MIN_CLEAR_SECONDS := 12.0
const EASY_LOOKBACK_BANDS := 1


func ProcessOfflineProgress() -> Dictionary:
	var now_unix := Time.get_unix_time_from_system()
	var last_saved := float(GlobalSave.save_data.meta.last_saved_unix)
	var offline_seconds = max(0, int(now_unix - last_saved))

	if offline_seconds < OFFLINE_MIN_SECONDS:
		return {
			"did_collect": false,
			"offline_seconds": offline_seconds,
			"capped_seconds": 0,
			"coins": 0,
			"crystals": 0,
			"energy": 0,
			"drop_data": []
		}
	print("1")
	var capped_seconds := mini(offline_seconds, GlobalStats.GetOfflineCapSeconds())
	print("1.1")
	var selected_band_index := GetSelectedOfflineBandIndex()
	print("1.2")
	var result := _SimulateSelectedBandOffline(capped_seconds, selected_band_index)
	print("2")
	result["coins"] = int(result["coins"] * GlobalStats.GetOfflineCoinGain())
	result["crystals"] = int(result["crystals"] * GlobalStats.GetOfflineCrystalGain())
	result["energy"] = int(result["energy"] * GlobalStats.GetOfflineEnergyGain())
	result["did_collect"] = true
	result["offline_seconds"] = offline_seconds
	result["capped_seconds"] = capped_seconds
	print("3")
	# keep your current final coin multiplier behavior
	result["coins"] = int(result["coins"] * GlobalStats.GetCoinYieldMultiplier())

	return result


func GetOfflineCapSeconds(plus_level: int = 0) -> int:
	var level := int(GlobalSave.save_data.global_upgrades.offline_gain_level) + plus_level
	var res: int = OFFLINE_BASE_CAP_SECONDS + (level * 1800)
	return int(res * GlobalStats.GetUpgradeValue("offline_efficiency"))


func GetOfflineEfficiency() -> float:
	var level := int(GlobalSave.save_data.global_upgrades.offline_gain_level)
	return min(OFFLINE_MAX_EFFICIENCY, 0.35 + (level * 0.10))


func GetAvailableBands() -> Dictionary:
	_EnsureOfflinePlannerData()

	if not GlobalBlockDatabase.is_loaded():
		GlobalBlockDatabase.load_data()

	var candidate_entries := _BuildVisibleBandEntries()
	if candidate_entries.is_empty():
		return {
			"selected_band_index": -1,
			"selected_slot": "",
			"total_offline_dps": 0.0,
			"bands": []
		}

	var recommended_band_index := _PickRecommendedBandIndex(candidate_entries)
	var easy_band_index := _PickEasyCoinBandIndex(candidate_entries, recommended_band_index)
	var hard_band_index := _PickTooHardBandIndex(candidate_entries, recommended_band_index)

	var resolved := _ResolveBandSlots(
		candidate_entries,
		easy_band_index,
		recommended_band_index,
		hard_band_index
	)

	var selected_band_index := int(GlobalSave.save_data.offline_mining.get("selected_band_index", -1))
	var visible_band_indexes := [
		int(resolved[SLOT_EASY_COINS]),
		int(resolved[SLOT_RECOMMENDED]),
		int(resolved[SLOT_TOO_HARD])
	]

	if not visible_band_indexes.has(selected_band_index):
		selected_band_index = int(resolved[SLOT_RECOMMENDED])
		GlobalSave.save_data.offline_mining["selected_band_index"] = selected_band_index

	var slot_titles := {
		SLOT_EASY_COINS: "Easy for Coins",
		SLOT_RECOMMENDED: "Recommended",
		SLOT_TOO_HARD: "Too Hard"
	}

	var selected_slot := SLOT_RECOMMENDED
	var final_bands: Array = []

	for slot in [SLOT_EASY_COINS, SLOT_RECOMMENDED, SLOT_TOO_HARD]:
		var band_index := int(resolved[slot])
		var entry := _GetEntryByBandIndex(candidate_entries, band_index).duplicate(true)
		entry["slot"] = slot
		entry["title"] = str(slot_titles.get(slot, slot))
		entry["is_selected"] = band_index == selected_band_index

		if band_index == selected_band_index:
			selected_slot = slot

		final_bands.append(entry)

	return {
		"selected_band_index": selected_band_index,
		"selected_slot": selected_slot,
		"total_offline_dps": _GetTotalOfflineDps() * GlobalStats.GetOfflineEfficiency(),
		"bands": final_bands
	}


func GetSelectedOfflineBandIndex() -> int:
	_EnsureOfflinePlannerData()

	var saved_band_index := int(GlobalSave.save_data.offline_mining.get("selected_band_index", -1))
	if saved_band_index >= 0 and saved_band_index < GlobalBlockDatabase.depth_bands.size():
		return saved_band_index

	var bands_data := GetAvailableBands()
	return int(bands_data.get("selected_band_index", -1))


func SetSelectedOfflineBand(band_index: int) -> void:
	_EnsureOfflinePlannerData()

	if band_index < 0 or band_index >= GlobalBlockDatabase.depth_bands.size():
		return

	GlobalSave.save_data.offline_mining["selected_band_index"] = band_index
	GlobalSave.SyncSave(false)


func _SimulateSelectedBandOffline(seconds: int, band_index: int) -> Dictionary:
	var rewards := {
		"coins": 0,
		"crystals": 0,
		"energy": 0,
		"drop_data": [],
		"band_index": band_index
	}

	if seconds <= 0:
		return rewards

	if not GlobalBlockDatabase.is_loaded():
		GlobalBlockDatabase.load_data()

	if band_index < 0 or band_index >= GlobalBlockDatabase.depth_bands.size():
		return rewards

	var total_dps := _GetTotalOfflineDps() * GlobalStats.GetOfflineEfficiency()
	if total_dps <= 0.0:
		return rewards

	var band_entry := _BuildBandEntry(band_index, total_dps)
	var avg_block_hp = max(1.0, float(band_entry.get("avg_block_hp", 1.0)))
	var total_damage := total_dps * float(seconds)
	var whole_blocks := maxi(0, int(floor(total_damage / avg_block_hp)))

	rewards["min_depth"] = int(band_entry.get("min_depth", 0))
	rewards["max_depth"] = int(band_entry.get("max_depth", 0))
	rewards["representative_depth"] = int(band_entry.get("representative_depth", 0))
	rewards["whole_blocks"] = whole_blocks

	if whole_blocks <= 0:
		return rewards

	# IMPORTANT:
	# Keep these as base offline values only.
	# ProcessOfflineProgress() already applies:
	# - GlobalStats.GetOfflineCoinGain()
	# - GlobalStats.GetOfflineCrystalGain()
	# - GlobalStats.GetOfflineEnergyGain()
	# - GlobalStats.GetCoinYieldMultiplier() for coins
	var avg_coins_per_block := _GetAverageExpectedCurrencyForBand(band_index, "coins")
	var avg_crystals_per_block := _GetAverageExpectedCurrencyForBand(band_index, "crystals")
	var avg_energy_per_block := _GetAverageExpectedCurrencyForBand(band_index, "energy")

	rewards["coins"] = int(round(avg_coins_per_block * whole_blocks))
	rewards["crystals"] = int(round(avg_crystals_per_block * whole_blocks))
	rewards["energy"] = int(round(avg_energy_per_block * whole_blocks))

	return rewards


func _BuildVisibleBandEntries() -> Array:
	var entries: Array = []
	var total_dps := _GetTotalOfflineDps() * GlobalStats.GetOfflineEfficiency()
	var current_depth := int(GlobalSave.save_data.progress.get("global_depth", 0))
	var unlocked_band_index := maxi(0, GlobalBlockDatabase.get_depth_band_index(current_depth))
	var max_eval_index := mini(GlobalBlockDatabase.depth_bands.size() - 1, unlocked_band_index + 1)

	for band_index in range(max_eval_index + 1):
		entries.append(_BuildBandEntry(band_index, total_dps))

	return entries


func _BuildBandEntry(band_index: int, total_dps: float) -> Dictionary:
	var band: Dictionary = GlobalBlockDatabase.depth_bands[band_index]
	var representative_depth := _GetRepresentativeDepthForBand(band)
	var avg_block_hp := _GetAverageBlockHpForBand(band_index, representative_depth)

	var seconds_per_block := INF
	var blocks_per_hour := 0.0

	if total_dps > 0.0 and avg_block_hp > 0.0:
		seconds_per_block = avg_block_hp / total_dps
		blocks_per_hour = (total_dps * 3600.0) / avg_block_hp

	var coins_per_block := _GetAverageExpectedCurrencyForBand(band_index, "coins")
	var crystals_per_block := _GetAverageExpectedCurrencyForBand(band_index, "crystals")
	var energy_per_block := _GetAverageExpectedCurrencyForBand(band_index, "energy")

	var coins_per_hour := blocks_per_hour * coins_per_block
	coins_per_hour *= GlobalStats.GetOfflineCoinGain()
	coins_per_hour *= GlobalStats.GetCoinYieldMultiplier()

	var crystals_per_hour := blocks_per_hour * crystals_per_block
	crystals_per_hour *= GlobalStats.GetOfflineCrystalGain()

	var energy_per_hour := blocks_per_hour * energy_per_block
	energy_per_hour *= GlobalStats.GetOfflineEnergyGain()

	return {
		"band_index": band_index,
		"min_depth": int(band.get("min_depth", 0)),
		"max_depth": int(band.get("max_depth", 0)),
		"representative_depth": representative_depth,
		"avg_block_hp": avg_block_hp,
		"seconds_per_block": seconds_per_block,
		"blocks_per_hour": blocks_per_hour,
		"coins_per_hour": coins_per_hour,
		"crystals_per_hour": crystals_per_hour,
		"energy_per_hour": energy_per_hour
	}


func _PickRecommendedBandIndex(entries: Array) -> int:
	if entries.is_empty():
		return -1

	for i in range(entries.size() - 1, -1, -1):
		var entry: Dictionary = entries[i]
		if float(entry.get("seconds_per_block", INF)) <= RECOMMENDED_MAX_CLEAR_SECONDS:
			return int(entry.get("band_index", 0))

	return int(entries[0].get("band_index", 0))


func _PickEasyCoinBandIndex(entries: Array, recommended_band_index: int) -> int:
	if entries.is_empty():
		return -1

	var start_band_index := maxi(0, recommended_band_index - EASY_LOOKBACK_BANDS)
	var best_entry := _GetEntryByBandIndex(entries, recommended_band_index)
	var best_coins := float(best_entry.get("coins_per_hour", 0.0))

	for entry in entries:
		var band_index := int(entry.get("band_index", -1))
		if band_index < start_band_index or band_index > recommended_band_index:
			continue

		var entry_coins := float(entry.get("coins_per_hour", 0.0))
		if entry_coins > best_coins:
			best_entry = entry
			best_coins = entry_coins

	return int(best_entry.get("band_index", 0))


func _PickTooHardBandIndex(entries: Array, recommended_band_index: int) -> int:
	if entries.is_empty():
		return -1

	for entry in entries:
		var band_index := int(entry.get("band_index", -1))
		if band_index <= recommended_band_index:
			continue

		if float(entry.get("seconds_per_block", 0.0)) >= TOO_HARD_MIN_CLEAR_SECONDS:
			return band_index

	var next_band_index := recommended_band_index + 1
	if _HasBandIndex(entries, next_band_index):
		return next_band_index

	return int(entries[entries.size() - 1].get("band_index", 0))


func _ResolveBandSlots(
	entries: Array,
	easy_band_index: int,
	recommended_band_index: int,
	hard_band_index: int
) -> Dictionary:
	var resolved := {
		SLOT_EASY_COINS: easy_band_index,
		SLOT_RECOMMENDED: recommended_band_index,
		SLOT_TOO_HARD: hard_band_index
	}

	if resolved[SLOT_EASY_COINS] == resolved[SLOT_RECOMMENDED]:
		var fallback_easy := recommended_band_index - 1
		if _HasBandIndex(entries, fallback_easy):
			resolved[SLOT_EASY_COINS] = fallback_easy

	if resolved[SLOT_TOO_HARD] == resolved[SLOT_RECOMMENDED]:
		var fallback_hard := recommended_band_index + 1
		if _HasBandIndex(entries, fallback_hard):
			resolved[SLOT_TOO_HARD] = fallback_hard

	if resolved[SLOT_EASY_COINS] == resolved[SLOT_TOO_HARD]:
		var alt_hard := int(resolved[SLOT_TOO_HARD]) + 1
		if _HasBandIndex(entries, alt_hard):
			resolved[SLOT_TOO_HARD] = alt_hard

	return resolved


func _GetRepresentativeDepthForBand(band: Dictionary) -> int:
	var min_depth := int(band.get("min_depth", 0))
	var max_depth := int(band.get("max_depth", min_depth))

	if max_depth >= 999999:
		return min_depth + 125

	return min_depth + int(floor(float(max_depth - min_depth) * 0.5))


func _GetAverageBlockHpForBand(band_index: int, representative_depth: int) -> float:
	var band: Dictionary = GlobalBlockDatabase.depth_bands[band_index]
	var spawn_pool: Array = band.get("spawn_pool", [])

	if spawn_pool.is_empty():
		return 1.0

	var carried_base := float(GlobalBlockDatabase._GetContinuousBandBaseHp(band_index))
	var base_hp := float(band.get("base_hp", 1.0))
	var effective_base_hp := lerpf(base_hp, carried_base, 0.35)

	var band_start_depth := int(band.get("min_depth", representative_depth))
	var depth_in_band := maxi(0, representative_depth - band_start_depth)
	var depth_growth := float(band.get("depth_growth", 1.01))

	var total_weight := 0.0
	var weighted_hp_sum := 0.0

	for entry in spawn_pool:
		if typeof(entry) != TYPE_DICTIONARY:
			continue

		var spawn_weight := float(entry.get("weight", 0.0))
		if spawn_weight <= 0.0:
			continue

		var block_id := str(entry.get("id", "")).strip_edges()
		if block_id == "":
			continue

		var archetype: Dictionary = GlobalBlockDatabase.get_archetype(block_id)
		if archetype.is_empty():
			continue

		var hp_multiplier := float(archetype.get("hp_multiplier", 1.0))
		var final_hp = max(
			1.0,
			effective_base_hp * hp_multiplier * pow(depth_growth, depth_in_band)
		)

		total_weight += spawn_weight
		weighted_hp_sum += final_hp * spawn_weight

	if total_weight <= 0.0:
		return 1.0

	return weighted_hp_sum / total_weight


func _GetAverageExpectedCurrencyForBand(band_index: int, currency: String) -> float:
	var band: Dictionary = GlobalBlockDatabase.depth_bands[band_index]
	var spawn_pool: Array = band.get("spawn_pool", [])

	if spawn_pool.is_empty():
		return 0.0

	var reward_multiplier := float(band.get("reward_multiplier", 1.0))
	var total_weight := 0.0
	var weighted_currency_sum := 0.0

	for entry in spawn_pool:
		if typeof(entry) != TYPE_DICTIONARY:
			continue

		var spawn_weight := float(entry.get("weight", 0.0))
		if spawn_weight <= 0.0:
			continue

		var block_id := str(entry.get("id", "")).strip_edges()
		if block_id == "":
			continue

		var archetype: Dictionary = GlobalBlockDatabase.get_archetype(block_id)
		if archetype.is_empty():
			continue

		var expected_amount := _GetExpectedCurrencyFromArchetype(
			archetype,
			currency,
			reward_multiplier
		)

		total_weight += spawn_weight
		weighted_currency_sum += expected_amount * spawn_weight

	if total_weight <= 0.0:
		return 0.0

	return weighted_currency_sum / total_weight


func _GetExpectedCurrencyFromArchetype(
	archetype: Dictionary,
	currency: String,
	reward_multiplier: float = 1.0
) -> float:
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


func _GetTotalOfflineDps() -> float:
	var total_dps := 0.0

	for lane in GlobalSave.save_data.lanes:
		if !bool(lane.get("auto_dig_unlocked", false)):
			continue

		var bot_uid := int(lane.get("bot_uid", -1))
		if bot_uid == -1:
			continue

		var bot := _FindBotByUid(bot_uid)
		if bot.is_empty():
			continue

		total_dps += GlobalStats.GetBotFinalDPSWithGlobalAndStats(bot, true, false, true)

	return max(0.0, total_dps)


func _FindBotByUid(bot_uid: int) -> Dictionary:
	for bot in GlobalSave.save_data.bot_inventory.bot_db:
		if int(bot.uid) == bot_uid:
			return bot
	return {}


func _AddRolledDropsToRewards(rewards: Dictionary, rolled_drops: Dictionary) -> void:
	for currency in rolled_drops.keys():
		var amount := int(rolled_drops.get(currency, 0))
		if amount <= 0:
			continue

		rewards[currency] = int(rewards.get(currency, 0)) + amount


func _GetEntryByBandIndex(entries: Array, band_index: int) -> Dictionary:
	for entry in entries:
		if int(entry.get("band_index", -1)) == band_index:
			return entry
	return {}


func _HasBandIndex(entries: Array, band_index: int) -> bool:
	return not _GetEntryByBandIndex(entries, band_index).is_empty()


func _EnsureOfflinePlannerData() -> void:
	if !GlobalSave.save_data.has("offline_mining") or typeof(GlobalSave.save_data.offline_mining) != TYPE_DICTIONARY:
		GlobalSave.save_data["offline_mining"] = {
			"selected_band_index": -1
		}
		return

	if !GlobalSave.save_data.offline_mining.has("selected_band_index"):
		GlobalSave.save_data.offline_mining["selected_band_index"] = -1
