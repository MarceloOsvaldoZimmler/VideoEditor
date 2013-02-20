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
* Implimentation class represents splitting a video clip into two and inserting a frame clip
*
* @see Action
* @see IClip
*/
	public class ClipFreezeAction extends ClipSplitAction
	{

		public function ClipFreezeAction(clip:IClip, time:Time)
		{
			var quantize:uint = clip.media.getValue(MediaProperty.FPS).number;
			var mash_quantize:uint = clip.mash.getValue('quantize').number;
			time = time.copyTime();
			time.scale(mash_quantize);
		//	var frame:uint = time.frame;
			var clip_xml:XML;
			var clip_time:Time;
			clip_xml = clip.tag.copy();
			clip_xml.@type = ClipType.FRAME;
			clip_time = clip.clipTime(time);
			clip_time.scale(quantize);
			
			//RunClass.MovieMasher['msg'](this + ' ' + time + ' ' + clip_time);
			
			clip_xml.@frame = clip_time.frameForRate(quantize);
			clip_time = Time.fromSeconds(RunClass.MovieMasher['getOption']('mash', 'frameseconds'), mash_quantize);
			clip_xml.@length = clip_time.frame;
			delete clip_xml.@[ClipProperty.TRIMENDFRAME];
			delete clip_xml.@[ClipProperty.TRIMSTARTFRAME];
			delete clip_xml.@[ClipProperty.SPEED];
			__freezeClip = RunClass.Clip['fromXML'](clip_xml, clip.mash, clip.media);
			super(clip, time);
		}
		override protected function _redo():void
		{ 
			super._redo();
			var track:String = ClipType.VIDEO;
			var index:int = _clip.index;
			_mash.tracks[track].splice(index + 1, 0, __freezeClip);
			__freezeClip.setValue(new Value(_mash), ClipProperty.MASH);
			_mash.invalidateLength(track);

		}
		override protected function _undo():void
		{ 
			var track:String = ClipType.VIDEO;
			var index:int = _clip.index;
			
			__freezeClip.setValue(new Value(), ClipProperty.MASH);
			_mash.tracks[track].splice(index + 1, 1);

			super._undo();
		}
		
		private var __freezeClip:IClip;
	}
}