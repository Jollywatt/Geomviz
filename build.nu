#!/usr/bin/env nu

def status [name: string] {
	print -n (ansi green_bold) 'Building' (ansi w) $" ($name) " (ansi reset) "\n"
}

def "main clifford" [] {
	status "geomviz python package for clifford"
	mkdir dist
	python -m build ./clients/geomviz_clifford
	mv ./clients/geomviz_clifford/dist/geomviz*.whl dist
	rm -rf ./clients/geomviz_clifford/dist
	rm -rf ./clients/geomviz_clifford/*.egg-info
}

def "main blender" [] {
	status "Blender add-on"
	mkdir dist
	^zip -r dist/geomviz.blender-add-on.zip blender_addon -x "*.DS_Store" -x "**/__pycache__/*"
}

def main [] {
	rm -rf dist
	main clifford
	main blender
}
