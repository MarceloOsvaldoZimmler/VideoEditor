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

	import com.moviemasher.type.*;
	import com.moviemasher.constant.*;
	import com.moviemasher.events.*;
	import com.moviemasher.interfaces.*;
	import com.moviemasher.type.*;
	import com.moviemasher.constant.*;
	import flash.display.*;
	import flash.events.*;
	import flash.system.*;
/**
* Implementation class for mash module
*
* @see IModule
* @see IClip
*/
	public class AVMash extends Module
	{
		public function AVMash()
		{
			
		}
		
		override public function buffered(range:TimeRange, mute:Boolean):Boolean
		{
			var is_buffered:Boolean = super.buffered(range, mute);
			if (is_buffered)
			{
				if (__mash == null)
				{
					_initializeSize();
				}
				if (__mash != null)
				{
					is_buffered = __mash.buffered(range, mute);
					//if (! is_buffered) RunClass.MovieMasher['msg'](this + '.buffered ! ' + range); 
				}
				else is_buffered = false;
			}
			//RunClass.MovieMasher['msg'](this + '.buffered mute = ' + mute + ' ' + is_buffered); 
			return is_buffered;
		}
		
		override public function buffer(range:TimeRange, mute:Boolean):void
		{	
			//RunClass.MovieMasher['msg'](this + '.buffer mute = ' + mute + ' ' + range); 
			if (__mash == null)
			{
				_initializeSize();
			}
			if (__mash != null)
			{
				__mash.buffer(range, mute);
			}
			else RunClass.MovieMasher['msg'](this + '.buffer with no mash');
		}
		override public function getAudioDatum(position:uint, length:int, samples_per_frame:int):Vector.<AudioData>
		{
			var vector:Vector.<AudioData> = null;
			if (__mash != null)
			{
				vector = __mash.getAudioDatum(position, length, samples_per_frame);
			}
			return vector;
		}
		override public function unload():void
		{
			if (__mash != null)
			{
				__mash.removeEventListener(EventType.BUFFER, _mashBuffered);
				removeChild(__mash.displayObject);
				__mash.unload();
				__mash = null;
			}
			super.unload();
		}
		override public function unbuffer(range:TimeRange):void
		{ 
			if (__mash != null)
			{
				__mash.unbuffer(range);
			}
		}
		override protected function _changedSize():void
		{
			if (__mash != null)
			{
				__mash.metrics = _size;
			}
		}
		override protected function _initializeSize():void
		{
			//RunClass.MovieMasher['msg'](this + '._initializeSize');
					
			var m:IMedia = media;
			if (m != null)
			{
				var media_tag:XML = m.tag;
				if (media_tag != null)
				{
					__mash = _getClipPropertyObject('avmash') as IMash;
					//RunClass.Mash['fromXML'](media_tag);
					if (__mash != null)
					{
						var object:Object = _getClipPropertyObject(ClipProperty.MASH);
							
						if ((object != null) && (object is IMash))
						{
							__mash.setValue(new Value(1), 'dontreposition');
							/*
							var my_mash:IValued = object as IValued;
							__mash.setValue(my_mash.getValue(MediaProperty.FPS), MediaProperty.FPS);
							__mash.setValue(my_mash.getValue('buffertime'), 'buffertime');
							__mash.setValue(my_mash.getValue('minbuffertime'), 'minbuffertime');
							__mash.setValue(my_mash.getValue('unbuffertime'), 'unbuffertime');
							__mash.setValue(new Value(1), 'autostop');
							__mash.setValue(new Value(1), 'dontbufferstart');
							*/
							
							addChild(__mash.displayObject);
							if (_size != null) __mash.metrics = _size;
						}
						__mash.addEventListener(EventType.BUFFER, _mashBuffered);				
					}
				}
				else  RunClass.MovieMasher['msg'](this + '._initializeSize no media tag');
			}
			else RunClass.MovieMasher['msg'](this + '._initializeSize no media');
		}
		
		override public function set time(object:Time):void
		{
			super.time = object;
			if (__mash != null) 
			{
				//RunClass.MovieMasher['msg'](this + '.time ' + _time + ' ' + __mash.buffered(object.timeRange, true));
				/*
				var went:Boolean = __mash.goTime(_time);
				if (! went) RunClass.MovieMasher['msg'](this + '.time ' + _time + ' UNBUFFERED!'); 
				*/
				__mash.time = _time;		
			}		
		}
		override public function get displayObject():DisplayObjectContainer
		{
			return this;
		}

		protected function _mashBuffered(event:Event):void
		{
			//RunClass.MovieMasher['msg'](this + '._mashBuffered');
			dispatchEvent(new Event(EventType.BUFFER));
		}
		
		private var __mash:IMash;
		
	}
}