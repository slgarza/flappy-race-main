extends Control

const VIEW = Vector2(360, 640)
const PLAY_SECONDS = 20.0
const STORE_URL = "https://play.google.com/store/apps/details?id=com.slgdeveloper.flappyrace"

const SKY = Color(0.33, 0.72, 0.91)
const DEEP = Color(0.07, 0.16, 0.24)
const SHADOW = Color(0.02, 0.09, 0.13, 0.55)
const YELLOW = Color(1.0, 0.80, 0.15)
const PINK = Color(0.94, 0.31, 0.42)
const GREEN = Color(0.18, 0.43, 0.32)
const WHITE = Color(1, 1, 1)

const GLYPHS = {
	" ": ["000","000","000","000","000","000","000"],
	"!": ["1","1","1","1","1","0","1"],
	"+": ["000","010","010","111","010","010","000"],
	"-": ["000","000","000","111","000","000","000"],
	"?": ["111","001","001","011","010","000","010"],
	"/": ["001","001","010","010","100","100","100"],
	"1": ["010","110","010","010","010","010","111"],
	"2": ["111","001","001","111","100","100","111"],
	"3": ["111","001","001","111","001","001","111"],
	"4": ["101","101","101","111","001","001","001"],
	"5": ["111","100","100","111","001","001","111"],
	"6": ["111","100","100","111","101","101","111"],
	"7": ["111","001","001","010","010","100","100"],
	"8": ["111","101","101","111","101","101","111"],
	"9": ["111","101","101","111","001","001","111"],
	"A": ["010","101","101","111","101","101","101"],
	"B": ["110","101","101","110","101","101","110"],
	"C": ["111","100","100","100","100","100","111"],
	"D": ["110","101","101","101","101","101","110"],
	"E": ["111","100","100","110","100","100","111"],
	"F": ["111","100","100","110","100","100","100"],
	"G": ["111","100","100","101","101","101","111"],
	"H": ["101","101","101","111","101","101","101"],
	"I": ["111","010","010","010","010","010","111"],
	"K": ["101","101","110","100","110","101","101"],
	"L": ["100","100","100","100","100","100","111"],
	"M": ["10001","11011","10101","10101","10001","10001","10001"],
	"N": ["1001","1101","1011","1001","1001","1001","1001"],
	"O": ["111","101","101","101","101","101","111"],
	"P": ["111","101","101","111","100","100","100"],
	"R": ["110","101","101","110","101","101","101"],
	"S": ["111","100","100","111","001","001","111"],
	"T": ["111","010","010","010","010","010","010"],
	"U": ["101","101","101","101","101","101","111"],
	"V": ["101","101","101","101","101","101","010"],
	"W": ["10001","10001","10001","10101","10101","11011","10001"],
	"Y": ["101","101","101","010","010","010","010"]
}

var state = "intro"
var t = 0.0
var pulse = 0.0
var shake = 0.0
var speed = 160.0
var progress = 0.0
var place = 4
var bird = {"x": 90.0, "y": 300.0, "vy": 0.0, "rot": 0.0, "hit": 0.0}
var walls = []
var coins = []
var boxes = []
var sparks = []
var rivals = []
var next_wall = 0.8
var next_coin = 1.3
var next_box = 3.2
var boost = 0.0
var last_power = "BOOST"
var draw_origin = Vector2.ZERO
var draw_zoom = 1.0


func _ready():
	randomize()
	reset()
	state = "intro"
	set_process(true)
	set_process_input(true)


func _input(event):
	var pressed = false
	if event is InputEventMouseButton and event.pressed and event.button_index == BUTTON_LEFT:
		pressed = true
	if event is InputEventScreenTouch and event.pressed:
		pressed = true
	if event.is_action_pressed("ui_accept"):
		pressed = true
	if not pressed:
		return
	get_tree().set_input_as_handled()
	if state == "intro":
		reset()
		state = "play"
		flap()
	elif state == "play":
		flap()
	else:
		exit_ad()


func reset():
	t = 0.0
	speed = 160.0
	progress = 0.0
	place = 4
	boost = 0.0
	last_power = "BOOST"
	bird = {"x": 90.0, "y": 300.0, "vy": 0.0, "rot": 0.0, "hit": 0.0}
	walls.clear()
	coins.clear()
	boxes.clear()
	sparks.clear()
	rivals = [
		{"x": 58.0, "y": 230.0, "p": 150.0, "c": Color(0.20, 0.82, 1.0), "hit": 0.0},
		{"x": 42.0, "y": 350.0, "p": 80.0, "c": YELLOW, "hit": 0.0},
		{"x": 68.0, "y": 440.0, "p": 230.0, "c": Color(0.58, 0.40, 1.0), "hit": 0.0}
	]
	next_wall = 0.8
	next_coin = 1.3
	next_box = 3.2


func flap():
	bird.vy = -355.0
	bird.rot = -0.4
	add_sparks(Vector2(bird.x - 20, bird.y + 8), YELLOW, 7)


func _process(delta):
	pulse += delta
	if state == "play":
		update_play(delta)
	update_sparks(delta)
	update()


func update_play(delta):
	t += delta
	if boost > 0:
		boost = max(0, boost - delta)
	speed = 160.0 + t * 2.2
	if boost > 0:
		speed += 95.0
	progress += speed * delta
	bird.vy = min(760.0, bird.vy + 980.0 * delta)
	bird.y = clamp(bird.y + bird.vy * delta, 84.0, 548.0)
	bird.rot = clamp(lerp(bird.rot, bird.vy / 720.0, 0.12), -0.45, 0.75)
	if bird.y > 536:
		bird.vy = -220
		hit()

	next_wall -= delta
	if next_wall <= 0:
		walls.append({"x": 390.0, "gap": rand_range(165, 430), "passed": false})
		next_wall = rand_range(1.5, 2.0)
	next_coin -= delta
	if next_coin <= 0:
		var y = rand_range(165, 450)
		for i in range(4):
			coins.append({"x": 392.0 + i * 34.0, "y": y + sin(i) * 22.0})
		next_coin = rand_range(1.25, 1.8)
	next_box -= delta
	if next_box <= 0:
		boxes.append({"x": 400.0, "y": rand_range(170, 430)})
		next_box = 4.0

	for w in walls:
		w.x -= speed * delta
		if not w.passed and w.x < bird.x:
			w.passed = true
		if abs(w.x - bird.x) < 32 and (bird.y < w.gap - 82 or bird.y > w.gap + 82):
			hit()
	for c in coins:
		c.x -= speed * delta
		if Vector2(c.x, c.y).distance_to(Vector2(bird.x, bird.y)) < 28:
			c.x = -99
			add_sparks(Vector2(bird.x, bird.y), YELLOW, 5)
	for b in boxes:
		b.x -= speed * delta
		if Vector2(b.x, b.y).distance_to(Vector2(bird.x, bird.y)) < 34:
			use_power()
			b.x = -99

	for i in range(walls.size() - 1, -1, -1):
		if walls[i].x < -80:
			walls.remove(i)
	for i in range(coins.size() - 1, -1, -1):
		if coins[i].x < -50:
			coins.remove(i)
	for i in range(boxes.size() - 1, -1, -1):
		if boxes[i].x < -50:
			boxes.remove(i)

	var ahead = 0
	for r in rivals:
		r.hit = max(0, r.hit - delta)
		var rs = 145.0
		if r.hit > 0:
			rs *= 0.35
		r.p += rs * delta
		r.x = 65.0 + (r.p - progress) * 0.12
		r.y += sin(pulse * 4.0 + r.p * 0.01) * 0.55
		if r.p > progress:
			ahead += 1
	place = clamp(ahead + 1, 1, 4)

	if bird.hit > 0:
		bird.hit = max(0, bird.hit - delta)
	if t >= PLAY_SECONDS:
		state = "end"


func hit():
	if bird.hit > 0:
		return
	bird.hit = 0.7
	bird.vy = -240
	shake = 0.35
	add_sparks(Vector2(bird.x, bird.y), WHITE, 12)


func use_power():
	var roll = int(t) % 3
	if roll == 0:
		last_power = "BOOST"
		boost = 1.6
		add_sparks(Vector2(bird.x, bird.y), YELLOW, 14)
	elif roll == 1:
		last_power = "LASER"
		if rivals.size() > 0:
			rivals[0].hit = 1.0
	else:
		last_power = "FLOMB"
		for r in rivals:
			r.hit = 0.75


func add_sparks(pos, color, count):
	for _i in range(count):
		sparks.append({"p": pos, "v": Vector2(rand_range(-110, 45), rand_range(-160, 40)), "life": rand_range(0.25, 0.55), "c": color})


func update_sparks(delta):
	for s in sparks:
		s.p += s.v * delta
		s.v.y += 420 * delta
		s.life -= delta
	for i in range(sparks.size() - 1, -1, -1):
		if sparks[i].life <= 0:
			sparks.remove(i)


func _draw():
	var canvas = get_viewport_rect().size
	draw_zoom = max(canvas.x / VIEW.x, canvas.y / VIEW.y)
	draw_origin = (canvas - VIEW * draw_zoom) * 0.5
	if shake > 0:
		shake = max(0, shake - get_process_delta_time() * 4.0)
		draw_origin += Vector2(rand_range(-4, 4), rand_range(-4, 4)) * shake
	draw_set_transform(draw_origin, 0, Vector2(draw_zoom, draw_zoom))
	draw_world()
	if state == "intro":
		draw_intro()
	elif state == "play":
		draw_hud()
	else:
		draw_end()
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


func draw_world():
	draw_rect(Rect2(Vector2.ZERO, VIEW), SKY)
	for i in range(4):
		var x = fmod(i * 140.0 - progress * 0.08, 560.0) - 110.0
		draw_circle(Vector2(x, 118 + i * 48), 30 + i * 3, Color(1, 1, 1, 0.35))
	draw_circle(Vector2(50 - fmod(progress * 0.18, 500), 510), 105, Color(0.53, 0.72, 0.39))
	draw_circle(Vector2(195 - fmod(progress * 0.18, 500), 520), 125, Color(0.48, 0.67, 0.34))
	draw_rect(Rect2(0, 556, VIEW.x, 84), GREEN)
	draw_rect(Rect2(0, 550, VIEW.x, 6), YELLOW)

	for w in walls:
		draw_wall(w.x, w.gap)
	for c in coins:
		draw_circle(Vector2(c.x, c.y), 9 + sin(pulse * 8) * 1.5, YELLOW)
		draw_circle(Vector2(c.x, c.y), 4, Color(0.75, 0.45, 0.05))
	for b in boxes:
		draw_rect(Rect2(b.x - 15, b.y - 15, 30, 30), Color(0.08, 0.20, 0.33))
		draw_rect(Rect2(b.x - 11, b.y - 11, 22, 22), YELLOW)
		draw_word("?", Vector2(b.x - 4, b.y - 12), 3, DEEP)

	if PLAY_SECONDS - t < 3.8:
		var fx = 345 + (PLAY_SECONDS - t) * 42
		for y in range(90, 552, 22):
			var c = WHITE if int(y / 22) % 2 == 0 else DEEP
			draw_rect(Rect2(fx, y, 18, 22), c)

	for r in rivals:
		draw_kart(Vector2(r.x, r.y), r.c, 0.72, r.hit > 0)
	draw_kart(Vector2(bird.x, bird.y), PINK, 1.0, bird.hit > 0)
	for s in sparks:
		var c = s.c
		c.a = clamp(s.life * 2.5, 0, 1)
		draw_circle(s.p, 3 + s.life * 4, c)


func draw_wall(x, gap):
	draw_rect(Rect2(x - 20, -10, 40, gap - 82), Color(0.28, 0.37, 0.44))
	draw_rect(Rect2(x - 24, gap - 108, 48, 26), Color(0.20, 0.28, 0.35))
	draw_rect(Rect2(x - 20, gap + 82, 40, 478), Color(0.28, 0.37, 0.44))
	draw_rect(Rect2(x - 24, gap + 82, 48, 26), Color(0.20, 0.28, 0.35))


func draw_kart(pos, color, scale, stunned):
	var c = color
	if stunned and int(pulse * 14) % 2 == 0:
		c = WHITE
	if boost > 0 and scale > 0.9:
		draw_rect(Rect2(pos.x - 54, pos.y - 7, 38, 14), YELLOW)
	draw_circle(pos + Vector2(-13, -7) * scale, 20 * scale, c)
	draw_circle(pos + Vector2(10, 5) * scale, 16 * scale, c.darkened(0.2))
	draw_circle(pos + Vector2(19, -13) * scale, 7 * scale, WHITE)
	draw_circle(pos + Vector2(21, -13) * scale, 3 * scale, DEEP)
	draw_polygon([pos + Vector2(-25, 5) * scale, pos + Vector2(-42, 19) * scale, pos + Vector2(-20, 17) * scale], [DEEP, DEEP, DEEP])


func draw_hud():
	draw_rect(Rect2(12, 12, 112, 30), Color(0.02, 0.08, 0.12, 0.65))
	draw_text_center("PLACE " + str(place) + "/4", Rect2(12, 18, 112, 18), 3, WHITE)
	draw_rect(Rect2(142, 15, 200, 12), Color(0.02, 0.08, 0.12, 0.55))
	draw_rect(Rect2(144, 17, 196 * clamp(t / PLAY_SECONDS, 0, 1), 8), YELLOW)
	draw_text_center(last_power, Rect2(0, 48, 360, 22), 3, WHITE)


func draw_intro():
	draw_rect(Rect2(0, 0, 360, 640), Color(0.02, 0.10, 0.15, 0.25))
	draw_logo(Vector2(42, 60), 5)
	draw_text_center("TAP TO PLAY", Rect2(0, 245, 360, 50), 7, WHITE)
	draw_text_center("FAST RACE + POWER UPS", Rect2(0, 318, 360, 24), 3, YELLOW)
	draw_circle(Vector2(180, 416), 35 + sin(pulse * 5) * 4, Color(1, 1, 1, 0.18))
	draw_circle(Vector2(180, 416), 25, YELLOW)
	draw_text_center("TAP", Rect2(140, 406, 80, 22), 4, DEEP)


func draw_end():
	draw_rect(Rect2(0, 0, 360, 640), Color(0.02, 0.10, 0.15, 0.72))
	draw_logo(Vector2(42, 58), 5)
	draw_text_center("NICE FLIGHT!", Rect2(0, 188, 360, 52), 7, WHITE)
	draw_text_center("YOU FINISHED " + ordinal(place), Rect2(0, 258, 360, 44), 5, YELLOW)
	draw_text_center("CAN YOU TAKE 1ST PLACE?", Rect2(0, 320, 360, 28), 3, WHITE)
	draw_rect(Rect2(25, 374, 310, 72), WHITE)
	draw_text_center("MULTIPLAYER", Rect2(25, 388, 310, 26), 4, DEEP)
	draw_text_center("POWER-UPS + RACES", Rect2(25, 417, 310, 26), 4, PINK)
	draw_text_center("INSTALL AND RACE FOR 1ST", Rect2(0, 492, 360, 24), 3, WHITE)
	draw_rect(Rect2(56, 536, 248, 58), Color(0.72, 0.46, 0.07))
	draw_rect(Rect2(56, 536, 248, 50), YELLOW)
	draw_text_center("INSTALL FREE", Rect2(56, 553, 248, 24), 4, DEEP)


func draw_logo(pos, scale):
	draw_rect(Rect2(pos, Vector2(276, 78)), Color(1.0, 0.28, 0.18))
	draw_rect(Rect2(pos + Vector2(138, 0), Vector2(138, 78)), Color(1.0, 0.62, 0.18))
	draw_text_center("FLAPPY KART", Rect2(pos.x, pos.y + 20, 276, 34), scale, WHITE)


func draw_text_center(text, rect, scale, color):
	var width = text_width(text, scale)
	var x = rect.position.x + (rect.size.x - width) * 0.5
	var y = rect.position.y + (rect.size.y - 7 * scale) * 0.5
	draw_word(text, Vector2(x, y), scale, color)


func draw_word(text, pos, scale, color):
	var x = pos.x
	for i in range(text.length()):
		var ch = text.substr(i, 1).to_upper()
		if not GLYPHS.has(ch):
			ch = "?"
		var rows = GLYPHS[ch]
		for row in range(rows.size()):
			for col in range(rows[row].length()):
				if rows[row].substr(col, 1) == "1":
					draw_rect(Rect2(x + col * scale, pos.y + row * scale, scale, scale), color)
		x += (rows[0].length() + 1) * scale


func text_width(text, scale):
	var w = 0
	for i in range(text.length()):
		var ch = text.substr(i, 1).to_upper()
		if not GLYPHS.has(ch):
			ch = "?"
		w += (GLYPHS[ch][0].length() + 1) * scale
	return max(0, w - scale)


func ordinal(v):
	if v == 1:
		return "1ST"
	if v == 2:
		return "2ND"
	if v == 3:
		return "3RD"
	return "4TH"


func exit_ad():
	if Engine.has_singleton("JavaScript"):
		var js = Engine.get_singleton("JavaScript")
		js.eval("if (typeof ExitApi !== 'undefined') { ExitApi.exit(); } else { window.open('" + STORE_URL + "', '_blank'); }")
