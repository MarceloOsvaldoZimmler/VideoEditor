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
This script is called by the Transcoder, when an error has occured during job processing.
The body of the request contains XML formatted progress info indicating the error encountered.
This error or any other encountered during processing is logged if possible.
*/

$err = '';
$dir_log = '';

// load utilities
$include = dirname(__FILE__) . '/include/';
if ((! $err) && (! @include_once($include . 'authutils.php'))) $err = 'Problem loading authentication utility script';
if ((! $err) && (! @include_once($include . 'configutils.php'))) $err = 'Problem loading configuration utility script';
if ((! $err) && (! @include_once($include . 'logutils.php'))) $err = 'Problem loading log utility script';
if ((! $err) && (! @include_once($include . 'xmlutils.php'))) $err = 'Problem loading xml utility script';
if (! $err) // pull in configuration so we can log other errors
{
	$config = config_get();
	$dir_log = config_path(empty($config['DirLog']) ? '' : $config['DirLog']);
	$err = config_error($config);
}

if (! $err) // pull in other configuration and check for required input
{
	$client = (empty($config['Client']) ? 'REST' : strtoupper($config['Client']));
}
if (! $err) // see if the user is authenticated (does not redirect or exit)
{
	if (! auth_ok_callback()) $err = 'Unauthenticated access';
}

if (! $err) // check to make sure required parameters have been sent
{
	$id = (empty($_REQUEST['id']) ? '' : $_REQUEST['id']);
	if (! $id ) $err = 'Parameter id required';
}
if (! $err)
{
	// set default $err for log entry
	$err = 'Render Error';
	
	$input = @file_get_contents('php://input');

	$input_xml = xml_from_string($input);
	if (! is_object($input_xml)) log_file("Could not parse error payload:\n" . $input_xml, $dir_log);
	else
	{
		$err = strval($input_xml->Error);
		$error_log = strval($input_xml->ErrorLog);
		$warning_log = strval($input_xml->WarningLog);
		if (! $err) $err = $error_log;
		if (! $err) log_file("Could not find error:\n" . $input_xml, $dir_log);
		if ($warning_log) log_file("Warning Log:\n" . $warning_log, $dir_log);
		if ($error_log) log_file("Error Log:\n" . $error_log, $dir_log);
	}
	if ($client == 'SQS')
	{
		$dir_temporary = config_path(empty($config['DirTemporary']) ? sys_get_temp_dir() : $config['DirTemporary']);
		$xml_string = '';
		$xml_string .= '<Response><Progress>' . "\n";
		$xml_string .= "\t" . '<Percent>-1</Percent>' . "\n";
		$xml_string .= "\t" . '<Status>' . $err . '</Status>' . "\n";
		$xml_string .= '</Progress></Response>' . "\n";
		if (! file_put($dir_temporary . $id . '.xml', $xml_string)) $err = 'Could not write progress file';
	}
}

if (! $err) $err = 'Received empty error';
if ($err) log_file($err, $dir_log);
?>