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
include_once(dirname(__FILE__) . '/xmlutils.php');
include_once(dirname(__FILE__) . '/mashutils.php');

function data_associated_mashes($id, $type, $user, $config = array())
{
	$result = array();
	if (! $config) $config = config_get();
	$err = config_error($config);
	if (! $err)
	{
		$dir_host = config_path(empty($config['DirHost']) ? $_SERVER['DOCUMENT_ROOT'] : $config['DirHost']);
		$path_xml = config_path(empty($config['PathXML']) ? '' : $config['PathXML']);
		$user_path_xml = $dir_host . $path_xml . $user . '/';
		$file_name = 'media_mash.xml';
		if (file_exists($user_path_xml . $file_name)) 
		{
			$xml_string = file_get($user_path_xml . $file_name);
			if ($xml_string)
			{
				$xml = xml_from_string($xml_string);
				if (is_object($xml))
				{
					$media_tags = $xml->xpath('./media[@type="mash"]');
					foreach($media_tags as $media_tag)
					{
						$file_name = strval($media_tag['id']) . '.xml';
						$xml_string = file_get($user_path_xml . $file_name);
						$mash_xml = xml_from_string($xml_string);
						if (is_object($mash_xml) && sizeof($mash_xml->mash))
						{
							$clip_tags = $mash_xml->xpath('//clip[@id="' . $id . '"]');
							if (sizeof($clip_tags))
							{
								$result[] = mash_data_from_tags($mash_xml->mash[0], $media_tag);
								break;
							}
						}
						else 
						{
							$err = 'Could not parse mash from ' . $file_name;
							break;
						}
					}
				}
				else $err = 'Could not parse ' . $file_name;
			}
		}
	}
	if ($err) $result = array('error' => $err);
	return $result;	
}

function data_delete($id, $type, $user, $config)
{
	$err = '';
	if (! $config) $config = config_get();
	$err = config_error($config);
	if (! $err)
	{
		$dir_host = config_path(empty($config['DirHost']) ? $_SERVER['DOCUMENT_ROOT'] : $config['DirHost']);
		$path_xml = config_path(empty($config['PathXML']) ? '' : $config['PathXML']);
		$user_path_xml = $dir_host . $path_xml . $user . '/';
		$file_name = 'media_' . $type . '.xml';
		if (file_exists($user_path_xml . $file_name)) 
		{
			$xml_string = file_get($user_path_xml . $file_name);
			if ($xml_string)
			{
				$xml = xml_from_string($xml_string);
				if (is_object($xml))
				{
					$media_tags = $xml->xpath('./media[not(@id="' . $id . '")]');
					
					$new_xml = xml_from_string('<moviemasher></moviemasher>');
					if (sizeof($media_tags)) xml_append_children($new_xml, $media_tags);
					//$err = 'Found ' . sizeof($media_tags) . ' of ' . sizeof($xml->xpath('./media'));
					if (! file_put($user_path_xml . $file_name, xml_pretty($new_xml->asXML()))) $err = 'Was not able to write ' . $file_name;
				}
				else $err = 'Could not parse ' . $file_name;
			}
		}
	}
	return $err;	
}

?>