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
package com.moviemasher.handler
{
	import flash.events.*;
	import flash.net.*;
	import flash.media.*;
	import flash.display.*;
	import flash.utils.*;
	
	import com.moviemasher.type.*;
	import com.moviemasher.constant.*;
	import com.moviemasher.interfaces.*;
	import com.moviemasher.type.*;
	import com.moviemasher.constant.*;

/**
* Abstract base class for audio/visual playback
*
* @see IHandler
* @see AssetFetcher
* @see AVAudio
*/
	public class Handler extends EventDispatcher implements IHandler
	{
		public function Handler(url:String)
		{ 
			_url = new RunClass.URL(url);
			//buffer(null);
		}
		public function getAudioDatum(position:uint, length:int, samples_per_frame:int):Vector.<AudioData>
		{
			return null;
		}
		public function buffer(range:Object):void
		{
		}
		public function buffered(range:Object):Boolean
		{
			// default behavior bases buffered state on bytesLoaded/bytesTotal
			var is_buffered:Boolean = true;
			try
			{
				is_buffered = (bytesLoaded / bytesTotal) >= Math.min(1, (__loopedTime(range.end) / duration));
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.buffered ', e);
			}
			return is_buffered;
		}
		override public function toString():String
		{
			var s:String = '[' + super.toString();
			s += ' ' + _url.file;
			s += ']';
			return s;
		}
		public function unload():void
		{ 
			_active = false;
		}
		public function get metrics():Size
		{ 
			return _metrics; 
		}
		public function get displayObject():DisplayObjectContainer
		{ 
			return null; 
		}
		public function set visual(iBoolean:Boolean):void
		{
			_visual = iBoolean;
		}
		public function get active():Boolean
		{
			return _active;
		}
		public function set active(iBoolean:Boolean):void
		{
			_active = iBoolean;
		}
		private function __loopedTime(n:Number):Number
		{
			_looped = Math.floor(n / _duration);
			if (_looped)
			{
				n = n % _duration;
			}
			return n;
		}
		public function set loops(iNumber:Number):void
		{
			_loops = Math.max(1, iNumber);
		}
		public function set duration(iNumber:Number):void
		{
			//RunClass.MovieMasher['msg'](this + '.duration ' + iNumber);
			_duration = iNumber;
		}
		public function get duration():Number
		{
			return _duration;
		}
		public function get bytesLoaded():Number
		{ return 0; }
		public function get bytesTotal():Number
		{ return -1; }
		protected var _active:Boolean = true;
		protected var _duration:Number = 0;
		protected var _looped:Number = 0;
		protected var _loops:Number = 1;
		protected var _metrics:Size;
		protected var _url:Object;
		protected var _visual:Boolean = false;		
	}
}