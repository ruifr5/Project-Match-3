extends Node2D

export (int) var width
export (int) var height
export (int) var grid_width
export (float) var unit_speed = 1
onready var offset = width / grid_width
var unit_half_size

#[[unit, target], ...]
var moving_units = []

var possible_units = {
	fire = preload("res://scenes/units/fire_unit.tscn"),
	water = preload("res://scenes/units/water_unit.tscn"),
	earth = preload("res://scenes/units/earth_unit.tscn"),
}

# normal -> normal movement
# correction -> moving into play area
enum MoveType { NORMAL, CORRECTION}

signal unit_collision(unit1, unit2)


# Called when the node enters the scene tree for the first time.
func _ready():
	var unit = possible_units.fire.instance()
	unit_half_size = unit.get_node("Sprite").get_texture().get_size().x / 2
	unit.queue_free()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	move_all_units()
#	touch_input()


func touch_input():
	if Input.is_action_just_pressed("ui_touch"):
#		debug
		spawn_unit_debug(get_local_mouse_position(), Vector2.UP, "fire")
	if Input.is_action_just_pressed("ui_touch_2"):
#		debug
		spawn_unit_debug(get_local_mouse_position(), Vector2.DOWN, "fire")


func spawn_unit(grid_position_x, run_direction, color):
	if !possible_units.has(color):
		return
	var unit = possible_units[color].instance()
	unit.allegiance = run_direction
	unit.position = calc_unit_spawn_position(unit, grid_position_x, run_direction)
	add_child(unit)
	moving_units.append([unit, calc_target(unit, run_direction)])


func spawn_unit_debug(mouse_position, run_direction, color):
	if !possible_units.has(color):
		return
	var unit = possible_units[color].instance()
	unit.allegiance = run_direction
	unit.position = mouse_position
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
#	check if unit is outside of play area
	var correction = Vector2(0,0)
	if unit.position.x < offset / 6:
		correction.x = offset * grid_width / 2
	elif unit.position.x > width - offset / 6:
		correction.x = -offset * grid_width / 2
	
	if direction.normalized() == Vector2.UP:
		var y = -offset if !correction.length() > 0 else unit.position.y
		return Vector2(unit.position.x, y) + correction
	if direction.normalized() == Vector2.DOWN:
		var y = height + offset if !correction.length() > 0 else unit.position.y
		return Vector2(unit.position.x, y) + correction


func calc_unit_spawn_position(unit, grid_position_x, run_direction) -> Vector2:
	var y = height - unit_half_size if run_direction == Vector2.UP else unit_half_size 
	return Vector2(grid_position_x * offset + unit_half_size, y)


func move_unit(unit: KinematicBody2D, target: Vector2, move_type = MoveType.NORMAL):
	var direction = target - unit.position
	var speed = unit_speed * 10 if move_type == MoveType.CORRECTION else unit_speed
	if unit.position.y < unit_half_size && direction.normalized() == Vector2.UP || unit.position.y > height - unit_half_size && direction.normalized() == Vector2.DOWN:
		remove_unit(unit)
		unit.die()
	else:
		var collision = unit.move_and_collide(calc_avoid_vector(unit) + direction.normalized() * speed)
		if collision && unit.allegiance != collision.collider.allegiance:
			emit_signal("unit_collision", unit, collision.collider)


func calc_avoid_vector(unit):
	var count = 0
	var to_return = Vector2()
	for entry in moving_units:
		if unit.allegiance == entry[0].allegiance && unit != entry[0] && unit.position.distance_to(entry[0].position) < unit_half_size * 1.5:
			var aaaa = unit.position - entry[0].position
			to_return += aaaa
			count += 1
	if count > 0:
		to_return /= count
		to_return = to_return.normalized()
		return to_return
	return Vector2(0,0)


func move_all_units():
	for move_info in moving_units:
		var unit = move_info[0]
		var target = calc_target(unit, unit.allegiance)
		var move_type = MoveType.CORRECTION if target.y == unit.position.y else MoveType.NORMAL
		move_unit(unit, target, move_type)
