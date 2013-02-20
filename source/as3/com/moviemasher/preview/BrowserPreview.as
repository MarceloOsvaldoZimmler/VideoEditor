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

package com.moviemasher.preview
{
	import com.moviemasher.constant.*;
	import com.moviemasher.display.*;
	import com.moviemasher.events.*;
	import com.moviemasher.interfaces.*;
	import com.moviemasher.options.*;
	import com.moviemasher.type.*;
	import com.moviemasher.utils.*;
	import flash.display.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.system.*;
	import flash.text.*;
	import flash.utils.*;
/**
* Implementation class for media preview appearing in a browser 
*
* @see Browser
*/
	public class BrowserPreview extends Sprite implements IPreview
	{
		public function BrowserPreview()
		{
			// create container for elements
			_maskSprite = new Sprite();
			addChild(_maskSprite);
			__childrenSprite = new Sprite();
			addChild(__childrenSprite);
			__childrenSprite.mask = _maskSprite;
			_displayObjectContainer = new Sprite();
			__childrenSprite.addChild(_displayObjectContainer);
			useHandCursor = false;
			_labelSprite = new Sprite();
			__childrenSprite.addChild(_labelSprite);
			_labelField = new TextField();
			__childrenSprite.addChild(_labelField);
		}
		public static function animatePreviews(tf:Boolean):void
		{
			__animatePreviews = tf;
		}
		override public function toString():String
		{
			var s:String = '[' + super.toString();
			if (_options != null)
			{
				var icon:String = _options.getValue('icon').string;
							
				if ((icon != null) && icon.length)
				{
					s += ' ' + icon;
				}
			}
			s += ']';
			return s;
		}
		public function updateTooltip(tooltip:ITooltip):Boolean
		{
			return false;
		}
		public function unload():void
		{
			try
			{
				animating = false;
				if (__mash != null) 
				{
					__mash.removeEventListener(EventType.BUFFER, __bufferMash);
					__mash.unload();
					__mash = null;
				}
				if (_mouseSprite != null)
				{
					if (contains(_mouseSprite)) removeChild(_mouseSprite);
				}
				if (__childrenSprite != null)
				{
					if (_displayObjectContainer != null)
					{
						if (_displayObject != null)
						{
							
							if (_displayObjectContainer.contains(_displayObject))
							{
								_displayObjectContainer.removeChild(_displayObject);
							}
							
							_displayObject = null;
						}
						if (__childrenSprite.contains(_displayObjectContainer)) __childrenSprite.removeChild(_displayObjectContainer);
						_displayObjectContainer = null;
					}
					if (_labelSprite != null)
					{
						__childrenSprite.removeChild(_labelSprite);
						_labelSprite = null;
					}
					if (_labelField != null)
					{
						__childrenSprite.removeChild(_labelField);
						_labelField = null;
					}
					if (contains(__childrenSprite)) removeChild(__childrenSprite);
					__childrenSprite.mask = null;
					__childrenSprite = null;
				}
				if (_loader != null)
				{
					_loader.releaseDisplay(_displayObject);
					_loader.removeEventListener(Event.COMPLETE, _displayLoaded);
					_loader = null;
				}
				if (_maskSprite != null)
				{
					if (contains(_maskSprite)) removeChild(_maskSprite);
					_maskSprite = null;
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + ' BrowserPreview.unload', e);
			}
		}
		public function set animating(tf:Boolean):void
		{
			if (tf)
			{
				if (__animTimer == null)
				{
					__animTimer = new Timer(500);
					__animTimer.addEventListener(TimerEvent.TIMER, __animTimed, false, 0, true);
					__animTimer.start();
					__animTimed(null);
				}
			}
			else
			{
				if (__animTimer != null)
				{
					__animTimer.stop();
					__animTimer.removeEventListener(TimerEvent.TIMER, __animTimed);
					__animTimer = null;
				}
			}
		
		}
		public function get backBounds():Rectangle
		{
			return _maskSprite.getBounds(this);
		}
		public function set clip(iclip:IClip):void
		{
			_clip = iclip;
		}
		public function get clip():IClip
		{
			if (_clip == null) _clip = __clipFromXML(_mediaTag.copy());
			return _clip;
		}
		public function set container(previewContainer:IPreviewContainer):void
		{
			_container = previewContainer;
		}
		public function get container():IPreviewContainer
		{
			return _container;
		}
		public function set data(object:Object):void
		{
			var defined:Boolean = (_data != null);
			//RunClass.MovieMasher['msg'](this + '.data ' + defined);
			_data = object;
			if (! defined) _initialize();
			_optionsChanged();
		}
		public function get data():Object
		{
			return _data;
		}
		public function get displayObject():DisplayObjectContainer
		{
			return this;
		}
		public function set mediaTag(xml:XML):void
		{
			_mediaTag = xml;
		}
		public function get mediaTag():XML
		{
			return _mediaTag;
		}
		public function get options():IOptions
		{
			return _options;
		}
		public function set options(value:IOptions):void
		{
			//RunClass.MovieMasher['msg'](this + '.options');
			_options = value;
		}
		public function set selected(value:Boolean):void
		{
			if (_selected != value)
			{
				_selected = value;
				_resize();
				_displayObjectContainer.blendMode = BlendMode[_options.getValue((_selected ? 'over' : '') + 'blend').string.toUpperCase()];
				if (_iconIsModule)
				{
					animating = _selected;
				}
			}
		}
		public function get size():Size
		{
			return new Size(_mouseSprite.width, _mouseSprite.height);
		}
		protected function _displayLoaded(event:Event):void
		{
			try
			{
				event.target.removeEventListener(Event.COMPLETE, _displayLoaded);
				_displayLoadURL();
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '._displayLoaded', e);
			}
	
		}
		protected function _displayLoadURL():void
		{
			try
			{
				if ((_loader != null) && (_loader.state != EventType.LOADING))
				{
					var icon:String = null;
					icon = _options.getValue('icon').string;
					var display_size:Size = _displaySize();
					_displayObject = _loader.displayObject(icon, '', display_size);
					if (_displayObject != null)
					{
						_displayObjectContainer.blendMode = BlendMode[_options.getValue((_selected ? 'over' : '') + 'blend').string.toUpperCase()];
						_iconIsModule = (_displayObject is IModule);
						if (_iconIsModule)
						{
							
							__mash = RunClass.Mash['fromMediaXML'](_mediaTag, options.getValue('preview').string, ((_clip == null) ? null : _clip.tag.copy()));
							
							__mash.metrics = display_size;
							_displayObject = __mash.displayObject;
							__animFrame = PREVIEW_FRAMES / 2;
							__mashGo();
							
							_displayObject.x = display_size.width / 2;
							_displayObject.y = display_size.height / 2;
						
						}
						_displayObjectContainer.addChildAt(_displayObject, 0);

						_resize();
					}
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '._displayLoadURL ' + icon, e);
			}
		}
		protected function _displaySize():Size
		{
			return new Size(_iconWidth, _iconHeight);			
		}	
		protected function _drawBack():void
		{
			RunClass.DrawUtility['shadowBox'](_options, this, (_selected ? 'over' : ''));
			_mouseSprite.graphics.clear();
			RunClass.DrawUtility['fill'](_mouseSprite.graphics, _options.getValue('width').number, _options.getValue('height').number, 0, 0);
				
		}
		protected function _drawPreview():Boolean 
		{
			var called_resize:Boolean = false;
			try
			{
				if (_displayObject == null)
				{
					var size:Size = _displaySize();
					if ((size.width > 0) && (size.height > 0))
					{
						if (_loader == null)
						{
							var icon:String = _options.getValue('icon').string;
							if (icon.length)
							{
								_loader = RunClass.MovieMasher['assetFetcher'](icon);
								_loader.retain();
								_displayLoadURL();
								called_resize = (_displayObject != null);
								if (! called_resize) _loader.addEventListener(Event.COMPLETE, _displayLoaded);
							}
						}
					}
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this, e);
			}
			return called_resize;
		}
		protected function _initialize():void
		{ 
			var iString:String = _data[MediaProperty.LABEL];
			_labelField.visible = _labelSprite.visible = Boolean(iString.length) && _options.getValue('textheight').boolean;
			if (_labelField.visible) 
			{
				RunClass.FontUtility['formatField'](_labelField, _options);
				_labelField.text = iString;
			}
			__createMouse();
			
		}
		protected function _optionsChanged():void
		{ 
			_resize();
		}
		protected function _resize():void
		{
			try
			{
				var sel:String = (_selected ? 'over' : '');
				var textvalign:String = _options.getValue(TextProperty.TEXTVALIGN).string;
				var textsize:Number = _options.getValue(TextProperty.TEXTSIZE).number;
				var w:Number = _options.getValue('width').number;
				var h:Number = _options.getValue('height').number;
				
				var textheight:Number = _options.getValue('textheight').number;
				var border:Number = _options.getValue(ControlProperty.BORDER).number;
				var ratio:Number = _options.getValue('ratio').number;
				_iconHeight = 0;
				_iconWidth = 0 ;
				var label_height:Number = 0;
				if (textheight && textsize)
				{
					switch(textvalign)
					{
						case 'above':
						case 'below':
						
							label_height += textheight;
							break;
					}
				}
				if (w)
				{
					_iconWidth = w - (2 * border);
				}
				if (h)
				{
					_iconHeight = h - (2 * border + label_height);
				}
				
				if (ratio)
				{
					if (! h) _iconHeight = _iconWidth / ratio;
					else if (! w) _iconWidth = _iconHeight / ratio;
					else
					{
						if (_iconHeight >= _iconWidth / ratio) _iconHeight = _iconWidth / ratio;
						else _iconWidth = _iconHeight / ratio;
					}
				}
				 
				
				//RunClass.MovieMasher['msg'](this + '._resize ' + w + 'x' + h + ' -> ' + _iconWidth + 'x' + _iconHeight + ' Ratio: ' + ratio);
				
				var icon_y:Number = _resizeLabel();
				_displayObjectContainer.x = border;
				_displayObjectContainer.y = icon_y;
				
				if (! h)
				{
					h = _iconHeight + (2 * border) + label_height;
					_options.setValue(new Value(h), 'height');
				}
				_drawBack();
				_maskSprite.graphics.clear();
				RunClass.DrawUtility['setFill'](_maskSprite.graphics, 0x000000);
				RunClass.DrawUtility['drawPoints'](_maskSprite.graphics, RunClass.DrawUtility['points'](border, border, w - (2 * border), h - (2 * border), _options.getValue('curve').number));

				if (_displayObject == null)
				{
					_drawPreview();
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this, e);
			}
		}
		protected function _resizeLabel():Number
		{
			var sel:String = (_selected ? 'over' : '');
			var border:Number = _options.getValue(ControlProperty.BORDER).number;
			var icon_y:Number = border;
			try
			{
				var textheight:Number = _options.getValue('textheight').number;
				var textsize:Number = _options.getValue(TextProperty.TEXTSIZE).number;
				if (textheight && textsize)
				{
					var textbackalpha:Number = _options.getValue(sel + 'textbackalpha').number;
					
					var textbackcolor:String = _options.getValue(sel + 'textbackcolor').string;
					var textcolor:String = _options.getValue(sel + TextProperty.TEXTCOLOR).string;
					
					var textvalign:String = _options.getValue(TextProperty.TEXTVALIGN).string;
					var text_width:Number = 0;
					var w:Number = _options.getValue('width').number;
					if (! w) w = _data['width'];
					var text_y:Number;
					
					text_width = w - (2 * border);
						
					_labelField.width = text_width;				
					_labelField.height = textheight;		
					
					var tf:TextFormat = _labelField.defaultTextFormat;
					tf.color = RunClass.DrawUtility['colorFromHex'](textcolor);
					_labelField.defaultTextFormat = tf;
					_labelField.text = _labelField.text;
					
					
					switch(textvalign)
					{
						case 'below':
						
							text_y = _iconHeight + border;
							break;
						
						case 'above':
						
							text_y = border;
							icon_y += textheight;
							break;
						
						case 'bottom':
						
							text_y = _iconHeight + border - textheight;
							break;
						
						case 'middle':
						case 'center':
						
							text_y = border + ((_iconHeight - textheight) / 2);
							break;
					}
					_labelField.x = _labelSprite.x = border;
					_labelSprite.y = text_y;
					_labelField.y = text_y + _options.getValue(TextProperty.TEXTOFFSET).number;
					
					_labelSprite.graphics.clear();
					// RunClass.MovieMasher['msg'](this + '._resizeLabel w = ' + w + ' border = ' + border + ' dims = ' + text_width + 'x' + textheight);
					RunClass.DrawUtility['fill'](_labelSprite.graphics, text_width, textheight, RunClass.DrawUtility['colorFromHex'](textbackcolor), textbackalpha);			
				}
			//	if (isNaN(text_y)) RunClass.MovieMasher['msg'](this + '._resizeLabel ' + text_y + ' ' + textvalign + ' ' + _iconHeight + ' ' + border );
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this, e);
			}
			return icon_y;
		}
		private function __animBuffered(event:Event):void
		{
			//RunClass.MovieMasher['msg'](this + '.__animBuffered');
			__mash.removeEventListener(EventType.BUFFER, __animBuffered);
			__animTimed(null);
		}
		private function __animTimed(event:TimerEvent):void
		{
			if ((event !=  null) && (! __animatePreviews)) return;
			var buffed:Boolean = false;	
			var time:Time;
			var range:TimeRange;
			try
			{
				time = __mash.lengthTime;
				if (time != null)
				{
					time.multiply(__animFrame / PREVIEW_FRAMES);
					range = time.timeRange;
					buffed = __mash.buffered(range, true);
					if (! buffed)
					{
						__mash.buffer(range, true);
						buffed =__mash.buffered(range, true);
					}
				}
				//RunClass.MovieMasher['msg'](this + '.__animTimed buffered ' + buffed + ' length ' + __mash.lengthTime + ' time ' + time );
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__animTimed was not able to buffer', e);
			}
			try
			{
				if (buffed && __mashGo()) 
				{
					__animFrame ++;
					if (__animFrame == PREVIEW_FRAMES) __animFrame = 0;		
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__animTimed was not able to setFrame', e);
			}
		}
		private function __clipFromXML(xml:XML):IClip
		{
			var iclip:IClip = null;
		
			iclip = RunClass.Clip['fromXML'](xml);
			if (! iclip.getValue(ClipProperty.LENGTHFRAME).boolean)
			{
				iclip.setValue(new Value(RunClass.TimeUtility['fps'] * 10), ClipProperty.LENGTHFRAME);
			}
			return iclip;
		}
		private function __createMouse():void
		{
			try
			{
				
				if (_mouseSprite == null) 
				{
					_mouseSprite = new Sprite();
					addChild(_mouseSprite);
					_mouseSprite.addEventListener(MouseEvent.MOUSE_OVER, __doRollOver);
					_mouseSprite.addEventListener(MouseEvent.MOUSE_DOWN, __doPress);
				
					_mouseSprite.useHandCursor = false;
				
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__createMouse', e);
			}
		
		}
		private function __doPress(event:MouseEvent):void
		{
			try
			{
				if (! RunClass.MouseUtility['dragging']) 
				{
					RunClass.MovieMasher['instance'].stage.focus = null;
					_container.downPreview(this, event);
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__doPress', e);
			}
		}	
		private function __doRollOver(event:MouseEvent):void
		{
				
			try
			{
				if (! RunClass.MouseUtility['dragging']) 
				{
					RunClass.MovieMasher['instance'].addEventListener(MouseEvent.MOUSE_MOVE, __doMoveOver);
					__doMoveOver(event);
					//if (event != null) event.updateAfterEvent();
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__doRollOver', e);
			}
		}
		private function __doMoveOver(event:MouseEvent):void
		{
			try
			{
				if ((! RunClass.MouseUtility['dragging']))
				{
					if (_mouseSprite.hitTestPoint(event.stageX, event.stageY))
					{
						_container.overPreview(this, event);
					}
					else
					{
						RunClass.MovieMasher['instance'].removeEventListener(MouseEvent.MOUSE_MOVE, __doMoveOver);
						_container.outPreview(this, event);
					}
					//event.updateAfterEvent();
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__doMoveOver ' + event, e);
			}
		}
		private function __bufferMash(event:Event):void
		{
			try
			{
				if (__mash != null)
				{
					__mash.removeEventListener(EventType.BUFFER, __bufferMash);
					__mashGo();
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__bufferMash ' + event, e);
			}
		}
		private function __mashGo():Boolean
		{
			var went:Boolean = false;
			var time:Time;
			try
			{
				time = __mash.lengthTime;
				if (time == null)
				{
					__mash.addEventListener(EventType.BUFFER, __bufferMash);
				}
				else
				{
					time.multiply(__animFrame / PREVIEW_FRAMES);
					went = __mash.goTime(time);					
					//RunClass.MovieMasher['msg'](this + '.__mashGo goTime ' + time + ' ' + went);
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__mashGo ' + __mash + ' ' + time, e);
			}

			return went;
		}
		private static const PREVIEW_FRAMES:Number = 10;
		private static var __animatePreviews:Boolean = true;
		private var __animFrame:Number;
		private var __animTimer:Timer;
		private var __mash:IMash;
		private var __childrenSprite: Sprite;
		protected var _mouseSprite:Sprite; // background for whole clip 
		protected var _clip:IClip;
		protected var _mediaTag:XML;
		protected var _id:String;
		protected var _selected:Boolean;
		protected var _iconHeight:Number;
		protected var _iconWidth:Number;
		protected var _options:IOptions;
		protected var _maskSprite:Sprite;
		protected var _labelSprite:Sprite;
		protected var _labelField:TextField;
		protected var _container:IPreviewContainer;
		protected var _displayObject:DisplayObject;
		protected var _displayObjectContainer:Sprite;
		protected var _loader:IAssetFetcher;
		protected var _data:Object;
		protected var _iconIsModule:Boolean;
	}
}