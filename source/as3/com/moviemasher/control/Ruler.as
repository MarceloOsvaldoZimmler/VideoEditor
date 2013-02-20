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
	import flash.events.*
	import flash.geom.*
	import com.moviemasher.type.*;
	import com.moviemasher.constant.*;
	import com.moviemasher.events.*;
	import com.moviemasher.type.*;
	import com.moviemasher.constant.*;
	import com.moviemasher.interfaces.*;
/**
* Implimentation class represents a time-based scrubber control
*/
	public class Ruler extends Slider
	{
		public function Ruler()
		{
			__incrementers = new Vector.<IIncrement>();
			_defaults.bind = 'player.location';
			
			_defaults[TextProperty.FONT] = 'default';
			_defaults[TextProperty.TEXTCOLOR] = '0';
			_defaults[TextProperty.TEXTSIZE] = '9';
			_defaults[TextProperty.TEXTALIGN] = 'center';
			_defaults[TextProperty.PATTERN] = '{time}';
			_defaults[TextProperty.TEXTOFFSET] = '0';
			
			_centerIcon = true;
			_allowFlexibility = true;
			
			__incrementContainer = new Sprite();
			addChild(__incrementContainer);
							
		}
		override public function makeConnections():void
		{
			super.makeConnections();
			__timeline = RunClass.MovieMasher['getByID'](ReservedID.TIMELINE) as Timeline;
			if (__timeline != null)
			{
				addEventBroadcaster('hscroll', __timeline);
				addEventBroadcaster('refresh', __timeline);
				setValue(__timeline.getValue('hscroll'), 'hscroll');
				addEventBroadcaster('zoom', __timeline);
				setValue(__timeline.getValue('zoom'), 'zoom');
			}
			else RunClass.MovieMasher['msg'](this + '.makeConnections with no control having id of timeline');
			var propertied:IPropertied = RunClass.MovieMasher['getByID'](ReservedID.PLAYER) as IPropertied;
			if (propertied != null)
			{
				addEventBroadcaster(ClipProperty.LENGTH, propertied);
				setValue(propertied.getValue(ClipProperty.LENGTH), ClipProperty.LENGTH);
			}
			//else RunClass.MovieMasher['msg'](this + '.makeConnections with no control having id of player');
			
		}

	
		override protected function _createChildren():void
		{
			super._createChildren();
			_displayObjectLoad('ruleicon');
			_displayObjectLoad('ruleovericon');
			if (! getValue('incrementsymbol').empty)
			{
				_displayObjectLoad('incrementsymbol');
				_displayObjectLoad(TextProperty.FONT);
			}
			__iconContainer = new Sprite();
			__iconContainer.mouseChildren = false;
			addChild(__iconContainer);
		}
		override public function setValue(value:Value, property:String):Boolean
		{
					
			switch(property)
			{
				case 'refresh':
				case 'length':
				case 'zoom':
				case 'hscroll':
					if (_height && (__timeline != null)) 
					{
						__layoutIncrementers();
					}
					value = new Value(__location);
					property = PlayerProperty.LOCATION;
					super.setValue(value, property);
					break;
				case PlayerProperty.LOCATION:
					__location = value.number;
					// intentional fallthrough to default
				default:
					super.setValue(value, property);
			}
			
			return false;
			
		}
		override public function resize():void
		{
			super.resize();
			
			setValue(new Value(__location), PlayerProperty.LOCATION);
			if (_width && _height && (__timeline != null))
			{
				var rect:Rectangle;
				var pt:Point = new Point(0, y);
				pt = localToGlobal(pt);
				
				var h : Number = pt.y;
				
				pt = new Point(0, __timeline.height + __timeline.y);
				pt = __timeline.localToGlobal(pt);
				
				h = pt.y - h;
				
				if (h < 0)
				{
					_width = 0;
					_height = 0;
				}
				else
				{
					var mc:DisplayObject;
					var size:Size = new Size(Infinity, h);
					if (h < 2880)
					{
					
						try
						{
							_displayObjectSize('ruleicon', size, __iconContainer);
							_displayObjectSize('ruleovericon', size, __iconContainer);
							
							__syncRuler();
							__layoutIncrementers();
						}
						catch(e:*)
						{
							RunClass.MovieMasher['msg'](this, e);
						}
					}
				}
			}
		}
		override protected function _backSize():Size
		{
			return new Size(Infinity, _height);
		}
		override protected function _percent2Value(percent : Number):Number
		{
			if (__timeline == null)
			{
				return NaN;
			}
			var value:Number = ((_width * percent) / 100);
			value += __timeline.getValue('xscroll').number;
			value = __timeline.pixels2Time(value);
			return value;
		}
		override protected function _mouseOver(event:MouseEvent):void
		{
			try
			{
				super._mouseOver(event);
				__syncRuler();
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
				super._mouseOut();
				__syncRuler();
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this, e);
			}

		}
		override protected function __setSlide(percent : Number, mc : DisplayObject= null, over_mc : DisplayObject = null):void
		{
			
			var per:Number = _value2Percent(_percent2Value(percent));
		//	RunClass.MovieMasher['msg'](this + '.__setSlide ' + percent + ' -> ' + per);
					
			super.__setSlide(per, mc, over_mc);
			__syncRuler();
		}
		override protected function _update():void
		{
			super._update();
			__syncRuler();
		}
		override protected function _value2Percent(location : Number):Number
		{
			if (__timeline == null)
			{
				return 0;
			}
			var percent:Number = __timeline.time2Pixels(location);
			percent -= __timeline.getValue('xscroll').number;
			percent = (percent / _width) * 100;
			return percent;
		}
		private function __incrementWidthFromTime(now:Number):Number
		{
			var w:Number = 0;
			if (__increment == null)
			{
				var loader:IAssetFetcher;
				var url:String = getValue('incrementsymbol').string;
				if (url.length)
				{
					loader = RunClass.MovieMasher['assetFetcher'](url, 'swf');
					__incrementClass = loader.classObject(url, 'display');
					__increment = __newIncrementInstance();
				}
			}
			if (__increment != null)
			{
				__increment.metrics = new Size(Infinity, _height);
				__increment.time = now;				
				w = __increment.metrics.width;
			//	RunClass.MovieMasher['msg'](this + '.__incrementWidthFromTime ' + w);
			}
			return w;
		}
		private function __newIncrementInstance():IIncrement
		{
			var increment:IIncrement = null;
			if (__incrementClass != null)
			{
				increment = new __incrementClass() as IIncrement;
				if (increment != null)
				{
					increment.owner = this;
					/*
					increment.font = getValue(TextProperty.FONT).string;
					increment.color = getValue(TextProperty.TEXTCOLOR).string;
					increment.size = getValue(TextProperty.TEXTSIZE).number;
					increment.textalign = getValue(TextProperty.TEXTALIGN).string;
					increment.pattern = getValue(TextProperty.PATTERN).string;
					increment.textoffset = getValue(TextProperty.TEXTOFFSET).number;
					*/
				}				
			}	
			return increment;
		}
		private function __layoutIncrementers():void
		{
			
			var xscroll:Number = __timeline.getValue('xscroll').number;
			var start_time:Number = __timeline.pixels2Time(xscroll);
			var end_time:Number = start_time + __timeline.pixels2Time(_width);
			var i:int = 0;
			if (end_time)
			{
			
				var increment_width:Number = __incrementWidthFromTime(end_time) + 10; // some padding!
				if (__incrementClass != null)
				{
					var interval:Number = getValue('increment').number;
					var max_incrementers:Number = Math.ceil(_width / increment_width);
					var interval_width:Number =  __timeline.time2Pixels(interval);
					var increment_time:Number = __timeline.pixels2Time(increment_width)
					var increment:IIncrement;
					
					start_time += interval - (start_time % interval);
					for (i = 0; i < max_incrementers; i++)
					{
						if (i == __incrementers.length)
						{
							increment = __newIncrementInstance();
							if (increment != null)
							{
								__incrementContainer.addChild(increment.displayObject);
								__incrementers.push(increment);
							}
						}
						else 
						{
							increment = __incrementers[i];
						}
						increment.metrics = new Size(Infinity, _height);
						increment.time = start_time;
						increment.displayObject.x =  __timeline.time2Pixels(start_time) - xscroll;
						start_time = Math.ceil((start_time + increment_time) / interval) * interval;
						
					
					}	
					//if (increment != null) RunClass.MovieMasher['msg'](this + '.__layoutIncrementers ' + _width + 'x' + _height + ' ' + increment.displayObject.width + 'x' + increment.displayObject.height + ' ' + increment.metrics.width + 'x' + increment.metrics.height);
					setChildIndex(__incrementContainer, getChildIndex(_displayedObjects.icon) - 1);	
					
				}
			}
			var target_length:int = i;
			for (;i < __incrementers.length; i++)
			{
				increment = __incrementers[i];
				
				__incrementContainer.removeChild(increment.displayObject);
			}
			__incrementers.length = target_length;
		}
		private function __syncRuler()
		{

			var ruleicon_mc:DisplayObject = _displayedObjects.ruleicon;
			var ruleovericon_mc:DisplayObject = _displayedObjects.ruleovericon;
			var icon_mc:DisplayObject = _displayedObjects.icon;
			var overicon_mc:DisplayObject = _displayedObjects.overicon;

			if (ruleicon_mc != null)
			{
				ruleicon_mc.visible = icon_mc.visible;
				if (ruleicon_mc.visible)
				{
					ruleicon_mc.x = icon_mc.x + Math.ceil((icon_mc.width - ruleicon_mc.width) / 2);
				}
			}
			if (ruleovericon_mc != null)
			{
				ruleovericon_mc.visible = overicon_mc.visible;
				ruleovericon_mc.x = overicon_mc.x + Math.ceil((overicon_mc.width - ruleovericon_mc.width) / 2);
			}
		}
		private var __incrementContainer:Sprite;
		private var __increment:IIncrement;
		private var __iconContainer:DisplayObjectContainer;
		private var __timeline:Timeline;
		private var __incrementClass:Class;
		private var __incrementers:Vector.<IIncrement>;
		private var __location:Number = 0;
	}
}