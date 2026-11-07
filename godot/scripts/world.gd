extends Node2D

const Cat = preload("res://scripts/catalog.gd")
const Sprites = preload("res://scripts/sprites.gd")

var phase_i := 0
var sub := 0
var ng := 0
var hp_max := 6
var coins := 0
var points := 0
var time := 0.0
var cam := 0.0
var shake := 0.0
var slowmo := 0.0
var flash := 0.0
var hurt := 0.0
var sub_t := 0.0
var note := ""
var note_t := 0.0
var combo := 0
var combo_t := 0.0
var boss_dead := false
var intro_done := false
var event := ""
var boss_name := ""
var boss_line := ""

var hero: Dictionary = {}
var enemies: Array = []
var projectiles: Array = []
var shots: Array = []
var pickups: Array = []
var particles: Array = []
var numbers: Array = []
var hitbox = null
var wave = null
var _seq := 1
var _tex := {}

func start_phase(i: int, wallet: int, hearts: int, cycle: int, armor: String) -> void:
	phase_i = i
	sub = 0
	ng = cycle
	hp_max = hearts
	coins = wallet
	points = 0
	time = 0.0
	cam = 0.0
	shake = 0.0
	slowmo = 0.0
	flash = 0.0
	hurt = 0.0
	sub_t = 0.0
	note = ""
	note_t = 0.0
	combo = 0
	combo_t = 0.0
	boss_dead = false
	intro_done = false
	event = ""
	projectiles = []
	shots = []
	pickups = []
	particles = []
	numbers = []
	hitbox = null
	wave = null
	var ph := Cat.phase(i)
	enemies = scale_list(spawn_sub(0), int(ph["n"]))
	hero = {
		"x": 100.0, "y": Cat.FLOOR - 56.0, "w": 36.0, "h": 56.0,
		"vx": 0.0, "vy": 0.0, "ground": true, "facing": true,
		"hp": hearts, "hp_max": hearts, "iframe": 0.0, "atk": 0.0,
		"fly": false, "last_jump": -100.0, "ang": 0, "dg": 0,
		"coyote": 6.0, "jbuf": 0.0, "armor": armor,
	}
	var plats := platforms()
	if not plats.is_empty():
		var top: Dictionary = plats[0]
		for p in plats:
			if p["y"] < top["y"]:
				top = p
		for n in 5:
			pickups.append(_gem(top["x"] + 10.0 + n * 22.0, top["y"] - 24.0, 0.0, 99999.0))
		var g := make_enemy("v", top["x"] + top["w"] * 0.5 - 17.0, 1, str(ph["flyer"]))
		g["y_base"] = top["y"] - 60.0
		g["y"] = g["y_base"]
		enemies.append(scale_list([g], int(ph["n"]))[0])

func consume_event() -> String:
	var e := event
	event = ""
	return e

func boss_near(dist: float) -> Dictionary:
	for e in enemies:
		if e["boss"] and abs(hero["x"] - e["x"]) < dist and e["hp"] > 0:
			return e
	return {}

func cut_jump() -> void:
	if hero.is_empty():
		return
	if hero["vy"] < -3.0 and not hero["fly"]:
		hero["vy"] *= 0.4

func show_note(text: String) -> void:
	note = text
	note_t = 50.0

func tick(dtf: float, inp: Dictionary) -> void:
	if hero.is_empty():
		return
	time += dtf
	var ph := Cat.phase(phase_i)
	if sub >= 4 and not boss_dead and _boss() == null:
		var spawned := scale_list(spawn_sub(4), int(ph["n"]))
		for e in spawned:
			if e["boss"]:
				e["x"] = hero["x"] + (700.0 if hero["facing"] else -700.0)
				e["y"] = Cat.FLOOR - e["h"]
				enemies.append(e)
				intro_done = false
				break
	if not intro_done:
		var near := boss_near(600.0)
		if not near.is_empty():
			intro_done = true
			boss_name = str(near["name"])
			boss_line = Cat.line_for(boss_name)
			event = "boss"
			shake = maxf(shake, 10.0)
			return

	var move := 0.0
	if inp.get("l", false):
		move = -1.0
	if inp.get("r", false):
		move = 1.0
	hero["vx"] = move * Cat.SPEED
	if move != 0.0:
		hero["facing"] = move > 0.0

	if hero["jbuf"] > 0.0:
		hero["jbuf"] -= dtf
	if not hero["ground"] and hero["coyote"] > 0.0:
		hero["coyote"] -= dtf

	if inp.get("jump", false):
		var passed: float = time - hero["last_jump"]
		var arm := str(hero["armor"])
		if (arm == "angelical" or arm == "dragao_supremo") and passed < 18.0:
			hero["fly"] = not hero["fly"]
			hero["vy"] = -3.0 if hero["fly"] else 0.0
		elif hero["fly"]:
			hero["vy"] = -6.0
		elif hero["ground"] or hero["coyote"] > 0.0:
			hero["vy"] = -Cat.JUMP
			hero["ground"] = false
			hero["coyote"] = 0.0
		else:
			hero["jbuf"] = 8.0
		hero["last_jump"] = time

	if hero["fly"]:
		if str(hero["armor"]) != "angelical" and str(hero["armor"]) != "dragao_supremo":
			hero["fly"] = false
		else:
			var lift := 0.0
			if inp.get("u", false):
				lift = -4.0
			if inp.get("d", false):
				lift = 4.0
			if lift != 0.0:
				hero["vy"] = lift
			else:
				hero["vy"] *= 0.92

	if inp.get("attack", false):
		do_attack()

	var ladder := _ladder_here()
	if not ladder.is_empty() and (inp.get("u", false) or inp.get("d", false)) and not hero["fly"]:
		hero["vy"] = -3.5 if inp.get("u", false) else 3.0
		if hero["y"] < ladder["y_top"]:
			hero["y"] = ladder["y_top"]
		hero["ground"] = false
	elif not hero["fly"]:
		hero["vy"] += Cat.GRAV * dtf

	hero["x"] += hero["vx"] * dtf
	hero["y"] += hero["vy"] * dtf
	if hero["fly"] and hero["y"] < 20.0:
		hero["y"] = 20.0
		hero["vy"] = 0.0

	hero["ground"] = false
	if hero["y"] + hero["h"] >= Cat.FLOOR:
		hero["y"] = Cat.FLOOR - hero["h"]
		hero["vy"] = 0.0
		hero["ground"] = true
		hero["fly"] = false
	if hero["vy"] >= 0.0 and not hero["fly"]:
		var prev_y: float = hero["y"] - hero["vy"] * dtf
		for p in platforms():
			if hero["x"] + hero["w"] > p["x"] + 4.0 and hero["x"] < p["x"] + p["w"] - 4.0 \
					and hero["y"] + hero["h"] >= p["y"] and prev_y + hero["h"] <= p["y"] + 2.0:
				hero["y"] = p["y"] - hero["h"]
				hero["vy"] = 0.0
				hero["ground"] = true
				break
	if hero["ground"]:
		hero["coyote"] = 6.0
		if hero["jbuf"] > 0.0:
			hero["vy"] = -Cat.JUMP
			hero["ground"] = false
			hero["jbuf"] = 0.0
			hero["coyote"] = 0.0
	hero["x"] = clampf(hero["x"], 0.0, float(ph["width"]) - hero["w"])

	if hero["atk"] > 0.0:
		hero["atk"] -= dtf
		if hitbox != null:
			var reach: float = hitbox["w"]
			hitbox["x"] = hero["x"] + hero["w"] if hero["facing"] else hero["x"] - reach
			hitbox["y"] = hero["y"] + hitbox["yoff"]
			hitbox["life"] -= dtf
			for e in enemies:
				if e["hp"] <= 0 or e["stun"] > 0:
					continue
				if _overlap(hitbox, e):
					_hurt_enemy(e, int(hitbox["dmg"]), 2.0 if hero["facing"] else -2.0, 15.0)
			if hitbox["life"] <= 0.0:
				hitbox = null
	else:
		hitbox = null

	if wave != null:
		wave["r"] += 7.0 * dtf
		wave["x"] = hero["x"] + hero["w"] * 0.5
		wave["y"] = hero["y"] + hero["h"] * 0.5
		wave["life"] -= dtf
		for e in enemies:
			if e["hp"] <= 0 or e["stun"] > 0 or wave["hit"].has(e["id"]):
				continue
			var dx: float = (e["x"] + e["w"] * 0.5) - wave["x"]
			var dy: float = (e["y"] + e["h"] * 0.5) - wave["y"]
			if sqrt(dx * dx + dy * dy) <= wave["r"]:
				wave["hit"][e["id"]] = true
				_hurt_enemy(e, int(wave["dmg"]), 4.0 if dx > 0.0 else -4.0, 12.0)
		if wave["life"] <= 0.0 or wave["r"] > wave["rmax"]:
			wave = null

	for p in projectiles:
		p["x"] += p["vx"] * dtf
		p["y"] += p["vy"] * dtf
		p["life"] -= dtf
		p["rot"] += 0.4 * dtf
		if p["grav"]:
			p["vy"] += 0.4 * dtf
		if p["k"] == "tornado":
			for e in enemies:
				var dxx: float = (p["x"] + p["w"] * 0.5) - (e["x"] + e["w"] * 0.5)
				if abs(dxx) < 120.0 and abs(dxx) > 8.0:
					e["x"] += signf(dxx) * 1.5 * dtf
		for e in enemies:
			if e["hp"] <= 0 or e["stun"] > 0 or p["life"] <= 0.0:
				continue
			if _overlap(p, e):
				_hurt_enemy(e, int(p["dmg"]), 1.5 if p["vx"] > 0.0 else -1.5, 12.0)
				if not p["pierce"]:
					p["life"] = 0.0
	for p in projectiles:
		if p["boom"] and p["life"] <= 0.0 and not p["boomed"]:
			p["boomed"] = true
			var ex: float = p["x"] + p["w"] * 0.5
			var ey: float = p["y"] + p["h"] * 0.5
			for e in enemies:
				if e["hp"] <= 0 or e["stun"] > 0:
					continue
				var dxx: float = (e["x"] + e["w"] * 0.5) - ex
				var dyy: float = (e["y"] + e["h"] * 0.5) - ey
				if sqrt(dxx * dxx + dyy * dyy) < 90.0:
					_hurt_enemy(e, 2, 4.0 if dxx > 0.0 else -4.0, 12.0)
			_burst(ex, ey, Color("#ffcc00"), 16)
			shake = maxf(shake, 8.0)
	projectiles = projectiles.filter(func(p):
		return p["life"] > 0.0 and p["x"] > cam - 120.0 and p["x"] < cam + Cat.VIEW_W + 120.0
	)

	for e in enemies:
		if e["stun"] > 0.0:
			e["stun"] -= dtf
			e["x"] += e["vx"] * dtf
			continue
		var dx: float = hero["x"] - e["x"]
		var spd := 1.5
		match str(e["k"]):
			"d": spd = 1.0
			"v": spd = 2.0
			"s": spd = 0.9
			"a": spd = 0.7
		if abs(dx) < 700.0:
			e["vx"] = signf(dx) * spd
		e["x"] += e["vx"] * dtf
		if e["k"] == "v":
			e["ph"] += 0.08 * dtf
			e["y"] = e["y_base"] + sin(e["ph"]) * 30.0
			if abs(hero["x"] - e["x"]) > 1300.0:
				e["x"] = hero["x"] + (700.0 if hero["facing"] else -700.0)
				e["y"] = e["y_base"]
		if not e["boss"] and abs(hero["x"] - e["x"]) > 1800.0:
			e["x"] = hero["x"] + (800.0 if hero["facing"] else -800.0)
		if e["boss"]:
			e["shot"] -= dtf
			if e["shot"] <= 0.0 and abs(hero["x"] - e["x"]) < 700.0:
				_boss_shot(e)
				e["shot"] = 70.0 if e["k"] == "s" else 110.0
		if hero["iframe"] <= 0.0 and _overlap(hero, e):
			_hurt_hero(int(e["dmg"]), e["x"])
	enemies = enemies.filter(func(e): return e["hp"] > 0)

	for pk in pickups:
		pk["life"] -= dtf
		pk["ph"] += 0.1 * dtf
		pk["vy"] += Cat.GRAV * 0.5 * dtf
		pk["y"] += pk["vy"] * dtf
		if pk["y"] + pk["h"] >= Cat.FLOOR - 4.0:
			pk["y"] = Cat.FLOOR - 4.0 - pk["h"]
			pk["vy"] = 0.0
		var mdx: float = (hero["x"] + hero["w"] * 0.5) - (pk["x"] + pk["w"] * 0.5)
		var mdy: float = (hero["y"] + hero["h"] * 0.5) - (pk["y"] + pk["h"] * 0.5)
		var mdist := sqrt(mdx * mdx + mdy * mdy)
		if mdist < 100.0 and mdist > 4.0:
			var forca := (1.0 - mdist / 100.0) * 0.6
			pk["x"] += mdx / mdist * forca * 8.0 * dtf
			pk["y"] += mdy / mdist * forca * 8.0 * dtf
			pk["vy"] = 0.0
		if _overlap(hero, pk):
			if pk["k"] == "heart":
				if hero["hp"] < hero["hp_max"]:
					hero["hp"] = mini(hero["hp_max"], hero["hp"] + 2)
				else:
					points += 50
			else:
				points += 25
			pk["life"] = 0.0
	pickups = pickups.filter(func(pk): return pk["life"] > 0.0)

	for pe in shots:
		pe["x"] += pe["vx"] * dtf
		pe["y"] += pe["vy"] * dtf
		pe["life"] -= dtf
		if hero["iframe"] <= 0.0 and _overlap(hero, pe):
			_hurt_hero(int(pe["dmg"]), pe["x"])
			pe["life"] = 0.0
	shots = shots.filter(func(pe): return pe["life"] > 0.0)

	if hero["iframe"] > 0.0:
		hero["iframe"] -= dtf
	if hurt > 0.0:
		hurt -= dtf
	if flash > 0.0:
		flash -= dtf
	if sub_t > 0.0:
		sub_t -= dtf
	if note_t > 0.0:
		note_t -= dtf
	if combo_t > 0.0:
		combo_t -= dtf
		if combo_t <= 0.0:
			combo = 0
	for n in numbers:
		n["y"] += n["vy"] * dtf
		n["vy"] *= pow(0.94, dtf)
		n["life"] -= dtf
	numbers = numbers.filter(func(n): return n["life"] > 0.0)
	for pt in particles:
		pt["x"] += pt["vx"] * dtf
		pt["y"] += pt["vy"] * dtf
		pt["vy"] += 0.3 * dtf
		pt["life"] -= dtf
	particles = particles.filter(func(pt): return pt["life"] > 0.0)
	if shake > 0.0:
		shake *= pow(0.85, dtf)

	if hero["hp"] <= 0:
		event = "dead"
	elif sub < 4 and enemies.is_empty():
		sub += 1
		intro_done = false
		sub_t = 90.0
		enemies = scale_list(spawn_sub(sub), int(ph["n"]))
		if sub >= 4:
			for e in enemies:
				if e["boss"]:
					e["x"] = hero["x"] + (550.0 if hero["facing"] else -550.0)
					e["y"] = Cat.FLOOR - e["h"]
	elif sub >= 4 and (boss_dead or _boss() == null):
		event = "win"

	var target: float = hero["x"] - Cat.VIEW_W / 3.0
	target = clampf(target, 0.0, maxf(0.0, float(ph["width"]) - Cat.VIEW_W))
	cam += (target - cam) * (1.0 - pow(0.9, dtf))

func platforms() -> Array:
	var out: Array = []
	for spec in Cat.phase(phase_i)["platforms"]:
		out.append(Cat.plat_rect(spec))
	return out

func ladders() -> Array:
	var out: Array = []
	for spec in Cat.phase(phase_i)["ladders"]:
		out.append(Cat.ladder_rect(spec))
	return out

func spawn_sub(sub_i: int) -> Array:
	var ph := Cat.phase(phase_i)
	if sub_i >= 4:
		var wave_list: Array = []
		for s in ph["spawns"]:
			wave_list.append(make_enemy(str(s["k"]), float(s["x"]), int(s.get("hp", 1)), str(s.get("c", ph["mob"])), str(s.get("name", ""))))
		return wave_list
	var list: Array = []
	var mob := str(ph["mob"])
	list.append(make_enemy("m", 450, 2 + sub_i, mob))
	list.append(make_enemy("m", 700, 2 + sub_i, mob))
	list.append(make_enemy("m", 1000, 3 + sub_i, mob))
	if phase_i >= 1:
		list.append(make_enemy("v", 850, 1, str(ph["flyer"])))
	if sub_i >= 2:
		list.append(make_enemy("m", 1200, 3 + sub_i, mob))
	list.append(make_enemy("sub", 1500, 4 + sub_i * 2, str(ph["sub_c"]), str(ph["sub_n"])))
	return list

func scale_list(list: Array, phase_n: int) -> Array:
	var f := Cat.factor(phase_n, ng)
	for e in list:
		e["hp"] = ceili(float(e["hp"]) * f)
		e["hp_max"] = e["hp"]
		var dmg := int(e["dmg"])
		if phase_n >= 9 and not e["boss"]:
			dmg = 2
		if ng >= 1 and not e["boss"]:
			dmg = maxi(dmg, 2)
		if ng >= 2 and not e["boss"]:
			dmg = maxi(dmg, 3)
		if ng >= 1 and e["boss"]:
			dmg = maxi(dmg, 3)
		e["dmg"] = dmg
	return list

func make_enemy(kind: String, x: float, hp: int, col: String, name: String = "") -> Dictionary:
	_seq += 1
	var e := {
		"id": _seq, "k": kind, "x": x, "y": 0.0, "w": 38.0, "h": 40.0,
		"vx": -1.2, "vy": 0.0, "hp": hp, "hp_max": hp, "dmg": 1, "pts": 50,
		"stun": 0.0, "c": col, "name": name, "boss": false,
		"y_base": 0.0, "ph": randf() * TAU, "shot": 90.0,
	}
	match kind:
		"m":
			e["y"] = Cat.FLOOR - 40.0
		"v":
			e["w"] = 34.0
			e["h"] = 28.0
			e["y"] = Cat.FLOOR - 180.0
			e["y_base"] = e["y"]
			e["vx"] = -1.6
			e["hp"] = 1
			e["hp_max"] = 1
			e["pts"] = 80
		"d":
			e["w"] = 80.0
			e["h"] = 70.0
			e["y"] = Cat.FLOOR - 70.0
			e["vx"] = -0.8
			e["pts"] = 300
			e["boss"] = true
		"sub":
			e["w"] = 60.0
			e["h"] = 50.0
			e["y"] = Cat.FLOOR - 50.0
			e["vx"] = -1.0
			e["pts"] = 200
		"s":
			e["w"] = 70.0
			e["h"] = 120.0
			e["y"] = Cat.FLOOR - 120.0
			e["vx"] = -0.7
			e["hp"] = 18
			e["hp_max"] = 18
			e["pts"] = 1000
			e["boss"] = true
			e["name"] = "SHIGARAKI"
			e["c"] = "#222222"
		"a":
			e["w"] = 90.0
			e["h"] = 160.0
			e["y"] = Cat.FLOOR - 160.0
			e["vx"] = -0.5
			e["hp"] = 30
			e["hp_max"] = 30
			e["dmg"] = 2
			e["pts"] = 2500
			e["boss"] = true
			e["name"] = "ALL FOR ONE"
			e["c"] = "#1a0030"
	return e

func do_attack() -> void:
	if hero["atk"] > 0.0:
		return
	hero["atk"] = 12.0
	var d := 1.0 if hero["facing"] else -1.0
	var mx: float = hero["x"] + hero["w"] if hero["facing"] else hero["x"]
	var my: float = hero["y"] + 24.0
	match str(hero["armor"]):
		"cavaleiro":
			_melee(50, 10, hero["h"] - 20, 8, 1)
		"ninja":
			_fire("shuriken", mx, my, 8.0 * d, 0.0, 16, 16, 1, 120)
		"robo":
			_fire("laser", mx, my + 4.0, 14.0 * d, 0.0, 28, 6, 2, 60, true)
		"mago_fogo":
			_fire("fogo", mx, my, 7.0 * d, 0.0, 24, 24, 1, 100)
		"mago_gelo":
			_fire("gelo", mx, my, 9.0 * d, 0.0, 18, 22, 1, 110)
		"mago_terra":
			_fire("terra", mx, my - 10.0, 6.0 * d, -4.0, 26, 26, 2, 100, false, true)
		"mago_vento":
			_fire("vento", mx, my, 11.0 * d, 0.0, 38, 12, 1, 90, true)
		"samurai":
			_melee(60, 5, hero["h"] - 10, 10, 2)
		"elementar":
			_fire("fogo", mx, my - 10.0, 8.0 * d, 0.0, 22, 18, 1, 100)
			_fire("agua", mx, my + 10.0, 8.0 * d, 0.0, 22, 18, 1, 100)
		"princesa":
			_aoe(150, 26, 2, "gold")
		"individualidade":
			_melee(80, 0, hero["h"], 8, 3)
			_fire("onda", mx, my - 8.0, 12.0 * d, 0.0, 36, 14, 2, 80, true)
			_fire("onda", mx, my + 8.0, 12.0 * d, 0.0, 36, 14, 2, 80, true)
			shake = maxf(shake, 8.0)
		"limitless":
			_fire("purple", mx, my + 4.0, 18.0 * d, 0.0, 90, 18, 3, 90, true)
			for i in 3:
				_fire("purple", mx - i * 20.0 * d, my + (i - 1) * 6.0, 18.0 * d, 0.0, 12, 12, 1, 90, true)
			shake = maxf(shake, 12.0)
		"boss_dragao":
			_fire("fogo", mx, my, 8.0 * d, 0.0, 26, 26, 2, 110)
		"boss_demonio", "boss_dragao_final":
			for i in [-1, 0, 1]:
				_fire("fogo", mx, my + float(i) * 12.0, 8.0 * d, float(i) * 0.6, 28, 28, 2, 110)
			shake = maxf(shake, 4.0)
		"boss_comissario", "boss_piloto":
			for i in 3:
				_fire("bullet", mx + i * 8.0 * d, my + float(i) * 2.0, 14.0 * d, 0.0, 16, 6, 1, 80)
		"boss_doutor", "boss_neurotoxina":
			for i in [-1, 0, 1]:
				_fire("syringe", mx, my + float(i) * 8.0, 9.0 * d, float(i) * 0.5, 24, 6, 1, 100)
		"boss_shigaraki":
			_aoe(180, 28, 2, "decay")
		"boss_glitch":
			for i in 4:
				_fire("glitch", mx, my + (i - 1.5) * 7.0, (8.0 + randf() * 2.0) * d, (randf() - 0.5) * 2.0, 14, 14, 1, 90)
		"boss_chef":
			for i in [-1, 0, 1]:
				_fire("knife", mx, my + float(i) * 8.0, 10.0 * d, float(i) * 0.4, 22, 6, 1, 90)
		"boss_palhaco", "boss_clown":
			_fire("bomb", mx, my - 10.0, 6.0 * d, -4.0, 24, 24, 2, 70, false, true, true)
		"boss_professor", "boss_escultor":
			_fire("ruler", mx, my + 4.0, 13.0 * d, 0.0, 56, 6, 1, 80, true)
		"boss_afo":
			_fire("purple", mx, my + 4.0, 16.0 * d, 0.0, 60, 10, 2, 70, true)
			_fire("purple", mx, my - 14.0, 7.0 * d, 0.0, 30, 30, 2, 100)
			shake = maxf(shake, 6.0)
		"boss_hooligan":
			_melee(70, 8, hero["h"] - 8, 8, 2)
		"boss_lobo":
			for i in [-1, 0, 1]:
				_fire("claw", mx, my + float(i) * 8.0, 11.0 * d, float(i) * 0.3, 20, 10, 1, 80)
		"boss_tubarao":
			_fire("agua", mx, my - 8.0, 7.0 * d, -3.0, 28, 20, 2, 100, false, true)
		"boss_maestro":
			for i in range(-2, 3):
				_fire("note", mx, my + float(i) * 8.0, 10.0 * d, float(i) * 0.35, 14, 14, 1, 100)
		"boss_espirito":
			_aoe(210, 30, 3, "spirit")
		"dragao_supremo":
			var step := int(hero["dg"]) % 4
			hero["dg"] = step + 1
			if step == 0:
				for i in [-1, 0, 1]:
					_fire("fogo", mx, my + float(i) * 12.0, 8.0 * d, float(i) * 0.6, 30, 30, 2, 110)
			elif step == 1:
				for i in range(-2, 3):
					_fire("gelo", mx, my + float(i) * 8.0, 9.0 * d, float(i) * 0.4, 20, 24, 1, 110)
			elif step == 2:
				_fire("tornado", mx - 25.0, hero["y"] - 30.0, 5.0 * d, 0.0, 70, hero["h"] + 50, 3, 160, true)
				shake = maxf(shake, 8.0)
			else:
				_aoe(220, 32, 3, "tri")
		"angelical":
			var step2 := int(hero["ang"]) % 3
			hero["ang"] = step2 + 1
			if step2 == 0:
				_fire("pena", mx, my, 8.0 * d, -1.0, 22, 14, 1, 130)
			elif step2 == 1:
				_fire("chama", mx, my, 7.0 * d, 0.0, 26, 26, 1, 110)
			else:
				_fire("feixe", mx, my + 4.0, 16.0 * d, 0.0, 50, 10, 2, 80, true)
		_:
			_melee(50, 10, hero["h"] - 20, 8, 1)

func _melee(reach: float, yoff: float, height: float, life: float, dmg: int) -> void:
	var hx: float = hero["x"] + hero["w"] if hero["facing"] else hero["x"] - reach
	hitbox = {"x": hx, "y": hero["y"] + yoff, "w": reach, "h": height, "life": life, "dmg": dmg, "yoff": yoff}

func _aoe(rmax: float, life: float, dmg: int, style: String) -> void:
	wave = {
		"x": hero["x"] + hero["w"] * 0.5, "y": hero["y"] + hero["h"] * 0.5,
		"r": 14.0, "rmax": rmax, "life": life, "dmg": dmg, "style": style, "hit": {},
	}
	shake = maxf(shake, 6.0)

func _fire(kind: String, x: float, y: float, vx: float, vy: float, w: float, h: float, dmg: int, life: float, pierce := false, grav := false, boom := false) -> void:
	projectiles.append({
		"k": kind, "x": x, "y": y, "vx": vx, "vy": vy, "w": w, "h": h,
		"dmg": dmg, "life": life, "pierce": pierce, "grav": grav, "boom": boom,
		"rot": 0.0, "boomed": false,
	})

func _hurt_enemy(e: Dictionary, dmg: int, kx: float, stun: float) -> void:
	if e["hp"] <= 0 or e["stun"] > 0.0:
		return
	e["hp"] -= dmg
	e["stun"] = stun
	e["vx"] = kx
	_num(e["x"] + e["w"] * 0.5, e["y"], "-%d" % dmg, Color("#ff4444") if dmg >= 3 else (Color("#ffcc00") if dmg >= 2 else Color.WHITE))
	_burst(e["x"] + e["w"] * 0.5, e["y"] + e["h"] * 0.5, Color("#ffcc00"), 6)
	shake = maxf(shake, 6.0 if e["boss"] else 3.0)
	if e["hp"] <= 0:
		_kill(e)

func _kill(e: Dictionary) -> void:
	points += int(e["pts"])
	var gain := _wallet(e)
	coins += gain
	_num(e["x"] + 20.0, e["y"] + 10.0, "+%dc" % gain, Color("#ffcc00"))
	combo += 1
	combo_t = 100.0
	_drop(e)
	_burst(e["x"] + e["w"] * 0.5, e["y"] + e["h"] * 0.5, Color("#ff4444"), 14)
	shake = maxf(shake, 16.0 if e["boss"] else 5.0)
	if e["boss"]:
		boss_dead = true
		slowmo = 36.0
		flash = 8.0

func _wallet(e: Dictionary) -> int:
	if e["k"] == "s" or e["k"] == "a":
		return 500
	if e["boss"]:
		return 200
	if e["k"] == "sub":
		return 50
	if e["k"] == "v":
		return 5
	return 2

func _drop(e: Dictionary) -> void:
	var x: float = e["x"] + e["w"] * 0.5 - 12.0
	var y: float = e["y"] + e["h"] * 0.5
	pickups.append(_heart(x, y, -3.0))
	if randf() < 0.35:
		pickups.append(_gem(x + 30.0, y, -3.0, 600.0))
	if e["boss"]:
		pickups.append(_heart(x + 50.0, y, -4.0))
		if randf() < 0.5:
			pickups.append(_heart(x - 30.0, y, -4.0))
	if e["k"] == "sub":
		pickups.append(_gem(x - 30.0, y, -3.0, 600.0))

func _heart(x: float, y: float, vy: float) -> Dictionary:
	return {"k": "heart", "x": x, "y": y, "w": 24.0, "h": 22.0, "vy": vy, "life": 600.0, "ph": 0.0}

func _gem(x: float, y: float, vy: float, life: float) -> Dictionary:
	return {"k": "gem", "x": x, "y": y, "w": 18.0, "h": 18.0, "vy": vy, "life": life, "ph": 0.0}

func _hurt_hero(dmg: int, src_x: float) -> void:
	hero["hp"] -= dmg
	hero["iframe"] = 60.0
	hurt = 14.0
	hero["vy"] = -6.0
	hero["x"] += -8.0 if hero["x"] < src_x else 8.0
	shake = maxf(shake, 8.0)
	_burst(hero["x"] + hero["w"] * 0.5, hero["y"] + hero["h"] * 0.5, Color("#ff8888"), 10)

func _boss_shot(e: Dictionary) -> void:
	var dx: float = (hero["x"] + hero["w"] * 0.5) - (e["x"] + e["w"] * 0.5)
	var dy: float = (hero["y"] + hero["h"] * 0.5) - (e["y"] + e["h"] * 0.5)
	var dist := maxf(1.0, sqrt(dx * dx + dy * dy))
	var kind := str(Cat.phase(phase_i)["shot"])
	var dmg := 1
	var w := 18.0
	var h := 18.0
	if e["k"] == "s":
		kind = "decay"
		dmg = 2
		w = 28.0
		h = 28.0
	elif e["k"] == "a":
		kind = "energy"
		dmg = 2
		w = 36.0
		h = 36.0
	shots.append({
		"k": kind,
		"x": e["x"] + e["w"] * 0.5 - w * 0.5,
		"y": e["y"] + e["h"] * 0.5 - h * 0.5,
		"vx": dx / dist * 4.5, "vy": dy / dist * 4.5,
		"w": w, "h": h, "life": 180.0, "dmg": dmg,
	})

func _num(x: float, y: float, text: String, col: Color) -> void:
	numbers.append({"x": x, "y": y, "vy": -2.5, "life": 50.0, "t": text, "c": col})

func _burst(x: float, y: float, col: Color, n: int) -> void:
	for i in n:
		var ang := randf() * TAU
		var v := randf() * 4.0 + 1.0
		particles.append({
			"x": x, "y": y, "vx": cos(ang) * v, "vy": sin(ang) * v - 1.0,
			"life": 30.0 + randf() * 20.0, "c": col, "s": 2 + randi() % 3,
		})

func _boss():
	for e in enemies:
		if e["boss"] and e["hp"] > 0:
			return e
	return null

func _ladder_here() -> Dictionary:
	for lad in ladders():
		if hero["x"] + hero["w"] > lad["x"] and hero["x"] < lad["x"] + lad["w"] \
				and hero["y"] + hero["h"] > lad["y_top"] and hero["y"] < lad["y_bot"] + 5.0:
			return lad
	return {}

func _overlap(a: Dictionary, b: Dictionary) -> bool:
	return a["x"] < b["x"] + b["w"] and a["x"] + a["w"] > b["x"] \
		and a["y"] < b["y"] + b["h"] and a["y"] + a["h"] > b["y"]

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if hero.is_empty():
		return
	var ph := Cat.phase(phase_i)
	var width := float(ph["width"])
	draw_rect(Rect2(0, 0, width, Cat.VIEW_H), Cat.colorize(str(ph["sky"])))
	var bg := _texture(str(ph["bg"]))
	if bg:
		var iw := bg.get_width()
		var xx := 0.0
		while xx < width:
			draw_texture(bg, Vector2(xx, 0))
			xx += iw
	draw_rect(Rect2(0, Cat.FLOOR, width, Cat.VIEW_H - Cat.FLOOR), Cat.colorize(str(ph["ground"])))
	_draw_props(ph, width)
	for lad in ladders():
		var lx: float = lad["x"]
		var top: float = lad["y_top"]
		var bot: float = lad["y_bot"]
		var lw: float = lad["w"]
		draw_rect(Rect2(lx, top, 5, bot - top), Color("#3e3e46"))
		draw_rect(Rect2(lx + lw - 5, top, 5, bot - top), Color("#3e3e46"))
		draw_rect(Rect2(lx + 1, top, 3, bot - top), Color("#c4c4ce"))
		draw_rect(Rect2(lx + lw - 4, top, 3, bot - top), Color("#c4c4ce"))
		var yy := top + 8.0
		while yy < bot - 4.0:
			draw_rect(Rect2(lx, yy, lw, 3), Color("#9a9aa6"))
			yy += 16.0
	for plat in platforms():
		var px: float = plat["x"]
		var py: float = plat["y"]
		var pw: float = plat["w"]
		var tall: float = plat["h"]
		draw_rect(Rect2(px - 2, py - 2, pw + 4, tall + 5), Color(0.09, 0.05, 0.03, 0.92))
		draw_rect(Rect2(px, py, pw, tall), Color("#6a4326"))
		draw_rect(Rect2(px, py, pw, 3), Color("#e0a15c"))
		draw_rect(Rect2(px + 3, py + tall - 3, pw - 6, 2), Color(0, 0, 0, 0.28))
	for pk in pickups:
		Sprites.pickup(self, pk)
	var hero_x: float = hero["x"]
	for e in enemies:
		Sprites.enemy(self, e, time, hero_x)
	for proj in projectiles:
		Sprites.shot(self, proj, true, time)
	for pe in shots:
		Sprites.shot(self, pe, false, time)
	for pt in particles:
		var c: Color = pt["c"]
		c.a = clampf(float(pt["life"]) / 40.0, 0.0, 1.0)
		draw_circle(Vector2(pt["x"], pt["y"]), maxf(1.2, float(pt["s"]) * 0.55), c)
	Sprites.hero(self, hero, time)
	if hitbox != null:
		var facing_right: bool = hero["facing"]
		Sprites.slash(self, hitbox, facing_right)
	if wave != null:
		Sprites.aoe(self, wave)
	var font := ThemeDB.fallback_font
	for n in numbers:
		var nx: float = n["x"]
		var ny: float = n["y"]
		var label: String = str(n["t"])
		draw_string(font, Vector2(nx + 1, ny + 1), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0, 0, 0, 0.72))
		draw_string(font, Vector2(nx, ny), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, n["c"])

func _draw_props(ph: Dictionary, width: float) -> void:
	var file := str(ph["bg"])
	if file != "" and _texture(file) != null:
		return
	var col := Cat.colorize(str(ph["mob"]))
	var x := 180.0
	var base := Cat.FLOOR
	var kind := sub % 3
	while x < width - 80.0:
		if kind == 0:
			draw_rect(Rect2(x - 2, base - 50, 76, 52), Color(0.08, 0.05, 0.04, 0.92))
			draw_rect(Rect2(x, base - 46, 70, 46), col.darkened(0.32))
			draw_rect(Rect2(x, base - 46, 70, 7), col.lightened(0.12))
			draw_rect(Rect2(x + 8, base - 30, 18, 14), col.darkened(0.5))
		elif kind == 1:
			draw_rect(Rect2(x + 22, base - 118, 22, 118), Color(0.08, 0.05, 0.04, 0.92))
			draw_rect(Rect2(x + 24, base - 114, 18, 114), col.darkened(0.28))
			draw_rect(Rect2(x + 8, base - 28, 50, 12), col)
			draw_rect(Rect2(x + 8, base - 28, 50, 3), col.lightened(0.15))
		else:
			draw_rect(Rect2(x, base - 78, 86, 24), Color(0.08, 0.05, 0.04, 0.92))
			draw_rect(Rect2(x + 2, base - 74, 82, 20), col.darkened(0.15))
			draw_rect(Rect2(x + 36, base - 54, 8, 54), col.darkened(0.4))
		x += 250.0

func _texture(file: String) -> Texture2D:
	if file == "":
		return null
	if _tex.has(file):
		return _tex[file]
	var path := ProjectSettings.globalize_path("res://").path_join("../assets").path_join(file)
	var img := Image.load_from_file(path)
	var tex: Texture2D = null
	if img != null and img.get_width() > 0:
		tex = ImageTexture.create_from_image(img)
	_tex[file] = tex
	return tex
