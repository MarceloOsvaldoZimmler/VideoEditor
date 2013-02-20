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

include_once(dirname(__FILE__) . '/configutils.php');

function file_dir($file_path)
{
	if (! is_string($file_path)) throw new UnexpectedValueException('file_dir ' . print_r($file_path, 1));
	if (substr($file_path, -1) != '/')
	{
		$file_path = dirname($file_path) . '/';
	}
	return $file_path;
}
function file_dir_delete_recursive($path)
{
	$result = FALSE;
	if ($path)
	{
		$file_prefix = '';
		if (substr($path, -1) == '*') 
		{
			$file_prefix = basename($path, '*');
			$path = file_dir($path);
		}
		if (file_exists($path) && is_dir($path))
		{
			$path = config_path($path);
			
			if ($handle = opendir($path)) 
			{
				$result = TRUE;
				while ($result && (FALSE !== ($file = readdir($handle))))
				{
					if (($file != ".") && ($file != "..")) 
					{
						if ($file_prefix && (substr($file, 0, strlen($file_prefix)) != $file_prefix))
						{
							continue;
						}
						if (is_dir($path . $file))
						{
							$result = file_dir_delete_recursive($path . $file);
						}
						else
						{
							$result = @unlink($path . $file);
						}
					}
				}
				closedir($handle);
				if ((! $file_prefix) && $result) $result = @rmdir($path);
			}
		}
	}
    return $result;

}
function file_extension($url, $dont_change_case = 0)
{
	$extension = '';
	if ($url)
	{
		$parsed = parse_url($url, PHP_URL_PATH);
		if ($parsed)
		{
			$extension = pathinfo($parsed, PATHINFO_EXTENSION);
			if (! $dont_change_case) $extension = strtolower($extension);
		}
	}
	return $extension;
}
function file_get($path, $options = 1)
{
	return @file_get_contents($path, $options);
}

function file_move_extension($extension, $archive_path, $media_path, $dont_replace = FALSE)
{
	$result = FALSE;
	// make sure parameters are defined
	if ($extension && $archive_path && $media_path)
	{
		$archive_path = config_path($archive_path);
		$media_path = config_path($media_path);
		
		// make sure archive path exists
		if (file_exists($archive_path))
		{
			// make sure we have somewhere to move to
			if (file_safe($media_path)) 
			{
				if ($handle = opendir($archive_path)) 
				{
					$result = TRUE;
					while ($result && (FALSE !== ($file = readdir($handle))))
					{
						if ($file != "." && $file != "..") 
						{
							if (is_file($archive_path . $file))
							{
								$ext = file_extension($archive_path . $file);
								if ($ext == $extension)
								{
									if ((! $dont_replace) || (! file_exists($media_path . $file)))
									{
										$result = @rename($archive_path . $file, $media_path . $file);
									}
								}
							}
						}
					}
					closedir($handle);
				}
			}
		}
	}
    return $result;
}
function file_put($path, $data, $options = NULL)
{
	$result = FALSE;
	if (file_safe($path))
	{
		$result = @file_put_contents($path, $data, $options);
		if (file_exists($path)) $result = TRUE;
	}
	return $result;
}
function file_safe($path)
{
	$result = FALSE;
	if ($path)
	{
		$ext = file_extension($path); // will be empty if path is directory
		$dirs = explode('/', $path);
		if ($ext) array_pop($dirs); // get rid of file name if path is file
		$dir = join('/', $dirs);
		if (file_exists($dir)) 
		{
			$result = TRUE;
			@chmod($dir, 0777);
		}
		else $result = @mkdir($dir, 0777, TRUE);
	}
	return $result;
}
function files_in_dir($dir, $just_names = FALSE, $filter = 'files')
{
	$result = FALSE;
	if ($dir && is_dir($dir))
	{
		$dir = config_path($dir);
		if ($handle = opendir($dir)) 
		{
			$result = array();
			while (FALSE !== ($file = readdir($handle)))
			{
				if ($file != "." && $file != "..") 
				{
					$full_path = $dir . $file;
					if (! $just_names) $file = $full_path;
					switch($filter)
					{
						case 'files':
							if (is_file($full_path)) $result[] = $file;
							break;
						case 'dirs':
							if (is_dir($full_path)) $result[] = $file;
							break;
						default:
							$result[] = $file;
					}
				}
			}
			closedir($handle);
		}
	}
	return $result;
}
function files_in_dir_recursive($full_path)
{
	$files = array();
	if (is_dir($full_path)) 
	{
		if ($dh = opendir($full_path)) 
		{
			if (substr($full_path, -1) != '/') $full_path .= '/';
			while (($file = readdir($dh)) !== false) 
			{
				if (substr($file, 0, 1) != '.')
				{
					$files = array_merge($files, files_in_dir_recursive($full_path . $file));
				}
			}
			closedir($dh);
		}
	}
	else $files[] = $full_path;
	return $files;
}
/*
function file_get_info($type, $file_path)
{
	$result = FALSE;
	if ($file_path)
	{
		$info_file = file_meta_path($type, $file_path);
		$result = file_get($info_file);
	}
	return $result;
}
function file_meta_path($type, $file_path)
{
	$dir_name = 'meta';
	$file_path = file_dir($file_path);
	return $file_path . $dir_name . '/' . $type . '.txt';
}
*/
?>