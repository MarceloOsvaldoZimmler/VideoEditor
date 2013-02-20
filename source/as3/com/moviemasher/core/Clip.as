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
	import com.moviemasher.events.*;
	import com.moviemasher.display.*;
	import com.moviemasher.interfaces.*;
	import com.moviemasher.type.*;
	import com.moviemasher.constant.*;
	import com.moviemasher.utils.*;
	import flash.display.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.system.*;
	import flash.utils.*;

/**
* Implementation class represents an instance of an {@link IMedia} item, usually within a mash.
* 
* @see IClip
*/
	public class Clip extends Propertied implements IClip
	{
		public function Clip(type:String, media:IMedia, imash:IMash = null)
		{
			__composites = new Vector.<IClip>(); 
			__effects = new Vector.<IClipEffect>(); 
			__media = media;
			__type = type;
			mash = imash;
		}
/**
* Static function creates clip out of {@link IMedia} object.
* 
* @param media IMedia object that clip is instance of.
* @param xml XML object containing clip or media tag or null,
* @param mash IMash object that will hold clip or null.
* @returns IClip ready for inserting into mash or null if media is null or has no type.
*/
		public static function fromMedia(media:IMedia, xml:XML = null, mash:IMash = null):IClip
		{
			var item_ob:IClip = null;
			var type:String = '';
			var i,z:uint;
			var media_id:String = '';
			var composites:Value;
			var a:Array;
			var media_tags:XMLList;
			
			if (media != null)
			{
				media_id = media.getValue(CommonWords.ID).string;
				if (xml != null) type = xml.@type;
				if (! type.length) type = media.getValue(CommonWords.TYPE).string;
				if (type.length)
				{				
					switch(type)
					{
						case ClipType.TRANSITION:
							item_ob = new TransitionClip(type, media, mash);
							break;
						case ClipType.EFFECT:
							item_ob = new EffectClip(type, media, mash);
							break;
						case ClipType.MASH:
							item_ob = new MashClip(type, media, mash);
							break;
						default:
							item_ob = new Clip(type, media, mash);
					}
					if (item_ob != null)
					{
						if (xml == null) 
						{
							xml = new XML('<clip type="' + type + '" id="' + media_id + '" />');
							media_tags = media.tag.media;
							z = media_tags.length()
							if (z)
							{
								for (i = 0; i < z; i++)
								{
									media = RunClass.Media['fromXML'](media_tags[i]);
									if (media != null)
									{
										media_id = media.getValue(CommonWords.ID).string;
										type = media.getValue(CommonWords.TYPE).string;
										xml.appendChild(new XML('<clip type="' + type + '" id="' + media_id + '" track="' + (i - z) + '" />'));
									}
								}
							}
							else
							{
								composites = media.getValue(ClipProperty.COMPOSITES);
								if (! composites.empty)
								{
									a = composites.array;
									z = a.length;
									for (i = 0; i < z; i++)
									{
										media_id = a[i];
										media = RunClass.Media['fromMediaID'](media_id, mash);
										if (media != null)
										{
											type = media.getValue(CommonWords.TYPE).string;
											xml.appendChild(new XML('<clip type="' + type + '" id="' + media_id + '" track="' + (i - z) + '" />'));
										}
									}
								}
							}
						}
						item_ob.tag = xml.copy();						
					}
				}
			}
			return item_ob;
		}
/**
* Static function creates clip out of Media ID.
* 
* @param id String containing {@link Media} object identifier
* @param xml XML object containing clip or media tag or null,
* @param mash IMash object that will hold clip or null.
* @returns IClip ready for inserting into mash or null if media wasn't found.
*/
		public static function fromMediaID(id:String, xml:XML = null, mash:IMash = null):IClip
		{
			var item_ob:IClip = null;
			var media:IMedia;
			try
			{
				media = RunClass.Media['fromMediaID'](id, mash);
				
				if ((media == null) && (xml != null))
				{
					media = RunClass.Media['fromXML'](xml);
				}
				if (media != null)
				{
					item_ob = fromMedia(media, xml, mash);
				}
				
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](Clip + '.fromMediaID', e);
			}
			return item_ob;
		}
/**
* Static function creates clip out of media or clip tag.
* 
* @param xml XML object containing clip or media tag or null,
* @param mash IMash object that will hold clip or null.
* @param media IMedia object or null to force search for one with id matching xml's id attribute.
* @returns IClip ready for inserting into mash or null if media wasn't found.
*/
		public static function fromXML(node:XML, mash:IMash = null, media:IMedia = null):IClip
		{ 
			var clip:IClip = null;
			if (media != null) clip = fromMedia(media, node, mash);
			else clip = fromMediaID(String(node.@id), node, mash);
			return clip;
		}
		public function appearsOnVisualTrack():Boolean
		{
			return ( ! ((__type == ClipType.AUDIO) || (__type == ClipType.EFFECT)));
		}
		public function buffer(range:TimeRange, mute:Boolean):void
		{
			try
			{				
				mute = mute || (! __hasAudio());
			//	if (__speed != 1) RunClass.MovieMasher['msg'](this + '.buffer ' + range + ' mute = ' + mute);
				var media_range:TimeRange = __mediaRange(range, (range.length > 1)); // buffer extra frame
				if (_module == null) __requestModule();
				if (_module != null)
				{
					_module.metrics = __metrics;
				//	RunClass.MovieMasher['msg'](this + '.buffer MODULE ' + media_range);
					//RunClass.MovieMasher['msg'](this + '.buffer MODULE ' + media_range + ' ' + lengthTime);
					_module.buffer(media_range, mute);
				}

				var z:uint = __effects.length;
				if (z)
				{
					media_range = range.copyTimeRange();
					media_range.subtract(new Time(__startFrame, _quantize));
					var clip:IClipEffect;
					for (var i:uint = 0; i < z; i++)
					{
						clip = __effects[i];
						clip.metrics = __metrics;
						clip.buffer(media_range, mute);
					}
				}

			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.buffer', e);
			}
		}
		public function buffered(range:TimeRange, mute:Boolean):Boolean
		{
			var is_buffered:Boolean = (_module != null);
			var media_range:TimeRange = range;
			var i,z:uint;
			var clip:IClipEffect;
			try
			{
				mute = mute || (! __hasAudio());
				if (is_buffered)
				{
					media_range = __mediaRange(range, (range.length > 1)); // make sure extra frame is buffered if loading a range
					//if (_module == null) __requestModule();
					is_buffered = _module.buffered(media_range, mute);
				}
				if (is_buffered)
				{
					z = __effects.length;
					if (z)
					{
						media_range = range.copyTimeRange();
						media_range.subtract(new Time(__startFrame, _quantize));
						for (i = 0; i < z; i++)
						{
							clip = __effects[i];
							if (! clip.buffered(media_range, mute))
							{
								is_buffered = false;
							}
						}
					}
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.buffered', e);
			}
			//RunClass.MovieMasher['msg'](this + '.buffered ' + is_buffered + ' ' + range + ' mute: ' + mute + ' media_range: ' + media_range + ' lengthTime: ' + lengthTime);
		
			return is_buffered;
		}
		public function changeQuantization(old_q:int, new_q:int):void
		{
			if (old_q != new_q)
			{
				switch(type)
				{
					case ClipType.AUDIO:
					case ClipType.MASH:
					case ClipType.VIDEO:
						// adjust trimming
						_startTrimFrame = RunClass.TimeUtility['convertFrame'](_startTrimFrame, old_q, new_q);
						_endTrimFrame = RunClass.TimeUtility['convertFrame'](_endTrimFrame, old_q, new_q);
						break;
				}
				_lengthFrame = RunClass.TimeUtility['convertFrame'](_lengthFrame, old_q, new_q);
			}
		}
		final public function clipTime(time:Time):Time 
		{
			return __clipTime(time);
		}
		private function __clipTime(time:Time, add_one_frame:Boolean = false):Time
		{
			var clip_time:Time = time.copyTime();
			try
			{
				clip_time.subtract(new Time(__startFrame, _quantize));
				var limit_time:Time = lengthTime;
				clip_time.min(limit_time);
				if (add_one_frame) clip_time.frame += Math.ceil(__speed);
				switch (__type)
				{
					case ClipType.VIDEO:
						clip_time.add(new Time(__trimFrame(), _quantize));
						clip_time.divide(__speed, 'ceil');
						break;
					case ClipType.MASH:
					case ClipType.AUDIO:
						clip_time.add(new Time(__trimFrame(), _quantize));
						break;
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__mediaTime', e);
			}
			
			return clip_time;
		
		}
		public function clone():IClip 
		{ 
			return fromXML(__xml(), _mash, __media); 
		}
		public function editableProperties():Array
		{
			var a:Array = null;
			if (! __readOnly)
			{				
				var nons:Array = getValue(MediaProperty.NONEDITABLE).array;
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
		public function getAudioDatum(position:uint, length:int, samples_per_frame:int):Vector.<AudioData>
		{
			var vector:Vector.<AudioData> = null;
			var clip_vector:Vector.<AudioData>;
			var audio_data:AudioData;
			var byte_array:ByteArray;
			var volume:Number;
			var z:uint;
			var insert_position:int = 0;
			var clip:IClip;
			var i:int;
			var start_position:int;
			var end_position:int;
			var intersect_position:int;
			var samples_to_grab:int;
			var intersect_end:int;
			var eight:int;
			
			var mod_position:uint; 
			try
			{
				
				start_position = __startFrame * samples_per_frame;
				end_position = start_position + (_lengthFrame * samples_per_frame);
				intersect_position = position;
				samples_to_grab = length;
				intersect_end = position + length;
				eight = 8;
				if (intersect_position < start_position) // i_start_after_position - __startPadFrame
				{
					insert_position = eight * (start_position - intersect_position);
					samples_to_grab -= (start_position - intersect_position);
					intersect_position = start_position;
				}
				if (end_position < intersect_end) // i_end_before_length
				{
					samples_to_grab -= (intersect_end - end_position);
					intersect_end = end_position;
				}
				if (samples_to_grab > 0) 
				{
					mod_position = (intersect_position - start_position) + samples_per_frame * __trimFrame();//+ __startPadFrame
					clip_vector = _moduleAudioDatum(mod_position, samples_to_grab, samples_per_frame);
					if (clip_vector != null)
					{
						//RunClass.MovieMasher['msg'](this + ' ' + getValue('id').string + '.getAudioDatum @ ' + position + ' got MODULE data: ' + clip_vector.length);
						if (samples_to_grab != length)
						{
							for each(audio_data in clip_vector)
							{
								byte_array = new ByteArray();
								byte_array.length = length * eight;
								//RunClass.MovieMasher['msg'](this + '.getAudioDatum @ ' + position + (end_position < intersect_end ? ' i_end_before_length' : '')  + (intersect_position < start_position ? ' i_start_after_position' : '') + ' ' + insert_position);
								byte_array.position = insert_position;
								audio_data.byteArray.position = 0;
								byte_array.writeBytes(audio_data.byteArray, 0, samples_to_grab * eight);
								audio_data.byteArray = byte_array;
							}
						}
						vector = clip_vector;
					}
					z = __effects.length;
					if (z)
					{
						for (i = 0; i < z; i++)
						{
							clip = __effects[i];
							clip_vector = clip.getAudioDatum(mod_position, samples_to_grab, samples_per_frame);
							if (clip_vector != null)
							{
								//RunClass.MovieMasher['msg'](this + ' ' + getValue('id').string + '.getAudioDatum @ ' + position + ' got EFFECT data: ' + clip_vector.length + ' from ' + clip);
							
								if (samples_to_grab != length)
								{
									for each(audio_data in clip_vector)
									{
										byte_array = new ByteArray();
										byte_array.length = length * eight;
										byte_array.position = insert_position;
										audio_data.byteArray.position = 0;
										byte_array.writeBytes(audio_data.byteArray, 0, samples_to_grab * eight);
										audio_data.byteArray = byte_array;
									}
								}
								if (vector == null) vector = clip_vector;
								else vector = vector.concat(clip_vector);
							}
						}
					}
					if ((vector != null) && vector.length)
					{
						volume = __volumeFromTime((intersect_position / samples_per_frame))
						for each (audio_data in vector)
						{
							audio_data.volume *= volume;
						}
					}
				}
				//else RunClass.MovieMasher['msg'](this + ' ' + getValue('id').string + '.getAudioDatum @ ' + position + ' samples_to_grab = ' +  samples_to_grab);
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.getAudioDatum', e);
			}
			return vector;
		}
		override public function getValue(property:String):Value
		{
			var value:Value = null;
			try
			{
				if ((__media != null) && __media.getValue(MediaProperty.COMPOSITEEDITABLE).array.indexOf(property) != -1)
				{
					//RunClass.MovieMasher['msg'](this + '.getValue in COMPOSITEEDITABLE ' + property);

					if (__composites.length) value = __composites[0].getValue(property);
					else value = new Value();
				}
				else
				{
					switch(property)
					{
						case 'readonly':
							value = new Value(__readOnly ? 1 : 0);
							break;
						case ClipProperty.TRACK:
							value = new Value(track);
							break;
						case 'kind':
							value = new Value('Clip');
							break;
						case ClipProperty.EFFECTS:
							value = new Value(__arrayEffects());
							break;
						case ClipProperty.COMPOSITES:
							value = new Value(__arrayComposites());
							break;
						case ClipProperty.XML:
							value = new Value(__xml());
							break;
						case ClipProperty.SPEED:
							if (__isModular()) value = super.getValue(property);
							else value = new Value(__speed);
							break;
						case CommonWords.TYPE:
							value = new Value(__type);
							break;
						
						case ClipProperty.LENGTHSECONDS:
							value = new Value(RunClass.TimeUtility['timeFromFrame'](lengthFrame, _quantize));
							break;
						case ClipProperty.LENGTH:
						case ClipProperty.LENGTHFRAME:
							value = new Value(lengthFrame);
							break;
						case ClipProperty.STARTFRAME:
						case ClipProperty.START:
							value = new Value(__startFrame);
							break;
						case ClipProperty.TRIMSTARTFRAME:
						case ClipProperty.TRIMENDFRAME:
						case ClipProperty.TRIMSTART:
						case ClipProperty.TRIMEND:
							value = new Value(__trimFrame(((property == ClipProperty.TRIMEND) || (property == ClipProperty.TRIMENDFRAME))));
							break;
						case ClipProperty.TRIM:
							value = __trimValue();
							break;
						case MediaProperty.WAVE:
						case MediaProperty.LOOP:
						case MediaProperty.WIDTH:
						case MediaProperty.HEIGHT:
						case MediaProperty.ICON:
						case MediaProperty.NONEDITABLE:
						case MediaProperty.COMPOSITEEDITABLE:
						case MediaProperty.AUDIO:
						case 'swap':
							value = ((__media == null) ? super.getValue(property) : __media.getValue(property));
							break;
						case MediaProperty.DURATION: // number of frames in mash quantization of media as a float
							value = new Value(_mediaSeconds);//RunClass.TimeUtility['frameFromTime'](_mediaSeconds, _quantize, '')
							break;
						case ClipProperty.HASAUDIO:
							value = new Value(__hasAudio());
							break;
						case ClipProperty.ISAUDIO:
							value = new Value(__hasAudio(true));
							break;
						case ClipProperty.HASVISUAL:
							value = new Value(__type != ClipType.AUDIO);
							break;
						case ClipProperty.TIMELINESTARTFRAME:
							value = new Value(__timelineStartFrame());
							break;
						case ClipProperty.TIMELINEENDFRAME:
							value = new Value(__timelineEndFrame());
							break;
						case ClipType.MASH:
							value = new Value(_mash);
							break;
						case ClipProperty.VOLUME:
							if (! __hasAudio(true))
							{
								value = new Value();
								break;
							}
							else;
						default:
							
							if (value == null) value = super.getValue(property);
					}	
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.getValue ' + property, e);
			}
			return value;
		}
		public function propertyDefined(property:String):Boolean
		{
			var defined:Boolean = false;
			var nons:Array = getValue(MediaProperty.NONEDITABLE).array;
			if (nons.indexOf(property) == -1)
			{
				switch(property)
				{
					case ClipProperty.TRACK:
						break;
					case CommonWords.TYPE:
						defined = true;
						break;
					case ClipProperty.VOLUME:
						defined = __hasAudio(true);
						break;
					case ClipProperty.LENGTH:
						if (track < 0) break;
						else;
					//case ClipProperty.EFFECTS:
					default:
						defined = (_defaults[property] != null);
				}
			}
			return defined;
		}
		public function referencedMedia(object:Object):void
		{
			var media_id:String;
			var xml_tag:XML;
			var list:XMLList;
			var child:XML;
			if (__media != null)
			{
				media_id = 'K' + RunClass.MD5['hash'](__media.getValue(CommonWords.ID).string);
				if (object[media_id] == null)
				{
					xml_tag = __media.tag.copy();
					list = xml_tag.media;
					if (list.length())
					{
						// flatten nested media tags
						for each (child in list)
						{
							object['K' + RunClass.MD5['hash'](child.@[CommonWords.ID])] = child;
						}
						delete xml_tag.media;
					}
					object[media_id] = xml_tag;
				}
			}
			
			if (__isModular())
			{
				var font_id:String = getValue(TextProperty.FONT).string;
				if (font_id.length)
				{
					media_id = 'K' + RunClass.MD5['hash'](font_id);
					if (object[media_id] == null)
					{
						xml_tag = RunClass.MovieMasher['searchTag'](TagType.OPTION, font_id, CommonWords.ID);
						
						if (xml_tag != null)
						{
							object[media_id] = xml_tag.copy();
							
						}
					}
				}
			}
				
			var clip:IClip;
			var z:uint;
			var i:uint;
			z = __effects.length;
			if (z)
			{
				for (i = 0; i < z; i++)
				{
					clip = __effects[i];
					clip.referencedMedia(object);
				}
			}
			z = __composites.length;
			if (z)
			{
				for (i = 0; i < z; i++)
				{
					clip = __composites[i];
					clip.referencedMedia(object);
				}
			}


		}
		override public function setValue(value:Value,property:String):Boolean
		{
			var length_changed:Boolean = false; // if true we'll adjust our lengths
			try
			{
				var dirty_mash_property:String = PlayerProperty.DIRTY;
					
				var dirty_mash:Boolean = (_mash != null); // if true, we'll set mash's dirty property (unneeded for properties that affect mash length )
				var do_super:Boolean = true; // if true, we'll call super.setValue
				var set_this:Boolean = false; // if true, we'll set this[property] to value.number
				var dispatch:Boolean = true;
				
				if ((__media != null) && __media.getValue(MediaProperty.COMPOSITEEDITABLE).array.indexOf(property) != -1)
				{
					//RunClass.MovieMasher['msg'](this + '.setValue in COMPOSITEEDITABLE ' + property + ' ' + value.string);
					if (__composites.length) __composites[0].setValue(value, property); // do NOT set length_changed for composites
					do_super = false;
				}
				else
				{
					switch (property)
					{
						case ClipProperty.SPEED:
							if (__isModular()) break; // modules might use as properties
						case ClipProperty.LENGTH:
						case ClipProperty.LENGTHSECONDS:
						case ClipProperty.LENGTHFRAME:
						case ClipProperty.START:
						case ClipProperty.TRIM:
						case ClipProperty.TRIMSTART:
						case ClipProperty.TRIMEND:
						case ClipProperty.TRIMSTARTFRAME:
						case ClipProperty.TRIMENDFRAME:
						case ClipProperty.LOOPS:
						
							length_changed = (track >= 0);
							break;
						
					}
					switch(property)
					{
						case ClipProperty.VOLUME:
							dirty_mash_property = 'dirtyaudio';
							// intentional fallthrough to ClipProperty.FADE
						case 'fade':
							if (value.array.length == 1)
							{
								value = new Value('0,' + value.string + ',100,' + value.string);
							}
							break;
						case 'mute':
							property = MediaProperty.AUDIO;
							value = new Value(value.boolean ? 0 : 1);
							dirty_mash_property = 'dirtyaudio';
							dispatch = false;
							break;
						case ClipProperty.EFFECTS:
							__setEffects(value.array);
							do_super = false;
							break;
						case ClipProperty.COMPOSITES:
							__setComposites(value.array);
							do_super = false;
							break;
						case ClipProperty.SPEED:
							if (! __isModular())
							{
								// TODO: enforce minimum clip lengths by increasing speed
								if (value.number > 0)
								{
									var dif:Number = __speed / value.number;
									_endTrimFrame = Math.round(_endTrimFrame / dif);
									_startTrimFrame = Math.round(_startTrimFrame / dif);
									__speed = value.number;
									_calculateLength();
									dirty_mash = (track < 0);
								}
							}
							break;
						case ClipType.MASH:
							mash = (value.undefined ? null : value.object as IMash);
							length_changed = true;
							do_super = false;
							dirty_mash = false;
							dispatch = false;
							break;
						
						case ClipProperty.START:
							dirty_mash = false;
							__setStartFrame(value.number);
							
							break;
						case ClipProperty.TRACK:
							dirty_mash = false;
							set_this = true;
							break;
						
						case ClipProperty.LENGTHSECONDS:
							if ((__type == ClipType.IMAGE) || (__type == ClipType.FRAME) || __isModular())
							{
								if (value.boolean)
								{
									lengthFrame = Math.round(RunClass.TimeUtility['frameFromTime'](value.number, _quantize)); // collision detection for effects
									value = getValue(ClipProperty.LENGTHSECONDS);
									length_changed = true;
								}
							}
							do_super = false;
							dirty_mash = false;
							break;
							
						case ClipProperty.LENGTHFRAME:
							dispatch = false; // low level access to set length without dirtying mash
						case ClipProperty.LENGTH:
							//RunClass.MovieMasher['msg'](this + '.setValue ' + property + ' = ' + value.number);
			
							length_changed = __setLengthFrame(value.number);
							if (length_changed)
							{
								property = ClipProperty.LENGTH;
								value = getValue(ClipProperty.LENGTH);
							}
							do_super = false;
							dirty_mash = false;
							break;
						case ClipProperty.TRIMSTART:
						case ClipProperty.TRIMSTARTFRAME:
							dirty_mash = (track < 0);
							do_super = false;
							__setTrimStart(value.number, (__type != ClipType.AUDIO));
							break;
						case ClipProperty.TRIMEND:
						case ClipProperty.TRIMENDFRAME:
							dirty_mash = (track < 0);
							do_super = false;
							__setTrimEnd(value.number, (__type != ClipType.AUDIO));
							break;
						case ClipProperty.TRIM:
							dirty_mash = (track < 0);
							do_super = false;
							__setTrim(value, (__type != ClipType.AUDIO)); // collision detection for audio
							break;
						case ClipProperty.LOOPS:
							__setLoops(value);
							dirty_mash = false;
							do_super = false;
							break;
					}
				}
				if (set_this) this[property] = value.number;
				if (do_super) super.setValue(value,property);
				if (dirty_mash) _mash.setValue(new Value(1), dirty_mash_property);
				if (length_changed)
				{
					__adjustLengthEffects();
					__adjustLengthComposites();
				}
				if (dispatch)
				{
					_dispatchEvent(property, value);
					dispatchEvent(new Event(Event.CHANGE));
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.setValue ' + property + ' '+ value, e);
			}
			return length_changed;
		}
		override public function toString():String
		{
			var s:String = '[';
			try
			{
				s += getQualifiedClassName(this).split(':').pop();
				var value:Value;
				value = super.getValue(MediaProperty.LABEL);
				if (! value.empty) s += ' ' + value.string;
				else if (__media != null)
				{
					value = __media.getValue(MediaProperty.LABEL);
					if (value.empty)
					{
						value = __media.getValue(CommonWords.ID);
					}
					if (! value.empty)
					{
						s += ' ' + value.string;
					}
				}
			}
			catch(e:*)
			{
				// whatever
			}
			s += ']';
			return s;
		}
		public function unbuffer(range:TimeRange):void
		{
			//RunClass.MovieMasher['msg'](this + '.unbuffer ' + range);
			var i,z:uint;
			var clip:IClip;
			try
			{
				var media_range:TimeRange;
				if (_module != null)
				{
					media_range = __mediaRange(range, false); // do not unbuffer our buffered extra frame!
					//RunClass.MovieMasher['msg'](this + '.unbuffer MODULE ' + media_range + ' ' + lengthTime);
					_module.unbuffer(media_range);
				}
									
				z = __effects.length;
				if (z)
				{
					media_range = range.copyTimeRange();
					media_range.subtract(new Time(__startFrame, _quantize));
					for (i = 0; i < z; i++)
					{
						clip = __effects[i];
						clip.unbuffer(media_range);
					}
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.unbuffer', e);
			}
		}
		public function unload():void
		{
			try
			{
				//RunClass.MovieMasher['msg'](this + '.unload');
				__destroyDisplayObject();
				if (_module != null)
				{
					_module.removeEventListener(EventType.BUFFER, __moduleBuffer);
					if (! getValue('dontunload').boolean) _module.unload();
					_module = null;
				}
				__requestedModule = false;

				var clip:IClip;
				var i:uint;
				var z:uint;
				z = __effects.length;
				for (i = 0; i < z; i++)
				{
					clip = __effects[i];
					/* DON'T stop listening
					clip.removeEventListener(EventType.BUFFER, __clipBuffer);
					*/
					clip.unload();
				}
			
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this, e);
			}
		}
		public function get backColor():String
		{
			var string:String = getValue(ModuleProperty.BACKCOLOR).string;
			if ((! string.length) && (_module != null))
			{
				string = _module.backColor;
			}
			return string;
		}
		public function get canTrim():Boolean
		{
			var can:Boolean = false;
			switch (__type)
			{
				case ClipType.AUDIO:
					can = ! __mediaDoesLoop;
					break;
				case ClipType.MASH:
				case ClipType.VIDEO:
					can = true;
					break;
			}
			return can;
		}
		public function get displayObject():DisplayObjectContainer
		{
			
			if (__maskedSprite == null) __createDisplayObject();
			return __maskedSprite;
		}
		public function get endPadFrame():Number
		{ 
			return __endPadFrame; 
		}
		public function set endPadFrame(value:Number):void
		{ 
			if (__endPadFrame != value) __endPadFrame = value; 
		}
		public function get index():int
		{ 
			return __index; 
		}
		public function set index(value:int):void
		{ 
			if (__index != value) __index = value; 
		}
		public function get lengthFrame():Number
		{ 
			var lf:Number = _lengthFrame;
			try
			{
				if (lf <= 0)
				{
					lf = _mediaSeconds;
					if (__speed != 1) lf *= __speed;
					lf = RunClass.TimeUtility['convertFrame'](lf, 1, _quantize, 'floor');
					if (_endTrimFrame || _startTrimFrame) lf -= _endTrimFrame + _startTrimFrame;
					if (lf < 0) lf = 0;
					if (_mash != null) _lengthFrame = lf;
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.lengthFrame', e);
			}
			return lf; 
		}
		public function set lengthFrame(n:Number):void
		{ 
			// enforce minimum clip length
			var minlength:Number = RunClass.MovieMasher['getOptionNumber']('clip', 'minlength');
			
			if (_mash != null)
			{
				if (minlength) minlength = RunClass.TimeUtility['frameFromTime'](minlength, _quantize);
				else minlength = 1;
				if (__type == ClipType.EFFECT) // check for collision in this effects track
				{
					var tracks:Array = _mash.clipsInOuterTracks(__startFrame, __startFrame + n, [this], track, 1, ClipType.EFFECT);
					var z:int = tracks.length;
					if (z)// hit something
					{
						var clip:IClip = tracks[0];
						n = clip.startFrame - __startFrame;
					}
					n = Math.max(n, __lastEffectStart() + minlength);
				}
			}
			
			
			if (n < minlength) n = minlength;
			
			_lengthFrame = Math.round(n);
		}
		public function get lengthTime():Time
		{
			return new Time(lengthFrame, _quantize);
		}
		public function get mash():IMash
		{	
			return _mash; 
		}
		public function set mash(object:IMash):void
		{	
			_mash = object; 
			_quantize = ((_mash == null) ? 0 : _mash.getValue(MashProperty.QUANTIZE).number);
		}
		public function get media():IMedia
		{	
			return __media; 
		}
		public function get metrics():Size
		{
			return __metrics;
		}
		public function set metrics(iMetrics:Size):void
		{
			try
			{
				if ((iMetrics != null) && (! iMetrics.isEmpty()))
				{
					__metrics = iMetrics;
					if (_module != null)
					{
						_module.metrics = __metrics;
					}
					if (__maskedSprite != null)
					{
						__maskedSprite.metrics = __metrics;
					}
				}
			}
			catch(e:*)
			{
				if (iMetrics != null) RunClass.MovieMasher['msg'](this + 'CLIP.metrics ' + iMetrics, e);
			}
		}
		public function get owner():IClip
		{
			return __parent;
		}
		public function set owner(clip:IClip):void
		{
			__parent = clip;
		}
		public function get paddedTimeRange():TimeRange
		{
			return new TimeRange(__startFrame - __startPadFrame, lengthFrame + __startPadFrame + __endPadFrame, _quantize);
		}
		public function get startFrame():Number
		{ 
			return __startFrame; 
		}
		public function set startFrame(value:Number):void
		{ 
			if (__startFrame != value) __startFrame = value; 
		}
		public function get startPadFrame():Number
		{ 
			return __startPadFrame; 
		}
		public function set startPadFrame(value:Number):void
		{ 
			if (__startPadFrame != value) __startPadFrame = value; 
		}
		public function get startTime():Time
		{
			return new Time(__startFrame, _quantize);
		}
		public function set time(object:Time):void
		{
			try
			{
				
				var clip_time:Time = __clipTime(object);
				//RunClass.MovieMasher['msg'](this + '.time ' + object + ' ' + clip_time);
				var backcolor:String;
				var display:DisplayObjectContainer = null;
				display = displayObject;
				__maskedSprite.removeContent();
				if (_module != null)
				{
					_module.time = clip_time;
						
					if (_module.displayObject != null) 
					{
						__maskedSprite.addDisplay(_module.displayObject);
					}
					if (__type == ClipType.THEME) 
					{
						if (! track) 
						{
							backcolor = _module.backColor;
						}
						__maskedSprite.background = backcolor;
					}
				}
				__maskedSprite.applyEffects(__effects, clip_time);
				
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.time ' + __maskedSprite, e);
			}
		}
		public function get timeRange():TimeRange
		{
			return new TimeRange(__startFrame, lengthFrame, _quantize);
		}
		public function get track():int
		{	 
			return __track;	
		}
		public function set track(value:int):void
		{	
			__track = value;	
		}
		public function get type():String
		{	
			return __type;	
		}
		protected function _moduleAudioDatum(mod_position:uint, samples_to_grab:int, samples_per_frame:int):Vector.<AudioData>
		{
			var vector:Vector.<AudioData> = null;
			if (_module != null)
			{
				vector = _module.getAudioDatum(mod_position, samples_to_grab, samples_per_frame);
			}
			return vector;
		}		
		override protected function _parseTag():void
		{
			try
			{
				var value:Value = null;
				_defaults[ClipProperty.TRACK] = '0';
				
				if (__type != ClipType.AUDIO) _defaults[ClipProperty.EFFECTS] = '';
				if (__media != null)
				{
					value = __media.getValue(MediaProperty.LABEL);
					if (value.empty)
					{
						value = __media.getValue(CommonWords.ID);
					}
					if (! value.empty)
					{
						_defaults[MediaProperty.LABEL]  = value.string;
					}
					_mediaSeconds = __media.seconds;
				}
				else _mediaSeconds = super.getValue(MediaProperty.DURATION).number;
				switch (__type)
				{
					case ClipType.AUDIO:
						if (__media != null) __mediaDoesLoop = __media.getValue(MediaProperty.LOOP).boolean;
						else;
					case ClipType.VIDEO:
					case ClipType.MASH:
						_defaults[MediaProperty.AUDIO] = '1';
						break;
				}
				//if (! _mediaSeconds) RunClass.MovieMasher['msg'](this + '._parseTag could not determine media length');
				_defaults[ClipProperty.START] = '0';
				switch (__type)
				{
					case ClipType.EFFECT:
						_defaults[ClipProperty.LENGTH] = '0';
						_defaults[ClipProperty.LENGTHSECONDS] = '0';
						break;
					case ClipType.FRAME:
					case ClipType.IMAGE:
						_defaults[MediaProperty.FILL] = __media.getValue(MediaProperty.FILL).string;
						// fall through to THEME for length
					case ClipType.THEME:
						_defaults[ClipProperty.LENGTH] = '0';
						_defaults[ClipProperty.LENGTHSECONDS] = '0';
						break;
					case ClipType.TRANSITION:
						_defaults[ClipProperty.LENGTH] = '0';
						_defaults[ClipProperty.LENGTHSECONDS] = '0';
						_defaults[ClipProperty.FREEZESTART] = '0';
						_defaults[ClipProperty.FREEZEEND] = '0';
						break;
					case ClipType.VIDEO:
						_defaults[MediaProperty.FILL] = __media.getValue(MediaProperty.FILL).string;
						_defaults[ClipProperty.TRIM] = '';
						_defaults[ClipProperty.SPEED] = '1';
						if (! __media.getValue(ClipType.AUDIO).empty) _defaults[ClipProperty.VOLUME] = Fades.FIFTY;
						else;
						break;
					case ClipType.AUDIO:
						_defaults[ClipProperty.VOLUME] = Fades.FIFTY;
						if (__mediaDoesLoop) _defaults[ClipProperty.LOOPS] = '1';
						else  _defaults[ClipProperty.TRIM] = '';
						break;
					case ClipType.MASH:
						_defaults[ClipProperty.TRIM] = '';
						//_defaults[ClipProperty.SPEED] = '1';
						_defaults[ClipProperty.VOLUME] = Fades.FIFTY;
						break;
				}
				var k:String;
				// make sure there are default values for all of media's editable attributes
				var props:Object;
				if (__media != null)
				{
					props = __media.clipProperties();
					__readOnly = (props == null);
					if (! __readOnly) // if it is, then 'editable' attribute is probably blank
					{
						for (k in props)
						{
							_defaults[k] = props[k];
						}
					}
				}
				
				// initialize runtime variables, some things sort by track
				__track = super.getValue(ClipProperty.TRACK).number;
				if (_defaults[ClipProperty.START] != null)
				{
					__startFrame = parseFloat(super.getValue(ClipProperty.START).string);
				}
				if (_defaults[ClipProperty.SPEED] != null) 
				{
					if (! __isModular())
					{
						__speed = parseFloat(super.getValue(ClipProperty.SPEED).string);
					}
				}
				_lengthFrame = super.getValue(ClipProperty.LENGTH).number;
				if (_defaults[ClipProperty.LENGTH] != null) // true for transitions, effects, themes, images
				{
					if (! _lengthFrame) 
					{
						
						_lengthFrame = RunClass.TimeUtility['frameFromTime'](_mediaSeconds, _quantize);
						//RunClass.MovieMasher['msg'](this + '._parseTag ' + _mediaSeconds + ' => ' + _lengthFrame);
					}
				}
				else if (_defaults[ClipProperty.TRIM] != null) // video and non looping audio
				{	
					_defaults[ClipProperty.TRIMSTART] = '0';
					_defaults[ClipProperty.TRIMEND] = '0';
					var trimstart:Number = super.getValue(ClipProperty.TRIMSTART).number;
					var trimend:Number = super.getValue(ClipProperty.TRIMEND).number;
					_startTrimFrame = trimstart;
					_endTrimFrame = trimend;
					if (! _lengthFrame) _calculateLength();
				}
				else // it is a looping audio clip
				{
					__setLoops(super.getValue(ClipProperty.LOOPS), true); // doesn't check for collision
				}
				
				// look for effect and composite clips embedded in me
				var children:XMLList = _tag.clip;
				var child_effects:Array = new Array();
				var child_composites:Array = new Array();
				var clip : IClip;
				
				if (children.length())
				{
					for each (var clip_node : XML in children)
					{
						clip = fromXML(clip_node, _mash);
						if (clip is IClipEffect)
						{
							child_effects.push(clip as IClipEffect);
							clip.addEventListener(EventType.BUFFER, __moduleBuffer);
						}
						else
						{
							child_composites.push(clip);
						}
					}
					__setComposites(child_composites);
					__setEffects(child_effects);
				}
				else
				{
					var composites:String = super.getValue(ClipProperty.COMPOSITES).string;
					if (composites.length)
					{
						var a:Array = composites.split(',');
						for each (composites in a)
						{
							clip = Clip.fromMediaID(composites, null, _mash);
							if (clip != null) __composites.push(clip);
						}
						__adjustLengthComposites();
					}
					
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg']('CLIP._parseTag', e);
			}
		}
		private function __adjustLengthComposites():void
		{
			var z:uint = __composites.length;
			if (z)
			{
				var clip:IClip;
				var value:Value = getValue(ClipProperty.LENGTHFRAME);
				var mash_value:Value = new Value(_mash);
				for (var i:uint = 0; i < z; i++)
				{
					clip = __composites[i];			
					clip.setValue(value, ClipProperty.LENGTHFRAME);
				}
			}
		}
		private function __adjustLengthEffects():void
		{
			var z:uint = __effects.length;
			if (z)
			{
				var clip:IClipEffect;
				var length_frame:Number = getValue(ClipProperty.LENGTHFRAME).number;
				
				var mash_value:Value = new Value(_mash);
				for (var i:uint = 0; i < z; i++)
				{
					clip = __effects[i];
					clip.setValue(new Value(length_frame - clip.startFrame), ClipProperty.LENGTHFRAME);					
				}
			}
		}
		private function __arrayComposites():Array
		{
			var array:Array = new Array();
			var i,z:int;
			z = __composites.length;
			for (i = 0; i < z; i++)
			{
				array.push(__composites[i]);
			}
			return array;
		}
		private function __arrayEffects():Array
		{
			var array:Array = new Array();
			var i,z:int;
			z = __effects.length;
			for (i = 0; i < z; i++)
			{
				array.push(__effects[i]);
			}
			return array;
		}
		protected function _calculateLength():void
		{
			_lengthFrame = 0;
			__adjustLengthEffects();
			__adjustLengthComposites();
		}
		private function __clipBuffer(event:Event):void 
		{
			try
			{
				//RunClass.MovieMasher['msg'](this + '.__clipBuffer effects BUFFER');
				dispatchEvent(new Event(EventType.BUFFER));
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this, e);
			}
		}
		private function __createDisplayObject():void
		{
			__maskedSprite = new MaskedSprite();
			__maskedSprite.name = 'CLIP CANVAS';
			if (__metrics != null)
			{
				__maskedSprite.metrics = __metrics;
			}
		}
		private function __createModule(loader:IAssetFetcher, url:String):void
		{
			try
			{
				var c:Class = loader.classObject(url, 'module');
				//RunClass.MovieMasher['msg'](this + '.__createModule ' + url + ' ' + _module + ' ' + c);
				if (c != null)
				{
					_module = new c() as IModule;
					if (_module != null)
					{
						try
						{
							_module.clip = this;
							_module.addEventListener(EventType.BUFFER, __moduleBuffer);
							dispatchEvent(new Event(EventType.BUFFER));
						}
						catch(e:*)
						{
							RunClass.MovieMasher['msg'](this + '.__createModule', e);
						}
					}
					else RunClass.MovieMasher['msg'](this +  '.__createModule unable to instance ' + c);
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__createModule', e);
			}
		}
		private function __destroyDisplayObject():void
		{
			if (__maskedSprite != null) 
			{	
				__maskedSprite.unload();
				__maskedSprite = null;
			}
		}
		private function __hasAudio(ignore_enabled:Boolean = false):Boolean 
		{ 
			var tf:Boolean = false;
			var z:uint;
			var i:uint;
			switch(__type)
			{
				case ClipType.THEME:
				case ClipType.TRANSITION:
				case ClipType.EFFECT:
					if (! ignore_enabled)
					{
						z = __composites.length;
						for (i = 0; ((! tf) && (i < z)); i++)
						{
							tf = (__composites[i].getValue(ClipProperty.HASAUDIO).boolean)
						}
					}
					break;
				case ClipType.AUDIO:
					tf = (ignore_enabled || __volumeEnabled());
					break;
				case ClipType.MASH:
					tf = ((ignore_enabled || __volumeEnabled()) && getValue('avmash').object.getValue(ClipProperty.HASAUDIO).boolean);
					break;
				case ClipType.VIDEO:
					tf = ((__speed == 1) && (! getValue(MediaProperty.AUDIO).empty) && (ignore_enabled || __volumeEnabled()));
					break;
			}
			if ((! tf) && (! ignore_enabled))
			{
				z = __effects.length;
				for (i = 0; ((! tf) && (i < z)); i++)
				{
					if (__effects[i].getValue((ignore_enabled ? ClipProperty.ISAUDIO : ClipProperty.HASAUDIO)).boolean) 
					{
						tf = true;
						break;
					} 
				}
			}
			//RunClass.MovieMasher['msg'](this + '.__hasAudio ' + tf);
			return tf; 
		}
		private function __isModular():Boolean
		{
			var is_modular:Boolean = true;
			switch (__type)
			{
				case ClipType.AUDIO:
				case ClipType.IMAGE:
				case ClipType.FRAME:
				case ClipType.VIDEO: 
					is_modular = false;	
					break;
			}
			return is_modular;
		}
		private function __lastEffectStart():Number
		{
			var n:Number = 0;
			var clip:IClipEffect;
			for each (clip in __effects)
			{
				n = Math.max(n, clip.startFrame);
			}
			return n;
		}
		private function __mediaRange(range:TimeRange, add_one_frame:Boolean = false):TimeRange
		{
			return TimeRange.fromTimes(__clipTime(range), __clipTime(range.endTime, add_one_frame));
		}
		private function __moduleBuffer(event:Event):void 
		{
			try
			{
				//RunClass.MovieMasher['msg'](this + '.__moduleBuffer BUFFER ' + _module);
				
				if (_module != null)
				{
					dispatchEvent(new Event(EventType.BUFFER));
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this, e);
			}
		}
		private function __moduleLoaded(event:Event):void
		{
			try
			{
				if (_module == null)
				{
					__createModule(event.target as IAssetFetcher, __symbolURL());
					
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this, e);
			}

		}
		private function __requestModule():void
		{
			try
			{
				if (! __requestedModule)
				{
					__requestedModule = true;
					
					
					var symbol:String = __symbolURL();
					
					if (symbol.length)
					{
						var loader:IAssetFetcher = RunClass.MovieMasher['assetFetcher'](symbol, 'swf');
						
						if (loader.state == EventType.LOADED)
						{
							__createModule(loader, symbol);
						}
						else 
						{
							loader.addEventListener(Event.COMPLETE, __moduleLoaded);
						}
					}
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this, e);
			}
		}
		private function __setComposites(composites:Array):void
		{
			__unloadComposites(composites);
			var clip:IClip;
			var i,z:uint;
			var orig_composites:Vector.<IClip> = __composites;
			__composites = new Vector.<IClip>();
			z = composites.length;
			for (i = 0; i < z; i++)
			{
				clip = composites[i];
				if (orig_composites.indexOf(clip) == -1)
				{
					clip.setValue(new Value(_mash), ClipProperty.MASH);
					clip.owner = this;
				}
				clip.track = i - z;
				__composites.push(clip);
			}
			__adjustLengthComposites();
		}
		private function __setEffects(effects:Array):void
		{
			__unloadEffects(effects);
			var clip:IClip;
			var i,z:uint;
			var orig_effects:Vector.<IClipEffect> = __effects;
			__effects = new Vector.<IClipEffect>();
			z = effects.length;
			for (i = 0; i < z; i++)
			{
				clip = effects[i];
				if (orig_effects.indexOf(clip) == -1)
				{
					clip.owner = this;
					clip.setValue(new Value(_mash), ClipProperty.MASH);
					clip.addEventListener(EventType.BUFFER, __clipBuffer);
				}
				clip.track = i - z;
				__effects.push(clip);
			}
			__adjustLengthEffects();
		}
		private function __setLengthFrame(frame:Number):Boolean
		{
			var length_changed:Boolean = false;
			if ((__type == ClipType.IMAGE) || (__type == ClipType.FRAME)  || __isModular())
			{
				
				lengthFrame = Math.round(frame); // collision detection for effects
				
				length_changed = true;
			
			}
			else if ((__type == 'video') && (__track < 0))
			{
				
				//RunClass.MovieMasher['msg'](this + '.__setLengthFrame VIDEO ' + frame);
			
				var time:Time = Time.fromSeconds(_mediaSeconds, _quantize);
				time.multiply(__speed);
				var media_frames:Number = RunClass.TimeUtility['frameFromTime'](_mediaSeconds, _quantize) * __speed;
				var ideal_end_trim:Number = media_frames - ((frame / __speed) + _startTrimFrame);
				var minlength:Number = RunClass.MovieMasher['getOptionNumber']('clip', 'minlength');
				if (minlength) minlength = (1 / _quantize);
				else minlength = 1;
				minlength = minlength / __speed;
				ideal_end_trim = Math.max(0, ideal_end_trim); // can't be negative
				ideal_end_trim = Math.min(media_frames - (minlength + _startTrimFrame), ideal_end_trim); // enforce minimum clip length
				if (ideal_end_trim > _endTrimFrame) _endTrimFrame = ideal_end_trim;
			}
			return length_changed;
		}
		private function __setLoops(value:Value, no_collision = false):void
		{
			value.number = Math.round(value.number);
			if (! no_collision)
			{
				var tracks:Array = _mash.clipsInOuterTracks(__startFrame, __startFrame + RunClass.TimeUtility['frameFromTime'](_mediaSeconds * value.number, _quantize), [this], track, 1, ClipType.AUDIO);
				if (tracks.length)
				{
					// hit something
					value.number = Math.floor((tracks[0].startFrame - __startFrame) / RunClass.TimeUtility['frameFromTime'](_mediaSeconds, _quantize));
				}
			}
			_lengthFrame = RunClass.TimeUtility['frameFromTime'](value.number * _mediaSeconds, _quantize);
			super.setValue(value, ClipProperty.LOOPS);
		}
		private function __setStartFrame(frame:Number):void
		{
			if (__track < 0)
			{
				var minlength:Number = RunClass.MovieMasher['getOptionNumber']('clip', 'minlength');
				if (minlength) minlength = RunClass.TimeUtility['frameFromTime'](minlength, _quantize);
				else minlength = 1;
				if (__composites.length) minlength = Math.max(minlength, __composites[0].lengthFrame); 
				frame = Math.min(frame, owner.lengthFrame - minlength);
				_lengthFrame = owner.lengthFrame - __startFrame;
			}
			__startFrame = frame;
		}
		private function __setTrim(value:Value, no_collision:Boolean = false):void
		{
			
			var value_array:Array = value.array;
			var old_trim:Array = getValue(ClipProperty.TRIM).array;
			old_trim[0] = parseFloat(old_trim[0]);
			old_trim[1] = parseFloat(old_trim[1]);
			value_array[0] = parseFloat(value_array[0]);
			value_array[1] = parseFloat(value_array[1]);
			
			
			if (Math.abs(value_array[0] - old_trim[0]) > Math.abs(value_array[1] - old_trim[1]))
			{
				__setTrimStart((RunClass.TimeUtility['frameFromTime'](_mediaSeconds * __speed * value_array[0] / 100, _quantize, 'floor')), no_collision);
			}
			else 
			{
				__setTrimEnd((RunClass.TimeUtility['frameFromTime'](_mediaSeconds * __speed * value_array[1] / 100, _quantize, 'floor')), no_collision);
			}
		}
		private function __setTrimEnd(frames:Number, no_collision:Boolean = false):void
		{
			try
			{
				frames = Math.max(frames, 0);
				var media_frames:Number;
				var other_trim:Number = super.getValue(ClipProperty.TRIMSTART).number;
				var prev_trim:Number = super.getValue(ClipProperty.TRIMEND).number;
				var dif:Number = prev_trim - frames;
				if (dif)
				{
					if (dif < 0) // making clip smaller
					{
						// enforce minimum clip length
						var minlength:Number = RunClass.MovieMasher['getOptionNumber']('clip', 'minlength');
						if (minlength) minlength = RunClass.TimeUtility['frameFromTime'](minlength, _quantize);
						else minlength = 1;
						media_frames = RunClass.TimeUtility['frameFromTime'](_mediaSeconds * __speed, _quantize, 'floor');
						frames = Math.min(frames, media_frames - (other_trim + minlength));
					}
					else // making clip bigger
					{
						if (! no_collision)
						{
							// make sure we don't collide with something to left
							var tracks:Array = _mash.clipsInOuterTracks(__startFrame + _lengthFrame, __startFrame + _lengthFrame + dif, [this], track, 1, ClipType.AUDIO);
							
							if (tracks.length)
							{
								// hit something
								var clip:Clip = tracks[0];
								media_frames = RunClass.TimeUtility['frameFromTime'](_mediaSeconds * __speed, _quantize, 'floor');
								frames = (media_frames - other_trim) - (clip.startFrame - __startFrame);
							}
						}
						else if (__track < 0) // composited video clip
						{
							media_frames = RunClass.TimeUtility['frameFromTime'](_mediaSeconds * __speed, _quantize, 'floor');
							frames = Math.max(frames, (media_frames - other_trim) - (owner.lengthFrame / __speed));
						}
					}
					_endTrimFrame = frames;
					_calculateLength();					
					var value:Value = new Value(frames);
					
					//RunClass.MovieMasher['msg'](this + '.__setTrimEnd ' + ClipProperty.TRIMEND + ' = ' + value.string);
					super.setValue(value, ClipProperty.TRIMEND);
					_dispatchEvent(ClipProperty.TRIMEND, value);
					_dispatchEvent(ClipProperty.TRIM, value);
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__setTrimEnd', e);
			}

		}
		private function __setTrimStart(frames:Number, no_collision:Boolean = false):void
		{
			try
			{
				var origtrim:Number = frames;
				frames = Math.max(frames, 0);
				var other_trim:Number = getValue(ClipProperty.TRIMENDFRAME).number;
				var prev_trim:Number = getValue(ClipProperty.TRIMSTARTFRAME).number;
				var dif:Number = prev_trim - frames;
				var media_frames:Number;
				if (dif)
				{
					
					if (dif < 0) // making clip smaller
					{
						// enforce minimum clip length
						var minlength:Number = RunClass.MovieMasher['getOptionNumber']('clip', 'minlength');
						if (minlength) minlength = RunClass.TimeUtility['frameFromTime'](minlength, _quantize);
						else minlength = 1;
						media_frames = RunClass.TimeUtility['frameFromTime'](_mediaSeconds * __speed, _quantize, 'floor');
							
						frames = Math.min(frames, media_frames - (other_trim + minlength));
					}
					else // making clip bigger
					{
						if (! no_collision)
						{
							// make sure we don't collide with something to left
							var tracks:Array = _mash.clipsInOuterTracks(__startFrame - dif, __startFrame, [this], track, 1, ClipType.AUDIO);
							
							if (tracks.length)
							{
								// hit something
								var clip:Clip = tracks[tracks.length - 1];
								media_frames = RunClass.TimeUtility['frameFromTime'](_mediaSeconds * __speed, _quantize, 'floor');
								frames = (media_frames - other_trim) - RunClass.TimeUtility['timeFromFrame'](__startFrame + _lengthFrame - (clip.startFrame + clip.lengthFrame), _quantize);
							}
						}
						else if (__track < 0) // composited video clip
						{
							media_frames = RunClass.TimeUtility['frameFromTime'](_mediaSeconds * __speed, _quantize, 'floor');
							frames = Math.max(frames, (media_frames - other_trim) - (owner.lengthFrame / __speed));
												
						}
						
					}
					if (track >= 0)
					{
						__startFrame += frames - _startTrimFrame;
						setValue(new Value(__startFrame), ClipProperty.START); // so tag is updated too
					}
					_startTrimFrame = frames;
					
					_calculateLength();
					var value:Value = new Value(frames);
					super.setValue(value, ClipProperty.TRIMSTART);
					_dispatchEvent(ClipProperty.TRIMSTART, value);
					_dispatchEvent(ClipProperty.TRIM, value);
				}
			}			
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__setTrimStart', e);
			}

		}
		private function __symbolURL():String
		{
			
			var symbol:String = getValue(MediaProperty.SYMBOL).string;
			if (! symbol.length) symbol = __media.getValue(MediaProperty.SYMBOL).string;
			if (symbol.length)
			{
				if (symbol.indexOf('@') == -1)
				{
					symbol = '@' + symbol;
				}
				if (symbol.indexOf('/') == -1)
				{
					symbol = __media.getValue(MediaProperty.URL).string + symbol;
				}
			}
			else
			{
				switch (__type)
				{
					case ClipType.FRAME:
					case ClipType.MASH:
					case ClipType.AUDIO:
					case ClipType.IMAGE:
						symbol += '@AV' + __type.substr(0, 1).toUpperCase() + __type.substr(1);
						break;
					case ClipType.VIDEO:
						symbol += '@AVSequence';
						break;
					
				}
			}
			return symbol;
		}
		private function __timelineEndFrame():Number // returns time eaten up at end by transitions and padding
		{
			var trans_time:Number = 0;
			if (_mash)
			{
				switch (__type)
				{
					case ClipType.AUDIO:
					case ClipType.EFFECT:
					case ClipType.TRANSITION:
						break;
					default:
						if ((__index != -1) && (__index < (_mash.tracks.video.length - 1)))
						{
							if (_mash.tracks.video[__index + 1] is TransitionClip)
							{
								trans_time += _mash.tracks.video[__index + 1].lengthFrame;
						
								trans_time -= __endPadFrame;
							}
						}
						else;
				}
			}
			return trans_time;
		
		}
		private function __timelineStartFrame():Number // returns time eaten up at start by transitions and padding
		{
			var trans_time:Number = 0;
			if (_mash)
			{
				switch (__type)
				{
					case ClipType.AUDIO:
					case ClipType.EFFECT:
					case ClipType.TRANSITION:
						break;
					default:
						if (__index > 0)
						{
							if (_mash.tracks.video[__index - 1] is TransitionClip)
							{
								trans_time += _mash.tracks.video[__index - 1].lengthFrame;
								trans_time -= __startPadFrame;
							}
						}
						else;
				}
			}
			return trans_time;
		}
		private function __trimFrame(trim_end:Boolean = false):Number
		{
			var n:Number = 0;
			switch(__type)
			{
				case ClipType.EFFECT:
					break;
				case ClipType.AUDIO:
					if (__mediaDoesLoop) break;
				case ClipType.MASH:
				case ClipType.VIDEO:
					n = (trim_end ? _endTrimFrame : _startTrimFrame);
			}
			return n;
		}
		private function __trimValue():Value
		{
			var value:Value = new Value(0);
			if (_mash != null)
			{
				
				var media_frames:Number = RunClass.TimeUtility['frameFromTime'](_mediaSeconds, _quantize) * __speed;
				value = new Value(((_startTrimFrame * 100) / media_frames) + ',' + ((_endTrimFrame * 100) / media_frames));
			}
			return value;
		}
		private function __unloadComposites(ignore:Array):void
		{
			
			var z:uint = __composites.length;
			for (var i:uint = 0; i < z; i++)
			{
				if (ignore.indexOf(__composites[i]) == -1)
				{
					__composites[i].owner = null;
					__composites[i].setValue(new Value(), ClipProperty.MASH);
					__composites[i].removeEventListener(EventType.BUFFER, __moduleBuffer);
					__composites[i].unload();
				}
			}
		}
		private function __unloadEffects(ignore:Array):void
		{
			var z:uint = __effects.length;
			for (var i:uint = 0; i < z; i++)
			{
				if (ignore.indexOf(__effects[i]) == -1)
				{
					__effects[i].owner = null;
					__effects[i].setValue(new Value(), ClipProperty.MASH);
					__effects[i].removeEventListener(EventType.BUFFER, __moduleBuffer);
					__effects[i].unload();
				}
			}
		}
		private function __volumeEnabled():Boolean
		{
			var tf:Boolean = (! super.getValue(ClipProperty.VOLUME).equals(Fades.OFF));
			return tf;
		}	
		private function __volumeFromTime(project_time:Number):Number
		{
			var n:Number = 100.0;
			
			var value:Value = getValue(ClipProperty.VOLUME);
			if (! value.empty)
			{
				var plot:Array = RunClass.PlotUtility['string2Plot'](value.string);
				
				n = RunClass.PlotUtility['value'](plot, ((project_time - __startFrame) * 100) / _lengthFrame);
			}
			n = n / 100;
			
			return n;
		}	
		private function __xml():XML
		{
			var result:XML = _tag.copy();
			__adjustLengthEffects();
			__adjustLengthComposites();
			
			
			delete result.clip; // composites and effects
			delete result.@composites;
			delete result.@effects;
			
			for (var k:String in _defaults)
			{
				switch (k)
				{
					case ClipProperty.EFFECTS:
					case ClipProperty.COMPOSITES:
					case ClipProperty.TRIM:
						break;
					default:
						result.@[k] = getValue(k).string;
				}
			}
			
			switch(__type)
			{
				case ClipType.THEME:
				case ClipType.FRAME:
				case ClipType.IMAGE:
					if (startPadFrame || endPadFrame) 
					{
						result.@length = lengthFrame + startPadFrame + endPadFrame;
						if (startPadFrame) result.@start = startFrame - startPadFrame;
					}
					else;
					break;
				case ClipType.VIDEO:
				case ClipType.AUDIO:
				case ClipType.MASH:
					// because length is not in defaults
					result.@length = lengthFrame;
					break;
			}
			var z:uint;
			var i:uint;
			var clip:IClip;
			z = __effects.length;
			if (z)
			{
				for (i = 0; i < z; i++)
				{
					clip = __effects[i];
					result.appendChild(clip.getValue(ClipProperty.XML).object as XML);
				}
			}
			z = __composites.length;
			if (z)
			{
				for (i = 0; i < z; i++)
				{
					clip = __composites[i];
					result.appendChild(clip.getValue(ClipProperty.XML).object as XML);
				}
			}
			return result;
		}
		private var __composites:Vector.<IClip>; 
		private var __effects:Vector.<IClipEffect>; 
		private var __endPadFrame:Number = 0;
		protected var _endTrimFrame:Number = 0;
		private var __index:int = 0;
		private var __maskedSprite:MaskedSprite;
		private var __media:IMedia; // the media object that I am an instance of
		private var __mediaDoesLoop:Boolean;
		private var __metrics:Size;
		private var __parent:IClip;
		protected var _quantize:uint = 0;
		private var __readOnly:Boolean = false;
		private var __requestedModule:Boolean = false;
		private var __speed:Number = 1;
		private var __startFrame:Number = 0;
		private var __startPadFrame:Number = 0;
		protected var _startTrimFrame:Number = 0;
		private var __track:int = 0;
		private var __type:String;
		protected var _lengthFrame:Number = 0;
		protected var _mash:IMash; // the mash object I'm inside of (might be null)
		protected var _mediaSeconds:Number = 0;
		protected var _module:IModule; // my visual representation in the player		
	}
}
