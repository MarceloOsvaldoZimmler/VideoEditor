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
	import com.moviemasher.constant.*;
	import com.moviemasher.events.*;
	import com.moviemasher.interfaces.*;
	import com.moviemasher.preview.*;
	import com.moviemasher.type.*;
	import com.moviemasher.type.*;
	import com.moviemasher.utils.*;
	import flash.display.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.utils.*;
	
/**
* Class represents PANEL tag, containing bars and controls
*
* @see BarView
* @see ControlView
*/
	public class PanelView extends View
	{
		
		public function PanelView()
		{
			super();
			_children = new Vector.<View>();
			_defaults.x = '0';
			_defaults.y = '0';
			_defaults.height = '*';
			_defaults.width = '*';
		
		}
		override public function getValue(property:String):Value
		{
			var value:Value;
			switch (property)
			{
				case EventType.FULLSCREEN:
					var allows:Boolean = true;
					try
					{
						allows = RunClass.MovieMasher['instance'].stage.allowsFullScreen;
					}
					catch(e:*)
					{
						// this shouldn't cause an error for FP 10.2 and above
					}
					if (! allows) value = new Value();
					else value = new Value(__fullscreen ? 1 : 0);
					break;
					
				default:
					value = super.getValue(property);
			}
			return value;
		}		
		override public function invalidate(type:String = ''):void
		{
			var was_invalidated:Boolean = _invalidated;
			super.invalidate(type);
			//if (getValue('id').equals('test')) RunClass.MovieMasher['msg'](this + '.invalidate ' + type);
			if (type == 'rect') __invalidatedSize = true;
			if (! was_invalidated) dispatchEvent(new Event(EventType.INVALIDATED));
		}	
		final public function setPanelRect(rect:Rectangle):void
		{
			var is_invalid:Boolean = rect.isEmpty();
			if (_setRectInvalid != is_invalid)
			{
				_setRectInvalid = is_invalid;
				invalidate('show');
			}
			if (! _setRectInvalid)
			{
				__invalidatedSize = ! ((_width == rect.width) && (_height == rect.height));
				__invalidatedPosition = ! ((x == rect.x) && (y == rect.y))
				if ( __invalidatedPosition || __invalidatedSize)
				{
					_rect = rect;
					invalidate('rect');				
				}
			}
		}
		override public function setValue(value:Value, property:String):Boolean
		{		
			var result:Boolean = false;
			switch (property)
			{
				case EventType.FULLSCREEN:
					if (__fullscreen != value.boolean)
					{
						__fullscreen = value.boolean;
						_dispatchEvent(property, value);
					}
					break;
				default: result = super.setValue(value, property);
			}
			return result; 
		}
		override public function toString():String
		{
			var s:String = '[PanelView';
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
				var bars:XMLList = _tag.bar;
				var z:int;
				var i:int;
				var bar:BarView;
				
				z = bars.length();
				if (z > 0)
				{
					for (i = 0; i < z; i++)
					{
						bar = new BarView(this);
						
						_children.push(bar);
						bar.tag = bars[i];
						_childrenSprite.addChild(bar);
						if (bar.isLoading)
						{
							_loadingThings++;
				
							bar.addEventListener(Event.COMPLETE, _tagCompleted);
						}
						
					}
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + ' PanelView._parseTag', e);
			}
		}
		override protected function _resizeSelf():void
		{	
			try
			{	
				if (__invalidatedPosition)
				{
					__invalidatedPosition = false;
					x = _rect.x;
					y = _rect.y;
				}
				if (__invalidatedSize)
				{
					__invalidatedSize = false;				
					_width = _rect.width;
					_height = _rect.height;
					__resizeBars();
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '._resizeSelf ' + _rect, e);
			}
		}		
		private function __resizeBars():void
		{
			try
			{
				var padding:Number;
				var content_width, content_height:Number;
				var verticals,centers,horizontals:Array;
				var max_center_flex:Number = 0;
				var max_center_hard:Number = 0;
					
				var align:String;
				var space:Object;
				var hORw:String;
				var bar:View;
				var i:Number;
				var hard:Size;
				var flex:Size;
				var flexible, center_flexible:Number;
				var data:Dictionary;
				var center_height:Number;
				var z:Number = _children.length;
				center_flexible = 0;
				center_height = 0;
				if (z)
				{
					data = new Dictionary();
					flex = new Size();
					hard = new Size();
					verticals = new Array();
					horizontals = new Array();
					centers = new Array();
					for (i = 0; i < z; i++)
					{
						bar = _children[i];
						if (bar.shouldBeVisible)
						{
							data[bar] = new Object();
							data[bar].align = bar.getValue('align').string;
							data[bar].rectangle = new Rectangle();
							data[bar].flexible = bar.getValue('flexible').number;
							switch (data[bar].align)
							{
								case 'center':
									data[bar].flexiblewidth = bar.getValue('flexiblewidth').number;
									data[bar].flexibleheight = bar.getValue('flexibleheight').number;
									centers.push(bar);
									break;
								case 'left':
								case 'right':
									verticals.push(bar);
									break;
								default:
									horizontals.push(bar);
							}
						}
					}
					z = centers.length;
					for (i = 0; i < z; i++)
					{
						bar = centers[i];
						flexible = data[bar].flexibleheight;
						if (flexible) 
						{
							center_flexible += flexible;
						}
						else 
						{
							data[bar].rectangle.height = bar.getValue('height').number;
							center_height += data[bar].rectangle.height;
						}
						flexible = data[bar].flexiblewidth;
						if (flexible) 
						{
							max_center_flex = Math.max(max_center_flex, flexible);
						}
						else 
						{
							data[bar].rectangle.width = bar.getValue('width').number;
							max_center_hard = Math.max(max_center_hard, data[bar].rectangle.width);
						}
					}
					hard.height += center_height;
					flex.width += max_center_flex;	
					flex.height += center_flexible;
					hard.width += max_center_hard;
					
					z = horizontals.length;
					for (i = 0; i < z; i++)
					{
						bar = horizontals[i];
						flexible = data[bar].flexible;
						if (flexible) flex.height += flexible;
						else 
						{
							data[bar].rectangle.height = bar.getValue('size').number;
							hard.height += data[bar].rectangle.height;
						}
					}
					z = verticals.length;
					if (z)
					{
						if (! (center_flexible || center_height)) 
						{
							center_flexible ++;
							flex.height ++;
						}
						for (i = 0; i < z; i++)
						{
							bar = verticals[i];
							flexible = data[bar].flexible;
							
							if (flexible) flex.width += flexible;
							else
							{
								data[bar].rectangle.width = bar.getValue('size').number;
								hard.width += data[bar].rectangle.width;
							}		
						}
					}
					padding = getValue(ControlProperty.PADDING).number + getValue('border').number;
					content_width = _width - (2 * padding);
					content_height = _height - (2 * padding);
					
					if (flex.width) flex.width = (content_width - hard.width) / flex.width;
					if (flex.height) flex.height = (content_height - hard.height) / flex.height;
					
					space = new Object();
					space.top = padding;
					space.left = padding;
					space.bottom = _height - padding;
					space.right = _width - padding;
					z = horizontals.length;
					for (i = 0; i < z; i++)
					{
						bar = horizontals[i];
						align = data[bar].align;
						flexible = data[bar].flexible;
						if (flexible)
						{
							data[bar].rectangle.height = flex.height * flexible;
						}
						data[bar].rectangle.width = content_width;
						if (align == 'bottom')
						{
							space[align] -= data[bar].rectangle.height;
						}
						data[bar].rectangle.x = padding;
						data[bar].rectangle.y = space[align];
						if (align == 'top')
						{
							space[align] += data[bar].rectangle.height;
						}
					}
					z = verticals.length;
					for (i = 0; i < z; i++)
					{
						bar = verticals[i];
						align = data[bar].align;
						flexible = data[bar].flexible;
						if (flexible)
						{
							data[bar].rectangle.width = flex.width * flexible;
						}
						data[bar].rectangle.height = flex.height * center_flexible + center_height;
						if (align == 'right')
						{
							space[align] -= data[bar].rectangle.width;
						}
						data[bar].rectangle.x = space[align];
						data[bar].rectangle.y = space.top;
						if (align == 'left')
						{
							space[align] += data[bar].rectangle.width;
						}
					}
					z = centers.length;
					for (i = 0; i < z; i++)
					{
						bar = centers[i];
						flexible = data[bar].flexiblewidth;
						if (flexible)
						{
							data[bar].rectangle.width = flex.width * flexible;
						}
						flexible = data[bar].flexibleheight;
						if (flexible)
						{
							data[bar].rectangle.height = flex.height * flexible;
						}
						data[bar].rectangle.y = space.top;
						space.top += data[bar].rectangle.height;
						
						
						data[bar].rectangle.x = space.left + Math.round(((space.right - space.left) - data[bar].rectangle.width) / 2);
						
					}
					z = _children.length;
					for (i = 0; i < z; i++)
					{
						bar = _children[i];
						if (data[bar] != null)
						{
							bar.setRect(data[bar].rectangle);
						}
					}
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__resizeBars', e);
			}

		}
		private var __fullscreen:Boolean = false;
		private var __invalidatedPosition:Boolean = false;
		private var __invalidatedSize:Boolean = false;
		private static  var controls:Object = new Object();
	
		
	}
}