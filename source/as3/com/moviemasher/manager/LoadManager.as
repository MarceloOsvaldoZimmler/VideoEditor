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
package com.moviemasher.manager
{
	import com.moviemasher.constant.*;
	import com.moviemasher.core.MovieMasher;
	import com.moviemasher.events.*;
	import com.moviemasher.interfaces.*;
	import com.moviemasher.type.*;
	import flash.display.*;
	import flash.events.*;
	import flash.media.*;
	import flash.net.*;
	import flash.system.*;
	import flash.text.*;
	import flash.utils.*;
	
/**
* Implementation class for load manager
*
* @see MoviemasherStage
* @see LoadManager
*/
	public class LoadManager extends Sprite
	{
		public function LoadManager()
		{
			// this should not be called directly - use LoadManager.sharedInstance
			
			__sessions = new Object();
			policies = new Dictionary();
			__purgeSessions = new Array();
			__purgeTimer = new Timer(5000);
			__purgeTimer.addEventListener(TimerEvent.TIMER, __purge);
			__purgeTimer.start();
		}
		public static function purgeSession(session:IAssetFetcher):void
		{
			__purgeSessions.push(session);
		}
		public static function unpurgeSession(session:IAssetFetcher):void
		{
			var index:int = __purgeSessions.indexOf(session);
			if (index != -1)
			{
				__purgeSessions.splice(index, 1);
			}
		}
		public function preconfigure():void
		{
			var url_string:String = MovieMasher.getParameter('url_filter');
			if (url_string.length)
			{
				
				// it should be an existing class in the current domain starting with @
				var fetcher:IAssetFetcher = assetFetcher(url_string, 'swf');
				if (fetcher != null) __translate = fetcher.classObject();
			}
		
		}
		public function assetFetcher(iUrlString:String, format:String = ''):IAssetFetcher
		{
			var session:IAssetFetcher = null;
			if (iUrlString.length)
			{
				if (iUrlString.indexOf('{') > -1) iUrlString = RunClass.ParseUtility['optionBrackets'](iUrlString);

				var url:URL = new URL(iUrlString, format);
				var url_key:String = url.key;
				session = __sessions[url_key];
				if (session == null)
				{
					session = new AssetFetcher(url, __translate != null);
				}
				__initFetcher(session, url_key, iUrlString);
			}
			return session;


		}
		public function dataFetcher(iUrlString:String, postData:*=null, format:String = null):IDataFetcher
		{
			if (format == null) format = URLLoaderDataFormat.TEXT;
			
			var session:IDataFetcher = null;
			if (iUrlString.length)
			{
				if (iUrlString.indexOf('{') > -1) iUrlString = RunClass.ParseUtility['optionBrackets'](iUrlString);
				var url:URL = new URL(iUrlString, 'xml');
				var url_key:String = url.key;
				session = __sessions[url_key];
				if (session == null)
				{
					session = new DataFetcher(url, postData, format, __translate != null);
				}
				__initFetcher(session, url_key, iUrlString);
			}
			return session;
		}
		public function getValue(property:String):Value
		{
			var value:Value;
			var k:String;
			var fetcher:IFetcher;
			var total:Number = 0;
			var loaded:Number = 0;
			var fetcher_total:Number = 0;
			switch(property)
			{
				case EventType.LOADING:
				
					for(k in __sessions)
					{
						fetcher = __sessions[k];
						total++;
						if (fetcher.state != EventType.LOADING)
						{
							loaded ++;
						}
					}
					if (total) loaded = 100 - Math.ceil((loaded / total) * 100);
					value = new Value(loaded);
					break;
				
				case EventType.LOADED:
					
					for(k in __sessions)
					{
						fetcher = __sessions[k];
						if (fetcher.state == EventType.LOADING)
						{
							fetcher_total = fetcher.bytesTotal;
							if (fetcher_total)
							{
								total += fetcher_total
								loaded += fetcher.bytesLoaded;
							}
						}
					}
					if (total) loaded /= total;
					value = new Value(loaded * 100);
					break;
				default:
					value = new Value('');
			}
			return value;
		}
		public static function removeSession(session:IFetcher):void
		{
			var key:String = session.key;
			__sessions[key] = null;
			delete __sessions[key];
		}
		public function addPolicy(iURL:String):void
		{
			var url:URL = null;
			var len:Number = iURL.length;
			if (len > 0)
			{
				url = new URL(iURL);
				var absolute_url:String = url.absoluteURL;
				if (absolute_url.length)
				{
					absolute_url = absolute_url.substr(0, - (url.file.length + url.extension.length + 1));
					policies[absolute_url] = url;
					Security.loadPolicyFile(url.absoluteURL);
				}
			}
		}
		public function translatedURL(url_string:String):String
		{
			if (__translate != null)
			{
				url_string = __translate['translatedURL'](url_string);
			}
			return url_string;
		}
		
		private function __initFetcher(session:IFetcher, url_key:String, iUrlString:String, format:String = null):void
		{
			if (__sessions[url_key] == null)
			{
				__sessions[url_key] = session;
				if (sharedInstance.hasEventListener(EventType.LOADED) || sharedInstance.hasEventListener(EventType.LOADING))
				{		
					session.addEventListener(Event.CHANGE, __sessionChange);
				}
				session.addEventListener(Event.COMPLETE, __sessionChange);
			}
			else session.url = iUrlString;
		}
		private function __purge(event:TimerEvent):void
		{
			if ((__purgingTimer == null) && __purgeSessions.length)
			{
				__purgingTimer = new Timer(1000);
				__purgingTimer.addEventListener(TimerEvent.TIMER, __purgeTimed);
				__purgingTimer.start();
			}
		}
		private function __purgeTimed(event:TimerEvent):void
		{
			try
			{
				var session:IAssetFetcher;
				var z:uint;
				var found_one, timed_out:Boolean;
				var stop_time:Number = (new Date()).getTime() + 15; // do this for less than 1/30 of a second
				z = __purgeSessions.length;
				if (z)
				{
					
					if ((z > 100) && ((RunClass.MovieMasher['evaluate']('moviemasher.playing') == '0') || (RunClass.MovieMasher['evaluate']('player.stalling') == '1'))) 
					{
						stop_time += 500;
					}
					
					__purgeSessions.sortOn('displayTime');
					while (z-- && (! timed_out))
					{
						session = __purgeSessions.shift();
						if (session != null)
						{
							if (! session.unload()) __purgeSessions.push(session);
							else found_one = true;
						}
						timed_out = (stop_time < (new Date()).getTime());
					}
				}
				if ((! timed_out) && (! __purgeSessions.length))
				{
					if (__purgingTimer != null)
					{
						__purgingTimer.removeEventListener(TimerEvent.TIMER, __purgeTimed);
						__purgingTimer.stop();
						__purgingTimer = null;
					}
				}
				if (found_one)
				{
					System.gc();
					System.gc();
				}
				//if (timed_out) RunClass.MovieMasher['msg']('timed out with ' + __purgeSessions.length);
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this, e);
			}
		}
		private static function __preloadingTimed(event:Event):void
		{
			if (__loadingPercent == 0)
			{

				sharedInstance.dispatchEvent(new ChangeEvent(new Value(__loadingPercent), EventType.LOADING));
			}
			__loadingTimer.stop();
			__loadingTimer.removeEventListener(TimerEvent.TIMER, __preloading);
			__loadingTimer = null;
		}
		private static function __preloading():void
		{
			var percent:int = sharedInstance.getValue(EventType.LOADING).number;
			var done:Number = 0.0;
			var step:Number = 1.0;
			var n:Number;
			if (__loadingPercent != percent)
			{
				__loadingPercent = percent;
				if (percent == 0)
				{
					__preloadingCount++;
					if (__preloadingCount < 3)
					{
						percent = 100; // we are now just starting the next step
						
						if (__preloadingCount == 2)
						{
							// configuration, interface elements and sources have been loaded
							if (__loadingTimer == null)
							{
								// start timer to see if additional requests are made in the next second
								__loadingTimer = new Timer(1000);
								__loadingTimer.addEventListener(TimerEvent.TIMER, __preloadingTimed);
								__loadingTimer.start();
							}
						}
					}
				}
				switch(__preloadingCount)
				{
					case 0: // loading XML config and SWFs in 'symbol' attributes
						step = .2;
						break;
					case 1: // loading SWFs and graphics referenced in panels
						step = .3;
						done = .3;
						break;
					case 2: // possibly loading icons for browser/timeline and frame one of player
						step = .3;
						done = .7;
						break;
					
				}
				n = (100 - percent) / 100;
				percent = 100 - Math.round(100 * (done + (n * step)));
				
				sharedInstance.dispatchEvent(new ChangeEvent(new Value(percent), EventType.LOADING));
				
			}
		}
		private static function __sessionChange(event:Event):void
		{
			var session:IFetcher = event.target as IFetcher;
			try
			{
				if (session.state != EventType.LOADING)
				{
					session.removeEventListener(Event.CHANGE, __sessionChange);
					session.removeEventListener(Event.COMPLETE, __sessionChange);
				}
				if (sharedInstance.hasEventListener(EventType.LOADED))
				{
					var value:Value;
					value = sharedInstance.getValue(EventType.LOADED)

					sharedInstance.dispatchEvent(new ChangeEvent(value, EventType.LOADED));
				}
				if (sharedInstance.hasEventListener(EventType.LOADING))
				{
					__preloading();
				}
				
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](LoadManager, e);
			}
		}
		private static var __bytesTotal:Number = 0;
		private static var __loadingPercent:int = 0;
		private static var __loadingTimer:Timer;
		private static var __needsAssetFetcher:AssetFetcher;
		private static var __needsDataFetcher:DataFetcher;
		private static var __preloadingCount:int = 0;
		private static var __purgeSessions:Array;
		private static var __purgeTimer:Timer;
		private static var __sessions:Object;
		private static var __purgingTimer:Timer;
		private static var __translate:Class;
		public static var policies:Dictionary; // accessed by Fetcher
		public static var sharedInstance:LoadManager;
		
	}
}

		