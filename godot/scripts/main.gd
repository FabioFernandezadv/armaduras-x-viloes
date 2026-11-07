extends Node2D

const Cat = preload("res://scripts/catalog.gd")
const WorldScript = preload("res://scripts/world.gd")

enum St { MENU, STORY, CUT, SHOP, PLAY, PAUSE, BOSS, TRAVEL, OVER, WIN }

var st := St.MENU
var world: WorldScript
var font: Font
var music: AudioStreamPlayer
var music_file := ""
var muted := false
var vol := 0.36
var tempo := 0.0
var down := {}
var just := {}
var released_jump := false

var slide := 0
var chars := 0
var char_acc := 0.0
var fade := 0.0
var cut_i := 0
var cut_acc := 0.0
var shop_i := 0
var shop_scroll := 0.0
var shop_msg := ""
var shop_msg_t := 0.0
var boss_t := 0.0
var travel_t := 0.0
var travel_from := 0
var travel_to := 0
var win_t := 0.0
var win_applied := false
var heart_msg := ""
var won_new := false

var villain: Texture2D
var hero_tex: Texture2D
var menu_bg: Texture2D
var light: ColorRect
var light_mat: ShaderMaterial

var demo := false
var shot := ""
var frames := 0
var _shot_started := false

func _ready() -> void:
	font = SystemFont.new()
	font.font_names = PackedStringArray(["DejaVu Sans Mono", "Liberation Mono", "Courier New"])
	font.font_weight = 700
	world = WorldScript.new()
	world.name = "World"
	world.visible = false
	add_child(world)
	var light_layer := CanvasLayer.new()
	light_layer.layer = 1
	add_child(light_layer)
	light = ColorRect.new()
	light.set_anchors_preset(Control.PRESET_FULL_RECT)
	light.mouse_filter = Control.MOUSE_FILTER_IGNORE
	light.color = Color(1, 1, 1, 1)
	light_mat = ShaderMaterial.new()
	light_mat.shader = load("res://shaders/light.gdshader")
	light.material = light_mat
	light.visible = false
	light_layer.add_child(light)
	var hud_layer := CanvasLayer.new()
	hud_layer.layer = 2
	add_child(hud_layer)
	var hud := Hud.new()
	hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud_layer.add_child(hud)
	music = AudioStreamPlayer.new()
	add_child(music)
	menu_bg = _load_tex("menu-bg.png")
	villain = _load_tex("retrato-vilao.png")
	hero_tex = _load_tex("retrato-heroi.png")
	for arg in OS.get_cmdline_user_args():
		if arg == "--demo":
			demo = true
		elif arg.begins_with("--shot="):
			shot = arg.trim_prefix("--shot=")
	if demo:
		_begin_play()

func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventKey and not ev.echo:
		var key_ev := ev as InputEventKey
		var key := key_ev.keycode
		if ev.pressed:
			if not down.get(key, false):
				just[key] = true
			down[key] = true
		else:
			down[key] = false
			if key == KEY_SPACE or key == KEY_W or key == KEY_UP:
				released_jump = true
		if ev.pressed and not ev.echo and key == KEY_F:
			var mode := DisplayServer.window_get_mode()
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if mode == DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_FULLSCREEN)
		if ev.pressed and not ev.echo and key == KEY_M:
			muted = not muted
			if muted:
				music.stop()
				music_file = ""
			else:
				_sync_music(true)

func _process(delta: float) -> void:
	var dtf := minf(delta * 60.0, 3.0)
	if st == St.PLAY and world.slowmo > 0.0:
		world.slowmo -= dtf
		dtf *= 0.22
	tempo += dtf
	frames += 1
	if released_jump and st == St.PLAY:
		world.cut_jump()
	match st:
		St.MENU:
			_sync_music(false)
			if _accept():
				if SaveData.has_save:
					SaveData.read()
					_prepare(SaveData.phase)
				else:
					_start_story()
			elif _hit(KEY_N) and SaveData.has_save:
				SaveData.wipe()
				_start_story()
		St.STORY:
			_sync_music(false)
			_tick_story(dtf)
		St.CUT:
			_tick_cut(dtf)
		St.SHOP:
			_tick_shop()
		St.PLAY:
			var inp := {
				"l": _held(KEY_A) or _held(KEY_LEFT) or (demo and true),
				"r": _held(KEY_D) or _held(KEY_RIGHT) or demo,
				"u": _held(KEY_W) or _held(KEY_UP),
				"d": _held(KEY_S) or _held(KEY_DOWN),
				"jump": _hit(KEY_W) or _hit(KEY_UP) or _hit(KEY_SPACE) or (demo and frames % 70 == 0),
				"attack": _hit(KEY_J) or _hit(KEY_Z) or (demo and frames % 12 == 0),
			}
			if demo:
				inp["l"] = false
			world.tick(dtf, inp)
			_sync_music(false)
			_update_light()
			var ev := world.consume_event()
			if ev == "dead":
				st = St.OVER
			elif ev == "boss":
				st = St.BOSS
				boss_t = 110.0
			elif ev == "win":
				_apply_win()
				st = St.WIN
			if _hit(KEY_P) or _hit(KEY_ESCAPE):
				st = St.PAUSE
			elif _hit(KEY_K) or _hit(KEY_X):
				world.show_note("NAO PODES TROCAR DURANTE A FASE")
		St.PAUSE:
			if _hit(KEY_P) or _hit(KEY_ESCAPE):
				st = St.PLAY
			elif _hit(KEY_Q):
				st = St.MENU
				world.visible = false
				light.visible = false
		St.BOSS:
			boss_t -= dtf
			if boss_t <= 0.0 or _accept():
				st = St.PLAY
		St.TRAVEL:
			travel_t += dtf
			if travel_t >= 90.0 and _accept():
				_prepare(travel_to)
		St.OVER:
			_sync_music(false)
			if _hit(KEY_R):
				_begin_play()
		St.WIN:
			win_t += dtf
			_sync_music(false)
			_tick_win()
	if _hit(KEY_MINUS) or _hit(KEY_KP_SUBTRACT):
		vol = maxf(0.05, vol - 0.08)
		_apply_vol()
	if _hit(KEY_EQUAL) or _hit(KEY_KP_ADD):
		vol = minf(1.0, vol + 0.08)
		_apply_vol()
	_maybe_shot()
	just.clear()
	released_jump = false

func _start_story() -> void:
	slide = 0
	chars = 0
	char_acc = 0.0
	fade = 0.0
	st = St.STORY

func _prepare(i: int) -> void:
	world.phase_i = i
	cut_i = 0
	cut_acc = 0.0
	st = St.CUT
	world.visible = false
	light.visible = false

func _begin_play() -> void:
	win_applied = false
	var idx := world.phase_i
	var wallet := SaveData.coins
	if st == St.OVER:
		wallet = world.coins
		SaveData.coins = wallet
	if st == St.MENU or st == St.STORY:
		idx = 0
	world.visible = true
	world.start_phase(idx, wallet, SaveData.hp_max, SaveData.ng, SaveData.armor)
	st = St.PLAY

func _enter_shop() -> void:
	st = St.SHOP
	shop_i = Cat.armor_index(SaveData.armor)
	shop_msg = ""
	shop_msg_t = 0.0
	world.visible = false
	light.visible = false

func _tick_story(dtf: float) -> void:
	var text := str(Cat.story()[slide])
	if fade > 0.0:
		fade += dtf * 0.06
		if fade >= 1.0:
			if slide + 1 < Cat.story().size():
				slide += 1
				chars = 0
				char_acc = 0.0
				fade = 0.0
			else:
				fade = 0.0
				world.phase_i = 0
				_prepare(0)
		return
	char_acc += dtf
	if char_acc >= 1.5 and chars < text.length():
		char_acc = 0.0
		chars += 1
	if _accept():
		if chars < text.length():
			chars = text.length()
		else:
			fade = 0.01

func _tick_cut(dtf: float) -> void:
	var fala := str(Cat.phase(world.phase_i)["cut"])
	cut_acc += dtf
	if cut_acc >= 2.0 and cut_i < fala.length():
		cut_acc = 0.0
		cut_i += 1
	if _accept():
		if cut_i < fala.length():
			cut_i = fala.length()
		else:
			_enter_shop()

func _tick_shop() -> void:
	var arms: Array = Cat.armors()
	var cols := 6
	if shop_msg_t > 0.0:
		shop_msg_t -= 1.0
	if _hit(KEY_LEFT) or _hit(KEY_A):
		shop_i = (shop_i - 1 + arms.size()) % arms.size()
	if _hit(KEY_RIGHT) or _hit(KEY_D):
		shop_i = (shop_i + 1) % arms.size()
	if (_hit(KEY_UP) or _hit(KEY_W)) and shop_i >= cols:
		shop_i -= cols
	if _hit(KEY_DOWN) or _hit(KEY_S):
		if shop_i + cols < arms.size():
			shop_i += cols
		elif shop_i < arms.size() - 1:
			shop_i = arms.size() - 1
	if _hit(KEY_Q):
		_begin_play()
		return
	if _accept():
		var arm: Dictionary = arms[shop_i]
		var id := str(arm["id"])
		if SaveData.owns(id):
			SaveData.armor = id
			_begin_play()
		else:
			var price := int(arm["price"])
			if SaveData.coins >= price:
				SaveData.coins -= price
				SaveData.grant(id)
				SaveData.armor = id
				shop_msg = str(arm["name"]) + " COMPRADA"
				shop_msg_t = 90.0
				SaveData.write(world.phase_i)
			else:
				shop_msg = "FALTAM %d MOEDAS" % (price - SaveData.coins)
				shop_msg_t = 90.0

func _apply_win() -> void:
	if win_applied:
		return
	win_applied = true
	win_t = 0.0
	var ph: Dictionary = Cat.phase(world.phase_i)
	world.coins += 100 + world.phase_i * 50
	SaveData.coins = world.coins
	SaveData.points = world.points
	var reward := str(ph["reward"])
	won_new = SaveData.grant(reward)
	var n := int(ph["n"])
	heart_msg = ""
	if n == 3 and SaveData.hp_max < 8:
		SaveData.hp_max = 8
		heart_msg = "+1 CORACAO MAXIMO (4)"
	elif n == 7 and SaveData.hp_max < 10:
		SaveData.hp_max = 10
		heart_msg = "+1 CORACAO MAXIMO (5)"
	if bool(ph["final"]):
		SaveData.write(world.phase_i)
	else:
		SaveData.write(world.phase_i + 1)
	world.visible = false
	light.visible = false

func _tick_win() -> void:
	var ph: Dictionary = Cat.phase(world.phase_i)
	if bool(ph["final"]):
		if _accept():
			SaveData.ng += 1
			SaveData.grant("boss_afo")
			SaveData.armor = "boss_afo"
			SaveData.points = 0
			SaveData.write(0)
			world.phase_i = 0
			_prepare(0)
		elif _hit(KEY_M):
			st = St.MENU
		return
	if won_new and win_t < 140.0 and not _accept():
		return
	if _accept():
		if world.phase_i + 1 < Cat.phases().size():
			travel_from = world.phase_i
			travel_to = world.phase_i + 1
			travel_t = 0.0
			st = St.TRAVEL
		else:
			st = St.MENU

func _sync_music(force: bool) -> void:
	if muted:
		return
	var file := "menu-musica.mp3"
	var pitch := 1.0
	if st == St.OVER:
		pitch = 0.72
	elif st == St.WIN:
		pitch = 1.22
	elif st == St.PLAY or st == St.PAUSE or st == St.BOSS or st == St.CUT or st == St.SHOP or st == St.TRAVEL:
		var ph: Dictionary = Cat.phase(world.phase_i)
		file = str(ph["music"])
		if st == St.PLAY or st == St.BOSS:
			var near: Dictionary = world.boss_near(900.0)
			if not near.is_empty():
				pitch = 1.45 if float(near["hp"]) / maxf(1.0, float(near["hp_max"])) < 0.4 else 1.2
	if not force and music_file == file:
		if music.playing:
			music.pitch_scale = pitch
		return
	var path := _asset(file)
	if not FileAccess.file_exists(path):
		return
	var stream := AudioStreamMP3.new()
	stream.data = FileAccess.get_file_as_bytes(path)
	stream.loop = true
	music.stream = stream
	music.pitch_scale = pitch
	_apply_vol()
	music.play()
	music_file = file

func _apply_vol() -> void:
	music.volume_db = linear_to_db(clampf(vol, 0.001, 1.0))

func _update_light() -> void:
	var ph: Dictionary = Cat.phase(world.phase_i)
	var dark := float(ph["dark"])
	light.visible = dark > 0.0 and world.visible
	if not light.visible:
		return
	var fog: Array = ph["fog"]
	var sx: float = world.position.x + world.hero["x"] + world.hero["w"] * 0.5
	var sy: float = world.position.y + world.hero["y"] + world.hero["h"] * 0.5
	var radius := 280.0 if str(world.hero["armor"]) == "angelical" else 220.0
	light_mat.set_shader_parameter("center", Vector2(sx, sy))
	light_mat.set_shader_parameter("radius", radius)
	light_mat.set_shader_parameter("darkness", dark)
	light_mat.set_shader_parameter("fog", Vector3(float(fog[0]), float(fog[1]), float(fog[2])))

func _maybe_shot() -> void:
	if shot == "" or _shot_started:
		return
	if frames > 600:
		push_error("shot timeout")
		get_tree().quit(1)
		return
	var due := (demo and frames == 150) or (not demo and frames == 40)
	if not due:
		return
	_shot_started = true
	_capture_shot()

func _capture_shot() -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var err := img.save_png(shot)
	print("SHOT ", shot, " err ", err, " ", img.get_width(), "x", img.get_height(), " phase ", world.phase_i, " enemies ", world.enemies.size(), " hp ", world.hero.get("hp", 0), " x ", world.hero.get("x", 0))
	get_tree().quit(0 if err == OK else 1)

func paint(c: Control) -> void:
	var sx := 0.0
	var sy := 0.0
	if st == St.PLAY or st == St.PAUSE or st == St.BOSS:
		if world.shake > 0.4:
			sx = (randf() - 0.5) * world.shake * 2.0
			sy = (randf() - 0.5) * world.shake * 2.0
		world.position = Vector2(-world.cam + sx, sy)
	match st:
		St.MENU:
			_paint_menu(c)
		St.STORY:
			_paint_story(c)
		St.CUT:
			_paint_cut(c)
		St.SHOP:
			_paint_shop(c)
		St.PLAY, St.PAUSE, St.BOSS:
			_paint_play(c)
			if st == St.PAUSE:
				_paint_pause(c)
			elif st == St.BOSS:
				_paint_boss(c)
		St.TRAVEL:
			_paint_travel(c)
		St.OVER:
			_paint_over(c)
		St.WIN:
			_paint_win(c)

func _paint_menu(c: Control) -> void:
	if menu_bg:
		c.draw_texture_rect(menu_bg, Rect2(0, 0, 960, 540), false)
	else:
		_bands(c, Color("#0a0a2a"), Color("#330033"))
	_text(c, "ARMADURAS", 0, 96, 64, Color(0, 0, 0, 0.75), HORIZONTAL_ALIGNMENT_CENTER, 960)
	_text(c, "ARMADURAS", 0, 90, 64, Color("#44aaff"), HORIZONTAL_ALIGNMENT_CENTER, 960)
	_text(c, "X VILOES", 0, 156, 64, Color("#ff4444"), HORIZONTAL_ALIGNMENT_CENTER, 960)
	c.draw_rect(Rect2(0, 430, 960, 110), Color(0, 0, 0, 0.62))
	if SaveData.has_save:
		var blink := Color("#44ff66") if int(tempo / 30.0) % 2 == 0 else Color("#888888")
		_text(c, "ENTER  CONTINUAR  (Fase %d)" % (SaveData.phase + 1), 0, 470, 22, blink, HORIZONTAL_ALIGNMENT_CENTER, 960)
		_text(c, "N  NOVO JOGO", 0, 500, 16, Color("#ffcc66"), HORIZONTAL_ALIGNMENT_CENTER, 960)
	else:
		var blink2 := Color.WHITE if int(tempo / 30.0) % 2 == 0 else Color("#aaaaaa")
		_text(c, "ENTER PARA COMECAR", 0, 480, 22, blink2, HORIZONTAL_ALIGNMENT_CENTER, 960)
	_text(c, "Para o Luis Manuel", 0, 524, 14, Color("#888888"), HORIZONTAL_ALIGNMENT_CENTER, 960)

func _paint_story(c: Control) -> void:
	var tops := [Color("#1a3a8a"), Color("#20060a"), Color("#3a0010"), Color("#100020"), Color("#0a0a20"), Color("#102040"), Color("#000000")]
	var bots := [Color("#ffaa66"), Color("#401010"), Color("#801010"), Color("#400010"), Color("#101028"), Color("#ffaa66"), Color("#332000")]
	_bands(c, tops[slide], bots[slide])
	c.draw_rect(Rect2(40, 340, 880, 160), Color(0, 0, 0, 0.75))
	c.draw_rect(Rect2(40, 340, 880, 3), Color("#ffcc00"))
	var full := str(Cat.story()[slide])
	var shown := full.substr(0, chars)
	var y := 390.0
	for line in shown.split("\n"):
		_text(c, line, 0, y, 24, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 960)
		y += 34
	_text(c, "ENTER", 820, 480, 16, Color("#ffcc00") if int(tempo / 20.0) % 2 == 0 else Color("#888888"))
	if fade > 0.0:
		c.draw_rect(Rect2(0, 0, 960, 540), Color(0, 0, 0, minf(1.0, fade)))

func _paint_cut(c: Control) -> void:
	_bands(c, Color("#1a0010"), Color("#0a0010"))
	if villain:
		c.draw_texture_rect(villain, Rect2(40, 30, 280, 280), false)
	else:
		c.draw_rect(Rect2(70, 80, 180, 220), Color("#222222"))
	if hero_tex:
		c.draw_texture_rect(hero_tex, Rect2(640, 30, 280, 280), false, Color(1, 1, 1, 0.7))
	var ph: Dictionary = Cat.phase(world.phase_i)
	c.draw_rect(Rect2(40, 380, 880, 120), Color(0, 0, 0, 0.8))
	c.draw_rect(Rect2(40, 380, 880, 3), Color("#ff4444"))
	_text(c, str(ph["cut_name"]), 60, 414, 16, Color("#ff8888"))
	_text(c, str(ph["cut"]).substr(0, cut_i), 60, 452, 22, Color.WHITE)
	_text(c, "ENTER", 800, 484, 14, Color("#888888"))

func _paint_shop(c: Control) -> void:
	c.draw_rect(Rect2(0, 0, 960, 540), Color("#0a0a1e"))
	var ph: Dictionary = Cat.phase(world.phase_i)
	_text(c, "ARMADURAS  —  FASE %d  %s" % [int(ph["n"]), ph["name"]], 0, 32, 22, Color("#ffcc00"), HORIZONTAL_ALIGNMENT_CENTER, 960)
	_text(c, "%d moedas" % SaveData.coins, 0, 56, 16, Color("#ffcc00"), HORIZONTAL_ALIGNMENT_CENTER, 960)
	var arms: Array = Cat.armors()
	var cols := 6
	var cell_w := 150.0
	var cell_h := 78.0
	var start_x := (960.0 - cols * cell_w) * 0.5
	var start_y := 70.0
	var view_h := 400.0
	var rows := int(ceil(float(arms.size()) / float(cols)))
	var max_scroll := maxf(0.0, rows * cell_h - view_h)
	var sel_y := float(shop_i / cols) * cell_h
	if sel_y < shop_scroll:
		shop_scroll = sel_y
	elif sel_y + cell_h > shop_scroll + view_h:
		shop_scroll = sel_y + cell_h - view_h
	shop_scroll = clampf(shop_scroll, 0.0, max_scroll)
	for i in arms.size():
		var col := i % cols
		var row := int(i / cols)
		var x := start_x + col * cell_w
		var y := start_y + row * cell_h - shop_scroll
		if y > 500.0 or y + cell_h < 64.0:
			continue
		var arm: Dictionary = arms[i]
		var owned := SaveData.owns(str(arm["id"]))
		var sel := i == shop_i
		var bg := Color("#ffcc00") if sel else (Color(0.2, 0.45, 0.25, 0.45) if owned else Color(0.15, 0.15, 0.22, 0.7))
		c.draw_rect(Rect2(x + 4, y + 2, cell_w - 8, cell_h - 6), bg)
		var body := Cat.colorize(str(arm["body"]))
		var trim := Cat.colorize(str(arm["trim"]))
		c.draw_rect(Rect2(x + 62, y + 16, 22, 28), body)
		c.draw_rect(Rect2(x + 66, y + 8, 14, 10), Color("#22cc88"))
		c.draw_rect(Rect2(x + 62, y + 16, 22, 4), trim)
		if not owned:
			c.draw_rect(Rect2(x + 4, y + 2, cell_w - 8, cell_h - 6), Color(0, 0, 0, 0.45))
		_text(c, str(arm["name"]), x + 4, y + cell_h - 16, 9, Color.BLACK if sel else Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, cell_w - 8)
		if owned:
			_text(c, "OK", x + 4, y + 28, 11, Color("#114411") if sel else Color("#88ff88"), HORIZONTAL_ALIGNMENT_CENTER, cell_w - 8)
		else:
			var price_col := Color("#44ff66") if SaveData.coins >= int(arm["price"]) else Color("#ff5555")
			_text(c, str(int(arm["price"])), x + 4, y + 28, 12, price_col, HORIZONTAL_ALIGNMENT_CENTER, cell_w - 8)
	if shop_msg_t > 0.0:
		c.draw_rect(Rect2(230, 492, 500, 28), Color(0, 0, 0, 0.85))
		_text(c, shop_msg, 0, 512, 14, Color("#ffcc00"), HORIZONTAL_ALIGNMENT_CENTER, 960)
	else:
		var verb := "EQUIPAR" if SaveData.owns(str(arms[shop_i]["id"])) else "COMPRAR"
		_text(c, "Setas navegar   ENTER %s   Q entrar com a actual" % verb, 0, 524, 13, Color("#999999"), HORIZONTAL_ALIGNMENT_CENTER, 960)

func _paint_play(c: Control) -> void:
	var ph: Dictionary = Cat.phase(world.phase_i)
	var grade: Array = ph["grade"]
	c.draw_rect(Rect2(0, 0, 960, 540), Color(float(grade[0]), float(grade[1]), float(grade[2]), float(grade[3])))
	var ratio := clampf(float(world.hero["hp"]) / maxf(1.0, float(world.hero["hp_max"])), 0.0, 1.0)
	var edge := 0.22 + (1.0 - ratio) * 0.45
	var edge_col := Color(0.6, 0, 0, edge) if ratio < 0.3 else Color(0, 0, 0, edge)
	c.draw_rect(Rect2(0, 0, 960, 36), edge_col)
	c.draw_rect(Rect2(0, 500, 960, 40), edge_col)
	c.draw_rect(Rect2(0, 0, 28, 540), edge_col)
	c.draw_rect(Rect2(932, 0, 28, 540), edge_col)
	var hearts := int(world.hero["hp_max"] / 2)
	for i in hearts:
		var state := 0
		if world.hero["hp"] >= (i + 1) * 2:
			state = 2
		elif world.hero["hp"] >= (i + 1) * 2 - 1:
			state = 1
		_hud_heart(c, 18 + i * 28, 36, state)
	_text(c, "PONTOS %d" % world.points, 760, 28, 16, Color.WHITE)
	_text(c, "%d moedas" % world.coins, 760, 48, 14, Color("#ffcc00"))
	if SaveData.ng > 0:
		_text(c, "NG+%d" % SaveData.ng, 860, 68, 14, Color("#ff4444"))
	var arm := Cat.armor_by_id(str(world.hero["armor"]))
	_text(c, str(arm["name"]), 18, 78, 13, Color("#aaccff"))
	var room: Array = ph["rooms"]
	_text(c, "F%d  %s" % [int(ph["n"]), room[world.sub]], 18, 96, 13, Color("#ffcc00"))
	if world.combo >= 2:
		var cc := Color("#ff66cc") if world.combo >= 10 else (Color("#ffcc00") if world.combo >= 5 else Color.WHITE)
		_text(c, "x%d KILLS" % world.combo, 0, 78, 26, cc, HORIZONTAL_ALIGNMENT_CENTER, 960)
	var prog := clampf(world.hero["x"] / maxf(1.0, float(ph["width"]) - 200.0), 0.0, 1.0)
	c.draw_rect(Rect2(200, 16, 560, 8), Color("#12305a"))
	c.draw_rect(Rect2(200, 16, 560.0 * prog, 8), Color("#44aaff"))
	c.draw_rect(Rect2(752, 12, 8, 16), Color("#ff4466"))
	if world.sub_t > 0.0:
		var room_name := str(room[world.sub])
		c.draw_rect(Rect2(220, 230, 520, 70), Color(0, 0, 0, 0.78))
		var box := Color("#ff4444") if world.sub >= 4 else Color("#ffcc00")
		_text(c, room_name, 0, 274, 28, box, HORIZONTAL_ALIGNMENT_CENTER, 960)
	if world.note_t > 0.0:
		c.draw_rect(Rect2(160, 150, 640, 40), Color(0, 0, 0, 0.75))
		_text(c, world.note, 0, 178, 18, Color("#ffcc00"), HORIZONTAL_ALIGNMENT_CENTER, 960)
	if world.flash > 0.0:
		c.draw_rect(Rect2(0, 0, 960, 540), Color(1, 1, 1, clampf(world.flash / 8.0, 0.0, 1.0) * 0.7))
	if world.hurt > 0.0:
		c.draw_rect(Rect2(0, 0, 960, 540), Color(1, 0, 0, world.hurt / 14.0 * 0.35))
	var boss = world._boss()
	if boss != null:
		var bx: float = boss["x"] - world.cam
		if bx > 980.0:
			_text(c, "> %s >" % boss["name"], 700, 270, 18, Color("#ff4444") if int(tempo / 10.0) % 2 == 0 else Color("#ffcc00"))

func _hud_heart(c: Control, x: float, y: float, state: int) -> void:
	var col := Color("#661111") if state == 0 else Color("#ee2244")
	c.draw_circle(Vector2(x + 6, y + 6), 6, col)
	c.draw_circle(Vector2(x + 14, y + 6), 6, col)
	c.draw_colored_polygon(PackedVector2Array([Vector2(x, y + 8), Vector2(x + 20, y + 8), Vector2(x + 10, y + 20)]), col)
	if state == 1:
		c.draw_rect(Rect2(x + 10, y, 12, 22), Color(0, 0, 0, 0.55))

func _paint_pause(c: Control) -> void:
	c.draw_rect(Rect2(0, 0, 960, 540), Color(0, 0, 0, 0.7))
	_text(c, "PAUSA", 0, 200, 56, Color("#ffcc00"), HORIZONTAL_ALIGNMENT_CENTER, 960)
	_text(c, "P ou ESC continuar", 0, 260, 20, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 960)
	_text(c, "Q voltar ao menu", 0, 292, 20, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 960)
	_text(c, "Setas/WASD andar   W/Espaco saltar   J/Z atacar", 0, 360, 14, Color("#aaaaaa"), HORIZONTAL_ALIGNMENT_CENTER, 960)
	_text(c, "Duplo salto: voo com Angelical ou Dragao Supremo", 0, 384, 14, Color("#aaaaaa"), HORIZONTAL_ALIGNMENT_CENTER, 960)

func _paint_boss(c: Control) -> void:
	c.draw_rect(Rect2(0, 0, 960, 540), Color(0.1, 0, 0.08, 0.55))
	var shown := int((1.0 - boss_t / 110.0) * world.boss_line.length())
	_text(c, "BOSS", 0, 180, 28, Color("#ff2222") if int(tempo / 8.0) % 2 == 0 else Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 960)
	_text(c, world.boss_name, 0, 240, 42, Color("#ffcc00"), HORIZONTAL_ALIGNMENT_CENTER, 960)
	c.draw_rect(Rect2(80, 280, 800, 70), Color(0, 0, 0, 0.85))
	_text(c, world.boss_line.substr(0, shown), 0, 324, 18, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 960)

func _paint_travel(c: Control) -> void:
	_bands(c, Color("#0a0a30"), Color("#100020"))
	var dest: Dictionary = Cat.phase(travel_to)
	_text(c, "A CAMINHO DE %s" % dest["name"], 0, 70, 26, Color("#ffcc00"), HORIZONTAL_ALIGNMENT_CENTER, 960)
	var n := Cat.phases().size()
	var pts: Array = []
	for i in n:
		pts.append(Vector2(40 + (880.0 * i / float(n - 1)), 280 + sin(i * 0.7) * 50))
	for i in n - 1:
		c.draw_line(pts[i], pts[i + 1], Color("#444444"), 2.0)
	for i in travel_from:
		c.draw_line(pts[i], pts[i + 1], Color("#44ff66"), 4.0)
	var prog := clampf(travel_t / 90.0, 0.0, 1.0)
	var a: Vector2 = pts[travel_from]
	var b: Vector2 = pts[travel_to]
	var at := a.lerp(b, prog)
	c.draw_line(a, at, Color("#ffcc00"), 4.0)
	for i in n:
		var col := Color("#666666")
		if i <= travel_from:
			col = Color("#44ff66")
		if i == travel_to:
			col = Color("#ffcc00") if int(tempo / 8.0) % 2 == 0 else Color("#ff8800")
		c.draw_circle(pts[i], 12 if i == travel_to else 8, col)
		_text(c, str(i + 1), pts[i].x - 8, pts[i].y + 4, 12, Color.BLACK)
	c.draw_rect(Rect2(at.x - 6, at.y - 22, 12, 10), Color("#22cc88"))
	c.draw_rect(Rect2(at.x - 5, at.y - 12, 10, 12), Color("#3a6acc"))
	var hint := "ENTER entrar na fase" if prog >= 1.0 else "a viajar..."
	_text(c, hint, 0, 500, 16, Color.WHITE if int(tempo / 20.0) % 2 == 0 else Color("#888888"), HORIZONTAL_ALIGNMENT_CENTER, 960)

func _paint_over(c: Control) -> void:
	c.draw_rect(Rect2(0, 0, 960, 540), Color(0, 0, 0, 0.72))
	_text(c, "GAME OVER", 0, 250, 64, Color("#ff4444"), HORIZONTAL_ALIGNMENT_CENTER, 960)
	_text(c, "R PARA REINICIAR", 0, 310, 22, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 960)
	_text(c, "PONTOS %d" % world.points, 0, 348, 18, Color("#aaaaaa"), HORIZONTAL_ALIGNMENT_CENTER, 960)

func _paint_win(c: Control) -> void:
	var ph: Dictionary = Cat.phase(world.phase_i)
	if bool(ph["final"]):
		c.draw_rect(Rect2(0, 0, 960, 540), Color(0.08, 0, 0.16, 0.94))
		_text(c, "MUNDO SALVO", 0, 160, 52, Color("#ffcc00") if int(tempo / 15.0) % 2 == 0 else Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 960)
		_text(c, "ESPIRITO SUPREMO DERROTADO", 0, 210, 28, Color("#44ff66"), HORIZONTAL_ALIGNMENT_CENTER, 960)
		_text(c, "Midoriya tornou-se lenda.", 0, 250, 18, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 960)
		_text(c, "PONTOS %d    NG+%d" % [world.points, SaveData.ng], 0, 300, 20, Color("#ffcc66"), HORIZONTAL_ALIGNMENT_CENTER, 960)
		_text(c, "ENTER  NEW GAME+ %d" % (SaveData.ng + 1), 0, 360, 26, Color("#ff4444") if int(tempo / 12.0) % 2 == 0 else Color("#ffcc00"), HORIZONTAL_ALIGNMENT_CENTER, 960)
		_text(c, "Ficas com as armaduras. Inimigos +60% por ciclo.", 0, 400, 14, Color("#888888"), HORIZONTAL_ALIGNMENT_CENTER, 960)
		_text(c, "M voltar ao menu", 0, 430, 14, Color("#666666"), HORIZONTAL_ALIGNMENT_CENTER, 960)
		return
	if won_new and win_t < 140.0:
		c.draw_rect(Rect2(0, 0, 960, 540), Color(0.08, 0.06, 0, 0.95))
		_text(c, "NOVA ARMADURA", 0, 120, 32, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 960)
		var reward := Cat.armor_by_id(str(ph["reward"]))
		_text(c, str(reward["name"]), 0, 280, 40, Color("#ffcc00"), HORIZONTAL_ALIGNMENT_CENTER, 960)
		if heart_msg != "":
			_text(c, heart_msg, 0, 340, 18, Color("#ff6688"), HORIZONTAL_ALIGNMENT_CENTER, 960)
		_text(c, "ENTER", 0, 480, 16, Color("#aaaaaa"), HORIZONTAL_ALIGNMENT_CENTER, 960)
		return
	c.draw_rect(Rect2(0, 0, 960, 540), Color(0, 0.12, 0, 0.88))
	_text(c, "FASE %d COMPLETA" % int(ph["n"]), 0, 200, 42, Color("#44ff66"), HORIZONTAL_ALIGNMENT_CENTER, 960)
	_text(c, str(Cat.armor_by_id(str(ph["reward"]))["name"]), 0, 260, 24, Color("#ffcc66"), HORIZONTAL_ALIGNMENT_CENTER, 960)
	if heart_msg != "":
		_text(c, heart_msg, 0, 300, 18, Color("#ff6688"), HORIZONTAL_ALIGNMENT_CENTER, 960)
	_text(c, "PONTOS %d" % world.points, 0, 340, 20, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 960)
	if world.phase_i + 1 < Cat.phases().size():
		var nxt: Dictionary = Cat.phase(world.phase_i + 1)
		_text(c, "ENTER  FASE %d: %s" % [int(nxt["n"]), nxt["name"]], 0, 400, 18, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 960)
	else:
		_text(c, "ENTER menu", 0, 400, 18, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, 960)

func _bands(c: Control, top: Color, bot: Color) -> void:
	for i in 12:
		c.draw_rect(Rect2(0, i * 45, 960, 46), top.lerp(bot, float(i) / 11.0))

func _text(c: Control, text: String, x: float, y: float, size: int, col: Color, align := HORIZONTAL_ALIGNMENT_LEFT, width := -1.0) -> void:
	c.draw_string(font, Vector2(x, y), text, align, width, size, col)

func _held(key: int) -> bool:
	return down.get(key, false)

func _hit(key: int) -> bool:
	return just.get(key, false)

func _accept() -> bool:
	return _hit(KEY_ENTER) or _hit(KEY_KP_ENTER)

func _asset(file: String) -> String:
	return ProjectSettings.globalize_path("res://").path_join("../assets").path_join(file)

func _load_tex(file: String) -> Texture2D:
	var path := _asset(file)
	if not FileAccess.file_exists(path):
		return null
	var img := Image.load_from_file(path)
	if img == null or img.get_width() == 0:
		return null
	return ImageTexture.create_from_image(img)

class Hud extends Control:
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_anchors_preset(Control.PRESET_FULL_RECT)
	func _process(_d: float) -> void:
		queue_redraw()
	func _draw() -> void:
		var main := get_parent().get_parent()
		if main and main.has_method("paint"):
			main.paint(self)
