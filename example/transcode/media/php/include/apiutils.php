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
Required directly by example scripts that access the Transcoder API
*/

include_once(dirname(__FILE__) . '/configutils.php');
include_once(dirname(__FILE__) . '/authutils.php');
include_once(dirname(__FILE__) . '/httputils.php');
include_once(dirname(__FILE__) . '/mimeutils.php');
include_once(dirname(__FILE__) . '/logutils.php');
include_once(dirname(__FILE__) . '/idutils.php');
include_once(dirname(__FILE__) . '/sigutils.php');

function api_import($input = array(), $output = array(), $config = array())
{
	$result = array();
	if (! $config) $config = config_get();
	$result['error'] = config_error($config);

	// create import job xml
	if (empty($result['error'])) $result = api_job_import($input, $output, $config);
	
	// authenticate import job xml
	if (empty($result['error'])) $result = api_authenticated_job($result['xml'], $config);
	
	// queue authenticated job
	if (empty($result['error'])) $result = api_queue_job($result['xml'], $config);
	
	return $result;
}

function api_job_import($input = array(), $output = array(), $config = array())
{
	$result = array();
	if (! $config) $config = config_get();
	$err = config_error($config);
	
	if (! $err) // pull in other configuration and check for required input
	{
		$client = (empty($config['Client']) ? 'REST' : strtoupper($config['Client']));
		$file = (empty($config['File']) ? 'Local' : ucwords($config['File']));
		$dir_host = config_path(empty($config['DirHost']) ? $_SERVER['DOCUMENT_ROOT'] : $config['DirHost']);
		$host = (empty($config['Host']) ? $_SERVER['HTTP_HOST'] : http_get_contents($config['Host']));
		$host_media = (empty($config['HostMedia']) ? $host : http_get_contents($config['HostMedia']));
		$path_cgi = config_path(empty($config['PathCGI']) ? substr(dirname(__FILE__), strlen($dir_host)) : $config['PathCGI']);
		$path_media = config_path(empty($config['PathMedia']) ? '' : $config['PathMedia']);
	
		$encoder_audio_bitrate = (empty($config['EncoderAudioBitrate']) ? '128' : $config['EncoderAudioBitrate']);
		$encoder_audio_extension = (empty($config['EncoderAudioExtension']) ? 'mp3' : $config['EncoderAudioExtension']);
		$encoder_audio_filename = (empty($config['EncoderAudioFilename']) ? 'audio' : $config['EncoderAudioFilename']);
		$encoder_audio_frequency = (empty($config['EncoderAudioFrequency']) ? '44100' : $config['EncoderAudioFrequency']);
		$encoder_extension = (empty($config['EncoderExtension']) ? 'jpg' : $config['EncoderExtension']);
		$encoder_image_quality = (empty($config['EncoderImageQuality']) ? '1' : $config['EncoderImageQuality']);
		$encoder_original_filename = (empty($config['EncoderOriginalFilename']) ? 'original' : $config['EncoderOriginalFilename']);
		$encoder_waveform_backcolor = (empty($config['EncoderWaveformBackcolor']) ? 'FFFFFF' : $config['EncoderWaveformBackcolor']);
		$encoder_waveform_dimensions = (empty($config['EncoderWaveformDimensions']) ? '8000x32' : $config['EncoderWaveformDimensions']);
		$encoder_waveform_extension = (empty($config['EncoderWaveformExtension']) ? 'png' : $config['EncoderWaveformExtension']);
		$encoder_waveform_forecolor = (empty($config['EncoderWaveformForecolor']) ? '000000' : $config['EncoderWaveformForecolor']);
		$encoder_waveform_name = (empty($config['EncoderWaveformBasename']) ? 'waveform' : $config['EncoderWaveformBasename']);
	
		$access_key_id =  (empty($config['AWSAccessKeyID']) ? '' : $config['AWSAccessKeyID']);
		$secret_access_key =  (empty($config['AWSSecretAccessKey']) ? '' : $config['AWSSecretAccessKey']);
		$keypair_private = (empty($config['KeypairPrivate']) ? '' : $config['KeypairPrivate']);
	
		if (($client == 'SQS') || ($file == 'S3'))
		{
			if ($file == 'S3')
			{
				$s3_bucket = (empty($config['S3Bucket']) ? '' : $config['S3Bucket']);
			}
			if ($client == 'SQS') $queue_url =  (empty($config['SQSQueueURLSend']) ? '' : $config['SQSQueueURLSend']);
		}
		if ($client == 'REST') $rest_endpoint = config_path(empty($config['RESTEndPoint']) ? '' : $config['RESTEndPoint']);
		
		$user_id = (isset($output['UserID']) ? $output['UserID'] : auth_userid());
		if ($user_id) $path_media .= $user_id . '/';
		
		// make sure required input parameters have been set
		$id = (empty($input['id']) ? '' : $input['id']);
		$url = (empty($input['url']) ? '' : $input['url']);	
		$extension = (empty($input['extension']) ? file_extension($url) : $input['extension']);
		$type = (empty($input['type']) ? mime_type_from_extension($extension) : $input['type']);
		$label = (empty($input['label']) ? ($url ? basename($url, '.' . $extension) : $id) : $input['label']);

		if (! ($id && $label && $extension && $type)) $err = 'Required parameter omitted';
	}
	if (! $err) // all input now in local variables, so create and send job to transcoder
	{
		if ($type != 'audio') $encoder_dimensions = (empty($config['EncoderDimensions']) ? '256x144' : $config['EncoderDimensions']);
		if ($type == 'video') $encoder_fps = (empty($config['EncoderFPS']) ? '10' : $config['EncoderFPS']);
		
		// start Job tag
		$job_writer = xml_writer('Job');
	
		// set default transfer type and host, for CGI callbacks
		xml_write($job_writer, array('TransferType' => 'http'));
		xml_write($job_writer, array('TransferHost' => $host));
		
		// construct shared transfer data
		$transfer = array('Inherit' => '1');
		
		if ($file == 'Local')
		{
			$transfer['Path'] = $path_cgi . 'import_transfer.php';
			$transfer['ParameterName'] = array();
			$transfer['ParameterValue'] = array();
			$transfer['ParameterName'][] = 'id';
			$transfer['ParameterValue'][] = $id;
			$transfer['ParameterName'][] = 'type';
			$transfer['ParameterValue'][] = $type;
			$transfer['ParameterName'][] = 'extension';
			$transfer['ParameterValue'][] = $extension;
			
			auth_data($transfer, $config); // adds what is needed to authenticate callback
		}
		else // s3 upload
		{
			$transfer['Host'] = $host_media;
			$transfer['Path'] = $path_media . $id . '/{Transfer.File}';
			$transfer['SeparateRequests'] = '1'; // one request per file
			$transfer['Retries'] = '3'; // sometimes S3 produces an error, so try a few times
			$transfer['Method'] = 'put';
			$transfer['HeaderName'] = array('Authorization', 'x-amz-acl', 'Content-Type', 'Content-MD5', 'Date');
			$transfer['HeaderValue'] = array('AWS {AccessKey.Identifier}:{Transfer.Signature}', 'public-read', '{Transfer.Mime}', '{Transfer.MD5}', '{Transfer.Date}');
			
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
		// see if an archive is required (only tgz is supported currently)
		if ($file == 'Local') $transfer['ArchiveExtension'] = 'tgz';
		xml_write($job_writer, array('Transfer' => $transfer));
			
		// add the uploaded file as the only Input
		$transfer = array('Inherit' => '1');
		if ($url) // it's a remote file
		{
			$parsed_url = parse_url($url);
			$transfer['Path'] = $parsed_url['path'];
			$transfer['Host'] = $parsed_url['host'];
		}
		else
		{
			$transfer['Path'] = $path_media . $id . '/' . $encoder_original_filename . '.' . $extension;
			$transfer['Host'] = (($file == 'Local') ? $host : $host_media);
		}
		
		xml_write($job_writer, array('Input' => array('Type' => $type, 'Transfer' => $transfer)));
		
		// construct shared transfer data
		$transfer = array('Host' => $host, 'Type' => 'http', 'ParameterName' => array('id'), 'ParameterValue' => array($id));
		$transfer['ParameterName'][] = 'job';
		$transfer['ParameterValue'][] = '{Job.ID}';
		if ($user_id)
		{
			$transfer['ParameterName'][] = 'uid';
			$transfer['ParameterValue'][] = $user_id;
		}
		auth_data($transfer, $config); // adds what is needed to authenticate callback
		
		// construct text output shared by notification callbacks
		$progress = array('Percent' => '{Job.Percent}', 'PercentEstimate' => '{Job.PercentEstimate}', 'Status' => '{Job.Status}');
		$body = array('Response' => array('Progress' => $progress, 'Version' => '{Job.Version}'));
		$error_body = array('Response' => array('WarningLog' => '{Job.Warnings}', 'ErrorLog' => '{Job.Errors}', 'Error' => '{Job.Error}', 'Version' => '{Job.Version}'));
		$output_tag = array('Type' => 'text', 'Payload' => '1', 'Body' => $body, 'Transfer' => &$transfer);
			
		// add output for job error abort notification
		$transfer['Path'] = $path_cgi . 'import_error.php';
		$output_tag['Trigger'] = 'error';
		$output_tag['Body'] = $error_body;
		xml_write($job_writer, array('Output' => $output_tag));
		$output_tag['Body'] = $body;
		
		if (($client == 'SQS') && (! empty($output['IncludeProgress']))) // add output for job progress notifications
		{
			$transfer['Path'] = $path_cgi . 'import_progress.php';
			$output_tag['Trigger'] = 'progress';
			xml_write($job_writer, array('Output' => $output_tag));
		}
		
		// add output for job successful done notification
		$transfer['Path'] = $path_cgi . 'import_done.php';
		$transfer['ParameterName'][] = 'started';
		$transfer['ParameterValue'][] = time();
		
		// add variables we'll need to ingest media from done notification
		$transfer['VariableName'] = array();
		$transfer['VariableValue'] = array();
		$transfer['VariableName'][] = 'label';
		$transfer['VariableValue'][] = $label;
		$transfer['VariableName'][] = 'extension';
		$transfer['VariableValue'][] = $extension;
		$transfer['VariableName'][] = 'type';
		$transfer['VariableValue'][] = '{Input.Type}';
		if ($type != 'image') 
		{
			$transfer['VariableName'][] = 'audio';
			$transfer['VariableValue'][] = '{Input.Audio}';
			$transfer['VariableName'][] = 'duration';
			$transfer['VariableValue'][] = '{Input.Duration}';
		}
		$output_tag['Trigger'] = 'done';
		$output_tag['Required'] = '1'; 
		$output_tag['Body'] = ''; 
		xml_write($job_writer, array('Output' => $output_tag));
	
		if ($type == 'image')
		{
			// add output for image file
			$output_tag = array('Type' => 'image', 'Basename' => $encoder_dimensions . 'x1/0', 'Dimensions' => $encoder_dimensions, 'Extension' => $extension, 'ImageQuality' => $encoder_image_quality, 'NoAudio' => '1');
			xml_write($job_writer, array('Output' => $output_tag));
		}
		else
		{
			// add output for audio/video file
			$output_tag = array('Type' => 'audio', 'AudioBitrate' => $encoder_audio_bitrate, 'Basename' => $encoder_audio_filename, 'Extension' => $encoder_audio_extension, 'NoVideo' => '1', 'Frequency' => $encoder_audio_frequency);
			xml_write($job_writer, array('Output' => $output_tag));
	
			// add output for waveform file
			$output_tag = array('Type' => 'waveform', 'Forecolor' => $encoder_waveform_forecolor, 'Backcolor' => $encoder_waveform_backcolor, 'Basename' => $encoder_waveform_name, 'Dimensions' => $encoder_waveform_dimensions, 'Extension' => $encoder_waveform_extension);
			xml_write($job_writer, array('Output' => $output_tag));
		}
		if ($type == 'video')
		{
			// add output for sequence files
			$output_tag = array('Type' => 'sequence', 'FPS' => $encoder_fps, 'ImageQuality' => $encoder_image_quality, 'Basename' => $encoder_dimensions . 'x' . $encoder_fps, 'Dimensions' => $encoder_dimensions);
			xml_write($job_writer, array('Output' => $output_tag));
		}
		$job_writer->endElement(); // Job
		$job_xml_string = $job_writer->outputMemory();
	}
	if ($err) $result['error'] = $err;
	else $result['xml'] = $job_xml_string;
	return $result;
}
function api_authenticated_job($job_xml_string, $config = array())
{
	$result = array();
	if (! $config) $config = config_get();
	$err = config_error($config);
	
	if (! $err)
	{
		$keypair_private = (empty($config['KeypairPrivate']) ? '' : $config['KeypairPrivate']);
		if (! $keypair_private)
		{
			$access_key_id =  (empty($config['AWSAccessKeyID']) ? '' : $config['AWSAccessKeyID']);
			$secret_access_key =  (empty($config['AWSSecretAccessKey']) ? '' : $config['AWSSecretAccessKey']);
		}
		if (! ($keypair_private || ($access_key_id && $secret_access_key))) $err = 'Option KeypairPrivate or AWSAccessKeyID and AWSSecretAccessKey required';
	}
	if (! $err)
	{
		// start XML payload with MovieMasher tag
		$authentication_xml_string = '';
		$nonce = id_unique();
		$gmd = gmdate(DATE_FORMAT_ISO8601);
		$authentication_writer = xml_writer('Authentication');
		$authentication_writer->writeElement('Nonce', $nonce);
		$authentication_writer->writeElement('Date', $gmd);
		if ($keypair_private) $authentication_writer->writeElement('Name', 'KeyPair');
		else 
		{
			$authentication_writer->writeElement('Identifier', $access_key_id);
			$authentication_writer->writeElement('Name', 'AccessKey');
		}
		$authentication_writer->endElement(); // Authentication	
		$authentication_xml_string = $authentication_writer->outputMemory(); 
		$sig = sig_for_xml_string($authentication_xml_string);
		$sig .= "\n" . sig_for_xml_string($job_xml_string);
		if ($keypair_private) $sig = sig_private_key($keypair_private, $sig);
		else $sig = sig_base_hmac($secret_access_key, $sig);
		if ($sig) 
		{
			$moviemasher_writer = xml_writer('MovieMasher', TRUE);
			$moviemasher_writer->writeElement('Signature', $sig);
			$moviemasher_writer->writeRaw($authentication_xml_string);
			$moviemasher_writer->writeRaw($job_xml_string);
			$moviemasher_writer->endElement(); // MovieMasher
			$job_xml_string = xml_pretty($moviemasher_writer->outputMemory());
		}
		else $err = 'Could not generate api signature';
	}
	if ($err) $result['error'] = $err;
	else $result['xml'] = $job_xml_string;
	return $result;
}

function api_queue_job($xml_string, $config = array())
{
	$result = array();
	if (! $config) $config = config_get();
	$err = config_error($config);
	if (! $err) // request is all signed, go ahead and make it
	{
		$dir_log = config_path(empty($config['DirLog']) ? '' : $config['DirLog']);
		$client = (empty($config['Client']) ? 'REST' : strtoupper($config['Client']));
		$log_transcoder_requests = (empty($config['LogTranscoderRequests']) ? '' : $config['LogTranscoderRequests']);
		$log_transcoder_responses = (empty($config['LogTranscoderResponses']) ? '' : $config['LogTranscoderResponses']);
		if ($client == 'SQS') 
		{
			$access_key_id =  (empty($config['AWSAccessKeyID']) ? '' : $config['AWSAccessKeyID']);
			$secret_access_key =  (empty($config['AWSSecretAccessKey']) ? '' : $config['AWSSecretAccessKey']);
			$end_point =  (empty($config['SQSQueueURLSend']) ? '' : $config['SQSQueueURLSend']);
		}
		else $end_point = config_path(empty($config['RESTEndPoint']) ? '' : $config['RESTEndPoint']);
		
		$job_id = '';
		// post decode job to the Transcoder
		if ($log_transcoder_requests) log_file("Client $client request:\n" . $xml_string, $dir_log);
	
		if ($client == 'SQS')
		{
			$variables = array();
			$variables['Action'] = 'SendMessage';
			$variables['MessageBody'] = $xml_string;
			$variables['Version'] = '2011-10-01';
			// the following are required for non-public queues
			$variables['AWSAccessKeyId'] = $access_key_id;
			$variables['Timestamp'] = gmdate('Y-m-d\TH:i:s\Z');
			$variables['SignatureVersion'] = '2';
			$variables['SignatureMethod'] = 'HmacSHA256';
			$variables['Signature'] = sig_version_two($secret_access_key, $end_point, $variables, 'post');
			
			$post_result = http_send($end_point, $variables);
			
			$xml_string = $post_result['result'];
			if ($xml_string && $log_transcoder_responses) log_file("Client SQS response:\n" . $xml_string, $dir_log);
			if ($post_result['error']) $err = 'Could not make SQS request ' . $end_point . ' ' . $post_result['error'];
			else if (! $xml_string) $err = 'Got no response from SQS request';
			else
			{
				$xml = xml_from_string($xml_string);
				if (! is_object($xml)) $err = 'Could not parse SQS response';
				else if (sizeof($xml->Error)) $err = 'Got error in SQS response';
				else $job_id = (string) $xml->SendMessageResult->MessageId;
			}
		}
		else // REST
		{
			$post_result = http_send($end_point, $xml_string);
			$xml_string = $post_result['result'];
			if ($xml_string && $log_transcoder_responses) log_file("Client REST response:\n" . $xml_string, $dir_log);
			// make sure we got a response, log it and parse into SimpleXML object
			if (! $xml_string) $err = 'Got no response from REST request';
			else
			{
				$xml = xml_from_string($xml_string);
				if (! is_object($xml)) $err = 'Could not parse REST response';
				else if (sizeof($xml->Error)) 
				{
					if (! $log_transcoder_responses) log_file("Client REST response:\n" . $xml_string, $dir_log);
					$err = 'Got error in REST response';
				}
				else if ($post_result['error']) $err = 'Could not make REST request ' . $post_result['error'];
				else
				{
					$id_tags = $xml->xpath('//JobID');
					if (sizeof($id_tags)) $job_id = (string) $id_tags[0];
				}
			}
		}
		if ((! $err) && (! $job_id)) $err = 'Got no Job ID';
	}
	if ($err) $result['error'] = $err;
	else $result['id'] = $job_id;
	return $result;
}
?>