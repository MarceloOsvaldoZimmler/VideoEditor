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
	import com.moviemasher.type.*;
	import com.moviemasher.constant.*;
	import com.moviemasher.interfaces.*;
	
/**
* Implimentation class represents moving multiple audio and effect {@link IClip} objects 
*
* @see Action
* @see IClip
*/
	public class ClipsTimeAction extends MashAction
	{
		
/**
* Constructs an {@link Action} object
*
* @param iMash {@link IMash} object associated with the action
* @param items Array of {@link IClip} objects that will be moved
* @param track Integer indicating vertical position (track number) to insert items, or -1 for removal
* @param start Float indicating horizontal position (start time) to insert items
* @see Timeline
* @see Browser
*/
		public function ClipsTimeAction(iMash:IMash, items : Array, track : Number = -1, time:Time = null):void
		{
			super(iMash);
			var quantize:Number = _mash.getValue('quantize').number;
			if (time == null) time = new Time(0, quantize);
			else 
			{
				time = time.copyTime();
				time.scale(quantize);
			}
			_start = time.frame;
		
			__items = items;
		
			__redos = new Array();
			__undos = new Array();
			var start_offset:Number;
			var track_offset:Number;
			var z:uint = __items.length;
			var ob;
			var clip:IClip = __items[0] as IClip;
			_type = clip.type;
			var item_track : int;
			var item_start:Number;
			var i:uint;
			
			if (track != -1)
			{
				item_track = clip.track;
				var minORmax : String = ((_type == ClipType.EFFECT) ? 'max' : 'min');
				var select_start : Number = clip.startFrame;
				var select_track : Number = item_track;
				for (i = 1; i < z; i++)
				{
					clip = __items[i];
					item_start = clip.startFrame;
					item_track = clip.track;
					select_start = Math.min(select_start, item_start);
					select_track = Math[minORmax](select_track, item_track);
				}
				start_offset = start - select_start;
				track_offset = track - select_track;
			}
			
			for (i = 0; i < z; i++)
			{
				ob = {};
				clip = __items[i] as IClip;
				item_start = clip.startFrame;
				if (! clip.getValue(ClipProperty.MASH).undefined) 
				{
					_start = Math.min(_start, item_start);
					_end = Math.max(_end, item_start + clip.lengthFrame);
				}
				item_track = clip.track;
					
				if (track != -1)
				{
					ob.track = item_track + track_offset;
					ob.time = item_start + start_offset;
					_end = Math.max(_end, ob.time + clip.lengthFrame);
				}
				else ob.track = -1;
			
				__redos.push(ob);
				__undos.push({track: (clip.getValue(ClipProperty.MASH).undefined ? -1 : item_track), time: item_start});
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
			return ((__targets == null) ? new Array() : __targets);
		}
		override protected function _redo():void
		{ 
			__resetTracks(__redos);
		}
		override protected function _undo():void
		{ 
			__resetTracks(__undos);
		}
		
		private function __resetTracks(positions : Array):void
		{
			var clip:IClip;
			var z:uint = __items.length;
			var track_index:Number;
			var track:Number;
			var container:Array;
			var value:Value;
			var mash_value:Value = new Value(_mash);
			for (var i:uint = 0; i < z; i++)
			{
				clip = __items[i];
				container = _mash.tracks[_type];
				track = positions[i].track;
				
				if (track != -1) 
				{
					clip.setValue(new Value(track), ClipProperty.TRACK);
				}
				if (positions[i].time != null) 
				{
					value = new Value(positions[i].time);
					clip.setValue(value, ClipProperty.START);
				}
				track_index = container.indexOf(clip);
				if (track_index == -1)
				{
					if (track > -1)
					{
						container.push(clip);
						clip.setValue(mash_value, ClipProperty.MASH);
					}
				}
				else if (track == -1) 
				{
					clip.setValue(new Value(), ClipProperty.MASH);
					container.splice(track_index, 1);
				}
			}
			__targets = ((track > -1) ? __items : null);
			_mash.invalidateLength(_type);
		}
		private var __targets:Array;
		private var __undos:Array;
		private var __redos:Array;
		private var __items:Array;
		
	}
}