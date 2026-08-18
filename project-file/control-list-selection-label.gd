extends RichTextLabel

# SOLVED: Problems with setting desired_opacity was due to me multiplying by 0.
# I forgot that I hadn't decided how I was going to use easing while designing this, and 
# lost about 3 hours 30 minutes without decent stack tracing skills because of this one
# component not behaving as expected. 
#
# So, yeah, my bad. Back to work.

var _flag_developer_printing : bool = false

@export var target_load_path : String = "RELOAD"
@export var default_opacity : float = (164.0/255.0) # Should be overwritten by control script.
var mid_opacity : float = (164.0/255.0) # yeahhhhh. I trust this.
var current_opacity : float # Should be overwritten by control script.
var desired_opacity : float # Should be overwritten by control script.
# I don't really use an easing function for this, so we can just constantly call "make this white"
var current_color : Color = Color( # THANK YOU Godot function use hints, huge timesave
	255.0/255.0, # current_color.r, NOT ~.x
	255.0/255.0, # current_color.g, NOT ~.y
	255.0/255.0, # current_color.b, NOT ~.z
	255.0/255.0 # We don't really use this anywhere, but current_color.a
)
var can_i_read_this_variable : String = "Yes you can!"

# Don't change this via script or editor These should be consistent on every Label
const _opacity_ease_amt : float = 0.001 # I forgot how to name ease in/out and types.
const _opacity_ease_exp : float = 1.0 # I should note those on polish.

var _flip_this_bit : bool = false



# Delete on commit.
func _call_func_test() -> void:
	printerr("Called function, setting now")
	print("pre-set value: ", _flip_this_bit)
	_flip_this_bit = true
	print("post-set value: ", _flip_this_bit)
	pass

# Delete on polish.
func _set_current_opacity(_x : float):
	current_opacity = (_x/255.0)
	pass

# Delete on polish.
func _set_desired_opacity(_x : float):
	desired_opacity = (_x/255.0)
	#printerr("Recieved ", _x)
	#print("Desired ", desired_opacity)
	#print(self.name)
	#current_opacity = (_x/255.0)
	pass

func _ready() -> void:
	# dammit is this a race condition with the main controller wanting to set this.
	#current_opacity = default_opacity
	
	# ookay, how about... what's the starting point here-- it's all happening in _ready() SOMEWHERE,
	# right? It's most likely that the earliest (topmost) thing in the tree will load first.
	# Actually, nevermind, I can't tell at a glance what'll be called first, and what'll potentially
	# get overwritten when handled in _ready() across different scripts, so instead of trial-and-
	# erroring allat I'm gonna do everything in 
	# "control-list-selection.gd"_ready_set_opacity_on_all_labels_to_zero()'s first macro/section.
	#
	# ...
	#
	# Which comes after just setting opacity in here, first.
	# Juuuust a second, I'm using _process() for this.
	
	# These two were used during testing that I *CAN* make opacity work, and should not be set in
	# this script's _ready() due to a potential race condition with 
	# _ready_set_opacity_on_all_labels_to_zero(); use that to set initial opacity info across
	# all labels, then set this script's midtone everywhere it's wanted in there (+opaque tone),
	# THEN set opaque tone everywhere it's wanted in there. I'm gonna need to prepare something more
	# elegant that maintains how rebust this is afterwards, though, because this is too blunt.
	#current_opacity = default_opacity # TLDR; Don't set these vars here, use list controller script
	#desired_opacity = default_opacity # TLDR; Don't set these vars here, use list controller script
	#print("Current ", current_opacity, " Desired ", desired_opacity)
	pass

func _process(_delta: float) -> void:
	#print("Current ", current_opacity, " Desired ", desired_opacity)
	# SIGHTREAD!! Now I just need to know how to respect corrent colors before coding with this.
	# Actually, I don't plan on easing these values and I know I just want white. Do I even need to?
	# I could just make 'current_colors := Color(text vomit)' and regulate with that later if needed
	# Meanwhile, opacity stuttering a bit at startup might honestly add charm, compared to a seizure
	# vibe with label text color stuttering, so I think I can shortcut this work in the label's
	# _ready() area.
	
	_ease_opacity_change(_opacity_ease_amt, _opacity_ease_exp, _delta)
	# Was last section's failures stunlocking because of this setting going before updates.
	# Okay, it isn't. These labels WANT to change value, but aren't for some reason.
	# I guess this is a closer point to diagnose with, but I'm not looking forwards to it at this
	# point.
	set("theme_override_colors/default_color",
		Color(
			current_color.r,
			current_color.g,
			current_color.b,
			current_opacity
			)
		)
	pass

func _ease_opacity_change(
	_ease_amt : float,
	_ease_exp : float,
	_delta : float
	) -> void:
	
	if !(desired_opacity == current_opacity):
		if (desired_opacity > current_opacity):
			#print("I want to raise opacity!")
			current_opacity += 0.01
			#current_opacity += (
			#	abs(current_opacity - desired_opacity)
			#	* ((1 - _ease_amt) ** _ease_exp)
			#	)
			pass
		if (desired_opacity < current_opacity):
			current_opacity -= 0.01
			#print("I want to lower opacity!")
			#current_opacity -= 0.01
#			current_opacity -= (
#				abs(current_opacity - desired_opacity)
#				* ((1 - _ease_amt) ** _ease_exp)
#				)
			pass
		if abs(desired_opacity - current_opacity) <= 0.01:
			desired_opacity = current_opacity
		pass
#	# If desired opacity doesn't match what we have, ease current according to...
#	if !(desired_opacity == current_opacity):
#		# ...if we want to increase opacity:
#		print(self.name, " Current: ", current_opacity, " Desired: ", desired_opacity)
#		if (desired_opacity > current_opacity):
#			print("Want to get brighter!")
#			# Easing math; Get difference between where we are, and add result of some easing
#			# point in-between that distance.
#			current_opacity += (
#				(desired_opacity - current_opacity)
#				# In GDScript (arithmetic operators): * multiplies, ** is an exponent.
#				# In case you don't know what that means, exponents are 'higher degrees' of
#				# multiplication, followed by tetration (which is already probably too difficult to
#				# type, and the 'inverse'/division-equivalent is logarithmic operations, like log()
#				#
#				# Example:
#				# (** => 'Multiplies base number that many times'; i.e. 4 ** 3 => 4 * 4 * 4 => 64)
#				* ((1 - _ease_amt) ** _ease_exp)
#				)
#			pass
#		# ...if we want to decrease opacity:
#		else:
#			# Okay, opacity easing is getting jammed here. What's going on?
#			printerr("Want to get darker!")
#			current_opacity -= (
#				(current_opacity - desired_opacity)
#				* ((1 - _ease_amt) ** _ease_exp)
#			)
#		pass
	pass
