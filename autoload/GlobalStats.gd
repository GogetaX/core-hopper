extends Node



#bot base stuff
const BOT_BASE_DPS := 1.0
const BOT_DPS_GROWTH := 2.1

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
	var lvl = GlobalSave.save_data.upgrades["coin_yield"].level + next_level
	return pow(1.10, lvl)
	
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
	return final_dps * GlobalStats.GetUpgradeValue("drill_power")
	
func GetBotFinalDigSpeedWithGlobal(level: int) -> float:
	var final_speed = GetBotFinalDigSpeed(level)
	return final_speed * GlobalStats.GetUpgradeValue("drill_speed")
	
func GetBotStats(level: int) -> Dictionary:
	var base_power := maxi(1, int(round(pow(1.9, level - 1))))
	var base_speed = min(3.0, snapped(pow(1.12, level - 1), 0.01))

	var power_mult = 1.0 + (GlobalSave.save_data.global_upgrades.global_dig_power_level * 0.15)
	var speed_mult = 1.0 + (GlobalSave.save_data.global_upgrades.global_dig_speed_level * 0.08)

	var final_power = base_power * power_mult * GetUpgradeValue("drill_power")
	var final_speed = base_speed * speed_mult * GetUpgradeValue("drill_speed")
	var dps = final_power * final_speed
	var hit_interval = 1.0 / max(final_speed, 0.001)

	return {
		"level": level,
		"dig_power": final_power,
		"dig_speed": final_speed,
		"dps": dps,
		"hit_interval": hit_interval,
		"merge_value": maxi(1, int(round(10.0 * pow(2.35, level - 1)))),
		"sell_value": int(round((10.0 * pow(2.35, level - 1)) * 0.6))
	}
	

func GetUpgradeCost(upgrade_id: String) -> int:
	var up = GlobalSave.save_data.upgrades[upgrade_id]
	return int(round(up.base_cost * pow(up.cost_scale, up.level)))

func GetUpgradeValue(upgrade_id: String,next_level:int = 0) -> float:
	var up = GlobalSave.save_data.upgrades[upgrade_id]

	match up.effect_type:
		"mult_pow":
			return pow(up.effect_base, up.level+next_level)
		"linear":
			return 1.0 + up.effect_base * (up.level+next_level)
		_:
			return 1.0
			
func GetTapDamage() -> float:
	return max(1.0, float(GetUpgradeValue("tap_damage")))
