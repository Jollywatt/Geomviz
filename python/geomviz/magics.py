from IPython.core.magic import (
	Magics,
	magics_class,
	line_magic,
	cell_magic,
	needs_local_scope,
)

from .encode import encode_and_send

@magics_class
class BlenderSender(Magics):

	@line_magic
	@needs_local_scope
	def blend(self, line, local_ns=None):
		value = eval(line, None, local_ns)
		encode_and_send(value)
		return line
