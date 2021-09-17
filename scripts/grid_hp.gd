class_name GridHP
extends Node2D

# IMPORTANT
# must have a grid as parent

export (int) var max_tile_hp = 3

# parent settings
onready var width = get_parent().width
onready var height = get_parent().height
onready var offset = get_parent().offset
onready var all_tiles = make_2d_array()

signal gameover(loser_allegiance)

var tiles = [
	preload("res://scenes/grid_hp_tile/grid_hp_tile_light.tscn"),
	preload("res://scenes/grid_hp_tile/grid_hp_tile_dark.tscn")
]


func _ready():
	init_tile_positions()


func make_2d_array():
	var array = []
	for x in width:
		array.append([])
		for y in height:
			var new_tile = tiles[x % 2].instance()
			new_tile.set_max_hp(max_tile_hp)
			array[x].append(new_tile)
			add_child(new_tile)
	return array


func init_tile_positions():
	var parent_grid = get_parent().all_pieces
	for x in width:
		for y in height:
			all_tiles[x][y].position = parent_grid[x][y].position


func attack_col(grid_position_x, damage = 3):
	for y in height:
		var new_y = y if get_parent().should_mirror() else height-1 - y
		var tile = all_tiles[grid_position_x][new_y]
		if tile.hp > 0:
			tile.damage(damage)
			break
	check_gameover()


func attack_position(grid_position, damage = 3):
	all_tiles[grid_position.x][grid_position.y].damage(damage)
	check_gameover()


func heal_positions(grid_positions: Array):
	for gp in grid_positions:
		all_tiles[gp.x][gp.y].heal(1)


func is_a_column_dead() -> bool:
	for x in width:
		var count = 0
		for y in height:
			if all_tiles[x][y].destroyed:
				count += 1
		if count >= height:
			return true
	return false


func check_gameover():
	if is_a_column_dead():
		emit_signal("gameover", get_parent().allegiance)
