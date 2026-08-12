extends Control

## What's new?
# Worked on list movement and cursor UX a bit; UX is solid, and visuals need more work.
# See _ready() for this session's starting point, and _process_move_cursor_by() for some logic.
#
# Also cleaned up a smidge, some code written during workshopping are gonna ✨disappear✨ after this.
#
# Also, I think I broke one of the input map keys in Project > Project Settings...;
# WASD - W doesn't work.

##TODO:
# Let's see how much we can bash out in an hour. We did not complete original workset because of cursor_pos confusion. This mildly upsets me.
# This seems easy, but it's been a WHILE since I did this.
# v Add controls: Make 'confirm' do a thing (I'm NOT going to auto-generate labels, I wanna see em in-editor)
# v Read up/down
# v Move the list up/down
# v Slap a quadease with Godot's ver of time.deltaTime()
# v Add core ux: Track where the cursor is + wrapping
# v Now using Wendy.ttf for label text
# > I want this to have the vibe of being infinitely scrolling. Smoke and mirrors.
#   v Add 4 ghost sections split between top and bottom (they're copies of OG list)
#   v Adjust VBox list up by 2x its size (calculate float at runtime - on ready)
#   > Have a ghAstLY vIiIibe to the full list by messing with opacity (I hope albedo works like that, but I'm sure it's doable)
#   - ooo I see some BBCode, I wanna experiment and animate the text, too
#   - See if we can get the labels to move diagonally like it's a game menu? like "\"
#   - Add border around text
#
# > Test how behaviour works with different list sizes
#   v Behaviour is perfect as pertains to cursor selection and list visually adjusting with internal information!
#   - Make sure BBCode and opacity works perfectly (lists should ALWAYS be 2 or greater in count)
#
# NOTE: Make sure to only use scancodes in input map!! You're using a custom XKB layout!
#
# Stuff to do during polish round:
# - Tweak list easing variables to be feel smoother (less snappy(?), but still responsive?? I need a better vernacular for this)
# - If holding arrows, start auto-moving.
# - Add a shadowed VBox BG generated during runtime because it's awesome and adds much-needed contrast + depth

# Bruh this is already a total mess, how--? I'll clean this when I clean it.
var _current_scene : String = "res://list_selection.tscn"

@export var _label_script : Script
@export var _label_theme : Theme

var _current_cursor_pos : int = 0

var _label_quantity : int # Used to remember how big the list is (counts from 1)
var _Labels : Array[RichTextLabel] # No array-specific naming convention soooooooooooooooo
# Below 2 vars used in _ready_visual_generate_primary_list_before_after() and
#   _process_move_cursor_by()
# The minimum size of the list to be designed around should always be 2 or greater.
var _before_copies_amt : int = 3
var _after_copies_amt : int = 5


@export var _VBoxContainer : VBoxContainer # LHand Y- I think??? Y+ is down, Xr.
var _default_VBox_pos : float
var _desired_VBox_pos : float
# Be carefule with fonts; Spacing can auto-adjust.
var _VBox_move_by_amt : float = 38.0 # diff is comparing the 1st two labels' pos

# Easing variables
var _var_ease_out_amt : float = 0.25
var _var_ease_out_exp : float = 2.5


 


func _ready() -> void:
	# Prepares VBoxContainer visual movement information (Might now be redundant)
	_default_VBox_pos = _VBoxContainer.position.y
	_desired_VBox_pos = _VBoxContainer.position.y
	# Prepares wrapping for VBox visuals (infinite wrapping, snapping container)
	# as well as UX cursor movement/selection;	
	_label_quantity = ( # starts counting from int 1
		_VBoxContainer.get_child_count(false)
		)
	
	_ready_visual_generate_primary_list_before_after()
	# Adjusts list for amount of copies we had up top
	_VBoxContainer.position.y -= _label_quantity*_before_copies_amt * _VBox_move_by_amt
	_desired_VBox_pos -= _label_quantity*_before_copies_amt * _VBox_move_by_amt
	#print("Label count: ", _label_quantity) # Might need to make a bunch of these dev prints or smth
	pass


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("up"):
		_process_move_cursor_by(-1)
		#print("ue oshimatta! New cursorpos: ", _current_cursor_pos, " New list position: ", _desired_VBox_pos)
		pass
	
	if Input.is_action_just_pressed("down"):
		_process_move_cursor_by(+1)
		print("shita oshimatta! New cursorpos: ", _current_cursor_pos, " New list position: ", _desired_VBox_pos)
		pass
	
	if Input.is_action_just_pressed("confirm"):
		match _VBoxContainer.get_child(_current_cursor_pos + (_before_copies_amt*_label_quantity)).target_load_path:
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

# Done - This generates extra labels
func _ready_visual_generate_primary_list_before_after():
	# --- PREPARATION OF '_Labels[RichTextLabel]', WE WANT TO DUPLICATE ENTRIES LATER ---
	_Labels.resize(_label_quantity)
	#print("Labels size", _Labels.size()) # I'm guessing it's counting from 1?
	
	# This array is only used in this scope; I might have to use a script-scope
	# array when I copy the text over for shadows
	var _disposable_deep_copy_labels_text : Array[String]
	_disposable_deep_copy_labels_text.resize(_label_quantity)
	
	for n in _VBoxContainer.get_child_count(): # Count from 0 or 1? Let's find out the hard way!
		_disposable_deep_copy_labels_text[n] = _VBoxContainer.get_child(n).text
		# lmao turns out I'm doing this very cleanly for how I'm making this;
		# I checked docs; Not only is .text exactly what I think it is (within 
		# my current use), modifying text also overwrites BBCode FORMATTING - 
		# BBCode is what lets me use [b], [i], etc and seems to let me do other
		# smallish goofy stuff - perfect for what I want to do here. I'll 
		# check what BBCode options exist when I'm ready to add juice.
		pass
	
	# ...why is it green. stop that. you're scaring me.
	for n in _label_quantity: _Labels[n] = _VBoxContainer.get_child(n)
	
	# --- EVERYTHING UNTIL HERE WORKS AS INTENDED --
	var _original_label_array_size = _Labels.size()
	
	# Start of 'before' part
	for _current_print_set in (_before_copies_amt):
		var _temp_iteration : int = 0
		for n in _Labels:
			var _instance_RichTextLabel = RichTextLabel.new()
			_instance_RichTextLabel.fit_content = true
			_instance_RichTextLabel.autowrap_mode = 0
			var _temp_current_cycle_name = "Pre-list instance "+ str(_current_print_set) +" dot "+ str(n)
			_instance_RichTextLabel.name = _temp_current_cycle_name
			_instance_RichTextLabel.text = _Labels[_temp_iteration].text# + " (prelist "+ str(_current_print_set) +")"
			_instance_RichTextLabel.theme = _label_theme
			_instance_RichTextLabel.set_script(
				_label_script # apparently better to use set_script() instead of .script = <Script>
			)
			_VBoxContainer.add_child(_instance_RichTextLabel)
			_VBoxContainer.move_child(_VBoxContainer.get_child(
					# This counts sections of text backwards. I do not care.
					(
						_original_label_array_size) + _temp_iteration
						+ (_original_label_array_size*_current_print_set)
					),
					_temp_iteration
				)
			_temp_iteration += 1
		pass
	# End of 'before' part
	
	# boo.
	
	# Start of 'after' part
	for _current_print_set in (_after_copies_amt):
		var _temp_iteration : int = 0
		for n in _Labels:
			var _instance_RichTextLabel = RichTextLabel.new()
			_instance_RichTextLabel.fit_content = true
			_instance_RichTextLabel.autowrap_mode = 0
			var _temp_current_cycle_name = "Post-list instance "+ str(_current_print_set) +" dot "+ str(n)
			_instance_RichTextLabel.name = _temp_current_cycle_name
			_instance_RichTextLabel.text = _Labels[_temp_iteration].text# + " (postlist "+ str(_current_print_set) +")"
			_instance_RichTextLabel.theme = _label_theme
			_instance_RichTextLabel.set_script(
				_label_script # apparently better to use set_script() instead of .script = <Script>
			)
			_VBoxContainer.add_child(_instance_RichTextLabel)
			_temp_iteration += 1
		pass
	# End of 'after' part.
	pass

# Done
func _handle_ease_out ( # I should totally note easing equations sometime (:
	_ease_amt : float,
	_ease_exp : float,
	_delta : float
	):
	if _VBoxContainer.position.y != _desired_VBox_pos:
		# if moving up...
		if _VBoxContainer.position.y < _desired_VBox_pos:
			_VBoxContainer.position.y += ( # Change by ease amt
				(_desired_VBox_pos - _VBoxContainer.position.y) # "Where are we going?"
				* ((1 - _ease_amt) ** _ease_exp) # "What does the ease look like?"
				)
		# if moving down...
		else:
			_VBoxContainer.position.y -= (
				(_VBoxContainer.position.y - _desired_VBox_pos)
				* ((1 - _ease_amt) ** _ease_exp)
				)
	pass

# Done - Might need extra cleanup to be more readable at a glance.
func _process_move_cursor_by(
	_cursor_move_amt : int # I'm pretty sure this forces coder to pass an int
	):
	if _cursor_move_amt == -1:
		# If cursor is going up and out of bounds... don't! Cave Johnson would be so proud.
		if ((_current_cursor_pos + _cursor_move_amt) < 0):
			#print("Cursor wants to be less than 0! Moved to end of list instead.")
			_current_cursor_pos = (_label_quantity - 1)
			_VBoxContainer.position.y = _default_VBox_pos - (
				_VBox_move_by_amt * (_label_quantity-1) # _label_quantity counts from 1, not 0
				) - _VBox_move_by_amt - (_label_quantity*(_before_copies_amt) * _VBox_move_by_amt)
			# Delete on commit
			#print("_label_quantity: ", _label_quantity)
			#print("_VBox_move_by_amt: ", _VBox_move_by_amt)
			#print("[A]: _VBox_move_by_amt * _label_quantity: ", _VBox_move_by_amt * _label_quantity)
			#print("_default_VBox_pos: ", _default_VBox_pos)
			#print("_default_VBox_pos - ':[A]':", _default_VBox_pos - (_VBox_move_by_amt * _label_quantity))
			#printerr(-_VBox_move_by_amt * (_label_quantity-1)) # bruh.
			_desired_VBox_pos = _default_VBox_pos - (
				_VBox_move_by_amt * (_label_quantity-1) # _label_quantity counts from 1, not 0
				) - (_label_quantity*(_before_copies_amt) * _VBox_move_by_amt)
		else:
			_current_cursor_pos -= 1
			_desired_VBox_pos += _VBox_move_by_amt
	elif _cursor_move_amt == +1:
		# If we're going down and out of bounds... don't!
		if ((_current_cursor_pos + _cursor_move_amt) > (_label_quantity - 1)):
			#print("Cursor wants to be more than available! Moved to end of list instead.")
			_current_cursor_pos = (0)
			_VBoxContainer.position.y = _default_VBox_pos + _VBox_move_by_amt - (
				_label_quantity*_before_copies_amt * _VBox_move_by_amt
				)
			_desired_VBox_pos = _default_VBox_pos - (
				_label_quantity*_before_copies_amt * _VBox_move_by_amt
				)
		else:
			_current_cursor_pos += 1
			_desired_VBox_pos -= _VBox_move_by_amt
	else:
		printerr("[control-list-selection.gd]_process_move_cursor_by()
			catch case: _cursor_move_amt is only supposed to go up/down by one!")
