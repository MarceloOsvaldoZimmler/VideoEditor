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
	import flash.geom.*;
	import com.moviemasher.utils.*;
	import com.moviemasher.type.*;
	import com.moviemasher.constant.*;
	import com.moviemasher.interfaces.*;
	import flash.display.*;
	
/**
* Implementation class for cube transition module
*
* @see IModule
* @see Transition
* @see Mash
*/
	public class Cube extends ModuleTransition
	{

		private var __mask_mc:Sprite;

		public function Cube()
		{
			_defaults.direction = '0';
			__mask_mc = new Sprite();
			addChild(__mask_mc);
		}
		
		override public function set time(object:Time):void
		{
			super.time = object;
			try
			{
				var direction:String = _getClipProperty('direction');
				var done:Number = _clipCompleted();
	
				var bmwidth = _size.width / 2;
				var bmheight = _size.height / 2;
	
				var frame_data:Object = new Object();
				frame_data.x = - bmwidth;
				frame_data.y = - bmheight;
				
				frame_data.w = _size.width;
				frame_data.h = _size.height;
				
				var not_done : Number = 1 - done;
				_moduleMatrix = new Matrix();
				_transitionMatrix = new Matrix();
				
				// it doesn't seem to matter if this is true or false?
				var swap:Boolean = Boolean(_getClipPropertyNumber('swap'));
				
				var wORh:String = 'w';
				var xORy:String = 'x';
				var amount:Number = 0;
				switch (direction)
				{
					case 'right':
					case '0':
						//RIGHT
						amount = (swap ? _size.width : 0);
						break;
					case 'left':
					case '1' :
						// LEFT
						amount = (swap ? 0 : _size.width);
						break;
					case 'up':
					case '3' :
						// BOTTOM
						xORy = 'y';
						wORh = 'h';
						amount = (swap ? 0 : _size.height);
						break;
					case 'down':
					case '2' :
						// TOP
						amount = (swap ? _size.height : 0);
						xORy = 'y';
						wORh = 'h';
						break;
				}
				frame_data[wORh] *= (swap ? not_done : done);
				if (amount) frame_data[xORy] += amount * (swap ? done : not_done);
				
				if (wORh == 'w')
				{
					_moduleMatrix.scale(not_done, 1);
					_transitionMatrix.scale(done, 1);
				}
				else
				{
					_moduleMatrix.scale(1, not_done);
					_transitionMatrix.scale(1, done);
				}
				switch (direction)
				{
					case 'right':
					case '0' :// LEFT
						_moduleMatrix.translate(bmwidth * done, 0);
						_transitionMatrix.translate(- bmwidth * not_done, 0);
						break;
					case 'left':
					case '1' :// RIGHT
						_moduleMatrix.translate(- bmwidth * done, 0);
						_transitionMatrix.translate(bmwidth * not_done, 0);
						break;
					case 'down':
					case '2' :// TOP
						_moduleMatrix.translate(0, bmheight * done);
						_transitionMatrix.translate(0, - bmheight * not_done);
						break;
					case 'up':
					case '3' :// BOTTOM
						_moduleMatrix.translate(0, - bmheight * done);
						_transitionMatrix.translate(0, bmheight * not_done);
						break;
				}
				
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.time', e);
			}
		}
	}

}