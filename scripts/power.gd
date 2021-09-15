class_name Power
extends Node2D

const particle_effect = preload("res://scenes/particle_effect.tscn")

func try_get_random_piece(enemy_grid) -> Piece:
	var piece: Piece = enemy_grid.get_random_piece()
	var max_loops = 10
	while piece.has_node(get_name()) and max_loops > 0:
		piece = enemy_grid.get_random_piece()
		max_loops -= 1
	return piece


func emit_particle_effect(origin: Vector2, target: Vector2, color: Color = Color(1,1,1,1)):
	var pe = particle_effect.instance()
	pe.modulate = color
	var direction = origin.direction_to(target)
	var distance = origin.distance_to(target)
	pe.position -= direction * distance
	add_child(pe)
	pe.start(direction, distance)
