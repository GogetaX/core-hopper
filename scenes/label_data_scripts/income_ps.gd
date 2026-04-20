extends Label

var income_history := {}
var income_per_sec := {}

const INCOME_WINDOW_SEC := 10.0

func _ready() -> void:
	GlobalSignals.CurrencyAdded.connect(OnCurrencyAdded)
	_on_incone_counter_timeout()
	
func OnCurrencyAdded(currency_type: String, amount: int) -> void:
	if amount <= 0:
		return

	if !income_history.has(currency_type):
		income_history[currency_type] = []
		income_per_sec[currency_type] = 0.0

	var now_ms := Time.get_ticks_msec()

	income_history[currency_type].append({
		"time": now_ms,
		"amount": amount
	})

	_RefreshIncomePerSec(currency_type, now_ms)

func _RefreshIncomePerSec(currency_type: String, now_ms: int = -1) -> float:
	if !income_history.has(currency_type):
		return 0.0

	if now_ms == -1:
		now_ms = Time.get_ticks_msec()

	var min_time := now_ms - int(INCOME_WINDOW_SEC * 1000.0)
	var total_amount := 0
	var new_history := []

	for entry in income_history[currency_type]:
		if int(entry.time) >= min_time:
			new_history.append(entry)
			total_amount += int(entry.amount)

	income_history[currency_type] = new_history
	income_per_sec[currency_type] = float(total_amount) / INCOME_WINDOW_SEC

	return income_per_sec[currency_type]
	
func _process(_delta: float) -> void:
	for currency_type in income_history.keys():
		_RefreshIncomePerSec(currency_type)


func GetTotalIncome()->float:
	var res : float = 0
	for x in income_per_sec:
		res += income_per_sec[x]
	return res
	
func _on_incone_counter_timeout() -> void:
	var tot_income = GetTotalIncome()
	if tot_income < 100:
		text = str(snapped(GetTotalIncome(),0.1))
	else:
		text = Global.CurrencyToString(tot_income)
