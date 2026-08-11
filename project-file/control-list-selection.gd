extends Control

##TODO:
# Let's see how much we can bash out in an hour. We did not complete original workset because of cursor_pos confusion. This mildly upsets me.
# This seems easy, but it's been a WHILE since I did this.
# v Add controls: Make 'confirm' do a thing (I'm NOT going to auto-generate labels, I wanna see em in-editor)
# v Read up/down
# v Move the list up/down
# v Slap a quadease with Godot's ver of time.deltaTime()
# ~ Add core ux: Track where the cursor is (This needs wrapping - I'll need to auto-check how many children are here and have a reset trigger based on where I'm at; _current_cursor_pos should probably be multiplied when setting desired_VBox_Pos, and a hard reset on desired pos and literal pos should be set upon wrapping.)
#   - No sub 1hr for tonight :'(
# - Figure out a font for listed items (will probably need to redo 'move by amt'
# - I want this to have the vibe of being infinitely scrolling. Smoke and mirrors.
#   - Add 4 ghost sections split between top and bottom (they're copies of OG list)
#   - Adjust VBox list up by 2x its size (calculate float at runtime - on ready)
#   - Have a ghAstLY vIiIibe to the full list by messing with opacity (I hope albedo works like that, but I'm sure it's doable)
#   - ooo I see some BBCode, I wanna experiment and animate the text, too
#   - See if we can get the labels to move diagonally like it's a game menu? like "\"
#   - Add border around text
#
# NOTE: Make sure to only use scancodes in input map!! You're using a custom XKB layout!
#
# Stuff to do during polish round:
# - If holding arrows, start auto-moving.
# - Add a shadowed VBox BG generated during runtime because it's awesome and adds much-needed contrast + depth

# Bruh this is already a total mess, how--? I'll clean this when I clean it.
var _current_cursor_pos : int = 0
var _current_scene : String = "res://list_selection.tscn"
@export var _VBoxContainer : VBoxContainer # LHand Y- I think??? Y+ is down, Xr.
var _VBox_move_by_amt : float = 27.0 # diff is comparing the 1st two labels' pos
var _current_VBox_pos : float = 0.0
var _desired_VBox_pos : float

# Easing variables
var _var_ease_out_amt : float = 0.25
var _var_ease_out_exp : float = 2.5





func _ready() -> void:
	_desired_VBox_pos = _current_VBox_pos
	pass

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("up"):
		_process_move_cursor_by(-1)
		print("ue oshimatta! New cursorpos: ", _current_cursor_pos)
		pass
	
	if Input.is_action_just_pressed("down"):
		_process_move_cursor_by(+1)
		print("shita oshimatta! New cursorpos: ", _current_cursor_pos)
		pass
	
	if Input.is_action_just_pressed("confirm"):
		# references child script so we know what to load (do cursor control!!)
		# oof, I don't know HOW this is out of range when trying to do quit
		# the list had 7 total children, NOT 8 children. Godot's autorename ruined my sub 1hr bc I didn't expect it :(
		match _VBoxContainer.get_child(_current_cursor_pos).target_load_path:
			"RELOAD", "reload", "refresh", "":
				get_tree().change_scene_to_file(_current_scene)
			"QUIT", "quit":
				get_tree().quit(1) # I should check how to handle exit codes...
			_:
				get_tree().change_scene_to_file(
					_VBoxContainer.get_child(_current_cursor_pos).target_load_path
				)
		pass
	
	if Input.is_action_just_pressed("cancel"):
		# There's no surmenu, so we just give up instead.
		get_tree().quit(1)
	
	if Input.is_action_pressed("quit"):
		get_tree().quit(1)
		pass
	
	_handle_ease_out( # eases the _VBoxContainer list of labels
		_var_ease_out_amt,
		_var_ease_out_exp,
		_delta
	)

func _handle_ease_out ( # I should totally note easing equations sometime (:
	_ease_amt : float, # I *HOPE* this is how easequad works as recalled, or
	_ease_exp : float, # else I'm gonna look realll dumb when I push to GitHub.
	_delta : float # okay this isn't a quad ease, I think. hmm....
	):
	# dude I was THIS CLOSE to freaking sightreading this equation from memory!!! omg bruv like
	if _VBoxContainer.position.y != _desired_VBox_pos:
		# if moving up...
		if _VBoxContainer.position.y < _desired_VBox_pos:
			_VBoxContainer.position.y += ( # Change by ease amt
				(_desired_VBox_pos - _VBoxContainer.position.y) # "Where are we going?"
				* ((1 - _ease_amt) ** _ease_exp) # "What does the ease look like?"
				)
			pass
		# if moving down...
		else:
			_VBoxContainer.position.y -= (
				(_VBoxContainer.position.y - _desired_VBox_pos)
				* ((1 - _ease_amt) ** _ease_exp)
				)
			pass
	pass

func _process_desired_vbox_pos():
	pass

func _process_literal_vbox_pos():
	pass

func _process_move_cursor_by(
	_cursor_move_amt : int # I'm pretty sure this forces coder to pass an int
	):
	if _cursor_move_amt == -1:
		_current_cursor_pos -= 1
		_desired_VBox_pos += _VBox_move_by_amt
		pass
	elif _cursor_move_amt == +1:
		_current_cursor_pos += 1
		_desired_VBox_pos -= _VBox_move_by_amt
		pass
	else:
		printerr("[control-list-selection.gd]_process_move_cursor_by()
			catch case: _cursor_move_amt is only supposed to go up/down by one!")
