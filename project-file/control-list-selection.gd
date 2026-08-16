extends Control

## What's new?
# Solved serious bug with opacity easing on labels not working; I was multiplying by zero.

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
# These handle opacity changes user sees when navigating the list - You're using math without an OOB check, MAKE SURE _before_copies_amt and _after_copies_amt is bigger than the total amt for these!
var _should_make_ready_overwrite_opaque_quantity : bool = true
var _opacity_base_list_fully_opaque_quantity : int = 2 # I want default to be _label_quantity, but this is an optional thing to change if I change my mind
var _opacity_list_look_behind_opaque : int = 0 # Customizable, but untested for robustness
var _opacity_list_look_behind_transparent : int = 1 # Customizable, but untested for robustness; added under _opacity_base_list_fully_opaque_quantity;
var _opacity_list_look_ahead_opaque : int = 0 # Customizable, but untested for robustness
var _opacity_list_look_ahead_transparent : = 2 # Customizable, but untested for robustness; added under _opacity_base_list_fully_opaque_quantity;

# It's very frustrating that I need make a flag variable for this, but intended func doesn't seem
# to work when within 2 or more functions, or when encapsulating a function with a return value.
# Off the top of my dome, this MIGHT be related to 'void' or the engine intentionally trying
# to prevent obscurized/bad code or something, but for now it's higher priority to get this script
# working now that I'm experiencing a clear impass this session.
var _flag_wants_to_snap_labels_opacity : bool = false


@export var _VBoxContainer : VBoxContainer # LHand Y- I think??? Y+ is down, Xr.
var _default_VBox_pos : float
var _desired_VBox_pos : float
# Be carefule with fonts; Spacing can auto-adjust.
var _VBox_move_by_amt : float = 38.0 # diff is comparing the 1st two labels' pos

# Easing variables
var _var_ease_out_amt : float = 0.25
var _var_ease_out_exp : float = 2.5


 

# System function
func _ready() -> void:
	# Prepares VBoxContainer visual movement information (Might now be redundant)
	_default_VBox_pos = _VBoxContainer.position.y
	_desired_VBox_pos = _VBoxContainer.position.y
	
	
	# Prepares VBox visuals wrapping (inf wrap, snaps container) + UX cursor movement/selection;
	_label_quantity = _VBoxContainer.get_child_count(false)  # starts counting from int 1
	# Needs to be after _label_quantity being processed.
	_ready_visual_generate_primary_list_before_after()
	# Adjusts list for amount of copies we made w/ _ready_visual_generate_primary_list_before_after
	_VBoxContainer.position.y -= (_label_quantity * _before_copies_amt * _VBox_move_by_amt)
	_desired_VBox_pos -= (_label_quantity * _before_copies_amt * _VBox_move_by_amt)
	# Needs to be after list generation.
	_ready_set_opacity_on_all_labels_to_zero()
	# Needs to be after _ready_set_opacity_on_all_labels_to_zero()
	if _should_make_ready_overwrite_opaque_quantity:
		_opacity_base_list_fully_opaque_quantity = _label_quantity
	else:
		printerr("You didn't think about how this script handles 
			_opacity_base_list_fully_opaque_quantity when it's not the same as the amount of items 
			as what you originally had pre-labels duplication for the infinite wrapping effect!
			
			You let this be possible for more robust customization in-code.
			
			I didn't finish writing code at the time of writing, but this should affect all opacity
			management coming from this script, both in this script snapping the current opacity of
			labels (in bulk or otherwise) and in this script telling what opacity to ease to (in
			bulk or otherwise).
			
			This script's basically the command centre for that in design, DON'T try to set this
			stuff in the labels' scripts, this one WILL overwrite it.")
		pass
	_ready_set_opacity_on_desired_stuff()
	
	#print("Label count: ", _label_quantity) # Might need to make a bunch of these dev prints or smth
	pass

# System function
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("up"):
		_process_pulse_update_visuals_labels_opacity(_process_move_cursor_by(-1))
		
		#_process_pulse_update_visuals_labels_opacity(_flag_wants_to_snap_labels_opacity)
		#print("ue oshimatta! New cursorpos: ", _current_cursor_pos, " New list position: ", _desired_VBox_pos)
		pass
	
	if Input.is_action_just_pressed("down"):
		#_process_move_cursor_by(+1)
		_process_pulse_update_visuals_labels_opacity(_process_move_cursor_by(+1))
		#print("shita oshimatta! New cursorpos: ", _current_cursor_pos, " New list position: ", _desired_VBox_pos)
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

# Done - This generates extra labels in _ready()
func _ready_visual_generate_primary_list_before_after() -> void:
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

# Done - Execution is much easier than the idea
func _ready_set_opacity_on_all_labels_to_zero() -> void:
	# This is gonna take all session to figure out, isn't it
	#theme_override_colors/default_color = (
	#	theme_override_colors/default_color.x,
	#	theme_override_colors/default_color.y,
	#	theme_override_colors/default_color.z,
	#	0.0
	#)
	
	# Okay, this is annoying; If I want that super cool ghost effect, I should NOT
	# iterate all labels via this list during engine updates/frames because that just seems insane
	# and failure-prone.
	#
	# Problem-solving time. I can apparently manually adjust RichTextLabel text colors via
	# "theme_override_colors/default_color", but idk how to access that in-code, or how to
	# structure that.
	#
	# So, first off, I think I need to use smth like 'set("Property path", value)' for this
	# 'theme override' idea in-script; This is the direct property path that the editor is giving
	# me. I'll still have to have this script coordinate what the labels are supposed to do,
	# so it's probably better to use a 'pulse pattern'; THIS SCRIPT knows what labels do what,
	# meaning it should tell the individual labels what to do, and labels can manually set it and
	# do easing, meaning...
	#
	# ...it's probably fine, resources-wise, to have the individual labels have a _process() call,
	# right? The only knowledge hurdle would then be setting ANY color info in-script.
	#
	## TODO:
	# v Set ANY LABEL's color info in a label script (it can affect all, I don't care for now)
	# > Set ANY LABEL's color info from this script using current cursor pos AFTER initializing
	#     Before/After copies
	#     > This is very messy noting, but intended behaviour is to be able to see entire length of
	#       list, INCLUDING a 'look-before amt' and 'look-after amt'.
	#
	# - Use the desired/ease pattern idea from this script's position info; Literal flow might
	#     need tweaking though, as I might not be able to pull color info comfortably, meaning
	#     I'd set 'current_opacity : float = 255.0/255.0' and get that var when working with 
	#     set(theme_override_colors/default_color, ...SOMETHING), not sure how this'll look yet)
	# - Figure out how to set this script's relevant control vars on START ONLY
	# - Figure out how to set this script's relevant control vars on WRAP ONLY
	# - Figure out how to set this script's relevant control vars on update (while moving up/down)
	# - Add opacity easing in label's script, add opacity snapping in this script's wrapping handling
	# - (Obsolete 'step') ?!?!?!?
	# - (Obsolete step) Come back to this function to initialize...how, exactly? I'll probably need a 
	#     'mid-opacity' value and a 'how far can I look ahead' + '~ look behind' value,
	#     combinatorized for full-opacity and 'mid-opacity' + adequate internal managment to make
	#     that work, PLUS robust functionality for different label quantities, hopefully not 
	#     spaghettified. Yaaaayyyy...
	# - Commit to main when confident.
	
	for n in _VBoxContainer.get_child_count(false): # counts from 0
		_VBoxContainer.get_child(n).current_opacity = (000.0/225.0)
		_VBoxContainer.get_child(n).desired_opacity = (000.0/225.0)
	pass

# Done - reading this is a slight headache though; Might be boilerplatey
func _ready_set_opacity_on_desired_stuff() -> void:
	# Basically, the logic is to find the exact size of the labels we'd affect, then move that range
	# backwards (closer to 0) depending on where we want to start moving through the list from 
	# (which would be wherever this script thinks "_before_copies_amt * _label_quantity" starts
	# from -- this is math is where 'cursor position 0' is supposed to be, in the label's 
	# position in the list instead of intended UX selection is.)
	
	var _func_scope_transparency_range_amt = ( # We find out how many labels to affect, and take some steps back from where the user would start (user's relative top of the list)
		_opacity_base_list_fully_opaque_quantity # Default is amt of labels originally contained (equal to range of stuff cursor UX selection range has); Alternative is a custom range specified by coder (this hasn't been tested yet)
		+ _opacity_list_look_behind_opaque # How many extra steps behind do we want to look from 1st label?
		+ _opacity_list_look_behind_transparent # How many extra steps back should we consider for mid-opacity?
		+ _opacity_list_look_ahead_opaque # How many extra steps forward do we want to look from the end of _opacity_base_list_fully_opaque_quantity?
		+ _opacity_list_look_ahead_transparent # How many etra steps forwards AFTER base opaque range + opaque look ahead should we consider for mid-opacity?
	)
	print("_func_scope_transparency_range_amt ", _func_scope_transparency_range_amt)
	
	var _func_scope_opacity_range_amt = ( # We find out how many labels to affect, and take some steps back from where the user would start (user's relative top of the list)
		_opacity_base_list_fully_opaque_quantity # Default is amt of labels originally contained (equal to range of stuff cursor UX selection range has); Alternative is a custom range specified by coder (this hasn't been tested yet)
		+ _opacity_list_look_behind_opaque # How many extra steps behind do we want to look from 1st label?
		+ _opacity_list_look_ahead_opaque # How many extra steps forward do we want to look from the end of _opacity_base_list_fully_opaque_quantity?
	)
	print("_func_scope_opacity_range_amt ", _func_scope_opacity_range_amt)
	
	# Half-opacity section - you should do this first in current design.
	for n in _func_scope_transparency_range_amt:
		# Set every (revelant) label's current opacity
		(_VBoxContainer.get_child(
				(_before_copies_amt * _label_quantity) # Where script thinks user's start of list is
				+ n # Iteration over the size of our list; _label_quantity
				- _opacity_list_look_behind_opaque
				- _opacity_list_look_behind_transparent # this shifts effected range backwards
			).current_opacity
		) = _VBoxContainer.get_child(
				(_before_copies_amt * _label_quantity) # Where script thinks user's start of list is
				+ n # Iteration over the size of our list; _label_quantity
				- _opacity_list_look_behind_opaque # this shifts effected range backwards
				- _opacity_list_look_behind_transparent # this shifts effected range backwards
			).mid_opacity
		# Set every (revelant) label's desired opacity
		(_VBoxContainer.get_child(
				(_before_copies_amt * _label_quantity) # Where script thinks user's start of list is
				+ n # Iteration over the size of our list; _label_quantity
				- _opacity_list_look_behind_opaque # this shifts effected range backwards
				- _opacity_list_look_behind_transparent # this shifts effected range backwards
			).desired_opacity
		) = _VBoxContainer.get_child(
				(_before_copies_amt * _label_quantity) # Where script thinks user's start of list is
				+ n # Iteration over the size of our list; _label_quantity
				- _opacity_list_look_behind_opaque # this shifts effected range backwards
				- _opacity_list_look_behind_transparent # this shifts effected range backwards
			).mid_opacity
	
	
	# Full-opacity section - you should set this after mid-opacity in current design.
	for n in _func_scope_opacity_range_amt:
		# Set every (relevant) label's current opacity
		(_VBoxContainer.get_child(
				(_before_copies_amt * _label_quantity) # Where script thinks user's start of list is
				+ n # Iteration over the size of our list; _label_quantity
				- _opacity_list_look_behind_opaque # this shifts effected range backwards
			).current_opacity
		) = (255.0/255.0)
		# Set every (revelant) label's desired opacity
		(_VBoxContainer.get_child(
				(_before_copies_amt * _label_quantity) # Where script thinks user's start of list is
				+ n # Iteration over the size of our list; _label_quantity
				- _opacity_list_look_behind_opaque # this shifts effected range backwards
			).desired_opacity
		) = (255.0/255.0)
	pass

# Done - Easing function used in _process (deltaTime stuff)
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

# Done - Used in _process. Might need extra cleanup to be more readable at a glance.
func _process_move_cursor_by( # Returns bool for _process_pulse_update_visuals_labels_opacity()!
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
			return true
		else:
			_current_cursor_pos -= 1
			_desired_VBox_pos += _VBox_move_by_amt
			return false
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
			return true
			#_flag_wants_to_snap_labels_opacity = true
		else:
			_current_cursor_pos += 1
			_desired_VBox_pos -= _VBox_move_by_amt
			return false
	else:
		printerr("[control-list-selection.gd]_process_move_cursor_by()
			catch case: _cursor_move_amt is only supposed to go up/down by one!")
		return false


func _process_pulse_update_visuals_labels_opacity(
	_should_snap_list_for_infinite_wrapping_effect : bool
	) -> void:
	var _func_scope_transparency_range_amt = ( # We find out how many labels to affect, and take some steps back from where the user would start (user's relative top of the list)
		_opacity_base_list_fully_opaque_quantity # Default is amt of labels originally contained (equal to range of stuff cursor UX selection range has); Alternative is a custom range specified by coder (this hasn't been tested yet)
		+ _opacity_list_look_behind_opaque # How many extra steps behind do we want to look from 1st label?
		+ _opacity_list_look_behind_transparent # How many extra steps back should we consider for mid-opacity?
		+ _opacity_list_look_ahead_opaque # How many extra steps forward do we want to look from the end of _opacity_base_list_fully_opaque_quantity?
		+ _opacity_list_look_ahead_transparent # How many etra steps forwards AFTER base opaque range + opaque look ahead should we consider for mid-opacity?
	)
	
	var _func_scope_opacity_range_amt = ( # We find out how many labels to affect, and take some steps back from where the user would start (user's relative top of the list)
		_opacity_base_list_fully_opaque_quantity # Default is amt of labels originally contained (equal to range of stuff cursor UX selection range has); Alternative is a custom range specified by coder (this hasn't been tested yet)
		+ _opacity_list_look_behind_opaque # How many extra steps behind do we want to look from 1st label?
		+ _opacity_list_look_ahead_opaque # How many extra steps forward do we want to look from the end of _opacity_base_list_fully_opaque_quantity?
	)
		
	# If we should move and handle opacity as normal...
	#if !_should_snap_list_for_infinite_wrapping_effect:
	# Start by politely asking all labels to turn invisible...
	for n in _VBoxContainer.get_child_count(false):
		_VBoxContainer.get_child(n)._set_desired_opacity(000.0)
	pass
	
	# Next, do a pass for mid-opacity stuff (range adjusted to be around cursor pos)...
	for n in _func_scope_transparency_range_amt:
		(_VBoxContainer.get_child(
				(_before_copies_amt * _label_quantity) # Where script thinks user's start of list is
				+ _current_cursor_pos # Starts counting from zero because arrays <3
				+ n # Iteration over the size of our list; _label_quantity
				- _opacity_list_look_behind_opaque
				- _opacity_list_look_behind_transparent # this shifts effected range backwards
			).desired_opacity
		) = _VBoxContainer.get_child( # I need to reference info in the label.
				(_before_copies_amt * _label_quantity) # Where script thinks user's start of list is
				+ _current_cursor_pos # Starts counting from zero because arrays <3
				+ n # Iteration over the size of our list; _label_quantity
				- _opacity_list_look_behind_opaque # this shifts effected range backwards
				- _opacity_list_look_behind_transparent # this shifts effected range backwards
			).mid_opacity
	
	# Finally, set full opacity stuff (range adjusted to be around cursor pos)...
	for n in _func_scope_opacity_range_amt:
		(_VBoxContainer.get_child(
					(_before_copies_amt * _label_quantity) # Where script thinks user's start of list is
					+ _current_cursor_pos # Starts counting from zero because arrays <3
					+ n # Iteration over the size of our list; _label_quantity
					- _opacity_list_look_behind_opaque # this shifts effected range backwards
				).desired_opacity
			) = (255.0/255.0)
	
	
	
	
	
	
	# If we should snap list contents' opacity due to OOB handling, also set current_opacity...
	if _should_snap_list_for_infinite_wrapping_effect:
		printerr("No snapping programmed yet!")
		# Start by politely asking all labels to turn invisible...
		for n in _VBoxContainer.get_child_count(false):
			_VBoxContainer.get_child(n)._set_current_opacity(000.0)
		pass
		
		# Next, do a pass for mid-opacity stuff (range adjusted to be around cursor pos)...
		for n in _func_scope_transparency_range_amt:
			(_VBoxContainer.get_child(
					(_before_copies_amt * _label_quantity) # Where script thinks user's start of list is
					+ _current_cursor_pos # Starts counting from zero because arrays <3
					+ n # Iteration over the size of our list; _label_quantity
					- _opacity_list_look_behind_opaque
					- _opacity_list_look_behind_transparent # this shifts effected range backwards
				).current_opacity
			) = _VBoxContainer.get_child( # I need to reference info in the label.
					(_before_copies_amt * _label_quantity) # Where script thinks user's start of list is
					+ _current_cursor_pos # Starts counting from zero because arrays <3
					+ n # Iteration over the size of our list; _label_quantity
					- _opacity_list_look_behind_opaque # this shifts effected range backwards
					- _opacity_list_look_behind_transparent # this shifts effected range backwards
				).mid_opacity
		
		# Finally, set full opacity stuff (range adjusted to be around cursor pos)...
		
		
		
		
		
		# This is all bad code. I need a more sound way of thinking about how I'm gonna tell labels
		# what other label to steal opacity info from in order to wrap up the logic behind keeping 
		# this visually clean.
		
		# I'm VERY CONFIDENT I can do something like "iterate over the list with new shifted select
		# range, and use 'the difference between cursorpos 0 and label_quantity - 1', as a copy
		# reference within what we were already using before updating with that info", which
		# would then probably justify using AN ENTIRE EXTRA DEEP COPY ARRAY in this function just 
		# for that. I'm out of time to think this through, so I'm stopping this session at this
		# note instead of blueprinting due to mental fatigue (I can't tell if this is a good idea
		# because I'm out of 'think of alternative ideas' energy).
		
	#	for n in _func_scope_opacity_range_amt:
	#		# Potential problem: If we NEED to update final item on list, we lose that control here.
	#		# I'll have to leave a dev note telling you to add a bit of extra padding for that.
	#		if (n+1 != null):
	#			(_VBoxContainer.get_child(
	#						(_before_copies_amt * _label_quantity) # Where script thinks user's start of list is
	#						+ _current_cursor_pos # Starts counting from zero because arrays <3
	#						+ n # Iteration over the size of our list; _label_quantity
	#						- _opacity_list_look_behind_opaque # this shifts effected range backwards
	#					).current_opacity
	#				) = _VBoxContainer.get_child(
	#					
	#				)
	#		else: # The bit we lost refined control over.
	#			# (Edge case) Stops working if last label was gonna cause a null reference error.
	#			
	#			_VBoxContainer.get_child(n).current_opacity = (000.0)
	#			
	#			# If this is a problem for label transparency updates, you're basically RIGHT at the
	#			# limit of the list; either subtract 1 to _opacity_list_look_ahead_transparent, or
	#			# _opacity_list_look_ahead_opaque, or _opacity_base_list_fully_opaque_quantity so
	#			# that you take up less space selecting (which is the 'see this range and move back'
	#			# mentality behind this code to keep sightreading and mental visualization easier) -
	#			# OR add 1 to _after_copies_amt so that you have more space to work with so that the
	#			# selection stuff stops being an edge case.
		pass
	pass

# FAILURE - Don't forget to place this somewhere affected post-cursor movement.
# Wow, there seems to be a blindspot from my POV, this just doesn't work when I'm calling
# _process_pulse_update_visuals_labels_opacity(_process_move_cursor_by(-1)) even though encapsulated
# function returns true accurately; It has modified behaviour for some reason, so I can't set 
# opacity in here. I'm gonna instead go for calling this inside of
# _process_move_cursor_by(), annoyingly enough, which makes this script a little less sightreadable.
#
# Nope, it's not encapsulation, this func's behaviour is in a blindspot for me.
# Despite executing print and getting variables, I can't set them with my usual.
#
# ...AND I can call functions in the labels that I can't set in. Eureka moment?
#
# Apparently the 'fail to set opacity' cases I said here are referencing "<null>".
#
# Nope seems to reference '<null>' either way. Alright, I can't quite identify *WHAT* is happening,
# but using function calls seem to be an adequate way to handle this.
#
# Guess we're getting tunnel vision.
#
# Wait, no. Something's wrong.
#
# ohhhhhhhhhhhhhh that was so stupid. There was later code in here that overwrote my progress, and
# it was a copy/paste from my initial setup func.
#
# Trying original attempt now.
#
# Okay, turns out the critical bug is desired_opacity not interfacing with the labels' easing 
# functions because those funcs are not handling any of this right. Yaaaaay...
func _old_process_pulse_update_visuals_labels_opacity(
	_should_force_update_opacity_stuff_for_smoke_and_mirrors : bool
	) -> void:
	var _func_scope_transparency_range_amt = ( # We find out how many labels to affect, and take some steps back from where the user would start (user's relative top of the list)
		_opacity_base_list_fully_opaque_quantity # Default is amt of labels originally contained (equal to range of stuff cursor UX selection range has); Alternative is a custom range specified by coder (this hasn't been tested yet)
		+ _opacity_list_look_behind_opaque # How many extra steps behind do we want to look from 1st label?
		+ _opacity_list_look_behind_transparent # How many extra steps back should we consider for mid-opacity?
		+ _opacity_list_look_ahead_opaque # How many extra steps forward do we want to look from the end of _opacity_base_list_fully_opaque_quantity?
		+ _opacity_list_look_ahead_transparent # How many etra steps forwards AFTER base opaque range + opaque look ahead should we consider for mid-opacity?
	)
	
	var _func_scope_opacity_range_amt = ( # We find out how many labels to affect, and take some steps back from where the user would start (user's relative top of the list)
		_opacity_base_list_fully_opaque_quantity # Default is amt of labels originally contained (equal to range of stuff cursor UX selection range has); Alternative is a custom range specified by coder (this hasn't been tested yet)
		+ _opacity_list_look_behind_opaque # How many extra steps behind do we want to look from 1st label?
		+ _opacity_list_look_ahead_opaque # How many extra steps forward do we want to look from the end of _opacity_base_list_fully_opaque_quantity?
	)
	
	# Here comes some textual vomit.
	
	# If we want smooth, normal updating
	if !_should_force_update_opacity_stuff_for_smoke_and_mirrors:
		#_flag_wants_to_snap_labels_opacity = false # This is also now redundant.
		
		# Gently tells all labels that they want to turn invisible.
		for n in _VBoxContainer.get_child_count(false):
			#print("omigah", n)
			#print("Can you 'get'? ", _VBoxContainer.get_child(n).can_i_read_this_variable," ",n)
			#print("Testing calls", _VBoxContainer.get_child(n)._call_func_test()," ",n)
			# Okay, apparently labels aren't regulating current_opacity yet. Hang on.
			#_VBoxContainer.get_child(n).current_opacity = (000.0/225.0)
			_VBoxContainer.get_child(n).desired_opacity = (000.0/225.0)
#			_VBoxContainer.get_child(n)._set_desired_opacity(000.0)
#			_VBoxContainer.get_child(n).set("theme_override_colors/default_color",
#				Color(
#					_VBoxContainer.get_child(n).current_color.r,
#					_VBoxContainer.get_child(n).current_color.g,
#					_VBoxContainer.get_child(n).current_color.b,
#					0.0)
#				)
			pass
		
		# Updates desired opacity on relevant labels -- This section handles mid-opacity.
		for n in _func_scope_transparency_range_amt:
			(_VBoxContainer.get_child(
					(_before_copies_amt * _label_quantity) # Where script thinks user's start of list is
					+ _current_cursor_pos # Starts counting from zero because arrays <3
					+ n # Iteration over the size of our list; _label_quantity
					- _opacity_list_look_behind_opaque
					- _opacity_list_look_behind_transparent # this shifts effected range backwards
				).desired_opacity
			) = _VBoxContainer.get_child( # I need to reference a var in the label.
					(_before_copies_amt * _label_quantity) # Where script thinks user's start of list is
					+ _current_cursor_pos # Starts counting from zero because arrays <3
					+ n # Iteration over the size of our list; _label_quantity
					- _opacity_list_look_behind_opaque # this shifts effected range backwards
					- _opacity_list_look_behind_transparent # this shifts effected range backwards
				).mid_opacity
		
		# Updates desired opacity on relevant labels -- This section handles full opacity.
		for n in _func_scope_opacity_range_amt:
			(_VBoxContainer.get_child(
						(_before_copies_amt * _label_quantity) # Where script thinks user's start of list is
						+ _current_cursor_pos # Starts counting from zero because arrays <3
						+ n # Iteration over the size of our list; _label_quantity
						- _opacity_list_look_behind_opaque # this shifts effected range backwards
					).desired_opacity
				) = (255.0/255.0)
		pass
	elif _should_force_update_opacity_stuff_for_smoke_and_mirrors:
		printerr("nope!")
		pass
	
	
	
	
	
	
	# OLD CODE BELOW
	
	
	
	
	# Half-opacity section - you should do this first in current design.
#	for n in _func_scope_transparency_range_amt:
#		# Set every (revelant) label's current opacity
#		(_VBoxContainer.get_child(
#				(_before_copies_amt * _label_quantity) # Where script thinks user's start of list is
#				+ n # Iteration over the size of our list; _label_quantity
#				- _opacity_list_look_behind_opaque
#				- _opacity_list_look_behind_transparent # this shifts effected range backwards
#			).current_opacity
#		) = _VBoxContainer.get_child(
#				(_before_copies_amt * _label_quantity) # Where script thinks user's start of list is
#				+ n # Iteration over the size of our list; _label_quantity
#				- _opacity_list_look_behind_opaque # this shifts effected range backwards
#				- _opacity_list_look_behind_transparent # this shifts effected range backwards
#			).mid_opacity
#		# Set every (revelant) label's desired opacity
#		(_VBoxContainer.get_child(
#				(_before_copies_amt * _label_quantity) # Where script thinks user's start of list is
#				+ n # Iteration over the size of our list; _label_quantity
#				- _opacity_list_look_behind_opaque # this shifts effected range backwards
#				- _opacity_list_look_behind_transparent # this shifts effected range backwards
#			).desired_opacity
#		) = _VBoxContainer.get_child(
#				(_before_copies_amt * _label_quantity) # Where script thinks user's start of list is
#				+ n # Iteration over the size of our list; _label_quantity
#				- _opacity_list_look_behind_opaque # this shifts effected range backwards
#				- _opacity_list_look_behind_transparent # this shifts effected range backwards
#			).mid_opacity
#	
#	
#	# Full-opacity section - you should do this after in current design.
#	for n in _func_scope_opacity_range_amt:
#		# Set every (relevant) label's current opacity
#		(_VBoxContainer.get_child(
#				(_before_copies_amt * _label_quantity) # Where script thinks user's start of list is
#				+ n # Iteration over the size of our list; _label_quantity
#				- _opacity_list_look_behind_opaque # this shifts effected range backwards
#			).current_opacity
#		) = (255.0/255.0)
#		# Set every (revelant) label's desired opacity
#		(_VBoxContainer.get_child(
#				(_before_copies_amt * _label_quantity) # Where script thinks user's start of list is
#				+ n # Iteration over the size of our list; _label_quantity
#				- _opacity_list_look_behind_opaque # this shifts effected range backwards
#			).desired_opacity
#		) = (255.0/255.0)
	pass
