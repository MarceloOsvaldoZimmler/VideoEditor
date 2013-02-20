Transcoder API Read Me 
----------------------

More extensive documentation of the API is available online:

	http://www.moviemasher.com/docs/mmapi/
	
The Transcoder API accepts requests for transcoding operations that convert media assets
into other formats, as well as combining them with effects, titling or transitions. As
part of the operation, the resultant files are transferred via HTTP to a web server or
similar service like S3.

A request is sent through either the REST or SQS interface depending on which of the
supported network architectures is chosen, but this doesn't affect the request itself
since all information required to authenticate it is contained within its body.

Basic Request Structure
-----------------------

<MovieMasher>
	<Authentication>...</Authentication>
	<Signature>...</Signature>
	<Job>
		<Input>...
			<Transfer>...</Transfer>
		</Input>
		<Output>...
			<Transfer>...</Transfer>
		</Output>
		<Transfer>...</Transfer>
	</Job>
</MovieMasher>

Each request consists of a MovieMasher root tag having a single Authentication and
Signature tag that together authorize the request, plus a Job tag which describes all the
transcoding and file transfer operations to perform. The Job tag contains one or more
Input tags each defining a media resource to incorporate into the transcoding, plus one or
more Output tags defining a media resource to generate from it. Transfer tags describe
each request that's made to exchange resources with external servers, and are conditional
within the Input, Output and Job tags.

Request Processing
------------------
Conceptually, when processing a Job the Transcoder joins all the Inputs together to form a
single intermediate file, which is then encoded into each of the formats specified in the
Outputs. Each Input tag generally requires a Transfer tag describing where to find its
associated media resource.

Each Output tag can each have its own Transfer tag if its associated file is going to a
unique destination, but if there is a Transfer tag within the enclosing Job tag it will be
used to batch transfer all the files produced by Outputs lacking one. Output transfers can
optionally be archived before transferring - otherwise they can all be transferred
individually or in a single combined request.

Authenticating Transfers
------------------------
Ideally, a highly secure web application will authenticate each and every HTTP request
made within the system. The Transcoder API enforces this principle for all job requests it
receives (see below) but not necessarily for requests it makes as Transfer tags are
evaluated. Additional tags must be supplied to augment the request in a way that will
authenticate it to its receiver. Query or POST parameters can be added as well as HTTP
headers, and the associated values can be generated as the request is being made. Digital
signatures can even be generated on the fly, using keys included on the Transcoder AMI at
launch time. The syntax of the Transfer tag and its children allow S3 to be used,
including support for advanced features like 'Requester Pays' and DevPay.


Types of Inputs, Output and Transfers
-------------------------------------
Inputs, Outputs and Transfer tags all contain a Type tag that affects their handling.
Currently only the 'http' Type is supported for Transfer tags, but thoroughly enough to
enable complex interactions with S3 and similar web services. Supported Input types
are 'video', 'audio', 'image' and 'mash'. The later one can contain more complex
arrangements of these core media type plus effects, transitions, titles and themes
supported by Movie Masher.

Supported Output Types include 'video', 'audio' and 'image' as expected, but also
'sequence' which produces a folder full of JPEG frames and 'waveform' which produces a PNG
spectral graphic of the audio. The other supported Type for an Output tag is 'text' which
can be used to generate meta data files from a template supplied in its Body tag, with
substitutions like 'Input.Type' and 'Input.Duration'.

Job Notifications
-----------------
Outputs of Type 'text' also support a Trigger tag, with possible values like 'initiate',
'progress', 'error', and 'complete'. These are used to facilitate remote notifications
during these particular junctures in Job processing. The templates used by these Text
Outputs can contain runtime references like 'Job.Status', 'Job.Percent' or even
'Job.Verbose' for debugging output.

Authenticating Requests
-----------------------

The first tier Authentication tag and Signature tag contain all information needed to
establish the identity of the caller and authorize a particular request:

<Authentication>
	<Name>KeyPair</Name>
	<Date>2012-12-21T11:12:01Z</Date>
	<Nonce>A7F25D19-5F7C-4550-B1BB-CFE90C65F2F0</Nonce>
</Authentication>
<Signature>YW7yJ0CIX12459W1rV6LOxNJwhs=</Signature>

Most importantly the Signature tag contains a digital fingerprint generated by applying
your access key to a string representing the Job tag and its descendants, combined with a
string representing the other tags within the Authentication tag. These always include a
Date tag containing the current time in ISO8601 format, and a Name tag that matches the
Name tag of one of the Transcoder's AccessKey tags. A Nonce tag containing a random string
is optional, but recommended for added security against replay attacks.

Generating the String to Sign
-----------------------------

The string that your access key is applied to starts with a string representation of the
Authentication tag, followed by a new line and a string representation of the Job tag. The
string representations of the tags consist of key/value pairs separated by new lines and
sorted alphabetically by key. There is one key/value pair for each discrete value within
the XML - each tag attribute as well as each text node. Empty values in attributes and
empty text nodes are ignored.

The key consists of the names of all the parent tags delimited by a period, and is
separated from the value by a colon. If the value contains any escaped XML special
characters they should be converted back to their XML equivalents - eg. '&amp;' and '&lt;'
should be converted back to just '&' and '<' respectively.

<MovieMasher>
	<Job>
		<Output>
			<Type>video</Type>
			<Transfer>
				<Host>example.com</Host>
				<Path>upload.cgi</Path>
				<Method>post</Method>
			</Transfer>
		</Output>
		<Output>
			<Type>type</Type>
			<Trigger>progress</Trigger>
			<Trigger>complete</Trigger>
			<Transfer>
				<Host>example.com</Host>
				<Path><![CDATA[status.cgi?p={Job.Percent}&d={Transfer.Date}]]></Path>
				<Method>get</Method>
			</Transfer>
		</Output>
		<Input>
			<Type>mash</Type>
			<Body>
				<mash quantize="10" autostart="" label="&lt;My Mash&gt;">
					<clip symbol="com/moviemasher/module/All.swf@Clouds" length="50" />
				</mash>
			</Body>
		</Input>
	</Job>
	<Authentication>
		<Identifier>B8BC8B8789B9EC08</Identifier>
		<Date>2012-12-21T11:12:01Z</Date>
		<Nonce>A7F25D19-5F7C-4550-B1BB-CFE90C65F2F0</Nonce>
	</Authentication>
</MovieMasher>

Authentication.Date:2012-12-21T11:12:01Z
Authentication.Identifier:B8BC8B8789B9EC08
Authentication.Nonce:A7F25D19-5F7C-4550-B1BB-CFE90C65F2F0
Job.Input.Body.mash.clip.length:50
Job.Input.Body.mash.clip.symbol:com/moviemasher/module/All.swf@Clouds
Job.Input.Body.mash.label:<My Mash>
Job.Input.Body.mash.quantize:10
Job.Input.Type:mash
Job.Output.1.Transfer.Host:example.com
Job.Output.1.Transfer.Method:post
Job.Output.1.Transfer.Path:upload.cgi
Job.Output.1.Type:video
Job.Output.2.Transfer.Host:example.com
Job.Output.2.Transfer.Method:get
Job.Output.2.Transfer.Path:status.cgi?p={Job.Percent}&d={Transfer.Date}
Job.Output.2.Trigger.1:progress
Job.Output.2.Trigger.2:complete
Job.Output.2.Type:type

Signing Methods 
---------------

Which signing method is used depends on how the Transcoder was configured at launch time.
By default, each instance can accept signatures generated with openssl using the private
key portion of the AWS Keypair that was used to launch it. If an AWS Access Key ID and
Secret Access Key were provided at launch time instances can accept signatures generated
with them as well.