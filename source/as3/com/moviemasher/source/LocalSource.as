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
	import com.moviemasher.constant.*;

/**
* Class allows conditional searching of tags within source
*
* @see Player
* @see Browser
*/
	public class LocalSource extends Source
	{
		public function LocalSource()
		{ }
		override protected function _search():void 
		{
			
			var search_items:Array = new Array();
			
			try
			{
				var all_media:XMLList = _tag.children();
				var z:int = all_media.length();
				var item:XML;
				var k:String;
				
				var keys:Array = new Array();
				if (_terms.length) keys.push(_termsKey);
				for (k in _attributes)
				{
					switch(k)
					{
						case _sortKey:
						case 'id':
						case 'symbol':
						case 'config':
							break;
						default: keys.push(k);
					}
					
				}
				var key_z:uint = keys.length;
				var values:Array;
				var values_z:uint;
				var values_i:uint;
				var item_value:String;
				var test_value:String;
				var matched:Boolean;
				
				for (var i:int = 0; i < z; i++)
				{
					try
					{
						item = all_media[i];
						matched = true;
						for (var j:int = 0; j < key_z; j++)
						{
							k = keys[j];
							values = getValue(k).array;
							
							values_z = values.length;
							matched = false;
							for (values_i = 0; values_i < values_z; values_i++)
							{
								item_value = String(item.@[k]);
								test_value = values[values_i];
								if ((item_value == test_value) || ((k == _termsKey) && (item_value.toLowerCase().indexOf(test_value.toLowerCase()) > -1)))
								{
									matched = true;
								}
							}
							if (! matched)
							{
								break;
							}
						}
						if (matched)
						{
							search_items.push(item);
						}
					}
					catch(e:*)
					{
						RunClass.MovieMasher['msg'](this, e);
					}
					
				}
				if (search_items.length && _sort.length)
				{
					search_items.sort(__xmlSort);
				}
				items = search_items;
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '._search', e);
			}
		}
		private function __xmlSort(a:XML, b:XML):Number
		{
			var a_value:String = String(a.@[_sort]);
			return a_value.localeCompare(String(b.@[_sort]));
		}
		
	}
}