extends Control

var ip: String
var tls: bool
var port: int
var official: bool
var game_id: String


func setup(server_info: Dictionary) -> void:
	$Hbox/Name.text = server_info.get("name", "unknown")
	$Hbox/Players.text = "%d / %d" % [server_info.get("players", "0"), Network.MAX_PLAYERS]
	ip = server_info.get("ip", "")
	tls = server_info.get("tls", false)
	port = server_info.get("port", Network.RPC_PORT)
	official = server_info.get("official", false)
	game_id = server_info.get("game_id", "")
	MobileUI.adapt_server_entry(self)


func _on_JoinButton_pressed() -> void:
	var version_override := Network.get_official_server_version() if official else ""
	if not game_id.empty():
		var url := Network.get_game_url(game_id)
		Network.Client.start_client(url, -1, false, Network.get_official_server_version())
	else:
		var url: String
		if official or is_official_server_ip(ip):
			url = Network.SERVER_DOMAIN_URL
			version_override = Network.get_official_server_version()
		else:
			var protocol := "wss" if tls else "ws"
			url = "%s://%s" % [protocol, ip]
		Network.Client.start_client(url, port, false, version_override)


func is_official_server_ip(ip_addr: String) -> bool:
	var hostname: String = Network.SERVER_DOMAIN_URL.get_slice("://", 1)
	var official_ip: String = IP.resolve_hostname(hostname, IP.TYPE_IPV4)
	return ip_addr == official_ip
