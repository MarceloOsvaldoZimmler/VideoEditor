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
	import com.moviemasher.constant.*;
	import com.moviemasher.display.*;
	import com.moviemasher.type.*;
	import com.moviemasher.utils.*;
	import flash.display.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.utils.*;
/**
* Class represents a BAR tag containing controls
*
* @see Control
* @see ControlView
*/
	public class BarView extends View
	{
		public function BarView(panel:PanelView)
		{
			super();
			_children = new Vector.<View>();
			__panel = panel;
			_defaults.align = 'top';
			_defaults.size = '0';
			_defaults.spacing = '0';
			
		
			
		}

		override protected function _resizeSelf():void
		{
			var padding:Number = getValue(ControlProperty.PADDING).number + getValue('border').number;
			var spacing:Number = getValue(ControlProperty.SPACING).number;
			var hORw:String = (vertical ? 'width' : 'height');
			var yORx:String = (vertical ? 'x' : 'y');
			var wORh:String = (vertical ? 'height' : 'width');
			var xORy:String = (vertical ? 'y' : 'x');
			var bar_size:Size = new Size(_width - (2 * padding), _height - (2 * padding));
			var hard:Size = new Size();
			var flex:Size = new Size();
			var control:ControlView;
			var sizes:Dictionary = new Dictionary();
			var pos:Point;
			var now_pos:Point;
			var align:String;
			var i,z:int;
			var control_rect:Rectangle;
			var is_first:Boolean = true;
			var flex_factors:Vector.<int>;
			var should_be_visibles:Vector.<View>;
			
			pos = new Point(padding, padding);
			should_be_visibles = _visibleChildren(true);
			z = should_be_visibles.length;
			flex_factors = new Vector.<int>(z, true);
			
			for (i = 0; i < z; i++)
			{
				control = should_be_visibles[i] as ControlView;
				
				flex_factors[i] = control.flexFactor(vertical);
				if (flex_factors[i]) 
				{
					flex[wORh] += flex_factors[i];
					sizes[control] = new Size();
					sizes[control][hORw] = control.getValue(hORw).number;
					if (! sizes[control][hORw]) sizes[control][hORw] = bar_size[hORw];
				}
				else 
				{
					sizes[control] = control.dimensionsFromBarSize(bar_size[hORw], vertical);
					hard[wORh] += sizes[control][wORh];
				}
				if (i) hard[wORh] += spacing;
			}
			if (flex.width || flex.height)
			{
				if (flex[wORh]) flex[wORh] = (bar_size[wORh] - hard[wORh]) / flex[wORh];
				if (flex[hORw]) flex[hORw] = (bar_size[hORw] - hard[hORw]) / flex[hORw];
				for (i = 0; i < z; i++)
				{
					control = should_be_visibles[i] as ControlView;
					if (flex_factors[i]) 
					{
						sizes[control][wORh] = flex_factors[i] * flex[wORh];
					}
				}
			}
			for (i = 0; i < z; i++)
			{
				control = should_be_visibles[i] as ControlView;
				if (control.shouldBeVisible)
				now_pos = pos.clone();
				if (sizes[control][hORw] != bar_size[hORw])
				{
					if (sizes[control][hORw] > bar_size[hORw]) 
					{
						sizes[control][hORw] = bar_size[hORw];
					}
					else
					{
						align = control.getValue('align').string;
						switch (align)
						{
							case 'bottom' :
							case 'right' :
								now_pos[yORx] += bar_size[hORw] - sizes[control][hORw];
								break;
							case 'left':
							case 'top':
								break;
							default:
								now_pos[yORx] += Math.round((bar_size[hORw] - sizes[control][hORw]) / 2);
						}
					}
				}
				control_rect = new Rectangle(now_pos.x, now_pos.y, sizes[control].width, sizes[control].height);
				control.setRect(control_rect);
//				if (control_rect.isEmpty()) break;
				pos[xORy] += spacing + sizes[control][wORh];
			}
		}
		
		override public function getValue(property:String):Value
		{
			var value:Value = null;
			switch(property)
			{
				case 'width':
				case 'height':
				case 'size':
					value = super.getValue(property);
					if (value.string.indexOf('{') != -1) value.string = RunClass.ParseUtility['expression'](value.string, null, true);
					break;
				case 'flexible':
					value = new Value(flexible);
					break;
				case 'flexiblewidth':
				case 'flexibleheight':
					value = getValue(property.substr(8)); // width or height
					if (value.string.length && isNaN(Number(value.string))) value = new Value(value.string.length);
					else value = new Value(0);
					break;
				default:
					value = super.getValue(property);
			}
			return value;
		}
		override public function invalidate(type:String = ''):void
		{
			super.invalidate(type);
			switch(type)
			{
				case 'rect':
					__panel.invalidate();
					//invalidate('show');
					break;
				case 'show':
					__panel.invalidate('rect');
					break;
			}
		}
	
		override public function toString():String
		{
			var s:String = '[BarView';
			var id_string:String = getValue(CommonWords.ID).string;
			if (id_string.length) s += ' ID:' + id_string;
			s += ']';
			return s;
		}
		
		override protected function _parseTag():void
		{
			super._parseTag();
			try
			{
				var align:String = getValue('align').string;
				
				
				var size_attribute:String = getValue('size').string;
				if (size_attribute.length && isNaN(Number(size_attribute)))
				{
					flexible = size_attribute.length;
				}
	
				if (String(_tag.@vertical).length) vertical = super.getValue('vertical').boolean;
				else 
				{
					switch (align)
					{
						case 'left' :
						case 'right' : vertical = true;
					}
				}
				var controls:XMLList = _tag.control;
				var z:Number;
				var i:Number;
				var control:ControlView;
	
				
				z = controls.length();
				if (z > 0)
				{
					for (i = 0; i < z; i++)
					{
						control = new ControlView(__panel, this);
						
						_childrenSprite.addChild(control);
						_children.push(control);
						control.tag = controls[i];
						if (control.isLoading)
						{
							_loadingThings++;
					
							control.addEventListener(Event.COMPLETE, _tagCompleted);
						}
					}
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + ' BarView._parseTag controls', e);
			}
		}
		private var __panel:PanelView;
		public var flexible:Number = 0;
		public var vertical:Boolean = false;
	}
}