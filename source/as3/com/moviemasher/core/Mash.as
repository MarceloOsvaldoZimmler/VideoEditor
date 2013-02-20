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

package com.moviemasher.core
{
	import com.moviemasher.control.*;
	import com.moviemasher.events.*;
	import com.moviemasher.interfaces.*;
	import com.moviemasher.display.*;
	import com.moviemasher.stage.*;
	import com.moviemasher.type.*;
	import com.moviemasher.constant.*;
	import com.moviemasher.utils.*;
	import flash.display.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.media.*;
	import flash.system.*;
	import flash.utils.*;
/**
* Class represents a collection of clips (edit decision list).
*
* @see IClip
* @see IMash
*/
	public class Mash extends Propertied implements IMash
	{
		public static function fromURL(source: String):IMash
		{
			var x:XML = <media type='mash' />;
			x.@source = source;
			return fromXML(x);
		}
		public static function fromXML(node: XML):IMash
		{
			var mash : IMash = null;
			try 
			{
				if (node != null)
				{
					
					if (node.name() == 'media')
					{
						node = node.copy();
						var new_node:XML = <mash />;
						XMLUtility['copyAttributes'](node, new_node);
						new_node.setChildren(node.children());
						node = new_node;
					}
				}
				if (mash == null)
				{
					mash = new Mash();
					if (node != null)
					{
						mash.tag = node.copy();
					}
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg']('Mash', e);
			}
			return mash;
		}
		public static function fromMediaXML(node: XML, preview:String = '', clip_xml:XML = null):IMash
		{
			var mash : IMash = null;
			try 
			{
				var type:String = node.@type;
				if (type == ClipType.MASH) return fromXML(node);
				
				var quantize:Number = RunClass.TimeUtility['fps'];
				var w:Number = 0;
				var h:Number = 0;
				var player:IPropertied = RunClass.MovieMasher['getByID'](ReservedID.PLAYER) as IPropertied;
				if (player != null)
				{
					w = player.getValue('displaywidth').number;
					h = player.getValue('displayheight').number;
				}
				var mash_xml:XML;
				mash_xml = <mash />;
				
				mash_xml.@crop = "1";
				mash_xml.@width = w;
				mash_xml.@height = h;
				mash_xml.@quantize = quantize;
				mash_xml.appendChild(node.copy());
				mash_xml.@[MediaProperty.LABEL] = node.@[MediaProperty.LABEL];
				if (clip_xml == null) clip_xml = <clip />;
				var s:String;
				var a:Array;
				var img_media_xml:XML = null;
				var img_clip_xml:XML = null;
						
				s = String(type);
				clip_xml.@id = node.@id;
				clip_xml.@composites = node.@composites;
				if (! String(clip_xml.@type).length) clip_xml.@type = s;
				switch(s)
				{
					case ClipType.IMAGE:
						clip_xml.@fill = 'crop';
						break;
					case ClipType.AUDIO:
						clip_xml.@track = 1;
						s = node.@wave;
						if (! s.length) s = node.@icon;
						if (s.length)
						{
							img_media_xml = <media />;
							img_clip_xml = <clip />;
							img_media_xml.@type = ClipType.IMAGE;
							img_clip_xml.@type = ClipType.IMAGE;
							img_clip_xml.@fill = 'stretch';
							img_media_xml.@url = s;
							s = RunClass.MD5['hash'](s);
							img_media_xml.@id = s;
							img_clip_xml.@id = s;
							img_clip_xml.@length = quantize * Number(node.@duration);
							mash_xml.appendChild(img_media_xml);
							mash_xml.appendChild(img_clip_xml);
						}
						break;
					case ClipType.EFFECT:
						clip_xml.@track = 1;
						img_media_xml = <media />;
						img_clip_xml = <clip />;
						
						img_media_xml.@type = ClipType.IMAGE;
						img_clip_xml.@type = ClipType.IMAGE;
						s = preview;
						img_media_xml.@url = s;
						s = RunClass.MD5['hash'](s);
						img_media_xml.@id = s;
						img_clip_xml.@id = s;
						//clip_xml.@length = 10;
						//img_clip_xml.@length = clip_xml.@length;
						img_clip_xml.appendChild(clip_xml);
						clip_xml = img_clip_xml;
						mash_xml.appendChild(img_media_xml);
						break;
					case ClipType.TRANSITION:
						img_media_xml = <media />;
						img_clip_xml = <clip />;
						img_media_xml.@type = ClipType.IMAGE;
						img_clip_xml.@type = ClipType.IMAGE;
						
						s = preview;
						a = s.split(',');
						s = a[0];
						img_media_xml.@url = s;
						s = RunClass.MD5['hash'](s);
						img_media_xml.@id = s;
						img_clip_xml.@id = s;
					//	img_clip_xml.@fill = 'crop';
						//clip_xml.@length = 10;
						img_clip_xml.@length = quantize * 1;
						mash_xml.appendChild(img_clip_xml);
						mash_xml.appendChild(clip_xml);
						mash_xml.appendChild(img_media_xml);
						s = a[1];
						img_media_xml = img_media_xml.copy();
						img_clip_xml = img_clip_xml.copy();
						img_media_xml.@url = s;
						s = RunClass.MD5['hash'](s);
						img_media_xml.@id = s;
						img_clip_xml.@id = s;
						//clip_xml.@length = 10;
						img_clip_xml.@length = quantize * 1;
						clip_xml = img_clip_xml;
						mash_xml.appendChild(img_media_xml);
						break;
				}
				mash_xml.appendChild(clip_xml);
				//RunClass.MovieMasher['msg']('Mash.fromMediaXML ' + mash_xml.toXMLString());
				mash = fromXML(mash_xml);
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg']('Mash.fromMediaXML', e);
			}
			return mash;
		}
		public function Mash()
		{
			__bufferTime = new Time(10, 1);
			__minbufferTime = new Time(1, 1);
			__unbufferTime = new Time(2, 1);
			
	
			__initialize();
		}
		public function buffer(range:TimeRange, mute:Boolean):void
		{
			//RunClass.MovieMasher['msg'](this + '.buffer ' + range + ' ' + mute);
			var limited_range:TimeRange = __limitRange(range);
			
			__mute = mute;
			
			__buffer(limited_range);			
		}
		public function buffered(range:TimeRange, mute:Boolean):Boolean
		{
			var is_buffered:Boolean = (! isNaN(__lengthFrame));
			if (is_buffered)
			{
				try
				{
					var limited_range:TimeRange = __limitRange(range);
					var clip:IClip;
					var clip_range:TimeRange;
					var clips:Dictionary = __clipRanges(limited_range);
					for (var ob:* in clips) // does not include embedded effects
					{
						clip = ob;
						if (mute && (clip.type == ClipType.AUDIO))
						{
							continue;
						}
						clip_range = clips[ob];
						is_buffered = clip.buffered(clip_range, mute);
						
						if (! is_buffered)
						{
							//RunClass.MovieMasher['msg'](this + '.buffered ! ' + clip);
							break;
						}
					}
				}
				catch(e:*)
				{
					RunClass.MovieMasher['msg'](this + '.buffered', e);
				}		
			}	
			//RunClass.MovieMasher['msg'](this + '.buffered ' + range + ' mute = ' + mute + ' ' + is_buffered);
			return is_buffered;
		}
		public function visibleClipsAtTime(time:Time):Vector.<IClip>
		{
			var clips:Vector.<IClip> = new Vector.<IClip>();

			var range:TimeRange = time.timeRange;
			var clip:IClip;
			var child:IClip;
			var effects:Array;
			
			var type:String;
			var clip_ranges:Dictionary = __clipRanges(range);
			var k:*;
			for (k in clip_ranges)
			{
				clip = k as IClip;
				type = clip.type;
				if (type == ClipType.AUDIO) continue; // just visuals!
				
				clips.push(clip);
				effects = clip.getValue(ClipProperty.EFFECTS).array;
				for each (child in effects)
				{
					clips.push(child);
				}
				effects = clip.getValue(ClipProperty.COMPOSITES).array;
				for each (child in effects)
				{
					clips.push(child);
				}
			}
			return clips;
		}
		public function clipsInRange(range:TimeRange):Array
		{
			var clips:Array = new Array();
			var clip_ranges:Dictionary = __clipRanges(range);
			var k:*;
			for (k in clip_ranges)
			{
				clips.push(k);
			}
			return clips;
		}
		public function clipsInTracks(first:Number, last:Number, type:String, transitions:Boolean = false, track:int = 0, count:int = 0):Array
		{
			var last_track:int = track + count;
			var atTime:Number = first;
			var for_duration:Number = last - first;
			var time_clips:Array = new Array();
			var clip:IClip;
			var end_time:Number = last;
			var av_clips:Array = __tracks[type];
			var clip_start:Number;
			var clip_end:Number;
			var z:int = av_clips.length;
			var clip_track:int;
			var clip_length:Number;
			for (var i:int = 0; i < z; i++)
			{
				clip = av_clips[i];
				clip_start = clip.startFrame;
				clip_start -= clip.startPadFrame;
				if (transitions)
				{
					clip_start += clip.getValue(ClipProperty.TIMELINESTARTFRAME).number;
				}
				if (clip_start > end_time)
				{
					break;
				}
				clip_length = clip.lengthFrame;
				clip_end = clip_start + clip_length + clip.startPadFrame;
				if (transitions)
				{
					clip_end -= clip.getValue(ClipProperty.TIMELINEENDFRAME).number;
				}

				if (clip_end > atTime)
				{
					if (type != ClipType.VIDEO)
					{
						// see if track is valid
						clip_track = clip.track;
						if ((track && (clip_track < track)) || (last_track && (clip_track > last_track)))
						{
							continue;
						}
					}
					time_clips.push(clip);
				}
			}
			if (track) 
			{
				time_clips.sort(sortByTrack);
			}
			return time_clips;
		}
		public function clipsInOuterTracks(first:Number, last:Number, ignore:Array = null, track:int = 0, count:int = 0, type:String = ''):Array
		{
			var atTime:Number = first;
			var for_duration:Number = last - first;
			var z:int;
			var ignore_ids:Dictionary = new Dictionary();
			var i:int;
			if (ignore != null)
			{
				z = ignore.length;
				for (i = 0; i < z; i++)
				{
					ignore_ids[ignore[i]] = true;
				}
			}
			var track_clips:Array = __tracks[type];
			var items:Array = new Array();
			var clip:IClip;
			var end_time:Number = atTime + for_duration;
			z = track_clips.length;
			var start_range:int = ((type == ClipType.EFFECT) ? (track - count) + 1 : track);
			var end_range:int = ((type == ClipType.EFFECT) ? track : (track + count - 1));
			var clip_start:Number;
			var clip_track:int;
			var clip_length:Number;
			for (i = 0; i < z; i++)
			{
				clip = track_clips[i];
				if (ignore_ids[clip] != null)
				{
					continue;
				}
				clip_track = clip.track;
				if ((clip_track < start_range) || (clip_track > end_range))
				{
					continue;
				}
				clip_start = clip.startFrame;
				if (clip_start >= end_time)
				{
					break;
				}
				clip_length = clip.lengthFrame;
				if ((clip_start + (clip_length ? clip_length : 1)) > atTime)
				{
					items.push(clip);
				}
			}
			return items;
		}
		public function editableProperties():Array
		{
			
			var a:Array = null;
			var nons:Array;
			if (! getValue(MashProperty.READONLY).boolean)
			{				
				nons = getValue(MediaProperty.NONEDITABLE).array;
				a = new Array();
				for (var property:String in _defaults)
				{
					if (nons.indexOf(property) == -1)
					{
						if (propertyDefined(property))
						{
							a.push(property);
						}
					}
				}
			}
			return a;

		}
		public function freeTime(first:Number, last:Number, type:String = '', ignore:Array = null, track:int = 0, count:int = 0):Number
		{
			var atTime:Number = first;
			var for_duration:Number = last - first;
			
			if (atTime < 0)
			{
				return atTime;
			}
			var fTracks:Array = clipsInOuterTracks(atTime, atTime + for_duration, ignore, track, count, type);
			var z:int = fTracks.length;

			var clip:IClip;
			var clip_start:Number;
			var best_time:Number = -1;
			var n:Number;
			if (z)
			{
				for (var i:int = 0; i < z; i++)
				{
					clip = fTracks[i];
					clip_start = clip.startFrame;
					n = clip_start + clip.lengthFrame;

					if (clip_start < atTime)
					{
						// try to put it to the right
						fTracks = clipsInOuterTracks(n, n + for_duration, ignore, track, count, type);
						if (! fTracks.length)
						{
							best_time = n;
						}
						break;
					}
					if (n > (atTime + for_duration))
					{
						n = clip_start - for_duration;
						if (n >= 0)
						{
							fTracks = clipsInOuterTracks(n, n + for_duration, ignore, track, count, type);
							if (! fTracks.length)
							{
								best_time = n;
							}
						}
						break;
					}
				}
			}
			else
			{
				best_time = atTime;
			}
			return best_time;
		}
		public function freeTrack(first:Number, last:Number, type:String, count:uint):uint
		{
			var a_clips:Array = clipsInTracks(first, last, type);
			a_clips.sort(sortByTrack);
			var z:uint = a_clips.length;
			var defined_tracks:Object = new Object();
			var key:String;
			for (var i:uint = 0; i < z; i++)
			{
				key = 't' + a_clips[i].track;
				if (defined_tracks[key] == null) defined_tracks[key] = true;
			}
			var track:uint = 0;
			var track_ok:Boolean = false;
			while (! track_ok)
			{
				track_ok = true;
				track ++;
				z = track + count;
				for (i = track; i < z; i++)
				{
					if (defined_tracks['t' + i])
					{
						track_ok = false;
						break;
					}
				}
			}
			return track;
		}
		public function getAudioDatum(position:uint, length:int, samples_per_frame:int):Vector.<AudioData>
		{
			// we always use our own, based on quantize
			samples_per_frame = Math.round(Number(Sampling.SAMPLES_PER_SECOND) / Number(__quantize));

			var vector:Vector.<AudioData> = null;
			var clip_vector:Vector.<AudioData> = null;
			var audio_data:AudioData;
			var test_start:int;
			var clip_start:Number;
			var test_end:int;
			var y,j,i,z:uint;
			var clip:IClip;
			var type:String;
			var track_clips:Array;
			var last:int;
			var clips:Vector.<IClip> = new Vector.<IClip>();
			var max_samples:int = (__lengthFrame) * samples_per_frame;
			length = Math.min(length, max_samples - position);
			z = __trackTypes.length;
			for (i = 0; i < z; i++)
			{
				type = __trackTypes[i];
				track_clips = __tracks[type];
				y = track_clips.length;
				for (j = 0; j < y; j++)
				{
					clip = track_clips[j];
					if (! clip.getValue(ClipProperty.HASAUDIO).boolean) continue;
					clip_start = clip.startFrame;
					test_start = samples_per_frame * int(clip_start);
					last = position + length;
					if (test_start <= last)
					{
						test_end = test_start + samples_per_frame * int(clip.lengthFrame + ((type == ClipType.VIDEO) ? clip.endPadFrame : 0));
						if (test_end > position)
						{
							clips.push(clip);
						}
					}
				}
			}
			for each (clip in clips)
			{
				clip_vector = clip.getAudioDatum(position, length, samples_per_frame);
				if (clip_vector != null)
				{
					if (vector == null) vector = clip_vector;
					else vector = vector.concat(clip_vector);
				}
			}
			if ((vector != null) && vector.length)
			{
				for each(audio_data in vector)
				{
					audio_data.volume *= __volume / 100;
				}
			}
			return vector;
		}
		public function get displayTime():Time
		{
			return __displayTime;
		}
		public function get goingTime():Time
		{
			return __goingTime;
		}
		override public function getValue(property:String):Value
		{
			var value:Value;
			switch (property)
			{
				case 'revert':
					value = new Value((__needsSave && __revertable) ? 1 : 0);
				//	RunClass.MovieMasher['msg'](this + '.getValue ' + property + ' ' + value.string);
					break;
				case ClipProperty.HASAUDIO:
					value = new Value((__volume && (tracks.audio.length || __clipsHaveAudio())) ? 1 : 0);
					break;
				case 'transfers':
					value = new Value(__transfers());
					break;
				case MashProperty.QUANTIZE:
					value = new Value(__quantize);
					break;
				case TagType.CLIP:
				case TextProperty.FONT:
					// so _tag[property] isn't returned
					//value = new Value();
					break;
				case ClipProperty.MEDIA:
					value = new Value(__xmlMedia());
					break;
				case ClipProperty.VOLUME:
					value = new Value(__volume);
					break;
				case MashProperty.STALLING:
					value = new Value(__stalling ? 1 : 0);
					break;
				case ClipProperty.MASH: // needed to support selection of mash in timeline
					value = new Value(this);
					break;
				case ClipProperty.EFFECTS:
					var effects:Array = clipsInOuterTracks(0, 1, null, -1, int.MIN_VALUE, ClipType.EFFECT);
					if (effects.length) effects.sort(sortByTrack);
					value = new Value(effects);
					break;
				case 'fatxml':
					value = new Value(__xmlFat());
					break;
				case ClipProperty.XML:
					value = new Value(__xml());
					break;
				case PlayerProperty.DIRTY:
					value = new Value(__needsSave ? 1 : 0);
					break;
				case PlayerProperty.PLAY:
					value = new Value(__paused ? 0 : 1);
					break;
				case MediaProperty.DURATION:
					value = new Value(RunClass.TimeUtility['timeFromFrame'](__lengthFrame, __quantize));
					break;
				case ClipProperty.LENGTHFRAME:
				case ClipProperty.LENGTH:
					value = new Value(__lengthFrame);
					break;
				case MashProperty.LENGTH_TIME:
					value = new Value(lengthTime);
					break;
				case MashProperty.TIME:
					value = new Value(displayTime);
					break;
				case 'ratio':
					var dims:Size = dimensions;
					value = new Value(dims.width / dims.height);
					break;
				case 'displaysize':
					value = new Value(__bitmapSize);
					break;
					
				case ClipType.VIDEO:
				case ClipType.AUDIO:
				case ClipType.EFFECT:
					value = new Value(__highest[property]);
					break;
				default:
					value = super.getValue(property);
			}
			return value;
		}
		public function goTime(object:Time = null):Boolean
		{
			var limited_range:TimeRange;
			var went_to:Boolean = false;
			if (object == null) object = __goingTime;
			if (object != null) 
			{
				__goingTime = object.copyTime();
				//RunClass.MovieMasher['msg'](this + '.goTime ' + object + ' from ' + __displayTime);
				limited_range = __goingTime.timeRange;
	
				if (__moving) limited_range.maxLength(__minbufferTime.copyTime());
				else if (! __paused) limited_range.maxLength(__bufferTime.copyTime());
				
				if (! isNaN(__lengthFrame)) 
				{
					went_to = buffered(limited_range, __paused || __mute);
					if (__paused && (! went_to)) // buffer and check buffered state again
					{
						buffer(limited_range, true);
						went_to = buffered(limited_range, true);
					}
				}
				if (went_to)
				{
					time = __goingTime;
					if (__moving) __samplePosition = Math.round(__displayTime.seconds * Sampling.SAMPLES_PER_SECOND); 
					else if (__paused) unbuffer(limited_range);
				}
				else 
				{
					__isGoingTime = true;
					if (! __paused) __bufferTimed(null); // to reset the buffering
				}
			}
			return went_to;
		}
		public function invalidateLength(type:String, dont_dirty:Boolean = false):void
		{
			//RunClass.MovieMasher['msg'](this + '.invalidateLength ' + type);
			try
			{
				switch (type)
				{
					case ClipType.AUDIO:
					case ClipType.EFFECT:
						__recalculateTrackLength(type);
						break;
					default:
						type = ClipType.VIDEO;
						__recalculateVideoLength();
				}
				__playingClipsRecalculate();
				_dispatchEvent(ClipProperty.TRACK);
				if (! dont_dirty)
				{
					setValue(new Value('1'), PlayerProperty.DIRTY);
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.invalidateLength', e);
			}			

		}
		public function invalidateLengths():void
		{
			invalidateLength(ClipType.VIDEO, true);
			if (isNaN(__lengthFrame)) return;
			invalidateLength(ClipType.AUDIO, true);
			invalidateLength(ClipType.EFFECT, true);
		}
		public function propertyDefined(property:String):Boolean
		{
			var ok:Boolean = false;
			ok = (_defaults[property] != null);
			var nons:Array;
			if (ok)
			{
				nons = getValue(MediaProperty.NONEDITABLE).array;
				ok = (nons.indexOf(property) == -1);
			}
			return ok;
		}
		public function referencedMedia():Object
		{
			
			var dictionary:Object = new Object();
			var y:uint;
			var j:uint;
			var z:uint = __trackTypes.length;
			var type:String;
			var track_clips:Array;
			for (var i:uint = 0; i < z; i++)
			{
				type = __trackTypes[i];
				track_clips = __tracks[type];
				y = track_clips.length;
				for (j = 0; j < y; j++)
				{
					track_clips[j].referencedMedia(dictionary);
				}
			}
			return dictionary;
		}
		public function set time(orig_object:Time):void
		{
			var object:Time = __limitTime(orig_object, true);
			__isGoingTime = false;
			__goingTime = object;					
			__displayTime = object;	
			__playingClipsRecalculate();
			if ((__bitmapSize != null) && (__canvasSprite != null) && (! isNaN(__lengthFrame)))
			{
				__canvasSprite.removeContent();						
				// if (! buffered(__displayTime.timeRange, true)) RunClass.MovieMasher['msg'](this + '.time ' + __displayTime + ' not buffered');
				
				var v_clips:Array = __playingVideoClips();
				if (v_clips.length == 3) __applyClips(v_clips);
				else if (v_clips.length) __applyClip(v_clips[0]);
				__canvasSprite.applyEffects(__playingEffectClips(), __displayTime);
			}	
			//else RunClass.MovieMasher['msg'](this + '.time ' + __bitmapSize + ' ' + __canvasSprite);
			_dispatchEvent(MashProperty.TIME);
		}
		override public function setValue(value:Value, property:String):Boolean
		{
			try
			{
				var do_super:Boolean = false;
				var changed_timing:Boolean = false;
				switch (property)
				{
					case 'revert':
						__revertMash();
						changed_timing = true;
						break;
					case MashProperty.QUANTIZE:
						__setQuantize(value.number);
						break;
					case ClipProperty.EFFECTS:
						__changeEffects(value.array);
						__setDirty(true);
						break;
					case PlayerProperty.UNBUFFERTIME:
						__bufferAdjust(__unbufferTime, value.number);
						changed_timing = true;
						break;
					case PlayerProperty.MINBUFFERTIME:
						__bufferAdjust(__minbufferTime, value.number);
						changed_timing = true;
						break;
					case PlayerProperty.BUFFERTIME:
						__bufferAdjust(__bufferTime, value.number);
						changed_timing = true;
						break;
					case 'dirtyaudio':
						__setDirty(value.boolean, true);
						break;
					case PlayerProperty.DIRTY: 
						__setDirty(value.boolean);
						break;
					case ClipProperty.VOLUME:
						__volume = value.number;
						__mute = ! value.boolean;
						break;
					case PlayerProperty.PLAY:
						if (value.boolean)
						{
							__mute = ! __volume;
						}
						paused = ! value.boolean;
						do_super = true;
						break;
					default:
						if ((__originalKeys != null) && (__originalKeys.indexOf(property) != -1))
						{
							__setDirty(true);
						}
						do_super = true;
				}
				if (do_super)
				{
					//RunClass.MovieMasher['msg'](this + '.setValue ' + property + ' ' + value.string + ' changed_timing=' + changed_timing + ' __paused=' + __paused);
					super.setValue(value, property);
					if (changed_timing &&  (! __paused)) 
					{
						__setMoving(false);
					}
					_dispatchEvent(property, value);
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.setValue ' + property + ' ' + __originalKeys, e);
			}
			return false;
		}
		public static function sortByTimeTrack(a:IClip, b:IClip):Number
		{
			var a_start:Number = a.startFrame;
			var b_start:Number = b.startFrame;
			if (a_start < b_start)
			{
				return -1;
			}
			if (a_start > b_start)
			{
				return 1;
			}
			return sortByTrack(a,b);

		}
		public static function sortByTimeTrans(a:IClip, b:IClip):Number
		{
			var a_start:Number = a.startFrame;
			var b_start:Number = b.startFrame;
			if (a_start < b_start)
			{
				return -1;
			}
			if (a_start > b_start)
			{
				return 1;
			}
			return sortByTrans(a,b);

		}
		public static function sortByTrack(a:IClip, b:IClip):Number
		{
			var a_track:Number = a.track;
			var b_track:Number = b.track;
			if (a_track < 0) a_track += int.MAX_VALUE;
			if (b_track < 0) b_track += int.MAX_VALUE;
			
			if (a_track < b_track)
			{
				return -1;
			}
			if (a_track > b_track)
			{
				return 1;
			}
			return 0;
		}
		public static function sortByTrans(a:IClip, b:IClip):Number
		{
			if (a.getValue(CommonWords.TYPE).equals(ClipType.TRANSITION))
			{
				return -1;
			}
			if (b.getValue(CommonWords.TYPE).equals(ClipType.TRANSITION))
			{
				return 1;
			}
			return 0;
		}
		override public function toString():String
		{
			var s:String = '[Mash';
			var value:Value = getValue(MediaProperty.LABEL);
			if (value.empty)
			{
				value = getValue(CommonWords.ID);
			}	
			if (! value.empty)
			{
				s += ' ' + value.string;
			}
			s += ']';
			return s;
		}
		public function unbuffer(range:TimeRange):void
		{
		//	RunClass.MovieMasher['msg'](this + '.unbuffer ' + range);
			if (range != null)
			{
				var limited_range:TimeRange = __limitRange(range);
				var range1:TimeRange = null;
				var range2:TimeRange = null;
				var time_range:TimeRange = null;
				time_range = timeRange;
				if (limited_range.frame) range2 = new TimeRange(0, limited_range.frame, limited_range.fps);
				if (limited_range.endTime.lessThan(time_range.endTime)) range1 = TimeRange.fromTimes(limited_range.endTime, time_range.endTime);
				__unbuffer(range1,range2);
			}
		}
		public function unload():void
		{
		//	RunClass.MovieMasher['msg'](this + '.unload');
			__setMoving(false);
			unbuffer(timeRange);
			if (__canvasSprite != null)
			{
				if (__canvasSprite.displayObject.parent != null)
				{
					__canvasSprite.displayObject.parent.removeChild(__canvasSprite.displayObject);
				}
				__canvasSprite.unload();
				__canvasSprite = null;
			}
			__initClips();
		}
		public function get backColor():String
		{
			return getValue(MashProperty.BGCOLOR).string;
		}
		public function get dimensions():Size
		{
			var s:Size = new Size();
			try
			{
				s.width = getValue(MediaProperty.WIDTH).number;
				s.height = getValue(MediaProperty.HEIGHT).number;
				if (! (s.width && s.height))
				{
					
					s.width = RunClass.MovieMasher['getOptionNumber'](ClipProperty.MASH, MediaProperty.WIDTH);
					s.height = RunClass.MovieMasher['getOptionNumber'](ClipProperty.MASH, MediaProperty.HEIGHT);
				
					
					if (! (s.width && s.height))
					{
						var player:IMetrics = RunClass.MovieMasher['getByID'](ReservedID.PLAYER) as IMetrics;
						if (player != null)
						{
							s.width = player.metrics.width;
							s.height = player.metrics.height;
						}
					}
					if (s.width && s.height)
					{
						setValue(new Value(s.width), MediaProperty.WIDTH);
						setValue(new Value(s.height), MediaProperty.HEIGHT);
					}
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.dimensions', e);
			}
			return s;
		}
		public function get displayObject():DisplayObjectContainer
		{
			if (__canvasSprite == null)
			{
				try
				{
					// first time this mash is being displayed
					__canvasSprite = new MaskedSprite();
					__canvasSprite.name = 'MASH CANVAS';
					__canvasSprite.background = backColor;
					__positionCanvas();
				}
				catch(e:*)
				{
					RunClass.MovieMasher['msg'](this + '.displayObject', e);
				}
			}
			return __canvasSprite.displayObject;
		}
		public function get latency():Number
		{
			return __latency;
		}
		public function get latencyUpdated():Number
		{
			return __latencyModified;
		}
		public function get lengthTime():Time
		{
			var length_time:Time = null;
			if (! isNaN(__lengthFrame)) length_time =  new Time(__lengthFrame, __quantize);
			return length_time;
		}
		public function get metrics():Size
		{
			return __metrics;
		}
		public function set metrics(iMetrics:Size):void
		{
			var dims:Size = null;
			var clip:IClip;
			try
			{
				if ((iMetrics != null) && (! iMetrics.isEmpty()) && (! iMetrics.equals(__metrics)))
				{
					__metrics = iMetrics;
					dims = dimensions;
					
					if (! (dims.width && dims.height))
					{
						dims.width = iMetrics.width;
						dims.height = iMetrics.height;
					}
					var crop:Boolean = getValue(MashProperty.CROP).boolean;
					
					var per:Number = Math[crop ? 'max' : 'min'](iMetrics.width / dims.width, iMetrics.height / dims.height);
					__bitmapSize = new Size(Math.ceil((per * dims.width) /2) * 2, Math.ceil((per * dims.height)/2) * 2);
					
					if (__canvasSprite != null)
					{
						__positionCanvas();
					}
					if (__bitmapSize != null)
					{
						for each (clip in __playingClips)
						{
							clip.metrics = __bitmapSize;
						}
					}
					//else RunClass.MovieMasher['msg'](this + '.metrics __bitmapSize NULL ' + dims);
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + 'MASH.metrics ' +  dims + ' ' + iMetrics, e);
			}
		}
		public function get moduleFilters():Array
		{
			// as of 3.1.11, no one asks for this but it's required by IModule
			return new Array();
		}
		public function set paused(tf:Boolean):void
		{
			try
			{
				if (__paused != tf)
				{
					__paused = tf;
					if (! __paused)
					{
						__mute = ! __volume;
					}
					var d:Date = new Date();
					if (__paused) 
					{
						PlayerStage.instance.stopPlaying();
						__setMoving(false);
						if (__bufferTimer != null)
						{
							__bufferTimer.removeEventListener(TimerEvent.TIMER, __bufferTimed);
							__bufferTimer.stop();
							__bufferTimer = null;
						}
					}
					else 
					{
						if (__bufferTimer == null)
						{
							__bufferTimer = new Timer(2000); 
							__bufferTimer.addEventListener(TimerEvent.TIMER, __bufferTimed);
							__bufferTimer.start();
						}
						goTime();
					}
					__setStalling((! __moving) && (! __paused));	
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.paused', e);
			}
		}
		public function get paused():Boolean
		{
			return __paused;
		}
		public function get sample():uint
		{
			return __samplePosition;
		}
		public function get timeRange():TimeRange
		{
			var time_range:TimeRange = null;
			if (! isNaN(__lengthFrame)) time_range =  new TimeRange(0, __lengthFrame, __quantize);
			return time_range;
		}		
		public function get tracks():Object
		{
			return __tracks;
		}
		override protected function _parseTag():void
		{
			var url_or_id:String;
			__originalKeys = new Array();
						
			try
			{
				url_or_id = super.getValue(MediaProperty.URL).string;
				if (url_or_id.length)
				{
					/*
					if ((url_or_id.indexOf('/') + url_or_id.indexOf('.')) == -2) // it's not a URI
					{
						var listener:IPropertied = SourceClass.Source['getSourceByID'](url_or_id) as IPropertied;
						if (listener != null)
						{
							url_or_id = '';
						}
					}
					else 
					*/
					url_or_id = RunClass.ParseUtility['brackets'](url_or_id);
					
					if (url_or_id.length)
					{
						if (__dataFetcher == null)
						{
							__dataFetcher = RunClass.MovieMasher['dataFetcher'](url_or_id);
							__dataFetcher.addEventListener(Event.COMPLETE, __completeFetch);
						}
					}
				}
				else if (__interpretXML(_tag))
				{
					__parseTag();
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '._parseTag ' + url_or_id, e);
			}
		}
		private function __adjustEffectsLength():void
		{
			var mash_effects:Array = clipsInOuterTracks(0, 1, null, -1, int.MIN_VALUE, ClipType.EFFECT);
			var z:uint = mash_effects.length;
			var effect_clip:IClip;
			var value:Value = new Value(__lengthFrame);
			for (var i:uint = 0; i < z; i++)
			{
				effect_clip = mash_effects[i];
				effect_clip.setValue(value, ClipProperty.LENGTHFRAME);
			}
		}
		private function __applyClip(clip:IClip):void
		{
			try
			{
				//RunClass.MovieMasher['msg'](this + '__applyClip ' + clip);
				if (clip != null)
				{
					clip.metrics = __bitmapSize;
					__canvasSprite.addDisplay(clip.displayObject);
					clip.time = __displayTime;
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__applyClip', e);
			}
		}
		private function __applyClips(v_clips:Array):void
		{
			try
			{
				var transition_clip:IClipTransition = v_clips[1];
				
				// one or the other of these could be null
				var from_clip:IClip = v_clips[0]; 
				var to_clip:IClip = v_clips[2];
				
				var sprite:Sprite;
				var color:String = backColor;
				if (to_clip != null)
				{
					//RunClass.MovieMasher['msg'](this + '__applyClips to not null');
					to_clip.metrics = __bitmapSize;
					__canvasSprite.addDisplay(to_clip.displayObject, 0, 'transition_to');
					to_clip.time = __displayTime;
				}
				else
				{
					//RunClass.MovieMasher['msg'](this + '__applyClips to null');
					sprite = new Sprite();
					RunClass.DrawUtility['fillBox'](sprite.graphics, - __bitmapSize.width / 2,  - __bitmapSize.height / 2,  __bitmapSize.width,  __bitmapSize.height, RunClass.DrawUtility['colorFromHex'](color));
					__canvasSprite.addDisplay(sprite, 0, 'transition_to');
					
				}
				if (from_clip != null)
				{
					//RunClass.MovieMasher['msg'](this + '__applyClips from not null ' + from_clip);
					from_clip.metrics = __bitmapSize;
					__canvasSprite.addDisplay(from_clip.displayObject, 0, 'transition_from');
					from_clip.time = __displayTime;
				}
				else
				{
					//RunClass.MovieMasher['msg'](this + '__applyClips from null');
					sprite = new Sprite();
					RunClass.DrawUtility['fillBox'](sprite.graphics, - __bitmapSize.width / 2,  - __bitmapSize.height / 2,  __bitmapSize.width,  __bitmapSize.height, RunClass.DrawUtility['colorFromHex'](color));
					__canvasSprite.addDisplay(sprite, 0, 'transition_from');
				}
				__canvasSprite.applyTransition(transition_clip, __displayTime);
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__applyClips', e);
			}
		}
		private function __buffer(range1:TimeRange, range2:TimeRange = null):Boolean 
		{
			//RunClass.MovieMasher['msg'](this + '.__buffer ' + range1 + ' ' + range2);
			
			var clip:IClip;
			var clips, clips1, clips2:Dictionary;
			var ob:*;
			var intersections:Array;
			var intersection1, intersection2:TimeRange;
			var found:Boolean = false;
			var clip_range:TimeRange;

			__bufferingClipRanges = new Dictionary();
			
			clips1 = new Dictionary();
			clips2 = new Dictionary();
			clips = new Dictionary();
			if (range1 != null) clips1 = __clipRanges(range1);
			if (range2 != null) clips2 = __clipRanges(range2);
			
			for (ob in clips1) clips[ob] = true;
			for (ob in clips2) clips[ob] = true;
			
			for (ob in clips) 
			{
				clip = ob;
				if (__mute && (clip.type == ClipType.AUDIO)) continue;
				
				intersection1 = intersection2 = null;
				
				__activeClips[clip] = true;
				if (clips1[clip] != null)
				{
					clip_range = clips1[clip];
					if (! clip.buffered(clip_range, __mute)) intersection1 = clip_range;
				}
				if (clips2[clip] != null)
				{
					clip_range = clips2[clip];
					if (! clip.buffered(clip_range, __mute)) intersection2 = clip_range;
				}
				if (! ( (intersection1 == null) && (intersection2 == null)))
				{
					found = true;
					clip.addEventListener(EventType.BUFFER, __clipBuffer);
					clip.metrics = __bitmapSize;
					intersections = new Array();
					if (intersection1 != null) intersections.push(intersection1);
					if (intersection2 != null) intersections.push(intersection2);
					__bufferingClipRanges[clip] = intersections;
				}
			}		
			if (found) 
			{
			//	RunClass.MovieMasher['msg'](this + '.__buffer __startBufferProcessTimer');
				__startBufferProcessTimer();
			}
			return found;
		}
		private function __bufferAdjust(btime:Time, seconds:Number):void
		{
			var atime:Time = Time.fromSeconds(seconds, btime.fps);
			btime.frame = atime.frame;
			btime.fps = atime.fps;
		}
		private function __bufferTimed(event:TimerEvent):void // called while not paused, every second
		{
			try
			{
				if ((! __lengthFrame) || __paused) return;
				if ((__bufferProcessTimer != null) && (event != null)) return;
				var started:Boolean = false;
				var is_buffered:Boolean = true;
				var buffer_time:Time = __bufferTime.copyTime();
				var min_buffer_time:Time = __minbufferTime.copyTime();
				var length_range:TimeRange = timeRange;
				var first1:Time = (__isGoingTime ? __goingTime: __displayTime);
				var last1:Time = first1.copyTime();
				last1.add(buffer_time);
				var range1:TimeRange = TimeRange.fromTimes(first1, last1);
				var range2:TimeRange = null;
				var intersection:TimeRange = range1.intersection(length_range);
				var set_moving:Boolean = true;
					
				if (! range1.isEqualToTimeRange(intersection))
				{
					if (intersection == null)
					{
						range1 = new TimeRange(0, buffer_time.frame, buffer_time.fps);
					}
					else if (! getValue(PlayerProperty.AUTOSTOP).boolean)
					{
						// we need to buffer some in the beginning too
						range2 = range1.copyTimeRange();
						intersection.synchronize(range2);
						range2.length -= intersection.length;
						range2.frame = 0;
					}
				}
			
				if (__unbuffer(range1, range2)) started = true;
				is_buffered = ! __buffer(range1, range2);
				if (! is_buffered) started = true;
				if ((! is_buffered) && __moving)
				{
					if (buffered(range1, __mute)) is_buffered = true;
					else
					{					
						// if moving and range1 isn't buffed, make sure at least the minimum in first range is
						range1.synchronize(min_buffer_time);
						range1.length = min_buffer_time.frame;
						is_buffered = buffered(range1, __mute);
					}
				}
				if (__moving != is_buffered)
				{
					if (! __moving) 
					{
						set_moving = ! __isGoingTime;
						if (__isGoingTime && (event != null)) goTime();
					}
					if (__moving || (! __isGoingTime))  __setMoving(is_buffered);
				}
				if (! started) __stopBufferProcessTimer();
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__bufferTimed', e);
			}
		}
		private function __changeEffects(new_effects:Array):void
		{
			try
			{
			
				var effects:Array = clipsInOuterTracks(0, 1, null, -1, int.MIN_VALUE, ClipType.EFFECT);
				var z:uint = effects.length;
				var i:uint;
				var effect_clip:IClip;
				var value:Value = new Value(__lengthFrame);
				var new_effects_length:uint = new_effects.length;
				var pos:uint;
				for (i = 0; i < z; i++)
				{
					effect_clip = effects[i];
					if ((! new_effects_length) || (new_effects.indexOf(effect_clip) == -1))
					{
						pos = tracks.effect.indexOf(effect_clip);
						tracks.effect.splice(pos, 1);
						effect_clip.unload();
					}
				}
				for (i = 0; i < new_effects_length; i++)
				{
					effect_clip = new_effects[i];
					effect_clip.setValue(new Value(i - new_effects_length), ClipProperty.TRACK);
					effect_clip.setValue(new Value(this), ClipType.MASH);
					if ((! z) || (effects.indexOf(effect_clip) == -1))
					{
						
						tracks.effect.unshift(effect_clip);
						effect_clip.setValue(value, ClipProperty.LENGTHFRAME);
					}
				}
			}	
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__changeEffects', e);
			}	
		}
		private function __clipBuffer(event:Event):void
		{
			if (__clipBufferTimer == null)
			{
				__clipBufferTimer = new Timer(20);
				__clipBufferTimer.addEventListener(TimerEvent.TIMER, __clipBufferTimed);
				__clipBufferTimer.start();
			}
		}
		private function __clipBufferTimed(event:TimerEvent):void
		{
			//RunClass.MovieMasher['msg'](this + '.__clipBufferTimed ' + __lengthFrame);
			__clipBufferTimer.removeEventListener(TimerEvent.TIMER, __clipBufferTimed);
			__clipBufferTimer.stop();
			__clipBufferTimer = null;
			if (isNaN(__lengthFrame))
			{
				invalidateLengths();
				//RunClass.MovieMasher['msg'](this + '.__clipBufferTimed __lengthFrame = ' + __lengthFrame + ' __isGoingTime = ' + __isGoingTime);
			}
			if (__isGoingTime) goTime();
			if (__paused) dispatchEvent(new Event(EventType.BUFFER));
		}
		private var __clipBufferTimer:Timer;
		
		private function __clipRange(clip:IClip, range:TimeRange):TimeRange
		{
			var padded_range:TimeRange = clip.paddedTimeRange;
			var result:TimeRange = range.intersection(padded_range);
			//RunClass.MovieMasher['msg'](this + '.__clipRange ' + range + ' ~ ' + padded_range + ' = ' + result);
			return result;
		}
		private function __clipRanges(orig_range:TimeRange):Dictionary
		{
			var range:TimeRange = orig_range;
			var dict:Dictionary = new Dictionary();
			var y:uint;
			var j:uint;
			var clip:IClip;
			var i,z:uint = __trackTypes.length;
			var type:String;
			var clip_range:TimeRange;
			var track_clips:Array;
			var found_some:Boolean = ! __lengthFrame;
			var tries:uint = 3;
			while ((! found_some) && (tries--))
			{
				for (i = 0; i < z; i++)
				{
					type = __trackTypes[i];
					track_clips = __tracks[type];
					y = track_clips.length;
					for (j = 0; j < y; j++)
					{
						clip = track_clips[j];
						clip_range = __clipRange(clip, range);
						if (clip_range != null)
						{
							dict[clip] = clip_range;
							found_some = true;
						}
					}
				}
				if (! found_some)
				{
					range = __limitRange(range);
					if (! range.frame) break;
					range.frame--;
					//RunClass.MovieMasher['msg'](this + '.__clipRanges ' + orig_range + ' -> ' + range + ' ' + clip);
				}
			}
			return dict;
		}
		private function __clipsHaveAudio():Boolean
		{
			var have:Boolean = false;
			var i,z:uint;
			var clip:IClip;
			z = tracks.video.length;
			for (i = 0; i < z; i++)
			{
				clip = tracks.video[i];
				if (clip.getValue(ClipProperty.HASAUDIO).boolean) 
				{
					have = true;
					break;
				}
			}
			//var mash_effects:Array = clipsInOuterTracks(0, 1, null, -1, int.MIN_VALUE, ClipType.EFFECT);
			z = tracks.effect.length;
			for (i = 0; i < z; i++)
			{
				clip = tracks.effect[i];
				if (clip.getValue(ClipProperty.HASAUDIO).boolean) 
				{
					have = true;
					break;
				}
			}
			return have;
		}
		private function __interpretXML(xml:XML):Boolean
		{
			var done:Boolean = true;
			var config:String = '';
			var list:XMLList;
			var attribute_name : String;
			var attributes : XMLList;
			var attribute :XML;
			var value:String;
			var new_tag:Boolean = (xml != _tag);
			if (! new_tag) 
			{
				config = _tag.@config;
				delete _tag.@config;
			}
			else
			{
				attributes = xml.@*;
				for each (attribute in attributes)
				{
					attribute_name = String(attribute.name());
					value = attribute;
					if (attribute_name == 'config') 
					{
						delete xml.@config;
						config = value;
					}
					else 
					{
						_tag.@[attribute_name] = value;
						_attributes[attribute_name] = new Value(value);
					//	RunClass.MovieMasher['msg'](this + '.__interpretXML ' + attribute_name + ' = ' + String(_tag.@[attribute_name]));
					
					}
				}
				attributes = xml.children();
				for each (attribute in attributes)
				{
					_tag.appendChild(attribute);
				}
			}
			done = (! config.length);
			if (! done)
			{
				config = RunClass.ParseUtility['brackets'](config);
				__dataFetcher = RunClass.MovieMasher['dataFetcher'](config);
				__dataFetcher.addEventListener(Event.COMPLETE, __completeFetch);
			}
			return done;	
		}
		
		private function __completeFetch(event:Event):void
		{
			try
			{
				var xml:XML = __dataFetcher.xmlObject();
				var config:String = '';
				var list:XMLList;
				var media_list:XMLList;
				var media_tag:XML;
				var value:String;
				var done:Boolean = true;
				
				if (xml != null)
				{
					__dataFetcher.removeEventListener(Event.COMPLETE, __completeFetch);
					__dataFetcher = null;
					//RunClass.MovieMasher['msg'](this + '.__completeFetch' + xml.toXMLString());
					list = xml..mash;
					if (list.length()) 
					{
						media_list = xml.media;
						xml = list[0];
						for each(media_tag in media_list)
						{
							xml.appendChild(media_tag);
						}
					}
					done = __interpretXML(xml);
					if (done)
					{
						__parseTag();
						__clipBuffer(null);
						dispatchEvent(new Event(EventType.BUFFER));
					}
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__completeFetch', e);
			}
		}
		private function __initClips():void
		{
			__playingClips = new Vector.<IClip>();
			__activeClips = new Dictionary();
			__containers = new Array();
		}
		private function __initialize():void
		{
			_defaults.effects = '';
			_defaults.kind = 'Mash';
			_defaults.status = '0';
			_defaults[MediaProperty.LABEL] = '';
			_defaults.revert = '';
			_defaults.quantize = '0';
			_defaults[MashProperty.BGCOLOR] = '0';
			
			__unbufferingClipRanges = new Dictionary();
			__bufferingClipRanges = new Dictionary();
		
			__initClips();
			
			__lengths = new Object();
			__highest = new Object();
			__tracks = new Object();
			
			var z:uint = __trackTypes.length;
			var type:String;
			for (var i:uint = 0; i < z; i++)
			{
				type = __trackTypes[i];
				__tracks[type] = new Array();
				__highest[type] = 0;
				__lengths[type] = 0;
			}	
		}
		private function __limitRange(range:TimeRange, lessone:Boolean = false):TimeRange
		{
			if (range != null)
			{
				var start_time:Time = range.copyTime();
				var end_time:Time = range.endTime;
				var limit_time:Time = lengthTime;
				if (lessone)
				{
					limit_time.scale(RunClass.TimeUtility['fps'], 'floor');
					limit_time.frame --;
				}
				start_time.min(limit_time);
				end_time.min(limit_time);
				range = TimeRange.fromTimes(start_time, end_time);
				range.scale(RunClass.TimeUtility['fps'], 'floor');
			}
			return range;

		}
		private function __limitTime(time:Time, lessone:Boolean = false):Time
		{
			var start_time:Time = time.copyTime();
			var limit_time:Time = lengthTime;
			if (lessone)
			{
				limit_time.scale(RunClass.TimeUtility['fps'], 'floor');
				limit_time.frame --;
			}
			start_time.min(limit_time);
			start_time.scale(RunClass.TimeUtility['fps'], 'floor');
			return start_time;
		}
		private function __loadTimed(event:TimerEvent):void // called while moving, at least every 20 milliseconds
		{
			var now:Time;
			now = __displayTime.copyTime();
			if (__moving) now.max(__speakerTime());
			var limited_time:Time = __limitTime(now);
			if (! limited_time.isEqualToTime(now))
			{
				if (getValue(PlayerProperty.AUTOSTOP).boolean) 
				{
					paused = true;
				}
				else
				{
					// reposition to begining, but treat it as a manual seek 
					 goTime(new Time(0, __quantize));
				}
			}
			else if (! now.isEqualToTime(__displayTime)) time = now;
		}
				
				
		private function __newLengthFrame(cur_time:Number):void
		{
			//RunClass.MovieMasher['msg'](this + '.__newLengthFrame ' + cur_time + ' from ' + __lengthFrame);
			if (__lengthFrame != cur_time)
			{
				__lengthFrame = cur_time;
				__adjustEffectsLength();
				_dispatchEvent(ClipProperty.LENGTH);
				_dispatchEvent(MashProperty.LENGTH_TIME);
			}
		}
		private function __parseTag():void
		{
			try
			{
				
				//RunClass.MovieMasher['msg'](this + '.__parseTag ' + _tag.toXMLString());
			//	if (isNaN(__lengthFrame)) __lengthFrame = 0;
				var key:String;
				for (key in _attributes)
				{
					__originalKeys.push(key);
				}
				
				if (getValue(CommonWords.ID).empty) _tag.@id = IDUtility.generate();
				
				
				// see if quantize was set in tag
				var quantize:Number = super.getValue(MashProperty.QUANTIZE).number;
				var needs_requantization:Boolean = ! quantize;
				if (needs_requantization) 
				{
					// it wasn't specified, so assume time values are fractional seconds
					__quantize = 1;
					super.setValue(new Value(1), MashProperty.QUANTIZE);
				}
				else __quantize = quantize;
				
				var clip : IClip;
				var children:XMLList = _tag.clip;
				var type:String;
				var track_clips:Array;
				for each (var clip_node:XML in children)
				{
					clip = Clip.fromXML(clip_node, this);
					if (clip != null)
					{
						type = (clip.appearsOnVisualTrack() ? ClipType.VIDEO : clip.type);
						track_clips = __tracks[type];
						track_clips.push(clip);
						//RunClass.MovieMasher['msg'](this + '.__parseTag adding ' + type + ' ' + clip.lengthFrame + ' ' + clip);
					}
				}
				invalidateLengths();
				if (needs_requantization) 
				{
					// see if the old fps property is set
					quantize = super.getValue(MediaProperty.FPS).number;
					// otherwise use default rate
					if (! quantize) quantize = RunClass.MovieMasher['getOption']('mash', MashProperty.QUANTIZE);
					setValue(new Value(quantize), MashProperty.QUANTIZE);
				}
				__revertable = ! super.getValue(PlayerProperty.DIRTY).boolean;
				__revertXML = _tag.copy();
				__setDirty(! __revertable, false);
				_dispatchEvent('revert');
				
				
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__parseTag', e);
			}
		}
		private function __playingClipsRecalculate():void
		{
			if (__displayTime == null) return;
			
			var clip:IClip;
			var clips:Array;
			var i,z:uint;
			var range:TimeRange;
			try
			{
				range = __displayTime.timeRange;
				clips = clipsInRange(range);
				z = clips.length;
				__playingClips = new Vector.<IClip>();
				range.scale(__quantize, 'floor');
				for (i = 0; i < z; i++)
				{
					clip = clips[i];
					if ((clip.type == ClipType.AUDIO) && ((! __volume) || (! clip.getValue(ClipProperty.HASAUDIO).boolean)))
					{
						// audio clips are ignored if either I or they have no volume
						continue;
					}
					__playingClips.push(clip);
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__playingClipsRecalculate', e);
			}
		}
		private function __playingEffectClips():Vector.<IClipEffect>
		{
			var array:Vector.<IClipEffect> = new Vector.<IClipEffect>();
			for each (var clip:IClip in __playingClips)
			{
				if (clip.type == ClipType.EFFECT)
				{
					array.push(clip as IClipEffect);
				}
			}
			if (array.length > 1) array.sort(sortByTrack);
			return array;
		}
		private function __playingVideoClips():Array
		{
			var array:Array = new Array();
			var clip:IClip;
			var z:int
			try
			{
				if (__playingClips)
				{
					for each (clip in __playingClips)
					{
						if (clip)
						{
							if (clip.appearsOnVisualTrack())
							{
								array.push(clip);
							}
						}
					}
					z = array.length;
					if (z > 1) 
					{
						array.sort(sortByTimeTrans);
					}
					if (z == 1)
					{
						clip = array[0];
						if (clip.type == ClipType.TRANSITION)
						{
							array.length = 0;
						}
					}
					else if (z == 2)
					{
						z = 3;
						clip = array[0];
						if (clip.type == ClipType.TRANSITION)
						{
							array.unshift(null);
						}
						else
						{
							clip = array[1];
							if (clip.type == ClipType.TRANSITION)
							{
								array.push(null);
							}
							else
							{
								// no transition? clips must be overlapping :(
								array.pop();
								z = 1;
							}
						}
					}
					if (z == 3)
					{
						clip = array[1];
						if (clip.type != ClipType.TRANSITION)
						{
							array.splice(1,1);
							array.push(clip);
						}
					}
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__playingVideoClips ' + array.length + ' ' + z, e);
			}
			return array;
		}
		private function __positionCanvas():void
		{
			try
			{
				if (__metrics != null)
				{
					var first_time:Boolean = false;
					if (! getValue('dontreposition').boolean)
					{
						first_time = ! (__canvasSprite.displayObject.x || __canvasSprite.displayObject.y);
						__canvasSprite.displayObject.x =  (__metrics.width / 2);
						__canvasSprite.displayObject.y =  (__metrics.height / 2);
					}
					if ((! first_time) && (! __isGoingTime)) goTime(__displayTime);
					__canvasSprite.metrics = __bitmapSize;
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__positionCanvas', e);
			}
		}
		private function __recalculateTrackLength(type:String):void
		{
			var track_clips:Array = __tracks[type];
			var z:int = track_clips.length;
			if (z) 
			{
				track_clips.sort(sortByTimeTrack);
				//RunClass.MovieMasher['msg'](this + '.__recalculateTrackLength ' + type + ' ' + z + ' ' + track_clips);
			}
			var cur_time:Number = 0;
			var highest_track:int = 0;
			var clip_track:int;
			var clip:IClip;
			for (var i = 0; i < z; i++)
			{
				clip = track_clips[i];
				clip_track = clip.track;
				// don't include mash effects (track -1)
				if (clip_track > -1)
				{
					cur_time = Math.max(cur_time, clip.lengthFrame + clip.startFrame);
					highest_track = Math.max(highest_track, clip_track);
				}
			}
			if ((! cur_time) || (__lengths[type] != cur_time))
			{
				__lengths[type] = cur_time;
				cur_time = Math.max(__lengths.effect, Math.max(__lengths.audio, __lengths.video));
				//RunClass.MovieMasher['msg'](this + '.__recalculateTrackLength ' + type + ' ' + cur_time);
				__newLengthFrame(cur_time);			
			}
			//else RunClass.MovieMasher['msg'](this + '.__recalculateTrackLength ' + type + ' ' + cur_time + ' ? ' + __lengths[type]);
				
			if (__highest[type] != highest_track)
			{
				__highest[type] = highest_track;
				_dispatchEvent(MashProperty.TRACKS);
			}
		}
		private function __recalculateVideoLength(event:Event = null):void
		{
			if (event != null)
			{
				//RunClass.MovieMasher['msg'](this + '.__recalculateVideoLength EVENT');
				event.target.removeEventListener(EventType.BUFFER, __recalculateVideoLength);
			}
			var z:int = __tracks.video.length;
			var cur_time:Number = 0;
			
			var clip:IClip;
			var left_clip:IClip;
			var right_clip:IClip;
			var transitions:Array = [];
			
			var last_type:String = '';
			var type:String;
			var left_padding:Number = 0;
			var right_padding:Number = 0;
			var trans_offset:Number = 0;
			var left_offset:Number = 0;
			var right_offset:Number = 0;
			var last_transition:Object;
			var clip_length:Number;
			var transition_length:Number;
			var freeze:Boolean;
			var y:Number;
			for (var i:int = 0; i < z; i++)
			{
				clip = __tracks.video[i];
				clip.index = i;
				type = clip.type;
				//RunClass.MovieMasher['msg'](this + '.__recalculateVideoLength ' + clip.lengthFrame + ' ' + clip);
				switch (type)
				{
					case ClipType.TRANSITION :
						// this is the first transition
						last_transition = clip;
						break;
					case ClipType.MASH:
						if (! clip.lengthFrame)
						{
							//RunClass.MovieMasher['msg'](this + '.__recalculateVideoLength NO LENGTH');
							clip.addEventListener(EventType.BUFFER, __clipBuffer);
							__lengthFrame = NaN;
							return;
						}
						else;
					default:
						// non transition clip
						clip.startPadFrame = 0;
						clip.endPadFrame = 0;
						if (last_transition)
						{
							// cur_time = the end time of last non trans clip
							transition_length = last_transition.lengthFrame;
							if (left_clip)
							{
								clip_length = left_clip.lengthFrame;
								freeze = last_transition.getValue(ClipProperty.FREEZESTART).boolean || left_clip.getValue(ClipProperty.FREEZEEND).boolean;
								left_padding = __transitionBuffer(clip_length, transition_length, freeze);
								left_clip.endPadFrame = left_padding;
							}
							else
							{
								left_padding = last_transition.lengthFrame;
							}
							right_clip = clip;
							clip_length = right_clip.lengthFrame;
							freeze = last_transition.getValue(ClipProperty.FREEZEEND).boolean || right_clip.getValue(ClipProperty.FREEZESTART).boolean;
							right_padding = __transitionBuffer(clip_length, transition_length, freeze);
							right_clip.startPadFrame = right_padding;
								
							cur_time -= transition_length;
							cur_time += left_padding;
							
							last_transition.startFrame = cur_time;
							last_transition = null;
							cur_time += right_padding;
						}
						clip.startFrame = cur_time;
						cur_time += clip.lengthFrame;
						left_clip = clip;
				}
				last_type = type;
			}
			
			if (last_transition)
			{
				// mash ends with transitions
				transition_length = last_transition.lengthFrame;
				if (left_clip)
				{
					clip_length = left_clip.lengthFrame;
					freeze = last_transition.getValue(ClipProperty.FREEZESTART).boolean;
					left_padding = __transitionBuffer(clip_length, transition_length, freeze)
					left_clip.endPadFrame = left_padding;
				}
				else
				{
					left_padding = transition_length;
				}
				cur_time += left_padding;
				last_transition.startFrame = cur_time - transition_length;
			}
			if ((! cur_time) || (__lengths.video != cur_time))
			{
				__lengths.video = cur_time;
				cur_time = Math.max(__lengths.effect, Math.max(__lengths.audio, __lengths.video));
				__newLengthFrame(cur_time);
			}
			if (Boolean(__highest.video) != Boolean(z))
			{
				__highest.video = (z ? 1 : 0);
				_dispatchEvent(MashProperty.TRACKS);
			}
		}
		private function __revertMash():void
		{
			if (__revertXML != null)
			{
				__setMoving(false);
				goTime(new Time(0, __quantize));
				__canvasSprite.removeContent();
				unbuffer(timeRange);
				__initialize();
				__lengthFrame = NaN;
				_tag = __revertXML;
				invalidateLengths();
				_parseTag();
				_dispatchEvent('track');
				_dispatchEvent('tracks');
				if (RunClass.Action != null) RunClass.Action['clear']();
			}
		}
		private function __speakerTime():Time
		{
			var speaker_time:Time = null;
			var n:Number = __samplePosition;
			n = n / Sampling.SAMPLES_PER_MILLISECOND; // convert from samples to milliseconds
			n -= __latency; // remove the buffer
			
			if (__latencyModified) // add in how much of the buffer we've actually played 
			{
				n += ((new Date()).getTime() - __latencyModified);
			}
			n = n / 1000; // covert from milliseconds to seconds
			if (n >= 0) speaker_time = Time.fromSeconds(n, RunClass.TimeUtility['fps'], 'ceil');
			return speaker_time;
		}
		private function __sampleData(event:SampleDataEvent):void 
		{
			var read: int;
			var change_position:Boolean = true;
			var buffer_size:int;
			var shaderJob:ShaderJob;
			var audio_data:AudioData;
			var vector:Vector.<AudioData>;
			var i:int = 0;
			var shader:Shader;
			var track_fade:Number;
			var track_counter:uint = 1;
			var c:Class;
			var b:ByteArray;
			vector = getAudioDatum(__samplePosition, Sampling.BLOCK_SIZE, 0);
			if ((vector == null) || (! vector.length))
			{
				//RunClass.MovieMasher['msg'](this + '.__sampleData got no audio data at ' + __samplePosition + ' (' + ((__samplePosition / Sampling.SAMPLES_PER_SECOND) * __quantize) + ')');
				audio_data = new AudioData();
				audio_data.volume = __volume / 100;
				vector = new Vector.<AudioData>(1, true);
				vector[0] = audio_data;
				for (i = 0; i < Sampling.BLOCK_SIZE; i++)
				{
					audio_data.byteArray.writeFloat( 0.0 );
					audio_data.byteArray.writeFloat( 0.0 );
				}
			}
			c = Mash['__audio' + vector.length];
			b = new c() as ByteArray;
			shader = new Shader(b);
			for each (audio_data in vector)
			{
				i = audio_data.byteArray.length / Sampling.BYTES_PER_SAMPLE;
				if (i != Sampling.BLOCK_SIZE)
				{
					//RunClass.MovieMasher['msg'](this + '.__sampleData expected ' + Sampling.BLOCK_SIZE + ' samples but got ' + i);
					if ( i < Sampling.BLOCK_SIZE )
					{
						//RunClass.MovieMasher['msg'](this + '.__sampleData filling from ' + i);
						audio_data.byteArray.position = audio_data.byteArray.length;
						while( i < Sampling.BLOCK_SIZE )//-- FILL REST OF STREAM WITH ZEROs
						{
							audio_data.byteArray.writeFloat( 0.0 );
							audio_data.byteArray.writeFloat( 0.0 );
							++i;
						}
					}
					else if ( i > Sampling.BLOCK_SIZE )
					{
						audio_data.byteArray.length = Sampling.BLOCK_SIZE * Sampling.BYTES_PER_SAMPLE;
					}
				}
				audio_data.byteArray.position = 0;
				buffer_size = Math.ceil(audio_data.byteArray.length / Sampling.BYTES_PER_SAMPLE);
			
				track_fade = audio_data.volume;
				shader.data['track' + track_counter].width = buffer_size / 1024;
				shader.data['track' + track_counter].height = 512;
				shader.data['track' + track_counter].input = audio_data.byteArray;
				shader.data['vol' 	+ track_counter].value = [track_fade * 4.0];
				track_counter++;
			}
			//-- INCREASE SOUND POSITION
			if (change_position)
			{
				__samplePosition += Sampling.BLOCK_SIZE;
			}
			shaderJob = new ShaderJob(shader, event.data, buffer_size / 1024, 512);
			shaderJob.start(true);		
			__latencyModified = (new Date()).getTime();
			__latency = (((event.position + Sampling.BLOCK_SIZE)/Sampling.SAMPLES_PER_MILLISECOND) - (__channel ? __channel.position : 0.0));
		}
		private function __startSampling():void
		{
			if (__sound == null)
			{
				__latency = 0.0;
				__samplePosition = Math.round(__displayTime.seconds * Sampling.SAMPLES_PER_SECOND); // just seconds was rounded before!
				__sound = new Sound();
				__sound.addEventListener(SampleDataEvent.SAMPLE_DATA, __sampleData);
				__sound.addEventListener(IOErrorEvent.IO_ERROR, __errorSound);
				__channel = __sound.play();
			}
		}
		private function __stopSampling():void
		{
			if (__sound != null)
			{
				try
				{
					__latencyModified = 0.0;
					if (__sound != null)
					{
						__sound.removeEventListener(SampleDataEvent.SAMPLE_DATA, __sampleData);
						//__sound.close();
						__sound = null;
					}
					if (__channel != null)
					{
						__channel.stop();
						__channel = null;
					}
				}
				catch(e:*)
				{
					RunClass.MovieMasher['msg'](this + '.__stopSampling', e);
				}
			}
		}
		private function __errorSound(event:ErrorEvent):void
		{ 	}
		private function __setDirty(tf:Boolean, dontrefresh:Boolean = false):void
		{
			try
			{
				if (! getValue(MashProperty.READONLY).boolean)
				{
					if ((! dontrefresh) && __moving) 
					{
						//RunClass.MovieMasher['msg'](this + '.__setDirty calling __bufferTimed');
						__bufferTimed(null);
					}
					if (__needsSave != tf)
					{
						__needsSave = tf;
						if (! __needsSave) 
						{
							__revertXML = _tag.copy();
							__revertable = true;
						}
						_dispatchEvent('revert');
						_dispatchEvent(PlayerProperty.DIRTY);
					}
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__setDirty', e);
			}
			
		}
		private function __setMoving(tf:Boolean):void
		{
			try
			{
					
				if (__moving != tf)
				{
					__moving = tf;
					
					//RunClass.MovieMasher['msg'](this + '.__setMoving ' + __moving);
					if (__moving)
					{
						__loadTimer = new Timer(Math.max(20, 500 / RunClass.TimeUtility['fps']));
						__loadTimer.addEventListener(TimerEvent.TIMER, __loadTimed);
						__loadTimer.start();
						__startSampling(); // start up the sound buffer
						
					}
					else
					{
						__stopSampling(); // shut down the sound buffer
						__loadTimer.removeEventListener(TimerEvent.TIMER, __loadTimed);
						__loadTimer.stop();
						__loadTimer = null;
					}
					__setStalling((! __moving) && (! __paused));
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__setMoving', e);
			}
		}
		private function __setQuantize(n:int):void
		{
			var quantize:int = __quantize;
			if (n != quantize)
			{
				// change quantization for all clip times
				var z:uint = __trackTypes.length;
				var type:String;
				var y:uint;
				var j:uint;
				var track_clips:Array;
				var clip:Clip;
				for (var i:uint = 0; i < z; i++)
				{
					type = __trackTypes[i];
					track_clips = __tracks[type];
					y = track_clips.length;
					for (j = 0; j < y; j++)
					{
						clip = track_clips[j];
						clip.changeQuantization(quantize, n);
					}
			
				}
				// so this function isn't called recursively
				__quantize = n;
				__unbufferTime.scale(__quantize);
				__minbufferTime.scale(__quantize);
				__bufferTime.scale(__quantize);
				
				super.setValue(new Value(n), MashProperty.QUANTIZE);
				
				invalidateLengths();
			}
			
		}
		private function __setStalling(tf:Boolean):Boolean
		{
			var changed:Boolean = false; // whether or not __stalling changed
			try
			{
				if (__stalling != tf)
				{
					__stalling = tf;
					//if (__bufferTimer != null) __bufferTimer.delay = (tf ? 20 : 1000);
					//RunClass.MovieMasher['msg'](this + '.__setStalling ' + __stalling);
					changed = true;
					_dispatchEvent(MashProperty.STALLING);
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__setStalling', e);
			}
			return changed;
		}
		private function __transitionBuffer(clip_time:Number, trans_time:Number, is_stopped:Boolean):Number
		{
			if (is_stopped)
			{
				return trans_time;
			}
			var target_time:Number = trans_time + Math.ceil(clip_time / 2);
			target_time -= clip_time;
			return Math.max(target_time,0);
		}
		private function __transfers():Array
		{
			var clips:Array = new Array();
			var track_clips:Array;
			var y:uint;
			var j:uint;
			var clip:IClip;
			var z:uint = __trackTypes.length;
			var array:Array;
			var effects:Array;
			var type:String;
			var value:Value;
			var object:Object;
			var k,x:int;
			for (var i:uint = 0; i < z; i++)
			{
				type = __trackTypes[i];
				track_clips = __tracks[type];
				
				y = track_clips.length;
				for (j = 0; j < y; j++)
				{
					clip = track_clips[j];
					
					if (clip == null) continue;
					value = clip.getValue('transfers');
					
					if ((! value.empty) && (value.object is Array))
					{
						array = value.object as Array;
						x = array.length;
						for (k = 0; k < x; k++)
						{
							object = array[k];
							if (object is TransferBytes)
							{
								clips.push(object);
							}
						}
					}
				}
			}
			return clips;
		}
		private function __unbuffer(range1:TimeRange, range2:TimeRange = null):Boolean 
		{
			var padded_range, unbuffer_range1, unbuffer_range2:TimeRange;
			var intersection, intersection1, intersection2:TimeRange;
			var found, do_unload:Boolean;
			var end_time, unbuffer_time:Time;
			var intersections:Array;
			var subtracted:uint;
			var clip:IClip;
			var ob:*;
			try
			{
				unbuffer_range1 = unbuffer_range2 = null;
				__unbufferingClipRanges = new Dictionary();
				unbuffer_time = __unbufferTime.copyTime();
				if (range1)
				{
					range1 = __limitRange(range1); 
					subtracted = range1.subtract(unbuffer_time);
					range1.length += subtracted;
				}
				if (range2) 
				{
					range2 = __limitRange(range2);
					subtracted = range2.subtract(unbuffer_time);
					range2.length += subtracted;
					if (range1)
					{
						range1.synchronize(range2);
						if (range1.frame <= range2.end) return false; // there is nothing to unbuffer
						end_time = range2.endTime;
						end_time.frame ++;
						unbuffer_range1 = TimeRange.fromTimes(end_time, range1);
					}
				}
				else if (range1)
				{
					if (range1.frame) unbuffer_range1 = new TimeRange(0, range1.frame, range1.fps);
					end_time = range1.endTime;
					if (end_time.lessThan(lengthTime)) unbuffer_range2 = TimeRange.fromTimes(end_time, lengthTime);
				}
				else unbuffer_range1 = timeRange;	
				//RunClass.MovieMasher['msg'](this + '.__unbuffer ' + unbuffer_range1 + ' ' + unbuffer_range2);
				for (ob in __activeClips)
				{
					clip = ob;
					intersection1 = null;
					intersection2 = null;
					padded_range = clip.paddedTimeRange;	
					if (unbuffer_range1 != null)
					{
						//RunClass.MovieMasher['msg'](this + '.__unbuffer Range 1: ' + unbuffer_range1.seconds + '->' + unbuffer_range1.endTime.seconds);
						intersection = padded_range.intersection(unbuffer_range1);
						if (intersection != null)
						{
							do_unload = padded_range.isEqualToTimeRange(intersection);
							if (! do_unload) intersection1 = intersection;
						}
					}
					if ((! do_unload) && (unbuffer_range2 != null))
					{
						//RunClass.MovieMasher['msg'](this + '.__unbuffer Range 2: ' + unbuffer_range2.seconds + '->' + unbuffer_range2.endTime.seconds);
						intersection = padded_range.intersection(unbuffer_range2);
						if (intersection != null)
						{
							do_unload = padded_range.isEqualToTimeRange(intersection);
							if (! do_unload) intersection2 = intersection;
						}
					}
					if (do_unload)
					{		
						found = true;
						__unbufferingClipRanges[clip] = true;	
						do_unload = false;
						delete __activeClips[clip];
					}
					else if (! ( (intersection1 == null) && (intersection2 == null)))
					{
						found = true;
						intersections = new Array();
						if (intersection1 != null) intersections.push(intersection1);
						if (intersection2 != null) intersections.push(intersection2);
						__unbufferingClipRanges[clip] = intersections;
					}
				}
				if (found) 
				{
				//	RunClass.MovieMasher['msg'](this + '.__buffer __startBufferProcessTimer');
					__startBufferProcessTimer();
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__unbuffer ' + range1 + ' ' + range2, e);
			}
			return found;
		}
		private function __startBufferProcessTimer():void
		{
			//RunClass.MovieMasher['msg'](this + '.__startBufferProcessTimer ' + __bufferProcessTimer);
			if (__bufferProcessTimer == null)
			{
				__bufferProcessTimer = new Timer(20);
				__bufferProcessTimer.addEventListener(TimerEvent.TIMER, __bufferProcessTimed);
				__bufferProcessTimer.start();
				__buffering = false;
			}
		}
		private var __buffering:Boolean;
		
		private function __bufferProcessTimed(event:TimerEvent):void
		{
			//var stop:Number = 10 + (new Date()).getTime();
			//var buffering:Boolean = __buffering || 
			var ob:*;
			var clips:Dictionary = new Dictionary();
			var clip:IClip;
			var i,z:uint;
			var array:Array;
			var range:TimeRange;
			var done:Boolean = true;
			//var is_buffered:Boolean;
			clips = (__buffering ? __bufferingClipRanges : __unbufferingClipRanges);
			for (ob in clips)
			{
				done = false;
				clip = ob;
				if (__buffering)
				{
					array = __bufferingClipRanges[clip] as Array;
					z = array.length;
					//is_buffered = true;
					for (i = 0; i < z; i++)
					{
						range = array[i];
						clip.buffer(range, __mute);
					}
					delete __bufferingClipRanges[clip];
				}
				else
				{
					if (__paused || __moving)
					{
						if (__unbufferingClipRanges[clip] is Array)
						{
							array = __unbufferingClipRanges[clip] as Array;
							z = array.length;
							for (i = 0; i < z; i++)
							{
								range = array[i];
								//RunClass.MovieMasher['msg'](this + '.__bufferProcessTimed ' + clip + ' unbuffer ' + range);
								clip.unbuffer(range);
							}
						}
						else if (__bufferingClipRanges[clip] == null) 
						{
							
							//RunClass.MovieMasher['msg'](this + '.__bufferProcessTimed ' + clip + ' unload');
							clip.unload();
							clip.removeEventListener(EventType.BUFFER, __clipBuffer);
						}
					}
					delete __unbufferingClipRanges[clip];
				}
				break; // just do one
			}
			__buffering = ! __buffering;
			if (done) 
			{
				clips = (__buffering ? __bufferingClipRanges : __unbufferingClipRanges);
			
				for (ob in clips)
				{
					done = false;
					break;
				}
			}
			if (done) __stopBufferProcessTimer();
		}
		private function __stopBufferProcessTimer():void
		{
			//RunClass.MovieMasher['msg'](this + '.__stopBufferProcessTimer ' + __bufferProcessTimer);
				
			if (__bufferProcessTimer != null)
			{
				__bufferProcessTimer.removeEventListener(TimerEvent.TIMER, __bufferProcessTimed);
				__bufferProcessTimer.stop();
				__bufferProcessTimer = null;
			}
		}
		private function __xmlMedia():XML
		{
			var dictionary:Object = referencedMedia();
			var container:XML = <moviemasher />;
			var node_xml:XML;
			for each (node_xml in dictionary)
			{
				container.appendChild(node_xml);
			}
			return container;
		}
		private function __xmlFat():XML
		{
			var container:XML = __xml();
			var dictionary:Object = referencedMedia();
			var node_xml:XML;
			for each (node_xml in dictionary)
			{
				container.appendChild(node_xml);
			}
			return container;
		}
		private function __xml():XML
		{
			var result:XML;
			result = _tag.copy();
			try
			{
				//RunClass.MovieMasher['msg'](this + '.__xml');
				var attr_list:XMLList;
				var name:String;
				var z:uint;
				var type:String;
				var y:uint;
				var j:uint;
				var track_clips:Array;
				var clip:IClip;
				var clip_tag:XML;
				var other_tag:XML;
				var count:Number;
				delete result.clip;
				delete result.media;
				delete result.option;
				
			
				attr_list = result.@*;
				for each (var attribute:XML in attr_list)
				{
					name = attribute.name();
					//RunClass.MovieMasher['msg'](this + '.__xml mash attribute: ' + name);
					switch(name)
					{
						case PlayerProperty.BUFFERTIME:
						case PlayerProperty.UNBUFFERTIME:
						case PlayerProperty.MINBUFFERTIME:
						case PlayerProperty.AUTOSTOP:
						case PlayerProperty.AUTOSTART:
						case PlayerProperty.DIRTY:
						case PlayerProperty.PLAY:
							delete result.@[name];
							break;		
						default: result.@[name] = getValue(name).string;
					}
				}
				result.@quantize = __quantize;
				
				z = __trackTypes.length;
				if (z)
				{
					for (var i:uint = 0; i < z; i++)
					{
						type = __trackTypes[i];
						track_clips = __tracks[type];
						y = track_clips.length;
						if (y)
						{
							for (j = 0; j < y; j++)
							{
								clip = track_clips[j];
								clip_tag = clip.getValue(ClipProperty.XML).object as XML;
								result.appendChild(clip_tag);
								if (result != clip_tag.parent())
								{
									RunClass.MovieMasher['msg'](this + '.__xml PARENT ERROR clip = ' + clip.getValue('clipindex').string + "\n" + 'clip_tag.parent() = ' + ((clip_tag.parent() == null) ? 'null' : clip_tag.parent().toXMLString()) + "\n" + '_tag = ' + result.toXMLString());
								}
							}
						}
					}
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__xml', e);
			}
			return result;
		}
		[Embed("../../../../pbj/Audio_01.pbj", mimeType="application/octet-stream")]
		private static var __audio1:Class;		
		[Embed("../../../../pbj/Audio_02.pbj", mimeType="application/octet-stream")]
		private static var __audio2:Class;		
		[Embed("../../../../pbj/Audio_03.pbj", mimeType="application/octet-stream")]
		private static var __audio3:Class;		
		[Embed("../../../../pbj/Audio_04.pbj", mimeType="application/octet-stream")]
		private static var __audio4:Class;		
		[Embed("../../../../pbj/Audio_05.pbj", mimeType="application/octet-stream")]
		private static var __audio5:Class;		
		[Embed("../../../../pbj/Audio_06.pbj", mimeType="application/octet-stream")]
		private static var __audio6:Class;		
		[Embed("../../../../pbj/Audio_07.pbj", mimeType="application/octet-stream")]
		private static var __audio7:Class;		
		[Embed("../../../../pbj/Audio_08.pbj", mimeType="application/octet-stream")]
		private static var __audio8:Class;		
		[Embed("../../../../pbj/Audio_09.pbj", mimeType="application/octet-stream")]
		private static var __audio9:Class;		
		[Embed("../../../../pbj/Audio_10.pbj", mimeType="application/octet-stream")]
		private static var __audio10:Class;		
		[Embed("../../../../pbj/Audio_11.pbj", mimeType="application/octet-stream")]
		private static var __audio11:Class;		
		[Embed("../../../../pbj/Audio_12.pbj", mimeType="application/octet-stream")]
		private static var __audio12:Class;		
		[Embed("../../../../pbj/Audio_13.pbj", mimeType="application/octet-stream")]
		private static var __audio13:Class;		
		[Embed("../../../../pbj/Audio_14.pbj", mimeType="application/octet-stream")]
		private static var __audio14:Class;		
		[Embed("../../../../pbj/Audio_15.pbj", mimeType="application/octet-stream")]
		private static var __audio15:Class;		
		[Embed("../../../../pbj/Audio_16.pbj", mimeType="application/octet-stream")]
		private static var __audio16:Class;		

		private static var __trackTypes:Array = [ClipType.EFFECT, ClipType.AUDIO, ClipType.VIDEO];
		
		private var __activeClips:Dictionary;
		private var __bitmapSize:Size;
		private var __bufferingClipRanges:Dictionary;
		private var __bufferProcessTimer:Timer;
		private var __bufferTime:Time;
		private var __bufferTimer:Timer;
		private var __canvasSprite:MaskedSprite;		
		private var __channel:SoundChannel;
		private var __containers:Array;
		private var __dataFetcher:IDataFetcher = null;
		private var __displayTime:Time; // last time received set time()
		private var __goingTime:Time // last time received by goTime()
		private var __highest:Object;// holds highest track created for audio and effects
		private var __isGoingTime:Boolean;
		private var __latency:Number=0.0; // in milliseconds
		private var __latencyModified:Number = 0.0; // getTime() - moment __latency last updated
		private var __lengthFrame:Number; // the total number of frames in mash
		private var __lengths:Object; // video, audio and effect keys with max frame length
		private var __loadTimer:Timer; // runs while video is actually playing back (not stalled)
		private var __metrics:Size; // the size of displayObject (actual dimensions could differ)
		private var __minbufferTime:Time; 
		private var __moving:Boolean = false;
		private var __mute:Boolean;
		private var __needsSave:Boolean = false;
		private var __originalKeys:Array;
		private var __paused:Boolean = true;
		private var __playingClips:Vector.<IClip>;
		private var __quantize:int = 0;
		private var __samplePosition:uint;
		private var __sound:Sound;
		private var __stalling:Boolean = false;
		private var __tracks:Object;
		private var __unbufferingClipRanges:Dictionary;
		private var __unbufferTime:Time;
		private var __volume:uint = 75;
		private var __revertXML:XML;
		private var __revertable:Boolean = false;
	}
}
