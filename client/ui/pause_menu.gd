extends PopupPanel

const REMOVE_ADS_FAILURE_LABEL := "Store unavailable"
const REMOVE_ADS_FAILURE_SECONDS := 1.5


func _ready() -> void:
	if Ads.has_signal("remove_ads_purchased") and not Ads.is_connected("remove_ads_purchased", self, "_on_remove_ads_purchased"):
		Ads.connect("remove_ads_purchased", self, "_on_remove_ads_purchased")
	if Ads.has_signal("remove_ads_purchase_failed") and not Ads.is_connected("remove_ads_purchase_failed", self, "_on_remove_ads_purchase_failed"):
		Ads.connect("remove_ads_purchase_failed", self, "_on_remove_ads_purchase_failed")
	if Ads.has_signal("remove_ads_purchase_cancelled") and not Ads.is_connected("remove_ads_purchase_cancelled", self, "_on_remove_ads_purchase_cancelled"):
		Ads.connect("remove_ads_purchase_cancelled", self, "_on_remove_ads_purchase_cancelled")
	if not $VBoxContainer/RemoveAdsButton.is_connected("pressed", self, "_on_RemoveAdsButton_pressed"):
		$VBoxContainer/RemoveAdsButton.connect("pressed", self, "_on_RemoveAdsButton_pressed")
	MobileUI.adapt_pause_menu(self)


func _notification(what: int) -> void:
	if what == MainLoop.NOTIFICATION_WM_GO_BACK_REQUEST:
		if visible:
			disable_pause_menu()
		else:
			enable_pause_menu()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_menu"):
		get_tree().set_input_as_handled()
		if visible:
			disable_pause_menu()
		else:
			enable_pause_menu()


func enable_pause_menu() -> void:
	_configure_buttons()
	# Only allow the game clock to be paused in singleplayer.
	if Network.Client.is_singleplayer:
		get_tree().paused = true
	MobileUI.adapt_pause_menu(self)
	self.popup()


func disable_pause_menu() -> void:
	self.hide()
	get_tree().paused = false


func _on_ResumeButton_pressed() -> void:
	disable_pause_menu()


func _on_NewRaceButton_pressed() -> void:
	Ads.run_after_maybe_interstitial(self, "_start_new_race_after_ad")


func _start_new_race_after_ad() -> void:
	get_tree().paused = false
	Network.Client.send_change_to_setup_request()


func _on_MainMenuButton_pressed() -> void:
	if Network.Client.is_singleplayer:
		Ads.run_after_maybe_interstitial(self, "_return_to_main_menu_after_ad")
		return

	_return_to_main_menu_after_ad()


func _return_to_main_menu_after_ad() -> void:
	Network.stop_networking()
	get_tree().paused = false
	Network.Client.change_scene_to_title_screen()


func _on_QuitButton_pressed() -> void:
	get_tree().notification(MainLoop.NOTIFICATION_WM_QUIT_REQUEST)


func _on_RemoveAdsButton_pressed() -> void:
	print("FlappyAds: Remove Ads button pressed on pause menu.")
	_set_menu_button_label($VBoxContainer/RemoveAdsButton, "Opening Store...")
	$VBoxContainer/RemoveAdsButton.disabled = true
	Ads.purchase_remove_ads()
	MobileUI.adapt_pause_menu(self)


func _on_remove_ads_purchased() -> void:
	_configure_buttons()
	MobileUI.adapt_pause_menu(self)


func _on_remove_ads_purchase_failed() -> void:
	if Ads.is_remove_ads_available() and not Ads.are_ads_removed():
		$VBoxContainer/RemoveAdsButton.disabled = false
		_set_menu_button_label($VBoxContainer/RemoveAdsButton, REMOVE_ADS_FAILURE_LABEL)
		MobileUI.adapt_pause_menu(self)
		yield(get_tree().create_timer(REMOVE_ADS_FAILURE_SECONDS), "timeout")
		if not is_inside_tree():
			return
	_configure_buttons()
	MobileUI.adapt_pause_menu(self)


func _on_remove_ads_purchase_cancelled() -> void:
	_configure_buttons()
	MobileUI.adapt_pause_menu(self)


func _configure_buttons() -> void:
	var is_multiplayer: bool = not Network.Client.is_singleplayer
	_set_menu_button_label($VBoxContainer/ResumeButton, "Continue" if is_multiplayer else "Resume")
	_set_menu_button_label($VBoxContainer/MainMenuButton, "Exit Game" if is_multiplayer else "Main Menu")
	$VBoxContainer/NewRaceButton.visible = (not is_multiplayer) and Network.Client.is_host()
	$VBoxContainer/MainMenuButton.visible = true
	$VBoxContainer/RemoveAdsButton.disabled = false
	$VBoxContainer/RemoveAdsButton.visible = Ads.is_remove_ads_available() and not Ads.are_ads_removed()
	_set_menu_button_label($VBoxContainer/RemoveAdsButton, "Remove Ads")
	$VBoxContainer/QuitButton.visible = not is_multiplayer


func _set_menu_button_label(button, text: String) -> void:
	if not button:
		return
	button.label = text
	if button.has_node("Label"):
		button.get_node("Label").text = text
