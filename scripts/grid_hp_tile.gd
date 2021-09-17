class_name GridHPTile
extends Node2D


var hp
var max_hp
var destroyed = false


func _process(_delta):
	$hp_label.text = str(hp)

func set_max_hp(amount):
	max_hp = amount
	hp = amount


func damage(amount):
	if hp > 0:
		hp -= amount
		clamp_hp()
		if hp <= 0:
			destroy()


func heal(amount):
	if destroyed:
		hp += amount
		clamp_hp()
		if hp >= max_hp:
			restore()


func destroy():
	destroyed = true
	$Sprite.modulate = Color(1, 1, 1, .1)


func restore():
	destroyed = false
	$Sprite.modulate = Color(1, 1, 1, 1)


# keep hp in valid values
func clamp_hp():
	hp = clamp(hp, 0, max_hp)
