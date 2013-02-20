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
	import com.moviemasher.events.*;
	import com.moviemasher.type.*;
	import com.moviemasher.constant.*;
	import com.moviemasher.utils.*;
	import flash.display.*;
	import flash.filters.*;
	import flash.geom.*;
/**
* Implementation class for colorfade image module
* 
* Attributes supported by this module are 'forecolor', 'backcolor', 'quality',
* 'direction' and 'speed'. 
* This module is a refactoring of the most excellent ActionScript 3 Clouds Tutorial
* by Dan Gries and Barbara Kaskosz. Many creative and easy to follow examples of 
* heavy math coding in ActionScript are available on their Flash and Math blog:
* http://www.flashandmath.com/intermediate/clouds/
* http://www.flashandmath.com/
* 
* @see IModule
* @see Clip
* @see Mash
*/
	public class Clouds extends Module
	{
		public function Clouds()
		{
			_defaults['forecolor'] = 'FFFFFF';
			_defaults['quality'] = '3';
			_defaults[ModuleProperty.BACKCOLOR] = '0';
			_defaults['speed'] = '1';
			_defaults['direction'] = 'upright';
			
		}
		override public function get backColor():String
		{
			return _getClipProperty(ModuleProperty.BACKCOLOR);
		}
		override public function set time(object:Time):void
		{
			try
			{
				super.time = object;
				
				var completed:Number = _clipCompleted();
				var i:int;
				var speed:Number = _getClipPropertyNumber('speed');
				var completed_speed:Number = completed * speed;
				var direction:String = _getClipProperty('direction');
				var x_pos:Number = 0;
				var y_pos:Number = 0;
				
				
				//Update __offsets of the Perlin noise which moves the clouds.
				
				switch (direction)
				{
					case 'right':
					case '0':
						//RIGHT
						x_pos = -1;
						break;
					case 'left':
					case '1' :
						// LEFT
						x_pos = 1
						break;
					case 'up':
					case '3' :
						// BOTTOM
						y_pos = 1;
						break;
					case 'down':
					case '2' :
						// TOP
						y_pos = -1;
						break;
					case 'upright':
					case '4':
						x_pos = -1
						y_pos = 1;
						break;
					case 'upleft':
					case '5':
						x_pos = 1
						y_pos = 1;
						break;
					case 'downright':
					case '6':
						x_pos = -1
						y_pos = -1;
						break;
					case 'downleft':
					case '7':
						x_pos = 1
						y_pos = -1;
						break;
				}
				if (x_pos) x_pos *= _size.width * completed_speed;
				if (y_pos) y_pos *= _size.height * completed_speed;
				
				for (i = 0; i<=__numOctaves-1; i++) {
					
					__offsets[i].x = x_pos;
					__offsets[i].y = y_pos;
				}
				//We create a grayscale Perlin noise in __perlinData and apply 
				//the ColorMatrixFilter to it. See the tutorial's page for explanations.
				// TODO: allow user to resize?
				x_pos = _size.width;
				y_pos = _size.height;
				
				__perlinData.perlinNoise(x_pos, y_pos,_getClipPropertyNumber('quality'),__seed,false,true,1,true,__offsets);
				__perlinData.applyFilter(__perlinData, __perlinData.rect, new Point(), __colorMatrixFilter);
			}
			catch (e:*)
			{
				RunClass.MovieMasher['msg'](this + '.time ' + _size, e);
			}
		}
		override public function unload():void
		{
			try
			{
				__removeBitmap();
				__colorMatrixFilter = null;
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.unload', e);
			}
			super.unload();
		}
		override public function get displayObject():DisplayObjectContainer
		{
			return this;
		}
		override protected function _changedSize():void
		{
			__removeBitmap();
			__perlinData = new BitmapData(_size.width,_size.height,true);
			__perlinBitmap = new Bitmap(__perlinData);
			addChild(__perlinBitmap);
			
			__perlinBitmap.x = - _size.width / 2;
			__perlinBitmap.y = - _size.height / 2;
		
		}
		override protected function _clipPropertyDidChange(event:ChangeEvent):void
		{
			super._clipPropertyDidChange(event);
			switch (event.property)
			{
				case 'forecolor':
				
			
					/*
					__numOctaves determine properties of our Perlin noise and the 
					appearance of the clouds. Smaller values for periods will result in higher
					horizontal or vertical frequencies which will produce smaller, more frequent clouds.
					
					Smaller number of octaves, __numOctaves, will give clouds not as good-looking but much
					more CPU friendly, especially for larger images. Perlin noise is very CPU intensive.
					For example, by setting __numOctaves=3, you will get a nice
					looking sky that will run at much higher FPS.
					
					We are creating a BitmapData object that supports transparency of pixels (parameter 'true')
					and a Bitmap with that BitmapData. We will apply a grayscale Perlin noise to __perlinData.
					To our grayscale Perlin noise, we will apply a ColorMatrixFilter, __colorMatrixFilter. This filter
					makes darker pixels in __perlinData more transparent so blue sky shows through.
					After applying __colorMatrixFilter, some pixels are more transparent than others but they are all turned to white.
					(See the tutorial's webpage for explanations.) 
					*/
					
					var forecolor:String = event.value.string;
					var red:Number = Number('0x' + forecolor.substr(0, 2));
					var green:Number = Number('0x' + forecolor.substr(2, 2));
					var blue:Number = Number('0x' + forecolor.substr(4, 2));			
					__colorMatrixFilter = new ColorMatrixFilter([0,0,0,0,red, 0,0,0,0,green, 0,0,0,0,blue, 1,0,0,0,0]);
					break;
			}
		}
		override protected function _initialize():void 
		{
			super._initialize();
			
			// Create __offsets array:
			__offsets = new Array();
			var i:int;
			for (i = 0; i<=__numOctaves-1; i++) 
			{
				__offsets.push(new Point());
			}
			_clipPropertyDidChange(new ChangeEvent(new Value(_getClipProperty('forecolor')), 'forecolor'));
		}
		private function __removeBitmap():void
		{
			if (__perlinBitmap != null)
			{
				removeChild(__perlinBitmap);
				__perlinBitmap.bitmapData = null;
				__perlinBitmap = null;
				__perlinData.dispose();
				__perlinData = null;
			}
		}
		private var __colorMatrixFilter:ColorMatrixFilter;
		private var __numOctaves:int = 3;
		private var __offsets:Array;
		private var __perlinBitmap:Bitmap; // a Bitmap correponding to __perlinData;
		private var __perlinData:BitmapData;// - a BitmapData object to which a Perlin noise will be applied as well as a ColorMatrixFilter, __colorMatrixFilter;
		private var __seed:int = int(Math.random()*10000);
	}
}