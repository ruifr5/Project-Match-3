extends Control

onready var start_layer = get_node("start_layer/MarginContainer")
onready var confirm_layer = get_node("confirm_layer/MarginContainer")
onready var title_label = get_node("confirm_layer/MarginContainer/VBoxContainer/MarginContainer/title_label")
onready var ip_label = get_node("confirm_layer/MarginContainer/VBoxContainer/form/labels/ip_label")
onready var ip_form = get_node("confirm_layer/MarginContainer/VBoxContainer/form/forms/ip_form")
onready var name_form = get_node("confirm_layer/MarginContainer/VBoxContainer/form/forms/name_form")
onready var confirm_button = get_node("confirm_layer/MarginContainer/VBoxContainer/VBoxContainer/confirm_button")
onready var waiting_label = get_node("confirm_layer/MarginContainer/VBoxContainer/VBoxContainer/MarginContainer/wating_label")

var create_not_join


func _ready():
	get_tree().paused = false


func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_GO_BACK_REQUEST:
		_on_exit_button_pressed()


func _on_create_button_pressed():
	create_not_join = true
	title_label.text = "Create"
	start_layer.visible = false
	confirm_layer.visible = true
	ip_label.visible = false
	ip_form.visible = false


func _on_join_button_pressed():
	create_not_join = false
	title_label.text = "Join"
	start_layer.visible = false
	confirm_layer.visible = true
	ip_label.visible = true
	ip_form.visible = true


func _on_back_button_pressed():
	start_layer.visible = true
	confirm_layer.visible = false
	ip_form.editable = true
	name_form.editable = true
	confirm_button.disabled = false
	waiting_label.visible = false


func _on_confirm_button_pressed():
	if name_form.text == "" or !create_not_join and ip_form.text == "":
		return
	confirm_button.disabled = true
	ip_form.editable = false
	name_form.editable = false
	waiting_label.visible = true
	if create_not_join:
#		create
		Network.create_server(name_form.text)
	else:
#		join
		Network.connect_to_server(ip_form.text, name_form.text)


func _on_exit_button_pressed():
	get_tree().quit()


func _on_local_button_pressed():
	get_tree().change_scene("res://scenes/game_window.tscn")
	queue_free()
