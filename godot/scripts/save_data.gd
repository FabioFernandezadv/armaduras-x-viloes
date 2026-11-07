extends Node

const PATH := "user://axv_save_v1.json"
const Cat = preload("res://scripts/catalog.gd")

var coins := 0
var points := 0
var ng := 0
var hp_max := 6
var armor := "cavaleiro"
var owned: Array = []
var phase := 0
var has_save := false

func _ready() -> void:
	owned = Cat.starters()
	has_save = read()

func read() -> bool:
	if not FileAccess.file_exists(PATH):
		return false
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(PATH)) != OK:
		return false
	var d: Dictionary = parser.data
	phase = int(d.get("fase", 0))
	points = int(d.get("pontos", 0))
	coins = int(d.get("coins", 0))
	ng = int(d.get("ng", 0))
	hp_max = int(d.get("vidaMax", 6))
	armor = str(d.get("armadura", "cavaleiro"))
	var list = d.get("armaduras", [])
	owned = []
	for id in list:
		owned.append(str(id))
	if owned.is_empty():
		owned = Cat.starters()
	return true

func write(next_phase: int) -> void:
	phase = next_phase
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify({
		"fase": next_phase,
		"pontos": points,
		"coins": coins,
		"armaduras": owned,
		"armadura": armor,
		"ng": ng,
		"vidaMax": hp_max,
	}))
	has_save = true

func wipe() -> void:
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	coins = 0
	points = 0
	ng = 0
	hp_max = 6
	armor = "cavaleiro"
	owned = Cat.starters()
	phase = 0
	has_save = false

func owns(id: String) -> bool:
	return owned.has(id)

func grant(id: String) -> bool:
	if owns(id):
		return false
	owned.append(id)
	return true
