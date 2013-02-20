
Flickr Example Read Me
----------------------

This example deployment is essentially the same as the 'static' example, except the browser control
contains a Flickr tab instead of tabs for video, audio and images. Note the difference in the
control_nav.xml and source.xml files. The later references a custom source module called
FlickrSource which makes requests directly to the Flickr API.

Extend this example by changing or adding attributes of the source tag in source.xml, using their
parameter naming conventions in most cases. One might also subclass FlickrSource or its parent to
develop a custom module that accesses another public API. 

flickr:
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
			media_effect.xml: contains media tags of type effect
			media_theme.xml: contains media tags of type theme
			media_transition.xml: contains media tags of type transition
			option_font.xml: contains option tags specifying fonts
			panel.xml: contains panels tags defining interface layout
			source_module.xml: contains source tags for modular media
			source.xml: contains source tag for FlickrSource class
	README.txt: this file
	VERSION.txt: specifies the version of Movie Masher this example was bundled with

This example deployment requires no installation steps beyond those that are outlined in the
INSTALL.txt file. 
	
