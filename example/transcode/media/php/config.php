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
This script is called directly from Movie Masher Applet, when user xml
data is needed. The id GET parameter contains the identifier for xml
file in the user's directory. If an error is encountered it is ignored
and an empty moviemasher tag is returned.
*/

$err = '';
$dir_log = '';

// load utilities
$include = dirname(__FILE__) . '/include/';
if ((! $err) && (! @include_once($include . 'authutils.php'))) $err = 'Problem loading authentication utility script';
if ((! $err) && (! @include_once($include . 'logutils.php'))) $err = 'Problem loading log utility script';
if ((! $err) && (! @include_once($include . 'configutils.php'))) $err = 'Problem loading configuration utility script';
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
if (! $err) // grab log directory configuration option
{
	$log_requests = (empty($config['LogRequests']) ? '' : $config['LogRequests']);
	$log_responses = (empty($config['LogResponses']) ? '' : $config['LogResponses']);
	$dir_host = config_path(empty($config['DirHost']) ? $_SERVER['DOCUMENT_ROOT'] : $config['DirHost']);
	$path_xml = config_path(empty($config['PathXML']) ? '' : $config['PathXML']);
	$path = $dir_host . $path_xml;
	$path .=  auth_userid() . '/';
	if ($log_requests) log_file($_SERVER['QUERY_STRING'], $dir_log);
	
	// make sure required parameters have been sent
	$id = (empty($_GET['id']) ? '' : $_GET['id']);	
	if (! $id) $err = 'Parameter id required';
}
if (! $err) // try reading in XML file
{	
	$path .= $id . '.xml';
	clearstatcache();
	if (file_exists($path)) $xml_str = @file_get_contents($path, 1);
	if (empty($xml_str)) $err = 'Problem reading ' . $path;
}
if (! $err) // try parsing XML file
{	
	$media_xml = xml_from_string($xml_str);
	if (! is_object($media_xml)) $err = 'Problem parsing ' . $xml_str;
}
if ($err) 
{
	$xml = '<moviemasher></moviemasher>';
	log_file($err, $dir_log);
}
else $xml = $media_xml->asXML();
print $xml . "\n\n";
if (! empty($log_responses)) log_file($xml, $dir_log);

?>