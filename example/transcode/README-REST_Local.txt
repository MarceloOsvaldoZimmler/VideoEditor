

REST-Local Example Read Me
-------------------------

Please see the README.txt file in the same directory as this file for prerequisite information and
installation steps. Addtional explanation is also available in the online documentation:

http://www.moviemasher.com/docs/install/architectures/
http://www.moviemasher.com/docs/install/mmserver/

To install for REST HTTP deployments:

* Launch an instance of the Movie Masher Transcoder AMI using a keypair
* Make sure its Security Group allows access on port 443
* Transfer the private key portion of the keypair to private/
* Make the following adjustments to options within the private/moviemasher.ini file:
	Set Client and File to REST and Local
	Set RESTEndPoint to the Transcoder instance Public DNS Name (prepend with 'https://')
	Set KeypairPrivate to the full path of the private key file
* Configure PHP5 upload related options - see http://php.net/file_upload
* Install the following PEAR module, if not already installed:
	Archive_Tar
If this is impractical, the following script can be rewritten to utilize another library:
	media/php/include/archiveutils.php

