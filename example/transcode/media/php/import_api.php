<?php 
/*
* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/.
* 
* Software distributed under the License is distributed on an
* "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express
* or implied. See the License for the specific language
* governing rights and limitations under the License.
* 
* The Original Code is 'Movie Masher'. The Initial Developer
* of the Original Code is Doug Anarino. Portions created by
* Doug Anarino are Copyright (C) 2007-2012 Movie Masher, Inc.
* All Rights Reserved.
*/
/*
This script is called from the CGI control, after import_init.php or
import_upload.php are called. $_GET contains information about the
imported media file with keys id, extension, type and label. If the
media file is remote, the url key will contain its location. The script
generates a job and posts it to Movie Masher Transcoder. The resultant
job ID is passed along with the media ID and type to import_monitor.php,
by setting the 'url' attribute in response. If an error is encountered
it is displayed in a javascript alert, by setting the 'get' attribute.
If possible, the response to client is logged.
*/

$err = '';
$dir_log = '';

// load utilities
$include = dirname(__FILE__) . '/include/';
if ((! $err) && (! @include_once($include . 'authutils.php'))) $err = 'Problem loading authentication utility script';
if ((! $err) && (! @include_once($include . 'mimeutils.php'))) $err = 'Problem loading authentication utility script';
if ((! $err) && (! @include_once($include . 'apiutils.php'))) $err = 'Problem loading api utility script';

if (! $err) // pull in configuration so we can log other errors
{
	$config = config_get();
	$dir_log = config_path(empty($config['DirLog']) ? '' : $config['DirLog']);
	$err = config_error($config);
}
if (! $err) // see if the user is authenticated (does not redirect or exit)
{
	if (! auth_ok()) $err = 'Unauthenticated access';
}
if (! $err) // pull in other configuration and check for required input
{
	$client = (empty($config['Client']) ? 'REST' : strtoupper($config['Client']));
	$file = (empty($config['File']) ? 'Local' : ucwords($config['File']));
	
	if (($client == 'SQS') || ($file == 'S3'))
	{
		if ($file == 'S3')
		{
			$s3_bucket = (empty($config['S3Bucket']) ? '' : $config['S3Bucket']);
		}
		if ($client == 'SQS') $queue_url =  (empty($config['SQSQueueURLSend']) ? '' : $config['SQSQueueURLSend']);
	}
	if ($client == 'REST') $rest_endpoint = config_path(empty($config['RESTEndPoint']) ? '' : $config['RESTEndPoint']);
	
	$log_requests = (empty($config['LogRequests']) ? '' : $config['LogRequests']);
	$log_responses = (empty($config['LogResponses']) ? '' : $config['LogResponses']);
	
	if ($log_requests) log_file($_SERVER['QUERY_STRING'], $dir_log);

	// make sure required parameters have been sent
	$id = (empty($_REQUEST['id']) ? '' : $_REQUEST['id']);
	$url = (empty($_GET['url']) ? '' : $_GET['url']);	
	$type = (empty($_GET['type']) ? mime_type_from_extension(empty($_GET['extension']) ? file_extension($url) : $_GET['extension']) : $_GET['type']);

	if (! ($id && $type)) $err = 'Required parameter omitted';
}
if (! $err) 
{
	$result = api_import($_GET, array('UserID' => auth_userid(), 'IncludeProgress' => 1), $config);
	if (! empty($result['error'])) $err = $result['error'];
	else $job_id = $result['id'];
}

if (! $err) $xml = '<moviemasher url="media/php/import_monitor.php?type=' . $type . '&amp;job=' . $job_id . '&amp;id=' . $id . '" progress="1" status="Queueing..." delay="10" />';
else $xml = '<moviemasher progress="-1" status="' .  $err . '" />';

print $xml . "\n\n";
if (! empty($log_responses)) log_file($xml, $dir_log);
?>