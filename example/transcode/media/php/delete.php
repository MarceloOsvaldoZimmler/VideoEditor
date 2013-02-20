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
This script is called directly from Movie Masher Applet, when user clicks the delete button on an item in the media browser. 
*/

$err = '';
$dir_log = '';

// load utilities
$include = dirname(__FILE__) . '/include/';
if ((! $err) && (! @include_once($include . 'authutils.php'))) $err = 'Problem loading authentication utility script';
if ((! $err) && (! @include_once($include . 'logutils.php'))) $err = 'Problem loading log utility script';
if ((! $err) && (! @include_once($include . 'configutils.php'))) $err = 'Problem loading configuration utility script';
if ((! $err) && (! @include_once($include . 'datautils.php'))) $err = 'Problem loading data utility script';
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
if (! $err) // grab log directory configuration option
{
	$log_requests = (empty($config['LogRequests']) ? '' : $config['LogRequests']);
	$log_responses = (empty($config['LogResponses']) ? '' : $config['LogResponses']);

	$user =  auth_userid();
	if ($log_requests) log_file($_SERVER['QUERY_STRING'], $dir_log);
	
	// make sure required parameters have been sent
	$id = (empty($_GET['id']) ? '' : $_GET['id']);	
	$type = (empty($_GET['type']) ? '' : $_GET['type']);	
	if (! ($id && $type)) $err = 'Parameters id, type required';
	
}
if (! $err) // see if there are mashes that use this media
{	
	$associated_mashes = data_associated_mashes($id, $type, $user, $config);
	if (! empty($associated_mashes['error'])) $err = $associated_mashes['error'];
	else if ($associated_mashes) 
	{
		$err = "Item is used in {$associated_mashes[0]['label']}";
		if (sizeof($associated_mashes) > 1) 
		{
			$err .= ' and ';
			if (sizeof($associated_mashes) > 2) $err .= 'others';
			else $associated_mashes[1]['label'];
		}
		
	}
}
if (! $err) $err = data_delete($id, $type, $user, $config);


if ($err) $xml = '<moviemasher get=\'javascript:alert("' .  $err . '");\' />';
else $xml = '<moviemasher trigger="browser.parameters.group=' . $type . '" />';

$writer = xml_writer('', TRUE);
$writer->writeRaw($xml);
print $writer->outputMemory() . "\n\n";

if (! empty($log_responses)) log_file($xml, $dir_log);
?>