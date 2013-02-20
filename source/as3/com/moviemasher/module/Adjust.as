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
	
	import com.moviemasher.type.*;
	import com.moviemasher.constant.*;
	import com.moviemasher.utils.*;
	import com.quasimondo.geom.*;
	import com.moviemasher.interfaces.*;
	
/**
* Implementation class for adjust effect module.
* 
* Attributes supported by this module are 'brightness', 'contrast', 'hue', 'saturation', 
* 'brightnessfade', 'contrastfade', 'huefade', 'saturationfade', and 'fade'.
* It relies heavily on the ColorMatrix class by Mario Klingemann as a simpler 
* interface to Flash's ColorMatrixFilter class see his site for more info:
* http://www.quasimondo.com/archives/000565.php
*
* @see IModule
* @see Clip
* @see Mash
*/
	public class Adjust extends ModuleEffect
	{
		public function Adjust()
		{
			_defaults.brightness = '0';
			_defaults.brightnessfade = '0';
			_defaults.contrast = '0';
			_defaults.contrastfade = '0';
			_defaults.hue = '0';
			_defaults.huefade = '0';
			_defaults.saturation = '1'; 
			_defaults.saturationfade = '1'; 
		}
		override public function set time(object:Time):void
		{
			super.time = object;
			
			// see how much we're faded now
			var per:Number = _getFade();
			
			// grab clip properties
			var keys:Array = ['brightness', 'contrast', 'hue', 'saturation'];
			var values:Object = new Object();
			var fade_values:Object = new Object();
			for each (var key:String in keys)
			{
				values[key] = _getClipPropertyNumber(key);
				if (per < 100.0)
				{	
					// only grabbing property if needed for fade
					fade_values[key] = _getClipPropertyNumber(key + 'fade');
				}
			}
			// if we're faded, blend between the values
			if (per != 100)
			{
				values = RunClass.PlotUtility['perValues'](per, values, fade_values, keys);
			}
		
			__values = values;
			
			// reset filters with new ColorMatrixFilter
			var matrix:ColorMatrix = new ColorMatrix();
			matrix.adjustContrast(values.contrast, values.contrast, values.contrast);
			matrix.adjustHue(values.hue);
			matrix.adjustSaturation(values.saturation);
			matrix.adjustBrightness(values.brightness, values.brightness, values.brightness);
			_moduleFilters = [matrix.filter];
	
		}
		private function __equals(a1, a2) : Boolean
		{
			for (var k in a1)
			{ 
				if (a1[k] != a2[k]) return false;
			}
			return true;
		}
		private var __values:Object; 

	}
	
}