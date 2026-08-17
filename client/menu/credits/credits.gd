extends MenuControl

var title_scene := "res://client/menu/title/title_screen.tscn"


func _ready() -> void:
	$Panel/ScrollContainer/CreditsText.text = _credits_text()
	MobileUI.adapt_credits(self)
	if not MobileUI.is_mobile():
		$BackButton.call_deferred("grab_focus")


func _on_BackButton_pressed() -> void:
	change_menu(title_scene)


func _credits_text() -> String:
	return PoolStringArray([
		"Android Port",
		"Modified/adapted for Android and published by SLG Developer.",
		"",
		"Original Game",
		"Flappy Race by Jibby Games.",
		"Original source: https://github.com/Jibby-Games/Flappy-Race",
		"",
		"MIT License",
		"Scripts and scene files are distributed under the MIT License.",
		"Copyright (c) 2021 Jibbajabbafic.",
		"Full MIT license text is available in this app's licenses/credits section and in the original project LICENSE file.",
		"",
		"Assets",
		"Unless mentioned otherwise, art assets, images, sounds, and files under raw_assets/ are distributed under the Creative Commons Attribution 4.0 International license:",
		"https://creativecommons.org/licenses/by/4.0/",
		"Changes were made as part of the Android adaptation.",
		"",
		"Sprites",
		"Wall sprite by www.kenney.nl, licensed under CC0 1.0 Universal:",
		"https://creativecommons.org/publicdomain/zero/1.0/",
		"",
		"Music",
		"Licensed under the Public Domain License:",
		"Computer F***! by Drozerix",
		"Crush by Drozerix",
		"Digital Rendezvous by Drozerix",
		"Dream Candy by Drozerix",
		"Spectrum by Peak and Drozerix",
		"",
		"Audio",
		"Voiceover pack by www.kenney.nl, licensed under CC0 1.0 Universal:",
		"https://creativecommons.org/publicdomain/zero/1.0/",
		"",
		"Level-Up Sound FX by elmasmalo1, licensed under Creative Commons Attribution 3.0 Unported:",
		"https://creativecommons.org/licenses/by/3.0/",
		"",
		"JJJ2 96 countdown - cheer.wav by FreqMan, licensed under Creative Commons Attribution 3.0 Unported:",
		"https://creativecommons.org/licenses/by/3.0/",
		"",
		"Fonts",
		"DelaGothicOne is licensed under the SIL Open Font License.",
		"Roboto is licensed under the Apache License 2.0 / included font license notice.",
		"",
		"No endorsement by the original authors or asset creators is implied."
	]).join("\n")
