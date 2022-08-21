extends Control

var current_scene = null
	

func _ready():
	$OptionsContainer.hide()
	var root = get_tree().get_root()
	current_scene = root.get_child(root.get_child_count() - 1)

func _on_SinglePlayerButton_pressed():
	var global = get_node("/root/Global")
	global.bot_risk_tolerance = $OptionsContainer/VBoxContainer/ScrollContainer/VBoxContainer/GridContainer/RiskSlider.value
	global.single_player = true
	get_tree().change_scene("res://Scenes/Level.tscn")

func _on_LocalGameButton_pressed():
	var global = get_node("/root/Global")
	global.bot_risk_tolerance = $OptionsContainer/VBoxContainer/ScrollContainer/VBoxContainer/GridContainer/RiskSlider.value
	global.single_player = false
	get_tree().change_scene("res://Scenes/Level.tscn")

func _on_OptionsButton_pressed():
	$OptionsContainer.show()


func _on_QuitButton_pressed():
	get_tree().quit()


func _on_OptionsDoneButton_pressed():
	$OptionsContainer.hide()


