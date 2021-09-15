class_name Power
extends Node2D


func try_get_random_piece(enemy_grid) -> Piece:
	var piece: Piece = enemy_grid.get_random_piece()
	var max_loops = 10
	while piece.has_node(get_name()) and max_loops > 0:
		piece = enemy_grid.get_random_piece()
		max_loops -= 1
	return piece
