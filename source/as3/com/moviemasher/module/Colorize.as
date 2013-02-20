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
	
	import com.moviemasher.interfaces.*;
	import com.moviemasher.utils.*;
	import com.moviemasher.type.*;
	import com.moviemasher.constant.*;
	import com.quasimondo.geom.*;
	
/**
* Implementation class for colorize effect module.
* 
* Attributes supported by this module are 'forecolor', 'backcolor' and 'fade'.  
* It relies heavily on the ColorMatrix class by Mario Klingemann as a simpler 
* interface to Flash's ColorMatrixFilter class see his site for more info:
* http://www.quasimondo.com/archives/000565.php
* 
* @see IModule
* @see Clip
* @see Mash
*/
	public class Colorize extends ModuleEffect
	{
		public function Colorize()
		{
			_defaults['forecolor'] = 'FF0000';
			_defaults[ModuleProperty.BACKCOLOR] = '00FF00';
			_defaults['fade'] = Fades.IN;
		}
/**
* Sets current clip time for module.
* 
* Pixels in underlying tracks will be desaturated and tinted with a flat
* color. The color will be somewhere between the 'forecolor' and 'backcolor' attributes, 
* as indicated by the 'fade' attribute. If only 'forecolor' is defined, it will be
* used at all times. 
*
* @see DrawUtility
* @see PlotUtility
*/
		override public function set time(object:Time):void
		{
			super.time = object;
			// start with forecolor attribute
			var color:Number = RunClass.DrawUtility['colorFromHex'](_getClipProperty('forecolor'));
			
			// see how much we're faded now
			var per:Number = _getFade();
			var lengthframe:Number = _getClipPropertyNumber(ClipProperty.LENGTHFRAME);
			if (per < 100.00)
			{
				// we are faded, so blend with backcolor
				color = RunClass.DrawUtility['blendColor'](per / 100.00, color, RunClass.DrawUtility['colorFromHex'](_getClipProperty(ModuleProperty.BACKCOLOR)));
			}
			// make sure we're not wasting time resetting the same value
			if (__color != color)
			{
				__color = color;
				
				// reset filters with new ColorMatrixFilter
				var matrix:ColorMatrix = new ColorMatrix();
				matrix.colorize(__color);
				_moduleFilters = [matrix.filter];
			}
		}
		private var __color:Number;
	}
}