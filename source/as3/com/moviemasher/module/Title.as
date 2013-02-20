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
	import flash.text.*;
	import flash.events.*;
	import flash.display.*;
	import com.moviemasher.utils.*;
	import com.moviemasher.type.*;
	import com.moviemasher.constant.*;
	import com.moviemasher.interfaces.*;
	import com.moviemasher.events.*;
/**
* Implementation base class for displaying text within mash
*
* @see IModule
* @see Clip
* @see Mash
*/
	public class Title extends Module implements IValued // so we can use formatField
	{
		public function Title()
		{
			_defaults.textalign = 'center';
			_defaults.textsize = '48';
			_defaults.forecolor = 'FFFFFF';
			_defaults.backcolor = '0';
			_defaults.text = '';
			_defaults.copy = '';
			_defaults.longtext = 'Title';
			_defaults.font = 'default';
			_textField = new TextField();
			_textField.autoSize = TextFieldAutoSize.LEFT;
			addChild(_textField);
		}
		
		public function getValue(property:String):Value
		{
			return new Value(_getClipProperty(property));
		}
		override public function get backColor():String
		{
			return _getClipProperty(ModuleProperty.BACKCOLOR);
		}
		override public function buffered(range:TimeRange, mute:Boolean):Boolean
		{
			var is_buffered:Boolean = true;
			var loader:IAssetFetcher = __fontLoader(_getClipProperty(TextProperty.FONT));
			if (loader != null)
			{
				is_buffered = (loader.state == EventType.LOADED);	
			}
			return is_buffered;
		}
		override public function get displayObject():DisplayObjectContainer
		{
			return this;
		}
		private function __fontLoader(font:String):IAssetFetcher
		{
					
			var loader:IAssetFetcher;
			if ((font != null) && font.length)
			{
				loader = __fontLoaders[font];
				if (loader == null)
				{
					var url:String = '';
					__fontLoaders[font] = false; // so we only try once

					var font_tag:XML;
					var imash:* = null;
					if ((font != null) && font.length)
					{
						imash = _getClipPropertyObject(ClipProperty.MASH);
						
						font_tag = RunClass.MovieMasher['fontTag'](font, imash);
						if (font_tag != null)
						{
							url = String(font_tag.@url);
						}
					}
			
			
					if (url.length)
					{
						loader = RunClass.MovieMasher['assetFetcher'](url, 'swf');
						if (loader != null)
						{
							__fontLoaders[font] = loader;
							loader.addEventListener(Event.COMPLETE, _fontComplete);
						}
					}
				}
			}
			return loader;
		}
	
		protected function _fontComplete(event:Event):void
		{
			try
			{
				event.target.removeEventListener(Event.COMPLETE, _fontComplete);
				var font:String = _getClipProperty(TextProperty.FONT);
				if ((font != null) && font.length)
				{
					if (__fontLoaders[font] == event.target)
					{
						dispatchEvent(new Event(EventType.BUFFER));
					}
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this, e);
			}
		}
		override public function set time(object:Time):void
		{
			super.time = object;
			_formatField();
			_setText();
			_setTextSize();
		}
		protected function _formatField():void
		{
			try
			{
				RunClass.FontUtility['formatField'](_textField, this, _size, _getClipPropertyObject(ClipProperty.MASH));
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '._formatField', e);
			}
		}
		
		protected function _setText():void
		{
			try
			{
				_textField.width = _size.width;
				var s:String = _getText();
				var tf:TextFormat = _textField.defaultTextFormat;
				_textField.htmlText = s;
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '._setText', e);
			}

		}
		protected function _getText():String
		{
			var text:String = _getClipProperty('text');
			var delimiter:String;
			var was_text:Boolean = Boolean(text.length);
			if (! text.length)
			{
				text = _getClipProperty('longtext');
			}
			if (text.length) 
			{
				delimiter =  _getMediaProperty('delimiter');
				if ((delimiter != null) && delimiter.length)
				{
					var index:Number = text.indexOf(delimiter);
					
					if (index != -1)
					{
						text = text.substr(0, index);
					}
				}
			}
			return text;
		}
		protected function _setTextSize():void
		{
			try
			{
				_textField.x = - Math.round(_textField.width / 2);
				_textField.y = - Math.round(_textField.height / 2);
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '._setTextSize', e);
			}

		}
		protected var _textField:TextField;
		private static var __fontLoaders:Object = new Object();
	}
}