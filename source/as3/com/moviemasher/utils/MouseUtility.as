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
	import flash.display.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.utils.*;
	import com.moviemasher.constant.*;
/**
* Static class manages mouse dragging 
*
* @see Control
* @see Timeline
*/
	public class MouseUtility 
	{
	/*
		public static function hover(event:MouseEvent, moveFunction:Function, outFunction:Function):void 
		{
			// in case dragging is set, though it shouldn't be!
			__mouseUp(event);
			
			// update current position
			__mouseMove(event);
			
			__moveFunction = moveFunction;
			__outFunction = outFunction;

			if (__timer == null)
			{
				__timer = new Timer(100);
				__timer.addEventListener(TimerEvent.TIMER, __timed);
				__timer.start();
			}
			
		}
	*/
/**
* Begins a drag operation
*
* @param event MouseEvent object
* @param moveFunction Function to call as mouse is moving
* @param upFunction Function to call when mouse is released
*/
		public static function drag(display:DisplayObject, event:MouseEvent, moveFunction:Function, upFunction:Function):void 
		{
			// in case dragging is set, though it shouldn't be!
			__mouseUp(event);
			
			// we are now dragging
			dragging = true;
			__stage = display.stage;
			
			// update current position
			__mouseMove(event);
			
			
			if (__sprite == null)
			{
				__sprite = new Sprite();
				__sprite.addEventListener(MouseEvent.MOUSE_UP,__mouseUp);
				__sprite.addEventListener(MouseEvent.MOUSE_MOVE,__mouseMove);
			}
			__sprite.graphics.clear();
			RunClass.DrawUtility['fill'](__sprite.graphics, __stage.stageWidth, __stage.stageHeight, 0, 0);
			__stage.addChild(__sprite);
			__stage.addEventListener(Event.MOUSE_LEAVE,__mouseLeave);
				
			
			__moveFunction = moveFunction;
			__upFunction = upFunction;

			if (__timer == null)
			{
				__timer = new Timer(100);
				__timer.addEventListener(TimerEvent.TIMER, __timed);
				__timer.start();
			}
		}
		private static function __mouseMove(event:MouseEvent):void
		{
			if (event != null)
			{
				x = Math.round(event.stageX);
				y = Math.round(event.stageY);
				shiftIsDown = event.shiftKey;
			}
		}
		private static function __mouseUp(event:MouseEvent):void
		{
			if (dragging) 
			{
				__mouseMove(event);
				__timed(event);
				if (__timer != null)
				{
					__timer.removeEventListener(TimerEvent.TIMER, __timed);
					__timer.stop();
					__timer = null;
				}
				__moveFunction = null;
				dragging = false;
				__stage.removeEventListener(Event.MOUSE_LEAVE,__mouseLeave);
				
				if (__upFunction != null) __upFunction();
				__upFunction = null;
				if (__stage.contains(__sprite)) 
				{
					__stage.removeChild(__sprite);
				}
			}
		}
		private static function __mouseLeave(event:Event):void
		{
			//RunClass.MovieMasher['msg']('__mouseLeave ' + offstage + ' ' + dragging);
			if (dragging) __mouseUp(null);
		}
		private static function __timed(event:Event):void
		{
			if (! ( (__x == x) && (__y == y) && (__shiftIsDown == shiftIsDown) ) )
			{
				__x = x;
				__y = y;
				__shiftIsDown = shiftIsDown;
				if (__moveFunction != null) __moveFunction();
			}
		}
		private static var __moveFunction:Function;
		private static var __sprite:Sprite;
		private static var __stage:Stage;
		private static var __shiftIsDown : Boolean = false;
		private static var __timer:Timer;
		private static var __upFunction:Function;
		private static var __x : Number = -1;
		private static var __y : Number = -1;
		public static var dragging : Boolean = false;
		public static var mouseIsDown : Boolean = false;
		public static var shiftIsDown : Boolean = false;
		public static var x : Number = -1;
		public static var y : Number = -1;
		
	}
}