extends MenuControl

var singleplayer_scene := "res://client/menu/setup/setup.tscn"
var multiplayer_scene := "res://client/menu/lobby/name_entry.tscn"
var options_scene := "res://client/menu/options/options.tscn"
var credits_scene := "res://client/menu/credits/credits.tscn"
var title_player := preload("res://client/menu/title/title_player.tscn")
const DEFAULT_LOGO_TEXTURE := preload("res://client/menu/title/flappy_race_logo.png")
const IOS_LOGO_TEXTURE := preload("res://client/menu/title/flappy_kart_logo.png")
const REMOVE_ADS_FAILURE_LABEL := "Store unavailable"
const REMOVE_ADS_FAILURE_SECONDS := 1.5
# Aim for about 16 players
var area_per_player := (1920 * 1080) / 16
var spawned_title_players := []


func _ready() -> void:
	_load_logo_texture()
	if Ads.has_signal("remove_ads_purchased") and not Ads.is_connected("remove_ads_purchased", self, "_on_remove_ads_purchased"):
		Ads.connect("remove_ads_purchased", self, "_on_remove_ads_purchased")
	if Ads.has_signal("remove_ads_purchase_failed") and not Ads.is_connected("remove_ads_purchase_failed", self, "_on_remove_ads_purchase_failed"):
		Ads.connect("remove_ads_purchase_failed", self, "_on_remove_ads_purchase_failed")
	if Ads.has_signal("remove_ads_purchase_cancelled") and not Ads.is_connected("remove_ads_purchase_cancelled", self, "_on_remove_ads_purchase_cancelled"):
		Ads.connect("remove_ads_purchase_cancelled", self, "_on_remove_ads_purchase_cancelled")
	if not $Menu/Buttons/RemoveAdsButton.is_connected("pressed", self, "_on_RemoveAdsButton_pressed"):
		$Menu/Buttons/RemoveAdsButton.connect("pressed", self, "_on_RemoveAdsButton_pressed")
	$Menu/VersionLabel.text = ProjectSettings.get_setting("application/config/version")
	_update_remove_ads_button()
	MobileUI.adapt_title_screen(self)
	if not MobileUI.is_mobile():
		$Menu/Buttons/SingleplayerButton.grab_focus()
	var result := get_viewport().connect("size_changed", self, "spawn_title_players")
	assert(result == OK)
	spawn_title_players()
	if OS.has_feature("web"):
		$Menu/Buttons/SingleplayerButton.hide()


func _load_logo_texture() -> void:
	$Menu/Logo.expand = true
	$Menu/Logo.stretch_mode = 5
	$Menu/Logo.texture = IOS_LOGO_TEXTURE if OS.get_name() == "iOS" else DEFAULT_LOGO_TEXTURE


func spawn_title_players() -> void:
	if not is_inside_tree():
		# Scene might not be fully loaded if using command line args to join
		return
	var total_players := get_viewport_rect().get_area() / area_per_player
	Logger.print(self, "Viewport size changed - Need %d players" % total_players)
	if total_players > spawned_title_players.size():
		# Add more players
		var players_to_spawn := total_players - spawned_title_players.size()
		Logger.print(self, "Spawning %d players" % players_to_spawn)
		for i in players_to_spawn:
			var inst = title_player.instance()
			spawned_title_players.append(inst)
			$PlayerContainer.add_child(inst)
	elif total_players < spawned_title_players.size():
		# Remove some players
		var players_to_despawn := spawned_title_players.size() - total_players
		Logger.print(self, "Removing %d players" % players_to_despawn)
		for i in players_to_despawn:
			var player = spawned_title_players.pop_back()
			player.remove_when_off_screen = true


func _on_SingleplayerButton_pressed() -> void:
	change_menu(singleplayer_scene)
	Network.start_singleplayer()


func _on_MultiplayerButton_pressed() -> void:
	change_menu(multiplayer_scene)


func _on_OptionsButton_pressed() -> void:
	change_menu(options_scene)


func _on_CreditsButton_pressed() -> void:
	change_menu(credits_scene)


func _on_RemoveAdsButton_pressed() -> void:
	print("FlappyAds: Remove Ads button pressed on title screen.")
	_set_remove_ads_button_label("Opening Store...")
	$Menu/Buttons/RemoveAdsButton.disabled = true
	Ads.purchase_remove_ads()


func _on_remove_ads_purchased() -> void:
	_update_remove_ads_button()


func _on_remove_ads_purchase_failed() -> void:
	if Ads.is_remove_ads_available() and not Ads.are_ads_removed():
		$Menu/Buttons/RemoveAdsButton.disabled = false
		_set_remove_ads_button_label(REMOVE_ADS_FAILURE_LABEL)
		yield(get_tree().create_timer(REMOVE_ADS_FAILURE_SECONDS), "timeout")
		if not is_inside_tree():
			return
	_update_remove_ads_button()


func _on_remove_ads_purchase_cancelled() -> void:
	_update_remove_ads_button()


func _on_QuitButton_pressed() -> void:
	get_tree().notification(MainLoop.NOTIFICATION_WM_QUIT_REQUEST)


func _update_remove_ads_button() -> void:
	$Menu/Buttons/RemoveAdsButton.disabled = false
	$Menu/Buttons/RemoveAdsButton.visible = Ads.is_remove_ads_available() and not Ads.are_ads_removed()
	_set_remove_ads_button_label("Remove Ads")


func _set_remove_ads_button_label(text: String) -> void:
	var button = $Menu/Buttons/RemoveAdsButton
	button.label = text
	if button.has_node("Label"):
		button.get_node("Label").text = text
