
ActionScript Example Read Me
----------------------------

This example deployment is essentially the same as the 'static' example, except the Movie Masher
applet is pulled in by another SWF instead of directly from the index file. Note the addition of the
container.swf file and associated source FLA file containing the AS3 code.

Extend this example by editing the ActionScript code in the container.fla file, or replacing it with
your own Adobe Flashˇ project. See the 'javascript' example for some of the possibilities offered by
Movie Masher's evaluate API, which is also available through ActionScript.

actionscript:
	index.html: uses swfobject to pull in container.swf
	media:
		swf:
			container.fla: source file contains ActionScript
			container.swf: pulls in MovieMasher and controls it
		xml:
			config.xml: loads the rest of the XML files
			control_nav_module.xml: contains control tags for modular media tabs
			control_nav.xml: contains control tags for media tabs and embeds control_nav_module.php
			control_save.xml: contains the control tag for the Movie Masher logo
			control_search.xml: contains the control tags for the browser search field
			handler.xml: contains handler tags for media types
			mash.xml: contains mash tag with default aspect ratio and label
			media_audio.xml: contains media tags of type audio
			media_effect.xml: contains media tags of type effect
			media_image.xml: contains media tags of type image
			media_theme.xml: contains media tags of type theme
			media_transition.xml: contains media tags of type transition
			media_video.xml: contains media tags of type video
			option_font.xml: contains option tags specifying fonts
			panel.xml: contains panels tags defining interface layout
			source_module.xml: contains source tags for modular media
			source.xml: contains source tags for asset media
	README.txt: this file
	VERSION.txt: specifies the version of Movie Masher this example was bundled with
	
This example deployment requires no installation steps beyond those that are outlined in the
INSTALL.txt file, and does NOT require PHP.
