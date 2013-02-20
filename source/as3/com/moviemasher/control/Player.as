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

package com.moviemasher.control
{
	import com.moviemasher.constant.*;
	import com.moviemasher.events.*;
	import com.moviemasher.interfaces.*;
	import com.moviemasher.type.*;
	import com.moviemasher.utils.*;
	import flash.display.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.system.*;
	import flash.utils.*;

/**
* Implimentation class represents a player control
*/
	public class Player extends Control implements IDrop, IPlayer
	{
		public function Player()
		{
			//_defaults.id = ReservedID.PLAYER;
			_defaults.volume = '75';
			_defaults.source = '';//ClipProperty.MASH;
			_defaults.fps = '10';
			_defaults[PlayerProperty.BUFFERTIME] = '10';
			_defaults[PlayerProperty.MINBUFFERTIME] = '1';
			_defaults[PlayerProperty.UNBUFFERTIME] = '2';
			_defaults.volume = '75';
			_defaults.dirty = '0';
			_defaults.hisize = '2';
			_defaults.hicolor = 'FFFFFF';
			_defaults.hialpha = '50';
			_defaults[MashProperty.STALLING] = '0';
			_allowFlexibility = true;
			__mashLengthTime = new Time(0, 1);
		}	
		public function dragAccept(drag:DragData):void
		{
		//	RunClass.MovieMasher['msg'](this + '.dragAccept ' + drag.items[0]);
			var clip:IClip = null;
			var media:IMedia = null;
			clip = drag.items[0] as IClip;
			if (clip != null)
			{
				media = clip.media as IMedia;
				if (media != null)
				{
					var source:String = media.getValue(MediaProperty.URL).string;
					if (source.length)
					{
						setValue(new Value(source), 'source');
					}
				}
			}
		}
		public function dragHilite(tf:Boolean):void
		{
			__dragIndicator.visible = tf;
		}
		public function dragOver(drag:DragData):Boolean
		{
			var ok:Boolean = false;
			try
			{
				if ( ! ((__mash == null) || __mash.getValue(PlayerProperty.DIRTY).boolean))
				{
					
					if (drag.items[0] is IClip)
					{
						var clip:IClip = drag.items[0] as IClip;
						if (clip.getValue(CommonWords.TYPE).equals(ClipProperty.MASH))
						{
							ok = true;
							if (__mash != null)
							{
								if (__mash.getValue(CommonWords.ID).equals(clip.getValue(CommonWords.ID).string))
								{
									ok = false;
								}
							}
						}
					}
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this, e);
			}
			return ok;
		}
		override public function finalize():void
		{
			super.finalize();
			if (RunClass.DragUtility != null) 
			{
				__dragIndicator = new Sprite();
				addChild(__dragIndicator);
				__dragIndicator.visible = false;
				RunClass.DragUtility['addTarget'](this);
			}
			//RunClass.MovieMasher['msg'](this + '.finalize ' + _width + 'x' + _height + ' ' + __mash);
			//if (__mash != null) __mashSync();
			__finalized = true;
			
			if (getValue(PlayerProperty.AUTOSTART).boolean || getValue(PlayerProperty.PLAY).boolean)
			{
				// not sure why we were turning autostart off
				//setValue(new Value(0), PlayerProperty.AUTOSTART);
				__resetPlayback();
				
				__paused = true;
				setValue(new Value(1), PlayerProperty.PLAY);
			}
		
		}
		override public function getValue(property:String):Value
		{
			var value:Value;
			switch(property)
			{
				case 'ratio':
					if (__mash != null) value = __mash.getValue(property);
					else if (_width && _height) value = new Value(_width / _height);
					else value = new Value(0);
					break;
				case MediaProperty.FPS:
					value = new Value(__fps);
					break;
				case PlayerProperty.LOCATION:
					value = new Value(__seekingTime == null ? 0 : __seekingTime.seconds);
					break;
				case MashProperty.POSITION:
					value = new Value(RunClass.StringUtility['timeString']((__seekingTime == null ? 0 : __seekingTime.seconds), __fps, __mashLengthTime.seconds));
					break;
				case PlayerProperty.COMPLETED:
					value = new Value(__seekingTime == null ? 0 : __seekingTime.ratio(__mashLengthTime) * 100);
					break;
				case ClipProperty.LENGTHFRAME:
					var time:Time = __mashLengthTime.copyTime();
					time.scale(__fps);
					value = new Value(time.frame);
					break;
				case ClipProperty.LENGTH:
					value = new Value(__mashLengthTime.seconds);
					break;
				case MediaProperty.DURATION:
					value = new Value(RunClass.StringUtility['timeString'](__mashLengthTime.seconds, __fps, __mashLengthTime.seconds));
					break;
				case ClipProperty.MASH:
					//RunClass.MovieMasher['msg'](this + '.getValue mash ' + __mash);
					value = new Value(__mash);
					break;
				case 'displaywidth':
					value = new Value(_width);
					break;
				case 'displayheight':
					value = new Value(_height);
					break;
				case PlayerProperty.PLAY:
					value = new Value(__paused ? 0 : 1);
					break;
				case 'revert':
				case PlayerProperty.DIRTY:
				case ClipProperty.TRACK:
				case MashProperty.TRACKS:
				case MediaProperty.LABEL:
				case MashProperty.STALLING:
					if (__mash != null)
					{
						value = __mash.getValue(property);
						break;
					}
				default:
					value = super.getValue(property);
			}
			return value;
		}
		private var __returnedZero:Boolean;
		public function overPoint(root_pt:Point):Boolean
		{
			var over_point:Boolean = false;
			var pt:Point = globalToLocal(root_pt);
						
			if ((pt.x >0) && (pt.y > 0) && (pt.x < _width) && (pt.y < _height))
			{
				over_point = true;
			}
			return over_point;
		}
		override protected function _createChildren():void
		{
			setValue(super.getValue(ClipProperty.VOLUME), ClipProperty.VOLUME);
			setValue(super.getValue(MediaProperty.FPS), MediaProperty.FPS);

			super._createChildren();
			setValue(super.getValue('source'), 'source');
		}
	
		override public function resize() : void
		{
			
			try
			{
				if (_width && _height)
				{
					//RunClass.MovieMasher['msg'](this + '.resize ' + _width + 'x' + _height);
					if (__dragIndicator != null)
					{
						var hialpha:Number = getValue('hialpha').number;
						var hicolor:String = getValue('hicolor').string;
						var c:Number = RunClass.DrawUtility['colorFromHex'](hicolor);
						var hisize:Number = getValue('hisize').number;
						__dragIndicator.graphics.clear();
						RunClass.DrawUtility['fillBox'](__dragIndicator.graphics, 0, 0, _width, hisize, c, hialpha);
						RunClass.DrawUtility['fillBox'](__dragIndicator.graphics, 0, _height - hisize, _width, hisize, c, hialpha);
						RunClass.DrawUtility['fillBox'](__dragIndicator.graphics, 0, hisize, hisize, _height - (2 * hisize), c, hialpha);
						RunClass.DrawUtility['fillBox'](__dragIndicator.graphics, _width - hisize, hisize, hisize, _height - (2 * hisize), c, hialpha);
					}
					if (__mash != null)
					{
						__mash.metrics = new Size(_width, _height);
						if (__finalized) __resetPlayback();
					}					
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this, e);
			}
		}
		override public function setValue(value:Value, property:String):Boolean
		{
			try
			{
				var dispatch:Boolean = false;
				var set_mash:Boolean = false;
				var do_super:Boolean = false;
				switch(property)
				{
					case MediaProperty.FPS:
						__fps = value.number;
						if (getValue('id').equals(ReservedID.PLAYER)) RunClass.TimeUtility['fps'] = __fps;
						dispatch = true;
						break;
					case PlayerProperty.DIRTY:
						set_mash = true;
						break;
					case 'refresh':
						if (__paused) __resetPlayback();
						break;
					case 'revert':
						set_mash = true;
						/*
						__source.items = new Array(__mashXML.copy());
						__sourceChange(null);
						*/
					//	RunClass.MovieMasher['msg'](this + '.setValue ' + property + ' ' + value.string);
						break;
					case 'mash':
						__setMash(__mashFromSomething(value.object));
						dispatch = true;
						value = getValue('mash');
						break;
					case 'new':
						__newMash(value.string);
						break;
					case PlayerProperty.COMPLETED:
						var a_time:Time = __mashLengthTime.copyTime();
						a_time.multiply(value.number / 100.00);
						__userSetTime(a_time);
						break;
					case MashProperty.POSITION:
					case PlayerProperty.LOCATION:
						__userSetTime(Time.fromSeconds(value.number, __fps));
						break;
					case PlayerProperty.AUTOSTART:
					case PlayerProperty.AUTOSTOP:
					case PlayerProperty.MINBUFFERTIME:
					case PlayerProperty.BUFFERTIME:
					case PlayerProperty.UNBUFFERTIME:
					case ClipProperty.VOLUME:
						do_super = true;
						set_mash = true;
						dispatch = true;
						break;
					case PlayerProperty.PLAY:
						paused = ! value.boolean;
						break;
					case MediaProperty.LABEL:
						set_mash = true;
						break;
					case 'source':
						__setSource(RunClass.MovieMasher['source'](value.string));
						dispatch = true;					
						break;
					default:
						do_super = true;
						dispatch = true;
				}
				if (do_super)
				{
					super.setValue(value, property);
				}
				if (set_mash && (__mash != null)) __mash.setValue(value, property);
				if (dispatch) _dispatchEvent(property, value);
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.setValue ' + property, e);
			}

			return false;
		}
		private function __mashSync():void
		{
			try
			{
				var property:String;
				
				__mash.setValue(getValue(ClipProperty.VOLUME), ClipProperty.VOLUME);
				__mash.setValue(getValue(PlayerProperty.BUFFERTIME), PlayerProperty.BUFFERTIME);
				__mash.setValue(getValue(PlayerProperty.MINBUFFERTIME), PlayerProperty.MINBUFFERTIME);
				__mash.setValue(getValue(PlayerProperty.UNBUFFERTIME), PlayerProperty.UNBUFFERTIME);
				__mash.setValue(getValue(PlayerProperty.AUTOSTOP), PlayerProperty.AUTOSTOP);
				__mashSetLength(__mash.lengthTime);
					
				for each(property in __mashProperties)
				{
					__mash.addEventListener(property, __mashChange);
					switch (property)
					{
						case MashProperty.LENGTH_TIME:
						case MashProperty.TIME:
						case ClipProperty.VOLUME: break;
						default: // MashProperty.STALLING, PlayerProperty.DIRTY, ClipProperty.TRACK, MashProperty.TRACKS, MediaProperty.LABEL
							//RunClass.MovieMasher['msg'](this + '.__mashSync ' + property + ' ' + __mash.getValue(property).string);
							__mashChange(new ChangeEvent(__mash.getValue(property), property));
					}
				}
				addChildAt(__mash.displayObject, 0);
	
				//RunClass.MovieMasher['setByID'](ClipProperty.MASH, __mash);
			
				if (_width && _height)
				{
					//RunClass.MovieMasher['msg'](this + '.mash resizing ' + _width + 'x' + _height);
					resize();
				}
				_dispatchEvent(ClipProperty.MASH);
				__mash.goTime(new Time(0, __fps));
				//__resetPlayback();
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__mashSync', e);
			}
		}
		public function set paused(boolean:Boolean):void
		{
			if (__paused != boolean)
			{
				if (! boolean) RunClass.PlayerStage['instance'].startPlaying(this);
				__paused = boolean;
				if ((__mash != null) && __finalized)
				{
					__mash.paused = boolean;
				}
				_dispatchEvent(PlayerProperty.PLAY);
			}
		}
		public function get paused():Boolean
		{
			return __paused;
		}
		override protected function _adjustVisibility():void
		{
			RunClass.PlayerStage['instance'][(_hidden ? 'de' : '') + 'registerPlayer'](this);
		}
		private function __dispatchLocationEvent():void
		{
			_dispatchEvent(PlayerProperty.LOCATION);
			_dispatchEvent(PlayerProperty.COMPLETED);
			_dispatchEvent(MashProperty.POSITION);
		}
		private function __mashChange(event:ChangeEvent):void
		{
		
			var dispatch:Boolean = false;
			switch (event.property)
			{
				case MashProperty.TIME:
					__mashTime = event.value.object as Time;
					//RunClass.MovieMasher['msg'](this + '.__mashChange ' + event.property + ' ' + __mashTime + ' ' + __seekingTime)
					//__mashLocation = RunClass.TimeUtility['convertFrame'](event.value.number, __mash.getValue(MashProperty.QUANTIZE).number, __fps); 
					
					if (! __mashTime.isEqualToTime(__seekingTime))
					{
						__seekingTime = __mashTime.copyTime();
						__dispatchLocationEvent();
					}
					break;
				case MashProperty.LENGTH_TIME:
					__mashSetLength(event.value.object as Time);
					break;
				case PlayerProperty.DIRTY:
				case ClipProperty.TRACK:
				case MashProperty.TRACKS:
				case MashProperty.STALLING:
				case MediaProperty.LABEL:
				case 'revert':
					dispatch = hasEventListener(event.property);
					break;
				case ClipProperty.VOLUME:
					break;
			}
			if (dispatch) _dispatchEvent(event.property, event.value);
		}
		private function __mashFromSomething(something:*):IMash
		{
			//RunClass.MovieMasher['msg'](this + '.__mashFromSomething ' + (something is XML ? (something as XML).toXMLString() : something));
							
			var i_mash:IMash = null;
			var xml:XML = null;
			var xml_list:XMLList;
			var string:String = null;
			var array:Array = null;
			if (something != null)
			{
				if (something is IMash) // easy
				{
					i_mash = something as IMash;
				}
				else if (something is Array) // grab first item and recurse
				{
					array = something as Array;
					if (array.length) 
					{
						something = array[0];
						i_mash = __mashFromSomething(something);
					}
				}
				else if (something is String)
				{
					string = something as String;
					if (string.length)
					{
						if (string.substr(0, 1) == '<')
						{
							try
							{
								xml = new XML(something);
							}
							catch(e:*)
							{
								xml = null;
							}
						}
						if (xml == null) xml = RunClass.Media['xmlFromMediaID'](string, __mash);
						if (xml == null) xml = new XML('<mash url="' + string + '" />');
						if (xml != null)
						{
							i_mash = __mashFromSomething(xml);
						}
					}
				}
				else if (something is XML)
				{
					xml = something as XML;
					string = xml.name();
					switch (string)
					{
						case 'moviemasher':
							xml_list = xml..mash;
							if (xml_list.length()) xml = xml_list[0];
							else break; // otherwise fall through to 'mash'
						case 'mash':
							i_mash = RunClass.Mash['fromXML'](xml);
							break;
						case 'media':
							i_mash = RunClass.Mash['fromMediaXML'](xml, getValue(String(xml.@type) + 'preview').string);
							break;
					}
				}
			}
			//RunClass.MovieMasher['msg'](this + '.__mashFromSomething ' + i_mash + ' ' + (i_mash == null));
			return i_mash;
		}
		private function __mashSetLength(time:Time):void
		{
			//RunClass.MovieMasher['msg'](this + '.__mashSetLength ' + time + ' __mashLengthTime = ' + __mashLengthTime);
			if ((time != null) && (! time.isEqualToTime(__mashLengthTime)))
			{
				__mashLengthTime = time.copyTime();
				if (__mashLengthTime.lessThan(__mashTime)) __userSetTime(__mashLengthTime);
				_dispatchEvent(ClipProperty.LENGTH);
				_dispatchEvent(PlayerProperty.COMPLETED);
				_dispatchEvent(MediaProperty.DURATION);
			}
		}
		private function __newMash(id:String = ''):void
		{
			
			try
			{
				var dims:Size = null;
				if (__mash != null)
				{
					dims = __mash.getValue('displaysize').object as Size;
				}
				if (dims == null)
				{
					dims = new Size(_width, _height);
				}
				if (! id.length) id = IDUtility.generate();
				var mash_xml:XML = <mash />;
				mash_xml.@width = dims.width;
				mash_xml.@height = dims.height;
				mash_xml.@id = id;
				mash_xml.@label = 'Untitled';
				
				__setMash(RunClass.Mash['fromXML'](mash_xml));
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this, e);
			}
		}
		private function __resetPlayback():void
		{
			if ((__mash != null) && __finalized) 
			{
				__mash.goTime(null);
			}
		}
/*		private function __saveXML():void
		{
			__mashXML = __mash.getValue(ClipProperty.XML).object as XML;
			//RunClass.MovieMasher['msg'](this + '.__saveXML ' + __mashXML.toXMLString());
			var object:Object = __mash.referencedMedia();
			var key:String;
			for (key in object)
			{
				__mashXML.appendChild(object[key]);
			}
		}
*/
		private function __seekTimed(event:TimerEvent):void
		{
			try
			{
				if (__seekingTime.isEqualToTime(__seekedTime))
				{
					if (__seekTimer != null)
					{
						__seekTimer.removeEventListener(TimerEvent.TIMER, __seekTimed);
						__seekTimer.stop();
						__seekTimer = null;
					}
				}
				else __seekedTime = __seekingTime.copyTime();
				
				if ((__mash != null) && _width && _height)
				{
					
					__mash.goTime(__seekedTime);//RunClass.TimeUtility['convertFrame'](__seekedFrame, __fps, __mash.getValue(MashProperty.QUANTIZE).number, ''));
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this, e);
			}
		}
		private function __setMash(iMash:IMash):void
		{
			try
			{
				setValue(new Value(0), PlayerProperty.PLAY);
				var property:String;
				if (__mash != null) 
				{
					setValue(new Value(0), MashProperty.POSITION);
					for each(property in __mashProperties)
					{
						__mash.removeEventListener(property, __mashChange);
					}
					__mash.unload();
				}
				
				__mash = iMash;
				if (__mash != null) __mashSync();
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this, e);
			}
		}
		private function __setSource(iSource:ISource):void
		{
			if (__source != null)
			{
				__source.removeEventListener(Event.CHANGE, __sourceChange);
			}
			__source = iSource;
			if (__source != null)
			{
				var count:Number = __source.getValue(ClipProperty.LENGTH).number;
				if (count)
				{
					__sourceChange(null);
				}
				else if (! __source.getValue(MediaProperty.URL).empty)
				{
					__source.addEventListener(Event.CHANGE, __sourceChange);
				}
			}
		}
		private function __sourceChange(event:Event):void
		{
			try
			{
				var mash_tag:XML = null;
				if ((__source != null) && __source.length)
				{
					for (var i = 0; i < __source.length; i++)
					{
						mash_tag = __source.getItemAt(i) as XML;
						if (mash_tag.name() == ClipProperty.MASH)
						{
							break;
						}
					}
				}
				if (mash_tag != null)
				{
					__setMash(RunClass.Mash['fromXML'](mash_tag));
					if (__source != null)
					{
						__source.removeEventListener(Event.CHANGE, __sourceChange);
					}
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__sourceChange', e);
			}
		}
		private function __userSetTime(time:Time, dont_delay:Boolean = false):void
		{
			//RunClass.MovieMasher['msg'](this + '.__userSetTime ' + time + ' ' + __seekingTime);
			time.min(__mashLengthTime);
			if (! time.isEqualToTime(__seekingTime))
			{
				__seekingTime = time.copyTime();
				__dispatchLocationEvent();
				if (! __paused) __seekTimed(null);
				else if (__seekTimer == null)
				{
					__seekTimer = new Timer(1);
					__seekTimer.addEventListener(TimerEvent.TIMER, __seekTimed);
					__seekTimer.start();				
				}
			}
		}
		private static var __mashProperties:Array = ['revert', MashProperty.LENGTH_TIME, MashProperty.TIME, MashProperty.STALLING, PlayerProperty.DIRTY, ClipProperty.VOLUME, ClipProperty.TRACK, MashProperty.TRACKS, MediaProperty.LABEL];
		private var __dragIndicator:Sprite;
		private var __mash:IMash = null;
		private var __mashLength:Number = 0;
		private var __paused:Boolean = true;
		private var __seekedTime:Time;
		private var __seekingTime:Time;
		private var __mashLengthTime:Time;
		private var __mashTime:Time;
		private var __seekTimer:Timer;
		private var __source:ISource;
		private var __fps:int = 0;
		private var __mashXML:XML;
		private var __finalized:Boolean = false;
	}	
}