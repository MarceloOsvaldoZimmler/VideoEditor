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
* Class representing a moment in time
*/
	public class Time
	{
		public var frame:uint;
		public var fps:uint;
		public function copyTime():Time
		{
			return new Time(frame, fps);			
		}
		public function Time(start:uint = 0, rate:uint = 0)
		{
			frame = start;
			fps = rate;
		}
		public function frameForRate(rate:uint, rounding:String='round'):Number
		{
			var start:Number = frame;
			
			if (rate != fps)
			{
				var time:Time = fromSeconds(seconds, fps, rounding);
				start = time.frame;
			}
			return start;	
		}
		public function get seconds():Number
		{
			return Number(frame) / Number(fps);
		}
		static public function fromSeconds(seconds:Number, rate:uint, rounding:String = 'round'):Time
		{
			return new Time(Math[rounding](seconds * Number(rate)), rate);
		}
		public function add(time:Time):void
		{
			synchronize(time);
			frame += time.frame;
		}
		public function subtract(time:Time):uint
		{
			synchronize(time);
			var subtracted:uint = time.frame;
			if (subtracted > frame)
			{
				subtracted -= subtracted - frame;
			}
			frame -= subtracted;
			return subtracted;
		}
		public function divide(number:Number, rounding:String = 'round'):void
		{
			frame = Math[rounding](Number(frame) / number);
		}
		public function multiply(number:Number, rounding:String = 'round'):void
		{
			frame = Math[rounding](Number(frame) * number);
		}
		public function synchronize(time:Time, rounding:String = 'round'):void
		{
			if (time.fps != fps)
			{
				var gcf:uint = __lcm(time.fps, fps);
				scale(gcf, rounding);
				time.scale(gcf, rounding);
			}
		}
		public function scale(rate:uint, rounding:String = 'round'):void
		{
			if (fps != rate)
			{
				frame = Math[rounding](Number(frame) / (Number(fps) / Number(rate)));
				fps = rate;
			}
		}
		public function toString():String
		{
			return '[Time ' + frame + '@' + fps + ']';
		}	
		private function __lcm(a:uint, b:uint):uint
		{
			return (a * b / __gcd(a, b));
		}
		private function __gcd(a:uint, b:uint):uint
		{
			var t:uint;
			while (b != 0)
			{
				t = b;
				b = a % b;
				a = t;
			}
			return a;
		}
		public function min(time:Time):void
		{
			if (time != null)
			{
				synchronize(time);
				frame = Math.min(time.frame, frame);
			}
		}
		public function lessThan(time:Time):Boolean
		{
			var less:Boolean = false;
			if ((time != null) && time.fps && fps)
			{
				if (fps == time.fps) less = (frame < time.frame);
				else
				{
					// make copies so neither time is changed
					var time1:Time = copyTime();
					var time2:Time = time.copyTime();
					time1.synchronize(time2);
					less = (time1.frame < time2.frame);
				}
			}
			return less;
			
		}
		public function max(time:Time):void
		{
			if (time != null)
			{
				synchronize(time);
				frame = Math.max(time.frame, frame);
			}
		}
		public function isEqualToTime(time:Time):Boolean
		{
			var equal:Boolean = false;
			if ((time != null) && time.fps && fps)
			{
				if (fps == time.fps) equal = (frame == time.frame);
				else
				{
					// make copies so neither time is changed
					var time1:Time = copyTime();
					var time2:Time = time.copyTime();
					time1.synchronize(time2);
					equal = (time1.frame == time2.frame);
				}
			}
			return equal;
		}
		public function get timeRange():TimeRange
		{
			return new TimeRange(frame, 1, fps);
		}
		public function ratio(time:Time):Number
		{
			var n:Number = 0;
			if ((time != null) && time.fps && fps && time.frame)
			{
				if (fps == time.fps) n = (frame / time.frame);
				else
				{
					// make copies so neither time is changed
					var time1:Time = copyTime();
					var time2:Time = time.copyTime();
					time1.synchronize(time2);
					n = (Number(time1.frame) / Number(time2.frame));
				}
			}
			return n;
		}
	}
}