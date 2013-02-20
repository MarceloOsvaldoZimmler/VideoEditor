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
This script is called directly from Movie Masher Applet, in response to clicks in browser navigation
and scrolling. The count, index and group values are sent as GET parameters, as specified in
panels.xml. Additional GET parameters are used to limit the result set. If the user is authenticated
the script searches either the relevant XML file, depending on group parameter. Media tags matching
parameters are included in result set, paged with count and index parameters. If an error is
encountered it is ignored and an empty result set is returned. This script is called repeatedly as
the user scrolls down, until an empty result set is returned.
*/

$err = '';
$dir_log = '';


// load utilities
$include = dirname(__FILE__) . '/include/';
if ((! $err) && (! @include_once($include . 'authutils.php'))) $err = 'Problem loading authentication utility script';
if ((! $err) && (! @include_once($include . 'logutils.php'))) $err = 'Problem loading log utility script';
if ((! $err) && (! @include_once($include . 'httputils.php'))) $err = 'Problem loading http utility script';
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
	$dir_host = config_path(empty($config['DirHost']) ? $_SERVER['DOCUMENT_ROOT'] : $config['DirHost']);
	$host = (empty($config['Host']) ? $_SERVER['HTTP_HOST'] : http_get_contents($config['Host']));

	$path_cgi = config_path(empty($config['PathCGI']) ? substr(dirname(__FILE__), strlen($dir_host)) : $config['PathCGI']);
	$path_site = config_path(empty($config['PathSite']) ? config_path(dirname(dirname($path_cgi))) : $config['PathSite']);
	$path_xml = config_path(empty($config['PathXML']) ? '' : $config['PathXML']);
	
	$count = (empty($_GET['count']) ? 10 : $_GET['count']);
	$index = (empty($_GET['index']) ? 0 : $_GET['index']);
	$group = (empty($_GET['group']) ? '' : $_GET['group']);

	$log_requests = (empty($config['LogRequests']) ? '' : $config['LogRequests']);
	$log_responses = (empty($config['LogResponses']) ? '' : $config['LogResponses']);
	if ($log_requests) log_file($_SERVER['QUERY_STRING'], $dir_log);

	// make sure required parameters have been sent

	if (! $group ) $err = 'Parameter group required';
}
if (! $err) // try reading in XML file
{
	$path = $dir_host;
	switch($group) // group parameter determines which xml file we search through
	{
		case 'mash':
		case 'video':
		case 'audio':
		case 'image':
			$path .= $path_xml . auth_userid() . '/';
			break;
		default: $path .= $path_site . 'media/xml/';
	}
	$path .= 'media_' . $group . '.xml';

	// if file doesn't exist, assume user hasn't uploaded anything yet
	if (file_exists($path)) $xml_str = @file_get_contents($path, 1);
	else $xml_str = '<moviemasher></moviemasher>' . "\n";

	if (! $xml_str) $err = 'Problem reading ' . $path;
	else
	{
		$media_xml = xml_from_string($xml_str);
		if (! is_object($media_xml)) $err = 'Problem parsing ' . $xml_str;
	}
}

$xml = ''; // output string
$xml .= '<moviemasher>' . "\n";

if (! $err)
{
	// loop through 'media' tags within XML file
	foreach ($media_xml->media as $tag)
	{
		// loop through all parameters
		$ok = 1;
		reset($_GET);
		foreach($_GET as $k => $v)
		{
			switch($k)
			{
				case 'index':
				case 'count':
				case 'unique':
					break;
				default:
					$test = (string) $tag[$k];
					// will match if parameter is empty, equal to or (for label) within attribute
					$ok = ((! $v) || ($v == $test) || ( ($k == 'label') && (strpos(strtolower($test), strtolower($v)) !== FALSE) )) ;
			}
			if (! $ok) break;
		}
		if ($ok)
		{
			// only add tag if within specified range
			if ($index) $index --;
			else
			{
				$xml .= "\t" . $tag->asXML() . "\n";
				$count --;
				if (! $count) break;
			}
		}
	}
}
$xml .= '</moviemasher>' . "\n";
if ($err) log_file($err, $dir_log);
print $xml . "\n\n";
if (! empty($log_responses)) log_file($xml, $dir_log);

?>