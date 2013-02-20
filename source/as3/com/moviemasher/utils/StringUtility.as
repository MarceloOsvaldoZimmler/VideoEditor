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
/**
* Static class provides basic String functions
*/
	public class StringUtility
	{
		public static function repeat(str:String, n:Number):String
		{
			str = String(str);
			if (! (str.length && n)) return '';
			var rs = '';
			for (var i = 0; i < n; i++)
			{
				rs += str;
			}
			return rs;
		}
		public static function replace(str:String, neadle:String, replacer:String):String
		{
			if (! str.length) return '';
			var pos2 = str.indexOf(neadle);
			if (pos2 < 0) return str;
			var pos1 = 0;
			var rs = '';
			
			while (pos2 > -1)
			{
				rs += str.substr(pos1, pos2 - pos1);
				rs += replacer;
				pos1 = pos2 + neadle.length;
				pos2 = str.indexOf(neadle, pos1);
				
			}
			rs += str.substr(pos1, str.length - pos1);
			return (rs);
		}
		public static function timeString(n:Number, fps:int, longest:Number = NaN):String
		{
			var s:String = '';
			try
			{
				if (isNaN(longest)) longest = n;
				
				
				var pad:int;
				var do_rest:Boolean = false;
				
				var time:int;
				time = 60 * 60; // an hour
				pad = 2;
				
				if (longest >= time)
				{
					if (n >= time)
					{
						s += strPad(String(Math.floor(n / time)), pad);
						do_rest = true;
						n = n % time;
					}
					else s += '00:';
					
				}
				
				time = 60; // a minute
				
				if (do_rest || (longest >= time))
				{
					if (do_rest) s += ':';
					if (n >= time)
					{
						s += strPad(String(Math.floor(n / time)), pad);
						do_rest = true;
						n = n % time;	
					}
					else s += '00:';
				}
				
				time = 1; // a second
				if (do_rest || (longest >= time))
				{
					if (do_rest) s += ':';
					if (n >= time)
					{
						s += strPad(String(Math.floor(n / time)), pad);
						do_rest = true;
						n = n % time;	
					}
					else s += '00';
					
				}
				else s += '00';
				
				if (fps > 1)
				{
					if (fps == 10) pad = 1;
					s += '.';
					if (n)
					{
						if (pad == 1) n = Math.round(n * 10) / 10;
						n = Math.round(100 * n);
						//n = Number(String(n).substr(2, 2));
						s += strPad(String(n), pad);
					}
					else s += strPad('0', pad);
				}
			
			}
			catch(e:*)
			{
				s = 'ERROR';
			}
			return s;
		}
		public static function strPad(input:String, pad_length:Number, pad_string:String = '0'):String
		{
			input = String(input);
			if (! pad_string.length) pad_string = ' ';
			if ((pad_length - input.length) > 0) input = repeat(pad_string, pad_length - input.length) + input;
			return input;
		}
		private static function __byteString(n:Number, bytes:Number, letter:String):String
		{
			var byte_string:String = '';
			if (n >= bytes)
			{
				byte_string += Math.floor(n / bytes);
				n = n % bytes;
				if (n)
				{
					byte_string += '.' + Math.round((n / bytes) * 10);
				}
				byte_string += letter;
			}			
			return byte_string;
		}
		public static function dirname(s:String):String
		{
			var result:String = '';
			if ((s != null) && s.length)
			{
				var pos:int = s.lastIndexOf('/');
				if (pos != -1) result = s.substr(0, pos);
			}
			return result;
		}
		public static function byteString(n:Number):String
		{
			var byte_string:String;
			
			byte_string = __byteString(n, 1024 * 1024 * 1024, 'G');
			if (! byte_string.length)
			{
				byte_string = __byteString(n, 1024 * 1024, 'M');
			}
			if (! byte_string.length)
			{
				byte_string = __byteString(n, 1024, 'K');
			}
			if (! byte_string.length)
			{
				byte_string = n + 'B';
			}
			return byte_string;
		}
		
	}
}
