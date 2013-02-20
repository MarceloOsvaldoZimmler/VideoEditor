
Save Example Read Me
--------------------

This example deployment is essentially the same as the 'static' example, except the timeline button
bar also contains an instance of the CGI control which facilitates posting of the file to the
save.php server side script. Note the differences in the control_save.xml file.

Extend this example by changing save.php to use the mash ID as the file name, so that multiple
mashes can be saved. Or turn index.html into a PHP file to add authentication, so that save.php can
save a unique mash for each user. The config.xml would probably also be converted to PHP so that the
correct mash file can be specified when the page is reloaded.

save:
	index.html: uses swfobject to pull in Movie Masher applet
	media:
		php:
			save.php: receives posted mash XML which is written as is to mash.xml
		xml:
			config.xml: loads the rest of the XML files
			control_nav_module.xml: contains control tags for modular media tabs
			control_nav.xml: contains control tags for media tabs and embeds control_nav_module.php
			control_save.xml: contains the control tag for the CGI module
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

This example deployment requires the installation steps outlined in the INSTALL.txt file, plus the
following:

* Change the file permissions for the following paths such that the web server process can write:
	media/xml/mash.xml
