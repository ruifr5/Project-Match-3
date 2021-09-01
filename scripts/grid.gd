extends Node2D

export (int) var width
export (int) var height
export (int) var x_start
export (int) var y_start
export (int) var offset
export (Rect2) var wrap_area

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

var movement_start_grid_position
var old_movement_direction


# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
	all_pieces = make_2d_array()
	spawn_pieces()


func make_2d_array():
	var array = []
	for x in width:
		array.append([])
		for y in height:
			array[x].append([null])
	return array
	
	
func spawn_pieces():
	for x in width:
		for y in height:
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
#			set position and save piece to array
			piece.position = grid_to_pixel(Vector2(x,y))
			add_child(piece)
			all_pieces[x][y] = piece


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


func grid_to_pixel(position):
	var new_x = x_start + offset * position.x
	var new_y = y_start + -offset * position.y
	return Vector2(new_x, new_y)


func pixel_to_grid(position):
	var new_x = round((position.x - x_start) / offset)
	var new_y = round((position.y - y_start) / -offset)
	return Vector2(new_x, new_y)


func is_in_grid(x, y):
	if x >= 0 && x < width:
		if y >= 0 && y < height:
			return true;
	return false


func touch_input():
	if Input.is_action_just_pressed("ui_touch"):
		touch_down = get_global_mouse_position()
		var grid_position = pixel_to_grid(touch_down)
		if is_in_grid(grid_position.x, grid_position.y):
			controlling = true
			movement_start_grid_position = grid_position
		
	if Input.is_action_just_released("ui_touch"):
		if controlling:
			controlling = false
			all_pieces_movement_end()
			reset_pieces_pixel_position()


func move_pieces(x, y, direction):
	direction = zero_smallest_dimention(direction)
	if abs(direction.x) > 0:
		for column in all_pieces:
			column[y].move(direction)
	elif abs(direction.y) > 0:
		for row in all_pieces[x]:
			row.move(direction)


func reset_pieces_pixel_position():
	for x in width:
		for y in height:
			var piece = all_pieces[x][y]
			piece.movement_stop()
			piece.position = grid_to_pixel(Vector2(x,y))


func reset_column_pixel_position(column_id):
	var row_id = 0
	for piece in all_pieces[column_id]:
		piece.movement_stop()
		piece.position = grid_to_pixel(Vector2(column_id, row_id))
		row_id += 1


func reset_row_pixel_position(row_id):
	var column_id = 0
	for column in all_pieces:
		column[row_id].movement_stop()
		column[row_id].position = grid_to_pixel(Vector2(column_id, row_id))
		column_id += 1


func all_pieces_movement_end():
	movement_start_grid_position = null
	for column in all_pieces:
		for row in column:
			row.movement_stop()


# difference between touchdown and touchup
func touch_difference(down, up):
	var difference = up - down
	return zero_smallest_dimention(difference)


func zero_smallest_dimention(position):
	if abs(position.x) > abs(position.y):
		position.y = 0
	else:
		position.x = 0
	return position


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	touch_input()


func _input(event):
	if event is InputEventMouseMotion && controlling:
		var new_direction = zero_smallest_dimention(get_global_mouse_position() - touch_down)
		
		if !old_movement_direction:
			old_movement_direction = new_direction
		elif abs(old_movement_direction.x) == 0 && abs(new_direction.x) != 0:
			reset_column_pixel_position(movement_start_grid_position.x)
		elif abs(old_movement_direction.y) == 0 &&  abs(new_direction.y) != 0:
			reset_row_pixel_position(movement_start_grid_position.y)
			
		move_pieces(movement_start_grid_position.x, movement_start_grid_position.y, new_direction)
		old_movement_direction = new_direction
