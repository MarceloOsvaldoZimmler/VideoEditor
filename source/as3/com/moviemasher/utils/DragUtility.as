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
	import com.moviemasher.constant.*;
	import com.moviemasher.interfaces.*;
	import com.moviemasher.type.*;
	import flash.display.*;
	import flash.events.*;
	import flash.geom.*;
/**
* Static class manages {@link Clip} dragging and dropping between {@link IDrop} objects
*
* @see IDrop
* @see Browser
* @see Timeline
*/
	public class DragUtility 
	{	
/**
* Defines an {@link IDrop} object as a drop target
*
* @param target {@link IDrop} object that will accept dragged media
*/
		public static function addTarget(target:IDrop):void 
		{
			var i:Number=__dragTargets.indexOf(target);
			if (i == -1) {
				__dragTargets.push(target);
			}
		}
/**
* Begins a drag operation
*
* @param items Array of {@link Clip} objects being dragged
* @param data Object containing drag information
*/
		public static function begin(event:MouseEvent, drag:DragData):void 
		{
			try
			{
				__dragData = drag;
				__clickTime=new Date();
				RunClass.MouseUtility['drag'](drag.source, event, __move, __dragRelease);
			}
			catch (e:*) 
			{
				RunClass.MovieMasher['msg'](DragUtility + '.begin', e);
			}
		}

/**
* Undefines an {@link IDrop} object as a potential drop target
*
* @param target {@link IDrop} object that will no longer accept dragged media
*/
		public static function removeTarget(target:IDrop):void 
		{
			var target_index=__dragTargets.indexOf(target);
			if (target_index != -1) 
			{
				__dragTargets.splice(target_index,1);
			}
		}
		private static function __dragTarget():IDrop 
		{

			var target:IDrop=null;

			var z:uint=__dragTargets.length;
			for (var i:uint=0; i < z; i++) {
				try {
					target=__dragTargets[i];
					if (target.overPoint(__dragData.rootPoint)) 
					{
						if ((! __dragData.local) || (target == __dragData.source))
						{
							break;
						}
					}
					target=null;
				} catch (e:*) {
					RunClass.MovieMasher['msg'](DragUtility, e);
				}
			}
			if (target != null) {
				try {
					if (! target.dragOver(__dragData)) {
						target=null;
					} 
				} catch (e:*) {
					RunClass.MovieMasher['msg'](DragUtility, e);
				}
			}
			return target;
		}
		private static function __move():void 
		{
			try 
			{

				__dragData.rootPoint = new Point(RunClass.MouseUtility['x'], RunClass.MouseUtility['y']);
				if (! __dragging) 
				{
					if ((__dragData.display == null) && (__dragData.previewCallback != null))
					{
						__dragData.display = __dragData.previewCallback(__dragData);
					}
					if (__dragData.display == null) return;
					__dragging = true;
					RunClass.PlayerStage['instance'].addChild(__dragData.display);
				}
					
				var cur_target:IDrop = __dragTarget();
				if (__dragData.target != cur_target) 
				{
					if (__dragData.target) __dragData.target.dragHilite(false);
					__dragData.target=cur_target;
					if (__dragData.target) __dragData.target.dragHilite(true);
				}
				__dragData.display.x=__dragData.rootPoint.x;
				__dragData.display.y=__dragData.rootPoint.y;
			
			} 
			catch (e:*) 
			{
				RunClass.MovieMasher['msg'](DragUtility, e);
			}
		}
		private static function __dragRelease():void 
		{
			try {
				
				var d=new Date();
				__dragData.dragged = (d.getTime() > __clickTime.getTime() + 250);
				__dragging = false;
				
				if (__dragData.display != null) 
				{
					if (__dragData.target != null) 
					{
					//	RunClass.MovieMasher['msg'](__dragData.target);
						if (__dragData.dragged) 
						{
							try 
							{
								__dragData.target.dragAccept(__dragData);
							}
							catch (e:*) 
							{
								RunClass.MovieMasher['msg'](__dragData.target + '.dragAccept', e);
							}
						}
						try
						{
							__dragData.target.dragHilite(false);
						}
						catch (e:*) 
						{
							RunClass.MovieMasher['msg'](__dragData.target + '.dragHilite', e);
						}
					}
					if (__dragData.display.parent != null)
					{
						__dragData.display.parent.removeChild(__dragData.display);
					}
				}
				try
				{
					if (__dragData.callback != null)
					{
						__dragData.callback(__dragData);
					}
				}
				catch (e:*) 
				{
					RunClass.MovieMasher['msg'](DragUtility + '.callback', e);
				}
				__dragData=null;
			} 
			catch (e:*) 
			{
				RunClass.MovieMasher['msg'](DragUtility + '.__dragRelease', e);
			}
		}
		private static var __dragData:DragData;
		private static var __dragTargets:Array=new Array();
		private static var __clickTime:Date;
		private static var __dragging:Boolean = false;
	}
}