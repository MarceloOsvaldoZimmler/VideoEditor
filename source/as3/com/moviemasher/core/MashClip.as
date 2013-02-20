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
* Implementation class represents an instance of a {@link IMedia} item, usually within a mash.
* 
* @see IClip
*/
	public class MashClip extends Clip implements IClipMash
	{
		public function MashClip(type:String, media:IMedia, mash:IMash = null)
		{
			//RunClass.MovieMasher['msg']('MashClip');
			
			super(type, media, mash);
			
		}
		override protected function _parseTag():void
		{
			__mash = RunClass.Mash['fromXML'](media.tag);
			super._parseTag();
			var time:Time;
			
			// we ignore the clip tag's length in favor of mash's, even if it's not loaded yet
			_lengthFrame = 0;
			_mediaSeconds = 0;
			time = __mash.lengthTime;
			
			if (time != null)
			{
				_mediaSeconds = time.seconds;
			}
			_calculateLength();
			if (lengthFrame <= 0)
			{
				_lengthFrame = 0;
			 	__mash.addEventListener(EventType.BUFFER, __bufferMash);
			}
			//RunClass.MovieMasher['msg'](this + '._parseTag lengthFrame: ' + lengthFrame + '__mash.lengthTime: ' + __mash.lengthTime);
		}
		override public function getValue(property:String):Value
		{
			var value:Value = null;
			switch(property)
			{
				case 'avmash':
					value = new Value(__mash);
					break;
				case 'label':
					value = __mash.getValue(property);
				//	RunClass.MovieMasher['msg'](this + '.getValue ' + property + ' = ' + value.string);
					break;
				default:
					value = super.getValue(property);
			}
			return value;
		}
		private function __bufferMash(event:Event):void
		{
			//RunClass.MovieMasher['msg'](this + '.__bufferMash')
			var time:Time;
			time = __mash.lengthTime;
			if (time != null)
			{
				_mediaSeconds = time.seconds;
				if (_mediaSeconds)
				{
					if ((time.frame - (_endTrimFrame + _startTrimFrame)) <= 0)
					{
						// mash time must have changed since we trimmed, so remove trim
						_endTrimFrame = _startTrimFrame = 0;
					}
				}
				_calculateLength();
				if (lengthFrame)
				{
					__mash.removeEventListener(EventType.BUFFER, __bufferMash);
					_mash.setValue(new Value(1), 'dirty');
					//RunClass.MovieMasher['msg'](this + '.__bufferMash _mediaSeconds ' + _mediaSeconds + ' _lengthFrame ' + _lengthFrame);
					dispatchEvent(new Event(EventType.BUFFER));
				}
			}
		}
		private var __mash:IMash;
	}
}
