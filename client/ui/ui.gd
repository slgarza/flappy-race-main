extends CanvasLayer

export(NodePath) var ScorePath
export(NodePath) var LivesPath
export(NodePath) var CoinsPath
export(NodePath) var ItemsPath
export(NodePath) var SpectateLabelPath
export(NodePath) var RaceProgressPath

onready var Score := get_node(ScorePath)
onready var Lives := get_node(LivesPath)
onready var Coins := get_node(CoinsPath)
onready var Items := get_node(ItemsPath)
onready var SpectateLabel := get_node(SpectateLabelPath)
onready var RaceProgress := get_node(RaceProgressPath)

signal countdown_finished
signal request_restart
signal spectate_change(forward_not_back)

var is_spectating := false
var item_slots := []


func _ready() -> void:
	MobileUI.adapt_hud(self)
	_set_pause_button_visible(false)
	# Hide all UI elements by default
	for child in get_children():
		if child is Control:
			child.hide()
	# Always show the message box
	$MessageBox.show()


func set_player_list(player_list: Dictionary) -> void:
	for player_id in player_list:
		if not player_list[player_id].spectate:
			var colour = Globals.COLOUR_OPTIONS[player_list[player_id].colour]
			RaceProgress.add_player(player_id, colour)


func set_spectating(value: bool) -> void:
	is_spectating = value
	$Ingame/Player.visible = not value
	$Ingame/Spectator.visible = value


func start_countdown() -> void:
	$Countdown.show()
	$Countdown/AnimationPlayer.play("Countdown")


func _countdown_finished() -> void:
	emit_signal("countdown_finished")
	$Ingame/Stopwatch.start()
	$Ingame.show()
	_set_pause_button_visible(true)
	if not is_spectating:
		$Ingame/InputControls.start_checking_for_input()


func update_lives(new_lives: int) -> void:
	Lives.set_lives(new_lives)

func items_enabled(value: bool) -> void:
	Coins.visible = value


func configure_arcade(enabled: bool, high_score: int = 0) -> void:
	RaceProgress.visible = not enabled
	Score.visible = not enabled
	$Ingame/ArcadeStats.visible = enabled
	if enabled:
		update_score(0)
		update_arcade_high_score(high_score)


func update_score(new_score: int) -> void:
	# Actual incrementing is handled on the player object
	Score.text = str(new_score)
	$Ingame/ArcadeStats/Score.text = "Score: %d" % new_score


func update_arcade_high_score(value: int) -> void:
	$Ingame/ArcadeStats/HighScore.text = "High Score: %d" % value


func update_coins(value: int) -> void:
	Coins.update_coins(value)


func get_item(item: Item) -> void:
	Items.get_item(item)


func _on_RestartButton_pressed() -> void:
	Ads.run_after_maybe_interstitial(self, "_request_restart_after_ad")


func _request_restart_after_ad() -> void:
	emit_signal("request_restart")


func show_death() -> void:
	$Ingame/Player.hide()
	_set_pause_button_visible(true)
	$Death.show()
	$Ingame/InputControls.stop_checking_for_input()
	$Death/AnimationPlayer.play("show")


func show_finished(place: int, time: float) -> void:
	$Death.hide()
	$Finished/ArcadeResult.hide()
	$Finished/FinishedLabel.show()
	$Finished/PlaceLabel.show()
	$Finished/FinishTime.show()
	_set_pause_button_visible(false)
	$Finished/PlaceLabel.text = int2ordinal(place)
	$Finished/FinishTime.set_time(time)
	$Finished.show()
	$Ingame/InputControls.stop_checking_for_input()
	$Finished/AnimationPlayer.play("Finished")


func show_arcade_game_over(time: float, score: int, high_score: int) -> void:
	$PauseMenu.disable_pause_menu()
	$Ingame/Stopwatch.stop()
	$Ingame/InputControls.stop_checking_for_input()
	$Ingame.hide()
	$Death.hide()
	$Leaderboard.hide()
	_set_pause_button_visible(false)
	$Finished/AnimationPlayer.stop()
	$Finished/FinishedLabel.hide()
	$Finished/PlaceLabel.hide()
	$Finished/FinishTime.hide()
	$Finished/ArcadeResult/Time.set_time(time)
	$Finished/ArcadeResult/Score.text = "Score: %d" % score
	$Finished/ArcadeResult/HighScore.text = "High Score: %d" % high_score
	$Finished/ArcadeResult.show()
	$Finished.show()
	MobileUI.adapt_arcade_game_over(self)
	if not MobileUI.is_mobile():
		$Finished/ArcadeResult/Buttons/NewRaceButton.grab_focus()


func _on_ArcadeNewRaceButton_pressed() -> void:
	Ads.run_after_maybe_interstitial(self, "_request_arcade_new_race_after_ad")


func _request_arcade_new_race_after_ad() -> void:
	Network.Client.send_change_to_setup_request()


func _on_ArcadeMainMenuButton_pressed() -> void:
	Ads.run_after_maybe_interstitial(self, "_return_from_arcade_to_main_menu_after_ad")


func _return_from_arcade_to_main_menu_after_ad() -> void:
	Network.stop_networking()
	Network.Client.change_scene_to_title_screen()


func show_leaderboard(player_list: Array) -> void:
	$Ingame/Stopwatch.stop()
	$Ingame.hide()
	_set_pause_button_visible(false)
	$Death.hide()
	$Leaderboard.clear_players()
	for player in player_list:
		var place_text := int2ordinal(player.place) if player.place > 0 else ""
		var time = player.get("time", 0.0)
		$Leaderboard.add_player(player.name, player.colour, place_text, player.progress, time)

	if Network.Client.is_host():
		$Leaderboard/Footer/NewRaceButton.show()
		if Network.Client.is_singleplayer:
			$Leaderboard/Footer/RestartButton.show()
			if not MobileUI.is_mobile():
				$Leaderboard/Footer/RestartButton.grab_focus()
		else:
			if not MobileUI.is_mobile():
				$Leaderboard/Footer/NewRaceButton.grab_focus()
	else:
		$Leaderboard/Footer/RestartButton.hide()
		$Leaderboard/Footer/NewRaceButton.hide()
	$Leaderboard.show()


func set_late_join_spectator(time: float) -> void:
	$Ingame/Stopwatch.set_time(time)
	$Ingame/Stopwatch.start()
	set_spectating(true)
	_set_pause_button_visible(true)
	$Ingame.show()


func int2ordinal(value: int) -> String:
	var digit := value % 10
	var suffix: String

	if digit == 1 and value != 11:
		suffix = "st"
	elif digit == 2 and value != 12:
		suffix = "nd"
	elif digit == 3 and value != 13:
		suffix = "rd"
	else:
		suffix = "th"

	return "%d%s" % [value, suffix]


func set_spectate_player_name(name: String) -> void:
	SpectateLabel.text = "Spectating:\n%s" % name


func _on_NewRaceButton_pressed() -> void:
	if not Network.Client.is_singleplayer:
		Network.Client.send_change_to_setup_request()
		return

	Ads.run_after_maybe_interstitial(self, "_request_new_race_after_ad")


func _request_new_race_after_ad() -> void:
	Network.Client.send_change_to_setup_request()


func _on_PreviousButton_pressed() -> void:
	emit_signal("spectate_change", false)


func _on_NextButton_pressed() -> void:
	emit_signal("spectate_change", true)


func _set_pause_button_visible(value: bool) -> void:
	if has_node("Ingame/PauseButton"):
		$Ingame/PauseButton.visible = value and MobileUI.is_mobile()


func _on_PauseButton_pressed() -> void:
	if MobileUI.is_mobile():
		$PauseMenu.enable_pause_menu()
