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
	import com.moviemasher.type.*;
	import com.moviemasher.constant.*;
	import com.moviemasher.interfaces.*;
	import com.moviemasher.events.*;
	import com.moviemasher.type.*;
	import com.moviemasher.constant.*;
	
/**
* Class handles playback of MP3 audio
*
* @see IHandler
* @see AssetFetcher
* @see AVAudio
*/

	public class MP3Handler extends Handler
	{
		public function MP3Handler(url:String)
		{
			super(url);
		}
		override public function getAudioDatum(position:uint, length:int, samples_per_frame:int):Vector.<AudioData>
		{
			var vector:Vector.<AudioData> = null;
			if (_sound != null)
			{
				vector = new Vector.<AudioData>(1, true);
				var audio_data:AudioData = new AudioData();
				vector[0] = audio_data;
				var still_needed:int;
				audio_data.byteArray.position = 0;
				//RunClass.MovieMasher['msg'](this + '.getAudioDatum asking for ' + length + ' while length = ' +  audio_data.byteArray.length);
				if (position > (_duration * Sampling.SAMPLES_PER_SECOND))
				{
					position = position % (_duration * Sampling.SAMPLES_PER_SECOND);
				}
				_sound.extract(audio_data.byteArray, length, position);
				still_needed = length - int(Math.round(Number(audio_data.byteArray.length) / 8.0));
				
				if (still_needed > 0)
				{
					_sound.extract(audio_data.byteArray, still_needed, 0);
					//still_needed = length - int(Math.round(Number(audio_data.byteArray.length) / 8.0));
				
				}
			}
			return vector;
		}
		override public function buffer(range:Object):void
		{
			try
			{
				if (range != null) __bufferTime = range.end;
				if (_sound == null)
				{
					// called just once
					_sound = new Sound();
					_sound.load(new URLRequest(_url.absoluteURL), new SoundLoaderContext(10, true));
					_sound.addEventListener(Event.COMPLETE, __soundComplete);
				}
				_sound.addEventListener(ProgressEvent.PROGRESS, __soundProgress);
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this, e);
			}
		}

		
		override public function unload():void
		{ 
			super.unload();
			if (_sound != null)
			{
				_sound.removeEventListener(Event.COMPLETE, __soundComplete);	
				_sound.removeEventListener(ProgressEvent.PROGRESS, __soundProgress);	
				_sound = null;
			}
		}
		override public function get duration():Number
		{
			return _duration * _loops;
		}

		override public function get bytesLoaded():Number
		{
			return (((_sound == null) || (isNaN(_sound.bytesLoaded))) ? 0 : _sound.bytesLoaded);
		}
		override public function get bytesTotal():Number
		{
			return (((_sound == null) || (isNaN(_sound.bytesTotal)) || (! _sound.bytesTotal)) ? -1 : _sound.bytesTotal);
		}
		private function __soundProgress(event:ProgressEvent):void
		{
			if ((bytesLoaded / bytesTotal) >= (__bufferTime / duration))
			{
				_sound.removeEventListener(ProgressEvent.PROGRESS, __soundProgress);	
				dispatchEvent(new Event(EventType.BUFFER));
			}
		}
		private function __soundComplete(event:Event):void
		{
			try
			{
				dispatchEvent(new Event(EventType.BUFFER));
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__soundComplete caught ' + e);
			}
		}
		private var _sound:Sound;
		private var __bufferTime:Number = 0;
	}
}