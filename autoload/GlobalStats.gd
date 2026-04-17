extends Node



#bot base stuff
const BOT_BASE_DPS := 1.0
const BOT_DPS_GROWTH := 2.1
const MAX_MERGE_SLOTS = 16
const DAILY_FREE_BOT = 2
const DAILY_MYTHIC_BOT = 1

func InitDailyFreeBot():
	if GlobalSave.save_data.daily_free_bot.day_key != _GetTodayKey():
		GlobalSave.save_data.daily_free_bot.amount = DAILY_FREE_BOT
		GlobalSave.save_data.daily_free_bot.mythic_amount = DAILY_MYTHIC_BOT+GlobalSkillTree.skill_summary.stats.daily_free_mythic_bot_limit_bonus
		GlobalSave.save_data.daily_free_bot.day_key = _GetTodayKey()
		
func GetBotDPSFromLevel(level: int) -> float:
	level = max(level, 1)
	return BOT_BASE_DPS * pow(BOT_DPS_GROWTH, level - 1)

func GetBotBaseDigPower(level: int) -> int:
	return maxi(1, int(round(pow(1.9, level - 1))))
	
func GetBotBaseDigSpeed(level: int) -> float:
	return min(3.0, snapped(pow(1.12, level - 1), 0.01))

func GetBotBaseDps(level: int) -> float:
	return GetBotBaseDigPower(level) * GetBotBaseDigSpeed(level)
	
func GetBotHitInterval(level: int) -> float:
	return 1.0 / GetBotBaseDigSpeed(level)

func GetBotMergeValue(level: int) -> int:
	return maxi(1, int(round(10.0 * pow(2.35, level - 1))))
	
func GetBotSellValue(level: int) -> int:
	return int(round(GetBotMergeValue(level) * 0.6))
	
func GetGlobalPowerMultiplier(next_level : int = 0) -> float:
	var level = GlobalSave.save_data.global_upgrades.global_dig_power_level + next_level
	return 1.0 + (level * 0.15)

func GetGlobalSpeedMultiplier(next_level : int = 0) -> float:
	var level = GlobalSave.save_data.global_upgrades.global_dig_speed_level + next_level
	return 1.0 + (level * 0.08)
	
func GetCoinYieldMultiplier(next_level :int = 0) -> float:
	#coin yield from Upgrade stats
	var lvl = GlobalSave.save_data.upgrades["coin_yield"].level + next_level
	var coint_multiplayer = pow(1.10, lvl) * GetRelicMultiplierTotal("coin_gain_mult")
	
	#double coin bonus from Timed Bonus
	if GlobalTimedBonus.IsBoosterActive("double_coins"):
		coint_multiplayer = coint_multiplayer * GlobalTimedBonus.GetBoosterDataById("double_coins").effect_value
	return coint_multiplayer
	
func GetGlobalCoinYieldMultiplayer():
	return GetCoinYieldMultiplier()

func GetBotFinalDigPower(level: int) -> float:
	return GetBotBaseDigPower(level) * GetGlobalPowerMultiplier()
	
func GetBotFinalDigSpeed(level: int) -> float:
	return GetBotBaseDigSpeed(level) * GetGlobalSpeedMultiplier()
	
func GetBotFinalDps(level: int) -> float:
	return GetBotFinalDigPower(level) * GetBotFinalDigSpeed(level)
	
func GetBotFinalDPSWithGobal(level:int) -> float:
	var final_dps = GetBotFinalDps(level)
	return final_dps * GetBotDamageMultiplier()
	

func GetBotFinalDPSWithGlobalAndStats(
	bot_data: Dictionary,
	include_expected_crit: bool = false,
	is_boss: bool = false,
	timed_stats: bool = true
) -> float:
	var level := int(bot_data.get("level", 1))

	var power := float(GetBotBaseDigPower(level))
	var speed := float(GetBotBaseDigSpeed(level))

	# flat bot stats
	power += GlobalBotStats.GetBotStatValue(bot_data, "dig_power")
	speed += GlobalBotStats.GetBotStatValue(bot_data, "dig_speed")

	# global progression
	power *= GetGlobalPowerMultiplier()
	speed *= GetGlobalSpeedMultiplier()

	# bot affix multipliers
	power *= GlobalBotStats.BotStatMultiplier(bot_data, "dig_power_mult")
	speed *= GlobalBotStats.BotStatMultiplier(bot_data, "dig_speed_mult")

	# normal upgrades / relic multipliers already used in the game
	power *= GetBotDamageMultiplier()
	speed *= GetUpgradeValue("drill_speed")

	var dps := power * speed

	if timed_stats:
		dps *= GetTimedBonusMultiplier([
			"dps_mult",
			"bot_dps_mult"
		])

	if include_expected_crit:
		var crit_chance = clamp(
			GetCritChance() + GlobalBotStats.GetBotStatValue(bot_data, "crit_chance"),
			0.0,
			1.0
		)

		var crit_mult = max(
			1.0,
			GetCritMultiplier() + GlobalBotStats.GetBotStatValue(bot_data, "crit_mult")
		)

		dps *= 1.0 + (crit_chance * (crit_mult - 1.0))

	if is_boss:
		dps *= GetBossDamageMultiplier()

	return max(0.0, dps)
	
func GetBotFinalDigSpeedWithGlobal(level: int) -> float:
	var final_speed = GetBotFinalDigSpeed(level)
	return final_speed * GlobalStats.GetUpgradeValue("drill_speed")
	
func GetBotStats(level: int) -> Dictionary:
	var base_power := maxi(1, int(round(pow(1.9, level - 1))))
	var base_speed = min(3.0, snapped(pow(1.12, level - 1), 0.01))

	var power_mult = 1.0 + (GlobalSave.save_data.global_upgrades.global_dig_power_level * 0.15)
	var speed_mult = 1.0 + (GlobalSave.save_data.global_upgrades.global_dig_speed_level * 0.08)

	var final_power = base_power * power_mult * GetBotDamageMultiplier()
	var final_speed = base_speed * speed_mult * GetUpgradeValue("drill_speed")

	var dps = final_power * final_speed
	var hit_interval = 1.0 / max(final_speed, 0.001)

	return {
		"level": level,
		"dig_power": final_power,
		"dig_speed": final_speed,
		"dps": dps,
		"expected_dps": dps * GetExpectedCritDamageMultiplier(),
		"hit_interval": hit_interval,
		"crit_chance": GetCritChance(),
		"crit_multiplier": GetCritMultiplier(),
		"merge_value": maxi(1, int(round(10.0 * pow(2.35, level - 1)))),
		"sell_value": int(round((10.0 * pow(2.35, level - 1)) * 0.6))
	}

func GetTapBaseDamageFromUpgradeLevel(level: int) -> int:
	var effective_level = max(1, level + 1)
	return maxi(1, int(round(pow(1.9, effective_level - 1) * 0.8)))
	
func GetUpgradeCost(upgrade_id: String) -> int:
	if !GlobalSave.save_data.has("upgrades") or !GlobalSave.save_data.upgrades.has(upgrade_id):
		return 0

	var up = GlobalSave.save_data.upgrades[upgrade_id]
	return int(round(up.base_cost * pow(up.cost_scale, up.level)))
	

func GetUpgradeValue(upgrade_id: String, next_level: int = 0) -> float:
	if !GlobalSave.save_data.has("upgrades") or !GlobalSave.save_data.upgrades.has(upgrade_id):
		match upgrade_id:
			"crit_chance", "crit_multiplier":
				return 0.0
			"tap_damage":
				return 1.0
			_:
				return 1.0

	var up = GlobalSave.save_data.upgrades[upgrade_id]
	var level := int(up.level) + next_level

	match str(up.effect_type):
		"tap_curve":
			return float(GetTapBaseDamageFromUpgradeLevel(level))
		"mult_pow":
			return pow(up.effect_base, level)
		"linear":
			return 1.0 + up.effect_base * level
		"flat":
			return up.effect_base * level
		_:
			return 1.0

func GetTapDamage() -> float:
	var base_tap_damage = max(1.0, float(GetUpgradeValue("tap_damage")))
	
	var upgrade_mult = max(1.0, GetTapDamageMultiplier())

	var tap_skill_bonus := 0.0
	if GlobalSkillTree.skill_summary.stats.has("tap_damage_mult"):
		tap_skill_bonus = float(GlobalSkillTree.skill_summary.stats.tap_damage_mult)

	var skill_mult := 1.0 + tap_skill_bonus
	var res = base_tap_damage * upgrade_mult * skill_mult
	return max(1.0, res)



func GetCritChance(next_level: int = 0) -> float:
	var base_chance := float(GetUpgradeValue("crit_chance", next_level))
	var relic_bonus := GetRelicFlatTotal("crit_chance_flat")
	return clamp(base_chance + relic_bonus, 0.0, 1.0)


func GetCritMultiplier(next_level: int = 0) -> float:
	var base_mult = max(1.0, 1.0 + float(GetUpgradeValue("crit_multiplier", next_level)))
	return max(1.0, base_mult * GetRelicMultiplierTotal("crit_mult_mult"))
	
func GetExpectedCritDamageMultiplier() -> float:
	var chance := GetCritChance()
	var crit_mult := GetCritMultiplier()
	return 1.0 + (chance * (crit_mult - 1.0))

func GetBotExpectedDps(level: int) -> float:
	return float(GetBotStats(level).expected_dps)

func RollCrit() -> bool:
	return randf() < GetCritChance()

func ApplyCritToDamage(base_damage: float) -> Dictionary:
	var final_damage = max(0.0, float(base_damage))
	var did_crit := RollCrit()

	if did_crit:
		final_damage *= GetCritMultiplier()

	return {
		"damage": final_damage,
		"did_crit": did_crit
	}

func GetUnlockedRelicSlots() -> int:
	GlobalRelicDb.SyncRelicInv()
	var base_relic_slots = GlobalSave.save_data.relic_inv.unlocked_slots
	var core_reset_slots = GlobalCoreResetDb.GetCoreResetStatValue("relic_slot_bonus")
	return maxi(0, int(base_relic_slots + core_reset_slots))
	
#Relics
func GetRelicMultiplierTotal(effect_type: String) -> float:
	var total := 1.0

	for relic_entry in GlobalRelicDb.GetAllEquippedRelics():
		var db_data = relic_entry.get("db_data", {})
		if typeof(db_data) != TYPE_DICTIONARY:
			continue
		if str(db_data.get("effect_type", "")) != effect_type:
			continue
		if str(db_data.get("effect_format", "")) != "multiplier":
			continue

		var rank_data = relic_entry.get("rank_data", {})
		if typeof(rank_data) != TYPE_DICTIONARY:
			continue

		total *= float(rank_data.get("effect_value", 1.0))

	return max(0.0, total)


func GetRelicFlatTotal(effect_type: String) -> float:
	var total := 0.0

	for relic_entry in GlobalRelicDb.GetAllEquippedRelics():
		var db_data = relic_entry.get("db_data", {})
		if typeof(db_data) != TYPE_DICTIONARY:
			continue
		if str(db_data.get("effect_type", "")) != effect_type:
			continue
		if str(db_data.get("effect_format", "")) != "flat":
			continue

		var rank_data = relic_entry.get("rank_data", {})
		if typeof(rank_data) != TYPE_DICTIONARY:
			continue

		total += float(rank_data.get("effect_value", 0.0))

	return total


func GetBotDamageMultiplier() -> float:
	return float(GetUpgradeValue("drill_power")) * GetRelicMultiplierTotal("bot_damage_mult")


func GetTapDamageMultiplier() -> float:
	return GetRelicMultiplierTotal("tap_damage_mult")


func GetBossDamageMultiplier() -> float:
	var relic_multiplier = GetRelicMultiplierTotal("boss_damage_mult")
	var skill_tree_multiplayer = GlobalSkillTree.skill_summary.stats.boss_damage_mult
	return relic_multiplier+skill_tree_multiplayer


func GetOfflineGainMultiplier() -> float:
	return GetRelicMultiplierTotal("offline_gain_mult")

func ApplyBossDamageMultiplier(base_damage: float) -> float:
	return max(0.0, float(base_damage) * GetBossDamageMultiplier())

func GetFreeMergeSlots()->int:
	var inv_merge_slots = GlobalSave.save_data.bot_inventory.merge_free_slots
	var skill_merge_slots = GlobalSkillTree.skill_summary.stats.merge_slot_bonus
	var core_reset_merge_slots = GlobalCoreResetDb.GetCoreResetStatValue("merge_slot_bonus")
	return min(int(inv_merge_slots + skill_merge_slots + core_reset_merge_slots),MAX_MERGE_SLOTS)

func BuyBotData():
	var base_bot_price = 5 * pow(1.12,GlobalSave.save_data.player_stats.total_bots_bought_this_reset)
	#Base
	var res = {
		"price":base_bot_price,
		"level":1
	}
	#Apply new level and price
	if GlobalSkillTree.skill_summary.unlock_features.direct_bot_buy_level.unlocked:
		var unlocked_level_list = GlobalSkillTree.skill_summary.unlock_features.direct_bot_buy_level.unlocked_levels
		if !unlocked_level_list.is_empty():
			var unlocked_last_level = unlocked_level_list[unlocked_level_list.size()-1]
			var cost_multiplayer = GlobalSkillTree.skill_summary.unlock_features.direct_bot_buy_level.cost_multiplier_by_level[str(unlocked_last_level).pad_decimals(0)]
			res.level = res.level + int(unlocked_last_level-1)
			res.price = int(res.price * cost_multiplayer)
	#Bot Reduction price from skills
	var reduction_percent = GlobalSkillTree.skill_summary.stats.direct_bot_buy_cost_reduction
	res.price = res.price - (res.price * reduction_percent)
	
	#Bot Reduction price from Timed Bonus
	if GlobalTimedBonus.IsBoosterActive("bot_discount"):
		var boost_data = GlobalTimedBonus.GetBoosterDataById("bot_discount")
		res.price = res.price - (res.price * boost_data.effect_value)
	
	#Core reset buy level bot
	res.level += GlobalCoreResetDb.GetCoreResetStatValue("bot_buy_start_level_bonus")
	#converting from float back to int
	res.price = int(res.price)
	res.level = int(res.level)
	return res

func GetOfflineCapSeconds():
	var cap_offline = GlobalOfflineProgress.GetOfflineCapSeconds()
	var cap_skills = GlobalSkillTree.skill_summary.stats.max_offline_seconds
	return cap_offline + cap_skills

func GetOfflineEfficiency()->float:
	var offline_efficiency = GlobalOfflineProgress.GetOfflineEfficiency()
	var skill_efficiency = GlobalSkillTree.skill_summary.stats.offline_gain_mult
	var res = offline_efficiency * (1.0 + skill_efficiency)
	return res

func GetOfflineCoinGain() -> float:
	var res = 1.0
	res += GlobalSkillTree.skill_summary.stats.offline_coin_gain_mult
	return res

func GetOfflineCrystalGain() -> float:
	var res = 1.0
	res += GlobalSkillTree.skill_summary.stats.offline_crystal_gain_mult
	return res

func GetOfflineEnergyGain() -> float:
	var res = 1.0
	res += GlobalSkillTree.skill_summary.stats.offline_energy_gain_mult
	return res

func GetTapCritChance() -> float:
	var res := GetCritChance()
	res += float(GlobalSkillTree.skill_summary.stats.get("tap_crit_chance", 0.0))
	return clamp(res, 0.0, 1.0)


func GetTapCritMultiplier() -> float:
	var res := GetCritMultiplier()
	res += float(GlobalSkillTree.skill_summary.stats.get("tap_crit_mult", 0.0))
	return max(1.0, res)


func RollTapCrit() -> bool:
	return randf() < GetTapCritChance()


func ApplyTapCritToDamage(base_damage: float) -> Dictionary:
	var final_damage = max(0.0, float(base_damage))
	var did_crit := RollTapCrit()

	if did_crit:
		final_damage *= GetTapCritMultiplier()

	return {
		"damage": final_damage,
		"did_crit": did_crit
	}


func GetTapExecuteThreshold() -> float:
	var res := 0.0

	var unlock_features = GlobalSkillTree.skill_summary.get("unlock_features", {})
	if typeof(unlock_features) == TYPE_DICTIONARY and unlock_features.has("tap_execute"):
		var tap_execute = unlock_features.get("tap_execute", {})
		if typeof(tap_execute) == TYPE_DICTIONARY and bool(tap_execute.get("unlocked", false)):
			if tap_execute.has("threshold_total"):
				res = float(tap_execute.get("threshold_total", 0.0))
			else:
				res = float(tap_execute.get("base_threshold", tap_execute.get("threshold", 0.0)))
				res += float(GlobalSkillTree.skill_summary.stats.get("tap_execute_threshold", 0.0))

	return clamp(res, 0.0, 0.95)


func GetTapExecuteRewardMultiplier() -> float:
	return 1.0 + float(GlobalSkillTree.skill_summary.stats.get("tap_execute_reward_mult", 0.0))

func GetBossRewardCrystalMulti():
	var res = 1.0
	res += GlobalSkillTree.skill_summary.stats.boss_crystal_reward_mult
	return res
	
func GetBossRewardEnergyMulti():
	var res = 1.0
	res += GlobalSkillTree.skill_summary.stats.boss_energy_reward_mult
	return res
	
func GetBossRegenReduction():
	var ret = 1.0
	ret -= GlobalSkillTree.skill_summary.stats.boss_regen_reduction
	return max(0,ret)

func GetBossRewardMulti():
	var ret = 1.0
	ret += GlobalSkillTree.skill_summary.stats.boss_reward_mult
	return ret

func HasChanceOfNextLevelBotOnBuy():
	var chance = randf_range(0,1.0)
	if chance <= GlobalSkillTree.skill_summary.stats.direct_bot_buy_bonus_level_chance:
		return true
	return false
	
func HasChanceOfNextLevelBotOnMerge():
	var chance = randf_range(0,1.0)
	if chance <= GlobalSkillTree.skill_summary.stats.merge_bonus_level_chance:
		return true
	return false
	
func HasChanceToSpawmNewBot():
	var chance = randf_range(0,1.0)
	if chance <= GlobalSkillTree.skill_summary.stats.merge_spawn_base_bot_chance:
		return true
	return false

func GetAdditionalDailyQuestLimit()->int:
	return int(GlobalSkillTree.skill_summary.stats.daily_quest_limit_bonus)

func GetFrontBlockTapDmgMulti()->float:
	var res = 1.0
	res += GlobalSkillTree.skill_summary.stats.front_block_tap_damage_mult
	return res
	
func GetRefundChestOnBuy():
	var chance = randf_range(0,1.0)
	if chance <= GlobalSkillTree.skill_summary.stats.direct_bot_buy_refund_chance:
		return true
	return false

func _GetTimedBonusNode() -> Node:
	return get_node_or_null("/root/GlobalTimedBonus")


func GetTimedBonusMultiplier(effect_types: Array) -> float:
	var timed_bonus = _GetTimedBonusNode()
	if timed_bonus == null:
		return 1.0

	var total := 1.0
	var active_ids: Array = timed_bonus.GetActivatedBoosterIds()

	for booster_id in active_ids:
		var booster_data: Dictionary = timed_bonus.GetActivatedBoosterData(str(booster_id))
		if booster_data.is_empty():
			continue

		if !bool(booster_data.get("is_active", false)):
			continue

		var effect_type := str(booster_data.get("effect_type", ""))
		if !effect_types.has(effect_type):
			continue

		total *= float(booster_data.get("effect_value", 1.0))

	return max(0.0, total)



func _GetTodayKey() -> String:
	var d := Time.get_date_dict_from_system()
	return "%04d-%02d-%02d" % [
		int(d.get("year", 1970)),
		int(d.get("month", 1)),
		int(d.get("day", 1))
	]

func RollDirectBotBuyRank() -> int:
	var chance = GlobalSkillTree.skill_summary.stats.direct_bot_buy_better_rank_chance
	var better_rank_chance = clampf(chance, 0.0, 1.0)

	var rank := 0

	# Each success upgrades the bought bot by 1 rank.
	# Max rank = 3
	
	for i in range(3):
		if randf() <= better_rank_chance:
			rank += 1
		else:
			break

	return clampi(rank, 0, 3)
