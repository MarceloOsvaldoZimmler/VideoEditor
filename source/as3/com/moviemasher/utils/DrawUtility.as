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

package com.moviemasher.utils
{
	import flash.geom.*;
	import flash.display.*;
	import com.moviemasher.type.*;
	import com.moviemasher.constant.*;
	import com.moviemasher.interfaces.*;
	import flash.filters.*;
/** 
Static class provides functions for drawing and color management.

*/	
	public class DrawUtility
	{
/** Finds a color that's a certain 'distance' between two other colors.

@param position float between 0 and 1 indicating the point within the blend
@param start integer representing first color in blend
@param finish integer representing last color in blend
@return integer representing the blended color
*/
		public static function blendColor(position:Number, start:Number, finish:Number):Number
		{
			var c1:Object = __color2RGB(start);
			var c2:Object = __color2RGB(finish);
			c1.r = position * c1.r + (1-position)*c2.r;
			c1.g = position * c1.g + (1-position)*c2.g;
			c1.b = position * c1.b + (1-position)*c2.b;
			return __getHex(c1.r, c1.g, c1.b);
		}
/** Returns a valid blend mode for string or numeric ID.

@param mode String or Number representing a blend mode
@return String representing valid blend mode
*/
		public static function blendMode(mode:*):String
		{
			var index:Number = Number(mode);
			if (isNaN(index))
			{
				var s:String = String(mode);
				if (s.length)
				{
					s = s.toUpperCase();
					index = blendModes.indexOf(s);
					if (index == -1) index = 0;
				}
			}
			else index--; // number equivalents are one (not zero) based
			return BlendMode[blendModes[index]];
		}
/** Converts a six character hex string to a numeric color with transparency.

@param hex String six character hex color
@return Number representing color 
*/
		public static function colorFromHex(hex:String = null, opacity:String = null):Number
		{
			if (hex == null) hex = '000000';
			else hex = String(hex);
			if (hex.length != 6) hex = RunClass.StringUtility['strPad'](hex, 6, '0');
			if (opacity != null) hex = opacity + hex;
			hex = '0x' + hex;
			var n = Number(hex);
			if (isNaN(n)) n = 0;
			return n;
		}	
/** Calls moveTo or curveTo with points supplied.

@param graphics Graphics object to draw into
@param points Array of Objects with x, y, and type keys
@param dont_end Boolean if true, endFill will not be called
*/
		public static function drawPoints(graphics:Graphics, points:Array, dont_end:Boolean = false, reverse_mode:Boolean = false):void
		{
			var aPoint:Object;
			var last:Object;
			var x:Number;
			var y:Number;
			var minORmax:String = (reverse_mode ? 'max' : 'min');
			var maxORmin:String = (reverse_mode ? 'min' : 'max');
			for (var i = 0; i <= points.length; i++)
			{
				if (i == points.length) aPoint = points[0];
				else aPoint = points[i];
				if (! i) graphics.moveTo(aPoint.x, aPoint.y);
				else
				{
					if (aPoint.type != 'curve') graphics.lineTo(aPoint.x, aPoint.y);
					else
					{
						x = last.x;
						y = last.y;
						if (aPoint.x > last.x) y = Math[minORmax](last.y, aPoint.y);
						else y = Math[maxORmin](last.y, aPoint.y);
						if (aPoint.y > last.y) x = Math[maxORmin](last.x, aPoint.x);
						else x = Math[minORmax](last.x, aPoint.x);
						graphics.curveTo(x, y, aPoint.x, aPoint.y);
					}
				}
				last = aPoint;
			}
			if (! dont_end) graphics.endFill();
		}		
/** Convenience function calls fillBox() with zero for x and y parameters.

@param graphics Graphics object to draw into
@param w Number width of box in pixels
@param h Number height of box in pixels
@param color integer representing base color
@param alpha Number draw transparency as a percentage
@param curve Number curvature of box corners in pixels

*/
		public static function fill(graphics:Graphics, w:Number, h:Number, color:Number = 0, alpha:Number = 100, curve:Number = 0):void
		{
			fillBox(graphics, 0, 0, w, h, color, alpha, curve);
		}
/** Convenience function calls setFill() points() and drawPoints() together.

@param graphics Graphics object to draw into
@param x Number indicating horizontal offset of box in pixels
@param y Number indicating vertical offset of box in pixels
@param w Number indicating the horizontal size of box in pixels
@param h Number indicating the vertical size of box in pixels
@param color Number indicating fill color
@param alpha Number indicating alpha transparency of box as percentage
*/
		public static function fillBox(graphics:Graphics, x:Number, y:Number, w:Number = 1, h:Number = 1, color:Number = 0, alpha:Number = 100, curve:Number = 0, dont_end:Boolean = false):void
		{
			setFill(graphics, color, alpha);
			drawPoints(graphics, points(x, y, w, h, curve), dont_end);
		}
/** Convenience function calls setFillGrad() points() and drawPoints() together.

@param graphics Graphics object to draw into
@param x Number indicating horizontal offset of box in pixels
@param y Number indicating vertical offset of box in pixels
@param w Number indicating the horizontal size of box in pixels
@param h Number indicating the vertical size of box in pixels
@param grad Object (see setFillGrad)
@param alpha Number indicating alpha transparency of box as percentage
*/
		public static function fillBoxGrad(graphics:Graphics, x:Number, y:Number, w:Number = 1, h:Number = 1, grad:Object = null, alpha:Number = 100, curve:Number = 0, dont_end:Boolean = false):void
		{
			var k:String;
			if (grad == null) grad = new Object();
			else
			{
				var object:Object = new Object();
				for (k in grad)
				{
					if (grad[k] is Array) object[k] = grad[k].concat();
					else object[k] = grad[k];
				}
				grad = object;
			}
			if (grad.width == null) grad.width = w;
			if (grad.height == null) grad.height = h;
			if (grad.x == null) grad.x = x;
			if (grad.y == null) grad.y = y;
			setFillGrad(graphics, grad, alpha);
			drawPoints(graphics, points(x, y, w, h, curve), dont_end);
			
		}
/** Draws a rounded, colored box with optional border.

The graphics object will be cleared before drawing begins.
The following keys should be in xml or object parameter:
<ul>
	<li>angle: Number indicating direction of gradient in degrees</li>
	<li>border: Number indicating border width in pixels</li>
	<li>bordercolor: String containing six character hex color for border</li>
	<li>color: String containing six character hex color for base</li>
	<li>curve: Number indicating how much to curve edges in pixels</li>
	<li>grad: Number indicating how much to gradate the color</li>
</ul>
@param graphics Graphics object to draw into
@param xml XML object to look for attributes in
@param object Object to look for keys in
@param w Number indicating the horizontal size of box in pixels
@param h Number indicating the vertical size of box in pixels
@param x Number indicating horizontal offset of box in pixels
@param y Number indicating vertical offset of box in pixels
@param a Number indicating alpha transparency of box as percentage
@see Plotter
*/
		public static function gradientBox(graphics:Graphics, object:IValued, w:Number, h:Number, x:Number = 0, y:Number = 0, a:Number = 100, prefix:String = ''):void
		{
			var color:String = object.getValue(prefix + 'color').string;
			var border:Number = object.getValue('border').number;
			var curve:Number = object.getValue('curve').number;
			
			if (border > 0)
			{
				fillBox(graphics, x, y, w, h, RunClass.DrawUtility['colorFromHex'](object.getValue(prefix + 'bordercolor').string), a, curve);
				x += border;
				y += border;
				w -= (2 * border);
				h -= (2 * border);
			}
			if (color.length)
			{
				var c:Number = RunClass.DrawUtility['colorFromHex'](color);
				var grad:Number = object.getValue(prefix + 'grad').number;
				if (grad > 0) fillBoxGrad(graphics, x, y, w, h, gradientFill(w, h, c, grad, object.getValue(prefix + 'angle').number), a, curve);
				else fillBox(graphics, x, y, w, h, c, a, curve);
			}
		}
/** Returns a color configuration object for a gradient filled box.

@param w Number width of box in pixels
@param h Number height of box in pixels
@param color integer representing base color
@param grad integer representing intensity of gradient
@param angle degree representing direction of gradient
@param type String 'radiant' or 'linear' gradient
@return Object suitable for passing to plotGrad function
@see Plotter
@see Timeline
*/
		public static function gradientFill(w:Number, h:Number, color:Number = 0, grad:Number = 0, angle:Number = 0, type:String = null):Object
		{
			return {width: w, height: h, type: type, angle: angle, colors: [__adjustColor(color, grad), __adjustColor(color, -grad)]};
			
		}
/** Converts a numeric color into a six character hex string.

@param color Number representing a color
@return String six character hex color
@see Picker
@see Colorfade
*/
		public static function hexFromColor(color:Number):String
		{
			var rgb:Object = __color2RGB(color);
			return __hexFromRGB(rgb.r,rgb.g,rgb.b);
		}
/** Converts box to Array of point like objects.

@param x Number indicating horizontal offset of box in pixels
@param y Number indicating vertical offset of box in pixels
@param w Number indicating the horizontal size of box in pixels
@param h Number indicating the vertical size of box in pixels
@param curve Number curvature of box corners in pixels
@return Array of objects with x, y and optionally curve keys
*/
		public static function points(x:Number, y:Number, w:Number, h:Number, curve:Number = 0):Array
		{	
			if (! curve) return [{x: x, y: y}, {x: x + w, y: y}, {x: x + w, y: y + h}, {x: x, y: y + h}];
			
			// make sure curve isn't more than half width or height
			curve = Math.min(curve, Math.round(w / 2));
			curve = Math.min(curve, Math.round(h / 2));
			return [{x: x, y: y + curve}, {x: x + curve, y: y, type: 'curve'}, {x: x + (w - curve), y: y}, {x: x + w, y: y + curve, type: 'curve'}, {x: x + w, y: y + h - curve}, {x: x + w - curve, y: y + h, type: 'curve'}, {x: x + curve, y: y + h}, {x: x, y: y + h - curve, type: 'curve'}];
		}
/** Calls beginFill(), with color and optional alpha.

@param graphics Graphics object to draw into
@param color Number indicating fill color
@param alpha Number indicating alpha transparency as percentage
*/
		public static function setFill(graphics:Graphics, color:Number, alpha:Number = 100):void
		{
			graphics.beginFill(color, alpha / 100);
		}
/** Calls beginGradientFill(), calculating ratios and alphas if needed.

@param graphics Graphics object to draw into
@param grad Object with keys for coordinates, colors, alphas, ratios, angle, type, matrix
@param alpha Number indicating alpha transparency of box as percentage
*/
		public static function setFillGrad(graphics:Graphics, grad:Object, a:Number = 100):void
		{
			var i:Number;
			if (grad.alphas == null)
			{
				grad.alphas = [];
				for (i = 0; i < grad.colors.length; i++)
				{
					grad.alphas.push(a);	
				}
			}
			if (grad.ratios == null)
			{
				grad.ratios = [];
				var increment = 255 / (grad.colors.length - 1);
				for (i = 0; i < grad.colors.length; i++)
				{
					grad.ratios.push(Math.round(i * increment));	
				}
			}
			if (grad.angle == null) grad.angle = 0;
			if (grad.type == null) grad.type = 'linear';
			if (grad.x == null) grad.x = 0;
			if (grad.y == null) grad.y = 0;
			if (grad.matrix == null)
			{
				grad.matrix = new Matrix();
				grad.matrix.createGradientBox(grad.width, grad.height, (grad.angle/180)*Math.PI, grad.x, grad.y);
			}
			if (grad.spread == null) grad.spread = 'pad';
			graphics.beginGradientFill(GradientType[grad.type.toUpperCase()], grad.colors, grad.alphas, grad.ratios, grad.matrix, SpreadMethod[grad.spread.toUpperCase()]);
		}
/** Calls lineStyle(), with options.

@param graphics Graphics object to draw into
@param thickness Number indicating line width in pixels
@param color Number indicating stroke tint
@param alpha Number indicating transparency of line as percentage
*/
		public static function setLine(graphics:Graphics, thickness:Number = 0, color:Number = 0, alpha:Number = 100, mode:String = null, joint:String = null):void
		{
			if (joint == null) joint = JointStyle.ROUND;
			
			if (mode == null) mode = LineScaleMode.NORMAL;
			graphics.lineStyle(thickness, color, alpha / 100, true, mode, null, joint);
			
			
			
			//lineStyle(thickness:Number = NaN, color:uint = 0, alpha:Number = 1.0, pixelHinting:Boolean = false, scaleMode:String = "normal", caps:String = null, joints:String = null, miterLimit:Number = 3):void

		}
/** Draws a rounded, colored box with optional drop shadow and border.

Uses DropShadowFilter to create shadow. Colored box can have curved edges and gradient color fill.

@param options {@link IOptions} object containing data for shadow and box options
@param sprite Sprite object to draw into and set filters for
@see IOptions
@see PreviewOptions
@see View
@see Tooltip
@see BrowserPreview
*/
		public static function shadowBox(options:IValued, sprite:Sprite, prefix:String = ''):void
		{
		
			try
			{
				
			
				var width:Number = options.getValue('width').number;
				var height:Number = options.getValue('height').number;
				
				sprite.graphics.clear();
				
				DrawUtility.gradientBox(sprite.graphics, options, width, height, 0, 0, options.getValue(prefix + 'alpha').number, prefix);
				sprite.filters = shadowFilters(options, prefix);
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg']('DrawUtility.shadowbox ' + options + ' ' + sprite + ' caught ' + e);
			}
		}
		
		public static function shadowFilters(options:IValued, prefix:String = ''):Array
		{
		
			var array:Array = new Array();
			try
			{
				var shadow:Number = options.getValue(prefix + 'shadow').number;
				var shadowblur:Number = options.getValue(prefix + 'shadowblur').number;
				var shadowcolor:String = options.getValue(prefix + 'shadowcolor').string;
				var shadowstrength:Number = options.getValue(prefix + 'shadowstrength').number;
				
				if (shadow || shadowcolor.length)
				{
					array = [new DropShadowFilter(shadow, 45, RunClass.DrawUtility['colorFromHex'](shadowcolor), 1, shadowblur, shadowblur, shadowstrength, 3)];
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg']('DrawUtility.shadowFilters ' + options + ' caught ' + e);
			}
			return array;
		}

	// PRIVATE CLASS METHODS
	
		private static function __adjustColor(cc:Number, n:Number):Number
		{
			var c:Object = __color2RGB(cc);
			for (var k in c)
			{
				c[k] = Math.min(255, Math.max(0, c[k] + n));
			}
			return __getHex(c.r, c.g, c.b);
		}	
		public static function __color2RGB(HEX:Number):Object
		{
			return {r:HEX >> 16, g:(HEX >> 8) & 0xff, b:HEX & 0xff};
		}
		private static function __getHex(r:Number, g:Number, b:Number):Number
		{
			return r << 16 | g << 8 | b;
		}
		public static function __hexFromRGB(r:Number, g:Number, b:Number):String
		{
			return __twoDigit(r.toString(16))+__twoDigit(g.toString(16))+__twoDigit(b.toString(16));
		}
		private static function __twoDigit(str:String):String 
		{
			return str.length == 1 ? "0"+str:str;
		}
		public static var blendModes:Array = ['NORMAL','LAYER','MULTIPLY','SCREEN','LIGHTEN','DARKEN','DIFFERENCE','ADD','SUBTRACT','INVERT','ALPHA','ERASE','OVERLAY','HARDLIGHT'];
	}
}