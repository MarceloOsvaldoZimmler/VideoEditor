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
	import flash.events.*;
	import flash.text.*;
	import flash.display.*;
	import flash.geom.*;
	import com.moviemasher.utils.*;
	import com.moviemasher.events.*;
	import com.moviemasher.type.*;
	import com.moviemasher.constant.*;
	import com.moviemasher.interfaces.*;

/**
* Implimentation class represents a simple text control
*/
	public class Text extends Icon
	{
		public function Text()
		{
			_defaults.hscrollunit = '10';
			_defaults.vscrollunit = '1';
			_defaults.textsize = '12';
			_defaults.textalign = 'left';
			_defaults.textvalign = '';
			_defaults.font = 'default';
			_defaults.textcolor = '000000';
			_defaults.multiline = '0';
			_defaults.wrap = '1';
			
			_allowFlexibility = true;
			_scroll = new Rectangle(-1, -1, -1, -1);
			_viewSize = new Size();
			
		}
		override public function getValue(property:String):Value
		{
			var n:Number = NaN;
			switch (property)
			{
				case 'viewwidth':
					n = _width;
					break;
				case 'viewheight':
					n = _height;
					break;
				case 'itemwidth':
					n = (_scroll.width - (_scroll.x + getValue('hscrollpadding').number));
					break;
				case 'itemheight':
					n = (_scroll.height - (_scroll.y + getValue('vscrollpadding').number));
					break;
				case 'xscroll':
					n = _scroll.x;
					break;
				case 'yscroll' :
					n = _scroll.y;
					break;
				case 'vscroll' :
					if ((! _hidden) && _viewSize.height && (_viewSize.height < _scroll.height))
					{
						n = (_scroll.y * 100) / (_scroll.height - _viewSize.height);
					}
					break;
				case 'hscroll' :
					if ((! _hidden) && _viewSize.width && (_viewSize.width < _scroll.width))
					{
						n = (_scroll.x  * 100) / (_scroll.width - _viewSize.width);
					}
					else n = 0;
					break;
				case 'vscrollsize' :
					if ((! _hidden) && _viewSize.height && (_viewSize.height < _scroll.height))
					{
						n = (_viewSize.height * 100) / _scroll.height;
					}
					else n = 0;
					
					break;
				case 'hscrollsize' :
					if ((! _hidden) && _viewSize.width && (_viewSize.width < _scroll.width))
					{
						n = (_viewSize.width * 100) / _scroll.width;
					}
					else n = 0;
					break;
				
			}
			var value:Value = (isNaN(n) ? super.getValue(property) : new Value(n));
			
			return value;
		}
		override public function setValue(value:Value, property:String):Boolean
		{
			try
			{
				switch (property)
				{
					case 'vscrollunit' :
					case 'hscrollunit' :
						__doScroll(value.number, (property.substr(0, 1) == 'h'));
						break;
					case 'hscroll':
					case 'vscroll':
						var xORy:String = ((property == 'hscroll') ? 'x' : 'y');
						var wORh:String = ((property == 'hscroll') ? 'width' : 'height');
						_setScrollPosition(xORy, Math.round((value.number * (_scroll[wORh] - _viewSize[wORh])) / 100));
						break;
					default:
						super.setValue(value, property);
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.setValue ' + property + ' ' + value.string, e);
			}
			
			return false;
		
		}
		override public function makeConnections():void
		{
			var pattern:String = getValue(TextProperty.PATTERN).string;
			var refs,obs:Array;
			var ref:String;
			var property:String;
			var valued:IValued;
			if (pattern.length)
			{
				refs =  RunClass.ParseUtility['bracketed'](pattern);
				for each (ref in refs)
				{
					obs = ref.split('.');
					if (obs.length > 1)
					{
						property = obs.pop();
						ref = obs.join('.');
						valued = RunClass.MovieMasher['getByID'](ref) as IValued;
						if (valued != null)
						{
							addEventBroadcaster(property, valued);
							
						}
						else 
						{
							if (! RunClass.MovieMasher['getOption'](ref, property).length)
							{
								RunClass.MovieMasher['msg'](this + '.makeConnections pattern reference target not found: ' + ref);
							}
						}
					}
				}
			}
			super.makeConnections();
			
		}
		override public function initialize() : void 
		{
			super.initialize();
			RunClass.FontUtility['formatField'](_textField, this);
			_textField.wordWrap = _textField.multiline = getValue('wrap').boolean;
			
			var can_be_disabled:Boolean = (getValue('disable').string.length > 0);
			var disforecolor:String = getValue('disforecolor').string;
			var overforecolor:String = getValue('overforecolor').string;
			_hasColorStates = ((can_be_disabled && disforecolor.length) || overforecolor.length);
		}
		override public function resize():void
		{
			super.resize();
			
			_textField.width = _width;
			_textField.height = _height;
			var x_pos:Number = 0;
			var y_pos:Number = 0;
			if (_textField.textHeight)
			{
				switch (getValue(TextProperty.TEXTVALIGN).string)
				{
					case 'top':
						break;
					case 'bottom':
						y_pos = _height - (_textField.textHeight);
						break;
					default:
						y_pos = Math.round((_height - (_textField.textHeight + 4)) / 2);
				}
			}
			if (hasEventListener('hscroll')) x_pos = Math.max(x_pos, 0);
			if (hasEventListener('vscroll')) y_pos = Math.max(y_pos, 0);
			_textField.x = x_pos;
			_textField.y = y_pos;
			_viewSize = new Size(_width, (_textField.bottomScrollV - _textField.scrollV));
		}
		protected function _adjustScroll():void
		{
			__iAmScrolling = true;
			_textField.scrollV = 1 + _scroll.y;//1 + Math.ceil(_scroll.y / (_textField.maxScrollV - 1));
			_textField.scrollH = _scroll.x;
			__iAmScrolling = false;
		}
		override protected function _createChildren():void
		{
			super._createChildren();
			_textField = new TextField();
			_textField.addEventListener(Event.SCROLL, __scrollField);
			
			addChild(_textField);
			_textField.text = '';
			var align:String = getValue('autosize').string;
			if (align.length) _textField.autoSize = TextFieldAutoSize[align.toUpperCase()];
			_displayObjectLoad(TextProperty.FONT);
		}
		
		final protected function _setScrollPosition(xORy:String, pixels:Number, redraw:Boolean = false):Boolean
		{
			var did_draw:Boolean = false;
			if (redraw || (_scroll[xORy] != pixels))
			{
				_scroll[xORy] = pixels;
				var hORv:String = ((xORy == 'x') ? 'h' : 'v');
				_dispatchEvent(hORv + 'scroll');
				_adjustScroll();
				did_draw = true;
			}
			return did_draw;
		}
		override protected function _sizeIcons():Boolean
		{
			var did_size:Boolean = super._sizeIcons();
			if (did_size)
			{
				// I have background graphics which may now be above the text field
				
				if ((_textField != null) && contains(_textField) && (getChildIndex(_textField) < (numChildren - 1)))
				{
					removeChild(_textField);
					addChild(_textField);
				}
			}
			return did_size;
		}
		
		override protected function _roll(tf : Boolean, prefix : String = ''):void
		{
			if (_hasColorStates) __adjustStateColor(tf);
			super._roll(tf, prefix);
		}
		private function __adjustStateColor(tf : Boolean):void
		{	
			var state:String = '';
			if (_disabled) state = 'dis';
			else if (tf) state = 'over';
			
			var s:String;
			var color:String;
			
			color = getValue(state + 'forecolor').string;
			if ((! color.length) && state.length) color = getValue('forecolor').string;
			
			var color_num:Number = RunClass.DrawUtility['colorFromHex'](color);
			var format:TextFormat = _textField.defaultTextFormat;
			//var key:String;

			if (format.color != color_num)
			{
				format.color = color_num;
				_textField.defaultTextFormat = format;
				
				_updateText(true);
				/*
				if (getValue('html').boolean)
				{
					s = _textField.htmlText;
					_textField.htmlText = '';
					_textField.htmlText = s;
				}
				else
				{
					s = _textField.text;
					_textField.text = '';
					_textField.text = s;
				}
				*/
			}
		}
		final protected function _setScrollDimension(wORh:String, pixels:Number):Boolean
		{
			var did_draw:Boolean = false;
				
			if (_resizing || (_scroll[wORh] != pixels))
			{
				_scroll[wORh] = pixels;
				var hORv:String = ((wORh == 'width') ? 'h' : 'v');
				var xORy:String = ((wORh == 'width') ? 'x' : 'y');
				var prop:String = hORv + 'scrollsize';
				var value:Value = getValue(prop);
				_dispatchEvent(prop, value);
				var scroll:Number = 0;
				if (pixels > _viewSize[wORh])
				{
					scroll = _scroll[xORy];
					scroll = Math.min(pixels - _viewSize[wORh], scroll);
					scroll = Math.max(0, scroll);
				}
				
				did_draw = _setScrollPosition(xORy, scroll, true);
				if (! did_draw)
				{
					_adjustScroll();
					did_draw = true;
				}
			}
			return did_draw;
		}
		override protected function _update():void
		{
			super._update();
			_updateText();
		}
		protected function _updateText(force:Boolean = false):void
		{
			var pattern:String = getValue(TextProperty.PATTERN).string;
			if (pattern.length) pattern = RunClass.ParseUtility['brackets'](pattern, null, true);
			else pattern = getValue('text').string;
			var key:String = (getValue('html').boolean ? 'htmlText' : 'text');
			if (! force) force = (_textField[key] != pattern);
			if (force)
			{
				_textField[key] = pattern;
				_updateTextDimensions();
			}
		}
		protected function _updateTextDimensions():void
		{
			_setScrollDimension('width', _textField.textWidth);
			_setScrollDimension('height', _textField.maxScrollV + _viewSize.height - 1);//textHeight);
		
		}
		protected function __doScroll(dir:Number, horizontal:Boolean):Number
		{
		
			var did_scroll:Number = 0;
			try
			{
				var wORh = (horizontal ? 'width' : 'height');
				var xORy = (horizontal ? 'x' : 'y');
				if (_scroll[wORh])
				{
					var cur_pos = _scroll[xORy];
					var new_pos = cur_pos + (dir * getValue((horizontal?'h':'v') + 'scrollunit').number);
					if (new_pos > (_scroll[wORh] - _viewSize[wORh]))
					{
						new_pos = _scroll[wORh] - _viewSize[wORh];
					}
					else if (new_pos < 0)
					{
						new_pos = 0;
					}
					if (new_pos != cur_pos)
					{
						did_scroll = _scrollTo(horizontal,new_pos);
					}
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this, e);
			}
			return did_scroll;
		}
		protected function _scrollTo(horizontal : Boolean, position : Number):Number
		{
			var scrolled = 0;
			var xORy:String = (horizontal ? 'x' : 'y');
			if (! isNaN(position))
			{
				position = Math.max(0, position);
				scrolled = position - _scroll[xORy];
				_setScrollPosition(xORy, position);
			}
			return scrolled;
		}
		private function __scrollField(event:Event):void
		{
			_setScrollPosition('x',  _textField.scrollH);
			_setScrollPosition('y', _textField.scrollV - 1);
			
		}
		private var __iAmScrolling:Boolean = false;
		protected var _textField : TextField;
		protected var _scroll:Rectangle;
		protected var _viewSize : Size;
		protected var _hasColorStates:Boolean;
	}
}