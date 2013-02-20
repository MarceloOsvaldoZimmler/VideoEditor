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

	import com.moviemasher.interfaces.*;
	import flash.display.*;
	import flash.geom.*;
/**
* Class representing previews dragged around in the timeline and browser controls
*/
	public class DragData extends Object
	{
		public function DragData()
		{
			rootPoint = new Point();
			items = new Array();
		}
		public var callback:Function;
		public var previewCallback:Function;
		public var display:DisplayObjectContainer;
		public var dragged:Boolean;
		public var items:Array;
		public var local:Boolean;
		public var rootPoint:Point;
		public var clickPoint:Point;
		public var source:DisplayObject;
		public var target:IDrop;
	}
	
}