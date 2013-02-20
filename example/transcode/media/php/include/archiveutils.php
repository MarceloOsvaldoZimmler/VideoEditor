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
Required directly by example scripts that receive encoded assets via HTTP as tgz archive.
This file uses PEAR's Archive_Tar class to handle the extraction. Functions will return
FALSE if the class cannot be loaded.
*/

@include_once('Archive/Tar.php');

include_once(dirname(__FILE__) . '/fileutils.php');

function archive_extract($path, $archive_dir)
{
	$result = FALSE;
	if (class_exists('Archive_Tar'))
	{
		if (file_safe($archive_dir . 'file.txt')) 
		{
			$tar = new Archive_Tar($path);
			$tar->extract($archive_dir);
			$result = file_exists($archive_dir);
		}
	}
	return $result;
}
?>