extends Node

const DISPLAY_FONT_DATA := preload("res://client/fonts/DelaGothicOne-Regular.ttf")
const BODY_FONT_DATA := preload("res://client/fonts/Roboto-Regular.ttf")

const SAFE_MARGIN := 56
const IOS_SAFE_MARGIN := 92
const BUTTON_HEIGHT := 112
const PRIMARY_BUTTON_HEIGHT := 124
const INPUT_HEIGHT := 104
const ICON_BUTTON_SIZE := 112
const BODY_FONT_SIZE := 36
const INPUT_FONT_SIZE := 42
const BUTTON_FONT_SIZE := 48
const HEADER_FONT_SIZE := 58
const TITLE_FONT_SIZE := 76
const TOGGLE_ON_ICON := preload("res://client/menu/setup/multiplayer/confirmed.png")
const TOGGLE_OFF_ICON := preload("res://client/menu/setup/multiplayer/cancel.png")

var _font_cache := {}
var _spinbox_up_texture: ImageTexture = null
var _spinbox_down_texture: ImageTexture = null
var _spinbox_blank_texture: ImageTexture = null


func is_mobile() -> bool:
	if OS.get_name() == "Android" or OS.get_name() == "iOS":
		return true
	return OS.get_cmdline_args().has("--mobile-ui")


func is_ios() -> bool:
	return OS.get_name() == "iOS"


func adapt_title_screen(root) -> void:
	if not is_mobile():
		return
	var menu = _node(root, "Menu")
	if menu:
		_fill_parent_with_margin(menu, SAFE_MARGIN)
	var logo = _node(root, "Menu/Logo")
	if logo:
		if is_ios():
			_center_rect(logo, Vector2(760, 220), Vector2(47, -405))
			logo.rect_min_size = Vector2(760, 220)
		else:
			logo.margin_bottom = 170
	var buttons = _node(root, "Menu/Buttons")
	if buttons:
		_center_rect(buttons, Vector2(700, 800), Vector2(0, 78))
		buttons.rect_min_size = Vector2(700, 0)
		buttons.add_constant_override("separation", 20)
		for button in buttons.get_children():
			_apply_button_style(button, 104, 42, 700)
	var version = _node(root, "Menu/VersionLabel")
	_apply_label_style(version, 34, false)
	if version:
		version.margin_top = -48
		version.margin_right = 180
	var dev = _node(root, "Menu/DevLabel")
	_apply_label_style(dev, 34, false)
	if dev:
		dev.margin_left = -250
		dev.margin_top = -48


func adapt_standard_menu(root) -> void:
	if not is_mobile():
		return
	_adapt_text_tree(root, BODY_FONT_SIZE, BUTTON_FONT_SIZE, HEADER_FONT_SIZE)
	_adapt_title_label(_node(root, "VBoxContainer/Title"))
	var menu = _node(root, "VBoxContainer/Menu")
	if menu:
		_fill_parent(menu)
	var info = _node(root, "VBoxContainer/Menu/HostingInfoLabel")
	_apply_label_style(info, BODY_FONT_SIZE, true)
	if info:
		_center_top_rect(info, 1280, 220, 18)
	var buttons = _node(root, "VBoxContainer/Menu/CenterContainer/ButtonContainer")
	if buttons:
		buttons.rect_min_size = Vector2(1060, 0)
		buttons.add_constant_override("separation", 40)
		_set_children_horizontal_size_flags(buttons, Control.SIZE_EXPAND_FILL)
	for path in [
		"VBoxContainer/Menu/CenterContainer/ButtonContainer/NameContainer",
		"VBoxContainer/Menu/CenterContainer/ButtonContainer/ServerNameContainer",
		"VBoxContainer/Menu/CenterContainer/ButtonContainer/HostOptionsContainer"
	]:
		var row = _node(root, path)
		if row:
			row.rect_min_size = Vector2(1060, INPUT_HEIGHT)
			row.add_constant_override("separation", 36)
			_apply_row_labels(row, BUTTON_FONT_SIZE)
			_apply_row_inputs(row, INPUT_HEIGHT, INPUT_FONT_SIZE, 640)
	var toggle_row = _node(root, "VBoxContainer/Menu/CenterContainer/ButtonContainer/HBoxContainer")
	if toggle_row:
		toggle_row.rect_min_size = Vector2(0, 86)
		toggle_row.add_constant_override("separation", 44)
		for child in toggle_row.get_children():
			_apply_button_style(child, 86, BODY_FONT_SIZE)
	for path in [
		"VBoxContainer/Menu/CenterContainer/ButtonContainer/NextButton",
		"VBoxContainer/Menu/CenterContainer/ButtonContainer/CreateButton",
		"VBoxContainer/Menu/CenterContainer/ButtonContainer/HostButton"
	]:
		_apply_button_style(_node(root, path), PRIMARY_BUTTON_HEIGHT, BUTTON_FONT_SIZE, 1060)
	for path in ["VBoxContainer/Menu/ErrorMessage", "VBoxContainer/Menu/InfoMessage"]:
		var message = _node(root, path)
		_apply_label_style(message, 40, true)
		if message:
			message.margin_top = -96
			message.margin_bottom = 0
	_adapt_back_button(_node(root, "VBoxContainer/Menu/BackButton"))


func adapt_server_browser(root) -> void:
	if not is_mobile():
		return
	_adapt_text_tree(root, BODY_FONT_SIZE, 42, HEADER_FONT_SIZE)
	_adapt_title_label(_node(root, "Title"))
	var panel = _node(root, "Panel")
	if panel:
		panel.anchor_left = 0.035
		panel.anchor_top = 0.14
		panel.anchor_right = 0.965
		panel.anchor_bottom = 0.84
		panel.rect_min_size = Vector2(1280, 620)
	var header_row = _node(root, "Panel/ServerListContainer/Control")
	if header_row:
		header_row.rect_min_size = Vector2(0, 96)
	var header = _node(root, "Panel/ServerListContainer/Control/ServerListHeader")
	if header:
		header.add_constant_override("separation", 20)
	var name_header = _node(root, "Panel/ServerListContainer/Control/ServerListHeader/Label")
	_apply_label_style(name_header, 40, false)
	if name_header:
		name_header.rect_min_size = Vector2(900, 0)
	var players_header = _node(root, "Panel/ServerListContainer/Control/ServerListHeader/Label2")
	_apply_label_style(players_header, 40, false)
	if players_header:
		players_header.rect_min_size = Vector2(280, 0)
	_apply_button_style(_node(root, "Panel/ServerListContainer/Control/RefreshButton"), 92, 38, 230)
	var entries = _node(root, "Panel/ServerListContainer/ServerListEntries")
	if entries:
		entries.add_constant_override("separation", 8)
	var bottom_buttons = _node(root, "Panel/CenterContainer2/ButtonContainer")
	if bottom_buttons:
		bottom_buttons.rect_min_size = Vector2(980, 96)
		bottom_buttons.add_constant_override("separation", 24)
		for child in bottom_buttons.get_children():
			_apply_button_style(child, 96, 38, 300)
	var self_host = _node(root, "Panel/CenterContainer2/ButtonContainer/SelfHostButton")
	if self_host and OS.get_name() == "Android":
		self_host.hide()
	for path in ["Panel/CenterContainer/InfoMessage", "Panel/CenterContainer/ErrorMessage"]:
		var message = _node(root, path)
		_apply_label_style(message, 48, true)
		if message:
			message.rect_min_size = Vector2(1080, 130)
			message.align = Label.ALIGN_CENTER
			message.valign = Label.VALIGN_CENTER
	_adapt_back_button(_node(root, "Footer/BackButton"))


func adapt_server_entry(root) -> void:
	if not is_mobile():
		return
	root.rect_min_size = Vector2(0, 92)
	var name_label = _node(root, "Hbox/Name")
	_apply_label_style(name_label, 38, false)
	if name_label:
		name_label.rect_min_size = Vector2(900, 0)
		name_label.clip_text = true
	var players = _node(root, "Hbox/Players")
	_apply_label_style(players, 38, false)
	if players:
		players.rect_min_size = Vector2(260, 0)
	_apply_button_style(_node(root, "JoinButton"), 86, 36, 220)


func adapt_join_panel(panel) -> void:
	if not is_mobile():
		return
	panel.rect_min_size = Vector2(920, 380)
	_center_rect(panel, panel.rect_min_size)
	var margin = _node(panel, "MarginContainer")
	if margin:
		_fill_parent_with_margin(margin, 32)
		margin.add_constant_override("margin_left", 32)
		margin.add_constant_override("margin_top", 32)
		margin.add_constant_override("margin_right", 32)
		margin.add_constant_override("margin_bottom", 32)
	var vbox = _node(panel, "MarginContainer/VBoxContainer")
	if vbox:
		vbox.add_constant_override("separation", 28)
	var input_row = _node(panel, "MarginContainer/VBoxContainer/IpContainer")
	if input_row:
		input_row.rect_min_size = Vector2(0, INPUT_HEIGHT)
		input_row.add_constant_override("separation", 28)
	_apply_line_edit(_node(panel, "MarginContainer/VBoxContainer/IpContainer/IpInput"), INPUT_HEIGHT, INPUT_FONT_SIZE, 600)
	_apply_button_style(_node(panel, "MarginContainer/VBoxContainer/IpContainer/JoinButton"), INPUT_HEIGHT, BUTTON_FONT_SIZE, 220)
	_apply_label_style(_node(panel, "MarginContainer/VBoxContainer/ErrorMessage"), 40, true)
	_apply_label_style(_node(panel, "MarginContainer/VBoxContainer/InfoMessage"), 40, true)


func adapt_options(root) -> void:
	if not is_mobile():
		return
	_adapt_text_tree(root, BODY_FONT_SIZE, 40, HEADER_FONT_SIZE)
	_adapt_title_label(_node(root, "Title"))
	var graphics = _node(root, "CenterContainer/GridContainer/Graphics")
	if graphics:
		graphics.hide()
	var grid = _node(root, "CenterContainer/GridContainer")
	if grid:
		grid.columns = 2
		grid.rect_min_size = Vector2(1220, 440)
		grid.add_constant_override("hseparation", 90)
		grid.add_constant_override("vseparation", 44)
	for section_path in [
		"CenterContainer/GridContainer/Volume",
		"CenterContainer/GridContainer/Gameplay"
	]:
		var section = _node(root, section_path)
		if section:
			section.rect_min_size = Vector2(560, 0)
			section.add_constant_override("separation", 28)
			_apply_label_style(_node(section, "Header"), HEADER_FONT_SIZE, false)
	for row_path in [
		"CenterContainer/GridContainer/Volume/MasterVolume",
		"CenterContainer/GridContainer/Volume/MusicVolume",
		"CenterContainer/GridContainer/Volume/SoundsVolume"
	]:
		_adapt_volume_row(_node(root, row_path))
	var gameplay_box = _node(root, "CenterContainer/GridContainer/Gameplay/VBoxContainer")
	if gameplay_box:
		gameplay_box.add_constant_override("separation", 24)
		var row = _node(gameplay_box, "HBoxContainer")
		if row:
			row.rect_min_size = Vector2(0, 48)
	_apply_button_style(_node(root, "CenterContainer/GridContainer/Gameplay/VBoxContainer/ResetHighScoreButton"), 86, 34, 560)
	_apply_button_style(_node(root, "CenterContainer/GridContainer/Gameplay/VBoxContainer/RestorePurchasesButton"), 86, 34, 560)
	_adapt_back_button(_node(root, "BackButton"))
	var reset = _node(root, "ResetButton")
	_apply_button_style(reset, BUTTON_HEIGHT, BUTTON_FONT_SIZE, 360)
	if reset:
		_bottom_center_rect(reset, 360, BUTTON_HEIGHT)


func adapt_credits(root) -> void:
	if not is_mobile():
		return
	_adapt_title_label(_node(root, "Title"))
	var panel = _node(root, "Panel")
	if panel:
		panel.anchor_left = 0.06
		panel.anchor_top = 0.15
		panel.anchor_right = 0.94
		panel.anchor_bottom = 0.84
	var scroll = _node(root, "Panel/ScrollContainer")
	if scroll:
		_fill_parent_with_margin(scroll, 38)
	var credits_text = _node(root, "Panel/ScrollContainer/CreditsText")
	_apply_label_style(credits_text, 34, true, true)
	if credits_text:
		credits_text.rect_min_size = Vector2(1500, 0)
	_adapt_back_button(_node(root, "BackButton"))


func adapt_setup(root) -> void:
	if not is_mobile():
		return
	var safe_margin := _safe_margin()
	_adapt_text_tree(root, 34, 42, HEADER_FONT_SIZE)
	_adapt_title_label(_node(root, "Title"))
	_adapt_back_button(_node(root, "BackButton"))
	for path in ["StartButton", "ReadyButton"]:
		var button = _node(root, path)
		_apply_button_style(button, PRIMARY_BUTTON_HEIGHT, 52, 460)
		if button:
			_bottom_center_rect(button, 460, PRIMARY_BUTTON_HEIGHT)
	if is_ios():
		for path in ["StartButton", "ReadyButton"]:
			var bottom_button = _node(root, path)
			if bottom_button:
				bottom_button.margin_top += 34
				bottom_button.margin_bottom += 34
		var back_button = _node(root, "BackButton")
		if back_button:
			_apply_button_style(back_button, 82, 36, 260)
			back_button.anchor_left = 0
			back_button.anchor_top = 1
			back_button.anchor_right = 0
			back_button.anchor_bottom = 1
			back_button.margin_left = safe_margin + 120
			back_button.margin_top = -112
			back_button.margin_right = safe_margin + 380
			back_button.margin_bottom = -30
			back_button.rect_min_size = Vector2(260, 82)
	var player_control = _node(root, "PlayerOptions/Control")
	if player_control:
		player_control.margin_top = 40
		player_control.margin_bottom = 40
	var player = _node(root, "PlayerOptions/Control/Player")
	if player:
		player.position = Vector2(0, -190)
	var colour_selector = _node(root, "PlayerOptions/Control/ColourSelector")
	_adapt_colour_selector(colour_selector)
	var player_list = _node(root, "PlayerList")
	if player_list:
		player_list.margin_left = -650 - safe_margin
		player_list.margin_right = -safe_margin
		player_list.rect_min_size = Vector2(630, 0)
		player_list.add_constant_override("separation", 8)
		for entry in player_list.get_children():
			if entry.visible:
				adapt_player_entry(entry)
	var info = _node(root, "InfoMessage")
	_apply_label_style(info, 42, true)
	if info:
		info.margin_top = 118
		info.margin_bottom = 178
	var spectator_text = _node(root, "SpectatorText")
	_apply_label_style(spectator_text, 44, true)
	_adapt_game_id_info(_node(root, "GameIdInfo"))
	adapt_setup_spectate_button(root, false)
	var game_options = _node(root, "GameOptions")
	if game_options:
		adapt_game_options(game_options)
	var back_button = _node(root, "BackButton")
	if back_button:
		back_button.raise()


func adapt_setup_spectate_button(root, is_spectating: bool) -> void:
	if not is_mobile():
		return
	var button = _node(root, "SpectateButton")
	_apply_button_style(button, 96, 38, 360)
	if button:
		if is_spectating:
			_center_rect(button, Vector2(360, 96), Vector2(0, 90))
		else:
			_center_rect(button, Vector2(360, 96), Vector2(0, 260))


func _adapt_game_id_info(root) -> void:
	if not root:
		return
	var header = _node(root, "Header")
	_apply_label_style(header, 40, false)
	if header:
		header.margin_right = 300
		header.margin_bottom = 70
	var buttons = _node(root, "ButtonContainer")
	if buttons:
		buttons.margin_top = 78
		buttons.margin_right = 330
		buttons.margin_bottom = 174
		buttons.rect_min_size = Vector2(330, 96)
		buttons.add_constant_override("separation", 16)
		for button in buttons.get_children():
			_apply_button_style(button, 96, 34, 154)
	var game_id = _node(root, "GameId")
	_apply_label_style(game_id, 34, false)
	if game_id:
		game_id.margin_left = 360
		game_id.margin_top = 78
		game_id.margin_right = 840
		game_id.margin_bottom = 174
		game_id.rect_min_size = Vector2(480, 96)
		game_id.align = Label.ALIGN_CENTER
		game_id.valign = Label.VALIGN_CENTER
	var message = _node(root, "MessageLabel")
	_apply_label_style(message, 32, false)
	if message:
		message.margin_left = 870
		message.margin_top = 108
		message.margin_right = 1040
		message.margin_bottom = 156


func adapt_game_options(root) -> void:
	if not is_mobile():
		return
	var safe_margin := _safe_margin()
	root.margin_left = safe_margin
	root.margin_top = -330
	root.margin_right = safe_margin + 670
	root.margin_bottom = 374
	root.rect_min_size = Vector2(670, 750)
	var header = _node(root, "Header")
	_apply_label_style(header, 36, false)
	if header:
		header.margin_bottom = 62
	var vbox = _node(root, "Panel/VBoxContainer")
	if vbox:
		vbox.margin_top = 72
		vbox.add_constant_override("separation", 10)
	for row in _collect_rows(vbox):
		row.rect_min_size = Vector2(0, 92)
		row.add_constant_override("separation", 22)
		_apply_row_labels(row, 32)
		_apply_row_inputs(row, 92, 32, 92)
	var difficulty = _node(root, "Panel/VBoxContainer/BotDifficulty/Difficulty")
	_apply_spin_box(difficulty, 92, 30, 330)
	if difficulty:
		difficulty.rect_min_size = Vector2(330, 92)
	var item_menu = _node(root, "Panel/VBoxContainer/ItemMenu")
	_apply_button_style(item_menu, 88, 32, 320)
	if item_menu:
		item_menu.rect_min_size = Vector2(320, 92)
		_adapt_item_menu_popup(item_menu)
	var overlay = _node(root, "Panel/DisableGameOptions")
	if overlay:
		_fill_parent(overlay)


func adapt_player_entry(entry) -> void:
	if not is_mobile():
		return
	entry.rect_min_size = Vector2(0, 82)
	entry.add_constant_override("separation", 12)
	var name_label = _node(entry, "Name")
	_apply_label_style(name_label, 26, true)
	if name_label:
		name_label.rect_min_size = Vector2(350, 78)
	for path in [
		"HostPlaceholder",
		"PlayerIcon",
		"SpectateIcon",
		"BotIcon",
		"HostIcon",
		"ReadyIcon"
	]:
		var control = _node(entry, path)
		if control:
			control.rect_min_size = Vector2(72, 72)
	for path in ["HostPlaceholder/Promote", "HostPlaceholder/Kick"]:
		_apply_button_style(_node(entry, path), 72, 24, 72)


func adapt_pause_menu(panel) -> void:
	if not is_mobile():
		return
	var visible_buttons := 0
	var vbox = _node(panel, "VBoxContainer")
	if vbox:
		for child in vbox.get_children():
			if child.visible:
				visible_buttons += 1
	var panel_height = max(320, 36 + visible_buttons * BUTTON_HEIGHT + max(0, visible_buttons - 1) * 18)
	panel.rect_min_size = Vector2(660, panel_height)
	_center_rect(panel, panel.rect_min_size)
	if vbox:
		_fill_parent_with_margin(vbox, 18)
		vbox.add_constant_override("separation", 18)
		for button in vbox.get_children():
			_apply_button_style(button, BUTTON_HEIGHT, BUTTON_FONT_SIZE, 600)


func adapt_hud(ui) -> void:
	if not is_mobile():
		return
	var safe_margin := _safe_margin()
	var score = _node(ui, "Ingame/Player/Score")
	_apply_label_style(score, 60, false, true)
	if score:
		_center_top_rect(score, 320, 70, max(18, safe_margin / 2))
	var stopwatch = _node(ui, "Ingame/Stopwatch")
	_apply_label_style(stopwatch, 42, false)
	if stopwatch:
		stopwatch.margin_left = -292 - safe_margin
		stopwatch.margin_top = safe_margin
		stopwatch.margin_right = -safe_margin
		stopwatch.margin_bottom = safe_margin + 58
		stopwatch.rect_min_size = Vector2(252, 0)
		stopwatch.align = Label.ALIGN_RIGHT
	var arcade_stats = _node(ui, "Ingame/ArcadeStats")
	if arcade_stats:
		arcade_stats.margin_left = -520 - safe_margin
		arcade_stats.margin_top = safe_margin + 76
		arcade_stats.margin_right = -safe_margin
		arcade_stats.margin_bottom = safe_margin + 222
		arcade_stats.rect_min_size = Vector2(464, 0)
		arcade_stats.add_constant_override("separation", 10)
	_apply_label_style(_node(ui, "Ingame/ArcadeStats/Score"), 44, false)
	_apply_label_style(_node(ui, "Ingame/ArcadeStats/HighScore"), 40, false)
	var arcade_score = _node(ui, "Ingame/ArcadeStats/Score")
	if arcade_score:
		arcade_score.align = Label.ALIGN_RIGHT
	var arcade_high_score = _node(ui, "Ingame/ArcadeStats/HighScore")
	if arcade_high_score:
		arcade_high_score.align = Label.ALIGN_RIGHT
	var race_progress = _node(ui, "Ingame/RaceProgress")
	if race_progress:
		_center_top_rect(race_progress, 940, 64, safe_margin + 112)
	_apply_label_style(_node(ui, "Ingame/RaceProgress/ActiveProgress"), 44, false, true)
	var pause_button = _node(ui, "Ingame/PauseButton")
	if pause_button:
		_top_left_rect(pause_button, 240, 92, safe_margin, safe_margin)
		_apply_button_style(pause_button, 92, 34, 240)
	_apply_label_style(_node(ui, "Ingame/Player/Lives/LifeBar/ExtraLives"), 38, false)
	var lives = _node(ui, "Ingame/Player/Lives")
	if lives:
		lives.margin_left = safe_margin
		lives.margin_top = -178 - safe_margin
		lives.margin_bottom = -safe_margin
	var life_bar = _node(ui, "Ingame/Player/Lives/LifeBar")
	if life_bar:
		life_bar.add_constant_override("separation", 6)
	var coins = _node(ui, "Ingame/Player/Coins")
	if coins:
		coins.margin_left = -352 - safe_margin
		coins.margin_top = -164 - safe_margin
		coins.margin_right = -safe_margin
		coins.margin_bottom = -safe_margin
	_apply_label_style(_node(ui, "Ingame/Player/Coins/HBoxContainer/Coins"), 54, false, true)
	_apply_label_style(_node(ui, "Ingame/Player/Coins/CoinUpdate"), 54, false, true)
	var spectator_box = _node(ui, "Ingame/Spectator/CenterContainer/HBoxContainer")
	if spectator_box:
		spectator_box.add_constant_override("separation", 28)
	for path in [
		"Ingame/Spectator/CenterContainer/HBoxContainer/PreviousButton",
		"Ingame/Spectator/CenterContainer/HBoxContainer/NextButton"
	]:
		_apply_button_style(_node(ui, path), ICON_BUTTON_SIZE, 34, ICON_BUTTON_SIZE)
	var spectating_label = _node(ui, "Ingame/Spectator/CenterContainer/HBoxContainer/SpectatingLabel")
	_apply_label_style(spectating_label, 38, true)
	if spectating_label:
		spectating_label.rect_min_size = Vector2(340, ICON_BUTTON_SIZE)
	_adapt_leaderboard(ui)
	_adapt_loading(ui)


func adapt_arcade_game_over(ui) -> void:
	if not is_mobile():
		return
	var result = _node(ui, "Finished/ArcadeResult")
	if not result:
		return
	_fill_parent_with_margin(result, SAFE_MARGIN)
	result.add_constant_override("separation", 24)
	_apply_label_style(_node(result, "Title"), 92, true)
	_apply_label_style(_node(result, "Time"), 58, true)
	_apply_label_style(_node(result, "Score"), 58, true)
	_apply_label_style(_node(result, "HighScore"), 52, true)
	var buttons = _node(result, "Buttons")
	if buttons:
		buttons.add_constant_override("separation", 24)
		for button in buttons.get_children():
			_apply_button_style(button, 104, 38, 400)


func _adapt_leaderboard(ui) -> void:
	var leaderboard = _node(ui, "Leaderboard")
	if not leaderboard:
		return
	_apply_label_style(_node(leaderboard, "VBoxContainer/Header"), 58, false)
	var footer = _node(leaderboard, "Footer")
	if footer:
		footer.add_constant_override("separation", 28)
		for child in footer.get_children():
			_apply_button_style(child, 92, 38, 280)


func _adapt_loading(ui) -> void:
	_apply_label_style(_node(ui, "Loading/CenterContainer/VBoxContainer/LoadingHint"), 38, true)
	var progress = _node(ui, "Loading/CenterContainer/VBoxContainer/ProgressBar")
	if progress:
		progress.rect_min_size = Vector2(700, 44)


func _adapt_volume_row(row) -> void:
	if not row:
		return
	row.rect_min_size = Vector2(0, 84)
	_apply_label_style(_node(row, "Label"), 34, false)
	_apply_label_style(_node(row, "Percent"), 34, false)
	var slider = _node(row, row.name.replace("Volume", "Slider"))
	if not slider:
		for child in row.get_children():
			if child is HSlider:
				slider = child
				break
	if slider:
		slider.rect_min_size = Vector2(520, 42)
		slider.margin_left = -260
		slider.margin_top = -24
		slider.margin_right = 260


func _adapt_colour_selector(selector) -> void:
	if not selector:
		return
	selector.columns = 8
	selector.add_constant_override("hseparation", 12)
	selector.add_constant_override("vseparation", 12)
	selector.margin_left = -234
	selector.margin_top = -70
	selector.margin_right = 234
	selector.margin_bottom = 38
	for swatch in selector.get_children():
		swatch.rect_min_size = Vector2(48, 48)
		var selected = _node(swatch, "Selected")
		if selected:
			_fill_parent(selected)


func _adapt_back_button(button) -> void:
	_apply_button_style(button, BUTTON_HEIGHT, BUTTON_FONT_SIZE, 280)
	if button:
		_bottom_left_rect(button, 280, BUTTON_HEIGHT)


func _adapt_title_label(label) -> void:
	_apply_label_style(label, TITLE_FONT_SIZE, false)
	if label:
		label.margin_bottom = 112


func _adapt_text_tree(node, label_size: int, button_size: int, header_size: int) -> void:
	if node is Label:
		var size = header_size if node.name == "Header" else label_size
		_apply_label_style(node, size, node.autowrap)
	elif node is LineEdit:
		_apply_line_edit(node, INPUT_HEIGHT, INPUT_FONT_SIZE)
	elif node is SpinBox:
		_apply_spin_box(node, 64, 30)
	elif node is Button:
		_apply_button_style(node, BUTTON_HEIGHT, button_size)
	elif node is HSlider:
		node.rect_min_size = Vector2(node.rect_min_size.x, max(node.rect_min_size.y, 42))
	for child in node.get_children():
		_adapt_text_tree(child, label_size, button_size, header_size)


func _apply_button_style(control, height: int, font_size: int, width: int = 0) -> void:
	if not control:
		return
	var min_width = max(control.rect_min_size.x, width)
	if control is CheckButton:
		min_width = max(min_width, 140)
		control.rect_min_size = Vector2(min_width, max(height, 88))
	else:
		control.rect_min_size = Vector2(min_width, max(control.rect_min_size.y, height))
	control.add_font_override("font", _display_font(font_size))
	if control is Button:
		control.focus_mode = Control.FOCUS_NONE
		control.release_focus()
		control.align = 1
	if control is CheckButton:
		control.add_icon_override("on", TOGGLE_ON_ICON)
		control.add_icon_override("off", TOGGLE_OFF_ICON)
		control.add_icon_override("on_disabled", TOGGLE_ON_ICON)
		control.add_icon_override("off_disabled", TOGGLE_OFF_ICON)
	var label = _node(control, "Label")
	if label:
		_apply_label_style(label, font_size, false)


func _apply_line_edit(control, height: int, font_size: int, width: int = 0) -> void:
	if not control:
		return
	control.rect_min_size = Vector2(max(control.rect_min_size.x, width), max(control.rect_min_size.y, height))
	control.add_font_override("font", _body_font(font_size))


func _apply_spin_box(control, height: int, font_size: int, width: int = 0) -> void:
	if not control:
		return
	control.rect_min_size = Vector2(max(control.rect_min_size.x, width), max(control.rect_min_size.y, height))
	control.add_icon_override("updown", _blank_spinbox_icon())
	if control.has_method("get_line_edit"):
		var line_edit = control.get_line_edit()
		_apply_line_edit(line_edit, height, font_size, width)
		line_edit.align = LineEdit.ALIGN_CENTER


func _apply_label_style(control, font_size: int, autowrap: bool, use_body: bool = false) -> void:
	if not control:
		return
	var font = _body_font(font_size) if use_body else _display_font(font_size)
	control.add_font_override("font", font)
	if control is Label:
		control.autowrap = autowrap


func _apply_row_labels(row, font_size: int) -> void:
	for child in row.get_children():
		if child is Label:
			_apply_label_style(child, font_size, child.autowrap)


func _apply_row_inputs(row, height: int, font_size: int, width: int) -> void:
	for child in row.get_children():
		if child is LineEdit:
			_apply_line_edit(child, height, font_size, width)
		elif child is SpinBox:
			_apply_spin_box(child, height, font_size, width)
			_ensure_spinbox_stepper(child)
		elif child is Button:
			_apply_button_style(child, height, font_size, width if child is OptionButton else 0)


func _collect_rows(node) -> Array:
	var rows := []
	if not node:
		return rows
	for child in node.get_children():
		if child is HBoxContainer:
			rows.append(child)
	return rows


func _set_children_horizontal_size_flags(node, flags: int) -> void:
	if not node:
		return
	for child in node.get_children():
		if child is Control:
			child.size_flags_horizontal = flags


func _font(key: String, font_data: DynamicFontData, size: int) -> DynamicFont:
	var cache_key = "%s-%d" % [key, size]
	if _font_cache.has(cache_key):
		return _font_cache[cache_key]
	var font := DynamicFont.new()
	font.font_data = font_data
	font.size = size
	font.use_filter = true
	_font_cache[cache_key] = font
	return font


func _display_font(size: int) -> DynamicFont:
	return _font("display", DISPLAY_FONT_DATA, size)


func _body_font(size: int) -> DynamicFont:
	return _font("body", BODY_FONT_DATA, size)


func _adapt_item_menu_popup(menu_button) -> void:
	if not menu_button or not menu_button.has_method("get_popup"):
		return
	var popup = menu_button.get_popup()
	if not popup:
		return
	popup.rect_min_size = Vector2(700, 0)
	popup.max_height = 820
	popup.add_font_override("font", _display_font(38))
	popup.add_constant_override("hseparation", 24)
	popup.add_constant_override("vseparation", 18)
	popup.add_icon_override("checked", TOGGLE_ON_ICON)
	popup.add_icon_override("unchecked", TOGGLE_OFF_ICON)


func _blank_spinbox_icon() -> ImageTexture:
	if _spinbox_blank_texture:
		return _spinbox_blank_texture
	var image := Image.new()
	image.create(1, 1, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	_spinbox_blank_texture = ImageTexture.new()
	_spinbox_blank_texture.create_from_image(image, 0)
	return _spinbox_blank_texture


func _spinbox_step_icon(is_up: bool) -> ImageTexture:
	if is_up and _spinbox_up_texture:
		return _spinbox_up_texture
	if not is_up and _spinbox_down_texture:
		return _spinbox_down_texture
	var image := Image.new()
	image.create(52, 34, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	image.lock()
	if is_up:
		_draw_up_triangle(image, 28, 7, 29, 21, Color(0, 0, 0, 0.55))
		_draw_up_triangle(image, 26, 5, 27, 21, Color(1, 1, 1, 1))
	else:
		_draw_down_triangle(image, 28, 7, 29, 21, Color(0, 0, 0, 0.55))
		_draw_down_triangle(image, 26, 5, 27, 21, Color(1, 1, 1, 1))
	image.unlock()
	var texture := ImageTexture.new()
	texture.create_from_image(image, 0)
	if is_up:
		_spinbox_up_texture = texture
	else:
		_spinbox_down_texture = texture
	return texture


func _ensure_spinbox_stepper(spin_box) -> void:
	if not spin_box or not spin_box.get_parent():
		return
	var embedded_stepper = _node(spin_box, "MobileStepper")
	if embedded_stepper:
		embedded_stepper.queue_free()
	var row = spin_box.get_parent()
	var stepper = _node(row, "MobileStepper_%s" % spin_box.name)
	if not stepper:
		stepper = VBoxContainer.new()
		stepper.name = "MobileStepper_%s" % spin_box.name
		stepper.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		stepper.add_constant_override("separation", 6)
		row.add_child(stepper)
		row.move_child(stepper, spin_box.get_index() + 1)
		for data in [["Up", 1], ["Down", -1]]:
			var button := Button.new()
			button.name = data[0]
			button.focus_mode = Control.FOCUS_NONE
			button.mouse_filter = Control.MOUSE_FILTER_STOP
			button.text = ""
			button.icon = _spinbox_step_icon(data[1] > 0)
			button.connect("pressed", self, "_on_mobile_spinbox_step", [spin_box, data[1]])
			stepper.add_child(button)
	stepper.rect_min_size = Vector2(76, 92)
	stepper.visible = spin_box.visible
	for child in stepper.get_children():
		child.rect_min_size = Vector2(76, 43)
		_apply_button_style(child, 43, 20, 76)
		child.rect_min_size = Vector2(76, 43)
		child.disabled = not spin_box.editable


func _on_mobile_spinbox_step(spin_box, direction: int) -> void:
	if not is_instance_valid(spin_box) or not spin_box.editable:
		return
	var next_value = clamp(spin_box.value + spin_box.step * direction, spin_box.min_value, spin_box.max_value)
	spin_box.value = next_value


func _draw_up_triangle(image: Image, center_x: int, tip_y: int, base_y: int, half_width: int, color: Color) -> void:
	for y in range(tip_y, base_y + 1):
		var t := float(y - tip_y) / max(1.0, float(base_y - tip_y))
		var span := int(round(half_width * t))
		_draw_row(image, center_x - span, center_x + span, y, color)


func _draw_down_triangle(image: Image, center_x: int, base_y: int, tip_y: int, half_width: int, color: Color) -> void:
	for y in range(base_y, tip_y + 1):
		var t := float(tip_y - y) / max(1.0, float(tip_y - base_y))
		var span := int(round(half_width * t))
		_draw_row(image, center_x - span, center_x + span, y, color)


func _draw_row(image: Image, left: int, right: int, y: int, color: Color) -> void:
	if y < 0 or y >= image.get_height():
		return
	for x in range(max(0, left), min(image.get_width() - 1, right) + 1):
		image.set_pixel(x, y, color)


func _node(root, path: String):
	if not root:
		return null
	return root.get_node(path) if root.has_node(path) else null


func _safe_margin() -> int:
	return IOS_SAFE_MARGIN if is_ios() else SAFE_MARGIN


func _fill_parent(control) -> void:
	control.anchor_left = 0
	control.anchor_top = 0
	control.anchor_right = 1
	control.anchor_bottom = 1
	control.margin_left = 0
	control.margin_top = 0
	control.margin_right = 0
	control.margin_bottom = 0


func _fill_parent_with_margin(control, margin: int) -> void:
	control.anchor_left = 0
	control.anchor_top = 0
	control.anchor_right = 1
	control.anchor_bottom = 1
	control.margin_left = margin
	control.margin_top = margin
	control.margin_right = -margin
	control.margin_bottom = -margin


func _center_rect(control, size: Vector2, offset: Vector2 = Vector2.ZERO) -> void:
	control.anchor_left = 0.5
	control.anchor_top = 0.5
	control.anchor_right = 0.5
	control.anchor_bottom = 0.5
	control.margin_left = -size.x / 2 + offset.x
	control.margin_top = -size.y / 2 + offset.y
	control.margin_right = size.x / 2 + offset.x
	control.margin_bottom = size.y / 2 + offset.y


func _center_top_rect(control, width: int, height: int, top: int) -> void:
	control.anchor_left = 0.5
	control.anchor_top = 0
	control.anchor_right = 0.5
	control.anchor_bottom = 0
	control.margin_left = -width / 2
	control.margin_top = top
	control.margin_right = width / 2
	control.margin_bottom = top + height
	control.rect_min_size = Vector2(width, height)


func _top_left_rect(control, width: int, height: int, left: int, top: int) -> void:
	control.anchor_left = 0
	control.anchor_top = 0
	control.anchor_right = 0
	control.anchor_bottom = 0
	control.margin_left = left
	control.margin_top = top
	control.margin_right = left + width
	control.margin_bottom = top + height
	control.rect_min_size = Vector2(width, height)


func _bottom_left_rect(control, width: int, height: int) -> void:
	var safe_margin := _safe_margin()
	control.anchor_left = 0
	control.anchor_top = 1
	control.anchor_right = 0
	control.anchor_bottom = 1
	control.margin_left = safe_margin
	control.margin_top = -height - safe_margin
	control.margin_right = width + safe_margin
	control.margin_bottom = -safe_margin
	control.rect_min_size = Vector2(width, height)


func _bottom_center_rect(control, width: int, height: int) -> void:
	var safe_margin := _safe_margin()
	control.anchor_left = 0.5
	control.anchor_top = 1
	control.anchor_right = 0.5
	control.anchor_bottom = 1
	control.margin_left = -width / 2
	control.margin_top = -height - safe_margin
	control.margin_right = width / 2
	control.margin_bottom = -safe_margin
	control.rect_min_size = Vector2(width, height)
