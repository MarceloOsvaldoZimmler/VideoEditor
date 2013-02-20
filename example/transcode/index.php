<?php
/*
* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/.
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
This script is called directly from the web browser. The HTML page is returned,
as long as the user can be authenticated via HTTP. This document includes styles
needed for a full window, liquid interface layout. The Movie Masher applet is
embedded using the swfObject JavaScript library.
*/

ini_set('display_errors', 1);
error_reporting(E_ALL);

$err = '';
$dir_log = '';

// load utilities
$include = dirname(__FILE__) . '/media/php/include/';

if ((! $err) && (! @include_once($include . 'authutils.php'))) $err = 'Problem loading authentication utility script';
if ((! $err) && (! @include_once($include . 'configutils.php'))) $err = 'Problem loading configuration utility script';
if ((! $err) && (! @include_once($include . 'logutils.php'))) $err = 'Problem loading log utility script';

if (! $err) // pull in configuration so we can log other errors
{
	$config = config_get();
	$dir_log = config_path(empty($config['DirLog']) ? '' : $config['DirLog']);
	$err = config_error($config);
}
// autheticate the user (will exit if not possible)
if ((! $err) && (! auth_ok())) auth_challenge();

if ($err) // if error encountered output it and exit, otherwise content below will output
{
	print $err;
	if ($dir_log) log_file($err, $dir_log);
	exit;
}
$mm_path = (empty($config['PathMovieMasher']) ? '../../' : $config['PathMovieMasher']);
// Player control dimensions are double preprocessed dimensions
$encoder_dimensions = (empty($config['EncoderDimensions']) ? '256x144' : $config['EncoderDimensions']);
list($video_width, $video_height) = explode('x', $encoder_dimensions);
// Preview control dimensions are same as rendered dimensions
$decoder_dimensions = (empty($config['DecoderDimensions']) ? '512x288' : $config['DecoderDimensions']);
list($preview_width, $preview_height) = explode('x', $decoder_dimensions);
?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
<meta http-equiv="content-type" content="text/html; charset=utf-8" />
<title><?php print $config['Client'] . '-' . $config['File'];?> Example :: SDK <?php print @file_get_contents('VERSION.txt', 1); ?>:: Movie Masher</title>
<script type='text/javascript' src='../media/js/swfobject/swfobject.js'></script>
<script type="text/javascript">
var base = window.location.href.substr(0, window.location.href.lastIndexOf('/'));
var parObj = {"allowFullScreen":"true"};
var flashvarsObj = {
	"base":base,
	"debug":1,
	"video_width":<?php print $video_width;?>,
	"video_height":<?php print $video_height;?>,
	"preview_width":<?php print $preview_width;?>,
	"preview_height":<?php print $preview_height;?>,
	"mm_path":'<?php print $mm_path; ?>',
	"config":"media/xml/config.xml"
};
flashvarsObj.preloader = flashvarsObj.mm_path + "moviemasher/com/moviemasher/display/Preloader/stable.swf";
swfobject.embedSWF(flashvarsObj.mm_path + "moviemasher/com/moviemasher/core/MovieMasher/stable.swf", "moviemasher_container", "100%", "100%", "10.2.0", "../media/js/swfobject/expressInstall.swf", flashvarsObj, parObj, parObj);
</script>
<style type="text/css">
	html {
		height:100%;
		overflow:hidden;
	}
	#moviemasher_container {
		height:100%;
	}
	body {
		height:100%;
		margin:0px;
		padding:0px;
		background-color:#FFFFFF;
	}
</style>
</head>
<body>
	<div id="moviemasher_container">
		<strong>You need to upgrade your Flash Plugin to version 10 and enable JavaScript</strong>
	</div>
</body>
</html>
