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

include_once(dirname(__FILE__) . '/fileutils.php');

function http_execute_array($ch)
{
	$result = array('error' => '', 'result' => '', 'status' => '');
	$result['result'] = curl_exec($ch);
	$result['info'] = curl_getinfo($ch);
	if (! empty($result['info']['http_code']))
	{
		$result['status'] = $result['info']['http_code'];
		if ($result['status'] >= 400) $result['error'] = 'Received status code ' . $result['info']['http_code'];
	}
	if (empty($result['error'])) $result['error'] = curl_error($ch);
	return $result;
}
function http_get_contents($url)
{
	if (substr($url, 0, 4) == 'http')
	{
		$result = http_retrieve($url);
		if (! $result['error']) $url = $result['result'];
		else $url = '';
	}
	return $url;
}
function http_retrieve_file($abs_url, $file_path, $headers = array(), $options = array())
{
	$result = array('error' => 'Could not open file or url', 'result' => $abs_url . ' ' . $file_path);
	clearstatcache();
	
	if (file_safe($file_path) && ((! file_exists($file_path)) || (! is_dir($file_path))))
	{
		$fp = fopen($file_path, "w");
		if ($fp)
		{
			$ch = curl_init($abs_url);
			if ($ch)
			{
				$options[CURLOPT_FOLLOWLOCATION] = 1;
				$options[CURLOPT_FILE] = $fp;
				//$options[CURLOPT_RETURNTRANSFER] = 1;

				http_set_options($ch, $options, $headers);
				
				$result = http_execute_array($ch);
				$result['options'] = $options;

				@fflush($fp);
				curl_close($ch);
				
				
			}
			@fclose($fp);
			if ($result['error']) @unlink($file_path);
			else @chmod($file_path, 0777);
		}
	}
	return $result;
}
function http_retrieve($url, $headers = array(), $options = array())
{
	$result = array('error' => 'HTTP Failure', 'result' => '', 'status' => '');

	$ch = curl_init($url);
	if ($ch)
	{
		$options[CURLOPT_RETURNTRANSFER] = 1;

		http_set_options($ch, $options, $headers);
		$result = http_execute_array($ch);
		$result['options'] = $options;

		curl_close($ch);
	}
	return $result;
}
function http_send($url, $data, $headers = array(), $options = array())
{
	// $data can be string or array
	$result = array('error' => 'HTTP Failure', 'result' => '', 'status' => '');
	$ch = curl_init($url);
	if ($ch)
	{
		$options[CURLOPT_RETURNTRANSFER] = 1;
		if ($data)
		{
			$options[CURLOPT_POST] = 1;

			if (is_array($data))
			{
				$a = array();
				foreach($data as $k => $v)
				{
					$a[] = urlencode($k) . '=' . urlencode($v);
				}
				$data = join('&', $a);
			}
			$options[CURLOPT_POSTFIELDS] = $data;
		}
		http_set_options($ch, $options, $headers);
		$result = http_execute_array($ch);
		$result['options'] = $options;
		curl_close($ch);
	}
	return $result;
}
function http_set_options($ch, $options = array(), $headers = array())
{
	if (is_array($headers))
	{
		$a = array();
		foreach($headers as $k => $v)
		{
			$a[] = "$k: $v";
		}
		$options[CURLOPT_HTTPHEADER] = $a;
	}
	if (! isset($options[CURLINFO_HEADER_OUT])) curl_setopt($ch, CURLINFO_HEADER_OUT, TRUE);
	if (! isset($options[CURLOPT_SSL_VERIFYPEER])) curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, FALSE);
	if (! isset($options[CURLOPT_SSL_VERIFYHOST])) curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, FALSE);
	if (! isset($options[CURLOPT_SSLVERSION])) curl_setopt($ch, CURLOPT_SSLVERSION, 3);
	if (! isset($options[CURLOPT_TIMEOUT])) curl_setopt($ch, CURLOPT_TIMEOUT, 600);
	if (! isset($options[CURLOPT_FAILONERROR])) curl_setopt($ch,CURLOPT_FAILONERROR, FALSE);
	if (! isset($options[CURLOPT_USERAGENT])) curl_setopt($ch,CURLOPT_USERAGENT, 'Movie Masher');

	
	foreach($options as $k => $v)
	{
		curl_setopt($ch, $k, $v);
	}

}

?>