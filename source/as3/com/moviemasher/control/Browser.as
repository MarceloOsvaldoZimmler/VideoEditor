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
package com.moviemasher.control
{
	import com.moviemasher.events.*;
	import com.moviemasher.source.*;
	import com.moviemasher.core.Selection;
	import com.moviemasher.core.BrowserSelection;
	import com.moviemasher.interfaces.*;
	import com.moviemasher.options.*;
	import com.moviemasher.preview.*;
	import com.moviemasher.type.*;
	import com.moviemasher.constant.*;
	import com.moviemasher.utils.*;
	import flash.display.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.system.*;
	import flash.text.*;
	import flash.utils.*;

/**
* Implimentation class represents a media browsing control
*/

	public class Browser extends ControlPanel
	{
		public function Browser()
		{
			__sourceProxy = new SourceProxy();
			_defaultPreviewClass = BrowserPreview;
			
			_defaults.previewwidth = '160';
			_defaults.previewheight = '';
			_defaults.valueattribute = 'id';
			_defaults.source = '';
			
		}
		override public function dragAccept(drag:DragData):void
		{ 
			var pt:Point = _clickSprite.globalToLocal(drag.rootPoint);
			var info:Object = __dragInfo(pt);
			if (info.index == -1) info.index = _sourceLength;
			if (_source == null) _source = RunClass.MovieMasher['source']();
			var items:Array = _source.items.concat();
			if (drag.source == this)
			{
				var pos:int = items.indexOf(drag.items[0]);
				if (pos == info.index) return;
				if (pos < info.index) info.index--;
				
				items.splice(pos, 1);
			}
			items.splice(info.index, 0, drag.items[0]);
			_source.items = items;
			//RunClass.MovieMasher['msg'](this + '.dragAccept');
			dispatchPropertyChange();
		}
		override public function dragOver(drag:DragData):Boolean
		{
			var clip:IClip;
			var i,z:uint;
			var ok:Boolean;
			var clip_id:String;
			
			z = drag.items.length;
			if (z != 1) return false;
			
			ok = (drag.source == this);
			if (! ok) ok = super.dragOver(drag);
			if (ok)
			{
				
				ok = (drag.source != RunClass.MovieMasher['getByID'](ReservedID.TIMELINE));
				ok = ok && (drag.items[0] is IClip);
				if (ok)
				{
					clip = (drag.items[0] as IClip);
					clip_id = clip.getValue(CommonWords.ID).string;
					z = _source.items.length;
					for (i = 0; i < z; i++)
					{
						if (_source.items[i].getValue(CommonWords.ID).equals(clip_id))
						{
							ok = (drag.source == this);
							break;
						}
					}
				}
			}
			if (ok)
			{
				var pt:Point = _clickSprite.globalToLocal(drag.rootPoint);
				var info:Object = __dragInfo(pt);
				var previewwidth:Number = getValue('previewwidth').number;
				var autoscroll:Number = getValue('autoscroll').number;
				var spacing:Number = getValue(ControlProperty.SPACING).number;
				var padding:Number = getValue(ControlProperty.PADDING).number;
				if (pt.y < autoscroll)
				{
					__doScroll(-1, false);
				}
				else if (pt.y > (_height - autoscroll))
				{
					__doScroll(1, false);
				}
				if (info.index == -1)
				{
					_dragHilite.width = _width;
					_dragHilite.height = _height;
					_dragHilite.x = 0;
					_dragHilite.y = 0;				
				}
				else
				{
					_dragHilite.width = spacing;
					_dragHilite.height = _previewHeight;
					_dragHilite.x = padding + (info.column * (previewwidth + spacing) - spacing);
					_dragHilite.y = padding + (info.row * (_previewHeight + spacing)) - _scroll.y;
				}
			}
			return ok;
		}
		override public function downPreview(preview:IPreview, event:MouseEvent):void
		{
			try
			{
							
				var media_tag:XML;
				var is_clip:Boolean;
				var media_item:*;
				var clip:IClip;
				for (var t:* in _visibleClips)
				{
					if (_visibleClips[t] == preview)
					{
						is_clip = (t is IClip);
						if (is_clip)
						{
							clip = (t as IClip);
							media_item = clip.media;
							media_tag = media_item.tag;
						}
						else media_tag = new XML(t);
						break;
					}
				}
			
					
				if (media_tag != null)
				{
					var id:String = String(media_tag.@id);
					if (id.length)
					{
						if (clip == null)
						{
							media_item = RunClass.Media['fromXML'](media_tag);
							if (media_item != null)
							{
								// including mash on creation so composites are found and quantize has value
								var valued:IValued = RunClass.MovieMasher['getByID'](ReservedID.PLAYER) as IValued;
								var mash:IMash = null;
								if (valued != null)
								{
									valued = valued.getValue(ClipType.MASH).object as IValued;
									if (valued && (valued is IMash)) mash = valued as IMash;
								}
								clip = RunClass.Clip['fromMedia'](media_item, null, mash);
								// we must calculate length here, while mash is set
								clip.getValue('length');
								// unset mash so ClipsTimeAction responds properly
								clip.setValue(new Value(), ClipProperty.MASH);								
							}
						}
						if (clip != null)
						{
							if (! getValue('nodrag').boolean) 
							{
								var drag_data:DragData = new DragData();
								drag_data.items.push(clip);
								drag_data.clickPoint = new Point(event.localX, event.localY);
								drag_data.source = this;
								drag_data.callback = __finishedDrag;
								drag_data.previewCallback = __dragPreview;
								drag_data.local = Boolean(_tag.drop.length());
								RunClass.DragUtility['begin'](event, drag_data);
							
								_changeCursor('drag');
							}
							if ((! is_clip) &&  getValue('selectable').boolean) 
							{
								_selection.items = [media_item];
							
								_updateSelection();
							}
						}
					}
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.downPreview', e);
			}
		}
		override public function getValue(property:String):Value
		{
			var value:Value;
			switch (property)
			{
				case 'parameters':
					value = new Value(__sourceProxy);
					break;
				case 'source':
					value = new Value(_source);
					break;
				case 'selection':
					value = new Value(_selection);
					break;
				case _property:
					value = (_tag.drop.length() ? new Value(_source.items) : _selection.getValue(getValue('valueattribute').string));
					break;
				default: value = super.getValue(property);
			}
			return value;
		}
		override public function initialize():void
		{
			super.initialize();
			if (! _source)
			{
				var value:Value = super.getValue('source');
				if (! value.empty) 
				{
					setValue(value, 'source');
				}
			}
		}
		override public function resize():void
		{
			super.resize();
			try
			{
				//RunClass.MovieMasher['msg'](this + '.resize ' + _width + 'x' + _height);
				if (_width && _height) 
				{
					var valued:IValued = null;
					if (! _previewHeight)
					{
						/*
						valued = RunClass.MovieMasher['getByID'](ReservedID.PLAYER) as IValued;
						if (valued == null) valued = RunClass.MovieMasher['getByID'](ReservedID.TIMELINE) as IValued;
						if (valued != null)
						{
							valued = valued.getValue(ClipType.MASH).object as IValued;
						}
						else valued = RunClass.MovieMasher['getByID'](ReservedID.MASH) as IValued;
						RunClass.MovieMasher['msg'](this + '.resize ' + valued + ' ? ' + RunClass.MovieMasher['getByID'](ReservedID.PLAYER) + ' ? ' + RunClass.MovieMasher['getByID'](ReservedID.TIMELINE));
						if (valued != null) __calcPreviewHeight();
						else 
						*/
						_previewHeight = getValue('previewheight').number;
						if (! _previewHeight) __calcPreviewHeight();
					}
					if (_previewHeight > 0)
					{
						var previewwidth:Number = getValue('previewwidth').number;
						var spacing:Number = getValue(ControlProperty.SPACING).number;
						var padding:Number = getValue(ControlProperty.PADDING).number;
						
						var innerwidth:Number = (_width - (2 * padding));
						_columns = Math.floor(innerwidth / previewwidth);
						if (((_columns * previewwidth) + ((_columns - 1) * spacing)) > innerwidth) _columns --;
						
						try
						{
							if (! __vScrollReset())
							{
								_drawClips();
							}
						}
						catch(e:*)
						{
							RunClass.MovieMasher['msg'](this + '.resize', e);
						}
					}
					//else RunClass.MovieMasher['msg'](this + '.resize _columns=' + _columns + ' _previewHeight=' + _previewHeight + ' valued=' + valued);
					
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.resize', e);
			}
		}
		override public function setValue(value:Value, property:String):Boolean
		{		
			try
			{
				var dispatch:Boolean = true;
				
				switch(property)
				{
					case 'selection':
						__setSelectionValue(value);
						break;
					case 'refresh':
						__sourceChange(null);
						break;
					case 'source':
					//	RunClass.MovieMasher['msg'](this + '.setValue set source null then ' + value.string);

						source = null;
						source = RunClass.MovieMasher['source'](value.string);
						//RunClass.MovieMasher['msg'](this + '.setValue super');
						super.setValue(value, property);
						break;
					default: 
						if (_property == property)
						{
							dispatch = false;
							if ((_source != null) && (_tag.drop.length()))
							{
								//RunClass.MovieMasher['msg'](this + '.setValue value = ' + _source);
								_source.items = (((value == null) || value.empty) ? new Array() : value.array);
							}
						}
						else super.setValue(value, property);
						
				}
				if (dispatch) _dispatchEvent(property);
				
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.setValue', e);
			}
			return false;
		}
		override public function updateTooltip(tooltip:ITooltip):Boolean
		{
			var dont_delete:Boolean = false;
			
			try
			{
				var tip:String = '';
				var pt:Point = globalToLocal(tooltip.point);
				var info:Object = __dragInfo(pt);
				var not_over_item = ((! _sourceLength) || info.off || (info.index == -1));
				var something:*;
				var ipreview:IPreview;
				tip = getValue('tooltip').string;
				var xmlORclip:* = null;
				
				if (! not_over_item)
				{
					xmlORclip = _source.getItemAt(info.index);
					if (xmlORclip != null)
					{
						something = ((xmlORclip is XML) ? xmlORclip.toXMLString() : ((xmlORclip is IClip) ? xmlORclip : null));
						if (something != null)
						{
							ipreview = _visibleClips[something];
							if (ipreview != null) 
							{
								dont_delete = ipreview.updateTooltip(tooltip);
								if (dont_delete) return dont_delete;
							}
						}
						if ((! dont_delete) && tip.length && (tip.indexOf('{') != -1)) tip = RunClass.ParseUtility['brackets'](tip, xmlORclip);
					}
				}
				if (! dont_delete) dont_delete = Boolean(tip.length) && (tip.indexOf('{') == -1);
				
				if (dont_delete) tooltip.text = tip;
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.updateTooltip', e);
			}		
			return dont_delete;
		}
		public function get source():ISource
		{
			return _source;
		}
		public function set source(iSource:ISource):void
		{
			if (_source != iSource)
			{
				if (_source != null)
				{
					//RunClass.MovieMasher['msg'](this + '.source removeEventListener ' + _source);
					_source.removeEventListener(Event.CHANGE, __sourceChange);
					_deleteClips();
					_visibleClips = new Dictionary();
				}
				_source = iSource;
				__sourceProxy.source = null;
				__sourceProxy.setValue(new Value(''), 'terms');
				__sourceProxy.source = _source;
				
				if (_source != null)
				{
					//RunClass.MovieMasher['msg'](this + '.source addEventListener ' + _source);
					_source.addEventListener(Event.CHANGE, __sourceChange);
					__sourceChange(null);
				}
			}
		}
		override protected function _adjustVisibility():void
		{
//			resize();
		}
		override protected function _createChildren():void
		{
			super._createChildren();
			var list:XMLList = _tag.drop;
			var xml:XML;
			if (list.length())
			{
				RunClass.DragUtility['addTarget'](this);
				for each(xml in list)
				{
					_dropTypes[xml.@[CommonWords.TYPE]] = true;
				}
				//RunClass.MovieMasher['msg'](this + '._createChildren set source');
				source = RunClass.MovieMasher['source']();
			}
		}
		override protected function _createSelection():Selection
		{
			return new BrowserSelection();
		}

		override protected function _drawClips(force:Boolean = false):void
		{
			try
			{
									
				var new_clips:Dictionary = new Dictionary();
				if ((_source != null) && (_columns > 0))
				{
					var padding:Number = getValue(ControlProperty.PADDING).number;
					var border:Number = getValue('border').number;
					var spacing:Number = getValue(ControlProperty.SPACING).number;
					var x_pos:Number = padding;
					var y_pos:Number = padding - _scroll.y;
					var previewwidth:Number = getValue('previewwidth').number;
					
					var index:Number = 0;
					var rowvisible:Boolean;
					var rows:Number = Math.ceil(_sourceLength / _columns);
					var first_item:Number;
					var ipreview:IPreview;
					var result:*;
					var key:*;
					
					for (var row:Number = 0; row < rows; row++)
					{
						rowvisible = ( ! ( ((y_pos + _previewHeight) < 0) || (y_pos > _height) ) );
						if (rowvisible) 
						{
							for (var i:Number = 0; (i < _columns) && (index < _sourceLength); i++)
							{
								result = _source.getItemAt(index);
								
								if (result != null)
								{
									key = ((result is XML) ? result.toXMLString() : ((result is IClip) ? result : null));
									if (key != null)
									{
										ipreview = _visibleClips[key];
										if (ipreview == null)
										{
											ipreview = ((result is XML) ? __drawMedia(result) : ((result is IClip) ? __drawClip(result) : null));
										}
										
										if (ipreview != null)
										{
										
											delete _visibleClips[key];
											
											new_clips[key] = ipreview;
											ipreview.displayObject.x = x_pos;
											ipreview.displayObject.y = y_pos;
											x_pos += previewwidth + spacing;
										}
									}
									index++;
								}
							}
						}
						else
						{
							index += _columns;
						}
						y_pos += _previewHeight + spacing;
						x_pos = padding;
					}
				}
				//else RunClass.MovieMasher['msg'](this + '._drawClips ' + _source + ' ' + _columns);
				_deleteClips();
				_visibleClips = new_clips;
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '._drawClips', e);
			}
		}
		override protected function _itemOptions(type:String):IOptions
		{
			var options:IOptions = super._itemOptions(type);
			if (options != null)
			{
				options.setValue(getValue('previewwidth'), 'width');
				options.setValue(getValue('previewheight'), 'height');
			}
			return options;
		}
		override protected function _selectionDidChange(event:Event):void
		{
			super._selectionDidChange(event);
			dispatchPropertyChange();
		}
		private function __calcPreviewHeight():void
		{
			try
			{
				var options:IOptions = _itemOptions(ClipType.VIDEO);
				if (options != null) 
				{
					_previewHeight = Math.round(options.metrics.height);
					//RunClass.MovieMasher['msg'](this + '.__calcPreviewHeight ' + options.metrics);
				}
				//else RunClass.MovieMasher['msg'](this + '.__calcPreviewHeight no _itemOptions');
				
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__calcPreviewHeight', e);
			}
		}
		private function __createPreview(media_tag:XML, clip:IClip = null):IPreview
		{			
			//RunClass.MovieMasher['msg'](this + '.__createPreview ' + clip);
				
			var clip_tag:XML = null;
			if (clip != null) clip_tag = clip.tag;
			var preview:IPreview = null;
			try
			{
				var media_type:String = '';
				var media_id:String = '';
				var media_icon:String = '';
				var media_label:String = '';
				if (clip_tag != null) media_type = String(clip_tag.@type);
				if (! media_type.length) media_type = String(media_tag.@type);
				if (clip_tag != null) media_id = String(clip_tag.@id);
				if (! media_id.length) media_id = String(media_tag.@id);
				if (clip_tag != null) media_icon = String(clip_tag.@icon);
				if (! media_icon.length) media_icon = String(media_tag.@icon);
				if (clip_tag != null) media_label = String(clip_tag.@label);
				if (! media_label.length) media_label = String(media_tag.@label);
				
				
				
				if (media_type.length && media_id.length)
				{
					var options:IOptions = _itemOptions(media_type);
					if (options != null)
					{
						// TODO: remove these
						options.setValue(new Value(media_id), CommonWords.ID);
						
						
						if (media_icon.length)
						{
							options.setValue(new Value(media_icon), 'icon');
						}
						
						if (! media_label.length)
						{
							media_label = media_id;
						}
						options.setValue(new Value(media_label), 'label');
						preview = _instanceFromOptions(options, media_tag, clip);
					}
				}
				else RunClass.MovieMasher['msg'](this + '.__createPreview media ' + media_type + ' ' + media_id);
			
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__createPreview', e);
			}

			return preview;
			
		}
		private function __dragInfo(pt:Point):Object
		{
			var ob:Object = new Object();
			ob.index = -1;
			try
			{
				if (_sourceLength)
				{
					var spacing:Number = getValue(ControlProperty.SPACING).number;
					var padding:Number = getValue(ControlProperty.PADDING).number;
					ob.column = Math.floor((pt.x - padding )/(getValue('previewwidth').number + spacing));
					ob.row = Math.floor(((pt.y + _scroll.y) - padding)/(_previewHeight + spacing));
					ob.off = (ob.column >= _columns);
					if (ob.off)
					{
						
						ob.column = 0;
						ob.row++;
					}
					ob.index = (ob.row * _columns) + ob.column;
					if (ob.index >= _sourceLength)
					{
						ob.index = -1;
					}
				}	
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__dragInfo', e);
			}
			return ob;
		}
		private function __dragPreview(drag_data:Object):DisplayObjectContainer
		{
			var sprite:Sprite = new Sprite();
			try
			{
				var iclip:IClip = drag_data.items[0];
				sprite.alpha = .7;				
				var ipreview:IPreview = __createPreview(iclip.media.tag, iclip);
				if (ipreview != null)
				{
					ipreview.selected = true;
					sprite.addChild(ipreview.displayObject);
					ipreview.displayObject.x = - drag_data.clickPoint.x;
					ipreview.displayObject.y = - drag_data.clickPoint.y;
					_changeCursor('drag');
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__dragPreview', e);
			}
			return sprite;
		}		
		private function __drawClip(clip:IClip):IPreview
		{
			//RunClass.MovieMasher['msg'](this + '.__drawClip');
			var ipreview:IPreview;
			try
			{
				if (_visibleClips[clip] == null)
				{
					ipreview = __createPreview(clip.media.tag, clip);
					if (ipreview != null) 
					{
						_clipsSprite.addChild(ipreview.displayObject);
					}
				}
				else 
				{
					ipreview = _visibleClips[clip];
					delete _visibleClips[clip];
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__drawClip', e);
			}
			return ipreview;
		}
		private function __drawMedia(xml:XML):IPreview
		{
			var ipreview:IPreview;
			try
			{
				
				var xml_str:String = xml.toXMLString();
										
				if (_visibleClips[xml_str] == null)
				{
					ipreview = __createPreview(xml);
					if (ipreview != null) 
					{
						_clipsSprite.addChild(ipreview.displayObject);
					}
				}
				else 
				{
					ipreview = _visibleClips[xml_str];
					delete _visibleClips[xml_str];
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__drawMedia', e);
			}
			
			return ipreview;
		}
		private function __finishedDrag(drag:DragData):void
		{
			try
			{
				_removePreviews(drag.display);
				
				if (_tag.drop.length())
				{
					if (drag.dragged)
					{
						
						var pt:Point = _clickSprite.globalToLocal(drag.rootPoint);
						var rect:Rectangle = new Rectangle(0,0,_width, _height);
						if (! rect.containsPoint(pt))
						{
							var existing:Array = _source.items;
							var new_items:Array = new Array();
							var z:uint = existing.length;
							var removing_items:Array = drag.items;
							for (var i:uint = 0; i < z; i++)
							{
								if (removing_items.indexOf(existing[i]) == -1)
								{
									new_items.push(existing[i]);
								}
							}
							_source.items = new_items;
							dispatchPropertyChange();
						}
					}
					else
					{
						var id:String = super.getValue('selection').string;
						if (id.length)
						{
							var ob:Object = RunClass.MovieMasher['getByID'](id);
							ob.items = drag.items;
						}
					}
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__finishedDrag', e);
			}			
		}
		private function __setSelectionValue(value:Value):void
		{
			try
			{
				var a:Array = new Array();
				if (_sourceLength) 
				{
					switch (value.string)
					{
						case 'first':
							a.push(RunClass.Media['fromXML'](_source.getItemAt(0)));
							break;
						case 'last':
							a.push(RunClass.Media['fromXML'](_source.getItemAt(_sourceLength -1)));
							break;
					}
				}
				if (_selection.items.length || a.length) _selection.items = a;
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__setSelectionValue ' + value.string, e);
			}
		}
		private function __sourceChange(event:Event):void
		{
			try
			{
				var had_length:Boolean = Boolean(_selection.length);
				_sourceLength = _source.getValue('length').number;
				if (_sourceLength && (! _columns)) resize();
				
				//RunClass.MovieMasher['msg'](this + '.__sourceChange ' + _sourceLength + ' _columns=' + _columns + ' _previewHeight=' + _previewHeight);
				if (had_length)
				{
					_selection.removeItems();
				}
				else
				{
					//RunClass.MovieMasher['msg'](this + '.__sourceChange __setSelectionValue');
					__setSelectionValue(getValue('autoselect'));
				}
				if (! __vScrollReset())
				{
					_drawClips();
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__sourceChange ' , e);
			}
		}
		protected function __vScrollReset():Boolean
		{
			var tf:Boolean = false;
			try
			{
				if (_columns > 0)
				{
					var spacing:Number = getValue(ControlProperty.SPACING).number;
					var padding:Number = getValue(ControlProperty.PADDING).number;
					
					var rows:Number = Math.ceil(_sourceLength / _columns);
					var contentheight:Number = padding * 2;
					
					contentheight += (rows * _previewHeight) + ((rows - 1) * spacing);
					tf = _setScrollDimension('height', contentheight);
					//RunClass.MovieMasher['msg'](this + '.__vScrollReset ' + contentheight);
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__vScrollReset', e);
			}
			return tf;
		}
		private var __sourceProxy:SourceProxy;
		protected var _columns:Number = 0;
		protected var _previewHeight:Number = 0;
		protected var _source:ISource;
		protected var _sourceLength:uint = 0;
	}
	
}
