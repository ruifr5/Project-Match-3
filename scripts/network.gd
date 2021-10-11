extends Node

var server_port = 31400
var upnp: UPNP
var thread = Thread.new()
var ip_url = "https://api.ipify.org"

var game_window: GameWindow
var players_done = 0


# Player info, associate ID to data
var enemy_info = { id = null, name = null}
# Info we send to other players
var my_info = { name = null }


func _ready():
#	 Connect all functions
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
	get_tree().connect("connected_to_server", self, "_connected_ok")
	get_tree().connect("connection_failed", self, "_connected_fail")
	get_tree().connect("server_disconnected", self, "_server_disconnected")
	var http_request = HTTPRequest.new()
	http_request.name = "http_request"
	add_child(http_request)


func _exit_tree():
	if upnp and upnp.get_device_count() > 0:
		upnp.delete_port_mapping(server_port)


func _player_connected(id):
	# Called on both clients and server when a peer connects. Send my info to it.
	rpc_id(id, "register_player", my_info)


func _player_disconnected(id):
	enemy_info.erase(id) # Erase player from info.
	return_to_home()


func _connected_ok():
	# Only called on clients, not server.
	pass


func _server_disconnected():
	# Server kicked us; show error and abort.
	return_to_home()


func _connected_fail():
	pass # Could not even connect to server; abort.


func return_to_home():
	if has_node("/root/game_window"):
		get_node("/root/game_window").queue_free()
	get_tree().change_scene("res://scenes/home_window.tscn")
	call_deferred("terminate_connection")


remote func register_player(name):
	# Store the info
	enemy_info.id = get_tree().get_rpc_sender_id()
	enemy_info.name = name
	rpc_id(1, "done_register")


remotesync func done_register():
	assert(get_tree().is_network_server())
	players_done += 1
	if players_done == 2:
		players_done = 0
		pre_configure_game_serverside()


func create_server(user_name):
	my_info.name = user_name
	var peer = NetworkedMultiplayerENet.new()
	peer.create_server(int(user_name), 1)
	get_tree().set_network_peer(peer)
	thread.start(self, "upnp_open_port", null)


func upnp_open_port(a):
	upnp = UPNP.new()
	var result = upnp.discover()
	if upnp.get_device_count() > 0:
		upnp.add_port_mapping(int(server_port))
	print("discover response: ", result)
#	var my_ipv4 = upnp.query_external_address()


func connect_to_server(server_ip, user_name):
	if server_ip == "":
		server_ip = "127.0.0.1"
	my_info.name = user_name
	var peer = NetworkedMultiplayerENet.new()
	peer.create_client(server_ip, int(user_name))
	get_tree().network_peer = peer


func terminate_connection():
	get_tree().network_peer = null


func refuse_connections():
	get_tree().set_refuse_new_network_connections(true)


func accept_connections():
	get_tree().set_refuse_new_network_connections(false)


func pre_configure_game_serverside():
	game_window = load("res://scenes/game_window.tscn").instance()
	get_node("/root/home_window").queue_free()
	get_node("/root").add_child(game_window)
	rpc("pre_configure_game", game_window.serialize())


remotesync func pre_configure_game(game_window_serialized):
	get_tree().set_pause(true) # Pre-pause

#	if !get_tree().is_network_server():
	# Load world
	if !game_window:
		game_window = load("res://scenes/game_window.tscn").instance()
		get_node("/root/home_window").queue_free()
		get_node("/root").add_child(game_window)
		game_window.load_data(game_window_serialized, true)

	# Load my player
	var my_id = get_tree().get_network_unique_id()
	var my_player_number = 1 if get_tree().is_network_server() else 2
	var my_grid = game_window.get_node("grid_player%s" % my_player_number)
	my_grid.set_network_master(my_id)

	# Load other player
	var enemy_player_number = 2 if get_tree().is_network_server() else 1
	var grid = game_window.get_node("grid_player%s" % enemy_player_number)
	grid.set_network_master(enemy_info.id)

	# Tell server (remember, server is always ID=1) that this peer is done pre-configuring.
	# The server can call get_tree().get_rpc_sender_id() to find out who said they were done.
	if get_tree().is_network_server():
		done_preconfiguring()
	else:
		rpc_id(1, "done_preconfiguring")


remotesync func done_preconfiguring():
		# Here are some checks you can do, for example
	assert(get_tree().is_network_server())

	players_done += 1
	if players_done == 2:
		rpc("post_configure_game")
		players_done = 0


remotesync func post_configure_game():
	# Only the server is allowed to tell a client to unpause
	if 1 == get_tree().get_rpc_sender_id():
		get_tree().set_pause(false)
		# Game starts now!


func get_enemy_grid() -> MyGrid:
	if get_tree().is_network_server():
		return game_window.get_node("grid_player2") as MyGrid
	else:
		return game_window.get_node("grid_player1") as MyGrid


func get_my_grid() -> MyGrid:
	if !get_tree().is_network_server():
		return game_window.get_node("grid_player2") as MyGrid
	else:
		return game_window.get_node("grid_player1") as MyGrid
