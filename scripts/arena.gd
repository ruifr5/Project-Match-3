extends Node2D

export (int) var width
export (int) var height
export (int) var grid_width
export (float) var unit_speed = 0.4
onready var offset = width / grid_width

#[[unit, target], ...]
var moving_units = []

var possible_units = {
	fire = preload("res://scenes/units/fire_unit.tscn"),
	water = preload("res://scenes/units/water_unit.tscn"),
	earth = preload("res://scenes/units/earth_unit.tscn"),
}

signal unit_collision(unit1, unit2)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	move_all_units()


func spawn_unit(grid_position_x, run_direction, color):
	if !possible_units.has(color):
		return
	var unit = possible_units[color].instance()
	unit.allegiance = run_direction
	unit.position = calc_unit_spawn_position(unit, grid_position_x, run_direction)
	add_child(unit)
	moving_units.append([unit, calc_target(unit, run_direction)])


func remove_unit(unit):
	for entry in moving_units:
		if entry[0] == unit:
			moving_units.erase(entry)
			break


func clamp_vector(vector):
	return Vector2(clamp(vector.x, 0, width), clamp(vector.y, 0, height))


func calc_target(unit, direction: Vector2):
	if direction == Vector2.UP:
		return Vector2(unit.position.x, 0)
	if direction == Vector2.DOWN:
		return Vector2(unit.position.x, height)


func calc_unit_spawn_position(unit, grid_position_x, run_direction) -> Vector2:
	var unit_half_size = unit.get_node("Sprite").get_texture().get_size().x / 2
	var y = height - unit_half_size if run_direction == Vector2.UP else unit_half_size 
	return Vector2(grid_position_x * offset + unit_half_size, y)


func move_unit(unit: KinematicBody2D, target: Vector2):
	var direction = target - unit.position
	if unit.position.y > 0 && unit.position.y < height:
		var collision = unit.move_and_collide(direction.normalized() * unit_speed)
		if collision && unit.allegiance != collision.collider.allegiance:
			emit_signal("unit_collision", unit, collision.collider)
	else:
		remove_unit(unit)
		unit.die()


func move_all_units():
	for move_info in moving_units:
		move_unit(move_info[0], move_info[1])
