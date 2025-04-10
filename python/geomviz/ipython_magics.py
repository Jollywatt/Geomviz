from IPython.core.magic import (Magics, magics_class, line_magic, cell_magic)

@magics_class
class BlenderSender(Magics):

	@line_magic
	def blend(self, line):
		eval
		return line

	@cell_magic
	def cadabra(self, line, cell):
		return line, cell