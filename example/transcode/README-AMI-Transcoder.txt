Transcoder AMI Read Me 
----------------------

The Movie Masher Transcoder AMI (Amazon Machine Image) is a prepackaged server you launch
up within Amazon's EC2 (Elastic Compute Cloud) infrastructure:

http://aws.amazon.com/ec2/

Once launched, instances of the AMI provide a powerful and flexible API (Application
Programming Interface) your web applications use to transcode and combine video, audio or
images with effects, titling and transitions. API requests are either directly POSTed to a
single instance through its REST (REpresentational State Transfer) interface or to
Amazon's SQS (Simple Queue Service), which doles them out to a pool of instances for
better performance. The resultant file(s) are securely transferred to Amazon's S3 (Simple
Storage Service) or most any HTTP compliant server or service.

http://aws.amazon.com/sqs/ 
http://aws.amazon.com/s3/

Launching Instances of the AMI 
------------------------------

You must have an Amazon account and be signed up for EC2 in order to launch instances of
the Movie Masher Transcoder AMI. It is a publicly available LINUX based AMI - search for
'moviemasher' within the EC2 Management Console and choose the latest version. It is also
a paid AMI so your account must be subscribed to it before launching. Subscriptions are 
activated and deactivated via the following URLs:

https://aws-portal.amazon.com/gp/aws/user/subscription/index.html?offeringCode=E83E989D
http://www.amazon.com/dp-applications

Depending on which Amazon services you want to use and how you choose to authenticate API
requests, two distinct approaches to launching the AMI can be used or combined: launching
with a Key Pair or User Data. If S3 and SQS are not being utilized, the AMI can simply be
launched with a Key Pair - the private key portion of it is used to authenticate API
requests. Otherwise the AMI is launched with User Data containing an AWS Access Key ID and
Secret Access Key, which are used to both gain access to S3 or SQS and authenticate
requests.

If instances are being accessed through REST then port 443 needs to be open in the
Security Group (firewall) they were launched within. Alternatively, port 80 can be opened
if HTTP is being used instead of HTTPS, though this is not recommended. When using SQS
there is no inbound traffic to instances so all the ports in the Security Group can (and
should) be closed. 

User Data XML Syntax 
--------------------

<MovieMasher>
	<AWSAccessKeyID>YOUR_ACCESS_KEY_ID</AWSAccessKeyID>
	<AWSSecretAccessKey>YOUR_SECRET_ACCESS_KEY</AWSSecretAccessKey> 
	<SQSQueueURLReceive>https://queue.amazonaws.com/123456/identifier</SQSQueueURLReceive>
</MovieMasher>

If either S3 or SQS are being used then both the AWSSecretAccessKey and AWSAccessKeyID
must be defined, and their associated identity must have permission to access the SQS
Queue or S3 buckets that are not public. SQSQueueURLReceive must be defined if SQS is
being used. 

Source Files
------------

Build files for all open source software installed on the Transcoder AMI are available via 
HTTP from each running instance, in the /installed directory. If a project directory does
not have a corresponding archive file this indicates the project came directly from a 
versioning system (typically git). For convenience, the output of 'ffmpeg -codecs' and 'ffmpeg -formats' has been saved in the ffmpeg installation directory:

http://[PUBLIC_DNS_NAME/installed/ffmpeg/codecs.txt
http://[PUBLIC_DNS_NAME/installed/ffmpeg/formats.txt
