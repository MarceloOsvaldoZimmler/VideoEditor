<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en" >
<head>
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
This template script is included by share.php which captures its output for saving as an HTML file.

The following variables are REQUIRED to be set before inclusion:

$config_url - movie masher configuration file
$movie_url - used in og:video meta tag
$moviemasher_url - movie masher installation (parent of example directory)

The following variables are OPTIONAL:

$title - used in title and og:title meta tag
$description - used in og:description and description meta tags

*/
if (empty($title)) $title = 'My Mash';
$title .= ' :: Movie Masher';
if (empty($description)) $description = 'Check out this video I made with Movie Masher, the open source online video editor. Click their logo to make your own to share.';

$movie_url .= '?config=' . urlencode($config_url);
$movie_url .= '&amp;base=' . urlencode($moviemasher_url . '/example/share');
$movie_url .= '&amp;mm_path=../../';

print '
	<meta name="og:title" content="' . $title . '" /> 
	<meta name="og:type" content="article"/>
	<meta name="og:site_name" content="Movie Masher"/>
	<meta name="og:description" content="' . $description . '" /> 
	<meta name="og:image" content="' . $moviemasher_url . '/example/share/media/image/icon.jpg" /> 
	<meta name="og:url" content="' . $movie_url . '" />
	<meta name="og:video" content="' . $movie_url . '" />
	<meta name="og:video:width" content="394" />
	<meta name="og:video:height" content="278" />
	<meta name="og:video:type" content="application/x-shockwave-flash" />
';
?>
<meta name="description" content="<?php print $description; ?>" />
<meta http-equiv="content-type" content="text/html; charset=utf-8" />
<title><?php print $title; ?></title>
<script type='text/javascript' src='<?php print $moviemasher_url; ?>/example/media/js/swfobject/swfobject.js'></script>
<script type="text/javascript">
var flashvarsObj = new Object();
flashvarsObj.base = "<?php print $moviemasher_url; ?>/example/share";
flashvarsObj.debug = 1;
flashvarsObj.video_width = 384;
flashvarsObj.video_height = 216;
flashvarsObj.mm_path = '../../';

flashvarsObj.config = "<?php print $config_url; ?>";
flashvarsObj.preloader = "<?php print $moviemasher_url; ?>/moviemasher/com/moviemasher/display/Preloader/stable.swf";
swfobject.embedSWF("<?php print $moviemasher_url; ?>/moviemasher/com/moviemasher/core/MovieMasher/stable.swf", "moviemasher_container", "100%", "100%", "10.0.0", "", flashvarsObj);
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
