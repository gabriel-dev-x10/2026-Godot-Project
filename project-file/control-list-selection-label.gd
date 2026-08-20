extends RichTextLabel

## What's new?
# Cleaned a ton of code in this script and in control-list-selection.gd and improved readability for
# script and of variables at the top of this script.

## --- DEBUGGING FLAGS ---
# Flags to toggle to make debugging easier.
var _flag_developer_printing : bool = false
var _flag_use_slow_easing : bool = true
# --- END OF DEBUGGING STUFF ---

## --- UX STUFF ---
# Set this in editor. Path to load using UX logic.
@export var target_load_path : String = "RELOAD"
# --- END OF UX STUFF ---

## --- OPACITY STUFF ---
# I only use easing for opacity changes, so we can just constantly call "make this white"
var current_color : Color = Color(
	255.0/255.0, # current_color.r, NOT ~.x
	255.0/255.0, # current_color.g, NOT ~.y
	255.0/255.0, # current_color.b, NOT ~.z
	255.0/255.0 # We don't really use this anywhere, but current_color.a
)
# Current is current, desired is where label wants to be. 255 is opaque and 0 is transparent.
var current_opacity : float # Should be overwritten by control script.
var desired_opacity : float # Should be overwritten by control script.
# Never change this during runtime. Reference point for half-transparency for use by desired_opacity
const mid_opacity : float = (164.0/255.0) # yeahhhhh. I trust this.
# Never change these during runtime. Lerp equation: opacity +/-= abs(difference) * ((1-amt)**exp)
const _opacity_ease_amt : float = 0.25 # These gets the diff between the desired label opacity
const _opacity_ease_exp : float = 2.5 # and the current opacity, by being in an easing function.
# --- END OF OPACITY STUFF ---



# Delete on polish.
func _set_current_opacity(_x : float):
	current_opacity = (_x/255.0)
	pass

# Delete on polish.
func _set_desired_opacity(_x : float):
	desired_opacity = (_x/255.0)
	pass

func _ready() -> void:
	# If you're wondering why there's no initial 'starting point' for labels opacity:
	# (control-list-selection.gd)_ready()__ready_set_opacity_on_all_labels_to_zero()
	
	# Frankly, I'm not sure we even need a _ready in here. Anything relevant is a potential
	# race condition (as far as I know, I didn't check docs for this, and I don't care to for this
	# since my code needs to be sightreadable enough for NOONE reading this to guess or not be able
	# to compartmentalize where something might be in-code).
	pass

# System function.
func _process(_delta: float) -> void:
	if _flag_developer_printing:
		print("Current ", current_opacity, " Desired ", desired_opacity)
		pass
	
	# Handles updating what the opacity should be.
	_ease_opacity_change(_opacity_ease_amt, _opacity_ease_exp, _delta)
	
	# Handles opacity change setteng
	set("theme_override_colors/default_color",
		Color(
			current_color.r,
			current_color.g,
			current_color.b,
			current_opacity
			)
		)
	pass

# Done.
func _ease_opacity_change(
	_ease_amt : float,
	_ease_exp : float,
	_delta : float
	) -> void:
	
	if !(desired_opacity == current_opacity):
		
		# If label is trying be more opaque...
		if (desired_opacity > current_opacity):
			
			if _flag_developer_printing: print("I want to raise opacity!")
			# I realllly wanted to try using a ternary operator here, but no assignments allowed.
			if !_flag_use_slow_easing:
				current_opacity += (
				abs(current_opacity - desired_opacity)
				* ((1 - _ease_amt) ** _ease_exp)
				)
			else:
				current_opacity += 0.01
			pass
		
		# If label wants to be more transparent...
		if (desired_opacity < current_opacity):
			
			if _flag_developer_printing: print("I want to lower opacity!")
			if !_flag_use_slow_easing:
				current_opacity -= (
					abs(current_opacity - desired_opacity)
					* ((1 - _ease_amt) ** _ease_exp)
					)
			else:
				current_opacity -= 0.01
			
			pass
		
		# If we're close enough to desired opacity, let current opacity catch up for resources.
		if abs(desired_opacity - current_opacity) <= 0.01:
			current_opacity = desired_opacity
		pass
