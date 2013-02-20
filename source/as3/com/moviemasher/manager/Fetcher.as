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
	import flash.display.*;
	import flash.events.*;
	import flash.media.*;
	import flash.net.*;
	import flash.system.*;
	import flash.text.*;
	import flash.utils.*;
	import com.moviemasher.type.*;
	import com.moviemasher.constant.*;
	import com.moviemasher.events.*;
	import com.moviemasher.manager.*;
	import com.moviemasher.type.*;
	import com.moviemasher.constant.*;
	import com.moviemasher.interfaces.*;
	
/**
* Implementation class for data and file loading
*
* @see LoadManager
* @see MoviemasherStage
* @see MovieMasher
* @see IAssetFetcher
*/
	public class Fetcher extends EventDispatcher
	{
		public function Fetcher(iURL:URL, translate:Boolean)
		{
			
			__url = iURL;
			_translate = translate;
			// URL might start with @ indicating an existing class
			_state = (__url.server.length ? EventType.LOADING : EventType.LOADED);
			if (_state == EventType.LOADING) __loadPolicy(__url);
		}
		public function get key():String
		{ return __url.key; }
		
		public function get bytesTotal():Number
		{
			return __bytesTotal;
		}
		public function get bytesLoaded():Number
		{
			return __bytesLoaded;
		}
		public function set url(string:String):void
		{
			__url.url = string;
		}
		public function get urlObject():URL
		{ return __url; }


		public function get state():String
		{
			return _state;
		}
		public function set retries(number:int):void
		{
			__reloadCount = number;
		}
		private function __loadPolicy(url:URL):void
		{
			var absolute_url:String = url.absoluteURL;
			var n:int = absolute_url.length;
			
			for (var url_string:String in LoadManager.policies)
			{
				if (url_string == absolute_url.substr(0, url_string.length))
				{
					if (LoadManager.policies[url_string] != 'REQUESTED')
					{
						var policy_url:URL = LoadManager.policies[url_string];
						Security.loadPolicyFile(policy_url.absoluteURL);
						LoadManager.policies[url_string] = 'REQUESTED';
					}
					break;
				}
			}
		}
		
		
		
				
		protected function _loaderComplete(event:Event):void
		{
			try
			{
				//RunClass.MovieMasher['msg'](this + '._loaderComplete ' + urlObject.url);
				if (event.target is IEventDispatcher)
				{
					_stopListening(event.target as IEventDispatcher);
				}
				if (_state != EventType.ERROR)
				{
					_state = EventType.LOADED;
					dispatchEvent(new Event(Event.COMPLETE));	
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '._loaderComplete', e);
			}
		}
		protected function _reload():Boolean
		{
			__reloadCount--;
			var reloaded:Boolean = (__reloadCount >= 0);
			return reloaded;
		}
		protected function __loaderError(event:IOErrorEvent):void
		{
			//RunClass.MovieMasher['msg'](this + '.__loaderError ' + event);
						
			try
			{
				if (_httpStatus != 200) // not sure why we're getting 2124 error??
				{
					if ((_httpStatus < 500) || (! _reload() ) )
					{
						
						_state = EventType.ERROR;
						dispatchEvent(new Event(Event.CHANGE));			
						dispatchEvent(new Event(Event.COMPLETE));
					}
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__loaderError', e);
			}
		}
		protected function __loaderSecurityError(event:SecurityErrorEvent):void
		{
			RunClass.MovieMasher['msg'](this + '.__loaderSecurityError' + event);
		}
		protected function __loaderHTTPStatus(event:HTTPStatusEvent):void
		{
			_httpStatus = event.status;
		//	if (_httpStatus != 200) RunClass.MovieMasher['msg'](this + '.__loaderHTTPStatus ' + _httpStatus);
		}
		protected function __loaderProgress(event:ProgressEvent):void
		{
			//RunClass.MovieMasher['msg'](this + '.__loaderProgress ' + event);
			__bytesLoaded = event.bytesLoaded;
			__bytesTotal = event.bytesTotal;
			if (__bytesTotal != __bytesLoaded) dispatchEvent(new Event(Event.CHANGE));	
		}
		
		protected function _startListening(listener:IEventDispatcher):void
		{
			listener.addEventListener(IOErrorEvent.IO_ERROR, __loaderError);
			listener.addEventListener(Event.COMPLETE, _loaderComplete);
			listener.addEventListener(SecurityErrorEvent.SECURITY_ERROR, __loaderSecurityError);
			listener.addEventListener(HTTPStatusEvent.HTTP_STATUS, __loaderHTTPStatus);
			if (LoadManager.sharedInstance.hasEventListener(EventType.LOADED))
			{
				listener.addEventListener(ProgressEvent.PROGRESS, __loaderProgress);
			}
		}
		
		protected function _stopListening(listener:IEventDispatcher):void
		{
			//RunClass.MovieMasher['msg'](this + '._stopListening ' + listener);
			listener.removeEventListener(IOErrorEvent.IO_ERROR, __loaderError);
			listener.removeEventListener(Event.COMPLETE, _loaderComplete);
			listener.removeEventListener(ProgressEvent.PROGRESS, __loaderProgress);
			listener.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, __loaderSecurityError);
			listener.removeEventListener(HTTPStatusEvent.HTTP_STATUS, __loaderHTTPStatus);
		}
		final protected function _translatedURL(url_string):String
		{
			if (_translate) url_string = LoadManager.sharedInstance.translatedURL(url_string);
			return url_string;
		}
		
		private var __reloadCount:int = 3;// number of times we'll retry after an http error >= 500
		protected var __bytesLoaded:Number = 0;
		protected var __bytesTotal:Number = 0;
		protected var __url:URL;
		protected var _httpStatus:int;
		protected var _state:String;
		protected var _translate:Boolean;
	}
}