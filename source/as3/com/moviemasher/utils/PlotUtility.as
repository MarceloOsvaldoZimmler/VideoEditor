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
	import flash.geom.*;
	import com.moviemasher.type.*;
	import com.moviemasher.constant.*;
/** 
* Static class provides utility functions for working with arrays of percentages.
*/
	public class PlotUtility
	{
		public static function perValue(per : Number, value : Number, default_value: Number) : Number
		{
			return default_value + (((value - default_value) * per) / 100);
		}
		public static function perValues(per : Number, values : Object, defaults: Object, keys : Array = null) : Object
		{
			var update:Object = new Object();
			var k:String;
				
			try
			{
				if (keys == null) 
				{
					keys = new Array();
					for (k in defaults)
					{ 
						keys.push(k); 
					}	
				}
				var z:Number = keys.length;
				for (var i = 0; i < z; i++)
				{	
					k = keys[i];
					if (typeof(values[k]) == 'string')
					{
						update[k] = __perPlot(per, values[k], defaults[k]);
					}
					else update[k] = perValue(per, values[k], defaults[k]);
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg']('PlotUtility.perValues caught ' + k + ' ' + values[k] + ' '  + defaults[k] + '  '+ e);
			}
			return update;
		}
		public static function plotPoint(s : String, total_size : Object, offset_size : Object = null) : Point
		{
			if (offset_size == null) offset_size = {width: 0, height: 0};
			var plot : Array = string2Plot(s);
			
			var pt:Point = new Point(total_size.width - offset_size.width, total_size.height - offset_size.height);
			pt.x = pt.x * (plot[0] / 100);
			pt.y = pt.y * ((100 - plot[1]) / 100);
			return pt;
		}
		public static function string2Plot(s : String) : Array
		{
			var plot : Array;
			if (! s.length) plot = [0, 100, 100, 100];
			else 
			{
				plot = s.split(',');
				var z = plot.length;
				for (var i = 0; i < z; i++)
				{
					plot[i] = parseFloat(plot[i]);
				}
			}
			return plot;
		}
		public static function value(plot:*, percent : Number) : Number
		{
			var val:Number = 0;
			
			if (percent < 0.0) percent = 0.0;
		
		
			if (typeof(plot) == 'string') plot = string2Plot(plot);
			//percent = Math.round(percent);
			var left_plot;
			var right_plot;
			var z = plot.length;
			for (var i = 0; i < z; i += 2)
			{
				if (plot[i] == percent)
				{
					left_plot = [plot[i], plot[i + 1]];
					break;
				}
				if (plot[i] > percent)
				{
					left_plot = [plot[i - 2], plot[i - 1]];
					right_plot = [plot[i], plot[i + 1]];
					break;
				}
			}
			if (! left_plot) left_plot = [plot[z - 2], plot[z - 1]];
			if (! right_plot) return left_plot[1];
			val = __tweenValue(left_plot, right_plot, percent);
		
			return val;
		}
		private static function __perPlot(per : Number, value : String, default_value: String) : String
		{
			var values = string2Plot(value);
			var defaults = string2Plot(default_value);
			var z = values.length;
			for (var i = 0; i < z; i++)
			{
				values[i] = perValue(per, values[i], defaults[i]);
			}
			return String(values);
		}
		private static function __tweenValue(left_plot : Array, right_plot : Array, percent : Number) : Number
		{
			var percent_total = right_plot[0] - left_plot[0];
			var value_total = (right_plot[1] - left_plot[1]);
			var percent_change = percent - left_plot[0];
			var value_change = (percent_change * value_total) / percent_total;
			return left_plot[1] + value_change;
		}		
			
	}
}