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
	import fl.video.*;
	import flash.media.*;
	import fl.video.*;
	import flash.display.*;
	import flash.events.*;
	import flash.media.*;
	import flash.net.*;
	import flash.utils.*;


/**
* Implimentation class represents a player control
*/
	public class PlayerFLV extends Control implements IPlayer
	{
		public function PlayerFLV()
		{
			//_defaults.id = ReservedID.PLAYER;
			_defaults.volume = '75';
			_defaults.source = ClipProperty.MASH;
			_defaults.fps = '10';
			_defaults.buffertime = '10';
			_defaults.minbuffertime = '1';
			_defaults.unbuffertime = '2';
			_defaults.volume = '75';
			_defaults.dirty = '0';
			_defaults.hisize = '2';
			_defaults.hicolor = 'FFFFFF';
			_defaults.hialpha = '50';
			_defaults[MashProperty.STALLING] = '0';
			_allowFlexibility = true;
		}	
		override public function finalize():void
		{
			super.finalize();
	
		
		}
		override public function getValue(property:String):Value
		{
			var value:Value;
			switch(property)
			{
				case 'audio':
					value = new Value(__audio ? 1 : 0);
					break;
				case 'url':
					value = new Value(RunClass.ParseUtility['brackets'](__url, null, true));
					break;
				case MashProperty.POSITION:
					value = new Value(RunClass.StringUtility['timeString'](__seekingTime, getValue('fps').number, __duration));
					break;
				case PlayerProperty.LOCATION:
					value = new Value(__seekingTime);
					break;
				case PlayerProperty.COMPLETED:
					value = new Value((__duration > 0) ? ((__seekingTime * 100.0) / __duration) : 0);
					//RunClass.MovieMasher['msg'](this + '.getValue ' + property + ' ' + value.string + ' ' + __seekingTime + ' of ' + __duration);
					break;
				case MediaProperty.DURATION:
					value = new Value(RunClass.StringUtility['timeString'](__duration, getValue('fps').number, __duration));
					break;
				case ClipProperty.LENGTH:
					value = new Value(__duration);
					break;
				case PlayerProperty.PLAY:
					value = new Value(__paused ? 0 : 1);
					break;
				case MashProperty.STALLING:
					value = new Value(__stalled ? 1 : 0);
					break;
				case MediaProperty.LABEL:
					value = new Value(__label);
					break;
				default:
					value = super.getValue(property);
			}
			return value;
		}
		override public function resize() : void
		{
			if (_width && _height && (__videoPlayer != null))
			{
				__videoPlayer.setSize(_width, _height);
				if (! __aspectRatio)
				{
					__aspectRatio = Number(_width) / Number(_height);
				}
				
			}
		}
		override public function setValue(value:Value, property:String):Boolean
		{
			try
			{
				var dispatch:Boolean = false;
				var do_super:Boolean = false;
				switch(property)
				{
					case MediaProperty.LABEL:
						__setLabel(value.string);
						break;
					case MediaProperty.DURATION:
					case ClipProperty.LENGTH:
					
						__setDuration(value.number);
						break;
					case PlayerProperty.COMPLETED:
						//RunClass.MovieMasher['msg'](this + '.setValue ' + property + ' ' + value);
						__userSetLocation((value.number * __duration) / 100.0, ! __paused);
						break;
					case MashProperty.POSITION:
					case PlayerProperty.LOCATION:
						__userSetLocation(value.number, !__paused);
						break;
					case ClipProperty.VOLUME:
						do_super = true;
						dispatch = true;
						if (__audio)
						{
							if (__soundTransform != null)
							{
								__soundTransform.volume = value.number / 100.0;
								if (__soundChannel != null) __soundChannel.soundTransform = __soundTransform;
							}
						}
						else if (__videoPlayer != null) __videoPlayer.volume = value.number / 100;
						break;
					case PlayerProperty.PLAY:
						paused = ! value.boolean;
						break;
					case 'url':
						__setURL(value.string);
						break;
					default:
						do_super = true;
						dispatch = true;
				}
				if (do_super) super.setValue(value, property);
				if (dispatch) _dispatchEvent(property, value);
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.setValue ' + property, e);
			}

			return false;
		}
		override protected function _createChildren():void
		{
			__setDuration(super.getValue('length').number);
			__setURL(super.getValue('url').string);	
		}
		public function set paused(boolean:Boolean):void
		{
			try
			{
				if (__paused != boolean)
				{
					if (! boolean) RunClass.PlayerStage['instance'].startPlaying(this);
					__paused = boolean;
					if (__url.length) 
					{
						if (boolean) 
						{
							if (__audio) 
							{
								__destroyAudioChannel();
								
							}
							else if (__videoPlayer != null) __videoPlayer.pause();
						}
						else 
						{
							if (__audio && (__sound != null)) 
							{
								//RunClass.MovieMasher['msg'](this + '.paused ' + boolean + ' ' + __seekingTime);
								__soundChannel = __sound.play(__seekingTime * 1000, 0, __soundTransform);
								__soundChannel.addEventListener(Event.SOUND_COMPLETE, __playerComplete);
								__audioTimer = new Timer(100);
								__audioTimer.addEventListener(TimerEvent.TIMER, __audioTimed);
								__audioTimer.start();
							}
							else if (__videoPlayer != null) __videoPlayer.play();
						}
					}
					_dispatchEvent(PlayerProperty.PLAY);
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.paused ' + boolean, e);
			}
		}
		public function get paused():Boolean
		{
			return __paused;
		}
		
		override protected function _adjustVisibility():void
		{
			RunClass.PlayerStage['instance'][(_hidden ? 'de' : '') + 'registerPlayer'](this);
			if (! _hidden) __autoStart();
			else __destroyPlayer();
		}
		private function __autoStart():Boolean
		{
			var started:Boolean = false;
			try
			{
				if (__url.length) 
				{
					__makeRequest();
					if (getValue(PlayerProperty.AUTOSTART).boolean || (! __paused))
					{
						__paused = true;
						setValue(new Value(1), PlayerProperty.PLAY);
						started = true;
					}
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__autoStart ' + started, e);
			}

			return started;
		}
		private function __dispatchLocationEvent():void
		{
			if (__duration)
			{
				_dispatchEvent(PlayerProperty.LOCATION);
				_dispatchEvent(PlayerProperty.COMPLETED);
				_dispatchEvent(MashProperty.POSITION);
			}
		}
		private function __createPlayer():void
		{
			//RunClass.MovieMasher['msg'](this + '.__createPlayer ' + (__audio ? 'audio' : 'video'));
			var volume:Number = super.getValue(ClipProperty.VOLUME).number / 100;
			if (__audio)
			{
				if (__sound == null)
				{
					__sound = new Sound();
					//__sound.addEventListener(Event.COMPLETE, __playerComplete);
					__sound.addEventListener(Event.ID3, __audioPlayerData);
					__sound.addEventListener(ProgressEvent.PROGRESS, __audioProgress);
				}
				if (__soundTransform == null)
				{
					__soundTransform = new SoundTransform();
					__soundTransform.volume = volume;
				}
			}
			else
			{
				if (__videoPlayer == null)
				{
					
					__videoPlayer = new VideoPlayer();		
					__videoPlayer.bufferTime = 2;
					//__videoPlayer.autoPlay = true;

					__videoPlayer.volume = volume;
					//__videoPlayer.fullScreenTakeOver = false;
					__videoPlayer.align = VideoAlign.CENTER;
					__videoPlayer.scaleMode = VideoScaleMode.EXACT_FIT;//VideoScaleMode.MAINTAIN_ASPECT_RATIO;// VideoScaleMode.NO_SCALE;
					__videoPlayer.addEventListener(VideoEvent.READY, __videoPlayerReady);
					__videoPlayer.addEventListener(VideoProgressEvent.PROGRESS, __videoPlayerProgress);
					__videoPlayer.addEventListener(VideoEvent.STATE_CHANGE, __videoPlayerStateChange);
					__videoPlayer.addEventListener(VideoEvent.COMPLETE, __playerComplete);
					__videoPlayer.addEventListener(VideoEvent.SEEKED, __videoPlayerSeeked);
					__videoPlayer.addEventListener(VideoEvent.PLAYHEAD_UPDATE, __videoPlayerUpdate);
					__videoPlayer.addEventListener(MetadataEvent.METADATA_RECEIVED, __videoPlayerData);
					addChild(__videoPlayer);
					resize();
				}
			}
		}
		
		private function __destroyAudioChannel():void
		{
			if (__soundChannel != null)
			{
				__soundChannel.stop();
				__soundChannel.removeEventListener(Event.SOUND_COMPLETE, __playerComplete);
				__soundChannel = null;
			}
			if (__audioTimer != null)
			{
				__audioTimer.stop();
				__audioTimer.removeEventListener(TimerEvent.TIMER, __audioTimed);
				__audioTimer = null;
			}
		}
		private function __destroyPlayer():void
		{
			try
			{			
				if (__audio)
				{
					__destroyAudioChannel();
					if (__sound != null)
					{
						//__sound.removeEventListener(Event.COMPLETE, __playerComplete);
						__sound.removeEventListener(Event.ID3, __audioPlayerData);
						__sound.removeEventListener(ProgressEvent.PROGRESS, __audioProgress);
						try { __sound.close(); }
						catch(e:*) {}
						__sound = null;
					}
					if (__soundTransform != null)
					{
						__soundTransform = null;
					}
				}
				else
				{
					if (__videoPlayer != null)
					{
						__videoPlayer.removeEventListener(VideoProgressEvent.PROGRESS, __videoPlayerProgress);
						__videoPlayer.removeEventListener(VideoEvent.READY, __videoPlayerReady);
						__videoPlayer.removeEventListener(VideoEvent.STATE_CHANGE, __videoPlayerStateChange);
						__videoPlayer.removeEventListener(VideoEvent.COMPLETE, __playerComplete);
						__videoPlayer.removeEventListener(VideoEvent.SEEKED, __videoPlayerSeeked);
						__videoPlayer.removeEventListener(VideoEvent.PLAYHEAD_UPDATE, __videoPlayerUpdate);
						__videoPlayer.removeEventListener(MetadataEvent.METADATA_RECEIVED, __videoPlayerData);
						removeChild(__videoPlayer);
						try { 
							__videoPlayer.stop();
							//__videoPlayer.closeVideoPlayer(); 
						}
						catch(e:*) {}
						
						__videoPlayer = null;
					}
				}
				__setStalled(false);
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__destroyPlayer', e);
			}

		
		}
		private function __seekTimed(event:TimerEvent):void
		{
			try
			{
				
			
				if (__seekedTime != __seekingTime)
				{
					__seekedTime = __seekingTime;
				}
				else if (__seekTimer != null)
				{
					__seekTimer.removeEventListener(TimerEvent.TIMER, __seekTimed);
					__seekTimer.stop();
					__seekTimer = null;
				}
				if (__audio) 
				{
					if (__soundChannel != null)
					{
						paused = true;
						paused = false;
					}
					
				}
				else if (__videoPlayer.stateResponsive) __videoPlayer.seek(__seekedTime);
			
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this, e);
			}
		}
		private function __setAudio(boolean:Boolean):void
		{
			if (__audio != boolean)
			{
				__audio = boolean;
				if (__videoPlayer != null) __videoPlayer.visible = ! __audio;
				_dispatchEvent('audio');
			}
		}
		private function __setStalled(boolean:Boolean):void
		{
			if (__stalled != boolean)
			{
				//RunClass.MovieMasher['msg'](this + '.__setStalled ' + boolean);
				__stalled = boolean;
				_dispatchEvent(MashProperty.STALLING);
			}
		}
		private function __setLabel(s:String):void
		{
			if (__label != s)
			{
				__label = s;
				_dispatchEvent(MediaProperty.LABEL);
			}
		}
		private function __setDuration(n:Number):void
		{
			//RunClass.MovieMasher['msg'](this + '.__setDuration ' + n);
			if (__duration != n)
			{
				__duration = n;
			
				_dispatchEvent(MediaProperty.DURATION);
				_dispatchEvent(ClipProperty.LENGTH);
				_dispatchEvent(PlayerProperty.COMPLETED);
			}
		}
		private function __setLocation(n:Number):Boolean
		{
			var different:Boolean = (__location != n);
			try
			{
				if (different)
				{
					__location = n;
					__seekingTime = n;
					__dispatchLocationEvent();
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__setLocation', e);
			}
			
			return different;
		}
		private function __setURL(url_string:String):void
		{
			try
			{
				__destroyPlayer();
				__setLocation(0);
				__setLabel('');
				__setDuration(0);
				var url:URL;
				__url = url_string;
				
				if (url_string.length) url_string = RunClass.ParseUtility['brackets'](url_string, null, true);
				if (url_string.length)
				{
					url = new URL(url_string);
					url_string = url.absoluteURL;
				}
				if (url_string.length) __setAudio(url.extension.toLowerCase() == 'mp3');
				_dispatchEvent('url');
				if (url_string.length && (! _hidden))
				{
					__autoStart();
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__setURL ' + url_string, e);
			}
		}
		private function __makeRequest():void
		{
			try
			{
				var url_string:String = '';
				var url:URL;
				
				if (__url.length) url_string = RunClass.ParseUtility['brackets'](__url, null, true);
				if (url_string.length)
				{
					url = new URL(url_string);
					url_string = url.absoluteURL;
				}
				if (url_string.length) 
				{
					__setStalled(true);
					__createPlayer();
					if (__audio && (__sound != null)) __sound.load(new URLRequest(url_string));
					else if (__videoPlayer != null) __videoPlayer.play(url_string);	
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__makeRequest', e);
			}
		}
		private function __userSetLocation(n:Number, dont_delay:Boolean = false):void
		{
			if (__duration)
			{
				n = Math.max(0, Math.min(n, __duration));
				if (__seekingTime != n)
				{
					//RunClass.MovieMasher['msg'](this + '.__userSetLocation ' + n);
				
					__seekingTime = n;
					__location = n;
					__dispatchLocationEvent();
					if (dont_delay)
					{
						__seekTimed(null);
					}
					else if (__seekTimer == null)
					{
						__seekTimer = new Timer(20);
						__seekTimer.addEventListener(TimerEvent.TIMER, __seekTimed);
						__seekTimer.start();				
					}
				}
			}
		}
		private function __playerComplete(event:Event):void 
		{
			//RunClass.MovieMasher['msg'](this + '.__playerComplete ' + event);
			setValue(new Value(0), PlayerProperty.PLAY);
		}
		private function __videoPlayerData(event:MetadataEvent):void
		{

			if (__videoPlayer.metadata != null)
			{
				if (__videoPlayer.metadata.duration != null)
				{
					__setDuration(__videoPlayer.metadata.duration);
				}
				var label:String;
				label = __videoPlayer.metadata.title;
				if ((label == null) || (! label.length)) 
				{
					if (__videoPlayer.metadata.tags is Object)
					{
						label = __videoPlayer.metadata.tags['©nam'];
					}
				}
				
				
				if ((label != null) && label.length)
				{
					__setLabel(label);
				}
			}
		}
		/* useful for inspecting meta data objects from players
		private function __objectString(object:Object):String
		{
			var a:Array = new Array;
			var s:String;
			for (var k:String in object)
			{
				if (object[k] is String) s = object[k];
				else if (object[k] is Number) s = String(object[k]);
				else if (object[k] is Object) s = __objectString(object[k]);
				a.push(k + ': ' + s);
			}
			if (a.length) s = a.join(', ');
			else s = String(object);
			return '{' + s + '}';
		}
		*/
			
		private function __audioPlayerData(event:Event):void
		{
			
			if (__sound.id3 != null)
			{
				if (__sound.id3.TIME != null)
				{
					__setDuration(__sound.id3.TIME);
				}
				if (__sound.id3.TITLE != null)
				{
					__setLabel(__sound.id3.TITLE);
				}
				else if (__sound.id3.TIT2 != null)
				{
					__setLabel(__sound.id3.TIT2);
				}
			}
		}
		private function __audioProgress(event:ProgressEvent):void 
		{
		
		}
		private function __audioTimed(event:TimerEvent):void
		{
			if (__sound != null)
			{
				__setDuration(__sound.length / 1000);
			}
			if (__soundChannel != null)
			{
				if (__setLocation(__soundChannel.position / 1000))
				{
					__setStalled(false);
				}
			}
		}
		private function __videoPlayerProgress(event:VideoProgressEvent):void 
		{
			//RunClass.MovieMasher['msg'](this + '.__videoPlayerProgress ' + (100 * (event.bytesLoaded/event.bytesTotal)) + '%');
		}
		private function __videoPlayerReady(event:VideoEvent):void 
		{
			//RunClass.MovieMasher['msg'](this + '.__videoPlayerReady ' + event.state + ' ' + __paused);
			if (! __paused)
			{
				__videoPlayer.play();
			}
		}
		private function __videoPlayerSeeked(event:VideoEvent):void 
		{
			//RunClass.MovieMasher['msg'](this + '.__videoPlayerSeeked ' + event.state);
		}
		private function __videoPlayerStateChange(event:VideoEvent):void 
		{
			
			//RunClass.MovieMasher['msg'](this + '.__videoPlayerStateChange ' + event.state + ' ' + __stalled);
			/*
			VideoState.DISCONNECTED
			VideoState.CONNECTION_ERROR
			VideoState.REWINDING
			*/
			switch (event.state)
			{
				case VideoState.BUFFERING:
				case VideoState.LOADING:
				case VideoState.SEEKING:
					__setStalled(true);
					break;
				case VideoState.STOPPED:
				case VideoState.PAUSED:
				case VideoState.STOPPED:
				case VideoState.PLAYING:
					__setStalled(false);
					break;
			}
		}
		private function __videoPlayerUpdate(event:VideoEvent):void
		{
			//RunClass.MovieMasher['msg'](this + '.__videoPlayerUpdate ' + __videoPlayer.playheadTime);
			__setLocation(__videoPlayer.playheadTime);
			
		}
		private var __sound:Sound;
		
		private var __soundChannel:SoundChannel;
		private var __soundTransform:SoundTransform;
		private var __audio:Boolean;
		private var __url:String = '';
		private var __label:String = '';
		private var __paused:Boolean = true;
		private var __stalled:Boolean = false;
		private var __seekedTime:Number = 0;
		private var __seekingTime:Number = 0;
		private var __location:Number = 0;
		private var __seekTimer:Timer;
		private var __duration:Number = 0;
		private var __audioTimer:Timer;
		private var __aspectRatio:Number;
		private var __videoPlayer:VideoPlayer;
		private static var __needsNCManager:NCManager;
		
	}	
}