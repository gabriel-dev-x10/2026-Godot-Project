extends Control

## What's new?
# I stopped being lobotomized and fixed visual opacity interaction when moving OOB for both upwards
# and downwards movement. This honestly shouldn't have taken as long as it did, and yeah, in my eyes
# I **did** kind of neglect my website by being functionally absent because of this in-between my
# life stuff, but in my defense...
#
# I was busy!
#
# ...ahem.
#
# This marks a completed milestone for this script! The only other part I could see being difficult
# right now is the BBCode stuff, but that just seems like adding a pass after generating
# before/after labels in _ready() - it's unlikely that it'll challenge how I think about this
# script's code.
#
# BEFORE DOING A COMMIT, I want to clean up all this garbage code and to make sure this script is 
# easily sightreadable when auditing. This means grouping up top variables properly, making sure
# there's no serious clutter with new code, and generally being happy with everything you're seeing.
# No dumb print calls or excessive vulgarity allowed.
#
# If you're seeing this, it means I've done a good job with cleanup, alongside you should start
# seeing more decent structuring with my code moving forwards.

## Important notes:
# The minimum size of the list to be designed around should always be 2 or greater.
# This script uses math without a check for selectors being out-of-bounds of what labels literally
# exist, so MAKE SURE _before_copies_amt and _after_copies_amt is bigger than the total amt for vars
#   like _opacity_base_list_fully_opaque_quantity that are used to guage what range of stuff to
#   select for opacity change animation!
#   See LIST'S LABEL GENERATION AND OPACITY MANAGEMENT CUTOMIZATION (NON-BBCODE STUFF) for vars.

##TODO:
# This prototype is taking much longer than an hour.
# This seems easy, but it's been a WHILE since I did this.
#
# v Add controls: Make 'confirm' do a thing
# v Read up/down
# v Move the list up/down
# v Slap a quadease with Godot's ver of time.deltaTime()
# v Add core ux: Track where the cursor is + wrapping
# v Now using Wendy.ttf for label text
# > I want this to have the vibe of being infinitely scrolling. Smoke and mirrors.
#   v Add 4 ghost sections split between top and bottom (they're copies of OG list)
#   v Adjust VBox list up by 2x its size (calculate float at runtime - on ready)
#   v Have a ghAstLY vIiIibe to the full list by messing with opacity
#		v This is in "_process_pulse_update_visuals_labels_opacity()"
#   > Add border around text
#   - ooo I see some BBCode, I wanna experiment and animate the text, too
#   - See if we can get the labels to move diagonally like it's a game menu? like "\"
#
# > Test how behaviour works with different list sizes
#   v Behaviour is perfect as pertains to cursor selection and list physically moving!
#   - Make sure BBCode and opacity works perfectly (lists should ALWAYS be 2 or greater in count)
#
# NOTE: Make sure to only use scancodes in input map!! You're using a custom XKB layout!
#
# Stuff to do during polish round:
# - Tweak list easing variables to be feel smoother
#		- (less snappy(?), but still responsive?? I need a better vernacular for this)
# - If holding arrows, start auto-moving.
# - Add a shadowed VBox BG generated during runtime because it's awesome and adds
#		- much-needed contrast + depth
# - Start studying easing functions (I'll probably just have them noted somewhere)
# - Start studying exit codes and apply them properly in this project.

# Much better.

# These variables are mostly grouped by what general function/purpose they serve in this script.

## --- DEBUGGING FLAGS ---
# Start using this after commiting. Should be used for non-spammable analysis.
@export var _flag_developer_printing : bool = false
# --- END OF DEBUGGING FLAGS ---

# These are used for multiple purposes or are intentionally spaghettified for ease of access.

## --- COMPLEX STUFF ---
# UX variable that this script is built around. Used to know where user so we can read scenechange
#   text, and is thus used by a ton of opacity management stuff. Last possible value is
#   "_label_quantity - 1". Handled in _process_move_cursor_by().
var _current_cursor_pos : int = 0 # Hope I don't need to say this, but 0 is the first possible value
# Given to all labels while calling _ready(). Currently used for opacity handling + scene text UX.
@export var _label_script : Script
# Given to all labels while calling _ready(). Currently used to set current font to wendy.ttf
@export var _label_theme : Theme
# ---- END OF COMPLEX STUFF ---

# UX-specific vars.

## --- UX STUFF ---
# _current_cursor_pos is in 'COMPLEX STUFF' because of it being tied to opacity handling animations.
var _current_scene : String = "res://list_selection.tscn"
# --- END OF UX STUFF ---

# 1st var is a critical component, vars 2-4 is used to label creation, remaining used for opacity.

## --- LIST'S LABEL GENERATION AND OPACITY MANAGEMENT CUTOMIZATION (NON-BBCODE STUFF) ---
var _label_quantity : int # Used to remember how big the list is (counts from 1)
var _Labels : Array[RichTextLabel] # No array-specific naming convention at a glance sooooooooooooo
# Used in _ready_visual_generate_primary_list_before_after() and _process_move_cursor_by()
var _before_copies_amt : int = 3
# Used in _ready_visual_generate_primary_list_before_after() and _process_move_cursor_by()
var _after_copies_amt : int = 5
# Intended to make the script more customizable after I polish it, but this currently does nothing.
var _should_make_ready_overwrite_opaque_quantity : bool = true
# Sets itself _label_quantity, uses value set here if above var is false. Untested. Adds to below.
var _opacity_base_list_fully_opaque_quantity : int = 2
# Customizable, but untested for robustness. Added to _func_scope_opaque/transparency_range_amt.
var _opacity_list_look_behind_opaque : int = 0
# Customizable, but untested for robustness. Added to _func_scope_transparency_range_amt.
var _opacity_list_look_behind_transparent : int = 1
# Customizable, but untested for robustness. Added to _func_scope_opaque/transparency_range_amt.
var _opacity_list_look_ahead_opaque : int = 0
# Customizable, but untested for robustness. Added to _func_scope_transparency_range_amt.
var _opacity_list_look_ahead_transparent : = 2
# --- END OF LABEL GENERATION AND OPACITY MANAGEMENT CUTOMIZATION (NON-BBCODE STUFF) ---

# Animation handling during _process(). These adjust position every frame, functionally animating.

## --- LIST CONTAINER MOVEMENT HANDLING ---
@export var _VBoxContainer : VBoxContainer # LHand Y-, I think??? Y+ is down, Xr. This note is awful
# Used with this script's in-code easing animation. This is where _VBoxContainer currently is.
var _default_VBox_pos : float
# Used with this script's in-code easing animation. This is where _VBoxContainer wants to go to.
var _desired_VBox_pos : float
# Manually set this difference between 1st and 2nd item. Careful with fonts, as spacing can adjust.
var _VBox_move_by_amt : float = 38.0
# Easing variable for _handle_ease_out(). Intended range is [0.0, 1.0[ (Setting 1.0 will multiply 0)
var _var_ease_out_amt : float = 0.25
# Easing variable for _handle_ease_out(). This affects aptitude (if I'm using that right); Intensity
var _var_ease_out_exp : float = 2.5
# Equation (function needs to adjust by +/- result depending on if we want to move up or down):
# pos.y +/- pos.y (_desired_VBox_pos - _VBoxContainer.position.y) * ((1 - _ease_amt) ** _ease_exp)

# --- END OF LIST CONTAINER MOVEMENT HANDLING ---


 

# System function. This is where all initializing code is run before the session starts.
func _ready() -> void:
	
	# Prepares VBoxContainer visual movement information (Only remembers vertical position)
	_default_VBox_pos = _VBoxContainer.position.y # Used for easier resets
	_desired_VBox_pos = _VBoxContainer.position.y # Used for vertical easing
	
	# Prepares VBox visuals wrapping (inf wrap, snaps container) + UX cursor movement/selection;
	_label_quantity = _VBoxContainer.get_child_count(false)  # starts counting from int 1
	
	# Needs to be after _label_quantity being processed.
	_ready_visual_generate_primary_list_before_after() # Uses _before_copies_amt, _after_copies_amt
	
	# Adjusts list for amount of copies we made w/ _ready_visual_generate_primary_list_before_after
	## NOTE:
	# This could be better optimized to remove mental detour when working with visual resets when
	# for variables _default_VBox_pos and _desired_VBox_pos. Would require reworking current code,
	# so I'm going to keep this as-is for now since this analysis is happening during a cleanup
	# round.
	_VBoxContainer.position.y -= (_label_quantity * _before_copies_amt * _VBox_move_by_amt)
	_desired_VBox_pos -= (_label_quantity * _before_copies_amt * _VBox_move_by_amt)
	
	# Self-explanatory. Needs to be after list generation.
	_ready_set_opacity_on_all_labels_to_zero()
	
	# Needs to be after setting labels opacity to zero.
	if _should_make_ready_overwrite_opaque_quantity:
		_opacity_base_list_fully_opaque_quantity = _label_quantity
	else: # Not yet implemented
		# Customization warning.
		printerr("You didn't think about how this script handles 
			_opacity_base_list_fully_opaque_quantity when it's not the same as the amount of items 
			as what you originally had pre-labels duplication for the infinite wrapping effect!
			
			You let this be possible for more robust customization in-code.
			
			I didn't finish writing code at the time of writing, but this should affect all opacity
			management coming from this script, both in this script masking the current opacity of
			labels (in bulk or otherwise) and in this script telling what opacity to ease to (in
			bulk or otherwise).
			
			This script's basically the command centre for that in design, DON'T try to set this
			stuff in the labels' scripts, this one WILL overwrite it.")
		pass
	
	# Handles half-opacity and full-opacity for the first time in this script after setting all 0.
	_ready_set_opacity_on_desired_stuff() # Set after _ready_set_opacity_on_all_labels_to_zero()
	
	if _flag_developer_printing:
		print("")
		print("Label count: ", _label_quantity)
		print("Child count: ", _VBoxContainer.get_child_count(false))
	pass

# System function. This is where the main session happens.
func _process(_delta: float) -> void:
	
	## --- START OF INPUTS SECTION ---
	if Input.is_action_just_pressed("up"):
		# _move_cursor_by handles UX and _VBox positioning, _opacity handles animation management
		_process_pulse_update_visuals_labels_opacity(_process_move_cursor_by(-1), -1)
		if _flag_developer_printing:
			print("ue oshimatta!
				New cursorpos: ", _current_cursor_pos, " New list position: ", _desired_VBox_pos
				)
		pass
	
	if Input.is_action_just_pressed("down"):
		# also, _move_cursor_by returns true if user goes OOB upwards/downwards for looping effect
		_process_pulse_update_visuals_labels_opacity(_process_move_cursor_by(+1), +1)
		if _flag_developer_printing:
			print("shita oshimatta!
			New cursorpos: ", _current_cursor_pos, " New list position: ", _desired_VBox_pos
			)
		pass
	
	if Input.is_action_just_pressed("confirm"):
		
		# UX wiring: Find out where we are, and behave by selected label's target_load_path string
		match _VBoxContainer.get_child(
			_current_cursor_pos + (_before_copies_amt*_label_quantity)
			).target_load_path:
			
			# (Default) Reload the current level select scene from scratch
			"RELOAD", "reload", "refresh", "":
				get_tree().change_scene_to_file(_current_scene)
			
			# Close game
			"QUIT", "quit":
				get_tree().quit(1) # I should check how to handle exit codes...
			
			# Load whatever the Godot relative path is. This will change scenes.
			_:
				get_tree().change_scene_to_file(
					_VBoxContainer.get_child(_current_cursor_pos).target_load_path
				)
		pass
	
	if Input.is_action_just_pressed("cancel"):
		#
		# There's no surmenu yet, so we just give up instead.
		get_tree().quit(1)
		pass
	
	if Input.is_action_pressed("quit"):
		#
		get_tree().quit(1)
		pass
	# --- END OF INPUTS SECTION ---
	
	# Handles the easing of the vertical position of the _VBoxContainer holding labels.
	_handle_ease_out(
		_var_ease_out_amt,
		_var_ease_out_exp,
		_delta
	)
	pass

# This is a good idea for fast troubleshooting, but this is something to add during polishing.
#func _test():
#	printerr("control-list-selection.gd:
#	_process_pulse_update_visuals_labels_opacity():
#	_should_mask_list_for_infinite_wrapping_effect:
#	_move_direction == -1:
#	!is_instance_valid:
#		Read these errors carefully, this message only checks for one problem at a time!
#		
#		You don't have enough space to work with labels' opacity management!
#		Add more space by adding to the following variable(s):")
#	print("						_after_copies_amt")
#	printerr("Here's the space this value is a part of:")
#	print("						(_after_copies_amt * label_quantity) + 'end of list adjustment': ", 
#								_after_copies_amt * _label_quantity 
#								+ (_before_copies_amt * _label_quantity)
#								+ (_label_quantity -1)
#		)
#	printerr("Here's the amount you need to add for this script to work:")
#	print("						", _opacity_base_list_fully_opaque_quantity
#		+ _opacity_list_look_ahead_opaque + _opacity_list_look_ahead_transparent
#		)
	pass

# Done - This generates extra labels in _ready()
func _ready_visual_generate_primary_list_before_after() -> void:
	
	# Preparation of '_Labels[RichTextLabel]', we want to duplicate elements in this function
	_Labels.resize(_label_quantity)
	if _flag_developer_printing:
		print("Labels size", _Labels.size()) # I'm guessing it's counting from 1?
		pass
	
	# This array is only used in this func. I'll need a script-scope array for a shadow backdrop.
	var _disposable_deep_copy_labels_text : Array[String]
	_disposable_deep_copy_labels_text.resize(_label_quantity)
	
	# Delete when ready; get_child_count() counts from 0.
	#for n in _VBoxContainer.get_child_count(): # Count from 0 or 1? Let's find out the hard way!
	#	_disposable_deep_copy_labels_text[n] = _VBoxContainer.get_child(n).text
	#	pass
	
	# ...why is it green. stop that. you're scaring me.
	for n in _label_quantity: _Labels[n] = _VBoxContainer.get_child(n)
	
	# Script needs to move new labels to the top of the list; Because Godot Control nodes use an
	# HTML-like logic, all labels need to be in the same order in the tree that you'd want them to
	# be shown during runtime.
	var _original_label_array_size = _Labels.size()
	
	# Start of 'before' labels generation part
	for _current_print_set in (_before_copies_amt):
		var _temp_iteration : int = 0
		for n in _Labels:
			var _instance_RichTextLabel = RichTextLabel.new()
			_instance_RichTextLabel.fit_content = true
			_instance_RichTextLabel.autowrap_mode = 0
			var _temp_current_cycle_name = (
				"Pre-list instance "+ str(_current_print_set) +" dot "+ str(n)
				)
			_instance_RichTextLabel.name = _temp_current_cycle_name
			_instance_RichTextLabel.text = (
				_Labels[_temp_iteration].text# + " (prelist "+ str(_current_print_set) +")"
				)
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
	# End of 'before' labels generation part
	
	# boo.
	
	# Start of 'after' labels generation part
	for _current_print_set in (_after_copies_amt):
		var _temp_iteration : int = 0
		for n in _Labels:
			var _instance_RichTextLabel = RichTextLabel.new()
			_instance_RichTextLabel.fit_content = true
			_instance_RichTextLabel.autowrap_mode = 0
			var _temp_current_cycle_name = (
				"Post-list instance "+ str(_current_print_set) +" dot "+ str(n)
				)
			_instance_RichTextLabel.name = _temp_current_cycle_name
			_instance_RichTextLabel.text = (
				_Labels[_temp_iteration].text# + " (postlist "+ str(_current_print_set) +")"
				)
			_instance_RichTextLabel.theme = _label_theme
			_instance_RichTextLabel.set_script(
				_label_script # apparently better to use set_script() instead of .script = <Script>
			)
			_VBoxContainer.add_child(_instance_RichTextLabel)
			_temp_iteration += 1
		pass
	# End of 'after' labels generation part
	pass

# Done - Execution is much easier than the idea generation for this
func _ready_set_opacity_on_all_labels_to_zero() -> void:
	
	for n in _VBoxContainer.get_child_count(false): # counts from 0
		_VBoxContainer.get_child(n).current_opacity = (000.0/225.0)
		_VBoxContainer.get_child(n).desired_opacity = (000.0/225.0)
		pass

# Done - Boilerplatey. Reading this is a slight headache.
func _ready_set_opacity_on_desired_stuff() -> void:
	
	# Basically, the logic is to find the exact size of the labels we'd affect, then move that range
	# backwards (closer to 0) depending on where we want to start moving through the list from 
	# (which would be wherever this script thinks "_before_copies_amt * _label_quantity" starts
	# from -- this is math is where 'cursor position 0' is supposed to be, in the label's 
	# position in the list instead of intended UX selection is.)
	
	# We find out how many labels to affect, and take some steps back from where the user would
	# start (user's relative top of the list)
	var _func_scope_transparency_range_amt = (
		# Default is amt of labels originally contained (equal to range of stuff cursor UX selection
		# range has); Alternative is a custom range specified by coder (this hasn't been tested yet)
		_opacity_base_list_fully_opaque_quantity
		# How many extra steps behind do we want to look from 1st label?
		+ _opacity_list_look_behind_opaque
		# How many extra steps back should we consider for mid-opacity?
		+ _opacity_list_look_behind_transparent
		# How many extra steps forward do we want to look from the end of
		# _opacity_base_list_fully_opaque_quantity?
		+ _opacity_list_look_ahead_opaque
		# How many etra steps forwards AFTER base opaque range + opaque look ahead should we
		# consider for mid-opacity?
		+ _opacity_list_look_ahead_transparent
	)
	if _flag_developer_printing:
		print("_func_scope_transparency_range_amt ", _func_scope_transparency_range_amt)
		pass
	
	# We find out how many labels to affect, and take some steps back from where the user would
	# start (user's relative top of the list)
	var _func_scope_opacity_range_amt = (
		# Default is amt of labels originally contained (equal to range of stuff cursor UX selection
		# range has); Alternative is a custom range specified by coder (this hasn't been tested yet)
		_opacity_base_list_fully_opaque_quantity
		# How many extra steps behind do we want to look from 1st label?
		+ _opacity_list_look_behind_opaque
		# How many extra steps forward do we want to look from the end of
		# _opacity_base_list_fully_opaque_quantity?
		+ _opacity_list_look_ahead_opaque
	)
	if _flag_developer_printing:
		print("_func_scope_opacity_range_amt ", _func_scope_opacity_range_amt)
		pass
	
	# Half-opacity section - you should do this first if you want to do it the way I did.
	for n in _func_scope_transparency_range_amt:
		
		# Set every (revelant) label's current opacity
		(_VBoxContainer.get_child(
			(_before_copies_amt * _label_quantity) # Where script thinks user's start of list is
			+ n # Iteration over the size of our list; _label_quantity
			- _opacity_list_look_behind_opaque
			- _opacity_list_look_behind_transparent # this shifts effected range backwards
			).current_opacity
				) = _VBoxContainer.get_child(
				(_before_copies_amt * _label_quantity)
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
			(_before_copies_amt * _label_quantity)
			+ n # Iteration over the size of our list; _label_quantity
			- _opacity_list_look_behind_opaque # this shifts effected range backwards
			).desired_opacity
				) = (255.0/255.0)
	pass

# Done - Easing function used in _process (deltaTime stuff)
func _handle_ease_out (
	_ease_amt : float,
	_ease_exp : float,
	_delta : float # You mult by time passed between frames so that my gameplay looks the same for 
	# you. (I plan around 60fps, it wouldn't be fair to 144fps users if an enemy moved faster per
	# frame compared to me in a First Person Shooter, for example.)
	):
	
	# If _VBox isn't where it wants to be...
	if _VBoxContainer.position.y != _desired_VBox_pos:
		# ... and if it wants to move upwards...
		if _VBoxContainer.position.y < _desired_VBox_pos:
			# ... lerp upwards to desired position.
			_VBoxContainer.position.y += ( # Add current value with following expression.
				(_desired_VBox_pos - _VBoxContainer.position.y) # What's the distance to endpoint?
				* ((1 - _ease_amt) ** _ease_exp) # What percent of that are we going to this frame?
				)
		# ... and if it wants to move downwards...
		else:
			# ... lerp downwards to desired position.
			_VBoxContainer.position.y -= ( # This is what the ease looks like, by the way.
				(_VBoxContainer.position.y - _desired_VBox_pos)
				* ((1 - _ease_amt) ** _ease_exp) # No visual graph for you, though.
				)
	pass

# Done - Boilerplatey, but Okayish code. It works.
func _process_move_cursor_by( # Returns bool for _process_pulse_update_visuals_labels_opacity()
	_cursor_move_amt : int
	):
	
	# If cursor is moving upwards...
	if _cursor_move_amt == -1:
		
		# If cursor is going up and out of bounds... don't! Cave Johnson would be so proud.
		if ((_current_cursor_pos + _cursor_move_amt) < 0):
			
			if _flag_developer_printing:
				print("Cursor wants to be less than 0! Moved to end of list instead.")
				pass
			
			# Updates UX logic. If we'd go OOB, set cursor to end of list.
			_current_cursor_pos = (_label_quantity - 1)
			
			# Updates _VBox container's position to bottom of list and accurately masks wrapping.
			
			# This part sets literal position to where OOB entry would've been from the bottom.
			_VBoxContainer.position.y = _default_VBox_pos - (
				_VBox_move_by_amt * (_label_quantity-1) # _label_quantity counts from 1, not 0
				) - _VBox_move_by_amt - (_label_quantity*(_before_copies_amt) * _VBox_move_by_amt)
			
			# This part sets desired position to where the latest position should be for user.
			_desired_VBox_pos = _default_VBox_pos - (
				_VBox_move_by_amt * (_label_quantity-1) # _label_quantity counts from 1, not 0
				) - (_label_quantity*(_before_copies_amt) * _VBox_move_by_amt)
			
			# Tells _process_pulse_update_visuals_labels_opacity() to wrap.
			return true
		
		# Move upwards normally if we're not going OOB
		else:
			
			# Updates UX (current cursor position)
			_current_cursor_pos -= 1
			
			# Updates visuals - desired vars are used for easing; This case, _VBox up/down movement.
			_desired_VBox_pos += _VBox_move_by_amt
			
			# Tells _process_pulse_update_visuals_labels_opacity() not to wrap.
			return false
	
	# If cursor is moving downwards...
	elif _cursor_move_amt == +1:
		
		# If we're going down and out of bounds... don't!
		if ((_current_cursor_pos + _cursor_move_amt) > (_label_quantity - 1)):
			if _flag_developer_printing:
				print("Cursor wants to be more than available! Moved to end of list instead.")
				pass
			
			# Updates UX logic. If we'd go OOB, set cursor to start of list.
			_current_cursor_pos = (0)
			
			# Updates _VBox container's position to top of list and accurately masks wrapping.
			_VBoxContainer.position.y = _default_VBox_pos + _VBox_move_by_amt - (
				_label_quantity*_before_copies_amt * _VBox_move_by_amt
				)
			
			# This part sets desired position to where the first position should be for user.
			_desired_VBox_pos = _default_VBox_pos - (
				_label_quantity*_before_copies_amt * _VBox_move_by_amt
				)
			
			# Tells _process_pulse_update_visuals_labels_opacity() to wrap.
			return true
		
		# Move downwards normally if not going OOB
		else:
			
			# Updates UX (current cursor position)
			_current_cursor_pos += 1
			
			# Updates visuals - desired vars are used for easing; This case, _VBox up/down movement.
			_desired_VBox_pos -= _VBox_move_by_amt
			
			# Tells _process_pulse_update_visuals_labels_opacity() not to wrap.
			return false
	
	# If we're not moving up/down by 1 step... what are we even trying to do here?
	# There's nothing planned for this, so I'm disabling anything outside of current design.
	else:
		
		if _flag_developer_printing:
			printerr("[control-list-selection.gd]_process_move_cursor_by()
				catch case: _cursor_move_amt is only supposed to go up/down by one!")
			pass
		
		# _process_pulse_update_visuals_labels_opacity() doesn't need wrapping if it doesn't move.
		return false

# Done. Finally.
func _process_pulse_update_visuals_labels_opacity(
	_should_mask_list_for_infinite_wrapping_effect : bool,
	_move_direction # Can be an int (-1=up, +1=down), used for wrapping effect.
	) -> void:
	
	# We find out how many labels to affect, and take some steps back from where the user would
	# start adding transparency (user's relative top of the list)
	var _func_scope_transparency_range_amt = (
		# Default is amt of labels originally contained (equal to range of stuff cursor UX selection
		# range has); Alternative is a custom range specified by coder (this hasn't been tested yet)
		_opacity_base_list_fully_opaque_quantity
		# How many extra steps behind do we want to look from 1st label?
		+ _opacity_list_look_behind_opaque
		# How many extra steps back should we consider for mid-opacity?
		+ _opacity_list_look_behind_transparent
		# How many extra steps forward do we want to look from the end of
		# _opacity_base_list_fully_opaque_quantity?
		+ _opacity_list_look_ahead_opaque
		# How many etra steps forwards AFTER base opaque range + opaque look ahead should we
		# consider for mid-opacity?
		+ _opacity_list_look_ahead_transparent
		)
	
	# We find out how many labels to affect, and take some steps back from where the user would
	# start adding transparency (user's relative top of the list)
	var _func_scope_opacity_range_amt = (
		# Default is amt of labels originally contained (equal to range of stuff cursor UX selection
		# range has); Alternative is a custom range specified by coder (this hasn't been tested yet)
		_opacity_base_list_fully_opaque_quantity
		# How many extra steps behind do we want to look from 1st label?
		+ _opacity_list_look_behind_opaque
		# How many extra steps forward do we want to look from the end of
		# _opacity_base_list_fully_opaque_quantity?
		+ _opacity_list_look_ahead_opaque
		)
	
	# Preparation for if _should_mask_list_for_infinite_wrapping_effect is true. See use below.
	var _disposable_opacity_information_current : Array[float]
	var _disposable_opacity_information_desired : Array[float]
	_disposable_opacity_information_current.resize(_VBoxContainer.get_child_count(false))
	_disposable_opacity_information_desired.resize(_VBoxContainer.get_child_count(false))
	var _disposable_setter_var : float
	
	# Setup info used as a reference point for masking to know what to do.
	for n in _VBoxContainer.get_child_count(false):
		
		# Copies list content to be read later; It's easier to read a copy than to move null around.
		_disposable_opacity_information_current[n] = _VBoxContainer.get_child(n).current_opacity
		_disposable_opacity_information_desired[n] = _VBoxContainer.get_child(n).desired_opacity
		pass
	
	if _flag_developer_printing:
		print(_current_cursor_pos)
		print(_disposable_opacity_information_current)
		
		printerr("Setting desired to invisible on all labels.")
		pass
	
	# This needs to happen after getting a deep copy of every label's opacity info
	for n in _VBoxContainer.get_child_count(false):
		_VBoxContainer.get_child(n).desired_opacity = (000.0/255.0)
		pass
	
	# If we're moving normally (not wrapping/going OOB)...
	if !_should_mask_list_for_infinite_wrapping_effect:
		if _flag_developer_printing:
			print("Moving normally!")
			pass
		
		# Pass 1: Transparency; Set affected range relative to where cursor is.
		for n in _func_scope_transparency_range_amt:
			( # Set desired_opacity to labels' mid_opacity values
				_VBoxContainer.get_child(
					# Range adjustments
					(_before_copies_amt * _label_quantity)
					- _opacity_list_look_behind_transparent
					- _opacity_list_look_behind_opaque
					# Stuff that's relative to cursor position/iteration of range
					+ _current_cursor_pos
					+ n
					)
					).desired_opacity = (
						_VBoxContainer.get_child(
						# Range adjustments
						(_before_copies_amt * _label_quantity)
						- _opacity_list_look_behind_transparent
						- _opacity_list_look_behind_opaque
						# Stuff that's relative to cursor position/iteration of range
						+ _current_cursor_pos
						+ n
						)
						).mid_opacity
			
			# Don't set current_opacity here; It'll ruin label easing animation.
			pass
		
		# Pass 2: Opacity; Set affected range relative to where cursor is.
		for n in _func_scope_opacity_range_amt:
			# Set desired_opacity to full opacity
			_VBoxContainer.get_child(
				# Range adjustments
				(_before_copies_amt * _label_quantity)
				- _opacity_list_look_behind_opaque
				# Stuff that's relative to cursor position/iteration of range
				+ _current_cursor_pos
				+ n
				).desired_opacity = (255.0/255.0)
			pass
		
		# Don't set current_opacity here; It'll ruin label easing animation.
		pass
	
	
	
	# Next is handling setting opacity to sibling label's values.
	
	# If we're wrapping (going OOB) and want to handle the smoke/mirrors effect...
	elif _should_mask_list_for_infinite_wrapping_effect:
		if _flag_developer_printing:
			print("Attempting wrapping effect!")
			pass
		
		##Note (Check this if you're getting animation bugs after customizing top variables):
		#   I'd rather over-explain than not say enough.
		#
		#       - In case you need to know...
		#   _label_quantity is what the original size of the array is, and will be set to the same
		# integer quantity you're seeing in-editor to make this script more robust by preventing
		# having to adjust manually every time something minor changes. Used as a basic building
		# block for everything else in here.
		#
		#       - In this function's context...
		#   You'll need extra slots at the top/bottom that are as big as the list contents that the
		# user can navigate (so whatever integer _label_quantity is, since that's what the UX func,
		# _process_move_cursor_by(), uses to figure out where to end of the list is like this:
		# "_current_cursor_pos = _label_quantity-1". Following my explaining, us wanting the range 
		# _current_cursor_pos results in "_label_quantity-1+1").
		#
		#   There's no check for this; You should expect these extra labels to stay invisible at
		# all times to avoid visual animation bugs by keeping track of everything during
		# customization. (labels' opacity easing funcs are effectively an animation curve without
		# a graph to represent it)
		#
		#   The reason I'm doing this is because we'll be making an effective range in this func
		# that'll be the same size as whatever our normal ranges are (so whatever math we used to
		# set transparency will be what we use to set everything here, using something unique to
		# this function). If the selector-style range moving forwards or backwards by 
		# _label_quantity goes outside of what's literally not there due to lack of generation, then
		# we'll reference <null> and fall outside of intended behaviour.
		# I'm gonna take a wild guess and assume neither of us want that.
		#
		#   Also, the previous paragraph is outdated because I worked out a much more elegant
		# solution.
		#
		#   So.
		#
		#   I'll probably either improve design or leave notes *eventually*, but for now my
		# suggested handling is non-destructive, so good enough at this prototyping phase safe for
		# a design document or something.
		
		# If we moved upwards OOB, mask visuals like we're at the bottom of list
		if _move_direction == -1:
			
			# Resetting all label's desired opacity to 0 has been handled in this function prior.
			
			# Check to make sure we can actually use label info (check for any null reference)
			if !is_instance_valid(
				# Remember, child selection counting in GDS starts at int 0, while this math is @ 1.
				_VBoxContainer.get_child( # Starts counting from 0. Select area = runtime labels-1
					(_before_copies_amt * _label_quantity) # Starts at 1 - Stops at usr cursor start
					+ (_label_quantity - 1) # Stops at the end of where user's cursor can go.
					+ _opacity_base_list_fully_opaque_quantity # Base extra space needed for opaque
					+ _opacity_list_look_ahead_opaque # Extra space needed for MORE opaque
					+ _opacity_list_look_ahead_transparent # Extra space needed for transparent
					)
				):
				printerr("control-list-selection.gd:
				_process_pulse_update_visuals_labels_opacity():
				_should_mask_list_for_infinite_wrapping_effect:
				_move_direction == -1:
				!is_instance_valid:
					I was GOING to add a detailed 'heres how to fix this error' message,
					but I'm still making the prototype for this script!
					
					Basically, script is trying to set opacity information for labels in a range
					outside of the slots available to variable _after_copies_amt (you're trying to
					use labels that don't exist).
					
					Give this variable a bigger numebr or take the time to study how your starting
					variables affect script behaviour. Nothing should be bigger than 20 in a list
					with a handful of items."
					)
				get_tree().quit(1)
				
				pass
			
			# Delete these comments on commit.
			
			# Makes sure there's no leftover labels when setting current_opacity. Bad idea?
#			for o in _VBoxContainer.get_child_count(false):
#				_VBoxContainer.get_child(o).current_opacity = (000.0/255.0)
#				pass
			
			# I was wrong about selection method, I need to get the entire list adjusted for this.
			
			# I'm not focused enough right now to add checks, MAKE SURE you have enough space here.
#			for n in (
#				_VBoxContainer.get_child_count(false)
#				):
#				pass
			
			# Steal desired and current opacity on everything in range.
			for n in _VBoxContainer.get_child_count(false) - _label_quantity:
				
				# Setting desired opacity has intended behaviour.
				_VBoxContainer.get_child( # Honestly, I should've seen this solution by now.
					n
					+ _label_quantity - 1
					).desired_opacity = (
						_disposable_opacity_information_desired[
						n
						]
					)
				
				# Setting current opacity is mostly working as intended.
				_VBoxContainer.get_child(
					n
					+ _label_quantity
					).current_opacity = (
						_disposable_opacity_information_current[
						n
						]
					)
				pass
			pass
		
		# If we moved downwards OOB, mask visuals like we're at the top of list
		elif _move_direction == +1:
			# Steal desired and current opacity on everything in range.
			for n in _VBoxContainer.get_child_count(false) - _label_quantity - 1:
				
				# This code feels slightly less cleanly-applied in practice, but I can't even read
				# the old code I did for moving up and OOB. I should seriously stop working so
				# late into the night, above code just looks insane in comparison.
				
				# Nevermind, I made a couple light touches to this new idea.
				
				# This new code is... very obvious, and very accurate. Perfectly accurate. 
				# Seriously, what the hell was I doing last session? How did this require three
				# tries to get right, was I that tired? This should've been incredibly easy...
				
				# Anyways, you don't get to inspect the insane garbage that was in here a sec ago
				# due to me being too busy and forgetting to commit my mistakes to git for the last
				# few days. If you read **THIS** code, you should know exactly how it works.
				
				# Setting desired opacity works as intended.
				_VBoxContainer.get_child(
					n
					).desired_opacity = (
					_disposable_opacity_information_desired[
						+ n
						+ _label_quantity - 1
						]
					)
				
				# Setting current opacity works as intended. I think.
				_VBoxContainer.get_child(
					n
					).current_opacity = (
					_disposable_opacity_information_current[
						+ n
						+ _label_quantity
						]
					)
				pass
			pass
		
		else:
			print()
			print()
			printerr("Catch case:")
			print()
			printerr("				_process_pulse_update_visuals_labels_opacity()
				_should_mask_list_for_infinite_wrapping_effect == true:
				!(_move_direction == -1) && !(_move_direction == +1):
					With the way this script is designed, you should either be moving up one
					or down one exclusively. You just tried to move more than that while going 
					out-of-bounds, which is currently meant to handle the visual wrapping effect
					that makes this list look like it loops infinitely by having funcs set UX and
					visuals at the very top/bottem while making it look like we came from 
					out-of-bounds (which for the user should look like it's an extension of the same
					list - infinitely). Anyways, go fix that before continuing. lol")
			print()
			printerr()
		
		pass
	
	pass
