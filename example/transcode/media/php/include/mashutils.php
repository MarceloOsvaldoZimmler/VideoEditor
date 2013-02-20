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

include_once(dirname(__FILE__) . '/floatutils.php');
include_once(dirname(__FILE__) . '/fileutils.php');

if (! defined('MASH_PATTERN_SWF')) define('MASH_PATTERN_SWF', '/^([.{}_\/[:alnum:]]+[.]swf)*@[[:alnum:]]+/i');
if (! defined('MASH_XPATH_FONT')) define('MASH_XPATH_FONT', '//option[@type="font"]');

// these should match com.moviemasher.manager.ConfigManager
if (! defined('MASH_LENGTH_IMAGE')) define('MASH_LENGTH_IMAGE', 1);
if (! defined('MASH_LENGTH_TRANSITION')) define('MASH_LENGTH_TRANSITION', 1);
if (! defined('MASH_LENGTH_FRAME')) define('MASH_LENGTH_FRAME', 2);
if (! defined('MASH_LENGTH_THEME')) define('MASH_LENGTH_THEME', 3);
if (! defined('MASH_LENGTH_EFFECT')) define('MASH_LENGTH_EFFECT', 4);

if (! defined('MASH_VOLUME_MUTE')) define('MASH_VOLUME_MUTE', '0,0,100,0');
if (! defined('MASH_VOLUME_NONE')) define('MASH_VOLUME_NONE', '0,50,100,50');
if (! defined('MASH_FILL_CROP')) define('MASH_FILL_CROP', 'crop');
if (! defined('MASH_FILL_SCALE')) define('MASH_FILL_SCALE', 'scale');
if (! defined('MASH_FILL_STRETCH')) define('MASH_FILL_STRETCH', 'stretch');
if (! defined('MASH_FILL_NONE')) define('MASH_FILL_NONE', 'none');

function mash_clean_xml_url($url)
{
	return str_replace(' ', '%20', trim($url));
}
function mash_clip($clip_tag, $media_tag, $quantize, $index = '', $return_array = FALSE)
{
	$types = mash_clip_types();
	$result = array('result' => FALSE, 'warnings' => array(), 'error' => FALSE);
	$clip = mash_data_from_tags($clip_tag, $media_tag);
	
	$clip['index'] = $index;
	if (empty($clip['id'])) $result['warnings'][] = 'No id attribute in ' . mash_description($clip);
	else if (is_null($media_tag)) $result['warnings'][] = 'Nonexistent media in ' . mash_description($clip);
	
	// type defaults to video
	if (empty($clip['type'])) 
	{
		$result['warnings'][] = 'Assuming type video in ' . mash_description($clip);
		$clip['type'] = 'video';
	}
	// duration is float in seconds, defaulting to zero (for modules and images)
	$clip['duration'] = (empty($clip['duration']) ? FLOAT_ZERO : floatval($clip['duration']));

	$clip['trimstart'] = (empty($clip['trimstart']) ? 0 : intval($clip['trimstart']));
	$clip['trimend'] = (empty($clip['trimend']) ? 0 : intval($clip['trimend']));
		
	// loops is int, defaulting to one
	$clip['loops'] = (empty($clip['loops']) ? 1 : intval($clip['loops']));
								
	if (isset($clip['source'])) $clip['source'] = mash_clean_xml_url($clip['source']);
	if (isset($clip['symbol'])) $clip['symbol'] = mash_clean_xml_url($clip['symbol']);
	
	if (! in_array($clip['type'], $types)) 
	{
		$result['warnings'][] = 'Ignoring unknown type in ' . mash_description($clip);
		$clip = FALSE;
	}
	if ($clip)
	{
		$clip['speed'] = (empty($clip['speed']) ? FLOAT_ONE : floatval($clip['speed']));
		switch($clip['type'])
		{
			case 'frame':
			{
				$clip['frame'] = (empty($clip['frame']) ? 0 : intval($clip['frame']));
				$clip['fps'] = (empty($clip['fps']) ? $quantize : intval($clip['fps']));
				if (! ($clip['frame'] && $clip['fps'])) $clip['quantized_frame'] = 0;
				else $clip['quantized_frame'] = ceil((floatval($clip['frame']) / floatval($clip['fps'])) * $quantize);
			} // intentional fall through to video
			case 'video':
			case 'image':
			{
				if (empty($clip['fill'])) $clip['fill'] = MASH_FILL_STRETCH;
				break;
			}
			case 'audio':
			{
				if ((! empty($clip['volume'])) && ($clip['volume'] == MASH_VOLUME_MUTE)) 
				{
					$result['warnings'][] = 'Ignoring muted audio in ' . mash_description($clip);
					$clip = FALSE;
				}
				break;
			}
		}
	}
	if ($clip)
	{
		switch($clip['type'])
		{
			case 'video':
			{
				if (isset($clip['audio']) && empty($clip['audio'])) 
				{
					$clip['volume'] = MASH_VOLUME_MUTE;
					break;
				}
			} // intentional fall through to audio
			case 'audio':
			{
				$clip['volume'] = (empty($clip['volume']) ? MASH_VOLUME_NONE : $clip['volume']);
			}
		}
		if (! isset($clip['track']))
		{
			switch($clip['type'])
			{
				case 'effect':
				case 'audio': 
				{
					$clip['track'] = 1;
					break;
				}
				default: $clip['track'] = 0;
			}
			$result['warnings'][] = 'Assuming track ' . $clip['track'] . ' in ' . mash_description($clip);
		}
		else $clip['track'] = intval($clip['track']);
		
		if (empty($clip['start'])) 
		{
			if (! isset($clip['start'])) $result['warnings'][] = 'Assuming start zero in ' . mash_description($clip);
			$clip['start'] = 0;
		}
		if ($clip['track'] < 0)  
		{
			// start is sum of clip start and the starts of each parent
			$clip['start'] = __nested_start($clip_tag, $media_tag); 
			if ($clip['start'] < 0) 
			{
				$result['warnings'][] = 'Ignoring additional composite in ' . mash_description($clip);
				$clip = FALSE; // composite, but not first
			}	
		}
	}
	if ($clip)
	{
		if (! isset($clip['length']))
		{
			$clip['length'] = 0;
			
			if (float_gtr($clip['duration'], FLOAT_ZERO)) // try to figure length from duration
			{
				$result['warnings'][] = 'Determining length from duration in ' . mash_description($clip);
				$clip['length'] = intval(floor(floatval($clip['loops']) * $clip['duration'] * $quantize)) - ($clip['trimend'] + $clip['trimstart']);
			}
			else // use the default length for clip type
			{
				$k = 'MASH_LENGTH_' . strtoupper($clip['type']);
				if (defined($k)) 
				{
					$result['warnings'][] = 'Using default length for type in ' . mash_description($clip);
					$clip['length'] = intval(floor(floatval(constant($k)) * $quantize));
				}
			}
		}
		
		if (! ($clip['length'] > 0)) 
		{
			$result['error'] = 'Could not determine length in ' . mash_description($clip);
			$clip = FALSE;
		}
		else if (! float_gtr($clip['duration'], FLOAT_ZERO)) // determine duration from length
		{
			$clip['duration'] = floatval($clip['length'] + $clip['trimend'] + $clip['trimstart']) / $quantize;
		}
	}
	if ($clip) 
	{
		$clip['stop'] = $clip['start'] + $clip['length'];
	}
	if (! $return_array) return $clip;
	$result['result'] = $clip;
	return $result;
}
function mash_clip_between($clip, $start, $stop)
{
	$between = FALSE;
	if ($stop > $clip['start'])
	{
		// I start before stop time
		if ($clip['stop'] > $start)
		{
			// I stop after start time
			$between = TRUE;
		} 
	}
	return $between;
}
function mash_clip_types()
{
	return array('audio', 'image', 'video', 'frame', 'effect', 'transition', 'theme', 'mash');
}
function mash_clips_between(&$clips, $start, $stop) // returns clips between supplied points
{
	$video_clips = array();
	$z = sizeof($clips);	
	for ($i = 0; $i < $z; $i++)
	{
		$clip = &$clips[$i];
		if (
			($clip['type'] != 'audio')
			&& ($clip['start'] < $stop)
			&& ($clip['stop'] > $start)
		) $video_clips[] = $clip;
	}
	return $video_clips;
}
function mash_data_from_tags($tag, $other_tag = NULL)
{
	$data = array();
	if (! is_null($other_tag))
	{
		$attributes = $other_tag->attributes();
		foreach($attributes as $k => $v) $data[strval($k)] = strval($v);
	}
	if (is_object($tag))
	{
		$attributes = $tag->attributes();
		foreach($attributes as $k => $v) $data[strval($k)] = strval($v);
	}
	return $data;
}
function mash_description($data, $verbose = FALSE)
{
	$bits = array();
	$id = (isset($data['id']) ? $data['id'] : '' );
	$index = (isset($data['index']) ? $data['index'] : '' );
	$type = (isset($data['type']) ? $data['type'] : '' );
	$label = (isset($data['label']) ? $data['label'] : '' );
	
	if ($type) $bits[] = $type;
	if (strlen($index)) $bits[] = 'clip ' . (1 + $index);
	if (strlen($id)) $bits[] = 'ID ' . $id;
	if (strlen($label)) $bits[] = '(' . $label . ')';
	if ($verbose)
	{
		$pairs = array();
		foreach($data as $k => $v)
		{
			switch($k)
			{
				case 'id':
				case 'index':
				case 'type':
				case 'label': break;
				default: $pairs[] = "$k:$v";
			}
		}
		if ($pairs) $bits[] = '{' . join(', ', $pairs) . '}';
	}
	return join(' ', $bits);
}
function mash_duration($xml, $return_array = FALSE)
{	
	$result = array('warnings' => array(), 'error' => FALSE, 'result' => 0);
	$duration = 0;
	$media_id_lookup = array(); // holds references to all media tags
	$mash_tag = NULL;
	if ($xml->getName() == 'mash') $mash_tag = $xml;
	else
	{
		$mash_tags = $xml->xpath('//mash'); // there will be some, or mash_duration would have choked
		if (sizeof($mash_tags)) $mash_tag = $mash_tags[0];
	}
	if (is_null($mash_tag)) $result['error'] = 'No mash tag found';
	else
	{
		$quantize = strval($mash_tag['quantize']);
		$quantize = ($quantize ? floatval($quantize) : FLOAT_ONE);
		$media_tags = $xml->xpath('//media'); // media can be outside mash tag
		$media_count = sizeof($media_tags);
		for ($i = 0; $i < $media_count; $i++)
		{
			$media_tag = $media_tags[$i];
			$media_id_lookup[strval($media_tag['id'])] = $media_tag;
		}
		// grab first tier clip tags within mash (not nested ones)
		$clip_tags = $mash_tag->clip;
		$clip_count = sizeof($clip_tags);
		for ($i = 0; $i < $clip_count; $i++)
		{
			$media_tag = NULL;
			$clip_tag = $clip_tags[$i];
			$id = (string) $clip_tag['id'];
			if ($id && (! empty($media_id_lookup[$id]))) $media_tag = $media_id_lookup[$id];
			$mash_clip = mash_clip($clip_tag, $media_tag, $quantize, $i, TRUE);
			if (! empty($mash_clip['warnings'])) $result['warnings'] = array_merge($result['warnings'], $mash_clip['warnings']);
			if (! empty($mash_clip['error'])) 
			{
				$result['error'] = $mash_clip['error'];
				break;
			}
			if (! empty($mash_clip['result'])) $duration = max($mash_clip['result']['stop'], $duration);
		}
	}
	if (! $return_array) return $duration;
	if ((! $result['error']) && (! ($duration > 0))) $result['error'] = 'Mash has no duration ' . $duration;
	$result['result'] = $duration;
	return $result;
}

function mash_info($xml, $trim = 0, $length = 0, $exact = FALSE)
{	
	// 'config' attributes in tags are NOT supported
	
	$result = array();
	$result['error'] = '';
	$result['warnings'] = array(); // nonfatal but potentially problematic issues
	$result['duration'] = 0;
	$result['has_audio'] = FALSE;
	$result['has_video'] = FALSE;
	$result['label'] = '';
	$result['id'] = '';
	$result['render_all'] = $exact; // switch for full flash rendering
	$result['cache_audio_urls'] = array(); //  files having audio needing to be cached
	$result['cache_video_urls'] = array(); // visual files needing to be cached (images and video)
	$result['cache_module_urls'] = array(); // fonts, modules and things required by modules (their source attributes)
	$result['cache_mash_urls'] = array(); // source attributes from media of type mash
	
	$result['flashframes'] = array(); // array(startframe, stopframe)
	$result['fonts'] = array();
	$result['clips'] = array(); // linear array() of arrays with keys needed for quick sorting and time based retrieval (start, stop)
	$media_id_lookup = array(); // holds references to all media tags (they may get altered)
	$render_clips = array();
	$mash_duration = mash_duration($xml, TRUE);
	if (! empty($mash_duration['error'])) 
	{
		if ($mash_duration['warnings']) $result['warnings'] = array_merge($result['warnings'], $mash_duration['warnings']);
		$result['error'] = $mash_duration['error'];
	}
	if (! $result['error'])
	{
		if ($xml->getName() == 'mash') $mash_tag = $xml;
		else
		{
			$mash_tags = $xml->xpath('//mash'); // there will be some, or mash_duration would have choked
			if (sizeof($mash_tags)) $mash_tag = $mash_tags[0];
		}
		$result['duration'] = $mash_duration['result'];
		$result['label'] = strval($mash_tag['label']);
		$result['id'] = strval($mash_tag['id']);
		$quantize = strval($mash_tag['quantize']);
		$quantize = ($quantize ? floatval($quantize) : FLOAT_ONE);
		$result['quantize'] = $quantize;
		$start = 0;
		$stop = $result['duration'];
		if ($trim || $length)
		{
			$start = $trim; //intval(round(floatval($trim) / $quantize));
			if (! $length) $length = $result['duration'] - $start;
			//else $length = intval(round(floatval($length) / $quantize));
			$stop = $start + $length;
		}
		
		$fonts = array();
		$font_tags = $xml->xpath(MASH_XPATH_FONT);
		foreach($font_tags as $font_tag)
		{
			$font = mash_data_from_tags($font_tag);
			if (empty($font['id']))
			{
				if (isset($fonts['default'])) $result['warnings'][] = 'Default font already set, ignoring ' . mash_description($font);
				else $font['id'] = 'default';
			}
			if (! empty($font['id'])) 
			{
				if (isset($fonts[$font['id']])) $result['warnings'][] = 'ID exists, ignoring ' . mash_description($font);
				else 
				{
					$font['url'] = mash_clean_xml_url($font['url']);
					if (empty($font['url'])) $result['warnings'][] = 'Attribute url undefined, ignoring ' . mash_description($font);
					else if (! preg_match(MASH_PATTERN_SWF, $font['url'])) $result['warnings'][] = 'Attribute url invalid, ignoring ' . mash_description($font);
					else $fonts[$font['id']] = $font;
				}
			}
		}

		
		// grab all media tags, even nested ones
		$media_tags = $xml->xpath('//media');
		
		$media_count = sizeof($media_tags);
		for ($i = 0; $i < $media_count; $i++)
		{
			$media_tag = $media_tags[$i];
			$media_id_lookup[strval($media_tag['id'])] = $media_tag;
		}
		
		// grab all clip tags within mash, even nested ones
		$clip_tags = $mash_tag->xpath('//clip');
		$clip_count = sizeof($clip_tags);
		
		for ($i = 0; ((! $result['error']) && ($i < $clip_count)); $i++)
		{
			$media_tag = NULL;
			$clip_tag = $clip_tags[$i];
			$id = (string) $clip_tag['id'];
			if ($id) $media_tag = (isset($media_id_lookup[$id]) ? $media_id_lookup[$id] : NULL);
			
			$mash_clip = mash_clip($clip_tag, $media_tag, $quantize, $i, TRUE);
			if (! empty($mash_clip['error'])) $result['error'] = $mash_clip['error'];
			
			if (! $result['error'])
			{
				if ($mash_clip['warnings']) $result['warnings'] = array_merge($result['warnings'], $mash_clip['warnings']);
				$clip = $mash_clip['result'];
			}
			if (! $result['error'])
			{
				if (! $clip) continue; // true if it was composite but not first
				
				if (! mash_clip_between($clip, $start, $stop)) 
				{
					$result['warnings'][] = 'Outside range ' . $start . '->' . $stop . ' in ' . mash_description($clip);
					continue;
				}
				switch ($clip['type'])
				{
					case 'mash':
					{
						$result['cache_mash_urls'][$clip['url']] = mash_description($clip);
						break;
					}
					case 'effect':
					{
						$render_clips[] = $clip;
						if ($clip['track'] < 0) 
						{
							// check if effect clip is attached to mash itself
							$parent_tag = __parent_tag($clip_tag);
							if ($parent_tag->getName() == 'mash') $result['render_all'] = 1;
						}
					} // fall through to other modules
					case 'theme': if ($clip['track'] == 0) $render_clips[] = $clip;
					case 'transition': 
					{	
						if ($clip['type'] == 'transition') $render_clips[] = $clip;
						if (! empty($clip['font']))
						{
							if (empty($fonts[$clip['font']])) $result['error'] = 'Nonexistent font (ID: ' . $clip['font'] . ') required for ' . mash_description($clip);
							else 
							{
								$result['cache_module_urls'][$font['url']] = mash_description($font);
								$result['fonts'][$font['id']] = $font;
							}
						}
						if (empty($clip['symbol'])) $result['error'] = 'Attribute symbol required for ' . mash_description($clip);
						else
						{
							
							if (! preg_match(MASH_PATTERN_SWF, $clip['symbol'])) $result['error'] = 'Attribute symbol invalid in ' . mash_description($clip);
							else
							{
								$result['cache_module_urls'][$clip['symbol']] = mash_description($clip);
								$result['has_video'] = TRUE;
								if (! empty($clip['source'])) // modules like Bender require an auxiliary file
								{
									
									$result['cache_module_urls'][$clip['source']] = mash_description($clip);
								}
							}
						}
						break;
					}
					default: // all true assets including audio - no modular media or mashes
					{
						if (empty($clip['source'])) $result['error'] = 'Attribute source required in ' . mash_description($clip);
						else 
						{
							
							if (! file_extension($clip['source'])) $result['error'] = 'Attribute source extension require in ' . mash_description($clip);
							else 
							{
								$could_have_audio = (($clip['type'] == 'audio') || ($clip['type'] == 'video'));
								if ($clip['type'] == 'video') 
								{
									$could_have_audio = ((! isset($clip['audio'])) || ($clip['audio'] !== '0'));
									$not_time_shifted = float_cmp($clip['speed'], FLOAT_ONE);
									if ($could_have_audio) $could_have_audio = $not_time_shifted;
									if (! $not_time_shifted) $render_clips[] = $clip;
								}
								if ($could_have_audio) $could_have_audio = (empty($clip['volume']) || ($clip['volume'] != MASH_VOLUME_MUTE));
								if ($clip['type'] != 'audio') 
								{
									$result['has_video'] = TRUE;
									$result['cache_video_urls'][$clip['source']] = mash_description($clip);
								}
								else if (! $could_have_audio) $clip = FALSE;
								if ($could_have_audio) 
								{
									$clip['has_audio'] = TRUE;
									$result['cache_audio_urls'][$clip['source']] = mash_description($clip);
								}
							}
						}
					}
				}
			}
			if ((! $result['error']) && $clip) $result['clips'][] = $clip;
		}
	}
	if (! $result['error'])
	{
		usort($result['clips'], '__sort_by_start');
		
		if (! empty($result['render_all']))
		{
			$result['flashframes'][] = array(0, $result['duration']);
		}
		else
		{
			usort($render_clips, '__sort_by_start');
		
			// determine flashframes of all clips requiring flash rendering
			$z = sizeof($render_clips);
			
			for ($i = 0; $i < $z; $i++)
			{
				$clip = $render_clips[$i];
				$clip_start_frame = max($start, $clip['start']);
				$clip_stop_frame = min($stop, $clip['stop']);
				$y = sizeof($result['flashframes']);
				for ($j = $y - 1; $j > -1; $j--)
				{
					$spanstart_frame = $result['flashframes'][$j][0];
					$spanstop_frame = $result['flashframes'][$j][1];
					if ( ! (($clip_start_frame > $spanstop_frame) || ($spanstart_frame > $clip_stop_frame)))
					{
						// they touch or overlap, so remove and expand
						$clip_start_frame = min($clip_start_frame, $spanstart_frame);
						$clip_stop_frame = max($clip_stop_frame, $spanstop_frame);
						array_splice($result['flashframes'], $j, 1);
					}
				}
				$result['flashframes'][] = array($clip_start_frame, $clip_stop_frame);
			}
			usort($result['flashframes'], '__framesort');
			if (sizeof($result['flashframes']) == 1)
			{
				if (($result['flashframes'][0][0] == 0) && ($result['flashframes'][0][1] == $result['duration']))
				{
					$result['render_all'] = 1;
				}
			}
		}		
	}
	$result['has_audio'] = (count($result['cache_audio_urls']) > 0);

	return $result;
}
function mash_is_moviemasher_path($path)
{
	return (strpos($path, '/com/moviemasher/') !== FALSE);
}
function mash_clip_duration($clip, $start, $stop)
{
	$clip_start = $clip['start'];
	$clip_stop = $clip_start + $clip['length'];
	
	if ($start > $clip_start) $clip_start = $start;
	if ($clip_stop > $stop) $clip_stop = $stop;

	return $clip_stop - $clip_start;
}
function mash_trim_frame($clip, $start, $stop, $fps = 44100) 
{
	$result = array();
	$fps = intval($fps);
	$orig_clip_length = $clip['length'];
	$speed = floatval($clip['speed']);
	
	$media_duration = intval(floor($clip['duration'] * floatval($fps)));
	if ($media_duration <= 0) $media_duration = $clip['length'];
	$media_duration = intval(floor(floatval($media_duration) * $speed));
	$orig_clip_start = $clip['start'];
	if ($clip['track'])
	{
		$start -= $orig_clip_start;
		$stop -= $orig_clip_start;
		$orig_clip_start = 0;
	}
	$orig_clip_end = $orig_clip_length + $orig_clip_start;
	$clip_start = max($orig_clip_start, $start);
	$clip_length = min($orig_clip_end, $stop) - $clip_start;
	
	$orig_clip_trimstart = $clip['trimstart'];
	$clip_trimstart = $orig_clip_trimstart + ($clip_start - $orig_clip_start);

	if ($media_duration) $clip_length = min($clip_length, $media_duration - $clip_trimstart);
	if ($clip_length > 0)
	{
		$result['offset'] = ($clip_start - $orig_clip_start);
		$result['trimstart'] = $clip_trimstart;
		$result['trimlength'] = $clip_length;
	}
	else
	{
		$result['error'] = '';
		$result['error'] .= '$clip_length = ' . $clip_length;
		$result['error'] .= "\n" . 'min($orig_clip_end, $stop) - $clip_start = ' . (min($orig_clip_end, $stop) - $clip_start) . ' = min(' . $orig_clip_end . ', ' . $stop . ') - ' . $clip_start;
		$result['error'] .= "\n" . '$clip_start = max($orig_clip_start, $start) = max(' . $orig_clip_start . ', ' . $start . ')';
	}
	return $result;
}
function __framesort($a, $b)
{
	if (($a[0] > $b[0])) return 1;
	if (($a[0] == $b[0])) return 0;
	return -1;
}
function __nested_start($tag, $media_tag)
{
	$neg_one = -1;
	// start for a nested tag is the sum of its start and its parents
	$parent = $tag;
	$result = intval($parent['start']);
	while (($parent != NULL) && (intval($parent['track']) < 0))
	{
		
		$child = $parent;
		$parent = __parent_tag($child);
		
		switch($child['type'])
		{
			case 'theme': // TODO: create a property for themes to indicate how many composites to utilize
			case 'video':
			case 'frame':
			case 'image':
			{
				// my parent is some sort of composite
				// only include me if I'm the first non effect child tag
				if ($parent != NULL) 
				{
					$children = $parent->children();
					$z = sizeof($children);
					if ($z)
					{
						for ($i = 0; $i < $z; $i++)
						{
							$first_child = $children[$i];
							if (($first_child->getName() == 'clip') && (((string) $first_child['type']) != 'effect')) break;
						}
						if ( ! ( ($first_child == $child) || ($first_child->asXML() == $child->asXML())))
						{
							return $neg_one;
						}
					}
				}
			}
		}
		if ($parent != NULL)
		{
			$result += intval($parent['start']);
		}
	}
	return $result;
}
function __parent_tag($tag)
{
	$dom = dom_import_simplexml($tag);
	$tag = NULL;
	$dom = $dom->parentNode;
	if ($dom != NULL) $tag = simplexml_import_dom($dom);
	return $tag;
}
function __sort_by_start($a, $b)
{
	if ($a['start'] > $b['start']) return 1;
	if ($a['start'] == $b['start']) return 0;
	return -1;
}
?>