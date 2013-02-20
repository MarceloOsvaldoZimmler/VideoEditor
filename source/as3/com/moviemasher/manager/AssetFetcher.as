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
	import com.moviemasher.events.*;
	import com.moviemasher.interfaces.*;
	import com.moviemasher.manager.*;
	import com.moviemasher.type.*;
	import flash.display.*;
	import flash.events.*;
	import flash.media.*;
	import flash.net.*;
	import flash.system.*;
	import flash.text.*;
	import flash.utils.*;
	
/**
* Implementation class for fetching of all server side assets except XML
*
* @see IAssetFetcher
*/
	public class AssetFetcher extends Fetcher implements IAssetFetcher
	{
		public function AssetFetcher(iURL:URL, translate:Boolean)
		{
			super(iURL, translate);
			var handler_url_string:String;
			var is_loader_content:Boolean;
			
			var format:String = __url.format;
			if (_state == EventType.LOADING) // won't be for class references
			{
				is_loader_content = __url.isLoaderContent;
				__unloadable = (format != 'swf');
				if (__unloadable)
				{
					__unloadable = is_loader_content;
					if (! __unloadable)
					{
						handler_url_string = __handlerURL(format);
						__unloadable = Boolean(handler_url_string.length);
					}
				}
				if (is_loader_content)
				{
					__loadLoader();
				}
			}
		}
		public function classInstance(type:String = ''):Object
		{
			var ob:Object = null;
			var c:Class = classObject('',  type);
			if (c != null)
			{
				ob = new c();
			}
			
			return ob;
		}
		public function loader():Loader
		{
			return __loader;
		}
		public function unload():Boolean
		{
			var can_unload = ((__retainCount < 1) && ((__handler == null) || (! __handler.active)));
			if (can_unload) __unload();
			return can_unload;
		}
		override public function toString():String
		{
			var s:String = '[AssetFetcher';
			if (__url != null) 
			{
				s += ' ' + __url.url;
			}
			s += ']';
			return s;
		}
		public function retain():void
		{
			var key:int = 0;
			if (__retainCount < 1)
			{
				LoadManager.unpurgeSession(this);
				__retainCount = 0;
			}
			__retainCount++;
			if ((_state == EventType.LOADING) && (__retainCount > 1) && __url.isLoaderContent)
			{
				__loadLoader();
			}
		}
		public function releaseDisplay(display:DisplayObject):void
		{
			__release();
		}
		public function releaseAudio(handler:IHandler):void
		{
			__release();
		}
		public function handlerObject(url:String = '', format:String = ''):IHandler
		{
			var handler_url_string:String;
			var c:Class;
			displayTime = (new Date()).getTime();
			if (format.length)
			{
				__url.format = format;
			}
			if (url.length)
			{
				__url.url = url;
			}
			if (__handler == null)
			{
				handler_url_string = __handlerURL(__url.format);
				//RunClass.MovieMasher['msg'](this + '.handlerObject ' + handler_url_string);
				
				if (handler_url_string.length)
				{
					if (__handlerFetcher == null)
					{
						__handlerFetcher = RunClass.MovieMasher['assetFetcher'](handler_url_string, 'swf')
						
						if (__handlerFetcher.state == EventType.LOADING)
						{
							__handlerFetcher.addEventListener(Event.COMPLETE, _loaderComplete);
						}
					}
					
					if (__handlerFetcher != null)
					{
						if (__handlerFetcher.state != EventType.LOADING)
						{
							c = __handlerFetcher.classObject(handler_url_string, TagType.HANDLER);
							if (c != null)
							{
							
								__handler = new c(__url.absoluteURL) as IHandler;
								
								if (__handler != null)
								{
									_startListening(__handler);
								}
							}
							else RunClass.MovieMasher['msg']('No class found for ' + handler_url_string);
						}
					}
					
				}
				else RunClass.MovieMasher['msg']('No handler found for ' + __url.format);			
			}
			return __handler;
		}
		public function classObject(url:String='', type:String=''):Class
		{
			__url.format = 'swf';
			if (url.length)
			{
				__url.url = url;
			}
			
			
			var c:Class = null;
			var definition:String = __url.definition;
			
			if (definition.length)
			{
				if ((type.length) && (definition.indexOf('.') == -1))
				{
					definition = 'com.moviemasher.' + type + '.' + definition;
				}
				if (ApplicationDomain.currentDomain.hasDefinition(definition))
				{
					c = ApplicationDomain.currentDomain.getDefinition(definition) as Class;
				}
				else if (__loader != null)
				{
					if (__loader.contentLoaderInfo.applicationDomain.hasDefinition(definition))
					{
						c = __loader.contentLoaderInfo.applicationDomain.getDefinition(definition) as Class;
					}
				}
			}
			return c;
		}
		public function displayObject(url:String, format:String = '', size:Size = null):DisplayObject
		{
			
			var display_object:DisplayObject = null;
			try
			{
				if (_state == EventType.LOADED)
				{
					if (format.length)
					{
						__url.format = format;
					}
					if (url.length)
					{
						__url.url = url;
					}
					display_object = __displayObjectFromSWF(size);
					if (size == null)
					{
					
						if (display_object != null)
						{
							display_object = __displayBitmap(display_object);
						}
					}
					else
					{
						if ((! __url.definition.length) && (display_object != null))
						{
							var bm:Bitmap = __displayBitmap(display_object, size);
							if (bm != null)
							{
								display_object = bm;
							}
						}
					}
					if (__swf != null)
					{
						__swf.gotoAndStop(1);
						__swf = null;
					}
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.displayObject ' + url, e);
			}
			return display_object;
		}
		public function fontObject(url:String = ''):Font
		{
			__url.format = 'swf';
			if (url.length)
			{
				__url.url = url;
			}
			var i_font:Font = null;
			var safe_key:String = __url.key + __url.definition;
			if (__fonts[safe_key] == null)
			{
				//
				__fonts[safe_key] = classInstance(TagType.FONT) as Font;
				if (__fonts[safe_key] != null)
				{
					try
					{
						Font.registerFont(classObject('', TagType.FONT));
					}
					catch (e:*)
					{
						RunClass.MovieMasher['msg'](this, e);
					}
					
					var option_tag:XML = RunClass.MovieMasher['searchTag'](TagType.OPTION, __url.url, 'url');
					if ((option_tag != null) && (String(option_tag.@antialias) == 'advanced'))
					{
						var children:XMLList = option_tag.children();
						for each(var tag:XML in children)
						{
							var myAntiAliasSettings = new CSMSettings(Number(tag.@size), Number(tag.@incut), -Number(tag.@outcut));
							var myAliasTable:Array = new Array(myAntiAliasSettings);
							TextRenderer.setAdvancedAntiAliasingTable(__fonts[safe_key].fontName, __fonts[safe_key].fontStyle, TextColorType.DARK_COLOR, myAliasTable);
							TextRenderer.setAdvancedAntiAliasingTable(__fonts[safe_key].fontName, __fonts[safe_key].fontStyle, TextColorType.LIGHT_COLOR, myAliasTable);
						}
					}
				}
			}
			i_font = __fonts[safe_key];
			return i_font;		
		}
		override protected function _reload():Boolean
		{
			var did_reload:Boolean = super._reload();
			if (did_reload)
			{
				
				__loadLoader(true);
			}
			return did_reload;
		}
		private function __createLoader():void
		{
			if (__loader == null)
			{
				__loader = new Loader();
				_startListening(__loader.contentLoaderInfo);
			}	
		}
		private function __displayBitmap(iDisplayObject:DisplayObject, size:Size = null):Bitmap
		{
			var bm:Bitmap = null;
			try
			{
				var bitmap_data:BitmapData = null;
				iDisplayObject.scaleX = iDisplayObject.scaleY = 1;
				var display_size:Size = new Size(iDisplayObject.width, iDisplayObject.height);
				if (! display_size.isEmpty())
				{
					bm = new Bitmap();
					var scale:Size = __scaleSize(size, display_size);
					
					bitmap_data = new BitmapData(display_size.width * scale.width, display_size.height * scale.height, true, 0x00FFFFFF);
				
					iDisplayObject.scaleX = scale.width;
					iDisplayObject.scaleY = scale.height;
							
					var ob_parent:DisplayObjectContainer = iDisplayObject.parent;
					var no_parent:Boolean = (ob_parent == null);
					if (no_parent)
					{
						ob_parent = new Sprite();
						ob_parent.addChild(iDisplayObject);
					}
					bitmap_data.draw(iDisplayObject.parent);
					if (no_parent)
					{
						ob_parent.removeChild(iDisplayObject);
					}
					
					iDisplayObject.scaleX = iDisplayObject.scaleY = 1;
				}
				
				if (bitmap_data != null)
				{
					bm.bitmapData = bitmap_data;
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__displayBitmap ' + size, e);
			}
			return bm;
		}
		private function __displayObjectFromSWF(size:Size=null):DisplayObject
		{
			var display_object:DisplayObject = null;
			try
			{
				if (__url.definition.length) 
				{
					display_object = classInstance('display') as DisplayObject;
					if (display_object != null)
					{
						var display_size:Size = new Size(display_object.width, display_object.height);
						var scale:Size = __scaleSize(size, display_size);
					
						display_object.scaleX = scale.width;
						display_object.scaleY = scale.height;
					}
				}
				else if (__url.anchor.length)
				{
					if (__loader)
					{
						if (__url.format == 'swf')
						{
							__swf = __loader.content as MovieClip;
							if (__swf != null)
							{
								__swf.gotoAndStop(__url.anchor);
								display_object = __swf;
							}
						}
					}
				}
				else
				{
					displayTime = (new Date()).getTime();
					display_object = __loader;
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__displayObjectFromSWF', e);
			}
			return display_object;
		}
		private function __handlerURL(format:String):String
		{
			var handler_url:String = '';
			var handler:XML;
			handler = RunClass.MovieMasher['searchTag'](TagType.HANDLER, format);
			if (handler == null) handler = RunClass.MovieMasher['searchTag'](TagType.HANDLER, '*');
			if (handler != null) handler_url = String(handler.@url);
			return handler_url;
			
		}
		private function __load(url_string:String, context):void
		{
			url_string = _translatedURL(url_string);
			
			__loader.load(new URLRequest(url_string), context);
		}
		private function __loadLoader(reload:Boolean = false):void
		{
			
			_state = EventType.LOADING;
			if (reload) __destroyLoader();
			if (__requestingSessions[this] == null)
			{
				__requestingSessions[this] = true;
				__queuedSessions.push(this);
				if (__requestingTimer == null)
				{
					__requestingTimer = new Timer(100);
					__requestingTimer.addEventListener(TimerEvent.TIMER, __requestingTimed);
					__requestingTimer.start();
					__requestingTimed(null);
				}
			}
		}
		private function __release():void
		{
			__retainCount--;
			if (__unloadable && (__retainCount == 0))
			{
				LoadManager.purgeSession(this);
				__retainCount = -1;
			}
			
		}
		private static function __requestContext(url:URL):LoaderContext
		{
			var domain:ApplicationDomain = ApplicationDomain.currentDomain;
			if (url.format == 'jpg')
			{
				domain = new ApplicationDomain(domain);
			}
			var loader_context:LoaderContext = new LoaderContext(false, domain);
			if (Security.sandboxType == Security.REMOTE)
			{
				loader_context.securityDomain = SecurityDomain.currentDomain;
			}
			
			return loader_context;
		}
		private static function __requestingTimed(event:TimerEvent):void
		{
			var found_one:Boolean = false;
			
			var session:AssetFetcher;
			var url:URL;
			var context:LoaderContext = null;
			var url_string:String;
			var stop_time:Number;
			try
			{
				stop_time = (new Date()).getTime() + 50; // do this for 1/20 of a second max
				while (__queuedSessions.length && (stop_time > (new Date()).getTime()))
				{
					found_one = true;
					session = __queuedSessions.shift();
					url = session.urlObject;
					if (url != null)
					{
						if (session.__loader == null)
						{
							session.__createLoader();
							url_string = url.absoluteURL;
							context = __requestContext(url);
							session.__load(url_string, context);
						//	RunClass.MovieMasher['msg'](AssetFetcher + '.__requestingTimed ' + url_string);
						}
					}
					delete __requestingSessions[session];
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](AssetFetcher + '.__requestingTimed', e);
			}
			if ((! found_one) && (__requestingTimer != null))
			{
				__requestingTimer.removeEventListener(TimerEvent.TIMER, __requestingTimed);
				__requestingTimer.stop();
				__requestingTimer = null;
			}
		}
		private function __scaleSize(size:Size, display_size:Size):Size
		{
			var scale:Size = new Size(1,1);
			if (size != null)
			{
				var width_valid:Boolean = (size.width && (size.width != Infinity));
				var height_valid:Boolean = (size.height && (size.height != Infinity));
				if (width_valid)
				{
					scale.width = size.width / display_size.width;
				}
				if (height_valid)
				{
					scale.height = size.height / display_size.height;
				}
				if (! size.width)
				{
					scale.width = scale.height;
				}
				if (! size.height)
				{
					scale.height = scale.width;
				}
			}
			return scale;
		}
		private function __unload():void
		{
			try
			{
				if (__url != null) LoadManager.removeSession(this);
				if (__handler != null)
				{
					_stopListening(__handler);
					__handler.unload();
					__handler = null;
				}
				if (__handlerFetcher != null)
				{
					__handlerFetcher.removeEventListener(Event.COMPLETE, _loaderComplete);
					__handlerFetcher = null;
				}
				__destroyLoader();
				__url = null;
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__unload', e);
			}
		}
		private function __destroyLoader():void
		{
			try
			{
				if (__loader != null)
				{
					if ((__loader.parent != null))
					{
						__loader.parent.removeChild(__loader);
					}
					if (__loader.contentLoaderInfo != null)
					{
						_stopListening(__loader.contentLoaderInfo);
					}
					__loader.unload();
					__loader = null;
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__unload', e);
			}
		}
		private static var __swf:MovieClip;
		private static var __fonts:Object = new Object();
		private static var __queuedSessions:Array = new Array();
		private static var __requestingSessions:Dictionary = new Dictionary();
		private static var __requestingTimer:Timer;
		private var __handlerFetcher:IAssetFetcher;
		private var __handler:IHandler;
		private var __loader:Loader;
		private var __retainCount:int = 0;
		private var __unloadable:Boolean = false;
		public var displayTime:Number = -1; // used by LoadManager to sort during purging
	}
}