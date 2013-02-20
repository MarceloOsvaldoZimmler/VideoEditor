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

function log_file($s, $dir_log)
{
	if ($dir_log && $s)
	{
		if (file_safe($dir_log))
		{
			$prelog = date('H:i:s') . ' ';
			$prelog .= basename($_SERVER['SCRIPT_NAME']);
			$path = $dir_log . 'log_' . date('Y-m-d') . '.txt';
			$existed = file_exists($path);
			$fp = fopen($path, 'a');
			if ($fp)
			{
				$s = $prelog . ' ' . $s . "\n";
				fwrite($fp, $s, strlen($s));
				fclose($fp);
			}
			if (! $existed) @chmod($path, 0777);
		}
	}
}
?>