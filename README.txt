
Movie Masher Installation
-------------------------

Please note that all of these example deployments come preinstalled on the Movie Masher Server AMI within
Amazon's EC2 infrastructure. See README-AMI-Server.txt for information on how to launch up your own
instance and customize it for your project. 

The examples vary in complexity and server requirements... By far the simplest is 'static' since it
uses no CGIs or APIs. The 'actionscript' and 'javascript' examples add the ability to control the
editing interface externally through these languages. The 'flickr' example demonstrates 
connecting to an external APIs for content. 

By relying on CGI scripts the 'browse', 'save' and 'upload' examples add various hooks that can be
extended to interface with existing content management systems. And finally the 'transcode' example
puts these functions together to demonstrate a simple content flow, incorporating preprocessing of
uploaded media and downloading of rendered mash in true video format.

moviemasher:
	example:
		actionscript: loads the Movie Masher applet through another SWF
		browse: searches through media XML files dynamically
		flickr: search and display content from Flickr
		javascript: loads and controls the Movie Masher applet through JavaScript
		media: demo assets and JavaScript shared by several examples
		save: writes mash data to file system
		transcode: uses remote transcoder api to render mashes
		share: demo of mash playback within Facebook wall
		static: simplest example requires no CGI
		upload: transfers file to server
	LICENSE.html: describes licensing for utilized software
	moviemasher: Applet SWF files
	README-AMI-Server.txt: describes the Movie Masher Server AMI in EC2 
	README-Issues.txt: known problems with particular versions
	README-Migration.txt: notes for those upgrading between versions
	README-Release.txt: features and fixes for particular versions
	README.txt: this file
	source: FLAs, fonts, scripts and other source material
	
To install the simpler examples that don't use CGI (actionscript, flickr, javascript, 
static), please do the following:

* Copy the /example and /moviemasher directories to a publicly accessible directory on a web server
* Load the example's index page in a browser through the web server (examples do not run locally!)

To install all other examples, please also do the following:

* Install PHP5 if it's not already
* Follow further directions at the end of each example's README.txt file

Further documentation of the whole system is available on the moviemasher.com site.

