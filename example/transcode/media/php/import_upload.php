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
This script is called from Movie Masher Applet.
The uploaded file is in _FILES['Filedata'], but the script just grabs the first key.
If the file uploads correctly and its extension is acceptable, the following happens:
	* the base file name is changed to 'media'
	* a directory is created in the user's directory, the ID is used for the name
	* the file is moved to this directory, and a 'meta' directory is created alongside it
	* extension, type and name properties are cached to the 'meta' directory for later use
The media ID is passed as a parameter to import_api.php, by setting the 'url' attribute in response.
If an error is encountered it is displayed in a javascript alert, by setting the 'get' attribute.
If possible, the response to client is logged.
*/

$err = '';
$dir_log = '';

// load utilities
$include = dirname(__FILE__) . '/include/';
if ((! $err) && (! @include_once($include . 'configutils.php'))) $err = 'Problem loading configuration utility script';
if ((! $err) && (! @include_once($include . 'logutils.php'))) $err = 'Problem loading log utility script';
if ((! $err) && (! @include_once($include . 'mimeutils.php'))) $err = 'Problem loading mime utility script';
if (! $err) // pull in configuration so we can log other errors
{
	$config = config_get();
	$dir_log = config_path(empty($config['DirLog']) ? '' : $config['DirLog']);
	$err = config_error($config);
}

if (! $err) // make sure required configuration options have been set
{
	$encoder_original_filename = (empty($config['EncoderOriginalFilename']) ? 'original' : $config['EncoderOriginalFilename']);
	$dir_log = config_path(empty($config['DirLog']) ? '' : $config['DirLog']);
	$dir_host = config_path(empty($config['DirHost']) ? $_SERVER['DOCUMENT_ROOT'] : $config['DirHost']);
	$path_cgi = config_path(empty($config['PathCGI']) ? substr(dirname(__FILE__), strlen($dir_host)) : $config['PathCGI']);
	$path_media = config_path(empty($config['PathMedia']) ? '' : $config['PathMedia']);
}

if (! $err) // check to make sure required parameters were sent
{
	$id = (empty($_REQUEST['id']) ? '' : $_REQUEST['id']);
	$u = (empty($_REQUEST['u']) ? '' : $_REQUEST['u']);
	$type = (empty($_REQUEST['type']) ? '' : $_REQUEST['type']);
	$extension = (empty($_REQUEST['extension']) ? '' : $_REQUEST['extension']);
	if (! ($u && $id && $extension && $type)) $err = 'Required parameters omitted';
}

if (! $err) // make sure $_FILES populated
{
	if (empty($_FILES) || empty($_FILES['Filedata'])) $err = 'No file was uploaded';
}
if (! $err) // make sure file is valid
{
	$file = $_FILES['Filedata'];
	if ($file['error']) $err = $file['error'];
	else if (! is_uploaded_file($file['tmp_name'])) $err = 'Error uploading your file';
}
if (! $err) // make sure we can determine mime type and extension from file name
{
	$file_name = stripslashes($file['name']);
	$file_size = $file['size'];
	$file_extension = file_extension($file_name);
	$mime = mime_from_path($file_name);
	if (! ($mime && $file_extension)) $err = 'Could not determine mime type or extension';
}
if (! $err) // make sure mime type is supported
{
	$file_type = mime_type($mime);
	switch($file_type)
	{
		case 'audio':
		case 'video':
		case 'image': break;
		default: $err = 'Only audio, image and video files supported';
	}
}
if (! $err) // make sure type and extension match
{
	if (($type != $file_type) || ($extension != $file_extension)) $err = 'Internal error';
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
if (! $err)  // try to move upload into its media directory and change permissions
{
	$path_media .=  $u . '/';
	$path = $dir_host . $path_media . $id . '/' . $encoder_original_filename . '.' .  $file_extension;
	if (! file_safe($path)) $err = 'Problem creating media directory';
	else if (! @move_uploaded_file($file['tmp_name'], $path)) $err = 'Problem moving file';
	else if (! @chmod($path, 0777)) $err = 'Problem setting permissions of media: ' . $path;
	else log_file('Saved to: ' . $path, $dir_log);
}

// build tag, print and log, if possible
$xml = '<moviemasher ';
if ($err) $xml .= 'progress="100" status="" get=\'javascript:alert("' .  $err . '");\' ';
else
{
	// get CGI control to load import_api.php in one second
	$xml .= "url='media/php/import_api.php?id=$id&amp;type=$type&amp;extension=$extension&amp;label=" . urlencode($file['name']) . "' ";
	$xml .= 'progress="1" status="Preparing..." delay="1" ';
}
$xml .= "/>\n\n";

print $xml . "

";
if (! empty($log_responses)) log_file($xml, $dir_log);

?>