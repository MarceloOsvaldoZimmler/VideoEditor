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
This script is called by the Transcoder when processing of an upload has completed and
transferred without error. If we can authenticate the request, we inject a new media
object into the user's data space for the newly uploaded file. If an error is encountered
a 400 header is returned and it is logged, if possible.
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
	$id = (empty($_REQUEST['id']) ? '' : $_REQUEST['id']);
	$uid = (empty($_REQUEST['uid']) ? '' : $_REQUEST['uid']);
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
	$started = (empty($_REQUEST['started']) ? 0 : $_REQUEST['started']);
	log_file('Took ' . (time() - $started) . ' seconds', $dir_log);
	if (! $id ) $err = 'Parameter id required';
	$encoder_original_filename = (empty($config['EncoderOriginalFilename']) ? 'original' : $config['EncoderOriginalFilename']);
	$encoder_fps = (empty($config['EncoderFPS']) ? '10' : $config['EncoderFPS']);
	$encoder_dimensions = (empty($config['EncoderDimensions']) ? '256x144' : $config['EncoderDimensions']);
	$encoder_audio_bitrate = (empty($config['EncoderAudioBitrate']) ? '128' : $config['EncoderAudioBitrate']);
	$encoder_audio_extension = (empty($config['EncoderAudioExtension']) ? 'mp3' : $config['EncoderAudioExtension']);
	$encoder_audio_filename = (empty($config['EncoderAudioFilename']) ? 'audio' : $config['EncoderAudioFilename']);
	$encoder_extension = (empty($config['EncoderExtension']) ? 'jpg' : $config['EncoderExtension']);
	$encoder_waveform_extension = (empty($config['EncoderWaveformExtension']) ? 'png' : $config['EncoderWaveformExtension']);
	$encoder_waveform_name = (empty($config['EncoderWaveformBasename']) ? 'waveform' : $config['EncoderWaveformBasename']);
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
if (! $err) 
{
	$media_extension = (empty($_POST['extension']) ? '' : $_POST['extension']);
	$type = (empty($_POST['type']) ? '' : $_POST['type']);
	switch ($type)
	{
		case 'image':
			$encoder_fps = '1';
			$encoder_extension = $media_extension;
			// intentional fall through to other types
		case 'video':
		case 'audio': break;
		default:
		{
			// Apache must not have delivered a proper mime type to transcoder, so grab from the file path
			$media_dir = (($file == 'Local') ? $dir_host : 'http://' . $host_media . '/') . $path_media . $id . '/';
			$type = mime_type_from_path($media_dir . $encoder_original_filename . '.' . $media_extension);
		}
	}
	if (! ($encoder_extension && $type)) $err = 'Could not determine type and extension';
}
if (! $err) // read in user's media.xml file
{
	$media_file_xml_path = $dir_host . $path_xml . 'media_' . $type . '.xml';
	$media_file_existed = file_exists($media_file_xml_path);
	if ($media_file_existed) $xml_str = file_get($media_file_xml_path);
	else $xml_str = '<moviemasher></moviemasher>' . "\n";
	if (! $xml_str) $err = 'Problem loading ' . $media_file_xml_path;
	else
	{
		$media_file_xml = xml_from_string($xml_str);
		if (! is_object($media_file_xml)) $err = 'Problem parsing ' . $xml_str;
	}
}
if (! $err) // search media.xml file for id - duplicate
{
	$media_tags = $media_file_xml->xpath("//media[@id='$id']");
	if (sizeof($media_tags)) $err = 'Duplicate notification';
}
// add media data to existing media.xml file
if (! $err)
{
	
	$duration = (empty($_POST['duration']) ? '' : $_POST['duration']);
	$label = (empty($_POST['label']) ? '' : $_POST['label']);
	$media_data = array();
	// add required attributes
	$media_data['type'] = $type;
	$media_data['id'] = $id;
	// add standard attributes
	$media_data['label'] = $label;
	$media_data['group'] = $type;
	
	// add required for rendering
	$media_data['source'] = $partial_media_path . $id . '/' . $encoder_original_filename . '.' . $media_extension;
	
	$frame_path = $partial_media_path . $id . '/' . $encoder_dimensions . 'x' . $encoder_fps . '/';
	$audio = 1;
	$did_icon = 0;
	
	switch($type)
	{
		case 'image':
		{
			$frame_path .= '0.' . $encoder_extension;
			$media_data['url'] = $frame_path;
			$media_data['fill'] = 'crop';
			$media_data['icon'] = $frame_path;
			break;
		}
		case 'video':
		{
			$media_data['fill'] = 'crop';
			$frames = floor($duration * $encoder_fps);
			$zero_padding = strlen($frames);
			$media_data['url'] = $frame_path;
			$media_data['fps'] = $encoder_fps;
			$media_data['pattern'] = '%.' . $encoder_extension;
			
			// uncomment the following line to use the mid frame as an icon, instead of the playback preview
			// $media_data['icon'] = $frame_path . str_pad(ceil($frames / 2), $zero_padding, '0', STR_PAD_LEFT) . '.' . $encoder_extension;
			$did_icon = 1;
			$audio = (empty($_POST['audio']) ? '' : $_POST['audio']);
			// intentional fallthrough to audio
		}
		case 'audio':
		{
			if (! $duration) $err = 'Could not determine duration';
			else
			{
				$media_data['duration'] = $duration;
				if ($audio)
				{
					$media_data['audio'] = $partial_media_path . $id . '/' . $encoder_audio_filename . '.' . $encoder_audio_extension;
					$media_data['wave'] = $partial_media_path . $id . '/' . $encoder_waveform_name . '.' . $encoder_waveform_extension;
					if (! $did_icon)
					{
						$media_data['icon'] = $partial_media_path . $id . '/' . $encoder_waveform_name . '.' . $encoder_waveform_extension;
					}
				}
				else $media_data['audio'] = '0'; // put in a zero to indicate that there is no audio
			}
			break;
		}
	}
	// start with an unattributed media tag document
	$writer = xml_writer('media');
	foreach($media_data as $k => $v) $writer->writeAttribute($k, $v);
	$writer->endElement(); // media
	$media_tag = $writer->outputMemory();
}
if (! $err)
{
	// build XML string
	$xml_str = '';
	$xml_str .= '<moviemasher>';
	$xml_str .= "\n\t" . $media_tag . "\n";
	$children = $media_file_xml->children();
	$z = sizeof($children);
	for ($i = 0; $i < $z; $i++) $xml_str .= "\t" . $children[$i]->asXML() . "\n";
	$xml_str .= '</moviemasher>' . "\n";
	// write file
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
else log_file($media_tag, $dir_log);

?>