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

/**
* Implementation class for image modules
*
* @see IModule
* @see IClip
*/
	public class AVImage extends AVAudio
	{
		public function AVImage()
		{
			__displayObjectContainer = new Sprite();
			addChild(__displayObjectContainer);
		}
		override public function buffer(range:TimeRange, mute:Boolean):void
		{
			try
			{
				super.buffer(range, mute);
				if (__displayObject == null)
				{
					__requestDisplay();
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this, e);
			}
			
		}
		
		override public function buffered(range:TimeRange, mute:Boolean):Boolean
		{
			var is_buffered:Boolean = super.buffered(range, mute);
			if (__displayObject == null) is_buffered = false;
			return is_buffered;
		}
		override public function unbuffer(range:TimeRange):void
		{ 
			// we wait until unloaded since there's just the one frame
			//super.unbuffer(range); 
		}
		override public function unload():void
		{
			 _removeDisplay();
			super.unload();
		}
		
		public function get fetcher():IAssetFetcher
		{
			return _imageLoader;
		}
		override public function set time(object:Time):void
		{
			super.time = object;
			try
			{
				if (__displayObject != null)
				{
					if (! __displayObjectContainer.contains(__displayObject))
					{
						__displayObjectContainer.addChild(__displayObject);
					}
					_sizeDisplay();
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this, e);
			}
		}
		override public function get displayObject():DisplayObjectContainer
		{
			return this;
		}
		protected function _removeDisplay():void
		{
			try
			{
				if (__displayObject != null)
				{
					
					if (_imageLoader != null)
					{
						_imageLoader.releaseDisplay(__displayObject);
						_imageLoader = null;
					}
						
					if (__displayObjectContainer.contains(__displayObject))
					{
						__displayObjectContainer.removeChild(__displayObject);
					}
					__displayObject = null;
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this, e);
			}

		}
		protected function __requestDisplay():void
		{
			var url_string:String;
			try
			{
				if (_imageLoader == null)
				{
					url_string = _getImageURL();
					if ((url_string != null) && url_string.length)
					{
						var url:URL = new URL(url_string);
						_imageIsVector = (url.extension == 'swf');
						_imageLoader = RunClass.MovieMasher['assetFetcher'](url_string);
						
						_imageLoader.retain();
						_imageLoader.addEventListener(Event.COMPLETE, __graphicLoaded, false, 0, true);
						if (_imageLoader.state == EventType.LOADED)
						{
							__graphicLoaded(null);
						
						}
						
					}
				}
			}
			catch(e:*)
			{	
			}
		}
		protected function _getImageURL():String
		{
			return _getClipProperty('url');
		}
		protected function __graphicLoaded(event:Event):void
		{
			try
			{
				if (_imageLoader != null) 
				{
					
					if (_size == null) throw ('NO SIZE ' + media.tag.toXMLString() + ' ' + _getClipPropertyObject('mash').displayObject.parent);
					
					// TODO: determine best dimension to scale to - it might not be height!
					var size:Size = null;
					if (_imageIsVector) size = new Size(0, _size.height)
					__displayObject = _imageLoader.displayObject(_getImageURL(), '', size);
					
					//RunClass.MovieMasher['msg'](this + '.__graphicLoaded ' + __displayObject + ' ' + _size);
					if (__displayObject != null)
					{
						_imageLoader.removeEventListener(Event.COMPLETE, __graphicLoaded);
						dispatchEvent(new Event(EventType.BUFFER));
						
					}
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this, e);
			}
		
		}
		protected function _sizeDisplay():void
		{
			_sizeContainedDisplay(__displayObject, __displayObjectContainer);
		}
		protected var _imageIsVector:Boolean;
		protected var __displayObject:DisplayObject;
		protected var __displayObjectContainer:Sprite;
		protected var _imageLoader:IAssetFetcher;
	}
}