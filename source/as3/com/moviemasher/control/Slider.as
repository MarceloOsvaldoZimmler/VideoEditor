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
	import flash.display.*;
	import flash.events.*;
	
	import com.moviemasher.type.*;
	import com.moviemasher.constant.*;
	import com.moviemasher.events.*;
	import com.moviemasher.type.*;
	import com.moviemasher.constant.*;
	import com.moviemasher.interfaces.*;
	import com.moviemasher.utils.*;
/**
* Implimentation and base class represents a sliding control for numerical values
*/
	
	public class Slider extends ControlIcon
	{
		public function Slider()
		{
			_defaults.min = '0';
			_defaults.max = '100';
			_defaults.increment = '0';
			_defaults.decimals = '-1';
			_ratioKey = 'back';
			_defaults.count = '1';
		}
		override protected function _createChildren():void
		{
			super._createChildren();
			_revealMaskSprite = new Sprite();
			addChild(_revealMaskSprite);
			_displayObjectLoad('back');
			_displayObjectLoad('reveal');
		}
		override public function initialize():void 
		{
			super.initialize();
			if (getValue('icon').empty) 
			{
				_centerIcon = true;
			}
		}
		
		
		protected function _backSize():Size
		{
			return new Size(_width, _height);
		}
		override protected function _sizeIcons():Boolean
		{
			var did_size:Boolean = false;
			try
			{
				if (_width && _height)
				{
					var size:Size = _backSize();
					if (_displayObjectSize('back', size)) did_size = true;
					if (_displayObjectSize('reveal', size)) did_size = true;
					if (_displayedObjects.reveal != null)
					{
						_displayedObjects.reveal.mask = _revealMaskSprite;
					}
					if (super._sizeIcons()) did_size = true;
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this, e);
			}
			return did_size;
		}
		
		override public function resize():void
		{
			
			
			__slideWidth = 0;
			
			_sizeIcons();
			
			if (! __slideWidth)
			{
				var wORh = _dimName('', 'width');
				var size = new Size(_width, _height);
				__slideWidth = size[wORh];
				if ( ! _centerIcon)
				{
					if (_displayedObjects.icon != null)
					{
						__slideWidth -= _displayedObjects.icon[wORh];
					}
				}
			}
			_update();
		}
		
		override protected function _update():void
		{
			super._update();
			if (_width)
			{
				__setSlide(__slidePercent);
			}
		}
		protected function _dimName(prefix:String = '', sname:String = '', post:String = ''):String
		{
			var dim_name = '';
			if (prefix.length)
			{
				dim_name += prefix;
			}
			if (getValue('vertical').boolean)
			{
				var dim_names:Object = new Object();
				dim_names['w'] = 'h';
				dim_names['h'] = 'w';
				dim_names['x'] = 'y';
				dim_names['y'] = 'x';
				dim_names['width'] = 'height';
				dim_names['height'] = 'width';
				dim_name += dim_names[sname];
			}
			else
			{
				dim_name += sname;
			}
			if (post.length)
			{
				dim_name += post;
			}
			return dim_name;
		}
		
		protected function _complexMask(mask_data:Object):void
		{
			try
			{
				if (mask_data != null)
				{
					if (_displayedObjects.reveal != null)
					{
						if (typeof(mask_data) == 'object')
						{
							var z:uint = mask_data.value.length;
							var loaded_time:Object;
							var total_size = mask_data.total;
							var x:Number, y:Number, w:Number, h:Number;
							
							var vertical:Boolean = getValue('vertical').boolean;
							var x_pos:Number;
							var w_pos:Number;
							var total_pixels:Number = this[_dimName('_', 'width')];
							_revealMaskSprite.graphics.clear();
							
							var icon_width:Number = 0;
							if ((! _centerIcon) && (_displayedObjects.icon != null))
							{
								icon_width = _displayedObjects.icon[_dimName('', 'width')];
								total_pixels -= icon_width;
									
							}
							
							RunClass.DrawUtility['setFill'](_revealMaskSprite.graphics, 0);
							for (var i:uint = 0; i < z; i++)
							{
								loaded_time = mask_data.value[i];
								x_pos = ((total_pixels * loaded_time.start) / total_size);
								w_pos = ((total_pixels * loaded_time.duration) / total_size);
								if (! _centerIcon) 
								{
									if (i)
									{
									x_pos += (icon_width / 2);
									}
									w_pos += (icon_width / 2);
									
								}
								
								y = (vertical ? x_pos:0);
								x = (vertical ? 0:x_pos);
								w = (vertical ? _width:w_pos);
								h = (vertical ? w_pos:_height);
								RunClass.DrawUtility['drawPoints'](_revealMaskSprite.graphics, RunClass.DrawUtility['points'](x, y, w, h), true);
							}
						}
						
					}
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this, e);
			}
		}
		protected var _centerIcon:Boolean = false;
		protected var __dontReveal:Boolean = false;
		protected var __pressClip:DisplayObject;
		protected var __pressOffset:Number;
		protected var __slidePercent:Number;
		protected var _revealMaskSprite:Sprite;
		protected var __slideWidth:Number = 0;
		override protected function _mouseDrag():void
		{		
			try
			{
				var percent = Math.max(0, Math.min(100, ((__pressOffset + this['mouse' + _dimName('', 'x').toUpperCase()]) * 100) /  __slideWidth));
				
				if (percent != __slidePercent)
				{
					__slidePercent = percent;
					dispatchPropertyChange(true);
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this, e);
			}
		}
		protected function _percent2Value(percent:Number):Number
		{
			var value:Number = NaN;
			if (! isNaN(percent))
			{
				
				var smaller:Number = getValue('min').number;
				var larger:Number = getValue('max').number;
				var increment:Number = getValue('increment').number;
				var i:int;
				value = smaller + ((percent * (larger - smaller)) / 100);
				if (increment)
				{
					i = Math.round(value / increment);
					value = increment * Number(i);
				}
				value = Math.max(value, Math.min(smaller, larger));
				value = Math.min(value, Math.max(smaller, larger));
				
			//	RunClass.MovieMasher['msg'](this + '._percent2Value ' + percent + ' ' + value);
			}
			return value;
		}
		override protected function _press(event:MouseEvent):void
		{
			try
			{
				if (! _disabled)
				{
					if (_displayedObjects.back)
					{
						__pressClip = _displayedObjects.icon;
						_pressedClip();
					}
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this, e);
			}
		}
		protected function _pressedClip():void
		{
			if (__pressClip != null)
			{
				var presswidth = __pressClip[_dimName('', 'width')] / 2;
				
				__pressOffset = 0;
				if (! _centerIcon) __pressOffset -= presswidth;
				if (__pressClip.hitTestPoint(RunClass.MovieMasher['instance'].mouseX, RunClass.MovieMasher['instance'].mouseY))
				{
					var cap_x:String = _dimName('', 'x').toUpperCase()
					__pressOffset += presswidth - (__pressClip['mouse' + cap_x] * __pressClip['scale' + cap_x]);
				}
			}
			_mouseDrag();
			
		}
		override protected function _release():void
		{
			try
			{
				__pressClip = null;
				dispatchPropertyChange();
				super._release();
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this, e);
			}
		}
		protected function __setReveal(percent:Number):void
		{
			
			var indeterminate:Boolean = _percentIndeterminate(percent);
			if (_width && (_revealMaskSprite != null))
			{
				_revealMaskSprite.graphics.clear();
				
				if (! indeterminate)
				{
					var icon_width = 0;
					if (_displayedObjects.icon != null)
					{
						icon_width = _displayedObjects.icon[_dimName('', 'width')];
					}
					var x_pos:Number = ((__slideWidth * percent) / 100);
					if (! _centerIcon) x_pos += (icon_width / 2);
					var vertical:Boolean = getValue('vertical').boolean;
					x_pos = Math.round(x_pos);
					RunClass.DrawUtility['fill'](_revealMaskSprite.graphics, (vertical ? _width:x_pos), (vertical ? x_pos:_height), 0x000000);
				}
			}	
		}
		protected function _percentIndeterminate(percent:Number):Boolean
		{
			return (isNaN(percent) || (percent < 0));// || (percent > 100)
		}
		protected function __setSlide(percent:Number, mc:DisplayObject = null, over_mc:DisplayObject = null):void
		{
			//__slidePercent = percent;
			if (_width && (root != null)) 
			{
				try
				{
					var indeterminate:Boolean = _percentIndeterminate(Math.floor(percent));
					
					if (mc == null) mc = _displayedObjects.icon;
					if (over_mc == null) over_mc = _displayedObjects.overicon;
					if (mc != null) 
					{
						mc.visible = ! indeterminate;
					}
					if (over_mc != null)
					{
						over_mc.visible = ! indeterminate;
					}
					if (! indeterminate)
					{
						if (__slideWidth)
						{
							var xORy:String = _dimName('', 'x');
							var wORh:String = _dimName('', 'width');
							var x_pos:Number = ((__slideWidth * percent) / 100);
							if ((mc != null) && _centerIcon && mc[wORh])
							{
								x_pos -= Math.floor(mc[wORh] / 2);
							}
							x_pos = Math.ceil(x_pos);
							if (over_mc != null)
							{
								over_mc[xORy] = x_pos;
								over_mc.visible = over_mc.hitTestPoint(RunClass.MovieMasher['instance'].mouseX, RunClass.MovieMasher['instance'].mouseY);
							}
							if (mc != null) mc[xORy] = x_pos;
						}
						
					}
					
					if (_displayedObjects.reveal && (! __dontReveal)) __setReveal(percent);
				}
				catch(e:*)
				{
					RunClass.MovieMasher['msg'](this, e);
				}
			}
		}
		protected function _value2Percent(value:Number):Number
		{
			var percent:Number = NaN;
			if (! isNaN(value))
			{
				var minimum:Number = getValue('min').number;
				percent = ((value - minimum) * 100) / (getValue('max').number - minimum);
				percent = Math.max(0, Math.min(100, percent));
			}
			return percent;
		}
		override public function getValue(property:String):Value
		{
			var value:Value;
			var string:String;
			var n:Number;
			var decimals:int;
			try
			{
				if (property == _property) 
				{
					n = _percent2Value(__slidePercent);
					string = String(n);
					decimals = getValue('decimals').number;
					if (decimals != -1)
					{
						n = string.indexOf('.');
							
						if (! decimals) 
						{
							if (n == 0) string = '0';
							else if (n > 0) string = string.substr(0, n - 1);
						}
						else
						{
							if (n == -1) 
							{
								string += '.';
								for (n = 0; n < decimals; n++)
								{
									string += '0';
								}
							}
							else if (n == 0)
							{
								string = '0' + string;
								n++;
							}
							if (n > 0) 
							{
								if (string.length > (n + decimals + 1))
								{
									string = string.substr(0, decimals + n + 1);
								}
								else
								{
									decimals = (n + decimals + 1) - string.length;
									for (n = 0; n < decimals; n++)
									{
										string += '0';
									}
								}
								
							}	
						}
							
					}
					switch (getValue('count').number)
					{
						case 2: 
							string = string + ',' + string;
							break;
						case 4:
							string = '0,' + string + ',100,' + string;
							break;
							
					}
					value = new Value(string);
				}
				else 
				{
					value = super.getValue(property);
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.getValue ' + property + ' ' + value);
			}
			return value;
		}
		override public function setValue(value:Value, property:String):Boolean
		{
			try
			{
				switch(property)
				{
					case 'mask':
						if (! __dontReveal) __dontReveal = true;
						_complexMask(value.object);
						break;
					case _property: 
						super.setValue(value, property);
						var n:Number = 0;
						if (! value.empty)
						{
							switch (getValue('count').number)
							{
								case 1:
									n = value.number;
									break;
								case 2: 
									n = Number(value.array[0]);
									break;
								case 4:
									n = Number(value.array[value.array.length - 1]);
									break;
							}
						}
						__slidePercent = _value2Percent(n);
						_update();
						break;
					default:
						super.setValue(value, property);
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.setValue ' + property + ' ' + value.string);
			}
			return false;
		}
	}
}