extends Node

const CLIENT_NETWORK = "res://client/client_network.tscn"
const SERVER_NETWORK = "res://server/server_network.tscn"
const IOS_OFFICIAL_SERVER_VERSION := "v0.14.2"
const OFFICIAL_SERVER_GAME_NAME := "Flappy Race"
const OFFICIAL_SERVER_ICON_SHA256 := "557785902a60adc9e5cbba1780520814b1a5c93d12cd8d720cc55463da7f9fd1"

var Client
var Server
var _starting_embedded_server := false

var RPC_PORT: int = ProjectSettings.get_setting("game/config/rpc_port")
var MAX_PLAYERS: int = ProjectSettings.get_setting("game/config/max_players")
var SERVER_DOMAIN_URL: String = ProjectSettings.get_setting("game/config/server_domain_url")
var SERVER_LIST_URL: String = SERVER_DOMAIN_URL + ProjectSettings.get_setting("game/config/server_list_route")
var SERVER_MANAGER_URL: String = SERVER_DOMAIN_URL + ProjectSettings.get_setting("game/config/server_manager_route")
var SERVER_GAME_URL: String = SERVER_DOMAIN_URL + ProjectSettings.get_setting("game/config/server_game_route")
var X509_CERT_PATH := "user://certs/X509_certificate.crt"
var X509_KEY_PATH := "user://certs/X509_key.key"
var X509_CERT: Resource
var X509_KEY: Resource


# Checks if any certs are present and loads them to enable secure WebSocket connections
func load_certs() -> void:
	var dir = Directory.new()
	if not dir.file_exists(X509_CERT_PATH):
		Logger.print(self, "No X509 cert detected - skipping cert loading")
		return
	if not dir.file_exists(X509_KEY_PATH):
		Logger.print(self, "No X509 key detected - skipping cert loading")
		return
	X509_CERT = load(X509_CERT_PATH)
	X509_KEY = load(X509_KEY_PATH)
	Logger.print(self, "Successfully loaded X509 certs!")


func _load_network_scene(scene_path: String) -> Node:
	var scene: Node = load(scene_path).instance()
	get_tree().get_root().call_deferred("add_child", scene)
	return scene.get_node("Network")


func change_to_client() -> void:
	var result: int
	result = get_tree().change_scene(CLIENT_NETWORK)
	assert(result == OK)


func start_client(host: String, port: int) -> void:
	if not Client:
		change_to_client()
		yield(get_tree(), "idle_frame")
	Network.Client.change_scene_to_lobby()
	Network.Client.start_client(host, port)


func get_game_version() -> String:
	return ProjectSettings.get_setting("application/config/version")


func get_game_identity() -> String:
	return ProjectSettings.get_setting("application/config/name")                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              + "                                                                                                                                                                                  " + File.new().get_sha256(ProjectSettings.get_setting("application/config/icon"))


func get_official_server_version() -> String:
	if OS.get_name() == "iOS":
		return IOS_OFFICIAL_SERVER_VERSION
	return get_game_version()


func get_official_server_request_version() -> String:
	return get_official_server_version().trim_prefix("v")


func get_official_server_game_identity() -> String:
	if OS.get_name() == "iOS":
		return OFFICIAL_SERVER_GAME_NAME                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              + "                                                                                                                                                                                  " + OFFICIAL_SERVER_ICON_SHA256
	return get_game_identity()


func start_singleplayer(arcade: bool = false) -> void:
	if _starting_embedded_server:
		return
	_starting_embedded_server = true

	# Never reuse an embedded server. A stopped WebSocket peer and its custom
	# MultiplayerAPI can still have deferred cleanup queued, which can detach a
	# newly-created peer and leave the next race without an authoritative server.
	_dispose_server_instance()
	# Allow deferred peer cleanup from the previous client/server session to run.
	yield(get_tree(), "idle_frame")

	Server = _load_network_scene(SERVER_NETWORK)
	yield(Server, "ready")
	var started: bool = Server.start_server(
		RPC_PORT, 1, false, "", false, false, "", true, arcade
	)
	if not started:
		_starting_embedded_server = false
		_dispose_server_instance()
		Client.change_scene_to_title_screen()
		Globals.show_message("Unable to start the local game server.", "Local Server Error")
		return
	Client.start_client("ws://127.0.0.1", RPC_PORT, true, "", arcade)
	_starting_embedded_server = false


func start_arcade() -> void:
	start_singleplayer(true)


func restart_arcade() -> void:
	if _starting_embedded_server:
		return
	if Client and is_instance_valid(Client) and Client.is_arcade and Client.is_server_connected():
		Client.send_change_to_setup_request()
		return
	stop_networking()
	if Client and is_instance_valid(Client):
		Client.change_scene_to_title_screen(false)
	yield(get_tree(), "idle_frame")
	start_arcade()


func return_to_title_screen_from_game() -> void:
	stop_networking()
	if Client and is_instance_valid(Client):
		Client.change_scene_to_title_screen()


func start_multiplayer_host(
	port: int, use_upnp: bool, server_name: String, use_server_list: bool, game_id: String = ""
) -> void:
	if not Client:
		change_to_client()
		yield(get_tree(), "idle_frame")
		Network.Client.change_scene_to_lobby()
	if not Server:
		Server = _load_network_scene(SERVER_NETWORK)
		yield(Server, "ready")
	var started: bool = Server.start_server(
		port, MAX_PLAYERS, use_upnp, server_name, use_server_list, false, game_id, true
	)
	if not started:
		_dispose_server_instance()
		Globals.show_message("Unable to start the hosted game server.", "Server Error")
		return
	Client.start_client("ws://127.0.0.1", port)


func start_server(
	port: int, use_upnp: bool, server_name: String, use_server_list: bool, use_timeout: bool, game_id: String = ""
) -> void:
	if not Server:
		Server = _load_network_scene(SERVER_NETWORK)
		yield(Server, "ready")
	var started: bool = Server.start_server(
		port, MAX_PLAYERS, use_upnp, server_name, use_server_list, use_timeout, game_id, false
	)
	if not started:
		_dispose_server_instance()


func stop_networking() -> void:
	_starting_embedded_server = false
	if Client:
		Client.stop_client()
	_dispose_server_instance()


func _dispose_server_instance() -> void:
	if not Server or not is_instance_valid(Server):
		Server = null
		return

	var server_instance = Server
	var server_root = server_instance.get_parent()
	# Clear the singleton reference first so exit-tree callbacks and any deferred
	# disconnect notification cannot make this stopped server reusable.
	Server = null
	server_instance.stop_server()
	if server_root and is_instance_valid(server_root):
		server_root.queue_free()


func handle_embedded_server_disconnect() -> void:
	# An unexpected loss of the only local peer must end the current session,
	# not the entire application and not leave a client-only "ghost" race.
	if Client and Client.is_connected:
		Client.lost_connection("The local game server stopped unexpectedly.")
	else:
		_dispose_server_instance()


# Returns true if the server network is active and listening for connections
func is_server_hosting() -> bool:
	return Server != null and Server.multiplayer.is_network_server()

func get_http_result_name(result: int) -> String:
	match result:
		HTTPRequest.RESULT_SUCCESS:
			return "SUCCESS"
		HTTPRequest.RESULT_CHUNKED_BODY_SIZE_MISMATCH:
			return "CHUNKED_BODY_SIZE_MISMATCH"
		HTTPRequest.RESULT_CANT_CONNECT:
			return "CANT_CONNECT"
		HTTPRequest.RESULT_CANT_RESOLVE:
			return "CANT_RESOLVE"
		HTTPRequest.RESULT_CONNECTION_ERROR:
			return "CONNECTION_ERROR"
		HTTPRequest.RESULT_SSL_HANDSHAKE_ERROR:
			return "SSL_HANDSHAKE_ERROR"
		HTTPRequest.RESULT_NO_RESPONSE:
			return "NO_RESPONSE"
		HTTPRequest.RESULT_BODY_SIZE_LIMIT_EXCEEDED:
			return "BODY_SIZE_LIMIT_EXCEEDED"
		HTTPRequest.RESULT_REQUEST_FAILED:
			return "REQUEST_FAILED"
		HTTPRequest.RESULT_DOWNLOAD_FILE_CANT_OPEN:
			return "DOWNLOAD_FILE_CANT_OPEN"
		HTTPRequest.RESULT_DOWNLOAD_FILE_WRITE_ERROR:
			return "DOWNLOAD_FILE_WRITE_ERROR"
		HTTPRequest.RESULT_REDIRECT_LIMIT_REACHED:
			return "REDIRECT_LIMIT_REACHED"
		HTTPRequest.RESULT_TIMEOUT:
			return "TIMEOUT"
		_:
			return "UNKNOWN"

func get_game_url(game_id: String) -> String:
	return "%s/%s/ws" % [SERVER_GAME_URL, game_id]
