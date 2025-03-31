
def error_popup(context, title, message):
	draw_menu = lambda self, context: self.layout.label(text=message)
	context.window_manager.popup_menu(draw_menu, title="No geomviz collection", icon="ERROR")

class InvalidDataException(Exception):
	"""
	Exception raised when the a `DataServer` receives data which cannot be decoded or is an invalid format.
	"""
	pass

class UnknownRigError(Exception):
	def __init__(self, name):
		self.name = name

class RigDataError(Exception):
	def __init__(self, message):
		self.message = message

class PoseError(Exception):
	def __init__(self, name, key):
		self.name = name
		self.key = key

