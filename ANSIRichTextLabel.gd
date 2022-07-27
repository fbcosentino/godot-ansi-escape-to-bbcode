# Author: fbcosentino - https://github.com/fbcosentino/godot-ansi-escape-to-bbcode
# License: MIT

extends RichTextLabel

const ESCAPE_CSI = char(27) +"["
var data_buffer = "" # Used to identify escape sequences

var is_bold = false
var is_italic = false
var current_color = ""

const color_values = [
	"#555555", # real black would not be readable
	"#ff7733", # orangish pale red
	"#00ff00", # green
	"#ffff00", # yellow
	"#6666ff", # paler blue
	"#ffff00", # magenta
	"#00ffff", # cyan
	"#ffffff", # white
]

func add_data(text_line: String):
	var text = data_buffer + text_line
	data_buffer = ""
	
	var s = "" # s goes to screen regardless of escape codes
	#            e.g. in "Hello \x1b[31mworld!\x1b0m!"
	#            the part "Hello " goes to screen even if the escape
	#            sequence is not yet fully received
	
	while ESCAPE_CSI in text:
		var parts = text.split(ESCAPE_CSI, true, 1)
		s += parts[0]
		text = parts[1]
		
		if "m" in text:
			parts = text.split("m", true, 1)
			text = parts[1]
			
			s += process_escape_code(parts[0])
		
		else:
			# Escape not fully received yet
			data_buffer = ESCAPE_CSI + text
			text = ""
			break
	
	if text.length() > 0:
		s += text
	
	bbcode_text += s


func process_escape_code(code_text: String) -> String:
	var code_items = code_text.split(";")
	
	var request_bold = null
	var request_italic = null
	var request_color = null
	
	for code in code_items:
		match code:
			"0": # Reset all
				request_bold = false
				request_italic = false
				request_color = ""
			
			"1":
				request_bold = true
			"22":
				request_bold = false
			
			"3":
				request_italic = true
			"23":
				request_italic = false
			
			"39":
				request_color = ""
			
			_:
				var code_int = int(code)
				if (code_int >= 30) and (code_int <= 37):
					var color_index = code_int - 30
					request_color = color_values[color_index]
	
	# Invalidate requests which don't change anything
	if (request_italic != null) and (request_italic == is_italic):
		request_italic = null
	if (request_bold != null) and (request_bold == is_bold):
		request_bold = null
	if (request_color != null) and (request_color == current_color):
		request_color = null
	
	# entanglement ("[i]  [b]   [/i]   [/b]") is not supported
	# "[i]  [/i][b][i]   [/i]   [/b]" must be done instead
	# italics are inside bold, which are inside color
	
	var s = ""
	
	var has_to_close_italic = is_italic and ((request_italic == false) or (request_bold != null) or (request_color != null))
	var has_to_close_bold = is_bold and ((request_bold == false) or (request_color != null))
	var has_to_open_bold = (is_bold and (request_bold == null)) or (request_bold == true)
	var has_to_open_italic = (is_italic and (request_italic == null)) or (request_italic == true)
	
	if has_to_close_italic:
		s += "[/i]"
		is_italic = false
	
	if has_to_close_bold:
		s += "[/b]"
		is_bold = false
	
	if (current_color != ""):
		if (request_color != null):
			s += "[/color]"
			current_color = ""
	
	if (request_color != null):
		if request_color != "":
			s += "[color=%s]" % request_color
		current_color = request_color
	
	if has_to_open_bold: 
		s += "[b]"
		is_bold = true
	
	if has_to_open_italic: 
		s += "[i]"
		is_italic = true
	
	
	return s


func reset_formats() -> String:
	var s = ""
	
	if is_italic:
		s += "[/i]"
		is_italic = false
	if is_bold:
		s += "[/b]"
		is_bold = false
	if current_color != "":
		s += "[/color]"
		current_color = ""
	
	return s

func set_color(color_name: String = "") -> String:
	# Both bold and italic are inside colors and boundaries should be regenerated
	
	var s = ""
	
	if color_name == current_color:
		return ""
	
	if is_italic:
		s += "[/i]"
	if is_bold:
		s += "[/b]"
	if (current_color != ""):
		s += "[/color]"
	
	current_color = color_name
	if current_color != "":
		s += "[color=%s]" % current_color
	if is_bold:
		s += "[b]"
	if is_italic:
		s += "[i]"
	
	return s


func set_bold(should_be_bold: bool = false) -> String:
	# Italics are inside bold and boundaries must be regenerated
	
	var s = ""
	
	if is_bold == should_be_bold:
		return ""
	
	if is_italic:
		s += "[/i]"
	
	is_bold = should_be_bold
	if (is_bold):
		s += "[b]"
	else:
		s += "[/b]"
	
	if is_italic:
		s += "[i]"
	
	
	return s

func set_italic(should_be_italic: bool = false) -> String:
	var s = ""
	
	if is_italic == should_be_italic:
		return ""
	
	is_italic = should_be_italic
	
	if is_italic:
		s += "[i]"
	else:
		s += "[/i]"
	
	return s

