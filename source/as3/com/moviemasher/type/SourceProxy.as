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


package com.moviemasher.type
{
	import flash.events.*;
	import com.moviemasher.interfaces.*;
	import com.moviemasher.events.*;
	import com.moviemasher.type.*;
	import com.moviemasher.constant.*;
	
/**
* Class passes events from an ISource implementation to a browser control
* @see ISource
* @see Browser
*/
	public class SourceProxy extends Propertied
	{
		public function SourceProxy()
		{ }
		override public function setValue(value:Value, property:String):Boolean
		{
			var tf:Boolean;
			if (__source) tf = __source.setValue(value, property);
			tf = super.setValue(value, property);
			
			dispatchEvent(new Event('change'));
			_dispatchEvent(property, value);
			return tf;
		}
		override public function getValue(property:String):Value
		{
			var value:Value;
			if (__source) value = __source.getValue(property);
			else value = super.getValue(property);
			return value;
		}
		public function set source(iSource:ISource):void
		{
			if (__source != null)
			{
				__source.removeEventListener(EventType.PROPERTY_CHANGED, __propertyChanged);
			}
			__source = iSource;
			if (__source != null)
			{
				__source.addEventListener(EventType.PROPERTY_CHANGED, __propertyChanged);
				for (var k:String in _attributes)
				{
					__source.setValue(super.getValue(k), k);
				}
			}
		}
		private function __propertyChanged(event:ChangeEvent):void
		{
			dispatchEvent(new Event('change'));
			_dispatchEvent(event.value.string, __source.getValue(event.value.string));
		}
		private var __source:ISource;
	}
}