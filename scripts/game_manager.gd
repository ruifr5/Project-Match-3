extends Node


# Called when the node enters the scene tree for the first time.
#func _ready():
#	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _on_grid_player1_matched(grid_positions, color):
	$arena.queue_spawn_unit(mid_position_x(grid_positions), Vector2.UP, color)


func _on_grid_player2_matched(grid_positions, color):
	$arena.queue_spawn_unit(mid_position_x(grid_positions), Vector2.DOWN, color)


func mid_position_x(position_array: Array) -> int:
	var pos = 0
	for gp in position_array:
		pos += gp.x
	return pos / position_array.size()
