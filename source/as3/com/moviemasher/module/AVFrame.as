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
package com.moviemasher.module
{	
	import com.moviemasher.type.*;
	import com.moviemasher.constant.*;
	import com.moviemasher.interfaces.*;
	import com.moviemasher.type.*;
	import com.moviemasher.constant.*;
	import com.moviemasher.utils.*;
	import flash.display.*;
	import flash.events.*;
	import flash.utils.*;

/**
* Implementation class for image sequence based video module
*
* @see IModule
* @see IClip
*/
	public class AVFrame extends AVSequence
	{
		public function AVFrame()
		{
			_defaults.frame = '0';
		}
		override public function buffer(range:TimeRange, mute:Boolean):void
		{
			super.buffer(__getRange(), true); // always muted
		}
		override public function buffered(range:TimeRange, mute:Boolean):Boolean
		{
			return super.buffered(__getRange(), true); // always muted
		}
		override public function unbuffer(range:TimeRange):void
		{
			super.unbuffer(__getRange()); 
		}
		override public function set time(object:Time):void
		{
			super.time = __getTime();
		}	
		private function __getRange():TimeRange
		{
			var object:Time = __getTime();
			return object.timeRange;
		}
		private function __getTime():Time
		{
			return new Time(_getClipPropertyNumber('frame'), _getClipPropertyNumber(MediaProperty.FPS));
		}

	}
}