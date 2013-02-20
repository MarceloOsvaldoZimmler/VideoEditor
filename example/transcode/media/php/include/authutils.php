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
This file provides hooks for the authentication mechanisms and is included by most
scripts. It uses PHP's built in HTTP authentication but allows ANY username/password
combination to be used. The auth_challenge() function is only called from the index page.
The auth_userid() function is called whenever paths are built to the user's content
(uploads, rendered videos, XML data files). The auth_data() function is called from
when callbacks are being generated for inclusion in the job XML for the transcoder. 

If using session-based authentication, you may need to start the session manually and make
sure that use_only_cookies is off so any callbacks from the Transcoder AMI can be properly
authenticated. 

ini_set('session.use_only_cookies', '0');
session_name('session');
        
session_start();

*/

include_once(dirname(__FILE__) . '/configutils.php');

function auth_challenge($realm = 'Any username and password will work for this example!', $msg = 'Reload to try again')
{
	// in this example we use HTTP authentication
	// if using sessions, you'll probably want to redirect to login page instead
	header('WWW-Authenticate: Basic realm="' . $realm . '"');
	header('HTTP/1.0 401 Unauthorized');
	print $msg;
	exit;
}

function auth_ok()
{
	// in this example we just check to see if ANY username and password have been set
	// if using sessions, a mechanism in your auth library probably returns authentication state
	return ! (empty($_SERVER['PHP_AUTH_USER']) || empty($_SERVER['PHP_AUTH_PW']));
}

function auth_userid()
{
	// in this example the username serves as the ID, and is used to build user paths
	// if using sessions, a mechanism in your auth library probably returns a user ID
	return (empty($_SERVER['PHP_AUTH_USER']) ? '' : $_SERVER['PHP_AUTH_USER']);
}

function auth_ok_callback($config = array())
{
	$ok = FALSE;
	if (! $config) $config = config_get();
	if (! config_error($config))
	{
		if (__auth_config_uses_keys($config))
		{
			$date = (empty($_REQUEST['date']) ? '' : $_REQUEST['date']);
			$sig = (empty($_REQUEST['sig']) ? '' : $_REQUEST['sig']);
			$sig = str_replace(' ', '+', $sig);
			$to_sign = array();
			$to_sign[] = $config['AWSAccessKeyID'];
			$to_sign[] = $date;
			$to_sign = implode("\n", $to_sign);
			$key = $config['AWSSecretAccessKey'];
			$sig_test = base64_encode(hash_hmac('sha1', $to_sign, $key, true));
			$ok = ($sig == $sig_test);
		}
		else $ok = auth_ok();
	}
	return $ok;
}

function auth_data(& $transfer, $config = array())
{
	if (! $config) $config = config_get();
	if (! config_error($config))
	{
		if (__auth_config_uses_keys($config))
		{
			// use AWS keys to authenticate callbacks
			$value = array('{AccessKey.Identifier}','{Transfer.DateTimestamp}');
			
			$join = array('NewLine' => '', 'Value' => $value);
			$hmac = array('Join' => $join, 'Value' => '{AccessKey.Secret}');
			$transfer['Signature'] = array('Base64Encode' => array('HMACSHA1' => $hmac));
			
			__auth_array_pair($transfer, 'Parameter');
			
			$transfer['ParameterName'][] = 'sig';
			$transfer['ParameterValue'][] = '{Transfer.Signature}';
			$transfer['ParameterName'][] = 'date';
			$transfer['ParameterValue'][] = '{Transfer.DateTimestamp}';
		}
		else
		{
			// use HTTP authentication - eg. http://User:Pass@www.example.com/path/
			$transfer['User'] = $_SERVER['PHP_AUTH_USER'];
			$transfer['Pass'] = $_SERVER['PHP_AUTH_PW'];
			
			/* 
			// if using sessions we add session name/id to parameter name/value
			__auth_array_pair($transfer, 'Parameter');
			$transfer['ParameterName'][] = session_name();
			$transfer['ParameterValue'][] = session_id();
			*/
			
		}


	}
}
function __auth_array_pair($transfer, $key) // makes sure Name/Value are both arrays
{	
	if (empty($transfer[$key . 'Name'])) $transfer[$key . 'Name'] = array();
	else if (is_string($transfer[$key . 'Name'])) $transfer[$key . 'Name'] = array($transfer[$key . 'Name']);
	if (empty($transfer[$key . 'Value'])) $transfer[$key . 'Value'] = array();
	else if (is_string($transfer[$key . 'Value'])) $transfer[$key . 'Value'] = array($transfer[$key . 'Value']);
}
function __auth_config_uses_keys($config)
{
	return (empty($config['KeypairPrivate']) && (! empty($config['AWSAccessKeyID'])) && (! empty($config['AWSSecretAccessKey'])));
}
?>