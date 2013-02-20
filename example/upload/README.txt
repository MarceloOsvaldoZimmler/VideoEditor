
Upload Example Read Me
----------------------

This example deployment is essentially the same as the 'browse' example, except the browser search
bar also contains two instances of the CGI control to handle upload and download of images. The
audio and video tabs have also been removed, since these media types require server processing to
determine duration. Note the differences in control_nav.xml and control_search.xml, plus the
addition of the upload.php CGI script and media.xml which replaces a few of the media_*.xml files.

Extend this example by editing upload.php to generate smaller icons for the uploaded images, instead
of using the actual file as an icon. Or add support for other media types, utilizing additional
libraries or programs to determine the duration of the file. Without transcoding Flash can natively
support FLV, F4V and H264 video files and MP3 audio. Bear in mind that optimal editor performance is
accomplished by supplying image sequences instead of true video files. See 'local_system' and
'rest_http' examples for more robust uploading capabilities.

upload:
	index.html: uses swfobject to pull in Movie Masher applet
	media:
		php:
			media.php: searches through media*.xml files for media tags
			upload.php: handles transfer of image and insertion of its meta data into media.xml
		upload: empty at first
		xml:
			config.xml: loads the rest of the XML files
			control_nav_module.xml: contains control tags for modular media tabs
			control_nav.xml: contains control tags for media tabs and embeds control_nav_module.php
			control_save.xml: contains the control tag for the Movie Masher logo
			control_search.xml: contains the control tags for the browser search field
			handler.xml: contains handler tags for media types
			mash.xml: contains mash tag with default aspect ratio and label
			media_effect.xml: contains media tags of type effect
			media.xml: contains media tags for uploaded images
			media_theme.xml: contains media tags of type theme
			media_transition.xml: contains media tags of type transition
			option_font.xml: contains option tags specifying fonts
			panel.xml: contains panels tags defining interface layout
			source.xml: contains source tag pointing to media.php
	README.txt: this file
	VERSION.txt: specifies the version of Movie Masher this example was bundled with

After uploading the upload directory would look something like this:

upload:
	media:
		upload: unique ID used as file base name
			3451e339666141f25a7cc85ffa29eac8.png
			89043831976e5ce4f5dfbfd4e291f287.jpg
			...

This example deployment requires the installation steps outlined in the INSTALL.txt file, plus the
following:

* Copy the /private directory to a directory OUTSIDE your web server root
* Place this directory path into PHP's include_path configuration option somehow

* Change the file permissions for the following paths such that the web server process can write:
	media/xml/media.xml
	media/user

* Configure PHP5 upload related options - see http://php.net/file_upload

