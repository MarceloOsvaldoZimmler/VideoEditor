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
	
	import flash.geom.*;
	import flash.events.*;
	import com.moviemasher.utils.*;
	import com.moviemasher.type.*;
	import com.moviemasher.constant.*;
	import com.moviemasher.interfaces.*;
	import com.moviemasher.type.*;
	import com.moviemasher.constant.*;
/**
* Implimentation class represents a control for editing volume and fade properties
*/
	public class Plotter extends ControlIcon
	{
		public function Plotter()
		{
			_defaults.controlangle = '90';
			_defaults.controlcolor = 'CCCCCC';
			_defaults.controlgrad = '40';
			_defaults.controlsize = '10';
			_defaults.multiple = '1';
			_allowFlexibility = true;
			_ratioKey = '';
		}
		override protected function _createChildren():void
		{
			__back_mc = new Sprite();
			addChild(__back_mc);
			__lines_mc = new Sprite();
			addChild(__lines_mc);
			__ovals_mc = new Sprite();
			addChild(__ovals_mc);
			addEventListener(MouseEvent.MOUSE_DOWN, __mouseDown);
			_createTooltip();
			
			
		}
		override public function getValue(property:String):Value
		{
			var value:Value;
			if (property == _property)
			{
				value = new Value(__value);
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
				if (value.indeterminate) 
				{
					// indeterminate value from multi selection
					__value = null;
				}
				else 
				{
					if (value.empty) 
					{
						value = getValue(property);
						if (value.empty) 
						{
							value = new Value(getValue('multiple').boolean ? '0,100,100,100':'50,50');
						}
					}
					__value = RunClass.PlotUtility['string2Plot'](value.string);
				}
				__plotValue();
			}
			else 
			{
				super.setValue(value, property);
			}
			return false;
		}
		override public function resize():void
		{
			super.resize();
			if (! (_width && _height)) return;
			__back_mc.graphics.clear();
			RunClass.DrawUtility['fill'](__back_mc.graphics, _width, _height, 0, 0);
			
			//DrawUtility.gradientBox(__back_mc.graphics, this, _width, _height);
			
			
			var padding:Number = getValue(ControlProperty.PADDING).number;
			var controlsize:Number = getValue('controlsize').number;
			
			__plotWidth = _width - ((2 * padding) + controlsize);
			__plotHeight = _height - ((2 * padding) + controlsize);
			__ovals_mc.x = __ovals_mc.y = __lines_mc.x = __lines_mc.y = padding + (controlsize / 2);
			
			__plotValue();
		}
		private function __copyArray(a1:Array):Array
		{
			var a2:Array = new Array();
			if (a1 != null)
			{
				var z:uint = a1.length;
				for (var k:uint = 0; k < z; k++)
				{ 
					a2[k] = a1[k]; 
				}
			}
			return a2;
		}
		override protected function _press(event:MouseEvent):void
		{
			try
			{
				if (__value != null)
				{
					var pt:Point = new Point(event.stageX, event.stageY);
					pt = globalToLocal(pt);
					var padding:Number = getValue(ControlProperty.PADDING	).number;
					if ((pt.x > padding) && (pt.x < (_width - padding)) && (pt.y > padding) && (pt.y < (_height - padding)))
					{
						__origValue = __copyArray(__value);
						if (! getValue('multiple').boolean) __dragIndex = 0;
						else if (__ovals_mc.hitTestPoint(event.stageX, event.stageY))
						{
							var z = __value.length;
							var oval_name;
							var oval:Sprite;
							for (var i:int = 0; i < z; i += 2)
							{
								oval_name = 'oval_' + i;
								oval = __ovals_mc.getChildByName(oval_name) as Sprite;
								
								if (oval.hitTestPoint(event.stageX, event.stageY))
								{
									__dragIndex = i;
									break;
								}
							}
						}
						_mouseDrag();
					}
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this, e);
			}

		}
		override protected function _mouseDrag():void
		{
			try
			{
				__didDrag = true;
				var pt:Point = new Point(RunClass.MouseUtility['x'], RunClass.MouseUtility['y']);
				pt = globalToLocal(pt);
				var	val:Array = __copyArray(__origValue);
				var is_outer:Boolean = false;
				var did_exist:Boolean = (__dragIndex > -1);
				
				if (did_exist) is_outer = ( (__dragIndex == 0) || (__dragIndex == (__origValue.length - 2)));
				var mouse_inside:Boolean = ((pt.x > 0) && (pt.x < _width) && (pt.y > 0) && (pt.y < _height));
				if ((! is_outer) && (! mouse_inside))
				{
					if (did_exist) val.splice(__dragIndex, 2);
				}
				else
				{
					var new_percents:Array = __pixels2Percents([pt.x - __ovals_mc.x, pt.y - __ovals_mc.y]);
					if (did_exist)
					{
						if (is_outer && getValue('multiple').boolean) new_percents[0] = __origValue[__dragIndex];
						val.splice(__dragIndex, 2);
					}
					var z:uint = val.length;
					var insert_index:int = __dragIndex;
					
					for (var i = 0; i < z; i += 2)
					{
						if (val[i] > new_percents[0])
						{
							insert_index = i;
							break;
						}
					}
					val.splice(insert_index, 0, new_percents[1]);
					val.splice(insert_index, 0, new_percents[0]);
				}	
				if (RunClass.MouseUtility['shiftIsDown'])
				{
					var n:Number = (val[0] + val[1]) / 2;
					val[0] = val[1] = n;
				}
				__value = val;
				__plotValue();
				dispatchPropertyChange(true);
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
				__dragIndex = -1;
				if (__didDrag) dispatchPropertyChange();
				__didDrag = false;
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this, e);
			}

		}
		private function __percents2Pixels(a:Array):Array
		{
			return [Math.round((a[0] * __plotWidth) / 100), Math.round(((100 - a[1]) * __plotHeight) / 100)];
		}
		private function __pixels2Percents(a:Array):Array
		{
			return [Math.max(0, Math.min(100, Math.round((a[0] * 100) / __plotWidth))), Math.max(0, Math.min(100, Math.round(((__plotHeight - a[1]) * 100) / __plotHeight)))];
		}
		private function __plotValue():void
		{
			if (! (_width && _height)) return;
			
			var z:Number;
			var i:Number = 0;
			var line_name:String;
			var oval_name:String;
			var mc:Sprite;
			var oval_mc:Sprite;
				
			if (__value != null)
			{
				z = __value.length;
				var controlgrad:Number = getValue('controlgrad').number;
				var controlsize:Number = getValue('controlsize').number;
				var controlangle:Number = getValue('controlangle').number;
				var controlcolor:String = getValue('controlcolor').string;
				var half_oval = controlsize / 2;
				var val;
				var line_params;
				var color_number:Number = RunClass.DrawUtility['colorFromHex'](controlcolor);
				var control_fill:Object;
				var line_hi = 0;
				var line_low = control_fill;
				if (controlgrad)
				{
					control_fill = RunClass.DrawUtility['gradientFill'](controlsize, controlsize, color_number, controlgrad, controlangle);
					line_hi = control_fill.colors[0];
					line_low = control_fill.colors[control_fill.colors.length - 1];
				}
				for (; i < z; i += 2)
				{
					val = __percents2Pixels([__value[i], __value[i + 1]]);
					
					oval_name = 'oval_' + i;
					oval_mc = __ovals_mc.getChildByName(oval_name) as Sprite;
					if (oval_mc == null) 
					{
						oval_mc = new Sprite();
						oval_mc.name = oval_name;
						__ovals_mc.addChild(oval_mc);
						
						if (controlgrad)
						{
							RunClass.DrawUtility['setFillGrad'](oval_mc.graphics, control_fill);
						}
						else
						{
							RunClass.DrawUtility['setFill'](oval_mc.graphics, color_number);
						}
						RunClass.DrawUtility['drawPoints'](oval_mc.graphics, RunClass.DrawUtility['points'](-half_oval, -half_oval, controlsize, controlsize, half_oval));
					}
					oval_mc.x = val[0];
					oval_mc.y = val[1];
					if (i)
					{
						line_name = 'line_' + i;
						mc = __lines_mc.getChildByName(line_name) as Sprite;
						
						if (mc == null) 
						{
							mc = new Sprite();
							mc.name = line_name;
							__lines_mc.addChild(mc);
							
						}
						mc.graphics.clear();
						oval_mc = __ovals_mc.getChildByName('oval_' + (i - 2)) as Sprite;
						line_params = [{x: oval_mc.x, y: oval_mc.y}, {x: val[0], y: val[1]}];
						RunClass.DrawUtility['setLine'](mc.graphics, 3, line_low);
						RunClass.DrawUtility['drawPoints'](mc.graphics, line_params, false);
						if (line_hi)
						{
							RunClass.DrawUtility['setLine'](mc.graphics, 1, line_hi);
							RunClass.DrawUtility['drawPoints'](mc.graphics, line_params, false);
						}
					}
				}
			}
			z = __highest;
			__highest = i;
			for (; i < z; i++)
			{
				line_name = 'line_' + i;
				oval_name = 'oval_' + i;
				mc = __ovals_mc.getChildByName(oval_name) as Sprite;
				if (mc != null)
				{
					__ovals_mc.removeChild(mc);
				}
				mc = __lines_mc.getChildByName(line_name) as Sprite;
				if (mc != null)
				{
					__lines_mc.removeChild(mc);
				}
				
			}
		}
		private var __back_mc:Sprite;
		private var __didDrag:Boolean = false;
		private var __dragIndex:int = -1;
		private var __highest:Number = 0;
		private var __lines_mc:Sprite;
		private var __origValue:Array;
		private var __ovals_mc:Sprite
		private var __plotWidth:Number;
		private var __plotHeight:Number;
		private var __value:Array;
	}
}