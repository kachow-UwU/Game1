extends CanvasLayer

func _ready():

	Global.connect("update_treasure", self, "_on_update_treasure")

func _on_update_treasure():
	$MarginContainer/NinePatchRect/HBoxContainer/value.text = str(Global.player.treasures)
