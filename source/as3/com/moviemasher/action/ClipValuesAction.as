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

package com.moviemasher.action
{
	import com.moviemasher.interfaces.*;
	import com.moviemasher.type.*;
	import com.moviemasher.constant.*;
	
/**
* Implimentation class represents changing multiple properties of a single {@link IClip} object
*
* @see IClip
*/
	public class ClipValuesAction extends MashAction
	{
/**
* Constructs an {@link Action} object
*
* @param iMash {@link IMash} object associated with the action
* @param items Array of {@link IClip} objects that will be moved
* @param index Integer indicating position to insert items, or -1 for removal
* @see Timeline
* @see Browser
*/
		public function ClipValuesAction(clip : IClip, properties : Object)
		{
			super(clip.mash);
			__clip = clip;
			_type = __clip.type;
			__start = __clip.startFrame;
			__end = __start + __clip.lengthFrame;
			
			try
			{
				__targets = new Array(__clip);
				__undos = new Object();
				for (var k:String in properties)
				{
					__undos[k] = __clip.getValue(k);
				}
				values = properties;
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this, e);
			}
		}
/**
* The Object containing new key-value pairs (write-only)
*
* @param properties Object with {@link IValue} objects at property keys
*/
		public function set values(properties:Object):void
		{
			try
			{
				__redos = new Object();
				for (var k:String in properties)
				{
					__redos[k] = properties[k];
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this, e);
			}
			_redoSelf();
		}
/**
* Provides a selection list based on done state
*
* @returns Array of {@link IClip} objects
*/
		override public function get targets():Array
		{
			return __targets;
		}
		override protected function _redo():void
		{ 
			__propertiesAction(__redos);
		}
		override protected function _undo():void
		{ 
			__propertiesAction(__undos);
		}
		private function __propertiesAction(properties : Object) : void
		{
			try
			{
			
				var invalidated_length : Boolean = false;
				_start = __start;
				_end = __end;
				
				for (var property:String in properties)
				{
					if (__clip.setValue(properties[property], property)) 
					{
						invalidated_length = true;
					}
					
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this, e);
			}			
			try
			{
				var clip_start:Number = __clip.startFrame
				_start = Math.min(_start, clip_start);
				_end = Math.max(_end, clip_start + __clip.lengthFrame);
				if (invalidated_length && (_mash != null)) 
				{
					_mash.invalidateLength(_type);
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this, e);
			}			

			
		}
		private var __clip:IClip;
		private var __end:Number = Number.MIN_VALUE;
		private var __redos:Object;
		private var __start:Number = Number.MAX_VALUE;
		private var __targets:Array;
		private var __undos:Object;
	}
}