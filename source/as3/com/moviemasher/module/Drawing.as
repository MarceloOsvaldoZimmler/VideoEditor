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
	import flash.display.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.filters.*;
	import flash.utils.*;
	import com.moviemasher.type.*;
	import com.moviemasher.constant.*;
	import com.moviemasher.utils.*;

/**
* Implementation class for generating various vector animations
*
* @see IModule
* @see Clip
* @see Mash
*/
	public class Drawing extends Composite
	{

		public function Drawing()
		{
			_defaultMatrix();
			
			_defaults.shape = 'rect'; // rect, roundrect, circle, ellipse, polygon
			_defaults.fade = Fades.ON;
			_defaults.alpha = '100';
			_defaults.alphafade = '0';
			_defaults.linealpha = '100';
			_defaults.fillalpha = '100';
			_defaults.curve = '1';
			
			__canvas = new Shape();
			_displayObjectContainer.addChild(__canvas);
			
		}

		override public function get backColor():String
		{
			return _getClipProperty(ModuleProperty.BACKCOLOR);
		}
		override public function set time(object:Time):void
		{
			super.time = object;
			try
			{
				if (_size != null) 
				{
					var forecolor:String;
					var backcolor:String;
					var line:int = 0;
					var inverted_matrix:Matrix;
					var pt:Point;
					var inverted_line:int;
					forecolor = _getClipProperty('forecolor');
					backcolor = _getClipProperty('backcolor');
					line = _getClipPropertyNumber('line');
					
					if (forecolor.length && line) line = _percentOfDimension(line);
					inverted_line = line;
					
					__canvas.graphics.clear();
					
					if (line)
					{
						// fill bounds with transparency so we can figure matrix
						RunClass.DrawUtility['setFill'](__canvas.graphics, 0, 0);
						__canvas.graphics.drawRect(- _size.width / 2, - _size.height / 2, _size.width, _size.height);
						__canvas.graphics.endFill();
						_setDisplayObjectMatrix(__canvas);
						pt = new Point(line, line);
						inverted_matrix = __canvas.transform.matrix.clone();
						inverted_matrix.invert();
						pt = inverted_matrix.deltaTransformPoint(pt);
						inverted_line = Math.max(pt.x, pt.y);
					}
					
					if (line) RunClass.DrawUtility['setLine'](__canvas.graphics, line, RunClass.DrawUtility['colorFromHex'](forecolor), _getClipPropertyNumber('linealpha'), LineScaleMode.NONE);
	
					if (backcolor.length) RunClass.DrawUtility['setFill'](__canvas.graphics, RunClass.DrawUtility['colorFromHex'](backcolor), _getClipPropertyNumber('fillalpha'));
					else RunClass.DrawUtility['setFill'](__canvas.graphics, 0x000000, 0);
					
					
					var map:String = _getClipProperty('shape');
					if (! ( this['__' + map + 'Shape'] is Function)) map = 'circle';
					
					this['__' + map + 'Shape'](inverted_line);
					__canvas.graphics.endFill();
					
					if (! line) _setDisplayObjectMatrix(__canvas);
						
					var array:Array = new Array();
					var shadow:int = _getClipPropertyNumber('shadow');
					if (shadow)
					{
						shadow = _percentOfDimension(shadow);
						array = [new DropShadowFilter(shadow, 45, RunClass.DrawUtility['colorFromHex'](_getClipProperty('shadowcolor')), 1, _getClipPropertyNumber('shadowblur'), _getClipPropertyNumber('shadowblur'), _getClipPropertyNumber('shadowstrength'), 3)];
					}
					__canvas.filters = array;

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
		private function __rectShape(line:int):void
		{
			var w:Number = _size.width - line;
			var h:Number = _size.height - line;
			
			__canvas.graphics.drawRect(- w / 2, - h / 2, w, h);
		}
		private function __roundrectShape(line:int):void
		{					
			var w:Number = _size.width - line;
			var h:Number = _size.height - line;
			
			__canvas.graphics.drawRoundRect(- w / 2, - h / 2, w, h, _percentOfDimension(_getClipPropertyNumber('curve')));
		}
		private function __circleShape(line:int):void
		{
			var w:Number = _size.width - line;
			var h:Number = _size.height - line;
			
			__canvas.graphics.drawCircle(0,0, Math.round(Math.min(w / 2, h / 2)));
			
		}
		private function __ellipseShape(line:int):void
		{
			var w:Number = _size.width - line;
			var h:Number = _size.height - line;
			
			__canvas.graphics.drawEllipse(- w / 2, - h / 2, w, h);
			
		}
		private function __polygonShape(line:int):void
		{
			var points_str:String = _getClipProperty('points');
			var points:Array;
			var i,z:int;
			var w:Number = _size.width - line;
			var h:Number = _size.height - line;
			
			var half_height:int = Math.round(h / 2);
			var half_width:int = Math.round(w / 2);
			var x_pos,y_pos:int;
			if (points_str.length)
			{
				points = points_str.split(',');
				z = Math.floor(points.length / 2);
				if (z)
				{
					for (i = 0; i < z; i++)
					{
						x_pos = _percentOfDimension(points[i * 2], 'width') - half_width;
						y_pos = _percentOfDimension(points[i * 2 + 1]) - half_height;
						if (i)
						{
							__canvas.graphics.lineTo(x_pos, y_pos);
						}
						else __canvas.graphics.moveTo(x_pos, y_pos);
					}
					x_pos = _percentOfDimension(points[0], 'width') - half_width;
					y_pos = _percentOfDimension(points[1]) - half_height;
					__canvas.graphics.lineTo(x_pos, y_pos);
				}
				
			}
		}
		private var __canvas:Shape;
	}

}