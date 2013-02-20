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

package com.moviemasher.display
{
	import flash.display.*;
	import com.moviemasher.interfaces.*;
	import com.moviemasher.type.*;
	import com.moviemasher.constant.*;
	import flash.text.*;
	import com.moviemasher.utils.*;


/**
* Base class represents time marker for {@link Ruler} control
*
* @see Ruler
* @see IIncrement
*/
	public class Increment extends PropertiedSprite implements IIncrement
	{
		public function Increment()
		{
			_textField = new TextField();
			addChild(_textField);
			
		}
		public function set owner(object:IValued):void
		{
			_owner = object;
			RunClass.FontUtility['formatField'](_textField, _owner);
			_textField.autoSize = TextFieldAutoSize.LEFT;
			_textField.y = _owner.getValue(TextProperty.TEXTOFFSET).number;
		}
		public function set time(n:Number):void
		{
			_time = RunClass.StringUtility['timeString'](n, 10);
			_textField.text = RunClass.ParseUtility['brackets'](getValue(TextProperty.PATTERN).string, this);
			var x_pos:Number = 0;
			switch(_owner.getValue(TextProperty.TEXTALIGN).string)
			{
				case 'left':
					x_pos = - _textField.width;
					break;
				case 'right':
					x_pos = 0;
					break;
				default:
					x_pos = - Math.round(_textField.width / 2);
					
			}
			_textField.x = x_pos;
		
		}
		override public function getValue(property:String):Value
		{
			var value:Value;
			switch (property)
			{
				case 'time':
					value = new Value(_time);
					break;
				default: value = _owner.getValue(property);
			}
			return value;
		}
		public function set metrics(iMetrics:Size):void
		{
			if ((iMetrics != null) && (! iMetrics.isEmpty()) && (! iMetrics.equals(_metrics)))
			{
				_metrics = iMetrics;
				
				graphics.clear();
				
				RunClass.DrawUtility['fillBox'](graphics, -2, _metrics.height - 4, 2, 4, 0xFFFFFF, 50);
				RunClass.DrawUtility['fillBox'](graphics, 0, _metrics.height - 4, 2, 4, 0x000000, 50);
			}
		}
		public function get metrics():Size
		{
			if (_metrics != null) _metrics.width = _textField.width;
			return _metrics;
		}
		public function get displayObject():DisplayObjectContainer
		{
			return this;
		}
		protected var _owner:IValued;
		protected var _time:String;
		protected var _metrics:Size;
		protected var _textField:TextField;
		
		
	
	}
}