class_name GameWindow
extends Node

var possible_units = {
	fire = preload("res://scenes/units/fire_unit.tscn"),
	water = preload("res://scenes/units/water_unit.tscn"),
	earth = preload("res://scenes/units/earth_unit.tscn"),
}

# game match tiles
var possible_pieces = {
	fire = preload("res://scenes/pieces/fire_piece.tscn"),
	water = preload("res://scenes/pieces/water_piece.tscn"),
	earth = preload("res://scenes/pieces/earth_piece.tscn"),
	useless = preload("res://scenes/pieces/useless_piece.tscn"),
#	purple = preload("res://scenes/pieces/yellow_piece.tscn"),	# placeholder
}

var powers = {
	fire = preload("res://scenes/piece_powers/fire_power.tscn"),
	water = preload("res://scenes/piece_powers/water_power.tscn"),
	earth = preload("res://scenes/piece_powers/earth_power.tscn"),
}

var gameover = false


func _init():
	randomize()


func _enter_tree():
	$arena.connect("end_reached", self, "_on_arena_end_reached")
	$arena.possible_units = possible_units
	$grid_player1.possible_pieces = possible_pieces
	$grid_player2.possible_pieces = possible_pieces


func _process(_delta):
	$debug/a.text = str($grid_player1.piece_count_dict)
	$debug/b.text = str($grid_player2.piece_count_dict)


func _ready():
	quit_if_important_node_missing()


func _input(event):
	if event.is_action_pressed("ui_cancel"):
		toggle_menu()


func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_GO_BACK_REQUEST:
		go_to_home()


func show_menu(value):
	$menu_layer/Control.visible = value


func toggle_menu():
	$menu_layer/Control.visible = !$menu_layer/Control.visible


func quit_if_important_node_missing():
	var error_msgs = []
	for node in ["arena", "grid_player1", "grid_player2"]:
		if !get_node(node):
			error_msgs.append(str(node, " not instanced properly"))
	if error_msgs.size():
		printerr("ERRORS: ", error_msgs)
#		close game
		get_tree().quit()


func center(grid_positions):
	var center = Vector2(0, 0)
	for gp in grid_positions:
		center += gp
	return center / grid_positions.size()


func _on_grid_player1_matched(grid_positions, centered_position, color):
	$arena.queue_spawn_unit(center(grid_positions).x, Vector2.UP, color)
	$grid_player1/grid_hp.heal_positions(grid_positions)
	activate_powers(color, grid_positions.size(), centered_position, $grid_player2)


func _on_grid_player2_matched(grid_positions, centered_position, color):
	$arena.queue_spawn_unit(center(grid_positions).x, Vector2.DOWN, color)
	$grid_player2/grid_hp.heal_positions(grid_positions)
	activate_powers(color, grid_positions.size(), centered_position, $grid_player1)


func _on_arena_end_reached(grid_position_x, allegiance):
	if allegiance == Vector2.DOWN:
		$grid_player1/grid_hp.attack_col(grid_position_x)
	else:
		$grid_player2/grid_hp.attack_col(grid_position_x)


func activate_powers(color, match_count, origin, enemy_grid):
	if get_tree().has_network_peer() and !get_tree().is_network_server():
		return
	var normal_match_count = 3
	var bonus_match_count = match_count - normal_match_count
	if color in powers.keys() and bonus_match_count > 0:
		for n in bonus_match_count:
			var power = powers[color].instance()
			var target = power.exec(enemy_grid, origin)
			if get_tree().has_network_peer():
				rpc_id(Network.enemy_info.id, "activate_power_remote", color, { x = origin.x, y = origin.y }, { x = target.x, y = target.y })


remote func activate_power_remote(color, origin, target):
	if color in powers.keys():
		origin = Vector2(origin.x, origin.y)
		target = Vector2(target.x, target.y)
		var power = powers[color].instance()
		var target_grid = get_node("/root/game_window/grid_player2") if origin.y > target.y else get_node("/root/game_window/grid_player1")
		power.exec_target(target_grid, origin, target)


func pause():
	get_tree().paused = true


func unpause():
	get_tree().paused = false


func _on_grid_hp_gameover(loser_allegiance):
	if !gameover:
		gameover = true
		pause()
		$grid_player1.lock()
		$grid_player2.lock()
		$gameover_layer/Control/winner_label.text %= "Player 1" if loser_allegiance == Vector2.DOWN else "Player 2"
		$gameover_layer/Control.visible = true


func serialize() -> Dictionary:
	var obj = {
		grid_player1 = $grid_player1.serialize(),
		grid_player2 = $grid_player2.serialize(),
	}
	return obj


func unserialize(serialized) -> Dictionary:
	var obj = {
		grid_player1 = $grid_player1.unserialize(serialized["grid_player1"]),
		grid_player2 = $grid_player2.unserialize(serialized["grid_player2"]),
	}
	return obj


func load_data(data: Dictionary, serialized = false):
	if serialized:
		data = unserialize(data)
	for key in data:
		get_node(key).load_data(data[key])


func _on_exit_button_pressed():
	go_to_home()


func _on_continue_button_pressed():
	show_menu(false)


func go_to_home():
	get_tree().change_scene("res://scenes/home_window.tscn")
	queue_free()
