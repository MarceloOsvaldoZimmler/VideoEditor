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
	import flash.geom.*;
	import flash.events.*;
	import flash.display.*;
	import com.moviemasher.type.*;
	import com.moviemasher.constant.*;
	import com.moviemasher.events.*;
	import com.moviemasher.type.*;
	import com.moviemasher.constant.*;
	import com.moviemasher.interfaces.*;
	
/**
* Implimentation class represents a control for trimming clips
*/
	public class Trimmer extends Slider
	{
		public function Trimmer()
		{
			_defaults.value = '0,0';
			__dontReveal = true;
		}
		override public function getValue(property:String):Value
		{
			var value:Value;
			if (property == _property)
			{
				value = new Value(__values);
			}
			else
			{
				value = super.getValue(property);
			}
			
			
			return value;
		}
		override public function setValue(value:Value, property:String):Boolean
		{
			if (property == _property)
			{
				__indeterminateValue = (value.indeterminate || value.empty);
				if (! __indeterminateValue)
				{
					var new_values:Array = value.array;
					__values = [Number(new_values[0]), Number(new_values[1])];
				}
				if (_width) _update();
			}
			return false;
		}
		override protected function _createChildren():void
		{
			super._createChildren();
			if (! getValue('trimicon').string.length)
			{
				_defaults.trimicon = getValue('icon').string;
			}
			if (! getValue('trimovericon').string.length)
			{
				_defaults.trimovericon = getValue('overicon').string;
			}
			__values = getValue('value').array;
			_displayObjectLoad('trimicon');
			_displayObjectLoad('trimovericon');
		}
		override protected function _mouseDrag():void
		{
			try
			{
				
				var is_end:Boolean = (__pressClip.name == 'trimicon');
				
				var percent:Number = __trimPercent(is_end);
				__values[is_end ? 1 : 0] = percent;
				dispatchPropertyChange(true);
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this, e);
			}

		}
		override protected function _mouseHover(event:MouseEvent):void
		{
			try
			{
				__roll(event.stageX, event.stageY);
			
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this, e);
			}

		}
		override protected function _mouseOut():void
		{
			try
			{
				_roll(false, '');
				_roll(false, 'trim');
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this, e);
			}
		}
		override protected function _mouseOver(event:MouseEvent):void
		{ 
			// not calling supper because we trap _mouseHover
		}
		override protected function _percent2Value(percent : Number):Number
		{
			return percent;
		}
		override protected function _press(event:MouseEvent) : void
		{
			try
			{
				__pressClip = __overObject(event.stageX, event.stageY);
				//RunClass.MovieMasher['msg'](this + '._press ' + __pressClip.name);
				_pressedClip();
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this, e);
			}
		}
		override protected function _release():void
		{
			try
			{
				var is_end:Boolean = (__pressClip.name == 'trimicon');
				
				var percent:Number = __trimPercent(is_end);
				__values[is_end ? 1 : 0] = percent;
				super._release();
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this, e);
			}
		}		
		override protected function _sizeIcons():Boolean
		{
			var did_size:Boolean = false;
			if (_width && _height)
			{
				did_size = super._sizeIcons();
				if (_displayObjectSize('trimicon')) did_size = true;
				if (_displayObjectSize('trimovericon')) did_size = true;
			}
			return did_size;
		}
		override protected function _update() : void
		{
			_drawBox();

			var a:Array = new Array();
			var ob:Object;
			var percent:Number = NaN;
			var slide_percent:Number = NaN;
			
			if ((! __indeterminateValue) && _width)
			{
				ob = new Object();
				ob.start = 0;
				ob.duration = __values[0];
				a.push(ob);
				ob = new Object();
				ob.start = 100 - __values[1];
				ob.duration = __values[1];
				a.push(ob);
				percent = 100 - __values[1];
				slide_percent = __values[0];
			}
			ob = new Object();
			ob.total = 100;
			ob.value = a;
			_complexMask(ob);
			__setSlide(percent, _displayedObjects.trimicon, _displayedObjects.trimovericon);
			__slidePercent = slide_percent;
			if (_width)
			{
				__setSlide(__slidePercent);
			}
			
			/*
			var mc:DisplayObject = _displayedObjects.disicon;
			if (mc != null) 
			{
				mc.visible = _disabled;
				mc = _displayedObjects.icon;
				if (mc != null) 
				{
					mc.visible = ! _disabled;
				}
			}
			*/
			__roll(RunClass.MovieMasher['instance'].mouseX, RunClass.MovieMasher['instance'].mouseY);
		
		}
		override protected function _value2Percent(value : Number):Number
		{
			return value;
		}
		private function __overObject(xPos:Number, yPos:Number):DisplayObject
		{
			var display_object:DisplayObject = null;
			try
			{
				if (hitTestPoint(xPos, yPos))
				{
					if (_displayedObjects.trimicon.hitTestPoint(xPos, yPos))
					{
						display_object = _displayedObjects.trimicon;
					}
					else if (_displayedObjects.icon.hitTestPoint(xPos, yPos))
					{
						display_object = _displayedObjects.icon;
					}
					else 
					{
						var pt:Point = new Point(xPos, yPos);
						pt = globalToLocal(pt);
						if (pt.x < _displayedObjects.icon.x)
						{
							display_object = _displayedObjects.icon;
						}
						else if (pt.x > _displayedObjects.trimicon.x)
						{
							display_object = _displayedObjects.trimicon;
						}
						else 
						{
							var distance:Number = pt.x - (_displayedObjects.icon.x + _displayedObjects.icon.width);
							if (distance > (_displayedObjects.trimicon.x - pt.x))
							{
								display_object = _displayedObjects.trimicon;
							}
							else
							{
								display_object = _displayedObjects.icon;
							}
						}
					}	
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this, e);
			}

			return display_object;
		}
		private function __roll(xPos:Number, yPos:Number):void
		{
			var prefix:String = '';
			var not_prefix:String = '';
			var display_object:DisplayObject = __overObject(xPos, yPos);
			if ((display_object != null) && (display_object.name == 'trimicon'))
			{
				prefix = 'trim';
			}
			else
			{
				not_prefix = 'trim';
			}
			//RunClass.MovieMasher['msg'](this + '.__roll ' + prefix + ' ' + (display_object != null) + ' ' + ((display_object != null) ? display_object.name : 'none'));
			_roll((display_object != null), prefix);
			_roll(false, not_prefix);
		
		}
		private function __trimPercent(is_end:Boolean):Number
		{
			var percent:Number = Math.max(0, Math.min(100, ((__pressOffset + mouseX) * 100) /  __slideWidth));
			if (is_end)
			{
				percent = 100 - Math.max(percent, __values[0] + 1);
			}
			else
			{
				percent =  Math.min(percent, (100 - __values[1]) - 1);
			}
			return percent;
		}
		private var __indeterminateValue : Boolean = true;
		private var __values : Array;
	}
}
