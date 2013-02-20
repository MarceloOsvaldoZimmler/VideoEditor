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
	import com.moviemasher.type.*;
	import com.moviemasher.constant.*;
	import com.moviemasher.interfaces.*;
	import com.moviemasher.options.*;
	import com.moviemasher.type.*;
	import com.moviemasher.constant.*;
	import com.moviemasher.utils.*;
	import flash.display.*;
	import flash.geom.*;
	import flash.text.*;
	
/**
* Class represents a tooltip displayer 
*
* @see ControlIcon
* @see ITooltip
*/
	public class Tooltip extends Sprite implements ITooltip, IValued
	{
		public function Tooltip()
		{
			_textField = new TextField();
			
			addChild(_textField);
			
			_point = new Point();
		}
		
		public function set tag(xml:XML):void
		{
			_tag = xml;
			
			_options = new PreviewOptions();
			_options.tag = _tag;
			RunClass.FontUtility['formatField'](_textField, this);
			_textField.autoSize = TextFieldAutoSize.LEFT;
		}
		
		public function get displayObject():DisplayObjectContainer
		{
			return this;
		}
		public function get point():Point
		{
			return _point;
		}
		public function set point(pt:Point):void
		{
			_point.x = pt.x;
			_point.y = pt.y;
			pt.x += 12;
			pt.y += 12;
			
			var w:Number = Math.round(width / 2);
			var h:Number = height;
			pt.x -= w;
			
			if ((pt.x - w) < 0)
			{
				pt.x = 0;
			}
			else if ((pt.x + w) > RunClass.MovieMasher['instance'].width)
			{
				pt.x = RunClass.MovieMasher['instance'].width - width;
			}
			if ((pt.y + h) > RunClass.MovieMasher['instance'].height)
			{
				pt.y = RunClass.MovieMasher['instance'].height - h;
			}
			
			x = y = 0;
			pt = globalToLocal(pt);
			
			x = pt.x;
			y = pt.y;
		}
		public function set text(iString:String):void
		{
			var should_be_visible:Boolean = Boolean(iString.length);
			visible = should_be_visible;
			if (should_be_visible)
			{
				_textField.text = iString;
				_options.setValue(new Value(_textField.width), 'width');
				_options.setValue(new Value(_textField.height), 'height');
				
				RunClass.DrawUtility['shadowBox'](_options, this);
			}
		}
		public function getValue(property:String):Value
		{
			return new Value(_tag.@[property]);
		}
		protected var _textField:TextField;
		protected var _tag:XML;
		protected var _options:PreviewOptions;
		protected var _point:Point;
	}
}