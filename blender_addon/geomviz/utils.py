
def error_popup(context, title, message=None):
	draw_menu = lambda self, context: self.layout.label(text=message)
	context.window_manager.popup_menu(draw_menu, title=title, icon="ERROR")

class GeomvizError(Exception):
	def __init__(self, message):
		self.message = message
		self.icon = 'ERROR'

class InvalidDataException(GeomvizError):
	"""
	Exception raised when the a `DataServer` receives data which cannot be decoded or is an invalid format.
	"""
	pass

class UnknownRigError(GeomvizError):
	def __init__(self, name):
		super().__init__(f"Unknown rig: {name!r}")
		self.name = name

class RigDataError(GeomvizError):
	def __init__(self, message, detail=None):
		if detail is not None:
			message += f"\n({detail})"
		super().__init__(message)

class PoseError(GeomvizError):
	def __init__(self, name, key, keys=None):
		message = f"Rig {name!r} has no parameter {key!r}"
		if keys is not None:
			message += f", expected one of {keys!r}"
		super().__init__(message)
		self.name = name
		self.key = key
