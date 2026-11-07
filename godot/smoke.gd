extends SceneTree

func _init() -> void:
	var Cat = load("res://scripts/catalog.gd")
	var WorldScript = load("res://scripts/world.gd")
	var fails: Array = []
	if Cat.phases().size() != 20:
		fails.append("phases %s" % Cat.phases().size())
	if Cat.armors().size() != 34:
		fails.append("armors %s" % Cat.armors().size())
	var factor: float = Cat.factor(10, 0)
	if absf(factor - 2.08) > 0.001:
		fails.append("factor %s" % factor)
	if absf(Cat.factor(1, 1) - 1.6) > 0.001:
		fails.append("ng factor")
	var w = WorldScript.new()
	w.start_phase(0, 0, 6, 0, "cavaleiro")
	if w.enemies.size() != 5:
		fails.append("wave %s" % w.enemies.size())
	var target: Dictionary = {}
	for e in w.enemies:
		if e["k"] == "m" and absf(float(e["x"]) - 450.0) < 1.0:
			target = e
	if target.is_empty():
		fails.append("no monster")
	else:
		w.hero["x"] = 440.0
		w.hero["facing"] = true
		var hp0: int = int(target["hp"])
		var id: int = int(target["id"])
		w.tick(1.0, {"l": false, "r": false, "u": false, "d": false, "jump": false, "attack": true})
		if w.hitbox == null:
			fails.append("hitbox")
		for _i in 8:
			w.tick(1.0, {"l": false, "r": false, "u": false, "d": false, "jump": false, "attack": false})
		var hp1 := -1
		for e in w.enemies:
			if int(e["id"]) == id:
				hp1 = int(e["hp"])
		print("SMOKE damage ", hp0, " -> ", hp1, " coins ", w.coins)
		if hp1 < 0 or hp1 >= hp0:
			fails.append("damage %s -> %s" % [hp0, hp1])
	var jumper = WorldScript.new()
	jumper.start_phase(0, 0, 6, 0, "cavaleiro")
	jumper.tick(1.0, {"l": false, "r": false, "u": false, "d": false, "jump": true, "attack": false})
	print("SMOKE jump vy ", jumper.hero["vy"], " y ", jumper.hero["y"])
	if float(jumper.hero["vy"]) > -10.0:
		fails.append("jump")
	var armed = WorldScript.new()
	armed.start_phase(0, 0, 6, 0, "limitless")
	armed.tick(1.0, {"l": false, "r": false, "u": false, "d": false, "jump": false, "attack": true})
	if armed.projectiles.is_empty():
		fails.append("limitless")
	var late = WorldScript.new()
	late.start_phase(19, 0, 10, 0, "boss_espirito")
	late.hero["x"] = 200.0
	late.tick(1.0, {"l": false, "r": false, "u": false, "d": false, "jump": false, "attack": true})
	if late.wave == null:
		fails.append("espirito aoe")
	if fails.is_empty():
		print("SMOKE OK")
		quit(0)
	else:
		print("FAIL ", fails)
		quit(1)
