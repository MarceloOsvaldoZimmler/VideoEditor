
Transcode Example Read Me - please read ALL of me!
-------------------------

This example deployment is qualitatively different from the others in that it preprocesses
uploaded assets and renders the edited mash back into a true video file available for
download. It builds extensively on the 'save' and 'upload' examples, adding an
authentication mechanism and maintaining different content for each user. Any username and
password combination is accepted in this example.

A 'Mash' tab has been added above the media browser to display previously created mashes,
and buttons have been added to enable loading of a selected mash and downloading of
uploaded assets or rendered videos. The timeline has new buttons for reverting, rendering
and creating a new mash. Progress bars are now attached to the upload and render buttons,
to track their transcoding operations. Note the more complex implementation of
control_search.xml and control_save.xml, as well as the many scripts added to the
media/php directory.

The PHP scripts in this example behave differently depending on the options set in the
private/moviemasher.ini configuration file. The two most crucial options are 'Client' and
'File' which determine which interface to use when connecting with Transcoder instances
and where to store transcoding results. The supported combinations of these two options
are described in the online documentation, along with the network architectures they
enable:

http://www.moviemasher.com/docs/install/mmserver/

Please also see additional installation notes in the README-[Client]_[File].txt file that
corresponds to the desired network architecture. Note that it's expected that at least one
instance of the Movie Masher Transcoder AMI be running in Amazon's Elastic Compute Cloud
(EC2) web service. Instructions for launching are outlined here:

http://www.moviemasher.com/server/

Extend this example by building a more complete content management system around it. Start
by rewritting the three functions in the media/php/include/authutils.php file, perhaps
utilizing sessions instead of HTTP authentication.

transcode:
	index.php: authenticates, and pulls in Movie Masher applet (via swfobject)
	media:
		php:
			config.php: returns XML from user's media_* files
			delete.php: removes tag from one of user's media_* files, if not referenced
			export_done.php: receives notice that render job completed successfully
			export_error.php: receives notice when render job encounters error
			export_init.php: initiates render job with Transcoder via REST or SQS
			export_monitor.php: returns render job progress data to applet
			export_progress.php: receives render job progress data when SQS used
			export_transfer.php: receives rendered file when S3 not used
			import_api.php: initiates upload job with Transcoder via REST or SQS
			import_done.php: receives notice that upload job completed successfully
			import_error.php: receives notice when upload job encounters error
			import_init.php: handles initial screening of uploads
			import_monitor.php: returns upload job progress data to applet
			import_progress.php: receives upload job progress data when SQS used
			import_transfer.php: receives preprocessed file when S3 not used
			import_upload.php: receives uploaded file when S3 not used
			include:
				archiveutils.php - provides tar gzip decompression (via PEAR's Archive_Tar)
				authutils.php - provides hooks for your authentication mechanism
				configutils.php - provides configuration parsing utility functions
				dateutils.php - provides common date format strings
				fileutils.php - provides file management utility functions
				floatutils.php - provides float handling utility functions
				httputils.php - provides HTTP utility functions (via curl)
				idutils.php - provides GUID generation (via com_create_guid, if found)
				logutils.php - provides simple logging mechanism
				mashutils.php - provides mash XML parsing utility functions
				mimeutils.php - provides MIME discovery (via PEAR's MIME_Type)
				sigutils.php - provides signature utility functions (via openssl)
				urlutils.php - provides URL transformation utility functions
				xmlutils.php - provides XML reading and writing utility functions
			media.php: searches through media*.xml files for media tags
			save.php: stores mash XML to user's directory and adds to their media_mash.xml
		
		user: empty at first, see README-Structure.txt
		xml:
			config.xml: loads the rest of the XML files
			control_nav_media_cgi.xml: contains control tags for other media tabs
			control_nav_module.xml: contains control tags for modular media tabs 
			control_nav.xml: contains control tags for media tabs
			control_save.xml: contains the control tag for the Movie Masher logo
			control_search.xml: contains the control tags for the browser search field
			mash.xml: contains mash tag with default aspect ratio and label
			media_effect.xml: contains media tags of type effect
			media_theme.xml: contains media tags of type theme
			media_transition.xml: contains media tags of type transition
			option_font.xml: contains option tags specifying fonts
			panel.xml: contains panels tags defining interface layout
			panel_record.xml: contains panel tags manifesting recorder controls (beta)
			panel_voiceover.xml: contains panel tags manifesting voiceover controls (beta)
			source.xml: contains source tag pointing to media.php
			style.xml: contains option tags defining many layout parameters
		README-AMI-Transcoder.txt: describes the Movie Masher Transcoder AMI in EC2
		README-API.txt: describes the XML syntax for transcoding jobs
		README-REST_Local.txt: describes using local storage with the REST interface
		README-REST_S3.txt: describes using S3 for storage with the REST interface
		README-SQS_S3.txt: describes using S3 for storage with the SQS interface
		README-Structure.txt: describes file organization of media assets
		README.txt: this file
	private: for security, should be moved to a directory OUTSIDE web server's root
		moviemasher.ini: configuration options for PHP scripts
		MovieMasherLog: directory for logs
	VERSION.txt: specifies the version of Movie Masher this example was bundled with

------------------
INSTALLATION STEPS
------------------

This example deployment requires the installation steps outlined in the main INSTALL.txt
file, plus the following:

* Move the private directory to a directory OUTSIDE your web server's document root
* Change the LOCATION OPTIONS in the private/moviemasher.ini file and review other options
* Place the new path to the private directory into PHP's include_path configuration option
- OR change the path reference to 'moviemasher.ini' within the config_get() function in:
	media/php/include/configutils.php
* Change the file permissions for these paths so the web server process can write to them:
	private/MovieMasherLog/
	media/user/
* Install the PHP curl module, for making HTTP requests
- OR rewrite all functions to use some other mechanism in:
	media/php/include/httputils.php
* Install the MIME_Type PEAR module
- OR manually add unusual extension/mime pairs to the mime_from_extension() function in:
  	media/php/include/mimeutils.php
* IF using your EC2 Key Pair to authenticate requests, install PHP's openssl module
- OR rewrite the sig_private_key() function to use some other library in:
	media/php/include/sigutils.php
* Get an Account at Amazon.com, and sign up for their EC2 service:
	http://aws.amazon.com/ec2/
* Use ElasticFox, command line or console to launch an instance of Movie Masher Transcoder:
	https://console.aws.amazon.com/
* You should launch the version of the Transcoder that is indicated in private/VERSION.txt
* IF using the private key portion of your keypair to sign Transcoder requests:
	Launch Transcoder with your keypair (there is no way to add it later)
	Copy private key to the private directory, and make readable by the web server
	Set the KeypairPrivate option in private/moviemasher.ini to the private key path
* OR if using your Amazon Security Credentials to sign requests instead:
	Set AWSAccessKeyID and AWSSecretAccessKey options in private/moviemasher.ini
	Launch Transcoder with Access Key ID and Secret Access Key (see README-AMI-Transcoder.txt)
* Follow steps in README-[Client]_[File].txt file that corresponds to desired architecture
* Check out README-AMI-Transcoder.txt for information about launching Transcoder AMI
* Check out README-Structure.txt for information about how the example organizes assets
* Check out README-API.txt for information regarding syntax of XML job requests
