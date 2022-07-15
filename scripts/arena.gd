extends Node2D

export (int) var width
export (int) var height
export (int) var grid_width
export (float) var unit_speed = 50
onready var offset = width / grid_width

# unit variables
var moving_units = [] #[ { unit, spawn_time, spawn_position }, ...]
var unit_half_size

# spawn variables
# dictionary = { allegiance: [] }
onready var spawn_queues = { Vector2.UP: make_2d_array(grid_width), Vector2.DOWN: make_2d_array(grid_width) }
var spawn_areas_block = { Vector2.UP: [], Vector2.DOWN: [] }

# ****IMPORTANT**** must be set
# dictionary { unit_type = preload(...), ...}
var possible_units

# NORMAL -> normal movement
# CORRECTION -> moving into play area
enum MoveType { NORMAL, CORRECTION}


signal end_reached(position_x, allegiance)


# Called when the node enters the scene tree for the first time.
func _ready():
	if !possible_units:
		queue_free()
		return
	init_unit_half_size()
	init_spawn_areas()


func _process(_delta):
	if moving_units.size() > 0:
		 check_if_units_reached_end()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta):
	try_to_spawn_next_unit()
	touch_input_debug()
#	print(moving_units.size())


func init_unit_half_size():
	var unit = possible_units[possible_units.keys()[0]].instance()
	unit_half_size = unit.pixel_size / 2
	unit.queue_free()


# create areas that detect spawn_blocks
func init_spawn_areas():
	for x in grid_width * 2:
		var area = Area2D.new()
		var collision_shape = CollisionShape2D.new()
		add_child(area)
		area.add_child(collision_shape)
		collision_shape.shape = CircleShape2D.new()
		var radius = unit_half_size * 0.75
		collision_shape.shape.radius = radius
#		top positions
		area.position.x = offset / 2 + x * offset
		area.position.y = radius
		var allegiance
		if x >= grid_width:
#			bottom positions
			area.position.x -= width
			area.position.y =  height - area.position.y
			allegiance = Vector2.UP
			spawn_areas_block[allegiance].append(false)
		else:
			allegiance = Vector2.DOWN
			spawn_areas_block[allegiance].append(false)
#		set signals
#		binds are array of array as a workaround for a godot bug
		area.connect("body_entered", self, "_on_spawn_area_entered", [[allegiance, x % grid_width]]) 
		area.connect("body_exited", self, "_on_spawn_area_exited", [[allegiance, x % grid_width]])


func make_2d_array(length):
	var array = []
	for x in length:
		array.append([])
	return array


func try_to_spawn_next_unit():
	for spawn_queue in spawn_queues[Vector2.UP] + spawn_queues[Vector2.DOWN]:
		if spawn_queue.size():
			var unit_info = spawn_queue.front()
			var spawn_blocked = spawn_areas_block[unit_info[1]][unit_info[0]]
#			if not spawn_blocked spawn unit and pop it
			if !spawn_blocked:
#				unit_info: 0-> grid_position_x, 1-> run_direction (aka allegiance), 2-> color, 3-> spawn_time
				spawn_unit(unit_info[0], unit_info[1], unit_info[2], unit_info[3])
				spawn_queue.pop_front()


func queue_spawn_unit(grid_position_x, run_direction, color, spawn_time):
	spawn_queues[run_direction][grid_position_x].append([grid_position_x, run_direction, color, spawn_time])


# todo: apagar
func touch_input_debug():
#	if Input.is_action_just_pressed("ui_touch"):
##		debug
#		spawn_unit_debug(get_local_mouse_position(), Vector2.UP, "fire", get_parent().game_time)
	if Input.is_action_just_pressed("ui_touch_2"):
#		debug
		for x in 6:
#			spawn_unit_debug(get_local_mouse_position(), Vector2.DOWN, ["fire","fire","fire"][floor(rand_range(0,3))])
#			queue_spawn_unit(2, Vector2.DOWN, "fire")
#			queue_spawn_unit(1.5, Vector2.DOWN, "water")
#			queue_spawn_unit(3, Vector2.UP, "earth")
#			queue_spawn_unit(3.5, Vector2.UP, "water")
			queue_spawn_unit(0, Vector2.DOWN, ["fire","water","earth"][floor(rand_range(0,3))], get_parent().game_time)
			queue_spawn_unit(1, Vector2.UP, ["fire","water","earth"][floor(rand_range(0,3))], get_parent().game_time)


func on_grid_match(grid_position_x, run_direction, color, spawn_time):
	queue_spawn_unit(grid_position_x, run_direction, color, spawn_time)


func spawn_unit(grid_position_x, run_direction, color, spawn_time):
	if !possible_units.has(color):
		return
	var unit = possible_units[color].instance()
	unit.speed = unit_speed
	unit.spawn_time = spawn_time
	unit.allegiance = run_direction
	unit.position = calc_unit_spawn_position(grid_position_x, run_direction)
#	(unit as Unit).scale *= rand_range(0.8, 1) # size range
	add_child(unit)
	moving_units.append({"unit": unit, "spawn_time": spawn_time, "spawn_position": unit.position})


func spawn_unit_debug(mouse_position, run_direction, color, spawn_time):
	if !possible_units.has(color):
		return
	var unit = possible_units[color].instance()
	unit.speed = unit_speed
	unit.allegiance = run_direction
	unit.position = mouse_position
	add_child(unit)
	moving_units.append({"unit": unit, "spawn_time": spawn_time, "spawn_position": unit.position})


func remove_from_moving_units(unit):
	for entry in moving_units:
		if !is_instance_valid(entry.unit):
			moving_units.erase(entry)
		elif entry.unit == unit:
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
		return Vector2(unit.position.x, -offset) + correction
	if direction.normalized() == Vector2.DOWN:
		return Vector2(unit.position.x, height + offset) + correction


func calc_unit_spawn_position(grid_position_x, run_direction) -> Vector2:
	var y = height - unit_half_size if run_direction == Vector2.UP else unit_half_size 
	return Vector2(offset / 2 + grid_position_x * offset, y)


var a = 0
var testpos = null
func sync_position(move_info):
	var start_time = move_info.spawn_time
	var life_time_seconds = float(OS.get_ticks_msec() - start_time) / 1000
	var real_pos_y = move_info.spawn_position.y + move_info.unit.allegiance.y * unit_speed * life_time_seconds
#	print ("lifetime", life_time_seconds)
	
#	if round(real_pos_y) != round(move_info.unit.position.y):
#		move_info.unit.speed = unit_speed
#	if a % 100 == 0:
#		if round(real_pos_y) == round(move_info.unit.position.y):
#			print(true, a)
#		print("2 calc -> ", real_pos_y, "   \\    real -> ", move_info.unit.position.y, "   \\    lifetime -> ", life_time_seconds)
#	a += 1
	pass


func check_if_units_reached_end():
	for move_info in moving_units:
		if move_info:
			if is_instance_valid(move_info.unit):
				var unit = move_info.unit
				if unit.position.y < unit_half_size && unit.allegiance == Vector2.UP || unit.position.y > height - unit_half_size && unit.allegiance == Vector2.DOWN:
#					reached enemy base
					emit_signal("end_reached", unit.position.x / offset, unit.allegiance)
					remove_from_moving_units(unit)
					unit.die()
#				sync_position(move_info)
			else:
				moving_units.erase(move_info)


# binds[0]: 0-> allegiance, 1-> index of spawn_area_block
func _on_spawn_area_entered(_body, binds):
#	set block to true
	spawn_areas_block[binds[0]][binds[1]] = _body.allegiance == binds[0]


func _on_spawn_area_exited(_body, binds):
#	set block to false
	spawn_areas_block[binds[0]][binds[1]] = false


func processGameEvent(event):
	match event:
		GameEvent.Event.UNIT_FIGHT:
			return
		GameEvent.Event.UNIT_GOAL:
			return
		GameEvent.Event.UNIT_SPAWN:
			return

