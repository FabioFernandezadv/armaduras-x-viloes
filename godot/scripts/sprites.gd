extends RefCounted

const Cat = preload("res://scripts/catalog.gd")

const HAIR := Color("#2ad46e")
const HAIR_D := Color("#0d7a3c")
const SKIN := Color("#ffd0a8")
const INK := Color(0.08, 0.045, 0.05, 0.96)
const PAPER := Color(0.95, 0.91, 0.84, 0.95)
const BLADE := Color("#d7dee8")

static func hero(ci: CanvasItem, h: Dictionary, time: float) -> void:
	var x: float = h["x"]
	var y: float = h["y"]
	var w: float = h["w"]
	var hh: float = h["h"]
	var vx: float = h["vx"]
	var ground: bool = h["ground"]
	var facing: bool = h["facing"]
	var atk: float = h["atk"]
	var flying: bool = h["fly"]
	var armor: String = str(h["armor"])
	var bob := 0.0
	if ground and absf(vx) < 0.2 and atk <= 0.0 and not flying:
		bob = sin(time * 0.08) * 2.0
	var walk := 0.0
	if ground and absf(vx) > 0.2 and not flying:
		walk = sin(time * 0.5)
	var attacking := atk > 0.0
	var swing := 0.0
	if attacking:
		swing = 1.0 - clampf(atk / 12.0, 0.0, 1.0)
	var face := 1.0
	if not facing:
		face = -1.0
	var lean := 0.0
	if attacking:
		lean = 7.0 * swing
	if not ground and not flying:
		lean += 3.0
	hero_at(ci, x + w * 0.5 + lean * face, y + hh - bob, 1.0, armor, facing, walk, swing, attacking, flying, (not ground) and (not flying), time)
	var iframe: float = h["iframe"]
	if iframe > 0.0 and int(iframe / 4.0) % 2 == 0:
		ci.draw_circle(Vector2(x + w * 0.5, y + hh * 0.35), 30.0, Color(1, 0.94, 0.9, 0.34))

static func hero_at(ci: CanvasItem, cx: float, foot: float, scale: float, armor_id: String, face_right: bool, walk: float, swing: float, attacking: bool, flying: bool, airborne: bool, time: float) -> void:
	var face := 1.0
	if not face_right:
		face = -1.0
	var arm := Cat.armor_by_id(armor_id)
	var legs := Cat.colorize(str(arm["legs"]))
	var body := Cat.colorize(str(arm["body"]))
	var trim := Cat.colorize(str(arm["trim"]))
	var style := _head_style(armor_id)
	var sway := sin(time * 0.14) * 6.0
	if absf(walk) > 0.25:
		sway -= 10.0
	if airborne:
		sway += 8.0
	if flying:
		sway -= 12.0
	var flap := sin(time * 0.22)
	if flying:
		flap = sin(time * 0.55)
	var shadow_scale := 1.0
	if airborne or flying:
		shadow_scale = 0.62
	_shadow(ci, cx, foot - 1.0 * scale, 30.0 * scale * shadow_scale, 8.0 * scale, 0.46 * shadow_scale)
	if armor_id == "boss_espirito":
		var aura := trim
		aura.a = 0.16
		_ellipse(ci, cx, foot - 64.0 * scale, 32.0 * scale, 50.0 * scale, aura, false)
	if style == "clown":
		_ellipse(ci, _v(cx, foot, face, scale, 2, 92).x, _v(cx, foot, face, scale, 2, 92).y, 20.0 * scale, 8.0 * scale, trim)
	if _winged(armor_id):
		if armor_id == "angelical":
			_feathers(ci, cx, foot, face, scale, Color("#f6f8ff"), trim, flap)
		else:
			var reach := 1.0
			if armor_id == "boss_demonio":
				reach = 0.62
			_bat_wing(ci, cx, foot, face, scale, body.darkened(0.18), trim, flap, 76.0, reach)
	if _tailed(armor_id):
		_tail(ci, cx, foot, face, scale, body, trim, sway)
	if style == "long" or armor_id == "princesa":
		_lock(ci, cx, foot, face, scale, -6.0, 104.0, -18.0, 62.0, HAIR_D)
		_lock(ci, cx, foot, face, scale, -2.0, 100.0, -14.0, 46.0, HAIR)
	_cape(ci, cx, foot, face, scale, _cape_col(body, trim), _cape_mode(armor_id), sway, airborne, flying)
	var s := walk
	var bkx := -9.0 - s * 5.0
	var bky := 26.0
	var bfx := -12.0 - s * 13.0
	var bfy := 1.0 + maxf(0.0, -s) * 8.0
	var fkx := 8.0 + s * 5.0
	var fky := 24.0
	var ffx := 14.0 + s * 13.0
	var ffy := 1.0 + maxf(0.0, s) * 8.0
	if airborne:
		bkx = -1.0
		bky = 34.0
		bfx = 8.0
		bfy = 18.0
		fkx = 14.0
		fky = 32.0
		ffx = 22.0
		ffy = 16.0
	elif flying:
		bkx = -18.0
		bky = 36.0
		bfx = -32.0
		bfy = 18.0
		fkx = -8.0
		fky = 30.0
		ffx = -20.0
		ffy = 12.0
	_leg(ci, cx, foot, face, scale, -6.0, 50.0, bkx, bky, bfx, bfy, legs, trim)
	var mid := _v(cx, foot, face, scale, 1.0, 70.0)
	_ellipse(ci, mid.x, mid.y, 16.0 * scale, 23.0 * scale, body)
	_poly(ci, PackedVector2Array([
		_v(cx, foot, face, scale, -18.0, 48.0),
		_v(cx, foot, face, scale, -16.0, 72.0),
		_v(cx, foot, face, scale, -8.0, 92.0),
		_v(cx, foot, face, scale, 10.0, 94.0),
		_v(cx, foot, face, scale, 20.0, 76.0),
		_v(cx, foot, face, scale, 18.0, 46.0),
	]), body, maxf(1.1, 2.2 * scale))
	_poly(ci, PackedVector2Array([
		_v(cx, foot, face, scale, -14.0, 76.0),
		_v(cx, foot, face, scale, 16.0, 74.0),
		_v(cx, foot, face, scale, 15.0, 82.0),
		_v(cx, foot, face, scale, -12.0, 84.0),
	]), trim, maxf(1.0, 1.6 * scale))
	_poly(ci, PackedVector2Array([
		_v(cx, foot, face, scale, -16.0, 46.0),
		_v(cx, foot, face, scale, 16.0, 44.0),
		_v(cx, foot, face, scale, 15.0, 52.0),
		_v(cx, foot, face, scale, -15.0, 54.0),
	]), trim.darkened(0.15), maxf(1.0, 1.5 * scale))
	_disc(ci, _v(cx, foot, face, scale, 0.0, 49.0), 3.6 * scale, trim.lightened(0.2))
	_poly(ci, PackedVector2Array([
		_v(cx, foot, face, scale, 0.0, 78.0),
		_v(cx, foot, face, scale, 8.0, 66.0),
		_v(cx, foot, face, scale, 0.0, 54.0),
		_v(cx, foot, face, scale, -8.0, 66.0),
	]), trim.lightened(0.12), maxf(1.0, 1.5 * scale))
	_poly(ci, PackedVector2Array([
		_v(cx, foot, face, scale, 6.0, 80.0),
		_v(cx, foot, face, scale, 24.0, 76.0),
		_v(cx, foot, face, scale, 20.0, 62.0),
		_v(cx, foot, face, scale, 4.0, 68.0),
	]), body.lightened(0.12), maxf(1.0, 1.6 * scale))
	if armor_id == "princesa":
		_poly(ci, PackedVector2Array([
			_v(cx, foot, face, scale, -16.0, 50.0),
			_v(cx, foot, face, scale, 18.0, 48.0),
			_v(cx, foot, face, scale, 28.0, 26.0),
			_v(cx, foot, face, scale, -24.0, 28.0),
		]), trim, maxf(1.0, 1.6 * scale))
	if armor_id == "elementar":
		_poly(ci, PackedVector2Array([
			_v(cx, foot, face, scale, -16.0, 60.0),
			_v(cx, foot, face, scale, -4.0, 58.0),
			_v(cx, foot, face, scale, -2.0, 86.0),
			_v(cx, foot, face, scale, -14.0, 84.0),
		]), Color("#1c6fd8"), maxf(1.0, 1.4 * scale))
	if armor_id == "boss_hooligan":
		_disc(ci, _v(cx, foot, face, scale, 18.0, 80.0), 10.0 * scale, body.lightened(0.08))
		_disc(ci, _v(cx, foot, face, scale, -16.0, 76.0), 8.0 * scale, body.darkened(0.08))
	if armor_id == "boss_tubarao":
		_poly(ci, PackedVector2Array([
			_v(cx, foot, face, scale, -10.0, 78.0),
			_v(cx, foot, face, scale, -28.0, 118.0),
			_v(cx, foot, face, scale, -4.0, 96.0),
		]), body.darkened(0.1), maxf(1.0, 1.6 * scale))
	_leg(ci, cx, foot, face, scale, 7.0, 48.0, fkx, fky, ffx, ffy, legs, trim)
	var pupil := Color(0.07, 0.05, 0.07)
	if armor_id == "boss_shigaraki" or armor_id == "boss_lobo" or armor_id == "boss_afo" or armor_id == "boss_espirito" or armor_id == "dragao_supremo":
		pupil = trim
	_draw_head(ci, cx, foot, face, scale, body, trim, style, pupil)
	_arm_weapon(ci, cx, foot, face, scale, body, trim, armor_id, attacking, swing)

static func enemy(ci: CanvasItem, e: Dictionary, time: float, hero_x: float) -> void:
	var kind: String = str(e["k"])
	var x: float = e["x"]
	var y: float = e["y"]
	var w: float = e["w"]
	var h: float = e["h"]
	var vx: float = e["vx"]
	var stun: float = e["stun"]
	var phase: float = e["ph"]
	var col := Cat.colorize(str(e["c"]))
	if stun > 0.0:
		col = col.lightened(0.4)
	var face := -1.0
	if absf(vx) > 0.12:
		face = signf(vx)
	elif hero_x >= x:
		face = 1.0
	var cx := x + w * 0.5
	var foot := y + h
	var name: String = str(e["name"])
	var is_boss: bool = e["boss"]
	var hp: float = e["hp"]
	var hp_max: float = e["hp_max"]
	var ratio := clampf(hp / maxf(1.0, hp_max), 0.0, 1.0)
	var top := foot
	var bar := 0.0
	if kind == "v":
		_flyer(ci, cx, y + h * 0.5, face, col, time + phase)
		top = y + h * 0.5 - 34.0
	elif kind == "m":
		top = _beast(ci, cx, foot, face, col, time, phase, 1.0, true)
	elif kind == "sub":
		top = _brute(ci, cx, foot, face, col, time, phase)
		bar = 72.0
	elif kind == "s":
		top = _shigaraki(ci, cx, foot, face, col, time)
		bar = 78.0
	elif kind == "a":
		top = _afo(ci, cx, foot, face, col, time, phase)
		bar = 96.0
	else:
		top = _phase_boss(ci, cx, foot, face, col, name, time, phase)
		bar = 86.0
	if is_boss or kind == "sub":
		_plate(ci, cx, top, bar, ratio, name)

static func pickup(ci: CanvasItem, pk: Dictionary) -> void:
	var x: float = pk["x"]
	var y: float = pk["y"]
	var ph: float = pk["ph"]
	var bob := sin(ph) * 3.0
	if str(pk["k"]) == "heart":
		heart_icon(ci, x, y + bob, 1.2, Color("#ff3355"), 2)
	else:
		var w: float = pk["w"]
		var h: float = pk["h"]
		coin(ci, x, y + bob, w, h)

static func shot(ci: CanvasItem, p: Dictionary, friendly: bool, time: float) -> void:
	var k: String = str(p["k"])
	var x: float = p["x"]
	var y: float = p["y"]
	var w: float = p["w"]
	var h: float = p["h"]
	var vx: float = p["vx"]
	var vy: float = p["vy"]
	var col := _shot_color(k)
	if not friendly:
		col = col.lightened(0.12)
	var cx := x + w * 0.5
	var cy := y + h * 0.5
	var ang := atan2(vy, vx)
	var length := maxf(w, h) * 0.62
	var thick := maxf(3.0, minf(w, h) * 0.5)
	var center := Vector2(cx, cy)
	match k:
		"fogo", "flame", "bomb", "chama":
			_flame(ci, center, ang, length, thick, col, Color("#ffe7a0"))
		"agua", "water":
			_flame(ci, center, ang, length, thick, col, Color("#d7ecff"))
		"gelo", "terra":
			_gem_shot(ci, center, ang, length, thick, col)
		"laser", "feixe", "onda", "ruler":
			_beam(ci, center, ang, length, thick, col)
		"shuriken":
			_shuriken(ci, center, maxf(length, thick), time * 0.35, col)
		"tornado":
			_tornado(ci, center, length, thick, col, time)
		"note", "notes":
			_note(ci, center, maxf(8.0, thick), col)
		"purple", "energy", "orb":
			_orb(ci, center, maxf(thick, length * 0.55), col)
		"bullet", "ball", "marble":
			_orb(ci, center, maxf(4.0, thick * 0.85), col)
		"knife", "syringe", "claw", "pena", "vento":
			_bolt(ci, center, ang, length, thick * 0.55, col)
		"decay":
			_orb(ci, center, maxf(thick, 8.0), col)
			ci.draw_arc(center, maxf(thick, 8.0) + 3.0, 0, TAU, 16, Color("#ff3355"), 1.8, true)
		"glitch":
			_gem_shot(ci, center + Vector2(3, -2), ang, length, thick, Color("#ff33ff"))
			_gem_shot(ci, center + Vector2(-3, 2), ang + 0.4, length * 0.8, thick, Color("#22ffff"))
		_:
			_gem_shot(ci, center, ang, length, thick, col)

static func slash(ci: CanvasItem, hb: Dictionary, facing_right: bool) -> void:
	var x: float = hb["x"]
	var y: float = hb["y"]
	var w: float = hb["w"]
	var h: float = hb["h"]
	var life: float = hb["life"]
	var fade := clampf(life / 8.0, 0.4, 1.0)
	var x_near := x
	var x_far := x + w
	if not facing_right:
		x_near = x + w
		x_far = x
	var p0 := Vector2(x_near, y + h * 0.06)
	var p1 := Vector2(x_far, y + h * 0.4)
	var p2 := Vector2(x_near + (x_far - x_near) * 0.12, y + h)
	var p3 := Vector2(x_near + (x_far - x_near) * 0.45, y + h * 0.55)
	ci.draw_colored_polygon(_ordered(PackedVector2Array([p0, p1, p2, p3])), Color(1, 0.95, 0.72, 0.22 * fade))
	ci.draw_polyline(PackedVector2Array([p0, p1, p2]), Color(1, 1, 0.92, 0.95 * fade), 5.0, true)
	ci.draw_polyline(PackedVector2Array([p0, p1, p2]), Color(1, 0.78, 0.2, 0.95 * fade), 2.0, true)

static func aoe(ci: CanvasItem, wave: Dictionary) -> void:
	var x: float = wave["x"]
	var y: float = wave["y"]
	var r: float = wave["r"]
	var style: String = str(wave["style"])
	var wc := Color("#ffcc00")
	if style == "decay":
		wc = Color("#ff2244")
	elif style == "spirit":
		wc = Color("#88aaff")
	elif style == "tri":
		wc = Color("#66ffcc")
	var soft := wc
	soft.a = 0.15
	_ellipse_raw(ci, x, y, r, r * 0.92, soft)
	var c := Vector2(x, y)
	ci.draw_arc(c, r + 4.0, 0, TAU, 28, Color(0.05, 0.04, 0.05, 0.55), 2.0, true)
	ci.draw_arc(c, r, 0, TAU, 36, wc, 3.4, true)
	ci.draw_arc(c, maxf(5.0, r - 7.0), 0, TAU, 28, Color(wc.r, wc.g, wc.b, 0.75), 1.5, true)
	for i in 6:
		var ang := TAU * float(i) / 6.0
		var dir := Vector2(cos(ang), sin(ang))
		ci.draw_line(c + dir * (r * 0.3), c + dir * (r * 0.82), Color(wc.r, wc.g, wc.b, 0.65), 1.6, true)

static func hud_heart(ci: CanvasItem, x: float, y: float, state: int) -> void:
	heart_icon(ci, x, y, 1.05, Color("#ff2d52"), state)

static func coin(ci: CanvasItem, x: float, y: float, w: float, h: float) -> void:
	var cx := x + w * 0.5
	var cy := y + h * 0.5
	var rx := maxf(4.0, w * 0.52)
	var ry := maxf(4.0, h * 0.52)
	_ellipse_raw(ci, cx, cy, rx + 1.7, ry + 1.7, Color(0.32, 0.15, 0.02, 0.96))
	_ellipse_raw(ci, cx, cy, rx, ry, Color("#ffc72e"))
	_ellipse_raw(ci, cx, cy, rx * 0.68, ry * 0.68, Color("#ffe38a"))
	ci.draw_arc(Vector2(cx, cy), rx * 0.55, 0.5, 2.5, 8, Color(1, 1, 1, 0.75), maxf(1.0, rx * 0.14), true)
	ci.draw_circle(Vector2(cx - rx * 0.28, cy - ry * 0.28), maxf(1.1, rx * 0.16), Color(1, 1, 1, 0.9))

static func heart_icon(ci: CanvasItem, x: float, y: float, scale: float, full: Color, state: int) -> void:
	var empty := Color("#5c1c2c")
	var left := empty
	var right := empty
	if state >= 1:
		left = full
	if state >= 2:
		right = full
	var grow := scale * 1.2
	var ox := x - 10.0 * scale * 0.2
	var oy := y - 9.0 * scale * 0.2
	_heart_raw(ci, ox, oy, grow, INK, INK)
	_heart_raw(ci, x, y, scale, left, right)
	if state >= 1:
		var glint := 0.72
		if state == 1:
			glint = 0.4
		ci.draw_circle(Vector2(x + 6.5 * scale, y + 6.2 * scale), 2.1 * scale, Color(1, 1, 1, glint))

static func _heart_raw(ci: CanvasItem, x: float, y: float, s: float, left: Color, right: Color) -> void:
	var c1 := Vector2(x + 6.6 * s, y + 6.5 * s)
	var c2 := Vector2(x + 13.6 * s, y + 6.5 * s)
	var mid := Vector2(x + 10.1 * s, y + 8.2 * s)
	var tip := Vector2(x + 10.1 * s, y + 18.4 * s)
	var l := Vector2(x + 0.8 * s, y + 9.4 * s)
	var r := Vector2(x + 19.4 * s, y + 9.4 * s)
	ci.draw_circle(c1, 6.3 * s, left)
	ci.draw_circle(c2, 6.3 * s, right)
	ci.draw_colored_polygon(_ordered(PackedVector2Array([l, mid, tip])), left)
	ci.draw_colored_polygon(_ordered(PackedVector2Array([mid, r, tip])), right)

static func _shot_color(k: String) -> Color:
	match k:
		"fogo", "flame", "bomb", "chama":
			return Color("#ff7700")
		"gelo":
			return Color("#d8ffff")
		"terra":
			return Color("#996633")
		"vento", "pena":
			return Color("#ccffcc")
		"laser", "feixe", "onda":
			return Color("#33ffff")
		"agua", "water":
			return Color("#4499ff")
		"purple", "energy", "orb":
			return Color("#bb55ff")
		"bullet", "ball":
			return Color("#dddddd")
		"knife", "ruler", "marble", "syringe":
			return Color("#f2f2f2")
		"decay":
			return Color("#331118")
		"glitch":
			return Color("#ff33ff")
		"claw":
			return Color("#dd3333")
		"note", "notes":
			return Color("#ffcc44")
		"tornado":
			return Color("#88ffcc")
		"shuriken":
			return Color("#e8e8e8")
		_:
			return Color.WHITE

static func _head_style(id: String) -> String:
	match id:
		"ninja", "mago_fogo", "mago_gelo", "mago_terra", "mago_vento", "boss_professor", "boss_espirito":
			return "hood"
		"robo", "boss_piloto":
			return "helm"
		"samurai":
			return "kabuto"
		"princesa":
			return "tiara"
		"limitless":
			return "blind"
		"angelical":
			return "long"
		"boss_lobo":
			return "wolf"
		"boss_tubarao":
			return "shark"
		"boss_palhaco", "boss_clown":
			return "clown"
		"boss_chef":
			return "chef"
		"boss_comissario":
			return "cap"
		"boss_afo", "boss_shigaraki":
			return "mask"
		"dragao_supremo", "boss_dragao", "boss_dragao_final", "boss_demonio":
			return "horns"
		_:
			return "hair"

static func _cape_mode(id: String) -> String:
	match id:
		"robo", "boss_piloto":
			return "jet"
		"ninja":
			return "scarf"
		"angelical", "dragao_supremo", "boss_dragao", "boss_dragao_final", "boss_demonio":
			return "short"
		_:
			return "long"

static func _winged(id: String) -> bool:
	return id == "angelical" or id == "dragao_supremo" or id == "boss_dragao" or id == "boss_dragao_final" or id == "boss_demonio"

static func _tailed(id: String) -> bool:
	return id == "dragao_supremo" or id == "boss_dragao" or id == "boss_dragao_final" or id == "boss_demonio" or id == "boss_lobo"

static func _weapon_kind(id: String) -> String:
	match id:
		"ninja":
			return "kunai"
		"robo", "boss_piloto":
			return "cannon"
		"mago_fogo", "mago_gelo", "mago_terra", "mago_vento", "elementar", "boss_espirito", "boss_professor", "boss_escultor":
			return "staff"
		"samurai":
			return "katana"
		"princesa", "angelical":
			return "rapier"
		"limitless":
			return "none"
		"individualidade", "boss_hooligan":
			return "fist"
		"boss_comissario":
			return "gun"
		"boss_doutor", "boss_neurotoxina":
			return "syringe"
		"boss_chef":
			return "knife"
		"boss_lobo", "boss_tubarao", "dragao_supremo", "boss_dragao", "boss_dragao_final", "boss_demonio", "boss_shigaraki":
			return "claws"
		"boss_maestro":
			return "baton"
		_:
			return "sword"

static func _cape_col(body: Color, trim: Color) -> Color:
	var cape := body.darkened(0.55)
	if cape.get_luminance() < 0.08:
		cape = trim.darkened(0.35)
	return cape

static func _draw_head(ci: CanvasItem, cx: float, foot: float, face: float, scale: float, body: Color, trim: Color, style: String, pupil: Color) -> void:
	_disc(ci, _v(cx, foot, face, scale, -10.0, 104.0), 5.6 * scale, SKIN.darkened(0.05))
	var hc := _v(cx, foot, face, scale, 2.0, 108.0)
	_ellipse(ci, hc.x, hc.y, 16.0 * scale, 17.0 * scale, SKIN)
	if style == "helm":
		_ellipse(ci, hc.x, hc.y - 1.0 * scale, 17.5 * scale, 18.0 * scale, body.lightened(0.06))
		var vis := _v(cx, foot, face, scale, 8.0, 106.0)
		_ellipse(ci, vis.x, vis.y, 11.0 * scale, 4.4 * scale, trim)
		_poly(ci, PackedVector2Array([
			_v(cx, foot, face, scale, -2.0, 124.0),
			_v(cx, foot, face, scale, 3.0, 144.0),
			_v(cx, foot, face, scale, 9.0, 124.0),
		]), HAIR, maxf(1.0, 1.6 * scale))
		return
	if style == "hood":
		var hood := _v(cx, foot, face, scale, -2.0, 116.0)
		_ellipse(ci, hood.x, hood.y, 17.0 * scale, 18.0 * scale, body.darkened(0.14))
		_poly(ci, PackedVector2Array([
			_v(cx, foot, face, scale, -8.0, 126.0),
			_v(cx, foot, face, scale, 8.0, 128.0),
			_v(cx, foot, face, scale, 0.0, 150.0),
		]), body.darkened(0.22), maxf(1.0, 1.6 * scale))
		var face_c := _v(cx, foot, face, scale, 10.0, 104.0)
		_ellipse(ci, face_c.x, face_c.y, 11.0 * scale, 12.0 * scale, SKIN)
		_poly(ci, PackedVector2Array([
			_v(cx, foot, face, scale, 4.0, 116.0),
			_v(cx, foot, face, scale, 10.0, 130.0),
			_v(cx, foot, face, scale, 16.0, 112.0),
		]), HAIR, maxf(1.0, 1.4 * scale))
		_hero_face(ci, cx, foot, face, scale, pupil, true)
		return
	_hair(ci, cx, foot, face, scale)
	if style == "blind":
		_poly(ci, PackedVector2Array([
			_v(cx, foot, face, scale, -14.0, 114.0),
			_v(cx, foot, face, scale, 18.0, 112.0),
			_v(cx, foot, face, scale, 18.0, 102.0),
			_v(cx, foot, face, scale, -14.0, 104.0),
		]), Color(0.04, 0.04, 0.05), maxf(1.0, 1.5 * scale))
		ci.draw_line(_v(cx, foot, face, scale, -10.0, 108.0), _v(cx, foot, face, scale, 16.0, 106.0), trim, maxf(1.2, 2.4 * scale), true)
		return
	_hero_face(ci, cx, foot, face, scale, pupil, false)
	if style == "tiara" or style == "long":
		_poly(ci, PackedVector2Array([
			_v(cx, foot, face, scale, -6.0, 122.0),
			_v(cx, foot, face, scale, -2.0, 134.0),
			_v(cx, foot, face, scale, 2.0, 122.0),
		]), trim, maxf(1.0, 1.3 * scale))
		_poly(ci, PackedVector2Array([
			_v(cx, foot, face, scale, 4.0, 122.0),
			_v(cx, foot, face, scale, 8.0, 136.0),
			_v(cx, foot, face, scale, 12.0, 122.0),
		]), trim, maxf(1.0, 1.3 * scale))
	if style == "long":
		var halo := _v(cx, foot, face, scale, 2.0, 132.0)
		_ring(ci, halo.x, halo.y, 18.0 * scale, 5.5 * scale, trim, maxf(1.2, 2.0 * scale))
	elif style == "kabuto":
		_ellipse(ci, hc.x, hc.y - 8.0 * scale, 14.0 * scale, 10.0 * scale, trim.darkened(0.15))
		_poly(ci, PackedVector2Array([
			_v(cx, foot, face, scale, -2.0, 124.0),
			_v(cx, foot, face, scale, 2.0, 148.0),
			_v(cx, foot, face, scale, 6.0, 124.0),
		]), trim, maxf(1.0, 1.4 * scale))
	elif style == "horns":
		_horn(ci, cx, foot, face, scale, -4.0, 118.0, 22.0, -2.0, trim.darkened(0.1))
		_horn(ci, cx, foot, face, scale, 8.0, 120.0, 26.0, 3.0, trim)
	elif style == "wolf":
		_horn(ci, cx, foot, face, scale, -8.0, 118.0, 18.0, -6.0, body.darkened(0.1))
		_horn(ci, cx, foot, face, scale, 4.0, 120.0, 16.0, 2.0, body)
		_poly(ci, PackedVector2Array([
			_v(cx, foot, face, scale, 12.0, 104.0),
			_v(cx, foot, face, scale, 26.0, 100.0),
			_v(cx, foot, face, scale, 14.0, 96.0),
		]), SKIN.darkened(0.08), maxf(1.0, 1.3 * scale))
	elif style == "clown":
		_disc(ci, _v(cx, foot, face, scale, 16.0, 100.0), 3.6 * scale, Color("#e21b1b"), false)
		_poly(ci, PackedVector2Array([
			_v(cx, foot, face, scale, 2.0, 124.0),
			_v(cx, foot, face, scale, 8.0, 152.0),
			_v(cx, foot, face, scale, 14.0, 124.0),
		]), trim, maxf(1.0, 1.4 * scale))
	elif style == "chef":
		_poly(ci, PackedVector2Array([
			_v(cx, foot, face, scale, -12.0, 122.0),
			_v(cx, foot, face, scale, 14.0, 122.0),
			_v(cx, foot, face, scale, 12.0, 156.0),
			_v(cx, foot, face, scale, -10.0, 156.0),
		]), Color("#f7f7f5"), maxf(1.0, 1.6 * scale))
		_poly(ci, PackedVector2Array([
			_v(cx, foot, face, scale, -13.0, 118.0),
			_v(cx, foot, face, scale, 15.0, 118.0),
			_v(cx, foot, face, scale, 15.0, 126.0),
			_v(cx, foot, face, scale, -13.0, 126.0),
		]), trim.darkened(0.2), maxf(1.0, 1.3 * scale))
	elif style == "cap":
		_ellipse(ci, hc.x, hc.y - 10.0 * scale, 14.0 * scale, 8.0 * scale, body.darkened(0.2))
		_poly(ci, PackedVector2Array([
			_v(cx, foot, face, scale, 4.0, 112.0),
			_v(cx, foot, face, scale, 28.0, 108.0),
			_v(cx, foot, face, scale, 26.0, 102.0),
			_v(cx, foot, face, scale, 2.0, 106.0),
		]), body.darkened(0.28), maxf(1.0, 1.4 * scale))
	elif style == "mask":
		_poly(ci, PackedVector2Array([
			_v(cx, foot, face, scale, -8.0, 112.0),
			_v(cx, foot, face, scale, 16.0, 110.0),
			_v(cx, foot, face, scale, 14.0, 100.0),
			_v(cx, foot, face, scale, -6.0, 102.0),
		]), Color(0.9, 0.9, 0.92, 0.85), maxf(1.0, 1.2 * scale))

static func _hair(ci: CanvasItem, cx: float, foot: float, face: float, scale: float) -> void:
	_poly(ci, PackedVector2Array([
		_v(cx, foot, face, scale, -8.0, 114.0),
		_v(cx, foot, face, scale, -22.0, 136.0),
		_v(cx, foot, face, scale, 0.0, 118.0),
	]), HAIR_D, maxf(1.0, 1.7 * scale))
	_poly(ci, PackedVector2Array([
		_v(cx, foot, face, scale, -4.0, 120.0),
		_v(cx, foot, face, scale, 4.0, 146.0),
		_v(cx, foot, face, scale, 12.0, 120.0),
	]), HAIR, maxf(1.0, 1.8 * scale))
	_poly(ci, PackedVector2Array([
		_v(cx, foot, face, scale, 6.0, 118.0),
		_v(cx, foot, face, scale, 18.0, 136.0),
		_v(cx, foot, face, scale, 16.0, 110.0),
	]), HAIR, maxf(1.0, 1.6 * scale))

static func _hero_face(ci: CanvasItem, cx: float, foot: float, face: float, scale: float, pupil: Color, hooded: bool) -> void:
	var ex := 12.0
	var ey := 104.0
	if hooded:
		ex = 13.0
		ey = 104.0
	var p := _v(cx, foot, face, scale, ex, ey)
	ci.draw_circle(p, 5.3 * scale, INK)
	ci.draw_circle(p, 4.1 * scale, Color(1, 0.98, 0.96))
	var d := Vector2(face * 1.2 * scale, 0.3 * scale)
	ci.draw_circle(p + d, 2.15 * scale, pupil)
	ci.draw_circle(p + d + Vector2(-0.7 * scale, -0.7 * scale), 0.75 * scale, Color(1, 1, 1, 0.95))
	if not hooded:
		ci.draw_line(_v(cx, foot, face, scale, 7.0, 112.0), _v(cx, foot, face, scale, 17.0, 109.0), Color(0.32, 0.16, 0.12), maxf(1.0, 2.0 * scale), true)
		ci.draw_line(_v(cx, foot, face, scale, 10.0, 96.0), _v(cx, foot, face, scale, 16.0, 95.0), Color(0.55, 0.26, 0.22), maxf(1.0, 1.6 * scale), true)

static func _arm_weapon(ci: CanvasItem, cx: float, foot: float, face: float, scale: float, body: Color, trim: Color, armor_id: String, attacking: bool, swing: float) -> void:
	var hand := _hand_local(swing, attacking)
	var elbow := Vector2(lerpf(14.0, hand.x, 0.48), lerpf(74.0, hand.y, 0.48) - 5.0)
	var arm_col := body
	if armor_id == "elementar":
		arm_col = Color("#1c6fd8")
	_bone(ci, _v(cx, foot, face, scale, 12.0, 74.0), _v(cx, foot, face, scale, elbow.x, elbow.y), 5.6 * scale, body.lightened(0.05))
	_bone(ci, _v(cx, foot, face, scale, elbow.x, elbow.y), _v(cx, foot, face, scale, hand.x, hand.y), 4.6 * scale, arm_col)
	var glove := trim
	if armor_id == "boss_shigaraki":
		glove = Color("#f4f1ea")
	_disc(ci, _v(cx, foot, face, scale, hand.x, hand.y), 5.5 * scale, glove)
	var kind := _weapon_kind(armor_id)
	if kind == "staff":
		_staff(ci, cx, foot, face, scale, hand, trim, armor_id, attacking, swing)
		return
	if kind == "cannon" or kind == "gun":
		_cannon(ci, cx, foot, face, scale, hand, body, trim, attacking, swing, kind == "gun")
		return
	if kind == "claws":
		_claws(ci, cx, foot, face, scale, hand, trim, attacking, swing)
		return
	if kind == "fist":
		_disc(ci, _v(cx, foot, face, scale, hand.x + 4.0, hand.y), 9.0 * scale, trim)
		_disc(ci, _v(cx, foot, face, scale, hand.x + 4.0, hand.y), 5.0 * scale, body.lightened(0.15), false)
		return
	if kind == "syringe":
		_syringe(ci, cx, foot, face, scale, hand, trim, attacking, swing)
		return
	if kind == "none":
		var hp := _v(cx, foot, face, scale, hand.x + 2.0, hand.y)
		ci.draw_arc(hp, 10.0 * scale, 0, TAU, 16, trim, maxf(1.2, 2.2 * scale), true)
		ci.draw_arc(hp, 5.0 * scale, 0, TAU, 12, Color(1, 1, 1, 0.8), maxf(1.0, 1.4 * scale), true)
		return
	var length := 52.0
	var width := 4.8
	var ang := 1.15
	if kind == "katana":
		length = 66.0
		width = 3.3
		ang = 1.28
	elif kind == "rapier":
		length = 60.0
		width = 2.3
		ang = 1.05
	elif kind == "kunai":
		length = 26.0
		width = 6.0
		ang = 0.25
	elif kind == "knife":
		length = 30.0
		width = 4.2
		ang = 0.2
	elif kind == "baton":
		length = 40.0
		width = 2.6
		ang = 0.9
	if attacking:
		var a0 := 2.45
		var a1 := 0.06
		if kind == "kunai" or kind == "knife":
			a0 = 1.3
			a1 = -0.05
		ang = lerpf(a0, a1, swing)
		if kind == "sword" or kind == "katana" or kind == "rapier" or kind == "kunai" or kind == "knife":
			_slash_trail(ci, cx, foot, face, scale, swing, length, trim, a0, a1)
	var blade := BLADE
	if kind == "baton":
		blade = Color("#f2f2f2")
	_blade(ci, cx, foot, face, scale, hand, ang, length, width, blade, trim)

static func _hand_local(swing: float, attacking: bool) -> Vector2:
	if not attacking:
		return Vector2(20.0, 66.0)
	return Vector2(lerpf(-4.0, 36.0, swing), lerpf(96.0, 50.0, swing))

static func _slash_trail(ci: CanvasItem, cx: float, foot: float, face: float, scale: float, swing: float, length: float, col: Color, a0: float, a1: float) -> void:
	var pts := PackedVector2Array()
	var n := 6
	for i in n:
		var t := clampf(swing - 0.42 + 0.42 * float(i) / float(n - 1), 0.0, 1.0)
		var hand := _hand_local(t, true)
		var ang := lerpf(a0, a1, t)
		var tip := hand + Vector2(cos(ang), sin(ang)) * length * 0.92
		pts.append(_v(cx, foot, face, scale, tip.x, tip.y))
	ci.draw_polyline(pts, Color(1, 0.97, 0.86, 0.32), maxf(2.0, 8.0 * scale), true)
	var ink := col
	ink.a = 0.9
	ci.draw_polyline(pts, ink, maxf(1.1, 2.4 * scale), true)

static func _blade(ci: CanvasItem, cx: float, foot: float, face: float, scale: float, hand: Vector2, ang: float, length: float, width: float, blade: Color, hilt: Color) -> void:
	var dir := Vector2(cos(ang), sin(ang))
	var nrm := Vector2(-dir.y, dir.x)
	var tip := hand + dir * length
	var b1 := hand + nrm * width
	var b2 := hand - nrm * width
	var t1 := tip + nrm * 0.6
	var t2 := tip - nrm * 0.6
	_poly(ci, PackedVector2Array([
		_v(cx, foot, face, scale, b1.x, b1.y),
		_v(cx, foot, face, scale, t1.x, t1.y),
		_v(cx, foot, face, scale, t2.x, t2.y),
		_v(cx, foot, face, scale, b2.x, b2.y),
	]), blade, maxf(1.0, 1.5 * scale))
	ci.draw_line(_v(cx, foot, face, scale, hand.x, hand.y), _v(cx, foot, face, scale, tip.x, tip.y), Color(1, 1, 1, 0.8), maxf(0.8, 1.3 * scale), true)
	var g1 := hand + nrm * (width + 6.0)
	var g2 := hand - nrm * (width + 6.0)
	ci.draw_line(_v(cx, foot, face, scale, g1.x, g1.y), _v(cx, foot, face, scale, g2.x, g2.y), hilt, maxf(1.6, 3.2 * scale), true)
	var pom := hand - dir * 8.0
	ci.draw_line(_v(cx, foot, face, scale, hand.x, hand.y), _v(cx, foot, face, scale, pom.x, pom.y), hilt.darkened(0.15), maxf(1.5, 3.4 * scale), true)
	_disc(ci, _v(cx, foot, face, scale, pom.x, pom.y), 3.3 * scale, hilt)

static func _staff(ci: CanvasItem, cx: float, foot: float, face: float, scale: float, hand: Vector2, trim: Color, armor_id: String, attacking: bool, swing: float) -> void:
	var ang := PI * 0.5
	if attacking:
		ang = lerpf(2.05, 0.2, swing)
	var dir := Vector2(cos(ang), sin(ang))
	var tip := hand + dir * 62.0
	var tail := hand - dir * 18.0
	_bone(ci, _v(cx, foot, face, scale, tail.x, tail.y), _v(cx, foot, face, scale, tip.x, tip.y), 3.1 * scale, Color("#6b3e22"))
	var orb := trim
	match armor_id:
		"mago_fogo", "elementar":
			orb = Color("#ff7722")
		"mago_gelo":
			orb = Color("#d8ffff")
		"mago_terra":
			orb = Color("#b6e04a")
		"mago_vento":
			orb = Color("#f4fff8")
	var tp := _v(cx, foot, face, scale, tip.x, tip.y)
	_disc(ci, tp, 8.2 * scale, orb)
	_disc(ci, tp, 3.6 * scale, Color(1, 1, 1, 0.88), false)

static func _cannon(ci: CanvasItem, cx: float, foot: float, face: float, scale: float, hand: Vector2, body: Color, trim: Color, attacking: bool, swing: float, small: bool) -> void:
	var ang := 0.1
	if attacking:
		ang = lerpf(0.5, 0.0, swing)
	var reach := 32.0
	var rad := 7.2
	if small:
		reach = 22.0
		rad = 4.2
	var dir := Vector2(cos(ang), sin(ang))
	var tip := hand + dir * reach
	_bone(ci, _v(cx, foot, face, scale, hand.x, hand.y), _v(cx, foot, face, scale, tip.x, tip.y), rad * scale, body.lightened(0.08))
	var tp := _v(cx, foot, face, scale, tip.x, tip.y)
	_disc(ci, tp, rad * 0.85 * scale, trim)
	_disc(ci, tp, rad * 0.4 * scale, Color(1, 1, 1, 0.9), false)

static func _claws(ci: CanvasItem, cx: float, foot: float, face: float, scale: float, hand: Vector2, trim: Color, attacking: bool, swing: float) -> void:
	for i in 3:
		var spread := -0.5 + float(i) * 0.48
		var ang := 0.05 + spread
		if attacking:
			ang = lerpf(0.85, -0.2, swing) + spread
		var dir := Vector2(cos(ang), sin(ang))
		var nrm := Vector2(-dir.y, dir.x)
		var tip := hand + dir * 16.0
		var b1 := hand + nrm * 1.8 + dir * 2.0
		var b2 := hand - nrm * 1.8 + dir * 2.0
		_tri(ci, cx, foot, face, scale, b1.x, b1.y, tip.x, tip.y, b2.x, b2.y, trim)

static func _syringe(ci: CanvasItem, cx: float, foot: float, face: float, scale: float, hand: Vector2, trim: Color, attacking: bool, swing: float) -> void:
	var ang := 0.15
	if attacking:
		ang = lerpf(0.8, 0.0, swing)
	var dir := Vector2(cos(ang), sin(ang))
	var tip := hand + dir * 34.0
	var tail := hand - dir * 8.0
	_bone(ci, _v(cx, foot, face, scale, tail.x, tail.y), _v(cx, foot, face, scale, tip.x, tip.y), 2.0 * scale, Color("#e8e8e8"))
	_disc(ci, _v(cx, foot, face, scale, tail.x, tail.y), 4.2 * scale, trim)
	_disc(ci, _v(cx, foot, face, scale, hand.x + dir.x * 12.0, hand.y + dir.y * 12.0), 2.4 * scale, trim.lightened(0.3), false)

static func _leg(ci: CanvasItem, cx: float, foot: float, face: float, scale: float, hipx: float, hipy: float, kx: float, ky: float, fx: float, fy: float, col: Color, trim: Color) -> void:
	_bone(ci, _v(cx, foot, face, scale, hipx, hipy), _v(cx, foot, face, scale, kx, ky), 6.3 * scale, col.darkened(0.1))
	_bone(ci, _v(cx, foot, face, scale, kx, ky), _v(cx, foot, face, scale, fx, fy), 5.4 * scale, col)
	_bone(ci, _v(cx, foot, face, scale, fx, fy), _v(cx, foot, face, scale, fx + 8.0, maxf(0.0, fy - 1.0)), 4.3 * scale, col.darkened(0.28))
	_disc(ci, _v(cx, foot, face, scale, fx, fy + 7.0), 3.3 * scale, trim)

static func _cape(ci: CanvasItem, cx: float, foot: float, face: float, scale: float, col: Color, mode: String, sway: float, airborne: bool, flying: bool) -> void:
	var tip_x := -58.0 + sway * 0.45
	var tip_y := 2.0
	var mid_x := -32.0
	var mid_y := 18.0
	if airborne:
		tip_y = 8.0
		mid_y = 24.0
	if flying:
		tip_x -= 12.0
		tip_y = 16.0
	if mode == "short":
		tip_x = -34.0 + sway * 0.2
		tip_y = maxf(tip_y, 34.0)
		mid_x = -22.0
		mid_y = 46.0
	if mode == "scarf":
		_tri(ci, cx, foot, face, scale, 2.0, 102.0, 14.0, 96.0, -10.0, 72.0, col)
		_tri(ci, cx, foot, face, scale, 2.0, 102.0, -10.0, 72.0, tip_x * 0.55, 58.0, col)
		return
	if mode == "jet":
		_tri(ci, cx, foot, face, scale, -2.0, 82.0, 4.0, 74.0, -18.0, 56.0, col.lightened(0.08))
		_tri(ci, cx, foot, face, scale, 4.0, 74.0, -6.0, 48.0, -18.0, 56.0, col)
		_disc(ci, _v(cx, foot, face, scale, -12.0, 52.0), 4.6 * scale, col.lightened(0.45), false)
		return
	_tri(ci, cx, foot, face, scale, 6.0, 88.0, -16.0, 94.0, -18.0, 44.0, col)
	_tri(ci, cx, foot, face, scale, -16.0, 94.0, -18.0, 44.0, mid_x, mid_y, col)
	_tri(ci, cx, foot, face, scale, -18.0, 44.0, mid_x, mid_y, tip_x, tip_y, col)
	_tri(ci, cx, foot, face, scale, -8.0, 60.0, mid_x + 6.0, mid_y + 6.0, tip_x + 14.0, tip_y + 18.0, col.darkened(0.16))
	ci.draw_line(_v(cx, foot, face, scale, -16.0, 94.0), _v(cx, foot, face, scale, tip_x, tip_y), Color(1, 1, 1, 0.28), maxf(1.2, 2.0 * scale), true)

static func _feathers(ci: CanvasItem, cx: float, foot: float, face: float, scale: float, col: Color, trim: Color, flap: float) -> void:
	var backs: Array[float] = [-20.0, -36.0, -50.0, -60.0]
	var tips: Array[float] = [122.0, 112.0, 96.0, 78.0]
	var bases: Array[float] = [80.0, 76.0, 70.0, 64.0]
	for i in 4:
		var lift := flap * (12.0 - float(i) * 2.0)
		_poly(ci, PackedVector2Array([
			_v(cx, foot, face, scale, -4.0, bases[i]),
			_v(cx, foot, face, scale, backs[i] * 0.55, (tips[i] + bases[i]) * 0.5 + 8.0 + lift * 0.4),
			_v(cx, foot, face, scale, backs[i], tips[i] + lift),
		]), col, maxf(1.0, 1.4 * scale))
	ci.draw_line(_v(cx, foot, face, scale, -4.0, 80.0), _v(cx, foot, face, scale, -20.0, 122.0 + flap * 12.0), trim, maxf(1.1, 2.2 * scale), true)

static func _bat_wing(ci: CanvasItem, cx: float, foot: float, face: float, scale: float, col: Color, trim: Color, flap: float, root_y: float, reach: float) -> void:
	var lift := flap * 16.0 * reach
	var root := Vector2(-6.0, root_y)
	var f1 := Vector2(-24.0 * reach, root_y + 30.0 + lift)
	var f2 := Vector2(-50.0 * reach, root_y + 12.0 + lift * 0.45)
	var f3 := Vector2(-62.0 * reach, root_y - 16.0 + lift * 0.1)
	_poly(ci, PackedVector2Array([
		_v(cx, foot, face, scale, root.x, root.y),
		_v(cx, foot, face, scale, f1.x, f1.y),
		_v(cx, foot, face, scale, f2.x, f2.y),
	]), col, maxf(1.0, 1.5 * scale))
	_poly(ci, PackedVector2Array([
		_v(cx, foot, face, scale, root.x, root.y),
		_v(cx, foot, face, scale, f2.x, f2.y),
		_v(cx, foot, face, scale, f3.x, f3.y),
	]), col.darkened(0.12), maxf(1.0, 1.5 * scale))
	_bone(ci, _v(cx, foot, face, scale, root.x, root.y), _v(cx, foot, face, scale, f1.x, f1.y), 1.8 * scale, trim)
	_bone(ci, _v(cx, foot, face, scale, root.x, root.y), _v(cx, foot, face, scale, f2.x, f2.y), 1.8 * scale, trim)
	_bone(ci, _v(cx, foot, face, scale, root.x, root.y), _v(cx, foot, face, scale, f3.x, f3.y), 1.7 * scale, trim)

static func _tail(ci: CanvasItem, cx: float, foot: float, face: float, scale: float, body: Color, trim: Color, sway: float) -> void:
	var a := _v(cx, foot, face, scale, -16.0, 42.0)
	var b := _v(cx, foot, face, scale, -34.0 + sway * 0.2, 24.0)
	var c := _v(cx, foot, face, scale, -26.0 + sway * 0.35, 8.0)
	_bone(ci, a, b, 5.2 * scale, body.darkened(0.12))
	_bone(ci, b, c, 3.6 * scale, trim.darkened(0.05))
	_poly(ci, PackedVector2Array([
		c + Vector2(-4.0 * face * scale, -2.0 * scale),
		c + Vector2(5.0 * face * scale, 3.0 * scale),
		c + Vector2(-2.0 * face * scale, 8.0 * scale),
	]), trim, maxf(1.0, 1.3 * scale))

static func _lock(ci: CanvasItem, cx: float, foot: float, face: float, scale: float, x0: float, y0: float, x1: float, y1: float, col: Color) -> void:
	_poly(ci, PackedVector2Array([
		_v(cx, foot, face, scale, x0, y0),
		_v(cx, foot, face, scale, x0 - 6.0, y0 - 6.0),
		_v(cx, foot, face, scale, x1, y1),
	]), col, maxf(1.0, 1.4 * scale))

static func _horn(ci: CanvasItem, cx: float, foot: float, face: float, scale: float, x: float, y: float, h: float, lean: float, col: Color) -> void:
	_poly(ci, PackedVector2Array([
		_v(cx, foot, face, scale, x - 3.5, y),
		_v(cx, foot, face, scale, x + 3.5, y + 1.0),
		_v(cx, foot, face, scale, x + lean, y + h),
	]), col, maxf(1.0, 1.5 * scale))

static func _beast(ci: CanvasItem, cx: float, foot: float, face: float, col: Color, time: float, phase: float, scale: float, horns: bool) -> float:
	_shadow(ci, cx, foot - 1.0, 22.0 * scale, 7.0 * scale, 0.42)
	var step := sin(time * 0.42 + phase)
	_bone(ci, _v(cx, foot, face, scale, -8.0, 30.0), _v(cx, foot, face, scale, -10.0 - step * 4.0, 14.0), 5.0 * scale, col.darkened(0.18))
	_bone(ci, _v(cx, foot, face, scale, -10.0 - step * 4.0, 14.0), _v(cx, foot, face, scale, -12.0 - step * 8.0, 0.0), 4.2 * scale, col.darkened(0.28))
	var body := _v(cx, foot, face, scale, 0.0, 40.0)
	_ellipse(ci, body.x, body.y, 20.0 * scale, 16.0 * scale, col)
	var belly := _v(cx, foot, face, scale, 3.0, 34.0)
	_ellipse(ci, belly.x, belly.y, 10.0 * scale, 9.0 * scale, col.lightened(0.22))
	_bone(ci, _v(cx, foot, face, scale, 8.0, 28.0), _v(cx, foot, face, scale, 10.0 + step * 4.0, 13.0), 5.2 * scale, col.darkened(0.12))
	_bone(ci, _v(cx, foot, face, scale, 10.0 + step * 4.0, 13.0), _v(cx, foot, face, scale, 14.0 + step * 8.0, 0.0), 4.4 * scale, col)
	_horn(ci, cx, foot, face, scale, -14.0, 46.0, 14.0, -6.0, col.darkened(0.25))
	_bone(ci, _v(cx, foot, face, scale, 12.0, 44.0), _v(cx, foot, face, scale, 24.0, 32.0), 3.6 * scale, col.darkened(0.08))
	_claws(ci, cx, foot, face, scale, Vector2(24.0, 32.0), Color("#e6d7c4"), false, 0.0)
	var head := _v(cx, foot, face, scale, 4.0, 66.0)
	_ellipse(ci, head.x, head.y, 15.0 * scale, 14.0 * scale, col.lightened(0.06))
	if horns:
		_horn(ci, cx, foot, face, scale, -8.0, 74.0, 16.0, -4.0, col.darkened(0.3))
		_horn(ci, cx, foot, face, scale, 2.0, 76.0, 18.0, 2.0, col.darkened(0.15))
	else:
		_horn(ci, cx, foot, face, scale, -10.0, 74.0, 14.0, -8.0, col.darkened(0.2))
		_horn(ci, cx, foot, face, scale, 0.0, 76.0, 12.0, -1.0, col)
	_eye_at(ci, _v(cx, foot, face, scale, 10.0, 68.0), 4.6 * scale, face, true)
	_eye_at(ci, _v(cx, foot, face, scale, 1.0, 70.0), 3.2 * scale, face, true)
	_poly(ci, PackedVector2Array([
		_v(cx, foot, face, scale, 8.0, 58.0),
		_v(cx, foot, face, scale, 18.0, 56.0),
		_v(cx, foot, face, scale, 12.0, 52.0),
	]), Color(0.12, 0.04, 0.05), maxf(1.0, 1.3 * scale))
	_poly(ci, PackedVector2Array([
		_v(cx, foot, face, scale, 12.0, 56.0),
		_v(cx, foot, face, scale, 15.0, 54.0),
		_v(cx, foot, face, scale, 13.0, 49.0),
	]), Color("#f4f1ea"), maxf(1.0, 1.1 * scale))
	return foot - 96.0 * scale

static func _flyer(ci: CanvasItem, cx: float, cy: float, face: float, col: Color, t: float) -> void:
	_shadow(ci, cx, cy + 20.0, 16.0, 5.0, 0.28)
	var flap := sin(t * 0.7)
	var span := 46.0
	_poly(ci, PackedVector2Array([
		Vector2(cx - 6, cy + 2),
		Vector2(cx - span, cy - 8 - flap * 16.0),
		Vector2(cx - span * 0.62, cy + 16.0 + flap * 5.0),
		Vector2(cx - 4, cy + 10),
	]), col.darkened(0.18), 1.7)
	_poly(ci, PackedVector2Array([
		Vector2(cx + 6, cy),
		Vector2(cx + span + 4.0, cy - 18.0 + flap * 14.0),
		Vector2(cx + span * 0.55, cy + 14.0 - flap * 4.0),
		Vector2(cx + 4, cy + 8),
	]), col.lightened(0.05), 1.7)
	var tail := Vector2(cx - face * 8.0, cy + 6.0)
	_poly(ci, PackedVector2Array([
		tail,
		tail + Vector2(-face * 16.0, 8.0),
		tail + Vector2(-face * 6.0, 14.0),
	]), col.darkened(0.12), 1.4)
	_ellipse(ci, cx, cy, 16.0, 12.0, col)
	_ellipse(ci, cx + face * 2.0, cy + 2.0, 8.0, 7.0, col.lightened(0.2))
	var head := Vector2(cx + face * 12.0, cy - 10.0)
	_ellipse(ci, head.x, head.y, 10.0, 9.0, col.lightened(0.08))
	_poly(ci, PackedVector2Array([
		head + Vector2(-4, -6),
		head + Vector2(-8, -16),
		head + Vector2(1, -8),
	]), col.darkened(0.2), 1.3)
	_poly(ci, PackedVector2Array([
		head + Vector2(2, -7),
		head + Vector2(6, -18),
		head + Vector2(8, -6),
	]), col.darkened(0.1), 1.3)
	_eye_at(ci, head + Vector2(face * 3.0, -1.0), 3.4, face, true)
	_poly(ci, PackedVector2Array([
		head + Vector2(face * 6.0, 3.0),
		head + Vector2(face * 12.0, 1.0),
		head + Vector2(face * 7.0, 6.0),
	]), Color(0.15, 0.05, 0.05), 1.2)
	_poly(ci, PackedVector2Array([
		head + Vector2(face * 8.0, 4.0),
		head + Vector2(face * 11.0, 3.0),
		head + Vector2(face * 9.0, 8.0),
	]), Color("#f6f3ec"), 1.0)

static func _brute(ci: CanvasItem, cx: float, foot: float, face: float, col: Color, time: float, phase: float) -> float:
	var scale := 1.12
	_shadow(ci, cx, foot - 2.0, 26.0, 7.0, 0.36)
	var step := sin(time * 0.36 + phase)
	_foe_legs(ci, cx, foot, face, scale, step, col)
	var body := _v(cx, foot, face, scale, 0.0, 62.0)
	_ellipse(ci, body.x, body.y, 26.0 * scale, 24.0 * scale, col)
	_ellipse(ci, _v(cx, foot, face, scale, 4.0, 54.0).x, _v(cx, foot, face, scale, 4.0, 54.0).y, 12.0 * scale, 12.0 * scale, col.lightened(0.16))
	_disc(ci, _v(cx, foot, face, scale, 20.0, 78.0), 11.0 * scale, col.lightened(0.08))
	_disc(ci, _v(cx, foot, face, scale, -18.0, 74.0), 9.0 * scale, col.darkened(0.12))
	var head := _v(cx, foot, face, scale, 2.0, 100.0)
	_ellipse(ci, head.x, head.y, 16.0 * scale, 16.0 * scale, col.lightened(0.05))
	_horn(ci, cx, foot, face, scale, -6.0, 112.0, 20.0, -2.0, col.darkened(0.25))
	_horn(ci, cx, foot, face, scale, 6.0, 114.0, 24.0, 3.0, trim_of(col))
	_eye_at(ci, _v(cx, foot, face, scale, 10.0, 102.0), 4.8 * scale, face, true)
	_eye_at(ci, _v(cx, foot, face, scale, 0.0, 104.0), 3.3 * scale, face, true)
	_fang_pair(ci, cx, foot, face, scale, 12.0, 90.0)
	var hand := _v(cx, foot, face, scale, 28.0, 70.0)
	var knob := _v(cx, foot, face, scale, 18.0, 108.0)
	_bone(ci, _v(cx, foot, face, scale, 16.0, 72.0), hand, 5.0 * scale, col.darkened(0.08))
	_bone(ci, hand, knob, 4.2 * scale, Color("#6a4324"))
	_disc(ci, knob, 8.0 * scale, Color("#5a381c"))
	return foot - 140.0 * scale

static func trim_of(col: Color) -> Color:
	return col.lightened(0.35)

static func _foe_legs(ci: CanvasItem, cx: float, foot: float, face: float, scale: float, step: float, col: Color) -> void:
	_bone(ci, _v(cx, foot, face, scale, -8.0, 40.0), _v(cx, foot, face, scale, -10.0 - step * 5.0, 18.0), 7.0 * scale, col.darkened(0.16))
	_bone(ci, _v(cx, foot, face, scale, -10.0 - step * 5.0, 18.0), _v(cx, foot, face, scale, -8.0 - step * 10.0, 0.0), 6.0 * scale, col.darkened(0.26))
	_bone(ci, _v(cx, foot, face, scale, 10.0, 38.0), _v(cx, foot, face, scale, 12.0 + step * 5.0, 18.0), 7.2 * scale, col.darkened(0.08))
	_bone(ci, _v(cx, foot, face, scale, 12.0 + step * 5.0, 18.0), _v(cx, foot, face, scale, 16.0 + step * 10.0, 0.0), 6.2 * scale, col)

static func _shigaraki(ci: CanvasItem, cx: float, foot: float, face: float, col: Color, time: float) -> float:
	var scale := 1.15
	var sway := sin(time * 0.12) * 5.0
	_shadow(ci, cx, foot - 2.0, 34.0 * scale, 8.0, 0.4)
	_poly(ci, PackedVector2Array([
		_v(cx, foot, face, scale, -32.0 + sway * 0.2, 2.0),
		_v(cx, foot, face, scale, 26.0, 0.0),
		_v(cx, foot, face, scale, 14.0, 112.0),
		_v(cx, foot, face, scale, -16.0, 118.0),
	]), col, 2.2)
	_poly(ci, PackedVector2Array([
		_v(cx, foot, face, scale, -16.0, 112.0),
		_v(cx, foot, face, scale, 12.0, 108.0),
		_v(cx, foot, face, scale, -2.0, 156.0),
	]), col.lightened(0.04), 2.0)
	var face_c := _v(cx, foot, face, scale, 0.0, 118.0)
	_ellipse(ci, face_c.x, face_c.y, 14.0 * scale, 16.0 * scale, Color("#f3f0ea"))
	_eye_red(ci, _v(cx, foot, face, scale, 6.0, 122.0), 3.6 * scale)
	_eye_red(ci, _v(cx, foot, face, scale, -4.0, 124.0), 2.8 * scale)
	var palm := _v(cx, foot, face, scale, 10.0, 108.0)
	_ellipse(ci, palm.x, palm.y, 12.0 * scale, 14.0 * scale, Color("#f7f4ef"))
	for i in 4:
		var fx := 10.0 - 9.0 + float(i) * 6.0
		_bone(ci, _v(cx, foot, face, scale, fx, 116.0), _v(cx, foot, face, scale, fx + sway * 0.05, 136.0), 2.6 * scale, Color("#f7f4ef"))
	return foot - 160.0 * scale

static func _afo(ci: CanvasItem, cx: float, foot: float, face: float, col: Color, time: float, phase: float) -> float:
	var scale := 1.48
	_humanoid(ci, cx, foot, face, col, "afo", scale, sin(time * 0.3 + phase), time)
	return foot - 150.0 * scale

static func _phase_boss(ci: CanvasItem, cx: float, foot: float, face: float, col: Color, name: String, time: float, phase: float) -> float:
	var n := name.to_upper()
	var style := _boss_style(n)
	var scale := 1.12
	if "FINAL" in n or "SUPREMO" in n or "ESP" in n:
		scale = 1.38
	var step := sin(time * 0.32 + phase)
	if style == "dragon":
		return _dragon(ci, cx, foot, face, col, scale, time, "DEM" in n)
	if style == "spirit":
		return _spirit(ci, cx, foot, face, col, scale, time)
	_humanoid(ci, cx, foot, face, col, style, scale, step, time)
	return foot - 148.0 * scale

static func _boss_style(n: String) -> String:
	if "ESP" in n:
		return "spirit"
	if "DRAG" in n or "DEM" in n:
		return "dragon"
	if "LOBO" in n:
		return "wolf"
	if "TUBAR" in n:
		return "shark"
	if "PALHA" in n:
		return "clown"
	if "CHEF" in n:
		return "chef"
	if "GLITCH" in n:
		return "glitch"
	if "PILOTO" in n:
		return "pilot"
	if "MAESTRO" in n:
		return "maestro"
	if "COMISS" in n or "HOOL" in n:
		return "brute"
	if "DOUTOR" in n or "NEURO" in n:
		return "doctor"
	return "human"

static func _dragon(ci: CanvasItem, cx: float, foot: float, face: float, col: Color, scale: float, time: float, fiery: bool) -> float:
	var flap := sin(time * 0.28)
	_shadow(ci, cx, foot - 2.0, 36.0 * scale, 8.0 * scale, 0.38)
	_tail(ci, cx, foot, face, scale * 1.15, col, col.lightened(0.25), sin(time * 0.2) * 8.0)
	_bat_wing(ci, cx, foot, face, scale, col.darkened(0.2), col.lightened(0.3), flap, 70.0, 1.25)
	_foe_legs(ci, cx, foot, face, scale * 1.05, sin(time * 0.35), col)
	var body := _v(cx, foot, face, scale, 4.0, 58.0)
	_ellipse(ci, body.x, body.y, 34.0 * scale, 26.0 * scale, col)
	_ellipse(ci, _v(cx, foot, face, scale, 8.0, 50.0).x, _v(cx, foot, face, scale, 8.0, 50.0).y, 14.0 * scale, 12.0 * scale, col.lightened(0.18))
	var head := _v(cx, foot, face, scale, 22.0, 96.0)
	_ellipse(ci, head.x, head.y, 18.0 * scale, 16.0 * scale, col.lightened(0.06))
	_poly(ci, PackedVector2Array([
		_v(cx, foot, face, scale, 30.0, 96.0),
		_v(cx, foot, face, scale, 52.0, 90.0),
		_v(cx, foot, face, scale, 48.0, 80.0),
		_v(cx, foot, face, scale, 26.0, 84.0),
	]), col, maxf(1.2, 1.8 * scale))
	_horn(ci, cx, foot, face, scale, 14.0, 108.0, 26.0, -4.0, col.darkened(0.25))
	_horn(ci, cx, foot, face, scale, 24.0, 110.0, 30.0, 4.0, col.lightened(0.15))
	_eye_at(ci, _v(cx, foot, face, scale, 30.0, 100.0), 4.2 * scale, face, true)
	_fang_pair(ci, cx, foot, face, scale, 40.0, 86.0)
	if fiery:
		_disc(ci, _v(cx, foot, face, scale, 50.0, 88.0), 6.0 * scale, Color("#ff9a22"), false)
		_disc(ci, _v(cx, foot, face, scale, 44.0, 96.0), 3.5 * scale, Color(1, 0.85, 0.4, 0.85), false)
	_claws(ci, cx, foot, face, scale, Vector2(24.0, 40.0), Color("#e6d7c4"), false, 0.0)
	return foot - 146.0 * scale

static func _spirit(ci: CanvasItem, cx: float, foot: float, face: float, col: Color, scale: float, time: float) -> float:
	var sway := sin(time * 0.16) * 8.0
	_shadow(ci, cx, foot - 2.0, 40.0 * scale, 8.0, 0.32)
	var aura := col.lightened(0.35)
	aura.a = 0.18
	_ellipse(ci, cx, foot - 80.0 * scale, 48.0 * scale, 70.0 * scale, aura, false)
	_tri(ci, cx, foot, face, scale, -38.0 + sway * 0.2, 4.0, 34.0, 2.0, 0.0, 150.0, col)
	_tri(ci, cx, foot, face, scale, -38.0 + sway * 0.2, 4.0, -8.0, 16.0, 0.0, 150.0, col.darkened(0.12))
	_tri(ci, cx, foot, face, scale, 10.0, 6.0, 36.0, 0.0, 0.0, 150.0, col.lightened(0.06))
	var face_c := _v(cx, foot, face, scale, 0.0, 132.0)
	_ellipse(ci, face_c.x, face_c.y, 16.0 * scale, 18.0 * scale, Color("#e7eeff"))
	_eye_at(ci, _v(cx, foot, face, scale, 6.0, 136.0), 4.0 * scale, face, true)
	_eye_at(ci, _v(cx, foot, face, scale, -5.0, 138.0), 3.0 * scale, face, true)
	_ring(ci, face_c.x, face_c.y - 28.0 * scale, 20.0 * scale, 6.0 * scale, col.lightened(0.4), 2.0)
	_bone(ci, _v(cx, foot, face, scale, -8.0, 100.0), _v(cx, foot, face, scale, -28.0, 132.0 + sway), 4.0 * scale, col.lightened(0.1))
	_bone(ci, _v(cx, foot, face, scale, 10.0, 96.0), _v(cx, foot, face, scale, 32.0, 128.0 - sway), 4.0 * scale, col.lightened(0.1))
	return foot - 176.0 * scale

static func _humanoid(ci: CanvasItem, cx: float, foot: float, face: float, col: Color, style: String, scale: float, step: float, time: float) -> void:
	_shadow(ci, cx, foot - 2.0, 22.0 * scale, 6.5 * scale, 0.34)
	var cape := col.darkened(0.35)
	if cape.get_luminance() < 0.08:
		cape = col.lightened(0.25)
	var sway := sin(time * 0.15) * 6.0
	_cape(ci, cx, foot, face, scale, cape, "long", sway, false, false)
	_foe_legs(ci, cx, foot, face, scale, step, col)
	var body := _v(cx, foot, face, scale, 0.0, 72.0)
	_ellipse(ci, body.x, body.y, 20.0 * scale, 26.0 * scale, col)
	if style == "doctor":
		_ellipse(ci, body.x, body.y, 16.0 * scale, 24.0 * scale, Color("#f4f7f6"))
		_poly(ci, PackedVector2Array([
			_v(cx, foot, face, scale, -4.0, 92.0),
			_v(cx, foot, face, scale, 4.0, 92.0),
			_v(cx, foot, face, scale, 2.0, 48.0),
			_v(cx, foot, face, scale, -2.0, 48.0),
		]), col, 1.4)
	elif style == "chef":
		_ellipse(ci, _v(cx, foot, face, scale, 4.0, 64.0).x, _v(cx, foot, face, scale, 4.0, 64.0).y, 14.0 * scale, 16.0 * scale, Color("#f7f7f5"))
	elif style == "shark":
		_ellipse(ci, _v(cx, foot, face, scale, 4.0, 66.0).x, _v(cx, foot, face, scale, 4.0, 66.0).y, 12.0 * scale, 16.0 * scale, col.lightened(0.28))
		_poly(ci, PackedVector2Array([
			_v(cx, foot, face, scale, -8.0, 90.0),
			_v(cx, foot, face, scale, -30.0, 132.0),
			_v(cx, foot, face, scale, -2.0, 104.0),
		]), col.darkened(0.1), 1.7)
	if style == "brute" or style == "afo":
		_disc(ci, _v(cx, foot, face, scale, 18.0, 90.0), 10.0 * scale, col.lightened(0.08))
		_disc(ci, _v(cx, foot, face, scale, -16.0, 86.0), 8.5 * scale, col.darkened(0.1))
	var skin := SKIN
	if style == "wolf" or style == "shark":
		skin = col.lightened(0.1)
	elif style == "clown":
		skin = Color("#f6f3ee")
	elif style == "glitch":
		skin = col.lightened(0.25)
	var head := _v(cx, foot, face, scale, 2.0, 114.0)
	_ellipse(ci, head.x, head.y, 15.0 * scale, 16.0 * scale, skin)
	if style == "wolf":
		_horn(ci, cx, foot, face, scale, -8.0, 124.0, 18.0, -8.0, col.darkened(0.15))
		_horn(ci, cx, foot, face, scale, 2.0, 126.0, 16.0, 0.0, col)
		_poly(ci, PackedVector2Array([
			_v(cx, foot, face, scale, 10.0, 112.0),
			_v(cx, foot, face, scale, 28.0, 108.0),
			_v(cx, foot, face, scale, 12.0, 104.0),
		]), skin.darkened(0.08), 1.4)
		_tail(ci, cx, foot, face, scale, col, col.lightened(0.2), sway)
	elif style == "clown":
		_ellipse(ci, _v(cx, foot, face, scale, 0.0, 96.0).x, _v(cx, foot, face, scale, 0.0, 96.0).y, 18.0 * scale, 7.0 * scale, col.lightened(0.2))
		_disc(ci, _v(cx, foot, face, scale, 14.0, 110.0), 3.8 * scale, Color("#e01818"), false)
		_poly(ci, PackedVector2Array([
			_v(cx, foot, face, scale, 0.0, 128.0),
			_v(cx, foot, face, scale, 8.0, 160.0),
			_v(cx, foot, face, scale, 16.0, 128.0),
		]), col, 1.5)
	elif style == "chef":
		_poly(ci, PackedVector2Array([
			_v(cx, foot, face, scale, -12.0, 126.0),
			_v(cx, foot, face, scale, 14.0, 126.0),
			_v(cx, foot, face, scale, 11.0, 162.0),
			_v(cx, foot, face, scale, -9.0, 162.0),
		]), Color("#f7f7f5"), 1.6)
	elif style == "pilot":
		_ellipse(ci, head.x, head.y - 2.0 * scale, 16.0 * scale, 17.0 * scale, col.darkened(0.1))
		_ellipse(ci, _v(cx, foot, face, scale, 8.0, 114.0).x, _v(cx, foot, face, scale, 8.0, 114.0).y, 10.0 * scale, 4.0 * scale, Color("#9ff6ff"))
	elif style == "doctor":
		_ellipse(ci, _v(cx, foot, face, scale, 6.0, 112.0).x, _v(cx, foot, face, scale, 6.0, 112.0).y, 9.0 * scale, 5.0 * scale, Color("#e8e8e8"))
	elif style == "maestro":
		_poly(ci, PackedVector2Array([
			_v(cx, foot, face, scale, -14.0, 104.0),
			_v(cx, foot, face, scale, 8.0, 100.0),
			_v(cx, foot, face, scale, 4.0, 92.0),
			_v(cx, foot, face, scale, -16.0, 96.0),
		]), Color("#1a1a1a"), 1.3)
		_disc(ci, _v(cx, foot, face, scale, 0.0, 96.0), 4.0 * scale, col.lightened(0.3))
	elif style == "glitch":
		ci.draw_rect(Rect2(head.x + 8.0, head.y - 8.0, 16.0, 5.0), Color(0, 1, 1, 0.55))
		ci.draw_rect(Rect2(head.x - 14.0, head.y + 6.0, 12.0, 4.0), Color(1, 0, 1, 0.5))
	elif style == "human":
		_ellipse(ci, head.x, head.y - 12.0 * scale, 16.0 * scale, 4.0 * scale, col.darkened(0.25))
	_eye_at(ci, _v(cx, foot, face, scale, 10.0, 116.0), 4.2 * scale, face, true)
	if style != "pilot" and style != "doctor":
		_eye_at(ci, _v(cx, foot, face, scale, 1.0, 118.0), 2.8 * scale, face, true)
	_foe_tool(ci, cx, foot, face, scale, style, col)

static func _foe_tool(ci: CanvasItem, cx: float, foot: float, face: float, scale: float, style: String, col: Color) -> void:
	var hand := _v(cx, foot, face, scale, 22.0, 70.0)
	_bone(ci, _v(cx, foot, face, scale, 12.0, 80.0), hand, 4.4 * scale, col.lightened(0.05))
	if style == "brute" or style == "afo":
		var knob := _v(cx, foot, face, scale, 16.0, 112.0)
		_bone(ci, hand, knob, 4.0 * scale, Color("#6b4426"))
		_disc(ci, knob, 8.0 * scale, Color("#54361a"))
	elif style == "doctor":
		var tip := _v(cx, foot, face, scale, 40.0, 86.0)
		_bone(ci, hand, tip, 1.8 * scale, Color("#f2f2f2"))
		_disc(ci, hand, 4.0 * scale, Color("#39d18a"))
	elif style == "chef":
		var tip2 := _v(cx, foot, face, scale, 42.0, 78.0)
		_bone(ci, hand, tip2, 2.2 * scale, Color("#e6e6e6"))
	elif style == "pilot":
		var muz := _v(cx, foot, face, scale, 44.0, 74.0)
		_bone(ci, hand, muz, 4.5 * scale, col.lightened(0.1))
		_disc(ci, muz, 4.0 * scale, Color("#7af6ff"), false)
	elif style == "maestro":
		var tip3 := _v(cx, foot, face, scale, 18.0, 108.0)
		_bone(ci, hand, tip3, 1.8 * scale, Color("#f4f4f4"))
	elif style == "wolf" or style == "shark":
		_claws(ci, cx, foot, face, scale, Vector2(22.0, 70.0), Color("#e6d7c4"), false, 0.0)
	elif style == "clown":
		_disc(ci, _v(cx, foot, face, scale, 30.0, 78.0), 7.0 * scale, Color("#222222"))
		_disc(ci, _v(cx, foot, face, scale, 30.0, 78.0), 3.0 * scale, Color("#ffcc33"), false)
	else:
		var tip4 := _v(cx, foot, face, scale, 40.0, 108.0)
		_bone(ci, hand, tip4, 2.6 * scale, BLADE)

static func _fang_pair(ci: CanvasItem, cx: float, foot: float, face: float, scale: float, x: float, y: float) -> void:
	_poly(ci, PackedVector2Array([
		_v(cx, foot, face, scale, x, y),
		_v(cx, foot, face, scale, x + 4.0, y - 1.0),
		_v(cx, foot, face, scale, x + 2.0, y - 8.0),
	]), Color("#f4f1ea"), 1.2)
	_poly(ci, PackedVector2Array([
		_v(cx, foot, face, scale, x + 5.0, y - 1.0),
		_v(cx, foot, face, scale, x + 9.0, y - 2.0),
		_v(cx, foot, face, scale, x + 7.0, y - 7.0),
	]), Color("#f4f1ea"), 1.1)

static func _eye_red(ci: CanvasItem, p: Vector2, r: float) -> void:
	ci.draw_circle(p, r + 1.2, INK)
	ci.draw_circle(p, r, Color("#ff2a3a"))
	ci.draw_circle(p, r * 0.4, Color(1, 0.9, 0.85))

static func _eye_at(ci: CanvasItem, p: Vector2, r: float, face: float, angry: bool) -> void:
	ci.draw_circle(p, r + 1.15, INK)
	ci.draw_circle(p, r, Color(1, 0.97, 0.92))
	var pupil := p + Vector2(face * r * 0.28, r * 0.08)
	ci.draw_circle(pupil, r * 0.48, Color(0.08, 0.05, 0.06))
	ci.draw_circle(pupil + Vector2(-r * 0.16, -r * 0.16), r * 0.16, Color(1, 1, 1, 0.95))
	if angry:
		ci.draw_line(p + Vector2(-r * 0.9, -r * 0.7), p + Vector2(r * 0.95, -r * 0.2), INK, maxf(1.2, r * 0.38), true)

static func _plate(ci: CanvasItem, cx: float, top: float, bar_w: float, ratio: float, name: String) -> void:
	var y := top - 10.0
	var x := cx - bar_w * 0.5
	ci.draw_rect(Rect2(x - 2, y - 2, bar_w + 4, 9), Color(0, 0, 0, 0.8))
	ci.draw_rect(Rect2(x, y, bar_w, 5), Color(0.32, 0.07, 0.08))
	var fill_w := bar_w * clampf(ratio, 0.0, 1.0)
	ci.draw_rect(Rect2(x, y, fill_w, 5), Color("#ff3b4e"))
	ci.draw_rect(Rect2(x, y, fill_w, 2), Color(1, 1, 1, 0.38))
	if name == "":
		return
	var font := ThemeDB.fallback_font
	var sz: Vector2 = font.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, 13)
	var tx := cx - sz.x * 0.5
	ci.draw_rect(Rect2(tx - 5, y - 20, sz.x + 10, 16), Color(0, 0, 0, 0.62))
	ci.draw_string(font, Vector2(tx + 1, y - 6), name, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0, 0, 0, 0.85))
	ci.draw_string(font, Vector2(tx, y - 7), name, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#ffe566"))

static func _flame(ci: CanvasItem, c: Vector2, ang: float, length: float, thick: float, col: Color, core: Color) -> void:
	var dir := Vector2(cos(ang), sin(ang))
	var nrm := Vector2(-dir.y, dir.x)
	var tip := c + dir * length
	var back := c - dir * length * 0.45
	ci.draw_circle(back, thick + 1.8, INK)
	ci.draw_circle(back, thick, col)
	_poly(ci, PackedVector2Array([tip, back + nrm * thick * 0.85, back - nrm * thick * 0.85]), col, 1.6)
	ci.draw_circle(back, thick * 0.42, core)

static func _gem_shot(ci: CanvasItem, c: Vector2, ang: float, length: float, thick: float, col: Color) -> void:
	var dir := Vector2(cos(ang), sin(ang))
	var nrm := Vector2(-dir.y, dir.x)
	_poly(ci, PackedVector2Array([
		c + dir * length,
		c + nrm * thick,
		c - dir * length * 0.8,
		c - nrm * thick,
	]), col, 1.8)
	ci.draw_circle(c, thick * 0.28, Color(1, 1, 1, 0.75))

static func _beam(ci: CanvasItem, c: Vector2, ang: float, length: float, thick: float, col: Color) -> void:
	var dir := Vector2(cos(ang), sin(ang))
	var a := c - dir * length
	var b := c + dir * length
	_bone(ci, a, b, thick + 1.6, INK)
	_bone(ci, a, b, thick, col)
	_disc(ci, b, thick * 0.7, Color(1, 1, 1, 0.85), false)

static func _bolt(ci: CanvasItem, c: Vector2, ang: float, length: float, thick: float, col: Color) -> void:
	var dir := Vector2(cos(ang), sin(ang))
	var nrm := Vector2(-dir.y, dir.x)
	var tip := c + dir * length
	var tail := c - dir * length * 0.7
	_poly(ci, PackedVector2Array([tip, tail + nrm * thick, tail - nrm * thick]), col, 1.6)

static func _shuriken(ci: CanvasItem, c: Vector2, r: float, spin: float, col: Color) -> void:
	for i in 4:
		var a := spin + float(i) * TAU / 4.0
		var dir := Vector2(cos(a), sin(a))
		var nrm := Vector2(-dir.y, dir.x)
		_poly(ci, PackedVector2Array([
			c + nrm * r * 0.22,
			c + dir * r,
			c - nrm * r * 0.22,
		]), col, 1.3)
	ci.draw_circle(c, r * 0.28 + 1.3, INK)
	ci.draw_circle(c, r * 0.24, Color("#f4f6f8"))

static func _tornado(ci: CanvasItem, c: Vector2, length: float, thick: float, col: Color, time: float) -> void:
	var h := maxf(length, thick * 2.0)
	for i in 3:
		var ry := h * (0.35 + float(i) * 0.22)
		var rx := thick * (0.7 + float(i) * 0.45)
		var shift := sin(time * 0.2 + float(i)) * 3.0
		_ring(ci, c.x + shift, c.y + (float(i) - 1.0) * h * 0.28, rx, ry * 0.45, col, 2.0)

static func _note(ci: CanvasItem, c: Vector2, r: float, col: Color) -> void:
	ci.draw_circle(c + Vector2(-r * 0.2, r * 0.35), r * 0.55 + 1.4, INK)
	ci.draw_circle(c + Vector2(-r * 0.2, r * 0.35), r * 0.55, col)
	ci.draw_line(c + Vector2(r * 0.35, r * 0.2), c + Vector2(r * 0.35, -r * 1.5), INK, 2.4, true)
	ci.draw_line(c + Vector2(r * 0.35, r * 0.2), c + Vector2(r * 0.35, -r * 1.5), col, 1.4, true)
	ci.draw_line(c + Vector2(r * 0.35, -r * 1.5), c + Vector2(r * 1.1, -r * 1.15), col, 1.6, true)

static func _orb(ci: CanvasItem, c: Vector2, r: float, col: Color) -> void:
	var glow := col
	glow.a = 0.22
	ci.draw_circle(c, r * 1.4, glow)
	ci.draw_circle(c, r + 1.6, _ink_of(col))
	ci.draw_circle(c, r, col)
	ci.draw_circle(c + Vector2(-r * 0.25, -r * 0.25), r * 0.28, Color(1, 1, 1, 0.75))

static func _ring(ci: CanvasItem, cx: float, cy: float, rx: float, ry: float, col: Color, width: float) -> void:
	var pts := PackedVector2Array()
	var segs := 14
	for i in segs:
		var a := TAU * float(i) / float(segs)
		pts.append(Vector2(cx + cos(a) * rx, cy + sin(a) * ry))
	pts.append(pts[0])
	ci.draw_polyline(pts, col, width, true)

static func _shadow(ci: CanvasItem, cx: float, foot: float, rx: float, ry: float, alpha: float) -> void:
	_ellipse_raw(ci, cx, foot, rx, ry, Color(0, 0, 0, alpha))

static func _bone(ci: CanvasItem, a: Vector2, b: Vector2, radius: float, col: Color) -> void:
	if radius <= 0.2:
		return
	var pad := clampf(radius * 0.2, 0.7, 2.0)
	if col.a < 0.6:
		_capsule(ci, a, b, radius, col)
		return
	_capsule(ci, a, b, radius + pad, _ink_of(col))
	_capsule(ci, a, b, radius, col)

static func _capsule(ci: CanvasItem, a: Vector2, b: Vector2, radius: float, col: Color) -> void:
	var d := b - a
	var len := d.length()
	if len < 0.4:
		ci.draw_circle(a, radius, col)
		return
	var n := Vector2(-d.y, d.x) / len * radius
	ci.draw_colored_polygon(_ordered(PackedVector2Array([a + n, b + n, b - n, a - n])), col)
	ci.draw_circle(a, radius, col)
	ci.draw_circle(b, radius, col)

static func _disc(ci: CanvasItem, c: Vector2, r: float, col: Color, inked: bool = true) -> void:
	if r <= 0.2:
		return
	if inked and col.a >= 0.6:
		ci.draw_circle(c, r + clampf(r * 0.16, 0.6, 1.8), _ink_of(col))
	ci.draw_circle(c, r, col)

static func _ellipse(ci: CanvasItem, cx: float, cy: float, rx: float, ry: float, col: Color, inked: bool = true) -> void:
	if rx <= 0.3 or ry <= 0.3:
		return
	if inked and col.a >= 0.6:
		_ellipse_raw(ci, cx, cy, rx + 1.6, ry + 1.6, _ink_of(col))
	_ellipse_raw(ci, cx, cy, rx, ry, col)

static func _ellipse_raw(ci: CanvasItem, cx: float, cy: float, rx: float, ry: float, col: Color) -> void:
	if rx <= 0.3 or ry <= 0.3:
		return
	var pts := PackedVector2Array()
	var segs := 12
	for i in segs:
		var a := TAU * float(i) / float(segs)
		pts.append(Vector2(cx + cos(a) * rx, cy + sin(a) * ry))
	ci.draw_colored_polygon(_ordered(pts), col)

static func _tri(ci: CanvasItem, cx: float, foot: float, face: float, scale: float, x0: float, y0: float, x1: float, y1: float, x2: float, y2: float, col: Color) -> void:
	var a := _v(cx, foot, face, scale, x0, y0)
	var b := _v(cx, foot, face, scale, x1, y1)
	var c := _v(cx, foot, face, scale, x2, y2)
	var area := a.x * (b.y - c.y) + b.x * (c.y - a.y) + c.x * (a.y - b.y)
	if absf(area) < 0.8:
		return
	_poly(ci, PackedVector2Array([a, b, c]), col, maxf(1.0, 1.7 * scale))

static func _poly(ci: CanvasItem, pts: PackedVector2Array, col: Color, width: float = 2.0) -> void:
	if pts.size() < 3:
		return
	var use := _ordered(pts)
	ci.draw_colored_polygon(use, col)
	if col.a < 0.6:
		return
	var loop: PackedVector2Array = use.duplicate()
	loop.append(use[0])
	ci.draw_polyline(loop, _ink_of(col), width, true)

static func _ink_of(col: Color) -> Color:
	if col.get_luminance() < 0.12:
		return PAPER
	return INK

static func _ordered(pts: PackedVector2Array) -> PackedVector2Array:
	var area := 0.0
	var n := pts.size()
	for i in n:
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[(i + 1) % n]
		area += a.x * b.y - b.x * a.y
	if area >= 0.0:
		return pts
	var rev := PackedVector2Array()
	for i in range(n - 1, -1, -1):
		rev.append(pts[i])
	return rev

static func _v(cx: float, foot: float, face: float, scale: float, lx: float, ly: float) -> Vector2:
	return Vector2(cx + lx * face * scale, foot - ly * scale)
