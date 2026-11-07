extends RefCounted

const VIEW_W := 960.0
const VIEW_H := 540.0
const FLOOR := 460.0
const GRAV := 0.7
const SPEED := 4.0
const JUMP := 13.0

static var _data = null

static func data() -> Dictionary:
	if _data == null:
		var parser := JSON.new()
		var err := parser.parse(FileAccess.get_file_as_string("res://data/game.json"))
		if err != OK:
			push_error("game.json: %s (linha %s)" % [parser.get_error_message(), parser.get_error_line()])
			_data = {}
		else:
			_data = parser.data
	return _data

static func armors() -> Array:
	return data()["armors"]

static func phases() -> Array:
	return data()["phases"]

static func phase(i: int) -> Dictionary:
	return phases()[i]

static func armor_by_id(id: String) -> Dictionary:
	for a in armors():
		if str(a["id"]) == id:
			return a
	return armors()[0]

static func armor_index(id: String) -> int:
	var list := armors()
	for i in list.size():
		if str(list[i]["id"]) == id:
			return i
	return 0

static func starters() -> Array:
	var out: Array = []
	for id in data()["starters"]:
		out.append(str(id))
	return out

static func story() -> Array:
	return data()["story"]

static func line_for(boss_name: String) -> String:
	return str(data()["lines"].get(boss_name, "AGORA TENS DE LUTAR COMIGO!"))

static func factor(phase_n: int, ng: int) -> float:
	return (1.0 + (phase_n - 1) * 0.12) * (1.0 + ng * 0.6)

static func colorize(hex: String) -> Color:
	var s := hex
	if s.length() == 4:
		s = "#" + s[1] + s[1] + s[2] + s[2] + s[3] + s[3]
	return Color(s)

static func plat_rect(spec: Array) -> Dictionary:
	return {
		"x": float(spec[0]),
		"y": FLOOR - float(spec[1]),
		"w": float(spec[2]),
		"h": float(spec[3]),
	}

static func ladder_rect(spec: Array) -> Dictionary:
	return {
		"x": float(spec[0]),
		"w": float(spec[2]),
		"y_top": FLOOR - float(spec[1]),
		"y_bot": FLOOR,
	}
