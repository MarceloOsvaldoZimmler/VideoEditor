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

package com.moviemasher.utils
{
	import com.moviemasher.type.*;
	import com.moviemasher.constant.*;
/**
* Static class provides functions for parsing XML
*/
	public class XMLUtility
	{
		public static function copyAttributes(from_node:XML, to_node:XML):void
		{
			if ((from_node != null) && (to_node != null))
			{
				var i,z : uint;
				var list : XMLList;
				var node_name : String;
				list =  from_node.@*;
				z = list.length();
				for (i = 0; i < z; i ++)
				{
					node_name = String(list[i].name());
					to_node.@[node_name] = from_node.@[node_name];
				}
			}
		}
		public static function attributeData(node : XML = null, data : Object = null) : Object
		{
			if (data == null) data = new Object();
			if (node != null) 
			{
				data.xmlNode = node;
			
					
				var i,z : uint;
				var list : XMLList;
				var node_name : String;
				list =  node.@*;
				z = list.length();
				for (i = 0; i < z; i ++)
				
				
				var s:String;
				var n : Number;
				var something:*;
				
				for (i = 0; i < z; i ++)
				{
					node_name = String(list[i].name());
					s = stringForAttribute(node,node_name);
					if (s.length)
					{
						n = Number(s);
						if (! isNaN(n)) 
						{
							if (s.indexOf('.') > -1) something = parseFloat(s);	
							else something = n;
						}
						else something = s;
					}
					else something = s;
					data[node_name] = something;
				}
				data.nodeName = node.name();
			}
			return data;
		}
		public static function numberForAttribute(xml:XML, attribute:String):Number
		{
			var n:Number = 0;
			var s:String = stringForAttribute(xml, attribute);
			
			if (s.length)
			{
				n = Number(s);
				if (isNaN(n)) n = 0;
				else if (s.indexOf('.') > -1) n = parseFloat(s);	
			}
			return n;						
		}
		public static function stringForAttribute(xml:XML, attribute:String):String
		{
			var s:String = '';
			if (xml != null)
			{
				s = xml.@[attribute];
			}
			return s;
		}
	}
}

