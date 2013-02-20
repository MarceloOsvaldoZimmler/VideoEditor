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
	import flash.events.*;
	import com.moviemasher.type.*;
	import com.moviemasher.constant.*;
	import com.moviemasher.events.*;
	import com.moviemasher.type.*;
	import com.moviemasher.constant.*;
	import com.moviemasher.interfaces.*;
	import com.moviemasher.utils.*;
/**
* Implimentation class represents a control for scrolling views
*
* @see ControlPanel
*/

	public class Scrollbar extends Slider
	{
		public function Scrollbar()
		{
			_allowFlexibility = true;
			_defaults.height="*";
		}
		
		
		override protected function _sizeIcons():Boolean
		{
			var did_size:Boolean = false;
			
			var size = new Size(_width, _height);
			if (_displayObjectSize('back', size)) did_size = true;
			if (_displayObjectSize('reveal', size)) did_size = true;
			if (_displayedObjects.reveal != null)
			{
				_displayedObjects.reveal.mask = _revealMaskSprite;
			}
			
			//super._sizeIcons();
			var icon_size:Size = new Size();
			var wORh = _dimName('', 'width');
			icon_size[wORh] = Math.floor((__sizeScroll * this['_' + wORh]) / 100);
			if (_displayObjectSize('icon', icon_size)) did_size = true;
			if (_displayObjectSize('disicon', icon_size)) did_size = true;
			if (_displayObjectSize('overicon', icon_size)) did_size = true;
			__slideWidth = this['_' + wORh] - icon_size[wORh];
			return did_size;
		}
		override public function set listener(object:IPropertied):void
		{	
			var prop:String = _property + 'size';
			var value:Value = object.getValue(prop);
			//RunClass.MovieMasher['msg'](this + '.listener ' + prop + ' = ' + value.string + ' ' + object);
			addEventBroadcaster(prop, object);
			setValue(value, prop);
		}
		override public function setValue(value:Value, property:String):Boolean
		{
														
			switch (property)
			{
				case 'hscrollsize':
				case 'vscrollsize':
					//RunClass.MovieMasher['msg'](this + '.setValue ' + property + ' ' + value.string);
					__sizeScroll = value.number;
					
					if (_width && _height)
					{
						_sizeIcons();
						_update();
					}
					break;
				default :
					super.setValue(value,property);

			}
			return false;
		}
		private var __sizeScroll:Number = 0;
	}

}