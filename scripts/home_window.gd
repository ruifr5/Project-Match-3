extends Control

onready var start_layer = get_node("start_layer/MarginContainer")
onready var confirm_layer = get_node("confirm_layer/MarginContainer")
onready var title_label = get_node("confirm_layer/MarginContainer/VBoxContainer/MarginContainer/title_label")
onready var ip_label = get_node("confirm_layer/MarginContainer/VBoxContainer/form/labels/ip_label")
onready var ip_form = get_node("confirm_layer/MarginContainer/VBoxContainer/form/forms/ip_form")
onready var name_form = get_node("confirm_layer/MarginContainer/VBoxContainer/form/forms/name_form")
onready var confirm_button = get_node("confirm_layer/MarginContainer/VBoxContainer/VBoxContainer/confirm_button")
onready var waiting_label = get_node("confirm_layer/MarginContainer/VBoxContainer/VBoxContainer/MarginContainer/wating_label")
onready var ip_container = get_node("confirm_layer/MarginContainer/VBoxContainer/ip_container")
onready var toggle_ip_button = get_node("confirm_layer/MarginContainer/VBoxContainer/ip_container/ip_button_container/toggle_ip_button")

var show_ip = false
var create_not_join

func _ready():
	get_tree().paused = false
	config_ip_labels()
	go_to_start_view()



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
	ip_container.visible = true


func _on_join_button_pressed():
	create_not_join = false
	title_label.text = "Join"
	start_layer.visible = false
	confirm_layer.visible = true
	ip_label.visible = true
	ip_form.visible = true
	ip_container.visible = false


func _on_back_button_pressed():
	Network.terminate_connection()
	go_to_start_view()



func _on_confirm_button_pressed():
#	if name_form.text == "" or !create_not_join and ip_form.text == "":
	if name_form.text == "":
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
		var ip = ip_form.text if ip_form.text.length() > 0 else ip_form.placeholder_text
		Network.connect_to_server(ip, name_form.text)


func go_to_start_view():
	start_layer.visible = true
	confirm_layer.visible = false
	ip_form.editable = true
	name_form.editable = true
	confirm_button.disabled = false
	waiting_label.visible = false
	ip_container.visible = false


func go_to_start_view():
	start_layer.visible = true
	confirm_layer.visible = false
	ip_form.editable = true
	name_form.editable = true
	confirm_button.disabled = false
	waiting_label.visible = false
	ip_container.visible = false


func config_ip_labels():
#	lan
	var local_ip = str(IP.resolve_hostname(str(OS.get_environment("COMPUTERNAME")),1))
	if local_ip and local_ip != "":
		ip_container.get_node("ip_container_labels/values/local_ip_value_label").text = local_ip
		ip_container.visible = true
#	public
	var http_request = Network.get_node("http_request")
	http_request.connect("request_completed", self, "_on_ip_http_request_completed")
	http_request.request(Network.ip_url)


func _on_ip_http_request_completed(_result, response_code, _headers, body):
	if response_code == 200:
		var public_ip = body.get_string_from_utf8()
		if public_ip and public_ip != "":
			ip_container.get_node("ip_container_labels/values/public_ip_value_label").text = public_ip
			ip_container.visible = true


func _on_exit_button_pressed():
	get_tree().quit()


func _on_local_button_pressed():
	if get_tree().change_scene("res://scenes/game_window.tscn") != OK:
		printerr("error when trying to switch to game_window scene")
	else:
		queue_free()


func _on_toggle_ip_button_pressed():
	show_ip = !show_ip
	ip_container.get_node("ip_container_labels").visible = show_ip
	var label = "Show IP" if !show_ip else "Hide IP"
	toggle_ip_button.text = label


func _on_local_ip_value_label_button_pressed():
	OS.clipboard = ip_container.get_node("ip_container_labels/values/local_ip_value_label").text


func _on_public_ip_value_label_button_pressed():
	OS.clipboard = ip_container.get_node("ip_container_labels/values/public_ip_value_label").text
