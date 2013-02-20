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
This script is called directly from Movie Masher Applet, in response to a click on the Save button.
The XML formatted mash is posted as raw data, available in php://input
The script saves the XML data to $xml_path - defined below
Any errors are reported in a javascript alert, by setting the 'get' attribute.
Otherwise an empty moviemasher tag is returned, to indicate success.
*/

$err = '';
$dir_log = '';

// load utilities
$include = dirname(__FILE__) . '/include/';
if ((! $err) && (! @include_once($include . 'authutils.php'))) $err = 'Problem loading authentication utility script';
if ((! $err) && (! @include_once($include . 'configutils.php'))) $err = 'Problem loading config utility script';
if ((! $err) && (! @include_once($include . 'httputils.php'))) $err = 'Problem loading http utility script';
if ((! $err) && (! @include_once($include . 'idutils.php'))) $err = 'Problem loading id utility script';
if ((! $err) && (! @include_once($include . 'logutils.php'))) $err = 'Problem loading log utility script';
if ((! $err) && (! @include_once($include . 'mimeutils.php'))) $err = 'Problem loading mime utility script';
if ((! $err) && (! @include_once($include . 'sigutils.php'))) $err = 'Problem loading signature utility script';
if ((! $err) && (! @include_once($include . 'urlutils.php'))) $err = 'Problem loading http utility script';
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
	$dir_host = config_path(empty($config['DirHost']) ? $_SERVER['DOCUMENT_ROOT'] : $config['DirHost']);
	$host = (empty($config['Host']) ? $_SERVER['HTTP_HOST'] : http_get_contents($config['Host']));
	$host_media = (empty($config['HostMedia']) ? $host : http_get_contents($config['HostMedia']));

	$encoder_original_filename = (empty($config['EncoderOriginalFilename']) ? 'original' : $config['EncoderOriginalFilename']);
	$path_cgi = config_path(empty($config['PathCGI']) ? substr(dirname(__FILE__), strlen($dir_host)) : $config['PathCGI']);
	$path_media = config_path(empty($config['PathMedia']) ? '' : $config['PathMedia']);
			
	if ($file == 'S3') // if using S3, grab bucket and credentials
	{
		$access_key_id = (empty($config['AWSAccessKeyID']) ? '' : $config['AWSAccessKeyID']);
		$secret_access_key = (empty($config['AWSSecretAccessKey']) ? '' : $config['AWSSecretAccessKey']);
		$s3_bucket = (empty($config['S3Bucket']) ? '' : $config['S3Bucket']);
		$s3_region = (empty($config['S3Region']) ? '' : $config['S3Region']);
		if (substr($path_media, 0, strlen($s3_bucket)) == $s3_bucket) $path_media = substr($path_media, strlen($s3_bucket) + 1);
	}
	$path_media .=  auth_userid() . '/';
	$log_requests = (empty($config['LogRequests']) ? '' : $config['LogRequests']);
	$log_responses = (empty($config['LogResponses']) ? '' : $config['LogResponses']);
	$log_transcoder_requests = (empty($config['LogTranscoderRequests']) ? '' : $config['LogTranscoderRequests']);
	if ($log_requests) log_file($_SERVER['QUERY_STRING'], $dir_log);
	$type = (empty($_REQUEST['type']) ? '' : $_REQUEST['type']);
	$file_name = (empty($_REQUEST['file']) ? '' : $_REQUEST['file']);
	$file_is_url = ($file_name && (substr($file_name, 0, 4) == 'http'));
	$file_label = (empty($_REQUEST['label']) ? ($file_is_url ? basename($file_name) : $file_name) : $_REQUEST['label']);
	$file_size = (empty($_REQUEST['size']) ? ($file_is_url ? 1 : 0) : $_REQUEST['size']);
	if (! ($file_name && $file_size)) $err = 'Parameters file, size required';
}
if (! $err) // make sure we can determine mime type and extension from file name
{
	$extension = file_extension($file_name);
	$mime = mime_from_path($file_name);
	if (! ($mime && $extension)) $err = 'Could not determine mime type or extension';
}
if (! $err) // make sure mime type is supported
{
	$type = mime_type($mime);
	switch($type)
	{
		case 'audio':
		case 'video':
		case 'image': break;
		default: $err = 'Only audio, image and video files supported';
	}
}
if (! $err) // enforce size limit from configuration, if defined
{
	$uc_type = ucwords($type);
	$max = (empty($config['MaxMeg' . $uc_type]) ? '' : $config['MaxMeg' . $uc_type]);
	if ($max)
	{
		$file_megs = round($file_size / (1024 * 1024));
		if ($file_megs > $max) $err = ($uc_type . ' files must be less than ' . $max . ' meg');
	}
}
if (! $err)
{
	$attributes = '';
	$id = id_unique();
	if ($file_is_url || ($file != 'Local'))
	{
		if (! $file_is_url) // $file == 'S3'
		{
			$s3_options = array();
			$s3_options['bucket'] = $s3_bucket;
			$s3_options['path'] = $path_media . $id . '/' . $encoder_original_filename . '.' . $extension;
			$s3_options['mime'] = $mime;
			$s3data = sig_s3_post($secret_access_key, $s3_options);
			$s3data['keyid'] = $access_key_id;
			$s3data['region'] = $s3_region;
			foreach($s3data as $k => $v) $attributes .= " $k='$v'";
		} 
		$attributes .= ' url="media/php/import_api.php?label=' . urlencode($file_label) . '&amp;';
		if ($file_is_url) $attributes .= 'url=' . urlencode($file_name) . '&amp;';
	}
	else
	{
		$attributes .= ' upload="media/php/import_upload.php?u=' . auth_userid() . '&amp;';
	}
	$attributes .= "id=$id&amp;type=$type&amp;extension=$extension" . '"';
	$attributes .= ' status="';
	$attributes .= ($file_is_url ? 'Copying' : (($file == 'Local') ? 'Uploading' : 'Transferring'));
	$attributes .= '"';
}
if ($err) $xml = '<moviemasher progress="-1" status="' .  $err . '" />';
else $xml = '<moviemasher ' . $attributes . ' />';

$writer = xml_writer('', TRUE);
$writer->writeRaw($xml);
print $writer->outputMemory() . "\n\n";

if (! empty($log_responses)) log_file($xml, $dir_log);
?>