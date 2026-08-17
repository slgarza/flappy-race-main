extends Control

const VIEW := Vector2(360, 640)
const PLAY_SECONDS := 20.0
const GRAVITY := 980.0
const FLAP := -355.0
const RACE_DISTANCE := 3400.0
const STORE_URL := "https://play.google.com/store/apps/details?id=com.slgdeveloper.flappyrace"

const BLUE := Color(0.33, 0.72, 0.91)
const DEEP := Color(0.10, 0.21, 0.31)
const SHADOW := Color(0.05, 0.18, 0.27, 0.55)
const YELLOW := Color(1.0, 0.80, 0.17)
const PINK := Color(0.95, 0.33, 0.44)
const GREEN := Color(0.19, 0.45, 0.34)

var logo := preload("res://assets/flappy_race_logo.png")
var player_tex := preload("res://assets/player.png")
var cloud_1 := preload("res://assets/cloudLayer1.png")
var cloud_2 := preload("res://assets/cloudLayer2.png")
var hills := preload("res://assets/hillsLarge.png")
var wall_tex := preload("res://assets/wall.png")
var coin_tex := preload("res://assets/gold.png")
var item_tex := preload("res://assets/item_box.png")
var boost_tex := preload("res://assets/boost.png")
var flomb_tex := preload("res://assets/flomb.png")
var laser_tex := preload("res://assets/laser.png")
var finish_tex := preload("res://assets/finish_line.png")
var font_data := preload("res://assets/Roboto-Regular.ttf")

var font_big := DynamicFont.new()
var font_mid := DynamicFont.new()
var font_small := DynamicFont.new()
var font_button := DynamicFont.new()

var state := "intro"
var game_time := 0.0
var finished_at := 0.0
var pulse := 0.0
var shake := 0.0
var scroll := 0.0
var speed := 165.0
var score := 0
var coins := 0
var final_place := 4
var finish_x := 560.0
var item_name := ""
var item_flash := 0.0
var boost_time := 0.0
var laser_time := 0.0
var flomb_time := 0.0

var bird := {
	"x": 92.0,
	"y": 300.0,
	"vy": 0.0,
	"rot": 0.0,
	"progress": 0.0,
	"hit": 0.0
}

var rivals := []
var obstacles := []
var pickups := []
var particles := []
var beams := []
var clouds := []
var next_obstacle := 1.0
var next_pickup := 1.4
var next_item := 3.4
var power_index := 0
var draw_origin := Vector2.ZERO
var draw_zoom := 1.0


func _ready() -> void:
	randomize()
	set_process(true)
	set_process_input(true)
	rect_min_size = VIEW
	font_big.font_data = font_data
	font_big.size = 48
	font_big.outline_size = 4
	font_big.outline_color = SHADOW
	font_mid.font_data = font_data
	font_mid.size = 31
	font_mid.outline_size = 3
	font_mid.outline_color = SHADOW
	font_small.font_data = font_data
	font_small.size = 18
	font_small.outline_size = 2
	font_small.outline_color = SHADOW
	font_button.font_data = font_data
	font_button.size = 26
	font_button.outline_size = 0
	font_button.outline_color = Color(0, 0, 0, 0)
	reset_race()
	state = "intro"


func _input(event: InputEvent) -> void:
	var pressed = false
	if event is InputEventMouseButton and event.pressed and event.button_index == BUTTON_LEFT:
		pressed = true
	elif event is InputEventScreenTouch and event.pressed:
		pressed = true
	elif event.is_action_pressed("ui_accept"):
		pressed = true

	if not pressed:
		return
	get_tree().set_input_as_handled()
	if state == "intro":
		start_race()
	elif state == "play":
		flap()
	elif state == "end":
		exit_ad()


func reset_race() -> void:
	game_time = 0.0
	finished_at = 0.0
	scroll = 0.0
	speed = 165.0
	score = 0
	coins = 0
	final_place = 4
	finish_x = 560.0
	item_name = ""
	item_flash = 0.0
	boost_time = 0.0
	laser_time = 0.0
	flomb_time = 0.0
	next_obstacle = 1.0
	next_pickup = 1.4
	next_item = 3.4
	power_index = 0
	bird = {"x": 92.0, "y": 300.0, "vy": 0.0, "rot": 0.0, "progress": 0.0, "hit": 0.0}
	obstacles.clear()
	pickups.clear()
	particles.clear()
	beams.clear()
	clouds = [
		{"x": 28.0, "y": 82.0, "speed": 14.0, "tex": cloud_2, "scale": 0.34},
		{"x": 205.0, "y": 150.0, "speed": 20.0, "tex": cloud_1, "scale": 0.28},
		{"x": -70.0, "y": 246.0, "speed": 24.0, "tex": cloud_2, "scale": 0.24}
	]
	rivals = [
		{"x": 54.0, "y": 238.0, "progress": 150.0, "phase": 0.4, "color": Color(0.21, 0.82, 1.0), "hit": 0.0},
		{"x": 42.0, "y": 360.0, "progress": 70.0, "phase": 2.0, "color": Color(1.0, 0.88, 0.17), "hit": 0.0},
		{"x": 60.0, "y": 452.0, "progress": 230.0, "phase": 3.7, "color": Color(0.59, 0.40, 1.0), "hit": 0.0}
	]


func start_race() -> void:
	reset_race()
	state = "play"
	flap()


func flap() -> void:
	bird.vy = FLAP
	bird.rot = -0.38
	add_particles(Vector2(bird.x - 20.0, bird.y + 13.0), YELLOW, 5)


func _process(delta: float) -> void:
	pulse += delta
	if shake > 0.0:
		shake = max(0.0, shake - delta * 5.0)
	if item_flash > 0.0:
		item_flash = max(0.0, item_flash - delta)
	if state == "play":
		update_game(delta)
	elif state == "end":
		finished_at += delta
	update_particles(delta)
	update()


func update_game(delta: float) -> void:
	game_time += delta
	var race_t = clamp(game_time / PLAY_SECONDS, 0.0, 1.0)
	var pace = lerp(1.0, 1.22, race_t)
	if boost_time > 0.0:
		boost_time = max(0.0, boost_time - delta)
	if laser_time > 0.0:
		laser_time = max(0.0, laser_time - delta)
	if flomb_time > 0.0:
		flomb_time = max(0.0, flomb_time - delta)

	speed = 165.0 * pace
	if boost_time > 0.0:
		speed += 90.0
	scroll += speed * delta
	bird.progress = min(RACE_DISTANCE, bird.progress + speed * delta)
	bird.vy = min(760.0, bird.vy + GRAVITY * delta)
	bird.y = clamp(bird.y + bird.vy * delta, 86.0, 548.0)
	bird.rot = clamp(lerp(bird.rot, bird.vy / 720.0, 0.12), -0.45, 0.75)
	if bird.y > 534.0:
		bird.vy = -210.0
		bird.hit = 0.2

	for cloud in clouds:
		cloud.x -= cloud.speed * delta
		if cloud.x < -150.0:
			cloud.x = VIEW.x + rand_range(10.0, 90.0)
			cloud.y = rand_range(70.0, 255.0)

	next_obstacle -= delta
	if next_obstacle <= 0.0:
		spawn_obstacle()
		next_obstacle = rand_range(1.55, 2.05)

	next_pickup -= delta
	if next_pickup <= 0.0:
		spawn_coins()
		next_pickup = rand_range(1.3, 1.8)

	next_item -= delta
	if next_item <= 0.0:
		spawn_item()
		next_item = 4.1

	update_objects(delta)
	update_rivals(delta)
	update_place()

	if game_time >= PLAY_SECONDS or bird.progress >= RACE_DISTANCE:
		state = "end"
		finished_at = 0.0


func spawn_obstacle() -> void:
	var gap_y = rand_range(170.0, 430.0)
	obstacles.append({"x": VIEW.x + 42.0, "gap": gap_y, "passed": false})


func spawn_coins() -> void:
	var base_y = rand_range(160.0, 460.0)
	for i in range(4):
		pickups.append({"x": VIEW.x + 34.0 + i * 36.0, "y": base_y + sin(i * 1.2) * 22.0, "kind": "coin", "taken": false})


func spawn_item() -> void:
	pickups.append({"x": VIEW.x + 70.0, "y": rand_range(170.0, 430.0), "kind": "item", "taken": false})


func update_objects(delta: float) -> void:
	for obs in obstacles:
		obs.x -= speed * delta
		if not obs.passed and obs.x < bird.x - 18.0:
			obs.passed = true
			score += 1
		if abs(obs.x - bird.x) < 34.0 and (bird.y < obs.gap - 78.0 or bird.y > obs.gap + 78.0):
			hit_bird()

	for pickup in pickups:
		pickup.x -= speed * delta
		var dist = Vector2(pickup.x, pickup.y).distance_to(Vector2(bird.x, bird.y))
		if not pickup.taken and dist < 34.0:
			pickup.taken = true
			if pickup.kind == "coin":
				coins += 1
				add_particles(Vector2(pickup.x, pickup.y), YELLOW, 7)
			else:
				use_next_powerup()

	for beam in beams:
		beam.life -= delta
		beam.x -= speed * 0.5 * delta

	for i in range(obstacles.size() - 1, -1, -1):
		if obstacles[i].x < -90.0:
			obstacles.remove(i)
	for i in range(pickups.size() - 1, -1, -1):
		if pickups[i].x < -60.0 or pickups[i].taken:
			pickups.remove(i)
	for i in range(beams.size() - 1, -1, -1):
		if beams[i].life <= 0.0:
			beams.remove(i)


func use_next_powerup() -> void:
	var powers = ["boost", "laser", "flomb"]
	item_name = powers[power_index % powers.size()]
	power_index += 1
	item_flash = 1.0
	if item_name == "boost":
		boost_time = 1.6
		add_particles(Vector2(bird.x - 12.0, bird.y), Color(1.0, 0.82, 0.15), 12)
	elif item_name == "laser":
		laser_time = 0.8
		beams.append({"x": bird.x + 28.0, "y": bird.y - 3.0, "life": 0.35})
		if rivals.size() > 0:
			rivals[0].hit = 0.8
	elif item_name == "flomb":
		flomb_time = 1.0
		shake = 0.45
		for rival in rivals:
			rival.hit = max(rival.hit, 0.55)


func hit_bird() -> void:
	if bird.hit > 0.0:
		return
	bird.hit = 0.7
	bird.vy = -230.0
	shake = 0.35
	coins = max(0, coins - 2)
	add_particles(Vector2(bird.x, bird.y), Color(1.0, 1.0, 1.0), 10)


func update_rivals(delta: float) -> void:
	for i in range(rivals.size()):
		var rival = rivals[i]
		rival.hit = max(0.0, rival.hit - delta)
		var rival_speed = 150.0 + i * 13.0
		if rival.hit > 0.0:
			rival_speed *= 0.42
		rival.progress += rival_speed * delta
		rival.x = 64.0 + (rival.progress - bird.progress) * 0.13
		rival.y = 240.0 + i * 92.0 + sin(game_time * 2.4 + rival.phase) * 42.0


func update_place() -> void:
	var place = 1
	for rival in rivals:
		if rival.progress > bird.progress:
			place += 1
	final_place = clamp(place, 1, 4)


func update_particles(delta: float) -> void:
	for p in particles:
		p.pos += p.vel * delta
		p.vel.y += 440.0 * delta
		p.life -= delta
	for i in range(particles.size() - 1, -1, -1):
		if particles[i].life <= 0.0:
			particles.remove(i)


func add_particles(pos: Vector2, color: Color, amount: int) -> void:
	for _i in range(amount):
		particles.append({
			"pos": pos + Vector2(rand_range(-6.0, 6.0), rand_range(-6.0, 6.0)),
			"vel": Vector2(rand_range(-130.0, 50.0), rand_range(-170.0, 30.0)),
			"life": rand_range(0.28, 0.62),
			"color": color
		})


func _draw() -> void:
	var canvas = get_viewport_rect().size
	var scale = max(canvas.x / VIEW.x, canvas.y / VIEW.y)
	var offset = (canvas - VIEW * scale) * 0.5
	draw_origin = offset
	draw_zoom = scale
	if shake > 0.0:
		draw_origin += Vector2(rand_range(-5.0, 5.0), rand_range(-5.0, 5.0)) * shake
	draw_set_transform(draw_origin, 0.0, Vector2(draw_zoom, draw_zoom))
	draw_world()
	if state == "intro":
		draw_intro()
	elif state == "play":
		draw_hud()
	else:
		draw_end()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func draw_world() -> void:
	draw_rect(Rect2(Vector2.ZERO, VIEW), BLUE)
	for cloud in clouds:
		draw_texture_scaled(cloud.tex, Rect2(cloud.x, cloud.y, cloud.tex.get_width() * cloud.scale, cloud.tex.get_height() * cloud.scale))

	var hill_w = 240.0
	var hill_x = -fmod(scroll * 0.18, hill_w)
	for i in range(4):
		draw_texture_scaled(hills, Rect2(hill_x + i * hill_w, 493.0, hill_w, 74.0))

	draw_rect(Rect2(0, 556, VIEW.x, 84), GREEN)
	draw_rect(Rect2(0, 552, VIEW.x, 6), Color(0.90, 0.87, 0.39))

	for obs in obstacles:
		draw_wall(obs.x, obs.gap)
	for pickup in pickups:
		if pickup.kind == "coin":
			draw_texture_centered(coin_tex, Vector2(pickup.x, pickup.y), 0.76 + sin(pulse * 8.0) * 0.05)
		else:
			draw_texture_centered(item_tex, Vector2(pickup.x, pickup.y), 0.95 + sin(pulse * 7.0) * 0.08)

	finish_x = VIEW.x + 26.0 + (RACE_DISTANCE - bird.progress) * 0.10
	if finish_x < VIEW.x + 60.0:
		draw_texture_scaled(finish_tex, Rect2(finish_x, 86, 22, 470))

	for beam in beams:
		draw_rect(Rect2(beam.x, beam.y - 4, 290, 8), Color(1.0, 0.16, 0.18, 0.82))
		draw_rect(Rect2(beam.x, beam.y - 1, 290, 2), Color(1.0, 1.0, 1.0, 0.92))

	for rival in rivals:
		draw_rival(rival)
	draw_bird()
	draw_particles()


func draw_wall(x: float, gap: float) -> void:
	var top_h = gap - 82.0
	var bottom_y = gap + 82.0
	var tile_h = 54.0
	var y = top_h - tile_h
	while y > -tile_h:
		draw_texture_scaled(wall_tex, Rect2(x - 18.0, y, 44.0, tile_h))
		y -= tile_h
	y = bottom_y
	while y < 560.0:
		draw_texture_scaled(wall_tex, Rect2(x - 18.0, y, 44.0, tile_h))
		y += tile_h


func draw_bird() -> void:
	var pos = Vector2(bird.x, bird.y)
	if boost_time > 0.0:
		draw_rect(Rect2(pos.x - 62.0, pos.y - 8.0, 42.0, 16.0), Color(1.0, 0.72, 0.10, 0.8))
	if flomb_time > 0.0:
		draw_texture_centered(flomb_tex, pos + Vector2(-42.0, -25.0), 1.0)
	var tint = Color(1, 1, 1, 1)
	if bird.hit > 0.0 and int(pulse * 20.0) % 2 == 0:
		tint = Color(1.0, 0.55, 0.55)
	draw_texture_rotated(player_tex, pos, 2.45, bird.rot, tint)
	if bird.hit > 0.0:
		bird.hit = max(0.0, bird.hit - get_process_delta_time())


func draw_rival(rival: Dictionary) -> void:
	var pos = Vector2(rival.x, rival.y)
	var tint: Color = rival.color
	if rival.hit > 0.0:
		tint = Color(0.8, 0.8, 0.8, 0.65)
	draw_texture_rotated(player_tex, pos, 1.55, sin(pulse * 4.0 + rival.phase) * 0.2, tint)


func draw_particles() -> void:
	for p in particles:
		var c: Color = p.color
		c.a = clamp(p.life * 2.2, 0.0, 1.0)
		draw_circle(p.pos, 3.0 + p.life * 3.0, c)


func draw_hud() -> void:
	draw_rect(Rect2(12, 12, 126, 32), Color(0.05, 0.18, 0.27, 0.62))
	draw_text_center(font_small, "PLACE " + str(final_place) + "/4", Rect2(12, 18, 126, 24), Color.white)
	draw_rect(Rect2(150, 14, 196, 12), Color(0.05, 0.18, 0.27, 0.52))
	draw_rect(Rect2(152, 16, 192 * clamp(game_time / PLAY_SECONDS, 0.0, 1.0), 8), YELLOW)
	draw_text_center(font_small, "COINS " + str(coins), Rect2(240, 32, 104, 24), Color.white)
	if item_flash > 0.0:
		var r = Rect2(88, 70, 184, 54)
		draw_rect(r, Color(1, 1, 1, 0.92))
		var tex = boost_tex
		if item_name == "laser":
			tex = laser_tex
		elif item_name == "flomb":
			tex = flomb_tex
		draw_texture_centered(tex, Vector2(128, 97), 1.0)
		draw_text_center(font_small, item_name.to_upper(), Rect2(152, 83, 96, 28), DEEP)


func draw_intro() -> void:
	draw_rect(Rect2(Vector2.ZERO, VIEW), Color(0.03, 0.14, 0.21, 0.25))
	draw_texture_scaled(logo, Rect2(31, 56, 298, 86))
	draw_bird()
	draw_text_center(font_big, "TAP TO PLAY", Rect2(0, 238, VIEW.x, 62), Color.white)
	draw_text_center(font_small, "race, flap, grab power-ups", Rect2(0, 304, VIEW.x, 34), YELLOW)
	var ring = 34.0 + sin(pulse * 5.2) * 3.0
	draw_circle(Vector2(180, 400), ring, Color(1, 1, 1, 0.20))
	draw_circle(Vector2(180, 400), 23.0, YELLOW)
	draw_text_center(font_small, "TAP", Rect2(140, 390, 80, 24), DEEP)


func draw_end() -> void:
	draw_rect(Rect2(Vector2.ZERO, VIEW), Color(0.05, 0.19, 0.27, 0.72))
	draw_texture_scaled(logo, Rect2(31, 58, 298, 86))
	draw_text_center(font_big, "Nice flight!", Rect2(0, 182, VIEW.x, 62), Color.white)
	draw_text_center(font_mid, "You finished " + ordinal(final_place), Rect2(0, 254, VIEW.x, 46), YELLOW)
	draw_text_center(font_small, "Can you take 1st place?", Rect2(0, 312, VIEW.x, 36), Color.white)
	draw_rect(Rect2(26, 368, 308, 78), Color(1, 1, 1, 0.96))
	draw_text_center(font_mid, "MULTIPLAYER", Rect2(38, 382, 284, 34), DEEP)
	draw_text_center(font_mid, "POWER-UPS + RACES", Rect2(24, 414, 312, 36), PINK)
	draw_text_center(font_small, "Install and race for 1st", Rect2(0, 488, VIEW.x, 32), Color.white)
	var btn = Rect2(56, 532, 248, 58)
	draw_rect(btn.grow(0), Color(0.77, 0.50, 0.08))
	draw_rect(Rect2(btn.position, btn.size - Vector2(0, 7)), YELLOW)
	draw_text_center(font_button, "INSTALL FREE", Rect2(btn.position.x, btn.position.y + 12, btn.size.x, 34), DEEP)


func draw_texture_centered(tex: Texture, pos: Vector2, scale: float, tint: Color = Color.white) -> void:
	var size = Vector2(tex.get_width(), tex.get_height()) * scale
	draw_texture_rect(tex, Rect2(pos - size * 0.5, size), false, tint)


func draw_texture_scaled(tex: Texture, rect: Rect2, tint: Color = Color.white) -> void:
	draw_texture_rect(tex, rect, false, tint)


func draw_texture_rotated(tex: Texture, pos: Vector2, scale: float, angle: float, tint: Color = Color.white) -> void:
	draw_set_transform(draw_origin + pos * draw_zoom, angle, Vector2(draw_zoom * scale, draw_zoom * scale))
	draw_texture(tex, -Vector2(tex.get_width(), tex.get_height()) * 0.5, tint)
	draw_set_transform(draw_origin, 0.0, Vector2(draw_zoom, draw_zoom))


func draw_text_center(font: Font, text: String, rect: Rect2, color: Color) -> void:
	var size = font.get_string_size(text)
	var pos = rect.position + Vector2((rect.size.x - size.x) * 0.5, (rect.size.y + size.y) * 0.5 - 4.0)
	font.draw(get_canvas_item(), pos, text, color)


func ordinal(value: int) -> String:
	if value == 1:
		return "1st"
	if value == 2:
		return "2nd"
	if value == 3:
		return "3rd"
	return "4th"


func exit_ad() -> void:
	if Engine.has_singleton("JavaScript"):
		var js = Engine.get_singleton("JavaScript")
		js.eval("if (typeof ExitApi !== 'undefined') { ExitApi.exit(); } else { window.open('" + STORE_URL + "', '_blank'); }")
