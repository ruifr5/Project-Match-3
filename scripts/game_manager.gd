extends Node


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_grid_player1_matched(grid_positions, color, count):
	var pos = round(rand_range(0, grid_positions.size() - 1))
	$arena.spawn_unit(grid_positions[pos].x, Vector2.UP, color)


func _on_grid_player2_matched(grid_positions, color, count):
	var pos = round(rand_range(0, grid_positions.size() - 1))
	$arena.spawn_unit(grid_positions[pos].x, Vector2.DOWN, color)
