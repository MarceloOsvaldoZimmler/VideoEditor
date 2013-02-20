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

include_once(dirname(__FILE__) . '/dateutils.php');
include_once(dirname(__FILE__) . '/xmlutils.php');
function sig_s3_post($secret_access_key, $options = array())
{
	$s3data = array();
	if ( ! ( empty($options['mime']) || empty($options['path'])) )
	{
		if (empty($options['acl'])) $options['acl'] = 'public-read';
		$policy = array();
		$policy['expiration'] = gmdate(DATE_FORMAT_TIMESTAMP, strtotime('+ 1 hour'));
		$policy['conditions'] = array();
		$policy['conditions'][] = array('eq', '$bucket', $options['bucket']);
		$policy['conditions'][] = array('eq', '$key', $options['path']);
		$policy['conditions'][] = array('eq', '$acl', $options['acl']);
		$policy['conditions'][] = array('eq', '$Content-Type', $options['mime']);
		$policy['conditions'][] = array('starts-with', '$Filename', '');
		$policy['conditions'][] = array('starts-with', '$success_action_status', '201');
	
		$policy = base64_encode(stripslashes(json_encode($policy)));
		
		$s3data['key'] = $options['path'];
		$s3data['mime'] = $options['mime'];
		$s3data['bucket'] = $options['bucket'];
		$s3data['acl'] = $options['acl'];
		$s3data['policy'] = $policy;
		$s3data['signature'] = sig_access_key($secret_access_key, $policy);
	}
	return $s3data;
}
function sig_version_two($secret_access_key, $url, $data, $method = 'get')
{
	$parsed_url = parse_url($url);
	uksort($data, 'strnatcmp');
	$lines = array();
	$lines[] = strtoupper($method);
	$lines[] = strtolower($parsed_url['host']);
	$lines[] = $parsed_url['path'];
	$params = array();
	foreach($data as $k => $v)
	{
		$params[] = sig_encode2($k) . '=' . sig_encode2($v);
	}
	if ($params) $lines[] = implode('&', $params);
	$to_sign = implode("\n", $lines);
	return sig_base_hmac($secret_access_key, $to_sign, 'sha256');
}

function sig_encode2($string)
{
	$string = rawurlencode($string);
	return str_replace('%7E', '~', $string);
}
	
function sig_base_hmac($secret_access_key, $to_sign, $method = 'sha256')
{
	return base64_encode(hash_hmac($method, $to_sign, $secret_access_key, TRUE));
}

function sig_for_xml_string($xml_string)
{
	return sig_for_xml(xml_from_string($xml_string));
}

function sig_for_xml($xml, $parents = array())
{	
	$result = array();
	if (is_object($xml))
	{
		$first_call = ! $parents;
		if ($first_call) $parents[] = $xml->getName();
		$attributes = $xml->attributes();
		$keys = array();
		foreach($attributes as $k => $v) $keys[$k] = $v;
		foreach($keys as $k => $v) if (strlen($v)) $result[join('.', $parents) . ".$k"] = $v;
		$children = $xml->children();
		$x = count($children);
		if ($x)
		{
			$parents_length = count($parents);
			$keys = array();
			for ($k = 0; $k < $x; $k++) $keys[$children[$k]->getName()] = TRUE;
			foreach(array_keys($keys) as $key)
			{
				$z = count($xml->{$key});
				for ($i = 0; $i < $z; $i++)
				{
					$child = $xml->{$key}[$i];
					$parents[$parents_length] = $key . (($z == 1) ? '' : '.' . ($i + 1));
					$result = array_merge($result, sig_for_xml($child, $parents));
				}
			}
		}
		else
		{
			$v = strval($xml);
			if ($v) $result[join('.', $parents)] = $v;
		}
		if ($first_call) 
		{
			ksort($result);
			$results = array();
			foreach($result as $k => $v)
			{
				$results[] = "$k:$v";
			}
			$result = join("\n", $results);
		}
	}
	return $result;
}

function sig_access_key($secret_access_key, $data)
{
	return __sig_s3_post_base64(__sig_s3_post_hasher($secret_access_key, $data));
}
function sig_private_key($key_path, $data)
{
	$result = FALSE;
	if (function_exists('openssl_get_privatekey') && function_exists('openssl_sign') && function_exists('openssl_free_key'))
	{
		$key = file_get($key_path);
		if ($key)
		{
			$pkeyid = openssl_get_privatekey($key);
			if ($pkeyid)
			{
				if (openssl_sign($data, $result, $pkeyid)) 
				{
					$result = base64_encode($result);
				}
				openssl_free_key($pkeyid);
			}
		}
	}
	return $result;
}

function __sig_s3_post_base64($str)
{
	$ret = "";
	for($i = 0; $i < strlen($str); $i += 2) $ret .= chr(hexdec(substr($str, $i, 2)));
	return base64_encode($ret);
}
function __sig_s3_post_hasher($key, $data)
{
	// Algorithm adapted (stolen) from http://pear.php.net/package/Crypt_HMAC/)
	if(strlen($key) > 64) $key = pack("H40", sha1($key));
	if(strlen($key) < 64) $key = str_pad($key, 64, chr(0));
	$ipad = (substr($key, 0, 64) ^ str_repeat(chr(0x36), 64));
	$opad = (substr($key, 0, 64) ^ str_repeat(chr(0x5C), 64));
	return sha1($opad . pack("H40", sha1($ipad . $data)));
}

if (! function_exists('json_encode')) // in case it's not there for some reason
{
  function json_encode($a=false)
  {
    if (is_null($a)) return 'null';
    if ($a === false) return 'false';
    if ($a === true) return 'true';
    if (is_scalar($a))
    {
      if (is_float($a))
      {
        // Always use "." for floats.
        return floatval(str_replace(",", ".", strval($a)));
      }

      if (is_string($a))
      {
        static $jsonReplaces = array(array("\\", "/", "\n", "\t", "\r", "\b", "\f", '"'), array('\\\\', '\\/', '\\n', '\\t', '\\r', '\\b', '\\f', '\"'));
        return '"' . str_replace($jsonReplaces[0], $jsonReplaces[1], $a) . '"';
      }
      else
        return $a;
    }
    $isList = true;
    for ($i = 0, reset($a); $i < count($a); $i++, next($a))
    {
      if (key($a) !== $i)
      {
        $isList = false;
        break;
      }
    }
    $result = array();
    if ($isList)
    {
      foreach ($a as $v) $result[] = json_encode($v);
      return '[' . join(',', $result) . ']';
    }
    else
    {
      foreach ($a as $k => $v) $result[] = json_encode($k).':'.json_encode($v);
      return '{' . join(',', $result) . '}';
    }
  }
}

?>