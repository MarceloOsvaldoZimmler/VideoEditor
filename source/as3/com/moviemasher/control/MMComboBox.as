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
	import fl.controls.*;
	
	import flash.display.*;
	import fl.data.*;
	import flash.events.*;
	import com.moviemasher.utils.*;
	import com.moviemasher.type.*;
	import com.moviemasher.constant.*;
	import com.moviemasher.interfaces.*;
	import com.moviemasher.type.*;
	import com.moviemasher.constant.*;
/**
* Implimentation class represents a standard Flash ComboBox component control
*/
	public class MMComboBox extends Control
	{
		public function MMComboBox()
		{ 
			_defaults.source = '';
		}
		override protected function _createChildren():void
		{
			_control = new ComboBox();
			addChild(_control);
			_control.addEventListener(Event.CHANGE, _controlChange, false, 0, true);
			
			//_createTooltip();
		}
		override public function makeConnections():void
		{
			super.makeConnections();
			var source:String = super.getValue('source').string;
			//RunClass.MovieMasher['msg'](this + '._createChildren ' + source);
			var data_source:*;
			if (! source.length) data_source = _tag;
			else
			{
				data_source = RunClass.MovieMasher['getByID'](source);
			}
			try
			{
				//RunClass.MovieMasher['msg'](this + '._createChildren ' + data_source);
			
				_control.dataProvider = new DataProvider(data_source);
			}
			catch(e:*)
			{
				//RunClass.MovieMasher['msg'](this + '._createChildren ' + _tag.toXMLString(), e);
				_control.dataProvider = new DataProvider(_tag);
			}
		}
		protected function _controlChange(event:Event):void
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
		override public function getValue(property:String):Value
		{
			var value:Value;
			if (property == _property)
			{
				if (_control.selectedIndex == -1)
				{
					value = new Value(null);
				}
				else
				{
					try
					{
						value = new Value(_control.selectedItem.id);
					}
					catch(e:*)
					{
						value = new Value('');
					}
				}
			}
			else 
			{
				value = super.getValue(property);
			}
			return value;
		}
		private var __needsDispatch:Boolean = false;
		
		override protected function _adjustVisibility():void
		{
			if (! _hidden)
			{
				if (__needsDispatch && getValue('force').boolean) dispatchPropertyChange();
				__needsDispatch = false;
			}
		}
		
		
		override public function setValue(value:Value, property:String):Boolean
		{
			
			if (property == _property)
			{
				var i,z:int = _control.dataProvider.length;
				var identifier:String;				
				if (z)
				{
					for (i = 0; i < z; i++)
					{
						identifier = _control.dataProvider.getItemAt(i).id;
						if (value.empty || value.equals('default'))
						{
							__needsDispatch = true;
							value = new Value(identifier);
							_control.selectedIndex = 0;
							break;
						}
						if (value.equals(identifier))
						{
							_control.selectedIndex = i;
							break;
						}
						identifier = '';
					}	
					if (! identifier.length) __needsDispatch = true;
					//RunClass.MovieMasher['msg']('MMComboBox.setValue ' + property + ' ' + value.string + ' ' + _control.selectedIndex);
					if (_control.selectedIndex == -1) _control.selectedIndex = 0;
				
				}
			}
			else 
			{
				super.setValue(value, property);
			}
			
			if (__needsDispatch && getValue('force').boolean && (! _hidden))
			{
				__needsDispatch = false;
				dispatchPropertyChange();
			}
			return false;
		}
		override public function resize():void
		{
			_control.setSize(_width, _height);
			_control.drawNow();
		}
		
		
		protected var _control:ComboBox;
		
		
	}
}