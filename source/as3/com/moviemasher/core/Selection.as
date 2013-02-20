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

package com.moviemasher.core
{
	import com.moviemasher.events.*;
	import com.moviemasher.type.*;
	import com.moviemasher.constant.*;
	import com.moviemasher.interfaces.*;
	import com.moviemasher.events.*;
	import com.moviemasher.action.*;
	import flash.utils.*;
	import flash.events.*;

/**
* Class represents the selection of a {@link ControlPanel} object
*
* @see Browser
* @see Timeline
*/
	public class Selection extends Propertied
	{
		public function Selection()
		{
			__items = new Array();
			__properties = new Object();
		}
		public function get items():Array
		{
			return __items;
		}
		public function get length():uint
		{
			return __items.length;
		}
		override public function setValue(value:Value, property:String):Boolean
		{
			
			try
			{
				var items_with_property:Array = __itemsWithProperty(property);
				if (items_with_property.length)
				{
					if (__action == null)
					{
						__action = _createAction(items_with_property, property, value);
					}
					else
					{
						__action.value = value;
					}
					
					__checkDefined();
					
					if (! __dontDestroyAction)
					{
						__action = null;
					}
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.setValue ' + property, e);
			}
			return true;
		}
		public function set items(a:Array):void
		{
			if (! __iAmChanging.length)
			{
				removeItems(true);
				var z:uint = a.length;
				var i:uint;
				for (i = 0; i < z; i++)
				{
					push(a[i], true);
				}
				__dispatchChange();
				
			}
		}
		public function sortOn(property:Object, sort:Object):void
		{
			__items.sortOn(property, sort);
		}
		public function indexOfKey(id:*, key:String = CommonWords.ID):int
		{
			var index:int = -1;
			var z:int = __items.length;
			var item:ISelectable;
			for (var i:int = 0; i < z; i++)
			{
				item = __items[i];
				if (item.getValue(key).equals(id))
				{
					index = i;
					break;
				}
			}
			return index;
		}
		public function indexOf(item:ISelectable):int
		{
			return __items.indexOf(item);
		}
		public function firstItem():ISelectable
		{
			var item:ISelectable = null;
			if (__items.length > 0)
			{
				item = __items[0];
			}
			return item;
		}
		public function push(item:ISelectable, dont_dispatch:Boolean = false):void
		{
			var property:String;
			var i:uint = 0;
			try
			{
				__items.push(item);
				item.addEventListener(Event.CHANGE, __clipChange, false, 0, true);
	
				var editable_properties:Array = item.editableProperties();
				if (editable_properties != null)
				{
					
					var z:uint = editable_properties.length;
					for (i = 0; i < z; i++)
					{
						property = editable_properties[i];
						
						if (__properties[property] == null)
						{
							__properties[property] = 1;
						}
						else
						{
							__properties[property]++;
						}
						try
						{
							_dispatchEvent(property);
						}
						catch(e:*)
						{
							RunClass.MovieMasher['msg'](this + '.push ' + property, e);
						}
					}
					if (! dont_dispatch)
					{
						__dispatchChange();
					}
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.push ' + item + ' ' + i + ' of ' + z, e);
			}
		}
		public function removeItem(item:ISelectable):void
		{
			var index:int = indexOf(item);
			if (index != -1)
			{
				__items.splice(i, index);
				item.removeEventListener(Event.CHANGE, __clipChange);
				var editable_properties:Array = item.editableProperties();
				if (editable_properties != null)
				{
					
					var z:uint = editable_properties.length;
					var property:String;
					for (var i:uint = 0; i < z; i++)
					{
						property = editable_properties[i];
						__properties[property] --;
						if (__properties[property] == 0)
						{
							delete __properties[property];
						}
						
						_dispatchEvent(property);
					}
					
					__dispatchChange();
				}
			}
		}
		public function removeItems(dont_dispatch:Boolean = false):void
		{
			var z:uint = __items.length;
			if (z > 0)
			{
				var old_items = __items;
				__items = new Array();

				var item:ISelectable;
				for (var i:uint = 0; i < z; i++)
				{
					item = old_items[i];
					item.removeEventListener(Event.CHANGE, __clipChange);

				}
				for (var property:String in __properties)
				{
					delete(__properties[property]);
					
					_dispatchEvent(property);
				}
				__properties = new Object();
				if (! dont_dispatch)
				{
				
					__dispatchChange();
				}
			}
		}
		
		override public function changeEvent(event:ChangeEvent):void
		{
			try
			{
				__iAmChanging = event.property;
				__dontDestroyAction = ! event.done;
				super.changeEvent(event);
				__dontDestroyAction = false;
				__iAmChanging = '';
			}
			catch (e:*)
			{
				RunClass.MovieMasher['msg'](this + '.changeEvent', e);
			}
			// do not redispatch event here since any real change would have dispatched already		
		}
		override public function getValue(property:String):Value
		{
			var value : Value = null;
			try
			{
				switch (property)
				{
					case 'count':
						value = new Value(length);
						break;
					case 'items':
						value = new Value(__items);
						break;
					case 'properties':
						var a:Array = new Array();
						for (var k:String in __properties)
						{
							a.push(k);
						}
						value = new Value(a);
						break;
					default:
										
						switch (__items.length)
						{
							case 0:
								value = new Value();
								break;
							/*
							case 1:
								value = __items[0].getValue(property);
								break;
							*/
							default:
								value = __sharedValue(property);
								break;
						}
				}
			}
			catch (e:*)
			{
				RunClass.MovieMasher['msg'](this + '.getValue ' + property, e);
			}
			return value;
		}
		protected function _createAction(items_with_property:Array, property:String, value:Value):IValueAction
		{
			return new ClipsValueAction(items_with_property, property, value);
		}
		private function __itemsWithProperty(property:String):Array
		{
			var items_with_property:Array = new Array();
			try
			{
				var z:uint = __items.length;
				var item:ISelectable;
				for (var i:uint = 0; i < z; i++)
				{
					item = __items[i];
					if (item != null)
					{
						if (item.propertyDefined(property))
						{
							items_with_property.push(item);
						}
					}
				}
			}
			catch (e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__itemsWithProperty ' + property, e);
			}
			return items_with_property;
		}
		private function __sharedValue(property:String):Value
		{
			var value:Value = null;
			try
			{
			
				var z:uint=__items.length;
				var i:uint;
				var test:Value = null;
				var item:ISelectable;
				
				for (i = 0; i < z; i++)
				{
					item = __items[i];
					if (item.propertyDefined(property))
					{
						if (value == null)
						{
							value = item.getValue(property);
							//RunClass.MovieMasher['msg'](this + '.__sharedValue ' + property + ' ' + item + ' ' + value.string);
						}
						else
						{
							test = item.getValue(property);
							if (! test.equals(value))
							{
								value = new Value(((property == 'label') ? 'Multiple Items' : Value.INDETERMINATE));
								break;
							}
						}
					}
				}
			}
			catch (e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__sharedValue ' + property, e);
			}
			if (value == null) value = new Value();
			return value;
		}
		private function __checkDefined():void
		{
			var property:String;
			try
			{
				var z:uint = __items.length;
				var i:uint;
				var y:uint;
				var j:uint;
				var editable_properties:Array;
				var items_with_property:Array;
				var item:ISelectable;
				for (i = 0; i < z; i++)
				{
					item = __items[i];
					editable_properties = item.editableProperties();
					if (editable_properties != null)
					{
						y = editable_properties.length;
						for (j = 0; j < y; j++)
						{
							property = editable_properties[j];
							if (__properties[property] == null)
							{
								__properties[property] = 1;
								_dispatchEvent(property);
							}
						}
					}
				}
				for (property in __properties)
				{
					items_with_property = __itemsWithProperty(property);
					if (! items_with_property.length)
					{
						delete __properties[property];
						_dispatchEvent(property);
					}
				}
			}
			catch (e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__checkDefined ' + property, e);
			}
		}
		private function __dispatchChange():void
		{
			try
			{
				dispatchEvent(new Event(Event.CHANGE));
				_dispatchEvent('count', new Value(length));
				_dispatchEvent('properties');
				RunClass.MovieMasher['instance'].stage.focus = null;
					
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__dispatchChange', e);
			}
		}
		private function __clipChange(event:Event)
		{
			try
			{
				for (var k:String in __properties)
				{
					try
					{
						_dispatchEvent(k);
					}
					catch(e:*)
					{
						RunClass.MovieMasher['msg'](this + '.__clipChange ' + k, e);
					}
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__clipChange', e);
			}
		}
		private var __dontDestroyAction:Boolean;
		private var __action:IValueAction;
		private var __items:Array;
		private var __properties:Object;
		private var __iAmChanging:String = '';
	}
}