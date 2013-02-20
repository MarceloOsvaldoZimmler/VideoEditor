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
This script receives the rendered mash from the Transcoder as a video file in $_FILES. If the
file is okay, it's moved to the directory named $id in the user's directory. If an
error is encountered a 400 header is returned and it is logged, if possible.
*/

$err = '';
$dir_log = '';

// load utilities
$include = dirname(__FILE__) . '/include/';
if ((! $err) && (! @include_once($include . 'archiveutils.php'))) $err = 'Problem loading archive utility script';
if ((! $err) && (! @include_once($include . 'authutils.php'))) $err = 'Problem loading authentication utility script';
if ((! $err) && (! @include_once($include . 'configutils.php'))) $err = 'Problem loading configuration utility script';
if ((! $err) && (! @include_once($include . 'idutils.php'))) $err = 'Problem loading id utility script';
if ((! $err) && (! @include_once($include . 'fileutils.php'))) $err = 'Problem loading file utility script';
if ((! $err) && (! @include_once($include . 'httputils.php'))) $err = 'Problem loading http utility script';
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
	$client = (empty($config['Client']) ? 'REST' : strtoupper($config['Client']));
	$file = (empty($config['File']) ? 'Local' : ucwords($config['File']));
	$dir_temporary = config_path(empty($config['DirTemporary']) ? sys_get_temp_dir() : $config['DirTemporary']);
	$dir_host = config_path(empty($config['DirHost']) ? $_SERVER['DOCUMENT_ROOT'] : $config['DirHost']);
	$host = (empty($config['Host']) ? $_SERVER['HTTP_HOST'] : http_get_contents($config['Host']));
	$host_media = (empty($config['HostMedia']) ? $host : http_get_contents($config['HostMedia']));
	$path_cgi = config_path(empty($config['PathCGI']) ? substr(dirname(__FILE__), strlen($dir_host)) : $config['PathCGI']);
	$path_media = config_path(empty($config['PathMedia']) ? '' : $config['PathMedia']);
	$path_media .=  auth_userid() . '/';
	$decoder_extension = (empty($config['DecoderExtension']) ? 'mp4' : $config['DecoderExtension']);
	$decoder_audio_extension = (empty($config['DecoderAudioExtension']) ? 'mp4' : $config['DecoderAudioExtension']);
	$id = (empty($_REQUEST['id']) ? '' : $_REQUEST['id']);
	$job = (empty($_REQUEST['job']) ? '' : $_REQUEST['job']);
	if (! ($id && $job)) $err = 'Parameter id, job required';
	$media_dir = $dir_host;
	$media_dir .=  $path_media . $id . '/';
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
	if (! empty($file['error'])) $err = 'Problem with your file: ' . $file['error'];
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
	set_time_limit(0);
	$tmp_path = $dir_temporary . id_unique();
	$archive_dir = $tmp_path . '/';
	if (! archive_extract($file['tmp_name'], $archive_dir)) $err = 'Could not extract to ' . $archive_dir;
}

// move select files from the archive to media directory
if (! $err)
{
	if (! file_move_extension('jpg', $archive_dir, $media_dir)) $err = 'Could not move jpg files from ' . $archive_dir . ' to ' . $media_dir;
	else if (! file_move_extension($decoder_audio_extension, $archive_dir, $media_dir)) $err = 'Could not move ' . $decoder_audio_extension . ' files from ' . $archive_dir . ' to ' . $media_dir;
	else if (! file_move_extension($decoder_extension, $archive_dir, $media_dir)) $err = 'Could not move ' . $decoder_extension . ' files from ' . $archive_dir . ' to ' . $media_dir;
	// remove the temporary directory we created, and any remaining files (there shouldn't be any)
	file_dir_delete_recursive($tmp_path);
}

if (! $err) // make sure we actually moved what we needed to, and change its permissions
{
	clearstatcache();
	$path = $media_dir . $job . '.jpg';
	if ((! empty($config['MashIcon'])) && (! file_exists($path))) $err = 'Did not generate icon ' . $path;
	else
	{
		$path = $media_dir . $job . '.' . $decoder_extension;
		if (! file_exists($path))
		{
			$path = $media_dir . $job . '.' . $decoder_audio_extension;
			if (! file_exists($path)) $err = 'Did not generate file ' . $path;
		}
	}
}
if ($err)
{
	header('HTTP/1.1: 400 Bad Request');
	header('Status: 400 Bad Request');
	log_file($err, $dir_log);
}
?>