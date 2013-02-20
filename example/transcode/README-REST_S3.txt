
REST-S3 Example Read Me
-----------------------

Please see the README.txt file in the same directory as this file for prerequisite information and
installation steps. Addtional explanation is also available in the online documentation:

http://www.moviemasher.com/docs/install/architectures/
http://www.moviemasher.com/docs/install/mmserver/

To install for REST S3 deployments:

* Make sure your Amazon account is signed up for S3
* Create the S3 bucket (referenced below as MY_BUCKET_NAME)
* Place a crossdomain.xml file in the bucket and make its permissions 'public read'
* Transfer the private key portion of the keypair to private/
* Make the following adjustments to options within the private/moviemasher.ini file:
	Set Client and File to REST and S3
	Set RESTEndPoint to the Transcoder instance Public DNS Name 
	Set S3Bucket to MY_BUCKET_NAME
	Set HostMedia to MY_BUCKET_NAME.s3.amazonaws.com
* Launch an instance of the Movie Masher Transcoder AMI using a keypair and user data 
  including the following (see README-AMI-Transcoder.txt):
	AWS Access Key ID
	AWS Secret Access Key
* Make sure its Security Group allows access on port 443
