#!/usr/bin/env nu

def build [] {
	cd $env.FILE_PWD
	^zip -r geomviz.blender-add-on.zip geomviz -x "*.DS_Store" -x "**/__pycache__/*"
}

def main [] {
	build
}