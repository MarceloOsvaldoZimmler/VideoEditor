
SQS-S3 Example Read Me
----------------------

Please see the README.txt file in the same directory as this file for prerequisite
information and installation steps. Addtional explanation is also available in the online
documentation:

http://www.moviemasher.com/docs/install/architectures/
http://www.moviemasher.com/docs/install/mmserver/

To install for SQS S3 deployments:

* Make sure your Amazon account is signed up for S3 and SQS
* Create the SQS queue URL (referenced below as MY_QUEUE_URL)
* Create the S3 bucket (referenced below as MY_BUCKET_NAME)
* Place a crossdomain.xml file in the bucket and make its permissions 'public read'
* Make the following adjustments to options within the private/moviemasher.ini file:
	Set Client and File to SQS and S3
	Set S3Bucket to MY_BUCKET_NAME
	Set HostMedia to MY_BUCKET_NAME.s3.amazonaws.com
	Set AWSAccessKeyID and AWSSecretAccessKey from your Amazon Security Credentials
	Set SQSQueueURLSend to MY_QUEUE_URL
* Transcoder does not need to be launched with a key pair and the security group can be as
  restricted as you'd like since there are only outbound connections. It does need to be 
  launched with user data though, including the following (see README-AMI-Transcoder.txt):
	AWS Access Key ID
	AWS Secret Access Key
	SQS Queue URL (MY_QUEUE_URL)
