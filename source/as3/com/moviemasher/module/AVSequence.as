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
	import com.moviemasher.interfaces.*;
	import com.moviemasher.type.*;
	import com.moviemasher.constant.*;
	import com.moviemasher.utils.*;
	import flash.display.*;
	import flash.events.*;
	import flash.utils.*;

/**
* Implementation class for image sequence based video module
*
* @see IModule
* @see IClip
*/
	public class AVSequence extends AVAudio
	{
		public function AVSequence()
		{
			__displayObjects = new Dictionary();
			__displayObjectContainer = new Sprite();
			__requestedFetchers = new Dictionary();
			__loaders = new Dictionary();
			
			addChild(__displayObjectContainer);
		}
		override public function buffer(range:TimeRange, mute:Boolean):void
		{
			//RunClass.MovieMasher['msg'](this + '.buffer ' + range);
			super.buffer(range, mute);
			try
			{
				var url:String;
				var loader:IAssetFetcher;
				var attempted:Dictionary = new Dictionary();
				
				var urls:Vector.<String> = __urlsForFrames(range);
				for each (url in urls)
				{
				
					if (__displayObjects[url] == null)
					{
						if (__requestedFetchers[url] == null)
						{
							loader = RunClass.MovieMasher['assetFetcher'](url);
							if (loader != null)
							{
								if (loader.state == EventType.LOADED)
								{
									__displayLoadedURL(loader, url);
																
								}
								else
								{
							//	RunClass.MovieMasher['msg'](range + ' ' + url);
				
									__requestedFetchers[url] = loader;
									__loaders[loader] = url;
									loader.addEventListener(Event.COMPLETE, __graphicLoaded, false, 0, true);
								}
								loader.retain();
							}
						}
						if ((__requestedFetchers[url] != null) && (attempted[url] == null))
						{
							attempted[url] = true;
							loader = __requestedFetchers[url];
							__displayObjects[url] = loader.displayObject(url);	
						}
					}
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.buffer ' + range, e);
			}
		}
		override public function buffered(range:TimeRange, mute:Boolean):Boolean
		{
			//RunClass.MovieMasher['msg'](this + '.buffered ' + range);
			var is_buffered:Boolean = super.buffered(range, mute);
			try
			{
				if (is_buffered)
				{
					var url:String;
				
					var urls:Vector.<String> = __urlsForFrames(range);
					for each (url in urls)
					{					
						if (__displayObjects[url] == null)
						{
							//RunClass.MovieMasher['msg'](this + '.buffered ' + range + ' ' + url);
							is_buffered = false;
							
							break;
						}
					}
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.buffered', e);
			}
			return is_buffered;
		}
		override protected function _initialize():void
		{
			var fps:uint = _getClipPropertyNumber(MediaProperty.FPS);
			var duration:Number;
			var url,pattern:String;
			url = _getClipProperty(MediaProperty.URL);
			pattern = _getClipProperty(TextProperty.PATTERN);
			duration = _getMediaPropertyNumber(MediaProperty.DURATION)
			__mediaLengthTime = new Time(Math.floor(duration * Number(fps)), fps);
			__increment = _getClipPropertyNumber('increment');
			__begin = _getClipPropertyNumber('begin');
			__zeroPadding = _getClipPropertyNumber('zeropadding');
			if (! __zeroPadding) __zeroPadding = String(String(__begin + (__increment * Math.floor(fps * duration)))).length;
			
			__urlPattern = url + pattern;
			__urlLookup = new Vector.<String>(__mediaLengthTime.frame, true); 
		}
		override public function unload():void
		{
			if ((__displayObject != null) && __displayObjectContainer.contains(__displayObject))
			{
				__displayObjectContainer.removeChild(__displayObject);
				__displayObject = null;
			}
			__unbuffer(__requestedFetchers);
			super.unload();
		}
		override public function unbuffer(range:TimeRange):void
		{
			try
			{
				var keys:Dictionary = new Dictionary();
				var loader:IAssetFetcher;
				var url:String;
				
				var urls:Vector.<String> = __urlsForFrames(range);
				/*
				RunClass.MovieMasher['msg'](this + '.unbuffer ' + range + ' ' + urls);
				for each (url in urls)
				{
					keys[url] = true;
				}
				*/
				var delete_keys:Dictionary = new Dictionary();
				
				for (url in __requestedFetchers)
				{
					if (urls.indexOf(url) != -1) delete_keys[url] = true;
				}
				__unbuffer(delete_keys);
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.unbuffer', e);
			}
			super.unbuffer(range);
		}
		override public function set time(object:Time):void
		{
			//RunClass.MovieMasher['msg'](this + '.time ' + object + ' ' + object.timeRange);
			super.time = object;
						
			var url:String;
			var display_object:DisplayObject = null;
			var play_frames:Vector.<String>;

			try
			{
				play_frames = __urlsForFrames(_time.timeRange);
				if (play_frames.length)
				{
					url = play_frames[0];
					if ((url != null) && url.length)
					{
						display_object = __displayObjects[url];
					}
					//else RunClass.MovieMasher['msg'](this + '.time AVSequence no url in ' + play_frames);
					if (__displayObject != display_object)
					{
						if ((__displayObject != null) && __displayObjectContainer.contains(__displayObject))
						{
							__displayObjectContainer.removeChild(__displayObject);
						}
						__displayObject = display_object;
						if (__displayObject != null)
						{
							__displayObjectContainer.addChildAt(__displayObject, 0);
						}
						//else RunClass.MovieMasher['msg'](this + '.time AVSequence no display object for ' + url);
					}
					//else RunClass.MovieMasher['msg'](this + '.time AVSequence no change in display object');
					if (__displayObject != null) __sizeDisplay();
				}
				//else RunClass.MovieMasher['msg'](this + '.time AVSequence no urls for frame ' + _time.timeRange);
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.time AVSequence', e);
			}
		
		}	
		override public function get displayObject():DisplayObjectContainer
		{
			return this;
		}
	
		private function __graphicLoaded(event:Event):void
		{
			//RunClass.MovieMasher['msg'](this + '.__graphicLoaded');
			if (__graphicTimer == null)
			{
				__graphicTimer = new Timer(100);
				__graphicTimer.addEventListener(TimerEvent.TIMER, __graphicTimed);
				__graphicTimer.start();
				
				__assetFetchers = new Array();
			}
			event.target.removeEventListener(Event.COMPLETE, __graphicLoaded);
		
			__assetFetchers.push(event.target);
			__graphicTimed(event);
		}
		private function __displayLoadedURL(loader:IAssetFetcher, url:String):Boolean
		{
			var ok:Boolean = false;
			var display:DisplayObject;
								
			display = loader.displayObject(url);	
			ok = ((display != null) && display.width && display.height)
			if (ok)
			{
				__displayObjects[url] = display;		
			}
			return ok;
		}
		private function __graphicTimed(event:Event):void
		{
			try
			{
				if (__assetFetchers.length)
				{
					var i,z:int;
					var url:String;
					z = __assetFetchers.length;
					var loader:IAssetFetcher;
					var display:DisplayObject;
					var stop_time:Number;
					var delete_indices:Array = new Array();
					stop_time = (new Date()).getTime() + 50; // do this for 1/20 of a second max
					
					for (i = 0; ((i < z) && (stop_time > (new Date()).getTime())); i++)
					{
						loader = __assetFetchers[i];
						if (loader.state == EventType.LOADED)
						{
							url = __loaders[loader];
							if (url != null)
							{
								if (__displayLoadedURL(loader, url))
								{
									delete_indices.push(i);
								}
							}
						}
					}
					z = delete_indices.length;
					for (i = z - 1; i > -1; i--)
					{
						__assetFetchers.splice(delete_indices[i], 1);
					}				
				}
				if (! __assetFetchers.length)
				{
					//RunClass.MovieMasher['msg'](this + '.__graphicTimed done');
					if (__graphicTimer != null)
					{
						__graphicTimer.removeEventListener(TimerEvent.TIMER, __graphicTimed);
						__graphicTimer.stop();
						__graphicTimer = null;
					}
					__assetFetchers = null;
				}
				dispatchEvent(new Event(EventType.BUFFER));
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__graphicTimed', e);
			}
		}
		private function __unbuffer(delete_keys:Dictionary):void
		{
			var url:String;
			var loader:IAssetFetcher;
					
			for (url in delete_keys)
			{
				
				if (__requestedFetchers[url] != null) 
				{
					loader = __requestedFetchers[url];
					loader.releaseDisplay(__displayObjects[url]);
					delete __loaders[__loaders[loader]];
					delete __loaders[loader];
					delete __requestedFetchers[url];
				}
				if (__displayObjects[url] != null)
				{
					delete(__displayObjects[url]);
				}	
			}
		}
		private function __sizeDisplay():void
		{
			_sizeContainedDisplay(__displayObject, __displayObjectContainer);
		}
		private function __urlForFrame(frame:uint):String
		{
			var s:String = String((Math.min(frame, __mediaLengthTime.frame) * __increment) + __begin);
			if (__zeroPadding) s = RunClass.StringUtility['strPad'](s, __zeroPadding, '0');
			return RunClass.StringUtility['replace'](__urlPattern, '%', s);
		}
		private function __urlsForFrames(range:TimeRange):Vector.<String>
		{
			//RunClass.MovieMasher['msg'](this + '.__urlsForFrames ' + range + ' ' + range.seconds);
			// range.fps is probably mash, but scaled to player
			
			if (range.isEqualToTimeRange(__lastRange)) return __lastURLs;
					
			__lastRange = range.copyTimeRange();
			
			var url:String;
			var urls:Vector.<String> = new Vector.<String>();
			var frame,z:uint;
			var media_time:Time = __mediaLengthTime.copyTime();
			
			var limited_range:TimeRange = range.copyTimeRange();
			limited_range.minLength(media_time);			
			limited_range.scale(RunClass.TimeUtility['fps'], 'floor'); 
			
			z = limited_range.end;
			frame = limited_range.frame;
			var last_frame:uint;
			for (; frame < z; frame ++)
			{
				media_time = new Time(frame, limited_range.fps);
				media_time.scale(__mediaLengthTime.fps, 'floor');
				if ((frame != limited_range.frame) && (last_frame == media_time.frame)) continue;
				last_frame = media_time.frame;
				last_frame = Math.min(last_frame, __urlLookup.length - 1);
				url = __urlLookup[last_frame];
				if (url == null) 
				{
					url = __urlForFrame(last_frame);
					__urlLookup[last_frame] = url;
				}
				if (url.length) urls.push(url);
					
			}
			__lastURLs = urls;
			//RunClass.MovieMasher['msg'](this + '.__urlsForFrames ' + range + ' -> ' + limited_range + ' ' + urls);
			return urls;
		
		}
		private var __urlLookup:Vector.<String>;
		private var __mediaLengthTime:Time;
		private var __urlPattern:String;
		private var __zeroPadding:uint;
		private var __begin:uint;
		private var __increment:uint;
		private var __lastURLs:Vector.<String>;
		private var __lastRange:TimeRange;
		private var __assetFetchers:Array;
		private var __displayObject:DisplayObject;
		private var __displayObjectContainer:Sprite;
		private var __displayObjects:Object;
		private var __graphicTimer:Timer;
		private var __loaders:Dictionary;
		private var __requestedFetchers:Dictionary;
		private var __unbufferTimer:Timer;
	}
}