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
	import com.moviemasher.events.*;
	import com.moviemasher.interfaces.*;
	import com.moviemasher.type.*;
	import com.moviemasher.constant.*;
	
/**
* Implimentation class represents moving multiple visual {@link IClip} objects 
*
* @see IClip
*/
	public class ClipsIndexAction extends MashAction
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
		public function ClipsIndexAction(iMash:IMash, items : Array, index : Number = -1):void
		{
			super(iMash);
			_end = Infinity;
			
			__redos = new Array();
			__undos = new Array();
			items.sortOn('startFrame', Array.NUMERIC);
			var z:uint = items.length;
			var undo_index:Number;
			var clip:IClip;
			var redo_index:Number = index;
			var new_targets:Array = new Array();
			for (var i:uint = 0; i < z; i++)
			{
				clip = items[i];
				undo_index = _mash.tracks.video.indexOf(clip);
				__undos.push({item: clip, index: undo_index});
				if (undo_index > -1) 
				{
					_start = Math.min(_start, clip.startFrame);
					
					if (undo_index < redo_index) redo_index--;
					_mash.tracks.video.splice(undo_index, 1);
					clip.setValue(new Value(), ClipProperty.MASH);
				}
				__redos.push({item: clip, index: redo_index});
				if (redo_index > -1) 
				{
					new_targets.push(clip);
					if (redo_index == 0)
					{
						_start = 0;
					}
					else if (_start && ((redo_index - 1) < _mash.tracks.video.length))
					{
						_start = Math.min(_start, _mash.tracks.video[(redo_index - 1)].startFrame + _mash.tracks.video[(redo_index - 1)].lengthFrame);
					}
					_mash.tracks.video.splice(redo_index, 0, clip);
					redo_index++;
					clip.setValue(new Value(_mash), ClipProperty.MASH);
				}
			}
			__targets = new_targets;
			_mash.invalidateLength(ClipType.VIDEO);
			_done = true;
			eventDispatcher.dispatchEvent(new ActionEvent(this));
		}
/**
* Provides a selection list based on done state
*
* @returns Array of {@link IClip} objects
*/
		override public function get targets():Array
		{
			return ((__targets == null) ? new Array() : __targets);
		}
		override protected function _redo():void
		{ 
			__resetClipIndices(__redos);
		}
		override protected function _undo():void
		{ 
			__resetClipIndices(__undos);
		}
		private function __resetClipIndices(indices : Array):void
		{
			var z : Number = indices.length;
			var mash_index : Number;
			var ob:Object;
			var clip:IClip;
			var new_targets:Array = new Array();
			for (var i = z - 1; i > -1; i--)
			{
				ob = indices[i];
				clip = ob.item;
				mash_index = _mash.tracks.video.indexOf(clip);
				if (mash_index > -1) 
				{
					_mash.tracks.video.splice(mash_index, 1);
					clip.setValue(new Value(), ClipProperty.MASH);
				}
				if (ob.index > -1) 
				{
					_mash.tracks.video.splice(ob.index, 0, clip);
					new_targets.push(clip);
					clip.setValue(new Value(_mash), ClipProperty.MASH);
				}
			}
			__targets = new_targets;
			_mash.invalidateLength(ClipType.VIDEO);
		}
		private var __redos:Array;
		private var __targets:Array;
		private var __undos:Array;
	}
}