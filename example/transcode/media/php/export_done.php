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
This script is called by the Transcoder when rendering of a mash has completed and
transferred without error. If we can authenticate the request, we update the mash's media
object into the user's data space for the freshly rendered file. If an error is
encountered a 400 header is returned and it is logged, if possible.
*/

$err = '';
$dir_log = '';

// load utilities
$include = dirname(__FILE__) . '/include/';
if ((! $err) && (! @include_once($include . 'authutils.php'))) $err = 'Problem loading authentication utility script';
if ((! $err) && (! @include_once($include . 'configutils.php'))) $err = 'Problem loading configuration utility script';
if ((! $err) && (! @include_once($include . 'fileutils.php'))) $err = 'Problem loading file utility script';
if ((! $err) && (! @include_once($include . 'httputils.php'))) $err = 'Problem loading http utility script';
if ((! $err) && (! @include_once($include . 'logutils.php'))) $err = 'Problem loading log utility script';
if ((! $err) && (! @include_once($include . 'mimeutils.php'))) $err = 'Problem loading mime utility script';
if ((! $err) && (! @include_once($include . 'xmlutils.php'))) $err = 'Problem loading xml utility script';

if (! $err) // pull in configuration so we can log other errors
{
	$config = config_get();
	$dir_log = config_path(empty($config['DirLog']) ? '' : $config['DirLog']);
	$err = config_error($config);
}
if (! $err) // see if the user is authenticated (does not redirect or exit)
{
	if (! auth_ok_callback()) $err = 'Unauthenticated access';
}

if (! $err) // pull in other configuration and check for required input
{
	$uid = (empty($_REQUEST['uid']) ? '' : $_REQUEST['uid']);
	$id = (empty($_REQUEST['id']) ? '' : $_REQUEST['id']);
	$client = (empty($config['Client']) ? 'REST' : strtoupper($config['Client']));
	$file = (empty($config['File']) ? 'Local' : ucwords($config['File']));
	$dir_host = config_path(empty($config['DirHost']) ? $_SERVER['DOCUMENT_ROOT'] : $config['DirHost']);
	$host = (empty($config['Host']) ? $_SERVER['HTTP_HOST'] : http_get_contents($config['Host']));
	$host_media = (empty($config['HostMedia']) ? $host : http_get_contents($config['HostMedia']));
	$path_cgi = config_path(empty($config['PathCGI']) ? substr(dirname(__FILE__), strlen($dir_host)) : $config['PathCGI']);
	$path_site = config_path(empty($config['PathSite']) ? config_path(dirname(dirname($path_cgi))) : $config['PathSite']);
	$path_media = config_path(empty($config['PathMedia']) ? '' : $config['PathMedia']);
	$path_media .=  $uid . '/';
	$path_xml = config_path(empty($config['PathXML']) ? '' : $config['PathXML']);
	$path_xml .=  $uid . '/';
	$job = (empty($_REQUEST['job']) ? '' : $_REQUEST['job']);
	$extension = (empty($_REQUEST['extension']) ? '' : $_REQUEST['extension']);
	$started = (empty($_REQUEST['started']) ? 0 : $_REQUEST['started']);
	log_file('Took ' . (time() - $started) . ' seconds', $dir_log);
	
	if (! ($id && $job)) $err = 'Parameters id, job required';

	if ($file == 'Local')
	{
		if (substr($path_media, 0, strlen($path_site)) == $path_site)
		{
			$partial_media_path = substr($path_media, strlen($path_site));
		}
		else $partial_media_path = '/' . $path_media;
	}
	else $partial_media_path = 'http://' . $host_media . '/' . $path_media;
}
if (! $err) // make sure user's media.xml file exists
{
	$media_file_xml_path = $dir_host . $path_xml . 'media_mash.xml';
	if (! file_exists($media_file_xml_path)) $err = 'Could not find ' . $media_file_xml_path;
}
if (! $err) // read in the media xml file
{
	$xml_str = file_get($media_file_xml_path);
	if (! $xml_str) $err = 'Problem loading ' . $media_file_xml_path;
}
if (! $err) // parse the media xml string
{
	$media_file_xml = xml_from_string($xml_str);
	if (! is_object($media_file_xml)) $err = 'Problem parsing ' . $xml_str;
}
if (! $err) // search media.xml file for id
{
	$media_tags = $media_file_xml->xpath("//media[@id='$id']");
	if (! sizeof($media_tags) > 0) $err = 'Could not find mash with ID: ' . $id;
}
if (! $err) // write file
{
	$media_tag = $media_tags[0];
	$media_tag['source'] = $partial_media_path . $id . '/' . $job . '.' . $extension;
	if (! empty($config['MashIcon'])) $media_tag['icon'] = $partial_media_path . $id . '/' . $job . '.jpg';
	// build XML string
	$xml_str = '';
	$xml_str .= '<moviemasher>';
	$children = $media_file_xml->children();
	$z = sizeof($children);
	for ($i = 0; $i < $z; $i++) $xml_str .= "\t" . $children[$i]->asXML() . "\n";
	$xml_str .= '</moviemasher>' . "\n";

	if (! file_put($media_file_xml_path, $xml_str)) $err = 'Problem writing ' . $media_file_xml_path;
}
if (! $err)
{
	if ($client == 'SQS')
	{
		$dir_temporary = config_path(empty($config['DirTemporary']) ? sys_get_temp_dir() : $config['DirTemporary']);
		$xml_string = '';
		$xml_string .= '<Response><Progress>' . "\n";
		$xml_string .= "\t" . '<Percent>100</Percent>' . "\n";
		$xml_string .= "\t" . '<Status>Done</Status>' . "\n";
		$xml_string .= '</Progress></Response>' . "\n";
		if (! file_put($dir_temporary . $id . '.xml', $xml_string)) $err = 'Could not write progress file';
	}
}
if ($err)
{
	header('HTTP/1.1: 400 Bad Request');
	header('Status: 400 Bad Request');
	print $err;
	log_file($err, $dir_log);
}
?>