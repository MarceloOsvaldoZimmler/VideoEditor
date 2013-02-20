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
if ((! $err) && (! @include_once($include . 'configutils.php'))) $err = 'Problem loading configuration utility script';
if ((! $err) && (! @include_once($include . 'fileutils.php'))) $err = 'Problem loading file utility script';
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
	$dir_host = config_path(empty($config['DirHost']) ? $_SERVER['DOCUMENT_ROOT'] : $config['DirHost']);

	$path_cgi = config_path(empty($config['PathCGI']) ? substr(dirname(__FILE__), strlen($dir_host)) : $config['PathCGI']);
	$path_site = config_path(empty($config['PathSite']) ? config_path(dirname(dirname($path_cgi))) : $config['PathSite']);
	$path_xml = config_path(empty($config['PathXML']) ? '' : $config['PathXML']);
	
	$id = (empty($_REQUEST['id']) ? '' : $_REQUEST['id']);
	$duration = (empty($_REQUEST['duration']) ? '' : $_REQUEST['duration']);
	$mash_string = file_get('php://input');

	$log_requests = (empty($config['LogRequests']) ? '' : $config['LogRequests']);
	$log_responses = (empty($config['LogResponses']) ? '' : $config['LogResponses']);
	if ($log_requests) log_file($_SERVER['QUERY_STRING']  . "\n" . $mash_string, $dir_log);

	// make sure required parameters have been sent
	if (! ($id && $mash_string && $duration)) $err = 'Mash duration, id and data required';
}
// check to make sure XML data is parsable
if (! $err)
{
	clearstatcache();
	$mash_xml =xml_from_string($mash_string);
	if (! $mash_xml) $err = 'Could not parse mash data: ' . $mash_string;
}
// make sure label was set
if (! $err)
{
	$label = $mash_xml->mash[0]['label'];
	if (! $label) $err = 'Could not determine mash label';
}
// make sure clip tags are found
if (! $err)
{
	if (! sizeof($mash_xml->mash[0]->clip)) $err = 'No clip tags found';
}

if (! $err) // save mash xml to local file
{
	$path_xml .= auth_userid() . '/';
	$xml_path = $dir_host . $path_xml . $id . '.xml'; // must be writable by the web server process
	if (! file_put($xml_path, $mash_string)) $err = 'Problem saving mash';
}
if (! $err) // try reading in user's media.xml file containing existing media items
{
	if (substr($path_cgi, 0, strlen($path_site)) == $path_site)
	{
		$partial_cgi_path = substr($path_cgi, strlen($path_site));
	}
	else $partial_cgi_path = '/' . $path_cgi;
	if (substr($path_xml, 0, strlen($path_site)) == $path_site)
	{
		$partial_media_path = substr($path_xml, strlen($path_site));
	}
	else $partial_media_path = '/' . $path_xml;
	$media_file_xml_path = $dir_host . $path_xml . 'media_mash.xml';

	if (file_exists($media_file_xml_path)) $xml_str = file_get($media_file_xml_path);
	else $xml_str = '<moviemasher />' . "\n";

	if (! $xml_str) $err = 'Problem loading ' . $media_file_xml_path;
	else
	{
		$media_file_xml = xml_from_string($xml_str);
		if (! is_object($media_file_xml)) $err = 'Problem parsing ' . $xml_str;
	}
}
if (! $err) // make sure there is a media tag for this mash in user's media.xml file
{
	$media_tag = null;
	// see if media tag for this mash already exists
	$media_tags = $media_file_xml->xpath('./media[@id="' . $id . '"]');
	if (sizeof($media_tags)) $media_tag = $media_tags[0];
	$media_tag_existed = ! is_null($media_tag);
	if (! $media_tag_existed) // add media data to existing media.xml file
	{
		if (! empty($config['MashMulti']))
		{
			$multi_mash_path = $dir_host . $path_site . $partial_media_path . 'multi-mash.xml';
			
			if (! sizeof($media_file_xml->xpath('./media[@id="multi-mash"]')))
			{	// there is no multi-mash media tag in media_mash.xml, so create one
				$multi_media_tag = $media_file_xml->addChild('media');
				$multi_media_tag['type'] = 'mash';
				$multi_media_tag['id'] = 'multi-mash';
				$multi_media_tag['group'] = 'mash';
				$multi_media_tag['url'] = $partial_cgi_path . 'config.php?id=multi-mash&unique={moviemasher.random}';
				$multi_media_tag['label'] = 'Multi-Mash';
				$multi_mash_string = '
					<moviemasher>
						<mash config="' . $partial_cgi_path . 'config.php?id=media_mash&amp;unique={moviemasher.random}" label="Multi-Mash" quantize="10" id="multi-mash" noneditable="effects">    
						<drop type="image"/>
						<drop type="video"/>
						<drop type="audio"/>
						<drop type="mash"/>
						</mash>
					</moviemasher>
				';
			}
			else $multi_mash_string = file_get($multi_mash_path);
			$multi_mash_xml = xml_from_string($multi_mash_string);
			if (! is_object($multi_mash_xml)) $err = 'Could not parse multi mash';
			if (! $err)
			{
				$multi_mash_tag = $multi_mash_xml->mash[0];
				$multi_mash_tag['dirty'] = 1;
				$clip_tag = $multi_mash_tag->addChild('clip');
				$clip_tag['id'] = $id;
				$clip_tag['type'] = 'mash';
				if (! file_put($multi_mash_path, xml_pretty($multi_mash_xml->asXML(), FALSE))) $err = 'Problem writing multi-mash file';
			}
		}
		$media_tag = $media_file_xml->addChild('media');
		$media_tag['type'] = 'mash';
		$media_tag['id'] = $id;
		$media_tag['group'] = 'mash';
		$media_tag['noneditable'] = 'effects,speed,label,volume';
		$media_tag['url'] = $partial_cgi_path . 'config.php?id=' . $id . '&unique={moviemasher.random}';
	}
	$media_tag['label'] = $label;
	// write file
	if ((! $err) && (! file_put($media_file_xml_path, xml_pretty($media_file_xml->asXML(), FALSE))))
	{
		$err = 'Problem writing media file';
	}
}
// setting dirty to zero should cause save button to disable
if (! $err) $xml = '<moviemasher trigger="player.dirty=0" />';
else
{
	$xml = '<moviemasher get=\'javascript:alert("' .  $err . '");\' />';
	log_file($err, $dir_log);
}
print $xml . "\n\n";
if (! empty($log_responses)) log_file($xml, $dir_log);


?>