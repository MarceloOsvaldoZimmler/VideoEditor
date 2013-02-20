
Static Example Read Me
----------------------

This example deployment is the base implementation that is used as a starting point for all the
other examples, since it is the most straightforward. All configuration is loaded when the applet
first launches, resulting in optimal performance when searching within the media browser.

Extend this example and the others by editing the various configuration files or developing your own
custom graphics for the various controls. Media assets (video, audio and images) can be specied in
the relevant media_*.xml files. Modules (effects, transition and themes) can be reconfigured and
recombined as well as dumbed down by editing the relevant media_*.xml files. Change the tabs above
the media browser by editing control_nav.xml and the source.xml file. Adjust the interface layout in
panel.xml and specify custom fonts in the option_font.xml file.

static:
	index.html: uses swfobject to pull in Movie Masher applet
	media:
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
