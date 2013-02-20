Server AMI Read Me 
------------------

The Movie Masher Server AMI (Amazon Machine Image) is a prepackaged server you launch up
within Amazon's EC2 (Elastic Compute Cloud) infrastructure:

http://aws.amazon.com/ec2/

Once launched, instances of the AMI provide a standard LAMP (LINUX, Apache, MySQL, PHP)
web server with the Movie Masher SDK preinstalled and configured. Simply access the Public
DNS Name of the instance in a web browser to begin editing video online. Instances of the
AMI can also be accessed via SSH or FTP, so it can be easily built upon and rebundled into
your own custom AMIs.

Launching Instances of the AMI 
------------------------------

You must have an Amazon account and be signed up for EC2 in order to launch instances of
the Movie Masher Server AMI. It is a publicly available LINUX based AMI - search for
'moviemasher' within the EC2 Management Console and choose the most recent version. Port
80 must be open in the Security Group that instances are launched within for HTTP access.
For SSH and FTP access open port 21 and 22, as well as the 12000-12100 range if using PASV
mode.

If launched without User Data, instances will display the 'share' example deployment when
their Public DNS Names are accessed. Otherwise, most of the options specified in the User
Data are placed in the moviemasher.ini file used by the 'transcode' example, which will
auto display if properly configured. In order for this example to function properly, an
instance of the Movie Masher Transcoder AMI will need to launched as well - see
README-AMI-Transcoder.txt within this example's directory for details.

The Transcoder instance provides the API that handles preprocessing of uploads and
rendering of mashes back into true video format. API requests are either directly POSTed
to a single instance through its REST (REpresentational State Transfer) interface or to
Amazon's SQS (Simple Queue Service), which doles them out to a pool of instances for
better performance. The resultant file(s) are securely transferred to Amazon's S3 (Simple
Storage Service) or most any HTTP compliant server or service. 

http://aws.amazon.com/sqs/ 
http://aws.amazon.com/s3/


User Data XML Syntax 
--------------------

<MovieMasher>

	<PasswordFTP>YOUR_FTP_PASSWORD</PasswordFTP>
	<PasswordMySQL>YOUR_MYSQL_PASSWORD</PasswordMySQL> 

	<AWSAccessKeyID>YOUR_ACCESS_KEY_ID</AWSAccessKeyID>
	<AWSSecretAccessKey>YOUR_SECRET_ACCESS_KEY</AWSSecretAccessKey> 

	<HostMedia>YOUR_BUCKET_NAME.s3.amazonaws.com</HostMedia>
	<S3Bucket>YOUR_BUCKET_NAME</S3Bucket>
	<S3Region>eu-west-1</S3Region>
	
	<RESTEndPoint>https://ec2-123-456-789-10.compute-1.amazonaws.com</RESTEndPoint> 
	<SQSQueueURLSend>https://queue.amazonaws.com/123456/identifier</SQSQueueURLSend> 

	<KeypairPrivate>-----BEGIN ... END RSA PRIVATE KEY-----</KeypairPrivate> 

</MovieMasher>

If PasswordFTP is defined then user 'moviemasher' will be created on the instance and a
link to /var/www placed in their home directory. If PasswordMySQL is defined then the
MySQL 'root' user password will be set (though the example doesn't yet use MySQL for
storage). Since the User Data is only evaluated when the instance is first launched,
setting these options later in moviemasher.ini has no effect - use SSH to change passwords
on running instances.

If S3 or SQS are being used, or if the Transcoder instance was launched without a Key
Pair, then both the AWSSecretAccessKey and AWSAccessKeyID must be defined in the User Data
when launching both AMIs. The SQS queue or S3 bucket must provide permission to the
identifiers if they are not publicly writable.

If S3 is being used then a bucket must be created and its name placed in the S3Bucket and
HostMedia options. Alternatively, HostMedia can be a CNAME you've set up on your domain
that maps to the bucket. If the bucket is in a region other than US Standard then S3Region
needs to be defined. The PathMedia option can also be defined to set the prefix used when generating bucket keys. 

If REST is being used then RESTEndPoint contains the Public DNS Name of the Transcoder
instance preceded by 'http://' or 'https://' (recommended). Or if SQS is being used
instead then a queue must be created and its URL placed in the SQSQueueURLSend option.
This must match the SQSQueueURLReceive option provided in the User Data when the
Transcoder instance is launched.

If the Transcoder is launched with a Key Pair then the PEM encoded private key portion of
it can be included in the KeypairPrivate option to authenticate API requests. This option
can alternatively contain a file path and the PEM file can be transferred to it after
launch via SSH or FTP. If KeypairPrivate is not defined then AWSAccessKeyID and
AWSSecretAccessKey must be, when launching both the Server and Transcoder AMIs or API
requests cannot be authenticated. 