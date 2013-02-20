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
This script receives the encoded asset from Movie Masher Server as an archive file in $_FILES. The
file is extracted with archiveutils.php and selected files in archive are moved to the directory
named $id in the upload directory.
If an error is encountered a 400 header is returned and it is logged, if possible.
*/

$err = '';
$dir_log = '';

// load utilities
$include = dirname(__FILE__) . '/include/';
if ((! $err) && (! @include_once($include . 'archiveutils.php'))) $err = 'Problem loading archive utility script';
if ((! $err) && (! @include_once($include . 'authutils.php'))) $err = 'Problem loading authentication utility script';
if ((! $err) && (! @include_once($include . 'configutils.php'))) $err = 'Problem loading configuration utility script';
if ((! $err) && (! @include_once($include . 'httputils.php'))) $err = 'Problem loading http utility script';
if ((! $err) && (! @include_once($include . 'idutils.php'))) $err = 'Problem loading id utility script';
if ((! $err) && (! @include_once($include . 'logutils.php'))) $err = 'Problem loading log utility script';

if (! $err) // pull in configuration so we can log other errors
{
	$config = config_get();
	$dir_log = config_path(empty($config['DirLog']) ? '' : $config['DirLog']);
	$err = config_error($config);
}
if (! $err) // see if the user is authenticated (does not redirect or exit)
{
	if (! auth_ok_callback($config)) $err = 'Unauthenticated access';
}

if (! $err) // pull in other configuration and check for required input
{
	$dir_temporary = config_path(empty($config['DirTemporary']) ? sys_get_temp_dir() : $config['DirTemporary']);
	$dir_host = config_path(empty($config['DirHost']) ? $_SERVER['DOCUMENT_ROOT'] : $config['DirHost']);
	$path_cgi = config_path(empty($config['PathCGI']) ? substr(dirname(__FILE__), strlen($dir_host)) : $config['PathCGI']);
	$path_media = config_path(empty($config['PathMedia']) ? '' : $config['PathMedia']);
	$encoder_dimensions = (empty($config['EncoderDimensions']) ? '256x144' : $config['EncoderDimensions']);
	$encoder_fps = (empty($config['EncoderFPS']) ? '10' : $config['EncoderFPS']);	$encoder_audio_extension = (empty($config['EncoderAudioExtension']) ? 'mp3' : $config['EncoderAudioExtension']);
	$encoder_audio_filename = (empty($config['EncoderAudioFilename']) ? 'audio' : $config['EncoderAudioFilename']);
	$encoder_extension = (empty($config['EncoderExtension']) ? 'jpg' : $config['EncoderExtension']);
	$encoder_waveform_extension = (empty($config['EncoderWaveformExtension']) ? 'png' : $config['EncoderWaveformExtension']);
	$encoder_waveform_name = (empty($config['EncoderWaveformBasename']) ? 'waveform' : $config['EncoderWaveformBasename']);
}

// check to make sure required parameters have been sent
if (! $err)
{
	$id = (empty($_REQUEST['id']) ? '' : $_REQUEST['id']);
	$extension = (empty($_REQUEST['extension']) ? '' : $_REQUEST['extension']);
	$type = (empty($_REQUEST['type']) ? '' : $_REQUEST['type']);
	if (! ($id && $extension && $type)) $err = 'Required parameter omitted';
}
// make sure $_FILES is set and has item

if ((! $err) && empty($_FILES)) $err = 'No files supplied';

// make sure first item in $_FILES is valid
if (! $err)
{
	foreach($_FILES as $k => $v)
	{
		$file = $_FILES[$k];
		break;
	}
	if (! $file) $err = 'No file supplied';
}
// make sure there wasn't a problem with the upload
if (! $err)
{
	if (! empty($file['error'])) $err = 'Problem with posted file: ' . $file['error'];
	elseif (! is_uploaded_file($file['tmp_name'])) $err = 'Not an uploaded file';
}

// make sure file extension is valid
if (! $err)
{
	$file_name = $file['name'];
	$file_ext = file_extension($file_name);
	if ($file_ext != 'tgz') $err = 'Unsupported extension: ' . $file_ext;
}
if (! $err) // check that we can extract the archive to temp directory
{
	$path_media .=  auth_userid() . '/';
	$media_dir = $dir_host . $path_media . $id . '/';
	if ($type == 'image') $encoder_extension = $extension;

	set_time_limit(0);
	$tmp_path = $dir_temporary . id_unique();
	$archive_dir = $tmp_path . '/';
	if (! archive_extract($file['tmp_name'], $archive_dir)) $err = 'Could not extract to ' . $archive_dir;
}

// move select files from the archive to media directory
if (! $err)
{
	switch($type)
	{
		case 'audio':
		case 'video':
		{
			// move any soundtrack
			$frag = $encoder_audio_filename . '.' . $encoder_audio_extension;
			$media_path = $media_dir . $frag;
			$archive_path = $archive_dir . $frag;
			if (file_exists($archive_path))
			{
				if (! file_safe($media_path)) $err = 'Could not create directories for ' . $media_path;
				elseif (! @rename($archive_path, $media_path)) $err = 'Could not move audio file from ' . $archive_path . ' to ' . $media_path;
				else
				{
					// move any soundtrack waveform graphic
					$frag = $encoder_waveform_name . '.' . $encoder_waveform_extension;
					$archive_path = $archive_dir . $frag;
					$media_path = $media_dir . $frag;
					if (file_exists($archive_path))
					{
						if (! @rename($archive_path, $media_path)) $err = 'Could not move audio file from ' . $archive_path . ' to ' . $media_path;
					}
				}
			}
			break;
		}
	}

	if (! $err)
	{
		$frame_extension = $extension;
		switch($type)
		{
			case 'video':
				$frame_extension = 'jpg'; // otherwise use image's original extension (eg. png)
			case 'image':
			{
				if ($type == 'image') $encoder_fps = '1';
				// move any frames
				$archive_path = $archive_dir . $encoder_dimensions . 'x' . $encoder_fps;
				if (file_exists($archive_path))
				{
					$media_path = $media_dir . $encoder_dimensions . 'x' . $encoder_fps;
					if (! file_move_extension($frame_extension, $archive_path, $media_path)) $err = 'Could not move ' . $frame_extension . ' files from ' . $archive_path . ' to ' . $media_path;
				}
				break;
			}
		}
	}
	if (! $err)
	{
		// move any meta data
		$frag = 'meta/';
		$archive_path = $archive_dir . $frag;
		if (file_exists($archive_path))
		{
			$media_path = $media_dir . $frag;
			if (! file_move_extension('txt', $archive_path, $media_path, TRUE)) $err = 'Could not move txt files from ' . $archive_path . ' to ' . $media_path;
		}
	}
	// remove the temporary directory we created, and any remaining files (there shouldn't be any)
	file_dir_delete_recursive($tmp_path);
}
if ($err)
{
	header('HTTP/1.1: 400 Bad Request');
	header('Status: 400 Bad Request');
	log_file($err, $dir_log);
}
else log_file($media_path, $dir_log);
?>