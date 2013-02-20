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
* Class representing height and width
*/
	public class Size
	{
		private var __w:Number = 0;
		private var __h:Number = 0;
		
		public function get width():Number 
		{
			return __w;
		}
		public function set width(w:*):void
		{
			var n:Number = Number(w);
			__w = n;
		}
		public function get height():Number 
		{
			return __h;
		}
		public function set height(h:*):void
		{
			var n:Number = Number(h);
			__h = n;
		}
		
		public function Size(w:Number = 0, h:Number=0)
		{
			width = w;
			height = h;
		}
		
		public function copy():Size
		{
			return new Size(__w, __h);
		}
		public function isEmpty():Boolean
		{
			return ! ((__w > 0) && (__h > 0));
		}
		
		public function toString():String
		{
			return String(__w) + 'x' + String(__h);
		}
		public function equals(size:Size):Boolean
		{
			var tf:Boolean = false;
			if (size != null)
			{
				tf = ((size.width == __w) && (size.height == __h));
			}
			return tf;
		}
		
	}
}