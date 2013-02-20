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

// A convenient place to suppress errors and avoid corrupt xml responses
ini_set('display_errors', 1);

include_once(dirname(__FILE__) . '/fileutils.php');

function config_get($return_error = FALSE)
{
	$ini_path = '/Applications/MAMP/htdocs/moviemasher/private/moviemasher.ini';
	$config = @parse_ini_file($ini_path);
	if (! $config) 
	{
		if ($return_error) 
		{
			$contents = file_get($ini_path);
			if (! $contents) $config = 'Could not find moviemasher.ini - make sure its parent directory is in include_path or adjust path in configutils.php';
			else $config = 'Could not parse moviemasher.ini - make sure options with special characters are quoted';
		}
		else $config = array();
	}
	return $config;
}

function config_error($config)
{
	$err = '';
	$exception = 'http://169.254.169.254/latest/meta-data/public-hostname'; // for retrieving current EC2 Public DNS Name
	if (! $config)
	{
		$err = config_get(TRUE);
		if (! $err) $err = 'Problem getting configuration';
	}
	if (! $err)
	{
		if ((! empty($config['HostMedia'])) && (strpos($config['HostMedia'], '/') !== FALSE) && ($config['HostMedia'] != $exception)) $err = 'Configuration option HostMedia cannot contain slashes';
	}
	if (! $err)
	{
		if ((! empty($config['Host'])) && (strpos($config['Host'], '/') !== FALSE) && ($config['Host'] != $exception)) $err = 'Configuration option Host cannot contain slashes';
	}
	if (! $err)
	{
		$client = (empty($config['Client']) ? 'REST' : strtoupper($config['Client']));
		$file = (empty($config['File']) ? 'Local' : ucwords($config['File']));
		$check_aws = FALSE;
		switch($file)
		{
			case 'Local':
			{
				break;
			}
			case 'S3':
			{
				if (empty($config['S3Bucket'])) $err = 'Configuration option S3Bucket required';
				else if (empty($config['HostMedia'])) $err = 'Configuration option HostMedia required';
				else
				{
					if (substr($config['HostMedia'], 0, strlen($config['S3Bucket'])) != $config['S3Bucket'])
					{
						if (empty($config['PathMedia'])) $err = 'Configuration option PathMedia required if HostMedia does not begin with S3Bucket';
						else if (substr($config['PathMedia'], 0, strlen($config['S3Bucket'])) != $config['S3Bucket'])
						{
							$err = 'Either HostMedia or PathMedia must begin with S3Bucket';
						}
					}					
				}
				if (! $err) $check_aws = TRUE;
				break;
			}
			default: 
			{
				$err = 'Unsupported File configuration ' . $file;
			}
		}
		switch($client)
		{
			case 'REST':
			{
				if (empty($config['RESTEndPoint']))
				{
					$err = 'Configuration option RESTEndPoint required';
				}
				else if (substr($config['RESTEndPoint'], 0, 4) != 'http') 
				{
					$err = 'Configuration option RESTEndPoint must have http prefix';
				}
				else if (empty($config['KeypairPrivate']))
				{
					$check_aws = TRUE;
					$err = 'Configuration option KeypairPrivate or both AWSAccessKeyID and AWSSecretAccessKey required';
				}
				break;
			}
			case 'SQS':
			{
				if (empty($config['SQSQueueURLSend'])) $err = 'Configuration option SQSQueueURLSend required';
				else $check_aws = TRUE;
				break;
			}
			default: 
			{
				$err = 'Unsupported Client configuration ' . $client;
			}
		}
		if ($check_aws)
		{
			if (empty($config['AWSAccessKeyID']) || empty($config['AWSSecretAccessKey']))
			{
				if (! $err) $err = 'Configuration options AWSAccessKeyID, AWSSecretAccessKey required';
			}
			else $err = '';
		}
	}
	return $err;
}
function config_path($input, $char = '/')
{
	if ($input && (substr($input, - strlen($char)) != $char)) $input .= $char;
	return $input;
}
?>