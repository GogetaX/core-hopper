extends Node

const ZERO := {"m": 0.0, "e": 0}

func Zero() -> Dictionary:
	return {"m": 0.0, "e": 0}

func One() -> Dictionary:
	return {"m": 1.0, "e": 0}

func FromFloat(value: float) -> Dictionary:
	if value <= 0.0:
		return Zero()

	var e := int(floor(log(value) / log(10.0)))
	var m := value / pow(10.0, e)
	return Normalize({"m": m, "e": e})

func FromParts(mantissa: float, exponent: int) -> Dictionary:
	return Normalize({"m": mantissa, "e": exponent})

func Normalize(v: Dictionary) -> Dictionary:
	var m := float(v.get("m", 0.0))
	var e := int(v.get("e", 0))

	if m <= 0.0:
		return Zero()

	while m >= 10.0:
		m /= 10.0
		e += 1

	while m < 1.0:
		m *= 10.0
		e -= 1

	return {"m": m, "e": e}

func IsBig(v) -> bool:
	return typeof(v) == TYPE_DICTIONARY and v.has("m") and v.has("e")

func ToBig(v) -> Dictionary:
	if IsBig(v):
		return Normalize(v)
	return FromFloat(float(v))

func Add(a, b) -> Dictionary:
	a = ToBig(a)
	b = ToBig(b)

	if float(a.m) <= 0.0:
		return b
	if float(b.m) <= 0.0:
		return a

	var diff := int(a.e) - int(b.e)

	if diff >= 8:
		return a
	if diff <= -8:
		return b

	if diff >= 0:
		return Normalize({"m": float(a.m) + float(b.m) / pow(10.0, diff), "e": int(a.e)})
	else:
		return Normalize({"m": float(b.m) + float(a.m) / pow(10.0, -diff), "e": int(b.e)})

func Sub(a, b) -> Dictionary:
	a = ToBig(a)
	b = ToBig(b)

	if Compare(a, b) <= 0:
		return Zero()

	var diff := int(a.e) - int(b.e)

	if diff >= 8:
		return a

	return Normalize({
		"m": float(a.m) - float(b.m) / pow(10.0, diff),
		"e": int(a.e)
	})

func MulFloat(a, mult: float) -> Dictionary:
	a = ToBig(a)
	if mult <= 0.0:
		return Zero()
	return Normalize({"m": float(a.m) * mult, "e": int(a.e)})

func Mul(a, b) -> Dictionary:
	a = ToBig(a)
	b = ToBig(b)

	if float(a.m) <= 0.0 or float(b.m) <= 0.0:
		return Zero()

	return Normalize({
		"m": float(a.m) * float(b.m),
		"e": int(a.e) + int(b.e)
	})

func PowFloat(base: float, exponent: float) -> Dictionary:
	if base <= 0.0:
		return Zero()

	var log10_value := log(base) / log(10.0) * exponent
	var e := int(floor(log10_value))
	var m := pow(10.0, log10_value - e)

	return Normalize({"m": m, "e": e})

func Compare(a, b) -> int:
	a = ToBig(a)
	b = ToBig(b)

	if int(a.e) > int(b.e):
		return 1
	if int(a.e) < int(b.e):
		return -1

	if float(a.m) > float(b.m):
		return 1
	if float(a.m) < float(b.m):
		return -1

	return 0

func Percent(current, maximum) -> float:
	current = ToBig(current)
	maximum = ToBig(maximum)

	if float(maximum.m) <= 0.0:
		return 0.0

	var diff := int(current.e) - int(maximum.e)

	if diff > 6:
		return 1.0
	if diff < -6:
		return 0.0

	return clampf((float(current.m) / float(maximum.m)) * pow(10.0, diff), 0.0, 1.0)

func ToFloatSafe(v, cap: float = 1.0e30) -> float:
	v = ToBig(v)

	if float(v.m) <= 0.0:
		return 0.0

	if int(v.e) > 30:
		return cap

	return float(v.m) * pow(10.0, int(v.e))

func Format(v, decimals: int = 2) -> String:
	v = ToBig(v)

	if float(v.m) <= 0.0:
		return "0"

	var e := int(v.e)
	var m := float(v.m)

	if e < 3:
		return str(int(round(ToFloatSafe(v))))

	var suffixes := ["", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc"]
	var suffix_index := int(floor(e / 3.0))

	if suffix_index < suffixes.size():
		var scaled := m * pow(10.0, e % 3)
		return str(snapped(scaled, pow(10.0, -decimals))) + suffixes[suffix_index]

	return str(snapped(m, pow(10.0, -decimals))) + "e" + str(e)

func DivideToFloat(a, b) -> float:
	a = ToBig(a)
	b = ToBig(b)

	if float(b.m) <= 0.0:
		return INF

	var diff := int(a.e) - int(b.e)

	if diff > 30:
		return INF
	if diff < -30:
		return 0.0

	return (float(a.m) / float(b.m)) * pow(10.0, diff)
