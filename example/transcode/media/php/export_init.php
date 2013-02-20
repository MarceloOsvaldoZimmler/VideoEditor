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
This script is called directly from Movie Masher Applet, in response to a click on the Render button.
The XML formatted mash data has already been saved to PathMedia/{auth_userid()}/$id.xml
This script then generates a decode job XML payload and posts it to the Transcoder.
The job ID is passed to export_monitor.php, by setting the 'url' attribute in response.
If an error is encountered it is displayed in a javascript alert, by setting the 'get' attribute.
If possible and options permit, responses and requests are logged.
*/

$err = '';
$dir_log = '';

// load utilities
$include = dirname(__FILE__) . '/include/';
if ((! $err) && (! @include_once($include . 'authutils.php'))) $err = 'Problem loading authentication utility script';
if ((! $err) && (! @include_once($include . 'apiutils.php'))) $err = 'Problem loading api utility script';
if ((! $err) && (! @include_once($include . 'urlutils.php'))) $err = 'Problem loading url utility script';
if ((! $err) && (! @include_once($include . 'mashutils.php'))) $err = 'Problem loading log utility script';

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
if (! $err) // read configuration (best to ignore this and set options in private/moviemasher.ini)
{
	$client = (empty($config['Client']) ? 'REST' : strtoupper($config['Client']));
	$file = (empty($config['File']) ? 'Local' : ucwords($config['File']));
	$dir_temporary = config_path(empty($config['DirTemporary']) ? sys_get_temp_dir() : $config['DirTemporary']);
	$dir_host = config_path(empty($config['DirHost']) ? $_SERVER['DOCUMENT_ROOT'] : $config['DirHost']);
	$dir_log = config_path(empty($config['DirLog']) ? '' : $config['DirLog']);
	$host = (empty($config['Host']) ? $_SERVER['HTTP_HOST'] : http_get_contents($config['Host']));
	$host_media = (empty($config['HostMedia']) ? $host : http_get_contents($config['HostMedia']));
	$path_cgi = config_path(empty($config['PathCGI']) ? substr(dirname(__FILE__), strlen($dir_host)) : $config['PathCGI']);
	$path_site = config_path(empty($config['PathSite']) ? config_path(dirname(dirname($path_cgi))) : $config['PathSite']);
	$path_media = config_path(empty($config['PathMedia']) ? '' : $config['PathMedia']);
	$path_media .= auth_userid() . '/';
	$path_xml = config_path(empty($config['PathXML']) ? '' : $config['PathXML']);
	$path_xml .=  auth_userid() . '/';
	
	$decoder_extension = (empty($config['DecoderExtension']) ? 'mp4' : $config['DecoderExtension']);
	$decoder_audio_codec = (empty($config['DecoderAudioCodec']) ? 'aac' : $config['DecoderAudioCodec']);
	$decoder_switches = (empty($config['DecoderSwitches']) ? '' : $config['DecoderSwitches']);
	
	$decoder_metatitle = (empty($config['DecoderMetatitle']) ? '' : $config['DecoderMetatitle']);
	$decoder_video_codec = (empty($config['DecoderVideoCodec']) ? 'libx264' : $config['DecoderVideoCodec']);
	$decoder_video_bitrate = (empty($config['DecoderVideoBitrate']) ? '2000' : $config['DecoderVideoBitrate']);
	$decoder_dimensions = (empty($config['DecoderDimensions']) ? '512x288' : $config['DecoderDimensions']);
	$decoder_fps = (empty($config['DecoderFPS']) ? '30' : $config['DecoderFPS']);
	$decoder_audio_frequency = (empty($config['DecoderAudioFrequency']) ? '44100' : $config['DecoderAudioFrequency']);
	$decoder_audio_bitrate = (empty($config['DecoderAudioBitrate']) ? '128' : $config['DecoderAudioBitrate']);
	
	$access_key_id =  (empty($config['AWSAccessKeyID']) ? '' : $config['AWSAccessKeyID']);
	$secret_access_key =  (empty($config['AWSSecretAccessKey']) ? '' : $config['AWSSecretAccessKey']);
	$keypair_private = (empty($config['KeypairPrivate']) ? '' : $config['KeypairPrivate']);

	$encoder_fps = (empty($config['EncoderFPS']) ? '10' : $config['EncoderFPS']);
	$encoder_dimensions = (empty($config['EncoderDimensions']) ? '256x144' : $config['EncoderDimensions']);


	if (($client == 'SQS') || ($file == 'S3'))
	{
		if ($file == 'S3') $s3_bucket = (empty($config['S3Bucket']) ? '' : $config['S3Bucket']);
		if ($client == 'SQS') $queue_url =  (empty($config['SQSQueueURLSend']) ? '' : $config['SQSQueueURLSend']);
	}
	if ($client == 'REST') $rest_endpoint = config_path(empty($config['RESTEndPoint']) ? '' : $config['RESTEndPoint']);

	$log_requests = (empty($config['LogRequests']) ? '' : $config['LogRequests']);
	$log_responses = (empty($config['LogResponses']) ? '' : $config['LogResponses']);
	$log_transcoder_requests = (empty($config['LogTranscoderRequests']) ? '' : $config['LogTranscoderRequests']);
	$log_transcoder_responses = (empty($config['LogTranscoderResponses']) ? '' : $config['LogTranscoderResponses']);
	if ($log_requests) log_file($_SERVER['QUERY_STRING'], $dir_log);

	$id = (empty($_REQUEST['id']) ? '' : $_REQUEST['id']);
	if (! $id ) $err = 'Parameter id required';
}
if (! $err) // try to read in mash XML file
{
	clearstatcache();
	$mash_xml_path = $path_xml . $id . '.xml';
	$mash_string = '<moviemasher>
  <mash width="16" height="9" label="Audio" quantize="44100" id="4F807AB5-52DF-ABA7-49F7-84A3D757B80D">
    <clip type="audio" id="89BD8E30-109C-4D52-ABC5-385E3B44F230" track="1" start="0" volume="0,50,100,50" audio="http://s3.amazonaws.com/static.moviemasher.com/doug/89BD8E30-109C-4D52-ABC5-385E3B44F230/audio.mp3" trimend="0" label="G_swing-8-bar-G6_85.mp3" trimstart="0" length="996660" lengthseconds="22.6"/>
    <clip type="audio" id="07BECF05-80ED-4C0A-9C5A-73FF6273018E" track="2" start="0" volume="0,50,100,50" audio="http://s3.amazonaws.com/static.moviemasher.com/doug/07BECF05-80ED-4C0A-9C5A-73FF6273018E/audio.mp3" trimend="0" label="G_swing_4-bar_85.mp3" trimstart="0" length="498330" lengthseconds="11.3" />
    <media type="audio" id="89BD8E30-109C-4D52-ABC5-385E3B44F230" label="G_swing-8-bar-G6_85.mp3" group="audio" source="http://s3.amazonaws.com/static.moviemasher.com/doug/89BD8E30-109C-4D52-ABC5-385E3B44F230/original.mp3" duration="22.66" audio="http://s3.amazonaws.com/static.moviemasher.com/doug/89BD8E30-109C-4D52-ABC5-385E3B44F230/audio.mp3" wave="http://s3.amazonaws.com/static.moviemasher.com/doug/89BD8E30-109C-4D52-ABC5-385E3B44F230/waveform.png" icon="http://s3.amazonaws.com/static.moviemasher.com/doug/89BD8E30-109C-4D52-ABC5-385E3B44F230/waveform.png"/>
    <media type="audio" id="07BECF05-80ED-4C0A-9C5A-73FF6273018E" label="G_swing_4-bar_85.mp3" group="audio" source="http://s3.amazonaws.com/static.moviemasher.com/doug/07BECF05-80ED-4C0A-9C5A-73FF6273018E/original.mp3" duration="11.35" audio="http://s3.amazonaws.com/static.moviemasher.com/doug/07BECF05-80ED-4C0A-9C5A-73FF6273018E/audio.mp3" wave="http://s3.amazonaws.com/static.moviemasher.com/doug/07BECF05-80ED-4C0A-9C5A-73FF6273018E/waveform.png" icon="http://s3.amazonaws.com/static.moviemasher.com/doug/07BECF05-80ED-4C0A-9C5A-73FF6273018E/waveform.png"/>
  </mash>
</moviemasher>
';
    $mash_string = file_get($dir_host . $mash_xml_path);
	if (! $mash_string) $err = 'Could not read mash xml file';
}
if (! $err) // try to parse mash XML
{
	$mash_xml = xml_from_string($mash_string);
	if (! $mash_xml) $err = 'Could not parse mash xml file';
}
if (! $err) // try to analyze mash 
{
	$mash_info = mash_info($mash_xml);
	if (! empty($mash_info['error'])) 
	{
		log_file(print_r($mash_info, 1), $dir_log);
		$err = $mash_info['error'];
	}
	else if ((! empty($mash_info['cache_mash_urls'])) && (! empty($mash_info['flashframes']))) $err = 'Modular media and mash media cannot be used together';
}
if (! $err) // build job request
{
	$inputs = array();
	$found_audio = $mash_info['has_audio'];
	$found_video = $mash_info['has_video'];
	$mash_transfer = array('Host' => $host, 'Path' => $path_site . '{Transfer.File}', 'method' => 'get', 'Type' => 'http');
	$type = 'video';
	if (! empty($mash_info['cache_mash_urls']))
	{
		foreach($mash_info['clips'] as $clip)
		{
			$input = array('Type' => $clip['type']);
			if ($clip['type'] != 'image') // it can be trimmed
			{
				$muted = ($clip['volume'] == MASH_VOLUME_MUTE);
				if ($muted)
				{
					if ($clip['type'] == 'audio') continue; // ignore muted audio
					$input['NoAudio'] = '1';
				}
				else $input['Volume'] = $clip['volume'];
				if ($clip['trimstart']) $input['Trim'] = floatval($clip['trimstart']) / floatval($mash_info['quantize']);
			}
			if ($clip['type'] == 'mash')
			{
				parse_str(parse_url($clip['url'], PHP_URL_QUERY), $query);
				
				$path = $dir_host . $path_xml . $query['id'] . '.xml';
				$mash_clip_string = file_get($path);
				$mash_clip_xml = xml_from_string($mash_clip_string);
				$mash_clip_info = mash_info($mash_clip_xml, $clip['trimstart'], $clip['length']);
				if ((! $muted) && $mash_clip_info['has_audio']) $found_audio = TRUE;
				if ($mash_clip_info['has_video']) $found_video = TRUE;
				else if ($muted) continue; // ignore muted audio only mashes
				$input['Body'] = $mash_clip_string;
				$input['Transfer'] = $mash_transfer;
			}
			else 
			{
				$input['URL'] = $clip['source'];
				if (! url_is_http($input['URL'])) $input['URL'] = 'http://' . $host . '/' . $path_site . $input['URL'];
			}
			if ($clip['type'] == 'audio') $input['Loops'] = $clip['loops'];		
			else if (! empty($clip['fill'])) $input['Fill'] = $clip['fill'];		
			$input['Length'] = floatval($clip['length']) / floatval($mash_info['quantize']);		
			$input['Start'] = floatval($clip['start']) / floatval($mash_info['quantize']);		
			$inputs[] = $input;
		}
	}
	else 
	{
		$input = array('Type' => 'mash', 'Body' => $mash_string);
		$input['Transfer'] = $mash_transfer;
		$inputs[] = $input;
	}
	if (! $found_video)
	{
		$type = 'audio';
		$decoder_extension = (empty($config['DecoderAudioExtension']) ? 'mp3' : $config['DecoderAudioExtension']);
		$decoder_switches = (empty($config['DecoderAudioSwitches']) ? '' : $config['DecoderAudioSwitches']);
		$decoder_audio_codec = (empty($config['DecoderAudioAudioCodec']) ? 'libmp3lame' : $config['DecoderAudioAudioCodec']);
	}
	
	// start Job tag
	$job_writer = xml_writer('Job');
		
	// construct shared transfer data
	$transfer = array('Host' => $host, 'Type' => 'http', 'ParameterName' => array('id'), 'ParameterValue' => array($id));
	auth_data($transfer, $config); // adds what is needed to authenticate callback
	
	// construct text output shared by notification callbacks
	$progress = array('Percent' => '{Job.Percent}', 'PercentEstimate' => '{Job.PercentEstimate}', 'PercentDetail' => '{Job.PercentDetail}', 'Status' => '{Job.Status}');
	$body = array('Response' => array('Progress' => $progress, 'Version' => '{Job.Version}'));
	$error_body = array('Response' => array('WarningLog' => '{Job.Warnings}', 'ErrorLog' => '{Job.Errors}', 'Error' => '{Job.Error}', 'Version' => '{Job.Version}'));
	$output = array('Type' => 'text', 'Payload' => '1', 'Transfer' => &$transfer);
		
	// add output for job error abort notification
	$transfer['Path'] = $path_cgi . 'export_error.php';
	$output['Trigger'] = 'error';
	$output['Body'] = $error_body;
	xml_write($job_writer, array('Output' => $output));
	$output['Body'] = $body;
	
	if ($client == 'SQS') // add output for job progress notifications
	{
		$transfer['Path'] = $path_cgi . 'export_progress.php';
		$output['Trigger'] = 'progress';
		xml_write($job_writer, array('Output' => $output));
	}
	// add output for job successful done notification
	// 'done' needs job ID and extension to determine rendered file name
	$transfer['ParameterName'][] = 'job';
	$transfer['ParameterValue'][] = '{Job.ID}';
	$transfer['ParameterName'][] = 'uid';
	$transfer['ParameterValue'][] = auth_userid();
	$transfer['Path'] = $path_cgi . 'export_done.php';
	$transfer['ParameterName'][] = 'extension';
	$transfer['ParameterValue'][] = $decoder_extension;
	$transfer['ParameterName'][] = 'started';
	$transfer['ParameterValue'][] = time();

	$output['Trigger'] = 'done';
	$output['Required'] = '1';
	
	xml_write($job_writer, array('Output' => $output));

	// add transfer main output and any others that don't have one
	if ($file == 'Local')
	{
		// we can just use the default callback transfer with different path
		$transfer['Path'] = $path_cgi . 'export_transfer.php';		
		$transfer['ArchiveExtension'] = 'tgz';
	}
	else // S3 needs its own transfer
	{
		$transfer = array('Host' => $host_media, 'Path' => $path_media . $id . '/{Transfer.File}', 'Method' => 'put', 'Type' => 'http', 'SeparateRequests' => '1');
		$transfer['HeaderName'] = array('Authorization', 'x-amz-acl', 'Content-Type', 'Content-MD5', 'Date');
		$transfer['HeaderValue'] = array('AWS {AccessKey.Identifier}:{Transfer.Signature}', 'public-read', '{Transfer.Mime}', '{Transfer.MD5}', '{Transfer.Date}');
		$transfer['Retries'] = '3'; // sometimes S3 produces an error
		
		$value = array('{Transfer.MD5}', '{Transfer.Mime}', '{Transfer.Date}');
		$value[] = 'x-amz-acl:public-read';
		// this does the same thing as preceeding line, but for ALL x-amz-* headers added above
		// $value[] = array('KeyJoin' => array('Value' => ':', 'KeySort' => array('KeyLowerCase' => array('MatchPairs' => '^x-amz-'))));
		
		$sig_path = '/';
		if (substr($path_media, 0, strlen($s3_bucket)) != $s3_bucket) $sig_path .= $s3_bucket . '/';
		$sig_path .= '{Transfer.Path}';
		$value[] = $sig_path;
		
		$join = array('NewLine' => '', 'UpperCase' => '{Transfer.Method}', 'Value' => $value);
		$hmac = array('Join' => $join, 'Value' => '{AccessKey.Secret}');
		$transfer['Signature'] = array('Base64Encode' => array('HMACSHA1' => $hmac));
	}
	xml_write($job_writer, array('Transfer' => $transfer));
	
	// add Inputs
	$input_count = sizeof($inputs);
	for ($input_index = 0; $input_index < $input_count; $input_index++)
	{
		$input = $inputs[$input_index];
		xml_write($job_writer, array('Input' => $input));
	}

	// add Output for rendered video or audio file, with no transfer tag of its own
	$output = array('Type' => $type);
	$output['Extension'] = $decoder_extension;
	$output['Basename'] = '{Job.ID}';
	$output['Switches'] = $decoder_switches;
		
	if ($decoder_metatitle && $mash_info['label']) $output['Switches'] .= ' -metadata ' . $decoder_metatitle . '="' . $mash_info['label'] . '"';
	
	if ($type == 'video')
	{
		$output['VideoCodec'] = $decoder_video_codec;
		$output['VideoBitrate'] = $decoder_video_bitrate;
		$output['FPS'] = $decoder_fps;
		$output['Dimensions'] = $decoder_dimensions;
	}
	else $output['NoVideo'] = '1';
	if ($found_audio)
	{
		$output['AudioCodec'] = $decoder_audio_codec;
		$output['AudioBitrate'] = $decoder_audio_bitrate;
		$output['Frequency'] = $decoder_audio_frequency;
	}
	else $output['NoAudio'] = '1';
	xml_write($job_writer, array('Output' => $output));

	if (($type == 'video') && (! empty($config['MashIcon'])))
	{	// add Output for icon of rendered video, with no transfer tag of its own
		$output = array('Type' => 'image');
		$output['Trim'] = '50%'; // take snapshot at midpoint
		$output['Basename'] = '{Job.ID}';
		$output['Dimensions'] = $encoder_dimensions;
		xml_write($job_writer, array('Output' => $output));
	}
	$job_writer->endElement(); // Job

	$job_xml_string = $job_writer->outputMemory();

	$result = api_authenticated_job($job_xml_string, $config);
	if (! empty($result['error'])) $err = $result['error'];
	else $job_xml_string = $result['xml'];
}
/* uncomment the block below to log job XML for testing, while not posting it to transcoder
if (! $err) // testing
{
	log_file($job_xml_string, $dir_log);
	$err = 'Testing - check log for request that would have been made';
}
*/
if (! $err) // request is all signed, go ahead and make it
{
	log_file($job_xml_string, $dir_log);
	$result = api_queue_job($job_xml_string, $config);
	if (! empty($result['error'])) $err = $result['error'];
	else $job_id = $result['id'];
}
if (! $err) $xml = '<moviemasher url="media/php/export_monitor.php?id=' . $id . '&amp;job=' . $job_id . '" progress="1" status="Queueing..." delay="5" />';
else $xml = '<moviemasher progress="100" status="" get=\'javascript:alert("' .  $err . '");\' />';
print $xml . "\n\n";
if (! empty($log_responses)) log_file($xml, $dir_log);
?>