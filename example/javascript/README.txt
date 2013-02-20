
JavaScript Example Read Me
--------------------------

This example deployment is essentially the same as the 'static' example, except the Movie Masher
applet shares the HTML page with various JavaScript links that control it. Note the changes in
index.html where the JavaScript is located, and mash.xml which contains initial timeline content.

Extend this example by editing the JavaScript code in index.html, or replacing it with your own
project. Movie Masher's evaluate API exposes most, but not all, of the documented control properties
to your code. 

actionscript:
	index.html: uses swfobject to pull in Movie Masher applet and JavaScript to control it
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
			mash.xml: contains mash tag with example clips to control
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
INSTALL.txt file.
