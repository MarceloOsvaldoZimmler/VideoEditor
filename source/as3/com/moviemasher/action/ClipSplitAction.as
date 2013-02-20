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
* Implimentation class represents splitting of a single {@link IClip} object into two
*
* @see Action
* @see IClip
*/
	public class ClipSplitAction extends MashAction
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
		public function ClipSplitAction(clip:IClip, time:Time)
		{
			
			super(clip.mash);
			time = time.copyTime();
			time.scale(_mash.getValue(MashProperty.QUANTIZE).number);
			__frame = time.frame;
			_clip = clip;
			
			__clipLength = _clip.lengthFrame;
			__clipTrimEnd = _clip.getValue(ClipProperty.TRIMENDFRAME).number;
			
			__splitClip = clip.clone();
			__splitClip.setValue(new Value(), ClipProperty.MASH);

			__targets = new Array(_clip);
			
			_type = _clip.type;
			_start = _clip.startFrame;
			_end = _start + __clipLength;
			
			// change start for audio and effects
			if (! _clip.canTrim)
			{
				if (! _clip.appearsOnVisualTrack()) 
				{
					__splitClip.startFrame = __frame;
				}
				// change length 
				__splitClip.setValue(new Value(_end - __frame), ClipProperty.LENGTHFRAME);
			}
			else 
			{
				// clip supports trimming
				__splitClip.setValue(new Value(_mash), ClipProperty.MASH);
				__splitClip.setValue(new Value(__splitClip.getValue(ClipProperty.TRIMSTARTFRAME).number + (__frame  - _start)), ClipProperty.TRIMSTARTFRAME);
				__splitClip.setValue(new Value(), ClipProperty.MASH);
			}
			_redo();
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
			var track:String = ClipType.VIDEO;
			var index:int = _clip.index;
			switch (_type)
			{
				case ClipType.AUDIO:
				case ClipType.EFFECT:
					track = _type;
					index = _mash.tracks[track].indexOf(_clip);
			}
			
			var value:Value;
			if (! _clip.canTrim)
			{
				// change length 
				value = new Value(__frame - _start);
				_clip.setValue(value, ClipProperty.LENGTHFRAME);
			}
			else 
			{
				// clip supports trimming
				value = new Value(_clip.getValue(ClipProperty.TRIMENDFRAME).number + (_end - __frame));
				_clip.setValue(value, ClipProperty.TRIMENDFRAME);

			}
			_mash.tracks[track].splice(index + 1, 0, __splitClip);
			__splitClip.setValue(new Value(_mash), ClipProperty.MASH);
			_mash.invalidateLength(track);
		}
		override protected function _undo():void
		{ 
			var track:String = ClipType.VIDEO;
			var index:int = _clip.index;
			switch (_type)
			{
				case ClipType.AUDIO:
				case ClipType.EFFECT:
					track = _type;
					index = _mash.tracks[track].indexOf(_clip);
			}
			
			__splitClip.setValue(new Value(), ClipProperty.MASH);
			_mash.tracks[track].splice(index + 1, 1);

			if (! _clip.canTrim)
			{
				// change length 
				_clip.setValue(new Value(__clipLength), ClipProperty.LENGTHFRAME);
			}
			else 
			{
				// clip supports trimming
				_clip.setValue(new Value(__clipTrimEnd), ClipProperty.TRIMENDFRAME);

			}
			_mash.invalidateLength(track);
		}
		private var __clipLength:Number;
		private var __clipTrimEnd:Number;
		private var __frame:Number;
		protected var _clip:IClip;
		private var __splitClip:IClip;
		private var __redos:Object;
		private var __targets:Array;
		private var __undos:Object;
	}
}