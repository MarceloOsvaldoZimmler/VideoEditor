
Browse Example Read Me
----------------------

This example deployment is essentially the same as the 'static' example, except the browser control
is populated dynamically from a CGI script instead of having the media_*.xml files all loaded
initially. Note the differences in the source.xml and control_nav_*.xml files, as well as the
addition of the media.php CGI script and the lack of a source_module.xml file. 

Extend this example by editing media.php to search through a database, or proxy requests between the
applet and a private external API (one that doesn't have a crossdomain.xml file). See the 'flickr'
example for a custom source module that accesses a public API directly from the applet without CGI
interaction.

browse:
	index.html: uses swfobject to pull in Movie Masher applet
	media:
		php:
			media.php: searches through media_*.xml files for media tags
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
			source.xml: contains source tag pointing to media.php
	README.txt: this file
	VERSION.txt: specifies the version of Movie Masher this example was bundled with

This example deployment requires the following installation steps beyond those that are outlined in the
INSTALL.txt file:

* Copy the /private directory to a directory OUTSIDE your web server root
* Place this directory path into PHP's include_path configuration option somehow


