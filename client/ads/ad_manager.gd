extends Node

signal remove_ads_purchased
signal remove_ads_purchase_failed
signal remove_ads_purchase_cancelled

const SHOW_CHANCE := 0.5
const PLUGIN_NAME := "FlappyAds"
const SAVE_PATH := "user://purchases.cfg"
const PURCHASE_SECTION := "purchases"
const REMOVE_ADS_KEY := "remove_ads"

var _plugin = null
var _rng := RandomNumberGenerator.new()
var _waiting_for_ad := false
var _pending_target = null
var _pending_method := ""
var _pending_args := []
var _ads_removed := false


func _ready() -> void:
	pause_mode = Node.PAUSE_MODE_PROCESS
	_ads_removed = _load_remove_ads_purchase()
	_rng.randomize()
	_connect_android_plugin()


func run_after_maybe_interstitial(target: Object, method: String, args: Array = []) -> void:
	if _waiting_for_ad:
		return

	if _should_show_interstitial():
		_store_pending_action(target, method, args)
		_waiting_for_ad = true
		if _plugin.showInterstitial():
			return
		_clear_pending_action()

	_call_action(target, method, args)


func maybe_show_interstitial() -> void:
	if _waiting_for_ad:
		return

	if _should_show_interstitial():
		_waiting_for_ad = true
		if _plugin.showInterstitial():
			return
		_clear_pending_action()


func are_ads_removed() -> bool:
	return _ads_removed


func is_remove_ads_available() -> bool:
	return OS.get_name() == "Android" and _plugin != null


func purchase_remove_ads() -> void:
	print("FlappyAds: purchase_remove_ads called. ads_removed=%s, available=%s, plugin=%s" % [_ads_removed, is_remove_ads_available(), _plugin])
	if _ads_removed:
		emit_signal("remove_ads_purchased")
		return
	if not is_remove_ads_available():
		print("FlappyAds: Remove Ads is not available. Android=%s, plugin=%s" % [OS.get_name(), _plugin])
		emit_signal("remove_ads_purchase_failed")
		return
	print("FlappyAds: Calling Android purchase_remove_ads.")
	_plugin.purchase_remove_ads()


func restore_purchases() -> void:
	if is_remove_ads_available():
		_plugin.restore_purchases()


func _connect_android_plugin() -> void:
	if OS.get_name() != "Android":
		return
	if not Engine.has_singleton(PLUGIN_NAME):
		print("FlappyAds: Android plugin not registered.")
		return

	_plugin = Engine.get_singleton(PLUGIN_NAME)
	print("FlappyAds: Android plugin registered.")
	if _plugin.has_method("get_method_list"):
		print("FlappyAds: Android plugin methods = %s" % [_plugin.get_method_list()])
	_connect_plugin_signal("interstitial_closed", "_on_interstitial_finished")
	_connect_plugin_signal("interstitial_failed", "_on_interstitial_finished")
	_connect_plugin_signal("remove_ads_purchased", "_on_remove_ads_purchased")
	_connect_plugin_signal("remove_ads_purchase_failed", "_on_remove_ads_purchase_failed")
	_connect_plugin_signal("remove_ads_purchase_cancelled", "_on_remove_ads_purchase_cancelled")

	_plugin.initialize()
	_plugin.restore_purchases()


func _connect_plugin_signal(signal_name: String, method_name: String) -> void:
	if _plugin.has_signal(signal_name) and not _plugin.is_connected(signal_name, self, method_name):
		_plugin.connect(signal_name, self, method_name)


func _should_show_interstitial() -> bool:
	if _ads_removed:
		return false
	if _plugin == null:
		return false
	if not _plugin.isInterstitialReady():
		print("FlappyAds: Interstitial is not ready yet.")
		_plugin.loadInterstitial()
		return false
	var should_show := _rng.randf() < SHOW_CHANCE
	print("FlappyAds: Interstitial chance result = %s." % should_show)
	return should_show


func _store_pending_action(target: Object, method: String, args: Array) -> void:
	_pending_target = weakref(target)
	_pending_method = method
	_pending_args = args.duplicate()


func _clear_pending_action() -> void:
	_waiting_for_ad = false
	_pending_target = null
	_pending_method = ""
	_pending_args.clear()


func _on_interstitial_finished() -> void:
	if not _waiting_for_ad:
		return

	var target = _pending_target.get_ref() if _pending_target else null
	var method := _pending_method
	var args := _pending_args.duplicate()
	_clear_pending_action()

	_call_action(target, method, args)


func _call_action(target: Object, method: String, args: Array) -> void:
	if target and is_instance_valid(target) and target.has_method(method):
		target.callv(method, args)


func _on_remove_ads_purchased() -> void:
	_ads_removed = true
	_save_remove_ads_purchase()
	emit_signal("remove_ads_purchased")


func _on_remove_ads_purchase_failed() -> void:
	emit_signal("remove_ads_purchase_failed")


func _on_remove_ads_purchase_cancelled() -> void:
	emit_signal("remove_ads_purchase_cancelled")


func _load_remove_ads_purchase() -> bool:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return false
	return bool(config.get_value(PURCHASE_SECTION, REMOVE_ADS_KEY, false))


func _save_remove_ads_purchase() -> void:
	var config := ConfigFile.new()
	config.set_value(PURCHASE_SECTION, REMOVE_ADS_KEY, true)
	var result := config.save(SAVE_PATH)
	if result != OK:
		push_warning("Failed to save remove ads purchase. Error: %d" % result)
