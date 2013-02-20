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
	import com.moviemasher.utils.*;
	import com.moviemasher.type.*;
	import com.moviemasher.display.*;
	import com.moviemasher.constant.*;
	import flash.display.*;
	import flash.events.*;
	import flash.geom.*;
	import com.moviemasher.type.*;
	import com.moviemasher.constant.*;
	import com.moviemasher.interfaces.*;
	import com.moviemasher.events.*;
/**
* Implimentation class represents a color picker control
*/
	public class Picker extends ControlIcon
	{
		public function Picker()
		{
			_defaults.value = '000000';
			_allowFlexibility = true;
	
		}
		override protected function _createChildren():void
		{	
			_displayObjectLoad('back');
			
			__chip_mc = new Sprite();
			addChild(__chip_mc);
			__bm_bevel_mc = new Sprite();
			addChild(__bm_bevel_mc);
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
				__indeterminateValue = value.indeterminate;
				__value = value.string;
			}
			super.setValue(value, property);
			return false;
		}
		override public function resize():void
		{
			if (! (_width && _height)) return;
			var icon_size = _height;	
			__chipSize = _height - 2;	
			var spacing:Number = getValue(ControlProperty.SPACING).number;
			__colorWidth = _width - (icon_size + 2 + spacing);
			__bm_bevel_mc.x = icon_size + spacing;
			__bevelClip(__bm_bevel_mc, 0, 0, _width - (icon_size + spacing), icon_size);
	
			
			_displayObjectSize('back', new Size(__colorWidth, icon_size - 2));
			
			__bm_mc = _displayedObjects.back as Bitmap;
			if (__bm_mc != null)
			{
				__bm_mc.x = __bm_bevel_mc.x + 1;
				__bm_mc.y = __bm_bevel_mc.y + 1;
			
			}
			
			
			__chip_mc.graphics.clear();
			super.resize();
		}
		override protected function _update():void
		{
			super._update();
			if (__chip_mc.visible = (! __indeterminateValue))
			{
				__chip_mc.graphics.clear();
				RunClass.DrawUtility['fillBox'](__chip_mc.graphics, 1, 1, __chipSize, __chipSize, RunClass.DrawUtility['colorFromHex'](__value));
				var icon_size = height;	
				__bevelClip(__chip_mc, 0, 0, icon_size, icon_size, true);
			}
		}
		private function __bevelClip(clip, x, y, w:Number = 0, h:Number = 0, concave:Boolean = false, depth:Number = 1):void
		{
			
			var up_color = (concave ? 0x000000:0xFFFFFF);
			var down_color =  (concave ? 0xFFFFFF:0x000000);
			
			RunClass.DrawUtility['fillBox'](clip.graphics, x, y, w, depth, up_color, 50);
			RunClass.DrawUtility['fillBox'](clip.graphics, x, y + depth, depth, h - depth, up_color, 50);
		
			RunClass.DrawUtility['fillBox'](clip.graphics, x + w - depth, y + depth, depth, h - depth, down_color, 50);
			RunClass.DrawUtility['fillBox'](clip.graphics, x + depth, y + h - depth, w - (depth * 2), depth, down_color, 50);
		
		}
		override protected function _press(event:MouseEvent):void
		{
			_mouseDrag();
		}
		private function __colorUnderDisplay(display_object:DisplayObject, pt:Point, matrix:Matrix = null):Number
		{
			var pixel:Number = NaN;
			var bitmap_data:BitmapData;
			
			bitmap_data = new BitmapData(display_object.width, display_object.height, true, 0x00000000);
			bitmap_data.draw(display_object, matrix);
			pt = display_object.globalToLocal(pt);
			if (matrix != null) pt = matrix.transformPoint(pt);
			pixel = bitmap_data.getPixel(pt.x, pt.y);
			bitmap_data.dispose();
			//RunClass.MovieMasher['msg'](this + '.__colorUnderDisplay ' + display_object + ' ' + RunClass.DrawUtility['hexFromColor'](pixel));
			return pixel;	
		}
		override protected function _mouseDrag():void
		{
			try
			{
				var pixel:Number = NaN;
				var pt:Point = new Point(RunClass.MovieMasher['instance'].mouseX, RunClass.MovieMasher['instance'].mouseY);
				if (__bm_mc.hitTestPoint(pt.x, pt.y))
				{
					pt = __bm_mc.globalToLocal(pt);
					pixel = __bm_mc.bitmapData.getPixel(pt.x, pt.y);
				}
				else
				{
					try
					{
						var display_object:DisplayObject;
						var pixel_color:String;
						var back_pixel:Number;
						var back_color:String;
						var mash:IMash;
						var control:IControl;
				
						control = RunClass.MovieMasher['getByID']('player') as IControl;
						
						if (control != null)
						{
							mash = control.getValue('mash').object as IMash;
							if (mash != null)
							{
								display_object = mash.displayObject;//RunClass.MovieMasher['getByID']('player') as DisplayObject;
								if (display_object != null)
								{
									
								
									
									if (display_object.hitTestPoint(pt.x, pt.y))
									{
										var matrix:Matrix;
										matrix = new Matrix();
										var size:Size;
										size = mash.metrics;
										matrix.translate(size.width / 2, size.height / 2);
										pixel = __colorUnderDisplay(display_object, pt, matrix);
										pixel_color = RunClass.DrawUtility['hexFromColor'](pixel);
									/*
										RunClass.MovieMasher['msg'](this + '._mouseDrag over mash ' + pixel_color);
										back_color = display_object['background'];
										
										if (back_color.length)
										{
											back_pixel = RunClass.DrawUtility['colorFromHex'](back_color);
											if (pixel == back_pixel) pixel = NaN;
										}
										else
										{
											switch (pixel_color)
											{
												case 'ffffff':
												case '000000': 
													pixel = NaN;
													break;
												default:
													RunClass.MovieMasher['msg'](this + '._mouseDrag over mash ' + back_color + ' ? ' + pixel_color);
											}
										}
										*/
									}
									else
									{
										var obs:Array = RunClass.MovieMasher['instance'].getObjectsUnderPoint(pt);
										
										if (obs.length)
										{
											var i,z:int;
											z = obs.length;
											for (i = 0; i < z; i++)
											{
												display_object = obs[i];
												pixel = __colorUnderDisplay(display_object, pt);
												if (pixel != 16777215)
												{
													break;
												}
											}
										}
									}
								}
							}
						}
					}
					catch(e:*)
					{
						// oh well
						RunClass.MovieMasher['msg'](this, e);
					}
				}
				
				if (! isNaN(pixel))
				{
					__value = RunClass.DrawUtility['hexFromColor'](pixel);
					dispatchPropertyChange(true);
				}
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
				dispatchPropertyChange();				
				
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this, e);
			}
		}
		private var __bm_bevel_mc:Sprite;
		private var __bm_mc:Bitmap;
		private var __chip_mc:Sprite;
		private var __chipSize:Number;
		private var __colorWidth:Number;
		private var __indeterminateValue:Boolean = false;
		private var __value:String;
		
	}
}