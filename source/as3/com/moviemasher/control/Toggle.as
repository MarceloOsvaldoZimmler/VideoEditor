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
	import com.moviemasher.type.*;
	import com.moviemasher.constant.*;
	import com.moviemasher.display.*;
	import com.moviemasher.events.*;
	import com.moviemasher.interfaces.*;
	import com.moviemasher.type.*;
	import com.moviemasher.constant.*;
	import com.moviemasher.utils.*;
	import flash.display.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.utils.*;
/**
* Implementation class represents a simple on/off button control
*/
	public class Toggle extends Icon
	{
		public function Toggle()
		{
			_defaults.toggleoffvalue = '0';
			_defaults.toggleonvalue='1';
		}
		override protected function _createChildren():void
		{
			try
			{
				_displayObjectLoad('toggleicon');
				_displayObjectLoad('toggleovericon');
				_displayObjectLoad('toggledisicon');
				super._createChildren();
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this, e);
			}
		}
		override protected function _roll(tf : Boolean, prefix : String = ''):void
		{
			if ((! prefix.length) && _toggled) prefix = 'toggle';
			super._roll(tf, prefix);
			
		}
		override protected function _update():void
		{
			super._update();

			var toggle:String = (_toggled ? 'toggle' : '');
			var untoggle:String = (_toggled ? '' : 'toggle');
			
			var mc:DisplayObject;
			
			// hide all the other icons
			mc = _displayedObjects[untoggle + 'icon'];
			if (mc != null) mc.visible = false;
			mc = _displayedObjects[untoggle + 'overicon'];
			if (mc != null) mc.visible = false;
			mc = _displayedObjects[untoggle + 'disicon'];
			if (mc != null) mc.visible = false;
			
			
			// find the disabled icon
			mc = _displayedObjects[toggle + 'disicon'];
			if (mc != null)
			{
				mc.visible = _disabled;
				mc = _displayedObjects[toggle + 'icon'];
				if (mc != null) 
				{
					mc.visible = ! _disabled;
				}
			}
			var tf:Boolean = hitTestPoint(RunClass.MovieMasher['instance'].mouseX, RunClass.MovieMasher['instance'].mouseY);
			if (_selected) tf = ! tf;
			_roll(tf);
		}
		override public function setValue(value:Value, property:String):Boolean
		{
			//TODO: figure out why this can't be in Icon...
			if (property == _property)
			{
				property = 'value';
				_toggled = value.equals(getValue('toggleonvalue'));
			}
			return super.setValue(value, property);
		}
		
		override protected function _sizeIcons():Boolean
		{
			var did_size:Boolean = false;

			var i_size:Size = null;
			if (getValue(MediaProperty.FILL).equals(FillType.STRETCH)) 
			{
				i_size = new Size(_width, _height);
			}
			if (_displayObjectSize('toggleicon', i_size)) did_size = true;
			if (_displayObjectSize('toggleovericon', i_size)) did_size = true;
			if (_displayObjectSize('toggledisicon', i_size)) did_size = true;
			did_size = (super._sizeIcons() || did_size);
			return did_size;
		}
		override protected function _release() : void
		{ 
			try
			{
				//RunClass.MovieMasher['msg']('_release ' + (_disabled ? 'dis' : 'en') + 'abled');
					
				if (! _disabled) 
				{
					var key:String = (_toggled ? 'toggle' : '') + CGIProperty.TRIGGER;
					var trigger:String = getValue(key).string;
					//RunClass.MovieMasher['msg']('_release ' + key + ' ' + trigger);
					if (trigger.length) RunClass.MovieMasher['evaluate'](trigger);
					setValue(getValue(_toggled ? 'toggleoffvalue' : 'toggleonvalue'), _property);
					dispatchPropertyChange();
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '._release', e);
			}
		
		}
		protected var _toggled:Boolean = false;
	}
}