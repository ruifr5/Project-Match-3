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


func mid_position_x(position_array: Array) -> int:
	var pos = 0
	for gp in position_array:
		pos += gp.x
	return pos / position_array.size()


func _on_grid_player1_matched(grid_positions, color):
	$arena.queue_spawn_unit(mid_position_x(grid_positions), Vector2.UP, color)
	$grid_player1/grid_hp.heal_positions(grid_positions)


func _on_grid_player2_matched(grid_positions, color):
	$arena.queue_spawn_unit(mid_position_x(grid_positions), Vector2.DOWN, color)
	$grid_player2/grid_hp.heal_positions(grid_positions)


func _on_arena_end_reached(position_x, allegiance):
	if allegiance == Vector2.DOWN:
		$grid_player1/grid_hp.attack_col(position_x)
	else:
		$grid_player2/grid_hp.attack_col(position_x)
