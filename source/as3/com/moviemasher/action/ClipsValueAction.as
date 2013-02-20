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
* Implimentation class represents changing a property of multiple {@link ISelectable} objects 
*
* @see ISelectable
*/
	public class ClipsValueAction extends MashAction implements IValueAction
	{
/**
* Constructs an {@link Action} object
*
* @param items Array of {@link ISelectable} objects that will be changed
* @param property String indicating property to change
* @param iValue {@link IValue} object holding new property to apply
* @see Selection
*/
		public function ClipsValueAction(items : Array, property : String, iValue:Value)
		{
			try
			{
				var mvalue:Value = items[0].getValue(ClipProperty.MASH);
				var imash:IMash = null;
				if ((! mvalue.empty) && mvalue.object is IMash) imash = mvalue.object as IMash;
				super(imash);
				__targets = items;
				__property = property;
				__undos = new Array();
				var z:uint = __targets.length;
				var i:uint;
				var clip:ISelectable = __targets[0];
					
				_type = clip.getValue(CommonWords.TYPE).string;
				var item_start:Number;
				for (i = 0; i < z; i++)
				{
					clip = __targets[i];
					if (clip != null)
					{
						item_start = clip.getValue(ClipProperty.STARTFRAME).number;
						__undos.push(clip.getValue(__property));
						__start = Math.min(__start, item_start);
						__end = Math.max(__end, item_start + clip.getValue(ClipProperty.LENGTHFRAME).number);
					}
				}
				value = iValue;
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg']('ClipsValueAction()', e);
			}
		}
/**
* The property being changed (read-only)
*
* @returns String containing property name
*/
		public function get property():String
		{
			return __property;
		}
/**
* Provides a selection list based on done state
*
* @returns Array of {@link ISelectable} objects
*/
		override public function get targets():Array
		{
			return ((__targets == null) ? new Array() : __targets);
		}
/**
* The {@link IValue} containing the new value (write-only)
*
* @param iValue {@link IValue} object containing new value to apply
*/
		public function set value(iValue:Value):void
		{
			__redos = new Array();
			var z:uint = __targets.length;
			var i:uint;
			for (i = 0; i < z; i++)
			{
				__redos.push(iValue);
			}
			_redoSelf();
		}
		override protected function _redo():void
		{ 
			__valuesAction(__redos);
		}
		override protected function _undo():void
		{ 
			__valuesAction(__undos);
		}
		private function __valuesAction(values : Array):void
		{
			var z:uint = __targets.length;
			var clip:ISelectable;
			var item_start:Number;
			var invalidated_length : Boolean = false;
			var i:uint;
			_start = __start;
			_end = __end;
			for (i = 0; i < z; i++)
			{
				clip = __targets[i];
				item_start = clip.getValue(ClipProperty.STARTFRAME).number;
				if (clip.setValue(values[i], __property)) invalidated_length = true;
				_start = Math.min(_start, item_start);
				_end = Math.max(_end, item_start + clip.getValue(ClipProperty.LENGTHFRAME).number);
			}
			if (invalidated_length && (_mash != null)) _mash.invalidateLength(_type);
		}
		private var __end:Number = Number.MIN_VALUE;
		private var __property:String;
		private var __redos:Array;
		private var __start:Number = Number.MAX_VALUE;
		private var __targets:Array;
		private var __undos:Array;
		
	}
}