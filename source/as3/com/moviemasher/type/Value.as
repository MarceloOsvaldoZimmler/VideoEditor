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
/**
* Class representing an abstract value that can be retrieved as a String, Boolean, Number or Array.
*/
	public class Value
	{
/** 
* Constant Value represents multiple differing values.
*/
		public static const INDETERMINATE : String = 'ValueIndeterminate';
/** 
* Constant Value represents undefined value.
*/
		public static const UNDEFINED : String = 'ValueUndefined';
/** 
* Constructor.
* @param Object null or Number, String or Array.
*/
		public function Value(iObject:Object = null)
		{
			if (iObject is Value)
			{
				iObject = iObject.object;
			}
			object = iObject;
		}
/** 
* Create a shallow duplicate of receiver. 
* @returns Value that is a copy of receiver.
*/
		public function copy():Value
		{
			return new Value(object);
		}
/** Tests to see if receiver equals a String, Number or Value.
* @param ob Object can be String, Number or Value to check for equality.
* @returns Boolean true if recever can be coerced to something that equals ob.
*/
		public function equals(ob:Object):Boolean
		{
			if (ob is Value)
			{
				ob = ob.object;
			}
			return (ob == object);
		}
/** 
* Receiver provides its String representation when coerced to a String.
* @returns String representation of receiver.
*/
		public function toString():String
		{
			return string;
		}
/**
* Retrieves Array representation of receiver. 
* Once called, the receiver's underlying object will have been converted to an Array using delimeter, if needed.
* @returns Array representation of receiver.
*/
		public function get array():Array 
		{
			var a:Array;
			
			if (object == null)
			{
				a = new Array();
			}
			else if (object is String)
			{
				if (empty)
				{
					a = new Array();
				}
				else
				{
					a = (object as String).split(delimiter);
				}
			}
			
			else if (object is Array)
			{
				a = object as Array;
			}
			else
			{
				a = [object];
			}
		
			object = a;
			return a;
		}
/**
* Sets Array representation of receiver.
* @param array Array or null.
*/		
		public function set array(array:Array):void
		{
			object = array;
		}
/**
* Retrieves Numeric representation of receiver coerced to a Boolean. 
* @returns Boolean representation of receiver.
*/
		public function get boolean():Boolean 
		{
			return Boolean(number);
		}
/**
* Sets Numeric representation of receiver to one or zero, depending on boolean. 
* @param Boolean if true underlying object will be set to one, otherwise zero.
*/
		public function set boolean(iBoolean:Boolean):void
		{
			object = iBoolean ? 1 : 0;
		}
/**
* Tests to see if receiver is null, zero or an empty String or Array.
* @returns Boolean true if receiver is null, zero or an empty String or Array.
*/
		public function get empty():Boolean
		{
			var is_empty:Boolean = true;
			if (object != null)
			{
				if (object is String)
				{
					is_empty = (((object as String) == UNDEFINED) || ((object as String).length == 0) || ((object as String) == '0'));
				}
				else if (object is Number)
				{
					is_empty = (isNaN((object as Number)) || ((object as Number) == 0));
				}
				else if (object is Array)
				{
					is_empty = ! Boolean((object as Array).length);
				}
				else is_empty = false;
			}
			return is_empty;
		}
/**
* Tests to see if receiver has the special value of Value.INDETERMINATE.
* @returns Boolean true if receiver is Value.INDETERMINATE.
*/
		public function get indeterminate():Boolean
		{
			return (object == Value.INDETERMINATE);
		}
/** 
* Retrieves the length of the String or Array representation of receiver. If receiver's underlying
* object is a String its length will be returned, even if it contains delimiters. 
* @returns int number of characters in String or items in Array.
*/
		public function get length():int
		{
			var n:int = 0;
			if (object != null)
			{
				if (object is String)
				{
					n = (object as String).length;
				}
				else if (object is Array)
				{
					n = (object as Array).length;
				}
				else if (object is Number)
				{
					n = String(object).length;
				}
			}
			return n;
		}
/** 
* Tests to see whether Number representation of receiver is valid.
* @returns Boolean true if Number representation is not a valid number.
*/
		public function get NaN():Boolean
		{
			return isNaN(Number(object));
		}
/**
* Retrieves Numeric representation of receiver.
* @returns Number representation of receiver or zero if NaN.
*/
		public function get number():Number 
		{
			var n:Number = Number(object);
			if (isNaN(n))
			{
				n = 0;
			}
			return n;
		}
/**
* Sets Numeric representation of receiver.
* @param number Number or NaN.
*/
		public function set number(number:Number):void
		{
			object = number;
		}
/**
* Retrieves String representation of receiver.
* @returns String representation of receiver or empty string, joining underlying object with delimiter if it is an Array.
*/
		public function get string():String 
		{
			var s:String;
			if (object == null)
			{
				s = '';
			}
			else if (object is Array)
			{
				s = (object as Array).join(delimiter);
			}
			else 
			{
				s = String(object);
			}
			return s;
		}
/**
* Sets String representation of receiver.
* @param string String or null.
*/
		public function set string(s:String):void
		{
			object = s;
		}
/**
* Tests to see if receiver is null or has the special value of Value.UNDEFINED.
* @returns Boolean true if receiver is null or Value.UNDEFINED.
*/
		public function get undefined():Boolean
		{
			return ((object == null) || (object == Value.UNDEFINED));
		}
/** 
* Used when converting between String and Array objects for splits and joins.
*/
		public var delimiter:String = ',';

/** 
* Underlying object.
*/
		public var object:Object = null;
	}
}