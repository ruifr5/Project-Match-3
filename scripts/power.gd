class_name Power
extends Node2D

const particle_effect = preload("res://scenes/particle_effect.tscn")

func try_get_random_piece(enemy_grid, color_to_avoid = null) -> Piece:
	var piece: Piece = enemy_grid.get_random_piece(color_to_avoid)
	var max_loops = 10
	while (piece.has_node(get_name()) or piece.color == color_to_avoid) and max_loops > 0:
		piece = enemy_grid.get_random_piece(color_to_avoid)
		max_loops -= 1
	return piece


#returns particle duration
func emit_particle_effect(origin: Vector2, target: Vector2, color: Color = Color(1,1,1,1)) -> float:
	var pe = particle_effect.instance()
	pe.modulate = color
	var direction = origin.direction_to(target)
	var distance = origin.distance_to(target)
	pe.position -= direction * distance
	add_child(pe)
	pe.start(direction, distance)
	return pe.lifetime
