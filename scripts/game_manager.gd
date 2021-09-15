extends Node

var possible_units = {
	fire = preload("res://scenes/units/fire_unit.tscn"),
	water = preload("res://scenes/units/water_unit.tscn"),
	earth = preload("res://scenes/units/earth_unit.tscn"),
}

# game match tiles
var possible_pieces = [
	preload("res://scenes/pieces/water_piece.tscn"),
	preload("res://scenes/pieces/earth_piece.tscn"),
	preload("res://scenes/pieces/fire_piece.tscn"),
#	preload("res://scenes/pieces/yellow_piece.tscn"),	# placeholder
#	preload("res://scenes/pieces/pink_piece.tscn"),		# placeholder
]

var powers = {
	water = preload("res://scenes/piece_powers/water_power.tscn"),
	earth = preload("res://scenes/piece_powers/earth_power.tscn")
}

func _init():
	randomize()


func _enter_tree():
	$arena.connect("end_reached", self, "_on_arena_end_reached")
	$arena.possible_units = possible_units
	$grid_player1.possible_pieces = possible_pieces
	$grid_player2.possible_pieces = possible_pieces


func _ready():
	quit_if_important_node_missing()


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
	activate_powers(color, grid_positions.size(), $grid_player2, centered_position)


func _on_grid_player2_matched(grid_positions, centered_position, color):
	$arena.queue_spawn_unit(center(grid_positions).x, Vector2.DOWN, color)
	$grid_player2/grid_hp.heal_positions(grid_positions)
	activate_powers(color, grid_positions.size(), $grid_player1, centered_position)


func _on_arena_end_reached(position_x, allegiance):
	if allegiance == Vector2.DOWN:
		$grid_player1/grid_hp.attack_col(position_x)
	else:
		$grid_player2/grid_hp.attack_col(position_x)


func activate_powers(color, match_count, enemy_grid, origin):
	var normal_match_count = 3
	var bonus_match_count = match_count - normal_match_count
	if color in powers.keys() and bonus_match_count > 0:
		for n in bonus_match_count:
			var power = powers[color].instance()
			power.exec(enemy_grid, origin)
