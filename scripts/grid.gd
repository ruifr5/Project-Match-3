class_name MyGrid
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
export (Vector2) var allegiance = Vector2.UP
export (float) var locked_piece_move_distance = 2


# ****IMPORTANT**** must be set
# array [ preload(...), ...]
var possible_pieces

# piece arrays
var all_pieces
var matched_pieces_vertical = []
var matched_pieces_horizontal = []
var disabled_positions: PoolVector2Array = [] # not used yet

# count of how many of each piece there is, { color : count }
var piece_count_dict =  {}

# touch variables
var touch_down: Vector2
var touch_up: Vector2
var touch_idx
var controlling = false
var locked = false
var movement_start_grid_position
var old_movement_direction

enum MovementType {INSTANT, ANIMATED}

# signals
signal matched(grid_positions, color)


func _enter_tree():
	if !possible_pieces:
		queue_free()
		return
	init_piece_count_array()
	all_pieces = make_2d_array()
	spawn_pieces(MovementType.INSTANT)


func _input(event):
	on_drag(event)
	
	if !locked:
		on_mouse_click()
		on_touch(event)


func should_mirror():
	return allegiance == Vector2.DOWN


func on_drag(event):
	if (event is InputEventMouseMotion or event is InputEventScreenDrag) && controlling:
		var drag_position
		if event is InputEventMouseMotion:
			drag_position = get_global_mouse_position()
		elif event is InputEventScreenDrag and touch_idx == event.index:
			drag_position = event.position
		
		var	new_direction = clamp_movement_distance(zero_smallest_dimention(drag_position - touch_down))
		reset_old_moving_pieces_if_movement_changed_axis(new_direction)
		new_direction = clamp_if_locked(new_direction)
		
		move_pieces(new_direction)
		old_movement_direction = new_direction
		highlight_matches()


func clamp_if_locked(direction):
	var is_locked = false
#	if vertical movement
	if direction.x == 0:
		is_locked = is_vertical_locked(movement_start_grid_position)
#	if horizontal movement
	elif direction.y == 0:
		is_locked = is_horizontal_locked(movement_start_grid_position)
#	limit direction if the row/column is locked
	if is_locked:
		direction = direction.clamped(locked_piece_move_distance)
	return direction


func reset_old_moving_pieces_if_movement_changed_axis(direction):
		if !old_movement_direction:
			old_movement_direction = direction
		elif abs(old_movement_direction.x) == 0 && abs(direction.x) != 0:
			reset_column_pixel_position(movement_start_grid_position.x)
		elif abs(old_movement_direction.y) == 0 &&  abs(direction.y) != 0:
			reset_row_pixel_position(movement_start_grid_position.y)


func on_touch(event):
	if event is InputEventScreenTouch:
#			touch down
			if event.pressed:
				var temp_touch_down = event.position
				var touch_down_grid_position = pixel_to_grid(temp_touch_down)
				if is_in_grid(touch_down_grid_position) && !touch_idx:
					touch_down = temp_touch_down
					touch_idx = event.index
					controlling = true
					movement_start_grid_position = touch_down_grid_position
#			touch up
			else:
				touch_idx = null
				controlling = false
				var grid_backup = all_pieces.duplicate(true)
				all_pieces = get_array_pixel_position_converted_to_grid_position()
		#		reset positions if there was no match
				if !find_matches():
					all_pieces = grid_backup
				reset_pieces_pixel_position()
				highlight_matches()


func on_mouse_click():
#	left click down
	if Input.is_action_just_pressed("ui_touch"):
		touch_down = get_global_mouse_position()
		var touch_down_grid_position = pixel_to_grid(touch_down)
		if is_in_grid(touch_down_grid_position):
			controlling = true
			movement_start_grid_position = touch_down_grid_position
		
#	left click up
	if Input.is_action_just_released("ui_touch") && controlling:
		controlling = false
		var grid_backup = all_pieces.duplicate(true)
		all_pieces = get_array_pixel_position_converted_to_grid_position()
#		reset positions if there was no match
		if !find_matches():
			all_pieces = grid_backup
		reset_pieces_pixel_position()
		highlight_matches()
		
#	right click down
	if Input.is_action_just_pressed("ui_touch_2"):
		var touch_down_grid_position = pixel_to_grid(get_global_mouse_position())
		if is_in_grid(touch_down_grid_position):
			if all_pieces[touch_down_grid_position.x][touch_down_grid_position.y].locked:
				unlock_grid_position(touch_down_grid_position)
			else:
				lock_grid_position(touch_down_grid_position)


func init_piece_count_array():
	for type in possible_pieces:
		var piece = type.instance()
		piece_count_dict[piece.color] = 0
		piece.queue_free()


# todo: criaçao continua de arrays, percorre 2 vezes o array todo, é cópia do find_matches, optimizar
func highlight_matches():
	var temp_arr = get_array_pixel_position_converted_to_grid_position()
#	reset nos highlights
	for x in width:
		for y in height:
			temp_arr[x][y].highlighted = false
#	set higlights
	for x in width:
		for y in height:
			var piece = temp_arr[x][y]
			if piece:
				var current_color = piece.color
#				check horizontal match
				if x > 0 && x < width - 1:
					var left_piece = temp_arr[x-1][y]
					var right_piece = temp_arr[x+1][y]
					if left_piece && right_piece:
						if left_piece.color == current_color && right_piece.color == current_color:
							left_piece.highlighted = true
							piece.highlighted = true
							right_piece.highlighted = true
#				check vertical match
				if y > 0 && y < height - 1:
					var up_piece = temp_arr[x][y-1]
					var down_piece = temp_arr[x][y+1]
					if up_piece && down_piece:
						if up_piece.color == current_color && down_piece.color == current_color:
							up_piece.highlighted = true
							piece.highlighted = true
							down_piece.highlighted = true



func make_2d_array():
	var array = []
	for x in width:
		array.append([])
		for y in height:
			array[x].append(null)
	return array


func get_lowest_count_piece_idx():
	var to_return
	var lowest_count = INF
	var idx = 0
	for key in piece_count_dict.keys():
		if piece_count_dict[key] < lowest_count:
			lowest_count = piece_count_dict[key]
			to_return = idx
		idx += 1
	return to_return


func spawn_pieces(move_type = MovementType.ANIMATED):
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
				var new_piece_id = get_lowest_count_piece_idx()
				var count = 0
				while match_at(x, y, piece.color) && count < possible_pieces.size():
					piece = possible_pieces[new_piece_id].instance()
					new_piece_id = 0 if new_piece_id + 1 >= possible_pieces.size() else new_piece_id + 1
					count += 1
	#			set position and save piece to array
				if should_mirror():
	#				count empty slots above to determine the spawn offset for each piece
					if empty_slots_above == 0 && y < height - 1:
						for k in range(y, height):
							if !all_pieces[x][k]:
								empty_slots_above += 1
							else:
								break
					piece.position = grid_to_pixel(Vector2(x, -empty_slots_above))
					empty_slots_above -= 1
				else:
					piece.position = grid_to_pixel(Vector2(x, height + spawn_offset))
				spawn_offset += 1
				add_child(piece)
				all_pieces[x][y] = piece
				piece_count_dict[piece.color] += 1
				var sprite_screen_wrap = piece.get_node("SpriteScreenWrap")
	#			set wrap area information
				sprite_screen_wrap.wrapArea = wrap_area
				if should_mirror():
					sprite_screen_wrap.flip_v = true
				if move_type == MovementType.INSTANT:
					piece.position = grid_to_pixel(Vector2(x,y))
				else:
	#				disable vertical wrap arround to remove noise from animation
					sprite_screen_wrap.setVerticalWrap(false)
	#				animate movement
					piece.move(grid_to_pixel(Vector2(x,y)), collapse_seconds)#, Tween.TRANS_EXPO, Tween.EASE_IN_OUT)
	#				re-enable vertical wrap arround after movement ends
					thread.start(sprite_screen_wrap, "enableVerticalWrapAfterDelay", collapse_seconds)
					thread.wait_to_finish()
	

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
			var piece = all_pieces[x][y]
			if piece:
				var current_color = piece.color
#				check horizontal match
				if x > 0 && x < width - 1:
					var left_piece = all_pieces[x-1][y]
					var right_piece = all_pieces[x+1][y]
					if left_piece && right_piece:
						if left_piece.color == current_color && right_piece.color == current_color && !is_matched_horizontal(piece):
							match_horizontal(piece)
							match_found = true
#				check vertical match
				if y > 0 && y < height - 1:
					var up_piece = all_pieces[x][y-1]
					var down_piece = all_pieces[x][y+1]
					if up_piece && down_piece:
						if up_piece.color == current_color && down_piece.color == current_color && !is_matched_vertical(piece):
							match_vertical(piece)
							match_found = true
	locked = match_found
	if match_found:
		destroy_matched()
	return match_found


func is_matched_vertical(piece):
	return piece in matched_pieces_vertical


func is_matched_horizontal(piece):
	return piece in matched_pieces_horizontal


func match_vertical(piece):
	if !piece:
		return
	matched_pieces_vertical_append(piece)
	var grid_positions = PoolVector2Array([])	# array with matched positions to emit in signal
	var grid_position = fix_wrapped_position(pixel_to_grid(piece.position))
	var y = grid_position.y - 1
	grid_positions.append(Vector2(grid_position.x, grid_position.y))
#	check up
	while y >= 0:
		var new_piece = all_pieces[grid_position.x][y]
		if new_piece && piece.color == new_piece.color:
			matched_pieces_vertical_append(new_piece)
			grid_positions.append(Vector2(grid_position.x, y))
		else:
			break
		y -= 1
#	check down
	y = grid_position.y + 1
	while y < height:
		var new_piece = all_pieces[grid_position.x][y]
		if new_piece && piece.color == new_piece.color:
			matched_pieces_vertical_append(new_piece)
			grid_positions.append(Vector2(grid_position.x, y))
		else:
			break
		y += 1
	emit_signal("matched", grid_positions, piece.color)


func match_horizontal(piece):
	if !piece:
		return
	matched_pieces_horizontal_append(piece)
	var grid_positions = PoolVector2Array([])	# array with matched positions to emit in signal
	var grid_position = fix_wrapped_position(pixel_to_grid(piece.position))
	var x = grid_position.x - 1
	grid_positions.append(Vector2(grid_position.x, grid_position.y))
#	check left
	while x >= 0:
		var new_piece = all_pieces[x][grid_position.y]
		if new_piece && piece.color == new_piece.color:
			new_piece.mark_matched()
			matched_pieces_horizontal_append(new_piece)
			grid_positions.append(Vector2(x, grid_position.y))
		else:
			break
		x -= 1
#	check right
	x = grid_position.x + 1
	while x < width:
		var new_piece = all_pieces[x][grid_position.y]
		if new_piece && piece.color == new_piece.color:
			new_piece.mark_matched()
			matched_pieces_horizontal_append(new_piece)
			grid_positions.append(Vector2(x, grid_position.y))
		else:
			break
		x += 1
	emit_signal("matched", grid_positions, piece.color)


func matched_pieces_horizontal_append(piece):
	if !(piece in matched_pieces_horizontal):
		matched_pieces_horizontal.append(piece)
		piece.mark_matched()


func matched_pieces_vertical_append(piece):
	if !(piece in matched_pieces_vertical):
		matched_pieces_vertical.append(piece)
		piece.mark_matched()


func get_matched_pieces() -> Array:
	return matched_pieces_horizontal + matched_pieces_vertical


func clear_matched_pieces_array():
	matched_pieces_horizontal.clear()
	matched_pieces_vertical.clear()


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


func move_pieces(direction):
	direction = zero_smallest_dimention(direction)
	if abs(direction.x) > 0:
		for column in all_pieces:
			if column[movement_start_grid_position.y]:
				column[movement_start_grid_position.y].move_as_group(direction)
	elif abs(direction.y) > 0:
		for row in all_pieces[movement_start_grid_position.x]:
			if row:
				row.move_as_group(direction)


func get_array_pixel_position_converted_to_grid_position():
	var updated_grid = make_2d_array()
	for x in width:
		for y in height:
			var piece = all_pieces[x][y]
			if piece:
				var real_position = fix_wrapped_position(pixel_to_grid(piece.position))
				updated_grid[real_position.x][real_position.y] = piece
	return updated_grid


func fix_wrapped_position(grid_position):
#		overflow right
	if grid_position.x >= width:
		grid_position.x = grid_position.x - width
#		overflow left
	if grid_position.x < 0:
		grid_position.x = width + grid_position.x
#		overflow down
	if grid_position.y >= height:
		grid_position.y = grid_position.y - height
#		overflow up
	if grid_position.y < 0:
		grid_position.y = height + grid_position.y
	return grid_position


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
	for piece in get_matched_pieces():
#		decrement count
		piece_count_dict[piece.color] -= 1
#		destroy piece
		piece.queue_free()
		var piece_position = pixel_to_grid(piece.position)
		all_pieces[piece_position.x][piece_position.y] = null
	clear_matched_pieces_array()
	collapse_columns()


func collapse_columns():
#	wait before starting
	yield(get_tree().create_timer(collapse_timer), "timeout")
	for x in width:
		if should_mirror():
			x = -x-1
		for y in height:
			if should_mirror():
				y = -y-1
			if !all_pieces[x][y]:
				var rang
				if should_mirror():
					rang = range(-5, y)
					rang.invert()
				else:
					rang = range(y + 1, height)
				for k in rang:
					if all_pieces[x][k]:
						var vec = Vector2(x, y)
						var veck = Vector2(x, k)
						if should_mirror():
							vec = negative_grid_positions_to_positive(vec)
							veck = negative_grid_positions_to_positive(veck)
						all_pieces[vec.x][veck.y].move(grid_to_pixel(vec))
						all_pieces[vec.x][vec.y] = all_pieces[vec.x][veck.y]
						all_pieces[vec.x][veck.y] = null
						break
	refill_grid()


func negative_grid_positions_to_positive(grid_position: Vector2) -> Vector2:
	var x = width + grid_position.x if grid_position.x < 0 else grid_position.x
	var y = height + grid_position.y if grid_position.y < 0 else grid_position.y
	return Vector2(x, y)


func refill_grid():
#	wait before starting
	yield(get_tree().create_timer(refill_timer), "timeout")
	spawn_pieces()
#	wait for pieces to finish falling
	yield(get_tree().create_timer(collapse_seconds), "timeout")
	find_matches()


func lock_grid_position(grid_position: Vector2):
	var piece = all_pieces[grid_position.x][grid_position.y]
	if piece:
		piece.lock()


func unlock_grid_position(grid_position: Vector2):
	var piece = all_pieces[grid_position.x][grid_position.y]
	if piece:
		piece.unlock()


func unlock_all():
	for x in width:
		for y in height:
			var piece = all_pieces[x][y]
			if piece:
				piece.unlock()


func is_horizontal_locked(grid_position: Vector2) -> bool:
	for x in width:
		var piece = all_pieces[x][grid_position.y]
		if piece and piece.locked:
			return true
	return false


func is_vertical_locked(grid_position: Vector2) -> bool:
	for y in height:
		var piece = all_pieces[grid_position.x][y]
		if piece and piece.locked:
			return true
	return false
