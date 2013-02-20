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
package com.moviemasher.module
{
	import com.moviemasher.events.*;
	import com.moviemasher.interfaces.*;
	import com.moviemasher.constant.*;
	import com.moviemasher.type.*;
	import com.moviemasher.constant.*;
	import flash.display.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.utils.*;
/**
* Abstract base class for all modules. 
*
* @see Clip
* @see Mash
*/
	public class Module extends Sprite implements IModule
	{
		public function Module()
		{
			_defaults = new Object();
			_defaults.fade = '';	
			_defaults.lengthframe = RunClass.TimeUtility['fps'] * 10; // used in case clip and media both return nothing
		}
		override public function toString():String
		{
			var s:String = '[Module';
			
			if (__clip != null)
			{
				s += ' ' + String(__clip);
			}
			s += ']';
			return s;
		}
		public function unbuffer(range:TimeRange):void
		{ }
		public function unload():void
		{
			
			// I will no longer exist after this
			
			var i:int;
			for (i = numChildren - 1; i > -1; i--)
			{
				removeChildAt(i);
			}

			if (__clip != null) 
			{
				__clip.removeEventListener(Event.CHANGE, _clipDidChange);
				for (var key:String in _defaults)
				{
					__clip.removeEventListener(key, _clipPropertyDidChange);
				}
			}
			__media = null;
			__clip = null;
		}
		public function get backColor():String
		{
			return null;
		}
		public function get displayObject():DisplayObjectContainer
		{
			return null;
		}
		public function getAudioDatum(position:uint, length:int, samples_per_frame:int):Vector.<AudioData>
		{
			return null;
		}
		public function set time(object:Time):void
		{
			if (! object.isEqualToTime(_time))
			{
				_time = object.copyTime();
			}
		}
		public function get media():IMedia
		{
			if ((__media == null) && (__clip != null)) __media = __clip.media;
			return __media;
		}
		public function set clip(m:IClip):void
		{
			__clip = m;
			_initialize();
		}
		final public function set metrics(iMetrics:Size):void
		{
			try
			{
				if ((iMetrics != null) && (! iMetrics.isEmpty()) && (! iMetrics.equals(_size)))
				{
				
					var wasnt_set:Boolean = (_size == null);
					if (wasnt_set || (! iMetrics.equals(_size)))
					{
						_size = iMetrics;
						if (wasnt_set) _initializeSize();
						__changedSize();
					}
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + 'MODULE.metrics ' + iMetrics, e);
			}
		}
		final public function get metrics():Size
		{
			return _size;
		}
		public function buffer(range:TimeRange, mute:Boolean):void
		{
			_mute = mute;
		}
		public function buffered(range:TimeRange, mute:Boolean):Boolean
		{
			_mute = mute;
			return true;
		}
		override public function set scaleX(n:Number):void
		{
			if (_size == null) _size = new Size(1, 1);
			_size.width = n;
		}
		override public function set scaleY(n:Number):void
		{
			if (_size == null) _size = new Size(1, 1);
			_size.height = n;
		}
		override public function get width():Number
		{ return 1; }
		override public function get height():Number
		{ return 1; }	
		private function __changedSize():void
		{
			_changedSize();
		}
		protected function _changedSize():void
		{}
		protected function _clipDidChange(event:Event):void
		{}
		protected function _clipPropertyDidChange(event:ChangeEvent):void
		{}
		protected function _initialize():void
		{
			if (__clip != null) 
			{
				__clip.addEventListener(Event.CHANGE, _clipDidChange);
				for (var key:String in _defaults)
				{
					__clip.addEventListener(key, _clipPropertyDidChange);
				}
			}
		}
		protected function _initializeSize():void
		{}
		protected function _clipCompleted():Number // returns float 0 to 1
		{
			var length_time:Time = __clip.lengthTime;
			var time:Time = _time.copyTime();
			time.synchronize(length_time);
			return time.frame / length_time.frame;
		}
		protected function _getFade():Number // returns float 0 to 100
		{
			var per:Number = 100.0;
			
			var fade:String = _getClipProperty('fade');
			switch (fade)
			{
				case '':
				case Fades.ON: 
					break;
				case Fades.OFF:
					per = 0.0;
					break;
				default:
					per = RunClass.PlotUtility['value'](RunClass.PlotUtility['string2Plot'](fade), _clipCompleted() * 100.0);
				
			}
			return per;
		}
		protected function _getClipPropertyObject(property:String):Object
		{
			
			// get from clip's current value
			var object:Object = null;
			try
			{
				if (__clip != null) object = __clip.getValue(property).object;
				
				if (object == null)
				{
					// get from media's current value
					object = _getMediaPropertyObject(property);
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '._getClipPropertyObject ' + property, e);
			}

			return object;
		}
		protected function _getClipProperty(property:String):String
		{
			
			// get from clip's current value
			var s:String = '';
			try
			{
				if (__clip != null) s = __clip.getValue(property).string;
				
				if (! s.length)
				{
					// get from media's current value
					s = _getMediaProperty(property);
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '._getClipProperty ' + property, e);
			}
			return s;
		}
		protected function _getMediaProperty(property:String):String
		{
			// get from media's value
			var s:String = '';
			try
			{
				if (media != null) 
				{
					s = __media.getValue(property).string;
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '._getMediaProperty MEDIA ' + property + ' ' + __media + ' ' + s, e);
			}
			try
			{
				if (! s.length)
				{
					// get from my own defaults
					if (_defaults[property] != null)
					{
						s = _defaults[property];
					}
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '._getMediaProperty ' + property, e);
			}
			return s;
		}
		protected function _getMediaPropertyObject(property:String):Object
		{
			var object:Object = null;
			try
			{
				// get from media's value
				if (media != null) object = __media.getValue(property).object;
				if ((object == null) && (_defaults[property] != null))
				{
					// get from my own defaults
					//RunClass.MovieMasher['msg'](this + '._getMediaPropertyObject ' + property + ' defaults');
					object = _defaults[property];
					//RunClass.MovieMasher['msg'](this + '._getMediaPropertyObject ' + property + ' defaults property = ' +  _defaults[property]);
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '._getMediaPropertyObject ' + property + ' defaults = ' + _defaults, e);
			}
			return object;
		}
		protected function _getClipPropertyNumber(property:String):Number
		{
			var n:Number = 0;
			var s:String = _getClipProperty(property);
			if ((s != null) && s.length)
			{
				n = Number(s);
				if (isNaN(n)) n = 0;
			}
			return n;
		}
		protected function _getMediaPropertyNumber(property:String):Number
		{
			var n:Number = 0;
			var s:String = _getMediaProperty(property);
			if (s.length)
			{
				n = Number(s);
				if (isNaN(n)) n = 0;
			}
			return n;
		}
		protected function _getQuantize():Number
		{
			var quantize:Number = 0;
			if ((__clip != null) && (__clip.mash != null)) quantize = __clip.mash.getValue(MashProperty.QUANTIZE).number;
			return quantize;
		}
		private var __clip:IClip = null;
		private var __media:IMedia = null;
		protected var _defaults:Object; 
		protected var _frame:Number;
		protected var _mute:Boolean;
		protected var _size:Size;
		protected var _time:Time;
	}
}