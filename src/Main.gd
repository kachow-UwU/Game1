extends Node

func save_game():
	print("saving game to ", OS.get_user_data_dir())
	var save_file = File.new()
	if save_file.open(Global.SAVE_FILE, File.WRITE) != 0:
		print("can't open save file at ", Global.SAVE_FILE)
	else:
		save_file.store_var(Global.level)
		save_file.store_var(Global.gate)
		save_file.store_var(Global.treasures)
		save_file.close()

func load_game():
	print("loading game from ", OS.get_user_data_dir())
	var save_file = File.new()
	if not save_file.file_exists(Global.SAVE_FILE):
		print("can't find save file at", Global.SAVE_FILE)
		return
	if save_file.open(Global.SAVE_FILE, File.READ) != 0:
		print("can't open save file at ", Global.SAVE_FILE)
	else:
		Global.level = save_file.get_var()
		Global.gate = save_file.get_var()
		Global.treasures = save_file.get_var()
		Global.curr_treasures = {}
		save_file.close()


func remove_save():
	var dir := Directory.new()
	if dir.file_exists(Global.SAVE_FILE) and dir.remove(Global.SAVE_FILE) != 0:
		print("can't remove save file at ", Global.SAVE_FILE)



func _load_level(level_str: String, gate_str: String, offset_pct: float):
	Global.level = level_str
	Global.gate = gate_str
	Global.player.disable()
	Global.player.count_treasures()
	var level_resource := load(level_str)
	
	var level = level_resource.instance()
	$Level.add_child(level)
	var gate = level.get_node(gate_str)
	
	gate.enter_gate(offset_pct)
	connect_gates(level)
	var bounds = level.get_node_or_null("Bounds")
	if bounds:
		Global.player.update_camera_limits(bounds.get_rect())
	else:
		Global.player.update_camera_limits(Rect2(-10000000,-10000000,20000000,20000000))

	yield(get_tree(), "physics_frame")
	yield(get_tree(), "physics_frame")
	$UI.disabled = false
	Global.player.enable()


func connect_gates(level: Node):
	for idx in level.get_child_count():
		var node = level.get_child(idx)
		if node is Gate:
			node.connect("exitted_scene", self, "_on_exitted_scene")



func _reset_game():
	Global.enemies = {}
	Global.curr_treasures = {}
	Global.treasures = {}
	var old_level = $Level.get_child(0)

	$Level.remove_child(old_level)
	old_level.free()
	$UI.disabled = false
	$UI/StartMenu.open_ui()


func _switch_level(level_str: String, gate_str: String, offset_pct: float, save: bool):
	var old_level = $Level.get_child(0)

	$Level.remove_child(old_level)
	old_level.free()
	Global.merge_treasures()
	$Fadeout/ColorRect.color = Color(0, 0, 0, 0)
	_load_level(level_str, gate_str, offset_pct)
	if (save):
		save_game()


func reload_level():
	$UI.disabled = true
	Global.enemies = {}
	Global.curr_treasures = {}
	$Fadeout/AnimationPlayer.play("fadeout")
	yield($Fadeout/AnimationPlayer, "animation_finished")
	call_deferred("_switch_level", Global.level, Global.gate, 0, false)


func continue_game():
	$UI.disabled = true
	load_game()
	call_deferred("_load_level", Global.level, Global.gate, 0)


func start_game():
	$UI.disabled = true
	remove_save()
	call_deferred("_load_level", "res://src/levels/Level1.tscn", "StartGate", 0)


func restart_game():
	$UI.disabled = true
	call_deferred("_reset_game")


func _on_exitted_scene(level_str, gate_str, offset_pct):
	$UI.disabled = true
	call_deferred("_switch_level", level_str, gate_str, offset_pct, true)


func _ready():
	$UI/StartMenu.open_ui()


func _on_Player_won():
	remove_save()
	$UI/GameEnd.open_ui()
