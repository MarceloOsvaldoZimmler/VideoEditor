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
This script is called from the CGI control, after loading export_init.php.
The job and media IDs are in _GET.
The script attempts to check on the progress of the job and either:
	* redirects client back to itself, if job is still processing, by setting 'url' attribute
	* directs client to refresh browser view if job is finished
	* displays javascript alert if error is encountered, by setting 'get' attribute
If possible, the response to client is logged.
*/

$err = '';
$dir_log = '';
$done = FALSE;
// load utilities
$include = dirname(__FILE__) . '/include/';
if ((! $err) && (! @include_once($include . 'authutils.php'))) $err = 'Problem loading authentication utility script';
if ((! $err) && (! @include_once($include . 'fileutils.php'))) $err = 'Problem loading file utility script';
if ((! $err) && (! @include_once($include . 'configutils.php'))) $err = 'Problem loading configuration utility script';
if ((! $err) && (! @include_once($include . 'httputils.php'))) $err = 'Problem loading http utility script';
if ((! $err) && (! @include_once($include . 'logutils.php'))) $err = 'Problem loading log utility script';
if ((! $err) && (! @include_once($include . 'xmlutils.php'))) $err = 'Problem loading xml utility script';

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
	$dir_temporary = config_path(empty($config['DirTemporary']) ? sys_get_temp_dir() : $config['DirTemporary']);
	$dir_host = config_path(empty($config['DirHost']) ? $_SERVER['DOCUMENT_ROOT'] : $config['DirHost']);
	$host = (empty($config['Host']) ? $_SERVER['HTTP_HOST'] : http_get_contents($config['Host']));
	$host_media = (empty($config['HostMedia']) ? $host : http_get_contents($config['HostMedia']));
	$path_cgi = config_path(empty($config['PathCGI']) ? substr(dirname(__FILE__), strlen($dir_host)) : $config['PathCGI']);
	$path_site = config_path(empty($config['PathSite']) ? config_path(dirname(dirname($path_cgi))) : $config['PathSite']);
	$path_media = config_path(empty($config['PathMedia']) ? '' : $config['PathMedia']);
	$path_media .=  auth_userid() . '/';


	if ($client == 'REST') $rest_endpoint = config_path(empty($config['RESTEndPoint']) ? '' : $config['RESTEndPoint']);

	$log_requests = (empty($config['LogRequests']) ? '' : $config['LogRequests']);
	$log_responses = (empty($config['LogResponses']) ? '' : $config['LogResponses']);
	$log_transcoder_requests = (empty($config['LogTranscoderRequests']) ? '' : $config['LogTranscoderRequests']);
	$log_transcoder_responses = (empty($config['LogTranscoderResponses']) ? '' : $config['LogTranscoderResponses']);
	if ($log_requests) log_file($_SERVER['QUERY_STRING'], $dir_log);

	$job = (empty($_REQUEST['job']) ? '' : $_REQUEST['job']);
	$id = (empty($_REQUEST['id']) ? '' : $_REQUEST['id']);
	if (! ($job && $id)) $err = 'Parameters job, id required';
}

if (! $err) // get job progress
{
	$progress = array();
	if ($client == 'SQS')
	{
		$url = $dir_temporary . $id . '.xml';
		$xml_string = file_get($url);
	}
	else
	{
		$url = config_path($rest_endpoint) . $job;
		if ($log_transcoder_requests) log_file($url, $dir_log);
		$xml_string = http_get_contents($url);
	}
	if (! $xml_string) // Could not read progress
	{
		$progress['percent'] = 1;
		$progress['status'] = 'Queued';
	}
	else 
	{
		if ($log_transcoder_responses) log_file($xml_string, $dir_log);
		$xml_object = xml_from_string($xml_string);
		if (! is_object($xml_object)) $err = 'Could not parse progress';
		else
		{
			$progress['status'] = (string) $xml_object->Progress->Status;
			$progress['percent'] = intval($xml_object->Progress->Percent);
			switch($progress['percent'])
			{
				case 2: // transcoder doesn't yet know for sure how involved job is
				{
					$progress['percent'] = intval($xml_object->Progress->PercentEstimate);
					break;
				}
				case -1: $err = $progress['status'];
				case 100: $done = TRUE;
			}
		}
	}
}

if (! $err)
{
	$attrs = '';
	// if job is still processing, redirect back here with same parameters
	if ($progress['percent'] < 100) $attrs = ' delay="10" url="media/php/export_monitor.php?job=' . $job . '&amp;id=' . $id . '"';
	else $attrs = ' trigger="browser.parameters.group=mash"';
}
if ($done && ($client == 'SQS')) @unlink($url);
if ($err) $xml = '<moviemasher progress="100" status="" get=\'javascript:alert("' .  $err . '");\' />';
else $xml = '<moviemasher' . $attrs . ' progress="' . $progress['percent'] . '" status="' . $progress['status'] . '" />';
print $xml . "\n\n";
if (! empty($log_responses)) log_file($xml, $dir_log);

?>