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
/**
* Class representing a span of time
*/
	public class TimeRange extends Time
	{
		public var length:uint = 1;
		static public function fromTimes(start:Time, end:Time):TimeRange
		{
			start.synchronize(end);
			return new TimeRange(start.frame, end.frame - start.frame, start.fps);
		}
		public function TimeRange(start:uint = 0, duration:uint = 1, rate:uint = 0)
		{
			length = Math.max(1, duration);
			super(start, rate);
		}
		/*
		override public function copyTime():Time
		{
			return copyTimeRange();
		}
		*/
		public function copyTimeRange():TimeRange
		{
			return new TimeRange(frame, length, fps);			
		}
		public function get endTime():Time
		{
			return new Time(end, fps);
		}
		override public function scale(rate:uint, rounding:String = 'round'):void
		{
			//trace('rate = ' + rate + ' fps ' + fps + ' length ' + length);
			if (fps != rate)
			{
				length = Math.max(1, Math[rounding](Number(length) / (Number(fps) / Number(rate))));
				//trace('rate = ' + rate + ' fps ' + fps + ' length ' + length);
				super.scale(rate, rounding);
			}
		}
		public function maxLength(time:Time):void
		{
			synchronize(time);
			length = Math.max(time.frame, length);
		}
		public function minLength(time:Time):void
		{
			synchronize(time);
			length = Math.min(time.frame, length);
		}
		public function set end(n:uint):void
		{
			length = Math.max(1, Number(n) - Number(frame));
		}
		public function get end():uint
		{
			return frame + length;
		}
		public function intersection(range:TimeRange):TimeRange
		{
			var result:TimeRange = null;
			var range1 = this;
			var range2 = range;
			if (range1.fps != range2.fps)
			{
				range1 = range1.copyTimeRange();
				range2 = range2.copyTimeRange();
				range1.synchronize(range2);
			}
			var last_start:uint = Math.max(range1.frame, range2.frame);
			var first_end:uint = Math.min(range1.end, range2.end);
			if (last_start < first_end)
			{
				result = new TimeRange(last_start, first_end - last_start, range1.fps);
			}
			return result;
		}
		public function isEqualToTimeRange(range:TimeRange):Boolean
		{
			var equal:Boolean = false;
			if ((range != null) && range.fps && fps)
			{
				if (fps == range.fps) equal = ((frame == range.frame) && (length == range.length));
				else
				{
					// make copies so neither range is changed
					var range1:TimeRange = copyTimeRange();
					var range2:TimeRange = range.copyTimeRange();
					range1.synchronize(range2);
					equal = ((range1.frame == range2.frame) && (range1.length == range2.length));
				}
			}
			return equal;
			
		}
		override public function toString():String
		{
			return '[TimeRange ' + frame + '+' + length + '=' + end + '@' + fps + ']';
		}	

	}
	
}