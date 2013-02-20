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
package com.moviemasher.source
{
	import com.moviemasher.type.*;
	import com.moviemasher.interfaces.*;
	import com.moviemasher.constant.*;
	import flash.events.*;
	import com.moviemasher.events.*;
/**
* Base class for conditional searching of source tags
*
* @see Player
* @see Browser
*/
	public class Source extends Propertied implements ISource
	{
		public static function getSourceByID(id:String):ISource
		{
			for each (var isource:ISource in __sources)
			{
				if (isource.getValue(CommonWords.ID).equals(id)) return isource;
			}
			return null;
		}
		public static function getByID(id:String, tag:String):XML
		{
			var xml_item:XML;
			var item_xml:XML;
			var xml_list:XMLList;
			try
			{
				for each (var isource:ISource in __sources)
				{
					for each (var item:* in isource.items)
					{
						if ( ! (item is XML)) break;
						item_xml = (item as XML);
						if ((item_xml.name() == tag) && (String(item_xml.@id) == id))
						{
							xml_item = item_xml;
							break;
						}
						xml_list = item_xml[tag];
						if (xml_list.length())
						{
							xml_list = xml_list.(attribute(CommonWords.ID) == id);
							if (xml_list.length())
							{
								xml_item = xml_list[0];
								break;
							}
						}
					}
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](Source, e);
			}
		
			return xml_item;
			
		}
		public function Source()
		{
			__sources.push(this);
			__items = new Array();
			
		}
		override public function toString():String
		{
			return getValue('id').string;
		}
		public function getItemAt(index:Number):*
		{
			try
			{
				if (! _active) _activate();
				
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this, e);
			}
			return __items[index];
		}
		final public function get items():Array
		{
			return __items;
		}
		final public function set items(array:Array):void
		{
			try
			{
				if (__items != array)
				{
					__items = array;
					_itemsDidChange();
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.items', e);
			}

		}
		public function get length() : uint 
		{ 
			return __length; 
		}
		override public function getValue(property:String):Value
		{
			var value:Value;
			switch(property)
			{
				case 'terms':
				case _termsKey:
					value = new Value(_terms);
					break;
				case 'sort':
				case _sortKey:
					value = new Value(_sort);
					break;
				case 'length':
					if (! _active) _activate();
					value = new Value(length);
					break;
				case 'loading':
					value = new Value();
					break;
				default:
					value = super.getValue(property);
			}
			return value;
		}
		override public function setValue(value:Value, property:String):Boolean
		{
			_searchInvalid = true;
			var set_super:Boolean = true;
			var change_properties:Array = new Array();
			var k:String;
			change_properties.push(property);
					
			switch(property)
			{
				case 'terms':
					change_properties.push(_termsKey);
					// intentional fallthrough to _termsKey
				case _termsKey:
					_terms = value.string;
					set_super = false;
					break;
				case 'sort':
					change_properties.push(_sortKey);
					// intentional fallthrough to _sortKey
				case _sortKey:
					_sort = value.string;
					set_super = false;
					break;
				default: // otherwise, clear the search terms
					_terms = '';					
					change_properties.push(_termsKey);
			}
			if (set_super) 
			{
				super.setValue(value, property);
			}
			for each (k in change_properties)
			{
				//RunClass.MovieMasher['msg'](this + '.setValue ' + property + ' ' + value.string + ' dispatching ' + k + ' "' + getValue(k).string + '"');
				_dispatchEvent(EventType.PROPERTY_CHANGED, new Value(k));
				_dispatchEvent(k);
			}
			__parametersDidChange();
			return false;
		}
		
		override protected function _parseTag():void
		{
			if (_defaults[_termsKey] == null) _defaults[_termsKey] = '';	
			if (_defaults[_sortKey] == null) _defaults[_sortKey] = '';	

			super._parseTag();
			
			var value:Value;
			value = getValue(_sortKey);
			if (! value.empty)
			{
				_sort = value.string;
			}
			value = getValue(_termsKey);
			if (! value.empty)
			{
				_terms = value.string;
			}
		}
		protected function _search():void
		{ }
		final protected function _addResultIfUnique(item_xml:XML, dont_dispatch:Boolean = false):Boolean
		{
			var did_add:Boolean = false;
			var i, z:uint;
			var id:String = String(item_xml.@id);
			if (id.length)
			{
				did_add = true;
				z = __items.length;
				for (i = 0; i < z; i++)
				{
					if (__items[i] is XML)
					{
						if (__items[i].@id == id)
						{
							did_add = false;
							break;
						}
					}
				}
				if (did_add)
				{
					__items.push(item_xml);
					if (! dont_dispatch)
					{
						_itemsDidChange();
					}
				}
			}
			return did_add;
			
		}
		final protected function _itemsDidChange():void
		{
			try
			{
				__length = __items.length;
				//RunClass.MovieMasher['msg'](this + '._itemsDidChange dispatching ' + hasEventListener(Event.CHANGE));
				dispatchEvent(new Event(Event.CHANGE));
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '._itemsDidChange', e);
			}

		}
		
		protected function _activate():void
		{
			//if (RunClass.MovieMasher['hasLoaded'])
			{
				_active = true;
				if (_searchInvalid) __parametersDidChange();
			}
		}
		private function __parametersDidChange():void
		{
			if (_active)
			{
				_search();
				_itemsDidChange();
			}
		}
		private static var __sources : Array = new Array(); 
		protected var _active:Boolean = false;
		private var __items:Array;
		private var __length:uint = 0;
		protected var _searchInvalid:Boolean = true;
		protected var _sort:String = '';
		protected var _sortKey:String = 'sort';
		protected var _terms:String = '';
		protected var _termsKey:String = 'label';
		
	}
}

		