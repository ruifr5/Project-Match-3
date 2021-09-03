extends Node2D

export (int) var width
export (int) var height
export (int) var x_start
export (int) var y_start
export (int) var offset
export (Rect2) var wrap_area
export (float) var destroy_timer = 0.3
export (float) var collapse_timer = 0.1
export (float) var refill_timer = 0
export (float) var collapse_seconds = 0.5


var possible_pieces = [
	preload("res://scenes/blue_piece.tscn"),
	preload("res://scenes/green_piece.tscn"),
	preload("res://scenes/orange_piece.tscn")
]

# piece array
var all_pieces

# touch variables
var touch_down = Vector2(0,0)
var touch_up = Vector2(0,0)
var controlling = false
var locked = false

var movement_start_grid_position
var old_movement_direction


# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	all_pieces = make_2d_array()
	spawn_pieces()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	touch_input()


func _input(event):
	if event is InputEventMouseMotion && controlling:
		var new_direction = clamp_movement_distance(zero_smallest_dimention(get_global_mouse_position() - touch_down))

		if !old_movement_direction:
			old_movement_direction = new_direction
		elif abs(old_movement_direction.x) == 0 && abs(new_direction.x) != 0:
			reset_column_pixel_position(movement_start_grid_position.x)
		elif abs(old_movement_direction.y) == 0 &&  abs(new_direction.y) != 0:
			reset_row_pixel_position(movement_start_grid_position.y)
		
		move_pieces(movement_start_grid_position, new_direction)
		old_movement_direction = new_direction


func make_2d_array():
	var array = []
	for x in width:
		array.append([])
		for y in height:
			array[x].append(null)
	return array
	
	
func spawn_pieces():
	for x in width:
		var empty_slots_above = 0
		var spawn_offset = 0
		for y in height:
			if !all_pieces[x][y]:
				var thread = Thread.new()
	#			choose a random number and store it
				var rand = floor(rand_range(0, possible_pieces.size()))
	#			instanciate that piece from the array
				var piece = possible_pieces[rand].instance()
	#			remove starting matches
				var new_piece_id = 0
				while match_at(x,y,piece.color) && new_piece_id < possible_pieces.size():
					piece = possible_pieces[new_piece_id].instance()
					new_piece_id += 1
	#			set wrap area information
				piece.get_node("SpriteScreenWrap").wrapArea = wrap_area
#				count empty slots above to determine the spawn offset for each piece
				if empty_slots_above == 0 && y < height - 1:
					for k in range(y + 1, height):
						if !all_pieces[x][k]:
							empty_slots_above += 1
	#			set position and save piece to array
				piece.position = grid_to_pixel(Vector2(x, height + spawn_offset))
				add_child(piece)
				all_pieces[x][y] = piece
#				increment spawn offset
				if spawn_offset < empty_slots_above:
					spawn_offset += 1
#				disable vertical wrap arround to remove noise from animation
				(piece as Node2D).get_node("SpriteScreenWrap").setVerticalWrap(false)
#				animate movement
				piece.move(grid_to_pixel(Vector2(x,y)), collapse_seconds, Tween.TRANS_EXPO, Tween.EASE_IN_OUT)
#				re-enable vertical wrap arround after movement ends
				thread.start(piece.get_node("SpriteScreenWrap"), "enableVerticalWrapAfterDelay", collapse_seconds)


func match_at(x, y, color):
	if x > 1:
		if all_pieces[x-1][y] && all_pieces[x-2][y]:
			if all_pieces[x-1][y].color == color && all_pieces[x-2][y].color == color:
				return true
	if y > 1:
		if all_pieces[x][y-1] && all_pieces[x][y-2]:
			if all_pieces[x][y-1].color == color && all_pieces[x][y-2].color == color:
				return true
	return false


# returns true if a match was found
func find_matches():
	var match_found = false
	for x in width:
		for y in height:
			if all_pieces[x][y]:
				var current_color = all_pieces[x][y].color
				if x > 0 && x < width - 1:
					if all_pieces[x-1][y] && all_pieces[x+1][y]:
						if all_pieces[x-1][y].color == current_color && all_pieces[x+1][y].color == current_color:
							all_pieces[x-1][y].mark_matched()
							all_pieces[x][y].mark_matched()
							all_pieces[x+1][y].mark_matched()
							match_found = true
				if y > 0 && y < height - 1:
					if all_pieces[x][y-1] && all_pieces[x][y+1]:
						if all_pieces[x][y-1].color == current_color && all_pieces[x][y+1].color == current_color:
							all_pieces[x][y-1].mark_matched()
							all_pieces[x][y].mark_matched()
							all_pieces[x][y+1].mark_matched()
							match_found = true
	locked = match_found
	if match_found:
		destroy_matched()
	return match_found


# método para match em "blob"
#func spread_match(origin_x, origin_y, color):
#	var piece = all_pieces[origin_x][origin_y]
#	if (piece.matched):
#		return
#	piece.mark_matched()
#	for x in range(-1,2):
#		var new_x = origin_x + x
#		if  new_x >= 0 && new_x < width && all_pieces[new_x][origin_y].color == color:
#			spread_match(new_x, origin_y, color)
#	for y in range(-1,2):
#		var new_y = origin_y + y
#		if  new_y >= 0 && new_y < height && all_pieces[origin_x][new_y].color == color:
#			spread_match(origin_x, new_y, color)


func grid_to_pixel(position):
	var new_x = x_start + offset * position.x
	var new_y = y_start + -offset * position.y
	return Vector2(new_x, new_y)


func pixel_to_grid(position):
	var new_x = round((position.x - x_start) / offset)
	var new_y = round((position.y - y_start) / -offset)
	return Vector2(new_x, new_y)


func centered_pixel_in_grid(position):
	return grid_to_pixel(pixel_to_grid(position))


func is_in_grid(grid_position):
	if grid_position.x >= 0 && grid_position.x < width:
		if grid_position.y >= 0 && grid_position.y < height:
			return true;
	return false


func touch_input():
	if Input.is_action_just_pressed("ui_touch") && !locked:
		touch_down = get_global_mouse_position()
		var touch_down_grid_position = pixel_to_grid(touch_down)
		if is_in_grid(touch_down_grid_position):
			controlling = true
			movement_start_grid_position = touch_down_grid_position
		
	if Input.is_action_just_released("ui_touch") && controlling:
		controlling = false
		var grid_backup = all_pieces.duplicate(true)
		update_pieces_grid_position_to_match_pixel_position()
#		reset positions if there was no match
		if !find_matches():
			all_pieces = grid_backup
		reset_pieces_pixel_position()


func move_pieces(position, direction):
	direction = zero_smallest_dimention(direction)
	if abs(direction.x) > 0:
		for column in all_pieces:
			if column[position.y]:
				column[position.y].move_as_group(direction)
	elif abs(direction.y) > 0:
		for row in all_pieces[position.x]:
			if row:
				row.move_as_group(direction)


func update_pieces_grid_position_to_match_pixel_position():
	var backup = all_pieces.duplicate(true)
#	for piece in get_children():
	for x in width:
		for y in height:
			var piece = backup[x][y]
			if piece:
				var real_position = pixel_to_grid(piece.position)
		#		overflow right
				if real_position.x >= width:
					real_position.x = real_position.x - width
		#		overflow left
				if real_position.x < 0:
					real_position.x = width + real_position.x
		#		overflow down
				if real_position.y >= height:
					real_position.y = real_position.y - height
		#		overflow up
				if real_position.y < 0:
					real_position.y = height + real_position.y
				all_pieces[real_position.x][real_position.y] = piece


func reset_pieces_pixel_position():
	for x in width:
		for y in height:
			var piece = all_pieces[x][y]
			if piece:
				piece.stop_movement()
				piece.position = grid_to_pixel(Vector2(x,y))


func reset_column_pixel_position(column_id):
	var row_id = 0
	for piece in all_pieces[column_id]:
		if piece:
			piece.stop_movement()
			piece.position = grid_to_pixel(Vector2(column_id, row_id))
			row_id += 1


func reset_row_pixel_position(row_id):
	var column_id = 0
	for column in all_pieces:
		var piece = column[row_id]
		if piece:
			piece.stop_movement()
			piece.position = grid_to_pixel(Vector2(column_id, row_id))
			column_id += 1


func zero_smallest_dimention(position):
	if abs(position.x) > abs(position.y):
		position.y = 0
	else:
		position.x = 0
	return position


func clamp_movement_distance(distance):
#	moving right
	if distance.x > 0:
		distance.x = clamp(distance.x, 0, (x_start + offset * (width - 1)) - (x_start))
#	moving left
	elif distance.x < 0:
		distance.x = clamp(distance.x, (x_start) - (x_start + offset * (width - 1)), 0)
#	moving up
	elif distance.y < 0:
		distance.y = clamp(distance.y, (y_start) - (y_start + offset * (height - 1)), 0)
#	moving down
	elif distance.y > 0:
		distance.y = clamp(distance.y, 0, (y_start + offset * (height - 1)) - (y_start))
	return distance


func destroy_matched():
#	wait before starting
	yield(get_tree().create_timer(destroy_timer), "timeout")
	for x in width:
		for y in height:
			if all_pieces[x][y] && all_pieces[x][y].matched:
				all_pieces[x][y].queue_free()
				all_pieces[x][y] = null
	collapse_columns()


func collapse_columns():
#	wait before starting
	yield(get_tree().create_timer(collapse_timer), "timeout")
	for x in width:
		for y in height:
			if !all_pieces[x][y]:
				for k in range(y + 1, height):
					if all_pieces[x][k]:
						all_pieces[x][k].move(grid_to_pixel(Vector2(x, y)))
						all_pieces[x][y] = all_pieces[x][k]
						all_pieces[x][k] = null
						break
	refill_grid()


func refill_grid():
#	wait before starting
	yield(get_tree().create_timer(refill_timer), "timeout")
	spawn_pieces()
#	wait for pieces to finish falling
	yield(get_tree().create_timer(collapse_seconds), "timeout")
	find_matches()


# debug function
func print_colors():
	var toprint = make_2d_array()
	for x in width:
		for y in height:
			toprint[x][y] = (all_pieces[x][y].color)
	for col in toprint:
		print(col)
	print("-------------------------------------------------------")
