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
This script is called directly from Movie Masher Applet, in response to a click on upload button.
The uploaded file is in _FILES['Filedata'].
If the file uploads and its extension is acceptable, the following happens:
	* a quasi unique ID is generated for the media file
	* the base file name is changed to this ID, retaining file extension
	* the file is moved to $upload_dir - defined below
	* a media tag is inserted into $media_file for the uploaded file
Any error encountered is reported in a javascript alert, by setting the 'get' attribute.
Otherwise the 'trigger' attribute is used to switch the browser view to the images tab.
*/

$upload_dir = '../user/'; // needs to be writable by web server process
$media_file = '../xml/media.xml'; // needs to be writable by web server process

$err = '';

// make sure $_FILES is set and has upload key
if (empty($_FILES) || empty($_FILES['Filedata'])) $err = 'No files supplied';

// make sure there wasn't a problem with the upload
if (! $err)
{
	$file = $_FILES['Filedata'];
	if (! empty($file['error'])) $err = 'Problem with your file: ' . $file['error'];
	elseif (! is_uploaded_file($file['tmp_name'])) $err = 'Not an uploaded file';
}

// check to make sure file has acceptable extension
if (! $err)
{
	$extension = strtolower(substr($file['name'], strrpos($file['name'], '.') + 1));
	switch ($extension)
	{
		case 'jpeg': 
			$extension = 'jpg';
		case 'jpg':
			break;
		case 'ping':
			$extension = 'png';
		case 'png':
			break;
		case 'giff':
			$extension = 'gif';
		case 'gif':
			break;
		default: 
			$err = 'Unsupported file extension ' . $extension;
	}
}


// move file and set its permissions
if (! $err)
{
	$type = 'image';
	$label = $file['name'];
	$id = md5(uniqid() . 'media' . $label);
	$url = 'media/user/' . $id . '.' . $extension;
	$path = $upload_dir . $id . '.' . $extension;
	if (! @move_uploaded_file($file['tmp_name'], $path)) $err = 'Problem moving file to ' . $path;
	elseif (! @chmod($path, 0777)) $err = 'Problem setting permissions';
}

if (! $err) 
{
	// try reading in media.xml file containing existing media items
	if (! $err)
	{
		$xml_str = @file_get_contents($media_file);
		if (! $xml_str) $err = 'Problem loading ' . $media_file;
		else
		{
			$media_file_xml = @simplexml_load_string($xml_str);
			if (! is_object($media_file_xml)) $err = 'Problem parsing ' . $xml_str;
		}
	}
	
	// add media data to existing media.xml file
	if (! $err)
	{
		// reset type, in case it was changed by the Transcoder - audio in video format?
		
		// start with an unattributed media tag document
		$media_xml = simplexml_load_string('<moviemasher><media /></moviemasher>');
		
		// add required attributes
		$media_xml->media->addAttribute('type', $type);
		$media_xml->media->addAttribute('id', $id);
		
		// add standard attributes
		$media_xml->media->addAttribute('label', $label);
		$media_xml->media->addAttribute('group', $type);
		
		// add required for rendering
		$media_xml->media->addAttribute('source', $url);
		
		$media_xml->media->addAttribute('url', $url);
		$media_xml->media->addAttribute('icon', $url);

		// build XML string
		$xml_str = '<moviemasher>';
		$xml_str .= "\n\t" . (string) $media_xml->media->asXML() . "\n";
		
		$children = $media_file_xml->children();
		$z = sizeof($children);
		for ($i = 0; $i < $z; $i++) $xml_str .= "\t" . $children[$i]->asXML() . "\n";
		$xml_str .= '</moviemasher>' . "\n";
		
		// write file
		if (! @file_put_contents($media_file, $xml_str)) $err = 'Problem writing ' . $media_file;
	}
}
if ($err) $attibs = 'get=\'javascript:alert("' .  $err . '");\'';
else $attibs = 'trigger="browser.parameters.group=image"';
print '<moviemasher ' . $attibs . '	/>' . "\n\n";

?>
