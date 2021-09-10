extends KinematicBody2D
class_name Unit

export (String) var color
export (Array, String) var strong_vs
export (Array, String) var weak_vs
export (int) var pixel_size = 64 * scale.x
export (float) var aggro_radius = pixel_size + pixel_size / 2
export (float) var flee_speed_multiplier = 1
export (float) var chase_speed_multiplier = 1.2

var state
var allegiance: Vector2 # aka what direction am I walking in (up or down)
var enemies_near = []
var closest_enemy: Unit

enum State {MOVING, CHASING, FLEEING, ATTACKING, DYING}
enum Result {WIN, LOSE, TIE}


func _ready():
	$aggro_area/CollisionShape2D.shape.radius = aggro_radius
	play_walk_animation()


func _process(_delta):
	process_enemies()


func process_enemies():
	if enemies_near.size():
		enemies_near.sort_custom(self, "sort_closest")
		closest_enemy = enemies_near[0]
	else:
		closest_enemy = null


func play_walk_animation():
	if allegiance == Vector2.UP:
		$AnimationPlayer.play("walk_up")
	elif allegiance == Vector2.DOWN:
		$AnimationPlayer.play("walk_down")


func sort_closest(a, b):
	return a.position.distance_to(self.position) < b.position.distance_to(self.position)


# return loser, if tied returns null
func fight(enemy: Unit) -> Unit:
	state = State.ATTACKING
	var fight_result = wins_vs(enemy)
	if fight_result == Result.WIN:
		attack_animation(enemy.position)
		enemy.die()
		return enemy
	if fight_result == Result.LOSE:
		enemy.attack_animation(position)
		die()
		return self
#	Result.TIE
	die()
	enemy.die()
	return null


# return loser, if tied returns null
func move_and_fight(dir: Vector2, speed: float):
#	if there is an enemy and is in front of self
	if closest_enemy and is_facing_me(closest_enemy):
		var fight_result = wins_vs(closest_enemy)
		var new_dir = (closest_enemy.position - position).normalized()
#			when chasing
		if fight_result == Result.WIN or fight_result == Result.TIE:
			state = State.CHASING
			dir = new_dir
			speed *= chase_speed_multiplier
#			when fleeing
		elif fight_result == Result.LOSE:
			state = State.FLEEING
			dir.x = dir.x + new_dir.x * -1
			speed *= flee_speed_multiplier
#	no enemy
	else:
		state = State.MOVING
#	move and if colision happens fight
	var collision = move_and_collide(dir * speed)
	if collision && allegiance != collision.collider.allegiance:
#		who loses?
		return fight(collision.collider)


func die():
#	die animation
	queue_free()
	pass


func attack_animation(pos):
#	animate and move to pos
	pass


func wins_vs(enemy) -> int:
	if enemy.color in strong_vs:
		return Result.WIN
	if enemy.color in weak_vs:
		return Result.LOSE
	return Result.TIE


# return true if enemy is facing self
func is_facing_me(enemy: Unit):
	var facing_angle_vs_enemy = position.direction_to(enemy.position).dot(allegiance)
	return facing_angle_vs_enemy > 0


# todo: possibly move facing detection from move_and_fight() to here instead
func _on_aggro_radius_body_entered(body):
	if body.allegiance != allegiance and not body in enemies_near:
		enemies_near.append(body)


func _on_aggro_radius_body_exited(body):
	if body in enemies_near:
		enemies_near.erase(body)
