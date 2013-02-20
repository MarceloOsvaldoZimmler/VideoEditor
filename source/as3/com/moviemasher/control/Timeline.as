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
	import com.moviemasher.type.*;
	import com.moviemasher.constant.*;
	import com.moviemasher.interfaces.*;
	import com.moviemasher.utils.*;
	import com.moviemasher.preview.*;
	import com.moviemasher.events.*;
	import com.moviemasher.action.*;
	import com.moviemasher.options.*;
	import flash.display.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.system.*;
	import flash.utils.*;

/**
* Implimentation class represents a timeline control
*/
	public class Timeline extends ControlPanel
	{
		public function Timeline()
		{
			super();
			_defaultPreviewClass = TimelinePreview;
			//_defaultOptionsClass = TimelineOptions;
			
			_defaults.source = 'mash';
			
			_defaults.width = '*';
			_defaults.height = '*';
			_defaults.autoselect = '';
			_defaults.zoom = '1';
			_defaults.id = ReservedID.TIMELINE;
			_defaults.snap = '1';
		
			_defaults.novisualaudio = '0';
			_defaults.previewmode = 'normal';
			_defaults.previewcurve = '4';
			_defaults.previewinset = '2';
			
			_defaults.hscrollunit = '50';
			_defaults.hscrollpadding = '10';
			_defaults.vscrollpadding = '10';
			
			__enabledControls = new Object();
			__enabledControls.undo = false;
			__enabledControls.redo = false;
			__enabledControls.cut = false;
			__enabledControls.copy = false;
			__enabledControls.paste = false;
			__enabledControls.remove = false;
			__enabledControls.split = false;
			__enabledControls.freeze = false;
		
			__enabledProperties = new Object();
			
			__heights = new Object();
			__heights.clip = 150;
			__heights.audio = 60;
			__heights.video = 90;
			__heights.effect = 60;
			
			_defaults.videotracks = '-1';
			_defaults.audiotracks = '-1';
			_defaults.effecttracks = '-1';
			
			
			_defaults.trimto = '5';
			_defaults.snapto = '20';
			_allowFlexibility = true;
			
			__tracks = new Object();
				
				
		}
		override public function getValue(property:String):Value
		{
			var value:Value;
			if (__enabledControls[property] != null)
			{
				value = new Value(Value[__enabledControls[property] ? 'INDETERMINATE' : 'UNDEFINED']);
			}
			else
			{
				switch(property)
				{
					case 'zoom':
						value = new Value(101 - (__zoom * 100));
						break;
					case 'selection':
						value = new Value(_selection);
						break;
					case 'mash':
						value = new Value(_mash);
						break;
					default:
						value = super.getValue(property);
				}
			}
			return value;
		}
		override public function setValue(value:Value, property:String):Boolean
		{
			try
			{
				var dispatch:Boolean = false;
				switch(property)
				{
					case 'selection':
						// respond to selection changes from triggers
						__setSelection(value.string);
						break;
					case MashProperty.TIME:
						if (_selection.length) __adjustEnableds(_selection.length);
						break;
					case 'split':
						if (__clipCanBeSplit(_selection.firstItem() as IClip))
						{
							new ClipSplitAction(_selection.firstItem() as IClip, _mash.goingTime);
							 __adjustEnableds(_selection.length);
						 }
						break;
					case 'freeze':
						if (__clipCanBeSplit(_selection.firstItem() as IClip), true)
						{
							new ClipFreezeAction(_selection.firstItem() as IClip, _mash.goingTime);
							__adjustEnableds(_selection.length);
						 }
						break;
					case 'zoom' :
						//super.setValue(value, property);
						__zoom = ((101 - Math.max(1, Math.min(100, value.number))) / 100);
						__hScrollReset();
						if (! __positionScroll())
						{
							_drawClips(true);
						}
						dispatch = true;
						break;
					case 'length' :
						super.setValue(value, property);
						// fallthrough to track
					case ClipProperty.TRACK:
						if (! __hScrollReset())
						{
							_drawClips();
						}
						break;
					case 'tracks' :
						__resetTracks();
						if (! __vScrollReset())
						{
							_drawClips();
						}
						break;
					case ControlProperty.MASH:
						mash = value.object as IMash;
						break;
					case 'cut' :
						clipboard = _selection.items;
						__doDelete();
						//_selectionDidChange(null);
						break;
					case 'copy' :
						clipboard = _selection.items;
						_selectionDidChange(null);
						break;
					case 'remove' :
						__doDelete();
						break;
					case 'paste' :
						var items:Array = clipboard;
						var clip:IClip = items[0] as IClip;
						var not_visual:Boolean = (! clip.appearsOnVisualTrack());
						if (not_visual)
						{
							var span:Object = spanOfItems(items);
							var start:Time = _mash.goingTime;
							
							start = start.copyTime();
							start.scale(__getFPS());
							
							var track:uint = _mash.freeTrack(start.frame, start.frame + span.frame, clip.type, span.tracks);
							new ClipsTimeAction(_mash, items, track, start);
						}
						else
						{
							new ClipsIndexAction(_mash, items, __insertIndex());
							
						}
						break;
					case 'redo' :
					case 'undo' :
						//RunClass.MovieMasher['msg'](this + '.setValue ' + property);
						Action[property]();
						break;
					case 'snap':
						dispatch = true;
						// fallthrough to default
					default:
						super.setValue(value, property);
				}
				if (dispatch) _dispatchEvent(property, value);
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.setValue ' + property, e);
			}

			return false;
		}
		override public function initialize():void
		{
			super.initialize();
			_configCursor('trimleft');
			_configCursor('trimright');
			setValue(super.getValue('zoom'), 'zoom');
			
			
			var iconwidth:Number = getValue('iconwidth').number;
			if (iconwidth)
			{
				var mc : DisplayObject;
				var z:int = __trackKeys.length;
				var kk:int;
				var k:String;
				var path:String;
				var loader:IAssetFetcher;
				for (kk = 0; kk < z; kk++)
				{
					k = __trackKeys[kk] + 'icon';
					path = getValue(k).string;
					if (path.length)
					{
						loader = RunClass.MovieMasher['assetFetcher'](path);
						mc = loader.displayObject(path);
						
						if (mc != null)
						{
							__heights[__trackKeys[kk]] = mc.height;
						}
						
					}
				}
			}
		}
		override public function makeConnections():void
		{
			super.makeConnections();
			var propertied:IPropertied = RunClass.MovieMasher['getByID'](ReservedID.PLAYER) as IPropertied;
			if (propertied != null)
			{
				propertied.addEventBroadcaster('refresh', this); // I change main player's refresh property
				
				addEventBroadcaster(ClipType.MASH, propertied);
				setValue(propertied.getValue(ClipType.MASH), ClipType.MASH);
			}
			else
			{
				var source_str:String = getValue('source').string;
				if (source_str.length)
				{
					var isource:ISource = RunClass.MovieMasher['source'](source_str);
					var mash_tag:XML = isource.getItemAt(0) as XML;
					if (mash_tag.name() == ClipProperty.MASH)
					{
						setValue(new Value(RunClass.Mash['fromXML'](mash_tag)), ClipProperty.MASH);
					}
				}
			}
			//RunClass.MovieMasher['msg'](this + '.finalize was not able to find control with id of player');
			
		}
		override public function dragAccept(drag:DragData):void
		{
		 	
		 	var offset_pt:Point = ((drag.source == this) ? __dragOffset : new Point(drag.display.x - drag.display.getBounds(drag.display.parent).left, 0));
			var clip_index:Number;
			var pt:Point = _clickSprite.globalToLocal(drag.rootPoint);
			var clip:IClip = drag.items[0] as IClip;
			var clip_type:String = clip.type;
			
			var not_visual = (! clip.appearsOnVisualTrack());
			try
			{
				if (not_visual)
				{
					try
					{
						var span:Object = spanOfItems(drag.items);
						var track:uint = pixels2Track(pt.y + _scroll.y - offset_pt.y, clip_type, ((clip_type == ClipType.EFFECT) ? span.tracks : 0));
	
						var start_time:Number = Math.max(0, pixels2Frame(pt.x + _scroll.x - (offset_pt.x + getValue('iconwidth').number)));
						var clip_is_in_mash:Boolean = ! clip.getValue(ClipProperty.MASH).undefined;
						var free_time:Number = -1;
						while (free_time == -1)
						{
							free_time = _mash.freeTime(start_time, start_time + span.frame, clip_type, (clip_is_in_mash ? drag.items : null), track, span.tracks);
							if (free_time == -1) track++;
						}	
						new ClipsTimeAction(_mash, drag.items, track, new Time(free_time, __getFPS()));
																						 
					}
					catch(e:*)
					{
						RunClass.MovieMasher['msg'](this + '.dragAccept', e);
					}
				}
				else
				{
					var mc:IPreview = __dragClip(drag.rootPoint);
					clip_index = ((mc == null) ? _mash.tracks.video.length : mc.clip.index);
					new ClipsIndexAction(_mash, drag.items, clip_index);
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.dragAccept', e);
			}
		}
		override public function dragOver(drag:DragData):Boolean
		{
			
			var root_pt:Point = drag.rootPoint;
			var items:Array = drag.items;
			
			
			var offset_pt:Point = ((drag.source == this) ? __dragOffset : new Point(drag.display.x - drag.display.getBounds(drag.display.parent).left, 0));
			
			var ok:Boolean = false;
			var pt:Point = _clickSprite.globalToLocal(root_pt);
						
			try
			{
				ok = super.dragOver(drag);
				if (ok && (_mash != null) && (items[0] is IClip))
				{
					var clip:IClip = items[0] as IClip;
					var clip_type:String = clip.type;
					var actual_clip_type:String = clip_type;
					switch (clip_type)
					{
						case ClipType.AUDIO:
							if (! getValue('audiotracks').boolean) return false;
							break;
						case ClipType.EFFECT:
							if (! getValue('effecttracks').boolean) return false;
							break;
						case ClipType.MASH:
							if (clip.getValue(CommonWords.ID).equals(_mash.getValue(CommonWords.ID).string)) return false; 	// intentional fall through to other visual types
						default:
							clip_type = ClipType.VIDEO;
							if (! getValue('videotracks').boolean) return false;

					}
					
					
					var not_visual:Boolean = (! clip.appearsOnVisualTrack());
					
					var autoscroll:Number = (__zoom == 1) ? 0 : getValue('autoscroll').number;
					
					var iconwidth:Number = getValue('iconwidth').number;
			
					if (pt.x < (autoscroll + iconwidth))
					{
						__doScroll(-1, true);
					}
					else if (pt.x > (_width - autoscroll))
					{
						__doScroll(1, true);
					}
					if (pt.y < autoscroll)
					{
						__doScroll(-1, false);
					}
					else if (not_visual && (pt.y > (_height - autoscroll)))
					{
						__doScroll(1, false);
					}
				
					ok = true;
					try
					{
						_dragHilite.width = _width - iconwidth;
						_dragHilite.height = _height;
						_dragHilite.x = 0;
						_dragHilite.y = 0;
						
						if (not_visual)
						{
							var highest_track:Number = getValue(clip_type + 'tracks').number;
							var span:Object = spanOfItems(items);
							var track:Number = pixels2Track(pt.y + _scroll.y - offset_pt.y, clip_type, ((clip_type == ClipType.EFFECT) ? span.tracks : 0));
							//RunClass.MovieMasher['msg'](this + '.dragOver ' + track);
							
							
							var start_time:Number = Math.max(0, pixels2Frame(pt.x + _scroll.x - (offset_pt.x + getValue('iconwidth').number)));
							
							var free_time = -1;
							while (free_time == -1)
							{
								free_time = _mash.freeTime(start_time, start_time + span.frame, clip_type, (clip.getValue(ClipProperty.MASH).undefined ? null : items), track, span.tracks);
								if (free_time == -1) track++;
							//	else RunClass.MovieMasher['msg'](this + '.dragOver ' + track + ' ' + free_time);
								if ((highest_track != -1) && (track > highest_track))
								{
									//RunClass.MovieMasher['msg'](this + '.dragOver ' + track + ' > ' + highest_track);
									ok = false
									break;
								}
							}
							if (ok)
							{
								_dragHilite.x = frame2Pixels(free_time) - _scroll.x;
								_dragHilite.height = (typeHeight(clip_type) * span.tracks) + (span.tracks - 1);
								_dragHilite.width = frame2Pixels(span.frame);
								_dragHilite.y = __track2Pixels(track, clip_type) - _scroll.y;
							}
						}
						else
						{
							// is visual selection
							var mc:IPreview = __dragClip(root_pt);
							
							if ((! mc) && (actual_clip_type == ClipType.TRANSITION) && _mash.tracks.video.length && _mash.tracks.video[_mash.tracks.video.length - 1].type == ClipType.TRANSITION)
							{
								return false;
							}
							
							if (mc && (! __isDropTarget(mc.clip.index, items)))
							{
								ok = false;
								mc = null;
							}
							//else if (mc) RunClass.MovieMasher['msg'](this + '.dragOver ' + mc.clip + ' ' + mc.clip.index + ' ' + mc.clip.mash.tracks.video.indexOf(mc.clip));
							
							if (mc != null)
							{
								
								var mc_size:Size = mc.size;
								
								_dragHilite.height = mc_size.height;
								_dragHilite.width = 5;
								_dragHilite.y = mc.displayObject.y;
								_dragHilite.x = mc.displayObject.x + mc.data.starttrans;
							}
						}
					}
					catch(e:*)
					{
						RunClass.MovieMasher['msg'](this + '.dragOver', e);
					}
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.dragOver', e);
			}
			return ok;
		}
		override public function resize():void
		{
			super.resize();
			if (! _mash) return;
			if (! (_width && _height) ) return;
			//RunClass.MovieMasher['msg'](this + '.resize ' + _width + 'x' + _height + ' ' + _mash);
			__resetSizes();
			__iconMaskSprite.graphics.clear();
			RunClass.DrawUtility['fill'](__iconMaskSprite.graphics, _width, _height, 0, 0);
			var drew:Boolean = false;
			if (__hScrollReset()) drew = true;
			if (__vScrollReset()) drew = true;
			if (! drew) _drawClips();
		}
		public function pixels2Time(pixels : Number, rounding:String = 'round'):Number
		{
			if (_mash == null) return 0;		
				
			var available_pixels:Number = _viewSize.width - getValue('hscrollpadding').number;
			var displayed_seconds = RunClass.TimeUtility['timeFromFrame'](getValue('length').number, __getFPS()) * __zoom;
			//RunClass.MovieMasher['msg'](this + '.pixels2Time displayed_seconds = ' + displayed_seconds + ' = ' + RunClass.TimeUtility['timeFromFrame'](getValue('length').number, __fps) + ' * ' + __zoom);
			var pixels_per_second:Number = available_pixels / displayed_seconds;
			return Math[rounding](pixels) / pixels_per_second;
		}
		private function pixels2Frame(pixels : Number, rounding:String = 'round'):Number
		{ 
			if (_mash == null) return 0;
			var available_pixels:Number = _viewSize.width - getValue('hscrollpadding').number;
			var displayed_seconds = RunClass.TimeUtility['timeFromFrame'](getValue('length').number, __getFPS()) * __zoom;
			//RunClass.MovieMasher['msg'](this + '.pixels2Frame displayed_seconds = ' + displayed_seconds + ' = ' + RunClass.TimeUtility['timeFromFrame'](getValue('length').number, __getFPS()) + ' * ' + __zoom);
			var pixels_per_second:Number = available_pixels / displayed_seconds;
			return Math[rounding]((pixels / pixels_per_second) * __getFPS());
		}
		public function pixels2Track(y_pixels:Number, type:String, lowest_track:int = 0):int
		{
			if (lowest_track < 1)
			{
				lowest_track = 1;
			}
			var highest_track:int = __tracks[type];
			var track:int = 0;
			if (__tracks[type])
			{
				switch (type)
				{
					case ClipType.EFFECT :

						track = __tracks.effect - Math.round(y_pixels / typeHeight(ClipType.EFFECT));
						break;

					case ClipType.AUDIO :

						y_pixels -= __tracks.effect * typeHeight(ClipType.EFFECT);
						y_pixels -= __tracks.video * typeHeight(ClipType.VIDEO);
						if (__showVisualAudioTrack())
						{
							y_pixels -= typeHeight(ClipType.AUDIO);
						}

						track = Math.round(y_pixels / typeHeight(ClipType.AUDIO)) + 1;

						break;

				}
			}
			// don't let user create new tracks if config specified a set number of them
			track = Math.min(__tracks[type] + (getValue(type + 'tracks').number == -1 ? 1 : 0), track);
			if (track < lowest_track)
			{
				track = lowest_track;
			}
			return track;
		}
		override public function downPreview(preview:IPreview, event:MouseEvent):void
		{
			if ( ! (getValue('notrim').boolean && getValue('nodrag').boolean))
			{
				
				var item : IClip = preview.clip;
				var on_handle : Number = __onHandle(preview, event);
				var do_press = true;
				try
				{
					var clip:IClip;
					var sel_index:int = _selection.indexOf(item);
					var shift_down:Boolean = event.shiftKey;
					if (sel_index > -1)
					{
						if (shift_down)
						{
							if (_selection.length == 1)
							{
								_selection.removeItems();
							}
							else _selection.removeItem(item);
							do_press = false;
						}
					}
					else
					{
						// item wasn't selected
						if (shift_down)
						{
							
							// make sure selection is all audio OR effects OR visual items
							clip = _selection.firstItem() as IClip;
							if (clip != null)
							{
								if ((item.appearsOnVisualTrack() != clip.appearsOnVisualTrack()) || ((! item.appearsOnVisualTrack()) && (! item.getValue(CommonWords.TYPE).equals(clip.getValue(CommonWords.TYPE)))))
								{
									shift_down = false;
								}
							}
							if (shift_down)
							{
								_selection.push(item);
							}
						}
						if (! shift_down)
						{
							_selection.removeItems(true);
							_selection.push(item);
						}
					}
	
					if (do_press && on_handle && (_selection.length == 1) && (! getValue('notrim').boolean))
					{
						do_press = __trimStart(event, on_handle, _selection.firstItem() as IClip);
					}
					if (do_press)
					{
						do_press = __itemsCanBeMoved();
					}
					if (do_press && (! getValue('nodrag').boolean))
					{
						__dragStart(event);
					}
					_drawClips();
				}
				catch(e:*)
				{
					RunClass.MovieMasher['msg'](this + '.downPreview', e);
				}
			}
		}
		override public function overPreview(preview:IPreview, event:MouseEvent):void
		{
			if (! getValue('notrim').boolean)
			{
				__setCursor(__onHandle(preview, event));
			}
			else if (! getValue('nodrag').boolean)
			{
				__setCursor(0);
			}
		}
		override public function updateTooltip(tooltip:ITooltip):Boolean
		{
			var dont_delete:Boolean = false;
			var tip:String;
			try
			{
				tip = getValue('tooltip').string;
				dont_delete = Boolean(tip.length);

				if (dont_delete && (tip.indexOf('{') != -1))
				{
					var ipreview:IPreview = __dragClip(tooltip.point);
					if (ipreview == null) tip = '';
					else tip = RunClass.ParseUtility['brackets'](tip, ipreview.clip);
					dont_delete = Boolean(tip.length);
				}
				if (dont_delete) tooltip.text = tip;
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this, e);
			}		
			return dont_delete;
		}
		public function spanOfItems(items : Array):Object
		{
			var ob:Object = new Object();
			var clip:IClip = items[0] as IClip;
			var select_start : Number = clip.startFrame;
			var select_end : Number = select_start + clip.lengthFrame;
			
			try
			{
				var track_start : uint = clip.track;
				var track_end : uint = track_start;
				var z:uint = items.length;
				var clip_start:Number;
				var item_track : uint;
				for (var i:uint = 1; i < z; i++)
				{
					clip = items[i] as IClip;
					clip_start = clip.startFrame;
					item_track = clip.track;
					track_start = Math.min(track_start, item_track);
					track_end = Math.max(track_end, item_track);
					select_start = Math.min(select_start, clip_start);
					select_end = Math.max(select_end, clip_start + clip.lengthFrame);
				}
				ob.frame = select_end - select_start;
				ob.tracks = 1 + track_end - track_start;
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.spanOfItems', e);
			}
			return ob;
		}
		public function time2Pixels(seconds : Number = 0, rounding : String = 'ceil'):Number
		{
			var pixels:Number = 0;
			if (seconds && (_mash != null)) 
			{
				var available_pixels:Number = _viewSize.width - getValue('hscrollpadding').number;
				var displayed_seconds = RunClass.TimeUtility['timeFromFrame'](getValue('length').number, __getFPS()) * __zoom;
				var pixels_per_second:Number = available_pixels / displayed_seconds;
				pixels = Math[rounding](seconds * pixels_per_second);
			}
			return pixels;
		}
		public function frame2Pixels(seconds : Number = 0, rounding : String = 'ceil'):Number
		{
			var pixels:Number = 0;
			try
			{
			
				if (seconds && (_mash != null)) 
				{
					var available_pixels:Number = _viewSize.width - getValue('hscrollpadding').number;
					var displayed_seconds = RunClass.TimeUtility['timeFromFrame'](getValue('length').number, __getFPS()) * __zoom;
					var pixels_per_second:Number = available_pixels / displayed_seconds;
					pixels = Math[rounding]((seconds / __getFPS()) * pixels_per_second);
					//RunClass.MovieMasher['msg']('available_pixels: ' + available_pixels + ' displayed_seconds: ' + displayed_seconds + ' pixels_per_second: ' + pixels_per_second + ' pixels: ' + pixels + ' __fps: ' + __getFPS());
				}
				//if (seconds) pixels = Math[rounding](seconds * __zoom);
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.frame2Pixels', e);
			}			
			return pixels;
		}
		public function typeHeight(type : String, subtract_line : Boolean = false) : int
		{
			switch(type)
			{
				case ClipType.AUDIO:
				case ClipType.EFFECT:
				case TagType.CLIP: break;
				default: type = ClipType.VIDEO;
			}
			var n:int = __heights[type];
			if (subtract_line) n -= getValue('line').number;
			return n;
		}
		public function get clipboard():Array
		{
			return __cloneItems(__clipboard);
		}
		public function set clipboard(s : Array):void
		{
			__clipboard = __cloneItems(s);
		}
		public function get mash():IMash
		{
			return _mash;
		}
		public function set mash(new_mash : IMash):void
		{
			var mash_props:Array = new Array();
			mash_props.push(ClipProperty.LENGTH);
			mash_props.push(MashProperty.TRACKS);
			mash_props.push(ClipProperty.TRACK);
			mash_props.push(MashProperty.TIME);
			var prop:String;
			var list:XMLList;
			var has_drop:Boolean;
			//RunClass.MovieMasher['msg'](this + '.mash = ' + new_mash);
			if (_mash)
			{
				for each (prop in mash_props)
				{
					_mash.removeEventListener(prop, changeEvent);
				}
				if (__drawingClipPreviews)
				{
					_visibleClips = __drawingClipPreviews;
				}
				_deleteClips();
				__drawingStop(true);
				_selection.items = new Array();
				Action.clear();				
			}
			_mash = new_mash;
			
			if (_mash)
			{
				list = _mash.tag.drop;
				has_drop = (list.length() > 0);
				for (prop in _dropTypes)
				{
					_dropTypes[prop] = (has_drop ? (list.(attribute(CommonWords.TYPE) == prop).length() > 0): true);
				}
				if (! has_drop) _dropTypes[ClipType.MASH] = false;
				
				__fps = _mash.getValue(MashProperty.QUANTIZE).number;
				if (__fps && (! RunClass.TimeUtility['fps'])) RunClass.TimeUtility['fps'] = __fps;
			
				for each (prop in mash_props)
				{
					_mash.addEventListener(prop, changeEvent);
					setValue(_mash.getValue(prop), prop);
				}
				var select:String = getValue('autoselect').string;
				if (! select.length) select = _mash.getValue('autoselect').string;
				if (select.length)
				{
					switch (select)
					{
						case ControlProperty.MASH:
							_selection.items = new Array(_mash);
							break;
						default:
							__setSelection(select);
							
					}
				}
				
			}
			resize();
			_dispatchEvent('zoom');
		}
		override protected function _createChildren():void
		{
			try
			{
				
				//__resetTrackCounts();
				
				super._createChildren();
				
				
				Action.eventDispatcher.addEventListener(ActionEvent.ACTION, __actionEvent);
				// all track heights to be overridden by cliptrack, videotrack, etc.
				var k : String;
				var z:int = __trackKeys.length;
				var track:Number;
				var kk:int;
	
				for (kk = 0; kk < z; kk++)
				{
					k = __trackKeys[kk];
					track = getValue(k + ClipProperty.TRACK).number;
					if (track)
					{
						__heights[k] = track;
					}
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '._createChildren', e);
			}
			__containers = new Dictionary();
			
			__containers[TagType.CLIP] = new Sprite();
			_clipsSprite.addChildAt(__containers[TagType.CLIP], 0);
			__containers[ClipType.TRANSITION] = new Sprite();
			_clipsSprite.addChildAt(__containers[ClipType.TRANSITION], 0);

			__iconSprite = new Sprite();
			addChild(__iconSprite);
			__iconMaskSprite = new Sprite();
			addChild(__iconMaskSprite);
			__iconSprite.mask = __iconMaskSprite;
			var iconwidth:Number = getValue('iconwidth').number;
			if (iconwidth)
			{
				_displayObjectLoad('clipicon');
				_displayObjectLoad('audioicon');
				_displayObjectLoad('effecticon');
				_displayObjectLoad('videoicon');
			}
			var cursors:Array = ['trimleft', 'trimright', 'hover', 'drag'];
			z = cursors.length;
			for (kk = 0; kk < z; kk++)
			{
				k = cursors[kk];
				__createCursor(k);
			}	
			
			if (! getValue('nodrop').boolean) 
			{
				RunClass.DragUtility['addTarget'](this);
			}

		}
		private var __containers:Dictionary;
		
		override protected function _drawClips(force : Boolean = false):void
		{
			if (__initDrawTimer == null)
			{
				//RunClass.MovieMasher['msg'](this + '._drawClips creating __initDrawTimer');
				__initDrawTimer = new Timer(20, 1);
				__initDrawTimer.addEventListener(TimerEvent.TIMER, __initDrawTimed);
				__initDrawTimer.start();
			}
		}
		
		
		override protected function _isSelected(preview:IPreview):Boolean
		{
			var selected:Boolean = false;
			for (var k:* in _visibleClips)
			{
				
				if (_visibleClips[k] == preview)
				{
					selected = (_selection.indexOf(k) != -1);
					break;
				}
			}
			return selected;
		}
		override protected function _previewData(clip:IClip):Object
		{
			var object:Object = super._previewData(clip);
			var is_multitrack:Boolean = false;
			var clip_index:Number;
			var n:uint;
			var options_x:Number;
			var options_width:Number;
			try
			{
				switch(clip.type)
				{
					case ClipType.AUDIO:
						is_multitrack = true;
						break;
					case ClipType.MASH:
					case ClipType.VIDEO:
						is_multitrack = clip.getValue(ClipProperty.HASAUDIO).boolean;
						break;
					case ClipType.TRANSITION: 
						if (! ((clip.getValue(ClipProperty.FREEZESTART).boolean && clip.getValue(ClipProperty.FREEZEEND).boolean))) 
						{
							var index:Number = -1;
							index = _mash.tracks.video.indexOf(clip);
							if (index > -1)
							{
								if (index && _mash.tracks.video[index - 1].getValue(ClipProperty.HASAUDIO).boolean) is_multitrack = true;
								else if ((index < (_mash.tracks.video.length - 1)) && _mash.tracks.video[index + 1].getValue(ClipProperty.HASAUDIO).boolean) is_multitrack = true;
							}
						}
						break;
				}
				if (is_multitrack && (clip.type != ClipType.AUDIO)) 
				{
					is_multitrack = ! getValue('novisualaudio').boolean;
				}
			}
			catch (e:*)
			{
				RunClass.MovieMasher['msg'](this + '._previewData 1', e);
			}
			try
			{
				object[ClipProperty.HASAUDIO] = is_multitrack;
				if (is_multitrack) 
				{
					object[ClipProperty.LOOPS] = clip.getValue(ClipProperty.LOOPS).number;
					//RunClass.MovieMasher['msg'](this + '._previewData wave=' + clip.getValue(MediaProperty.WAVE));
					
					if (! clip.getValue(MediaProperty.WAVE).empty)
					{
						n = clip.getValue(MediaProperty.DURATION).number;
						//RunClass.MovieMasher['msg'](this + '._previewData duration=' + n);
						object['durationpixels'] = time2Pixels(n);
						//RunClass.MovieMasher['msg'](this + '._previewData durationpixels=' + object['durationpixels']);
						object[ClipProperty.STARTFRAME] = clip.startFrame;
						n = clip.getValue(ClipProperty.TRIMSTARTFRAME).number;
						if (n) object[ClipProperty.TRIMSTART] = frame2Pixels(n, 'round'); 
					}
				}
			}
			catch (e:*)
			{
				RunClass.MovieMasher['msg'](this + '._previewData 2 ' + clip, e);
			}
			try
			{
				clip_index = clip.index;
				options_x = frame2Pixels(clip.startFrame, 'round') - _scroll.x;
				options_width = Math.max(1, frame2Pixels(clip.lengthFrame, 'ceil'));
				
				object['x'] = options_x;
				object['y'] = __track2Pixels(clip.track, clip.type) - _scroll.y;
				object['width'] = options_width;
				object['starttrans'] = (((clip_index < 0)) ? 0 : frame2Pixels(clip.getValue(ClipProperty.TIMELINESTARTFRAME).number, 'floor'));
				object['endtrans'] = (((clip_index < 0)) ? 0 : frame2Pixels(clip.getValue(ClipProperty.TIMELINEENDFRAME).number, 'floor'));
				object['leftcrop'] = ((options_x < 0) ? -options_x : 0);
				object['rightcrop'] = ((_viewSize.width < (options_x + options_width)) ? _viewSize.width - (options_x + options_width) : 0);
				//RunClass.MovieMasher['msg'](this + '._previewData width = ' + object['width'] + ' ' + clip.lengthFrame + ' ' + frame2Pixels(clip.lengthFrame, 'ceil'));
				
			}
			catch (e:*)
			{
				RunClass.MovieMasher['msg'](this + '._previewData 3', e);
			}
			return object;
		}
		override protected function _selectionDidChange(event:Event):void
		{
			try
			{
				//RunClass.MovieMasher['msg(this + '._selectionDidChange ' + _selection.length);// + ' ' + getValue']('mashselect').boolean + ' ' + _mash);
				
				var z:uint = _selection.length;
				
				if ((! z) && getValue('autoselect').equals(ControlProperty.MASH))
				{
					_selection.push(_mash);
				}
				else 
				{
					__adjustEnableds(z);
					
					_updateSelection();
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '._selectionDidChange', e);
			}
		}
		private function __actionEvent(event : ActionEvent):void
		{
			try
			{
				var refresh:Boolean = true;
				if (event.action == null) _selection.items = new Array();
				else
				{
					if (event.action is MashAction)
					{
						var mash_action:MashAction = event.action as MashAction;
						if ((mash_action.mash != null) && (mash_action.mash == _mash))
						{
							_drawClips(true);
							// some action was taken by the user
							if (event.action != null)
							{
								_selection.items = event.action.targets;
							}
							else
							{
								_selection.removeItems();
							}
							if (mash_action is ClipsValueAction)
							{
								var value_action:ClipsValueAction = mash_action as ClipsValueAction;
								if (value_action.property == ClipProperty.VOLUME) refresh = false;
							}
							
							if (refresh) _dispatchEvent('refresh', new Value());
						}
					}
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__actionEvent', e);
			}
		}
		private function __actionIsEnabled(property : String, z:uint):Boolean
		{
			var should_be_enabled : Boolean = true;
			try
			{
				
				switch (property)
				{
					case 'copy':
						should_be_enabled = ((z > 0) && (_selection.firstItem() is IClip));
						break;
					case 'cut':
					case 'remove':
						
						should_be_enabled = __itemsCanBeMoved();
						break;
					case 'paste':
	
						should_be_enabled = (clipboard.length > 0);
						if (should_be_enabled && clipboard[0].appearsOnVisualTrack())
						{
							var insert_index:Number = __insertIndex();
							should_be_enabled = __isDropTarget(insert_index, clipboard);
						}
						break;
					case 'undo':
						should_be_enabled = (Action.currentDo > -1);
						break;
					case 'redo':
						should_be_enabled = (Action.currentDo < (Action.doStack.length - 1));
						break;
					case 'snap':
						should_be_enabled = getValue(property).boolean;
						break;
					case 'split':
						should_be_enabled = ((z > 0) && (_selection.firstItem() is IClip));
						if (should_be_enabled)
						{
							should_be_enabled = __clipCanBeSplit(_selection.firstItem() as IClip);
						}
						break;
					case 'freeze':
						should_be_enabled = ((z > 0) && (_selection.firstItem() is IClip));
						if (should_be_enabled)
						{
							should_be_enabled = __clipCanBeSplit(_selection.firstItem() as IClip, true);
						}
						break;
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__actionIsEnabled ' + property + ' ' + z + ' ' + should_be_enabled, e);
			
			}
			return should_be_enabled;
		}
		private function __adjustEnableds(z:uint):void
		{
			var action_enabled:Boolean;
			for (var property in __enabledControls)
			{
				action_enabled = __actionIsEnabled(property, z);
				if (__enabledControls[property] != action_enabled)
				{
					__enabledControls[property] = action_enabled;
					_dispatchEvent(property);
				}
			}
		
		}
		private function __calculateContentHeight():void
		{
			__contentHeight = 0;
		
			if (__tracks.video)
			{
				__contentHeight += typeHeight(ClipType.VIDEO);
				if (__showVisualAudioTrack())
				{
					__contentHeight += typeHeight(ClipType.AUDIO);
				}
			}
			if (__tracks.audio)
			{
				__contentHeight += __tracks.audio * typeHeight(ClipType.AUDIO);
			}
			if (__tracks.effect)
			{
				__contentHeight += __tracks.effect * typeHeight(ClipType.EFFECT);
			}
				
		}
		private function __clipCanBeSplit(clip:IClip, freeze:Boolean = false):Boolean
		{
			
			var can:Boolean = false;
			var clip_type:String;
			try
			{
				if (clip.track >= 0)
				{
					clip_type = clip.type;
					if ((! freeze) || (clip_type == ClipType.VIDEO))
					{
						switch(clip_type)
						{
							case ClipType.TRANSITION: 
								break;
							case ClipType.AUDIO:
							case ClipType.VIDEO:
								if (! clip.canTrim)
								{
									break;
								}
								else;
							case ClipType.IMAGE:
							case ClipType.FRAME:
							case ClipType.THEME:
							case ClipType.EFFECT:
								var range:TimeRange = clip.timeRange;
								var time:Time = _mash.goingTime;
								//RunClass.MovieMasher['msg']('time ' + time + ' range ' + range);
								time.scale(__getFPS());
								
								var location:uint = time.frame;
								var frame:Number = range.frame;
								if (location >= (frame + 1)) 
								{
									frame = range.end;
									if (location <= (frame - 1)) 
									{
										can = true;
									}
								}
								else;
						}
					}
				}
			
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__clipCanBeSplit ' + clip + ' _mash = ' + _mash, e);
			
			}
			return can;
		}
		private function __cloneItems(a : Array):Array
		{
			var items : Array = [];
			var z = a.length;
			var item:IClip;
			for (var i = 0; i < z; i++)
			{
				item = a[i].clone();
				item.setValue(new Value(), ClipProperty.MASH);
				items.push(item);
			}
			return items;
		}
		private function __createClip(clip:IClip, container:DisplayObjectContainer = null):IPreview
		{
			var preview : IPreview;
			try
			{
				if (container == null)
				{
					container = __containers[((clip.type == ClipType.TRANSITION) ? ClipType.TRANSITION : TagType.CLIP)]
				}
				if (container != null)
				{
					var options:IOptions = __previewOptions(clip);
					var xml:XML = null;
					if (options != null)
					{
						if (clip.media != null) xml = clip.media.tag;
						else xml = clip.tag;
							
						preview = _instanceFromOptions(options, xml, clip);
						if (preview != null)
						{
							container.addChild(preview.displayObject);
						}
					}
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__createClip', e);
			}
			return preview;
		}
		private function __createCursor(cursor_name : String)
		{
			var cursor:String = getValue(cursor_name + 'icon').string;
			if (cursor.length)
			{
				var c:Array = cursor.split(';');
				_displayObjectLoad(c[0], true);
			}
		}
		private function __doDelete():void
		{
			if (_selection.length)
			{
				var clip:IClip = _selection.firstItem() as IClip;
				var not_visual = (! clip.appearsOnVisualTrack());
				if (not_visual)
				{
					new ClipsTimeAction(_mash, _selection.items);
				}
				else
				{
					new ClipsIndexAction(_mash, _selection.items);
				}
			}
		}
		private function __dragClip(root_pt:Point):IPreview
		{
			var mc : IPreview = null;
			var dictionary:Dictionary = __drawingClipPreviews;
			if (dictionary == null) dictionary = _visibleClips;
			for each (mc in dictionary)
			{
				if (mc.displayObject.hitTestPoint(root_pt.x, root_pt.y))
				{
					break;
				}
				mc = null;
			}
			//RunClass.MovieMasher['msg'](this + '.__dragClip ' + mc);
			return mc;
		}
		private var __drawingClips:Array;
		private var __drawingClipPreviews:Dictionary;
		private var __initDrawTimer:Timer;
		private function __initDrawTimed(event:TimerEvent):void
		{
			__initDrawTimer.stop();
			__initDrawTimer.removeEventListener(TimerEvent.TIMER, __initDrawTimed);
			__initDrawTimer = null;
		
			if (__drawClipsTimer == null)
			{
				__drawClipsTimer = new Timer(DRAW_INTERVAL);
				__drawClipsTimer.addEventListener(TimerEvent.TIMER, __drawClipsTimed);
				__drawClipsTimer.start();
			}
			else 
			{
				if (__drawingClipPreviews != null) _visibleClips = __drawingClipPreviews;
				__drawingClips = null;
			}
		}
		private const DRAW_INTERVAL:Number = 20;
		private function __drawingStop(delayed_too:Boolean = false):void
		{
			if (delayed_too && (__initDrawTimer != null))
			{
				__initDrawTimer.stop();
				__initDrawTimer.removeEventListener(TimerEvent.TIMER, __initDrawTimed);
				__initDrawTimer = null;
			}
			if (__drawClipsTimer != null)
			{
				__drawClipsTimer.stop();
				__drawClipsTimer.removeEventListener(TimerEvent.TIMER, __drawClipsTimed);
				__drawClipsTimer = null;
			}
			//RunClass.MovieMasher['msg'](this + '.__drawClipsTimed setting _visibleClips to ' + __drawingClipPreviews);
			__drawingClips = null;
			__drawingClipPreviews = null;
		}
		private function __drawClipsTimed(event:TimerEvent):void
		{
			try
			{
				//RunClass.MovieMasher['msg'](this + '.__drawClipsTimed ' + __drawingClips);
				var stop:Number = DRAW_INTERVAL + (new Date().getTime()); // do this for 10 milliseconds
				var changed:Boolean;
				var all_drawn:Boolean = false;
				var clip:IClip;
				var i,z:uint;
				var object:Object;
				var preview:IPreview;
				var data:Object;
				var k:String;
				//var test:Number;
				if (__drawingClips == null) // begin drawing process
				{
				//	test = (new Date().getTime());
					__drawingClips = __viewableClips();
					__drawingClips.sortOn('startFrame', Array.NUMERIC | Array.DESCENDING);
					//__drawTest.lookup += (new Date().getTime()) - test;
					
					__drawingClipPreviews = new Dictionary();
					z = __drawingClips.length;
					for (i = 0; i < z; i++)
					{
						clip = __drawingClips[i];
						preview = _visibleClips[clip];
						if (preview != null)
						{
							preview.displayObject.visible = false;
							__drawingClipPreviews[clip] = preview;
							delete _visibleClips[clip];
						}
					}
					_deleteClips(); // removes everything still in _visibleClips
					__iconSprite.y = - _scroll.y; //???
				}
			
				while (__drawingClips.length && ((new Date().getTime()) < stop))
				{
					clip = __drawingClips.pop();
					if (clip == null) continue;
					
					preview = __drawingClipPreviews[clip];
					changed = (preview == null);
					if (changed) 
					{
					//	test = (new Date().getTime());
						preview = __createClip(clip);
					//	__drawTest.creating += (new Date().getTime()) - test;
						__drawingClipPreviews[clip] = preview;
					}
					if (preview != null)
					{
						preview.displayObject.visible = true;
						//test = (new Date().getTime());
						object = _previewData(clip);

						//__drawTest.data += (new Date().getTime()) - test;

						if (! changed)
						{
							data = preview.data;
							changed = (data == null);
							
							if (! changed)
							{
								for (k in object)
								{
									if (object[k] != data[k])
									{
										changed = true;
										break;
									}
								}
							}
						}
						if (changed) preview.data = object;						
					}
				}
					
					
				if (! __drawingClips.length)
				{
					_visibleClips = __drawingClipPreviews;
					__drawingStop();
					/*
					RunClass.MovieMasher['msg'](this + '.__drawClipsTimed took ' + Math.round(((new Date().getTime()) - __drawTest.started) / 1000) + ' seconds');
					for (k in __drawTest)
					{
						if (k == 'started') continue;
						RunClass.MovieMasher['msg'](this + '.__drawClipsTimed ' + k + ' ' + (__drawTest[k] / 1000));
					}
					*/
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__drawClipsTimed', e);
			}

		}
		private function __dragPreview(drag_data:Object):DisplayObjectContainer
		{
			var wrapper:Sprite = new Sprite();
			try
			{
				var clip:IClip = drag_data.items[0] as IClip;
				var clip_type:String = clip.type;
				
				__dragOffset = new Point();
				
				if (clip_type == ClipType.EFFECT)
				{
					drag_data.items.sortOn(ClipProperty.TRACK, Array.DESCENDING | Array.NUMERIC);
				}
				else
				{
					drag_data.items.sortOn(ClipProperty.TRACK, Array.NUMERIC);
				}
				__dragOffset.y = (_scroll.y + drag_data.clickPoint.y) - __track2Pixels(clip.track, clip_type);
				drag_data.items.sortOn('startFrame', Array.NUMERIC);
				__dragOffset.x = (_scroll.x + drag_data.clickPoint.x - getValue('iconwidth').number) - frame2Pixels(clip.startFrame);
				
				var z:uint = drag_data.items.length;
				var sprite:Sprite = new Sprite();
				wrapper.addChild(sprite);
				sprite.x = - (drag_data.clickPoint.x - getValue('iconwidth').number);
				sprite.y = - drag_data.clickPoint.y;
				
				sprite.alpha = .7;
				var preview:IPreview;
				for (var i:uint = 0; i < z; i++)
				{
					clip = drag_data.items[i];
					preview = __createClip(clip, sprite);
					if (preview != null) preview.selected = true;
				}
				_changeCursor('drag');
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__dragPreview', e);
			}
			return wrapper;
		}
		private function __dragStart(event:MouseEvent):void
		{
			try
			{
				
				_changeCursor();
				
				var drag_data:DragData = new DragData();
				drag_data.clickPoint = new Point(mouseX, mouseY);
				drag_data.previewCallback = __dragPreview;

				drag_data.source = this;
				drag_data.items = _selection.items;
				drag_data.callback = __finishedDrag;
				RunClass.DragUtility['begin'](event, drag_data);
				
				//drag_data.display = wrapper;
				//_changeCursor('drag');
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__dragStart', e);
			}

		}
		private function __finishedDrag(drag:DragData):void
		{
			if (drag.display != null) _removePreviews(drag.display.getChildAt(0) as DisplayObjectContainer);
			if (drag.rootPoint.length)
			{
				
				var pt:Point = globalToLocal(drag.rootPoint);
				var rect:Rectangle = new Rectangle(0,0,_width, _height);
				
				
				//RunClass.MovieMasher['msg(this + '.__finishedDrag ' + rect + ' ' + pt + ' ' + rect.containsPoint'](pt));
				if (! rect.containsPoint(pt))
				{
					__doDelete();
				
				}
			}
		
		}
		private function __getFPS():uint
		{
			if (__fps == 0)
			{
				if (_mash != null) __fps = _mash.getValue(MashProperty.QUANTIZE).number;
			}
			return __fps;
		}
		private function __hScrollReset():Boolean
		{
			var new_w:Number = getValue('hscrollpadding').number;
			if (_mash)
			{
				new_w += Math.round(frame2Pixels(getValue('length').number));
			}
			return _setScrollDimension('width', new_w);
		}
		private function __insertIndex():uint
		{
			var i:uint = 0;
			var item:IClip = _selection.firstItem() as IClip;
			
			if (item != null)
			{
				i = item.index;
			}
			else
			{
				
					
				if ((_mash != null) && _mash.tracks.video.length)
				{
					var time:Time = _mash.goingTime;
					if (time == null) time = _mash.displayTime;
					time.scale(__getFPS());
					
					var frame:Number = time.frame;
					var clips:Array = _mash.clipsInTracks(frame, frame, ClipType.VIDEO, true);
					if (! clips.length)
					{
						i = _mash.tracks.video.length - 1;
					}
					else
					{
						i = clips[0].index;
					}
				}
				
			
			}
			return i;
		}
		private function __isDropTarget(index : Number, items : Array):Boolean
		{
			var ok = true;
			try
			{
				var clip:IClip = null;
				var first_is:Boolean;
				var last_is:Boolean;
				// see if transition is first or last in selection 
				if (items && items.length)
				{
				
					clip = items[0];
					if (clip != null)
					{
						first_is = (clip.type == ClipType.TRANSITION);
						clip = items[items.length - 1];
						last_is = (clip.type == ClipType.TRANSITION);
						if (first_is || last_is)
						{
							if (index < _mash.tracks.video.length)
							{
								clip = _mash.tracks.video[index];
								// see if we're dropping on or next to a transition
								if (last_is && (clip.type == ClipType.TRANSITION))
								{
									ok = false;
								}
								else 
								{
									//RunClass.MovieMasher['msg'](this + '.__isDropTarget last_is = ' + last_is + ' ' + clip);  
									if (first_is && index)
									{
										clip = _mash.tracks.video[index - 1];
										if (clip.type == ClipType.TRANSITION)
										{
											ok = false;
										}
										//else RunClass.MovieMasher['msg'](this + '.__isDropTarget first_is  = ' + first_is + ' ' + clip);
									}
									//else RunClass.MovieMasher['msg'](this + '.__isDropTarget first_is  = ' + first_is + ' ' + index);
								}
							}
							//else RunClass.MovieMasher['msg'](this + '.__isDropTarget ' + index + ' <= ' + _mash.tracks.video.length);
						}
					}
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__isDropTarget', e);
			}
			//RunClass.MovieMasher['msg'](this + '.__isDropTarget ' + index + ' ' + (ok ? 'yes' : 'no'));
			return ok;
		}
		private function __itemsCanBeMoved():Boolean
		{
			var can_remove : Boolean = false;
			try
			{
				var items:Array = _selection.items;
				var z : int = items.length;
				if ((z > 0) && (items[0] is IClip))
				{
	
					var item:IClip = items[0];
					if (item != null)
					{
						can_remove = (item.track >= 0);
						if (can_remove)
						{
							can_remove = ! item.appearsOnVisualTrack();
							if (! can_remove)
							{
								can_remove = true;
								var i : int;
								var item_mash:IMash;
								var index : int;
								var is_selected : Dictionary = new Dictionary();
								var left_index : Number;
								var right_index : Number;
								var yy:int;
			
								for (i = 0; i < z; i++)
								{
									item = items[i];
									is_selected[item] = true;
								}
								for (i = 0; i < z; i++)
								{
									item = items[i];
									if (item != null)
									{
										item_mash = item.mash;
										
										if (item_mash != null)
										{
											index = item.index;
					
											left_index = index - 1;
											while (left_index > -1)
											{
												item = item_mash.tracks.video[left_index];
												if (! is_selected[item])
												{
													break;
												}
												left_index --;
											}
											if (left_index > -1)
											{
												right_index = index + 1;
												yy = item_mash.tracks.video.length;
												while (right_index < yy)
												{
													item = item_mash.tracks.video[right_index];
													if (item != null)
													{
														if (! is_selected[item])
														{
															break;
														}
													}
													right_index ++;
												}
												if (right_index < yy)
												{
													item = item_mash.tracks.video[left_index];
													if (item != null)
													{
														if (item.type == ClipType.TRANSITION)
														{
															item = item_mash.tracks.video[right_index];
															if (item != null)
															{
																if (item.type == ClipType.TRANSITION)
																{
																	can_remove = false;
																	break;
																}
															}
														}
													}
												}
											}
										}
									}
								}
							}
						}
					}
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__itemsCanBeMoved', e);
			}
			//RunClass.MovieMasher['msg'](this + '.__itemsCanBeMoved ' + can_remove);
			return can_remove;
		}
		private function __onHandle(preview:IPreview, event:MouseEvent) : Number 
		{ 
			var is_within : Number = 0;
			try
			{
				if (! getValue('notrim').boolean)
				{
					if (! preview.clip.getValue('readonly').boolean)
					{
						var options:IOptions = preview.options;
					
						if (! ((options.getValue(CommonWords.TYPE).equals(ClipType.AUDIO)) && ((preview.clip).getValue('loop').boolean)))
						{
							var x_pos:Number = event.localX;
							var trimto:Number = getValue('trimto').number;
							var size:Size = preview.size;
							trimto = Math.min(trimto, Math.round(size.width / 4));
							if (trimto)
							{
								if (x_pos <= trimto) is_within = -1;
								else if (x_pos >= (size.width - trimto)) 
								{
									is_within = 1;
								}
							}
						}
					}
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this, e);
			}
			return is_within;
		}
		private function __positionScroll():Boolean
		{
			var new_pos:Number = 0;
			var did_draw:Boolean = false;
			if (_mash)
			{
				new_pos = Math.max(0, Math.min((_scroll.width - _width), time2Pixels(_mash.goingTime.seconds) - (_width / 2)));
			}
			
			did_draw = Boolean(_scrollTo(true, new_pos));
			return did_draw;
		}
		private function __previewOptions(clip:IClip):IOptions
		{
			var options:IOptions = null;
			try
			{
				var type:String = clip[CommonWords.TYPE];
				options = _itemOptions(type);
				if (options != null)
				{
				
					var media_icon:String = clip.getValue('icon').string;
					if (media_icon.length)
					{
						options.setValue(new Value(media_icon), 'icon');
					}
					
					
					// create spacing for line between tracks
					options.setValue(getValue('line'), ControlProperty.SPACING);
					
					// create height for clip type (audio will get set below)
					if (type != ClipType.AUDIO) options.setValue(new Value(typeHeight(type, true)), type + 'height');
					
					var is_multitrack:Boolean = false;
						
					switch(type)
					{
						case ClipType.AUDIO:
							is_multitrack = true;
							break;
						case ClipType.MASH:
						case ClipType.VIDEO:
							is_multitrack = clip.getValue(ClipProperty.HASAUDIO).boolean;
							break;
						case ClipType.TRANSITION: 
							var index:Number = -1;
							index = _mash.tracks.video.indexOf(clip);
							if (index > -1)
							{
								if (index && _mash.tracks.video[index - 1].getValue(ClipProperty.HASAUDIO).boolean) is_multitrack = true;
								else if ((index < (_mash.tracks.video.length - 1)) && _mash.tracks.video[index + 1].getValue(ClipProperty.HASAUDIO).boolean) is_multitrack = true;
							}
							else;
							break;
					}
					if (is_multitrack)
					{
						options.setValue(new Value(typeHeight(ClipType.AUDIO, true)), 'audioheight');
						options.setValue(clip.getValue(MediaProperty.WAVE), MediaProperty.WAVE);
						options.setValue(clip.getValue(MediaProperty.LOOP), MediaProperty.LOOP);
					}
				}
			}
			catch (e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__previewOptions', e);
			}
			return options;
		}
		private function __resetSizes():void
		{
			__resetTracks();
			var iconwidth:Number = getValue('iconwidth').number;
			_viewSize.width = _width - iconwidth;
			_clipsSprite.x = iconwidth;
		}
		private function __resetTrackCounts():void
		{
			

			if (_mash != null)
			{
				var videotracks:Number = getValue('videotracks').number;
				var audiotracks:Number = getValue('audiotracks').number;
				var effecttracks:Number = getValue('effecttracks').number;
				//RunClass.MovieMasher['msg'](this + '.__resetTrackCounts ' + videotracks + ' ' + audiotracks + ' ' + effecttracks);
				__tracks.video = ((videotracks == -1) ? _mash.getValue(ClipType.VIDEO).number : (videotracks ? 1 : 0));
				__tracks.audio = ((audiotracks == -1) ? _mash.getValue(ClipType.AUDIO).number : (audiotracks ? audiotracks : 0));
				__tracks.effect = ((effecttracks == -1) ? _mash.getValue(ClipType.EFFECT).number : (effecttracks ? effecttracks : 0));
			}
		}
		private function __resetTracks():void
		{
			if (_width && (_mash != null))
			{
				
				__resetTrackCounts();
				
				var i : Number;
				var z : Number;
				var clip_name : String;
				var y_pos : Number = 0;
				var k : String;
				__iconSprite.graphics.clear();
				var c;
				var mc:DisplayObject;
				var line:Number = getValue('line').number;
				var linegrad:Number = getValue('linegrad').number;
				var iconwidth:Number = getValue('iconwidth').number;
				var linecolor:String = getValue('linecolor').string;
	
				if (line && linecolor.length)
				{
					c = RunClass.DrawUtility['colorFromHex'](linecolor);
				}
				
				var icon:String;
				var loader:IAssetFetcher;
				for (var kk = 0; kk < 4; kk++)
				{
					k = __trackKeys[kk];
					i = 0;
					z =  __tracks[k];
					if ((k == ClipType.AUDIO) && __showVisualAudioTrack())
					{
						z++;
					}
					icon = getValue(k + 'icon').string;
					for (; i < z; i++)
					{
						if (icon.length)
						{
							clip_name = k + 'icon' + i + '_mc';
							mc = __iconSprite.getChildByName(clip_name) as DisplayObject;
							if (mc == null)
							{
								loader = RunClass.MovieMasher['assetFetcher'](icon);
								
								mc = loader.displayObject(icon);
								if (mc != null)
								{
									mc.name = clip_name;
									__iconSprite.addChild(mc);
								}
							}
							if (mc != null)
							{
								mc.y = y_pos;
							}
						}
						y_pos += __heights[k];
						if (line)
						{
							if (linegrad)
							{
								RunClass.DrawUtility['fillBoxGrad'](__iconSprite.graphics, 0, y_pos - line, _width, line, RunClass.DrawUtility['gradientFill'](_width, line, c, linegrad, getValue('liineangle').number));
							}
							else if (linecolor.length)
							{
								RunClass.DrawUtility['fillBox'](__iconSprite.graphics, 0, y_pos - line, _width, line, c);
							}
						}
					}
				
					if (icon.length)
					{
						clip_name = k + 'icon' + i + '_mc';
	
						while (mc = __iconSprite.getChildByName(clip_name) as DisplayObject)
						{
							__iconSprite.removeChild(mc);
							i++;
							clip_name = k + 'icon' + i + '_mc';
						}
					}
				}
				__calculateContentHeight();
			}
		}
		private function __setCursor(cursor : Number):void
		{
			try
			{
				_changeCursor(__rollCursors[1 + cursor]);
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.setCursor', e);
			}
		}
		private function __setSelection(select:String):void
		{
			// supported: '', 'clips', 'audio', 'effect', 'video'
			var types:Array;
			var type:String;
			var new_selection:Array = new Array();
			
			var i_clip:IClip;
			if (select.length) 
			{
				types = new Array();
				switch (select)
				{
					case 'clips':
					case 'all':
						types.push(ClipType.AUDIO);
						types.push(ClipType.EFFECT);
						types.push(ClipType.VIDEO);
						break;
					default:types.push(select);
					
				}
				
				for each(type in types)
				{
					for each (i_clip in _mash.tracks[type])
					{
						new_selection.push(i_clip);
					}
				}
			}
			_selection.items = new_selection;
		}
		private function __showVisualAudioTrack():Boolean
		{
			var show:Boolean = false;
			if (__tracks.video && (! getValue('novisualaudio').boolean) && _mash.getValue(ClipProperty.HASAUDIO).boolean) show = true;
			// TODO: use ) RunClass.Media['multitrackVideo']
			return show;
		}
		private function __snapMouse(x_pos : Number):Number
		{
			try
			{
				var matches:Array = new Array();
				var x : Number;
				var d : Number;
				var snapto:Number = getValue('snapto').number;
				var back_mc:Rectangle;
				var ipreview:IPreview;
				var item_start:Number;
				var ob:Object;
				for (var k:* in _visibleClips)
				{
					ipreview = _visibleClips[k];
					if (__trimInfo.clip == ipreview.clip)
					{
						continue;
					}
					if ((! __trimInfo.not_visual) && ipreview.clip.appearsOnVisualTrack())
					{
						continue;
					}
					back_mc = ipreview.backBounds;
					x = (ipreview.displayObject.x + back_mc.x);
					d = Math.abs(x_pos - x);
					item_start = ipreview.clip.startFrame;
					if (snapto > d)
					{
						ob = new Object();
						ob.d = d;
						ob.t = item_start + ipreview.clip.getValue(ClipProperty.TIMELINESTARTFRAME).number;
						matches.push(ob);
					}
					x += back_mc.width;
					d = Math.abs(x_pos - x);
					if (snapto > d)
					{
						ob = new Object();
						ob.d = d;
						ob.t = item_start + ipreview.clip.lengthFrame - ipreview.clip.getValue(ClipProperty.TIMELINEENDFRAME).number;
						matches.push(ob);
					}
				}
				if (matches.length)
				{
					
					matches.sortOn('d', Array.NUMERIC);
					ob = matches[0];
					x_pos = frame2Pixels(ob.t) - _scroll.x;
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__snapMouse', e);
			}
			return x_pos;
		}
		private function __track2Pixels(track:Number, type:String):Number
		{
			var pixels:Number = 0;
			switch (type)
			{
				case ClipType.EFFECT :

					pixels += (__tracks.effect - track) * typeHeight(ClipType.EFFECT);
					break;

				case ClipType.AUDIO :

					if (__tracks.video)
					{
						pixels += typeHeight(ClipType.VIDEO);
					}

					pixels += (track + (__showVisualAudioTrack() ? 0 : -1) ) * typeHeight(ClipType.AUDIO);
					// intentional fallthrough to default

				default :

					pixels += __tracks.effect * typeHeight(ClipType.EFFECT);


			}
			return pixels;
		}
		private function __trimEffect(dif_time : Number):Object
		{
			var data:Object = new Object();

			if (__trimInfo.direction < 0)
			{
				// decrease start while increasing length
				var data_start:Number = __trimInfo.orig_data.start + dif_time;
				data_start = (Math.max(__trimInfo.min_start, Math.min(__trimInfo.max_start, data_start)));
				data.length = new Value(__trimInfo.end_time - data_start);
				data.start = new Value(data_start);
			}
			else
			{
				// no need to validate, or worry about collision (clip takes care of this)
				data.length = new Value(__trimInfo.orig_data.length + dif_time);
				
			}
			return data;
		}
		private function __trimImage(dif_time : Number):Object
		{
			var data:Object = new Object();
			if (__trimInfo.direction < 0)
			{
				data.length = new Value(__trimInfo.orig_data.length - dif_time);
			}
			else data.length = new Value(__trimInfo.orig_data.length + dif_time);
			return data;
		}
		private function __trimStart(event:MouseEvent, direction : Number, clip : IClip):Boolean
		{
			var do_press:Boolean = (clip.editableProperties() == null);
			if (! do_press)
			{
				var i : Number;
				var items;
				__trimInfo = new Object();
				__trimInfo.direction = direction;
				__trimInfo.clip = clip;
				
				__trimInfo.orig_data = new Object();
				__trimInfo.orig_data.start = clip.startFrame;
				__trimInfo.orig_data.length = clip.lengthFrame;
				
				// set the mouse to the first or last pixel of clip
				if (direction < 0) __trimInfo.clipX = frame2Pixels(clip.startFrame + clip.getValue(ClipProperty.TIMELINESTARTFRAME).number) - _scroll.x;
				else __trimInfo.clipX = frame2Pixels(clip.startFrame + clip.lengthFrame - clip.getValue(ClipProperty.TIMELINEENDFRAME).number) - _scroll.x;
				
				__trimInfo.not_visual = false;
				var clip_type:String = clip.type;
				var clip_track:int = clip.track;
				var clip_length:Number = clip.lengthFrame;
				var item:IClip;
				if (clip_type == ClipType.EFFECT)
				{
					__trimInfo.not_visual = true;
					if (direction < 0)
					{
						__trimInfo.end_time = (__trimInfo.orig_data.start + clip_length);
						__trimInfo.max_start =(__trimInfo.end_time - 1);
						items = _mash.clipsInOuterTracks(0, __trimInfo.orig_data.start, [clip], clip_track, 1, clip_type);
						__trimInfo.min_start = 0;
	
						for (i = 0; i < items.length; i++)
						{
							item = items[i];
							__trimInfo.min_start = Math.max(__trimInfo.min_start, item.startFrame + item.lengthFrame);
						}
					}
				}
				else if ((clip_type == ClipType.AUDIO) || (clip_type == ClipType.VIDEO) || (clip_type == ClipType.MASH))
				{
					__trimStartAV();
				}
				RunClass.MouseUtility['drag'](this, event, __trimTimed, __trimUp);
			}
			return do_press;
			
		}
		private function __trimStartAV():void
		{
			var clip:IClip = __trimInfo.clip;
			var clip_type:String = clip.type;
			
			__trimInfo.orig_data.trimstartframe = clip.getValue('trimstartframe').number;
			__trimInfo.orig_data.trimendframe = clip.getValue('trimendframe').number;
			if (clip_type == ClipType.AUDIO)
			{
				__trimInfo.not_visual = true;
			}
		}
		private function __trimTimed():void
		{
			var point:Point = new Point(RunClass.MouseUtility['x'], RunClass.MouseUtility['y']);
			point = globalToLocal(point);
			
			var mouse_x:Number = point.x;//__trimInfo.localX;
			var snap:Number = getValue('snap').number;
			var autoscroll:Number = (__zoom == 1) ? 0 : getValue('autoscroll').number;
			var iconwidth:Number = getValue('iconwidth').number;
			var x_mouse:Number = Math.min(_viewSize.width, Math.max(0, Math.round(mouse_x - iconwidth)));
			var scrolling:Number = 0;
			var iclip:IClip = __trimInfo.clip;
			
			var do_snap:Boolean;
			var clip_type:String = iclip.type;
			try
			{
				
				__trimInfo.time = null;
				if (x_mouse < autoscroll)
				{
					scrolling = -1;
				}
				else if (x_mouse > (_viewSize.width - autoscroll))
				{
					scrolling = 1;
				}
				if (scrolling)
				{
					__trimInfo.clipX -= __doScroll(scrolling, true);
				}
				
				do_snap = (snap > 0);
				if (RunClass.MouseUtility['shiftIsDown'])
				{
					do_snap = ! do_snap;
				}
				if (do_snap && (clip_type != ClipType.TRANSITION) && (__trimInfo.not_visual || (__trimInfo.direction > 0)))
				{
					x_mouse = __snapMouse(x_mouse);
				}
				
				var dif:Number = x_mouse - __trimInfo.clipX;
				var dif_time:Number = pixels2Frame(dif);
				try
				{
					switch(clip_type)
					{
						case ClipType.EFFECT:
							__trimInfo.data = __trimEffect(dif_time);
							break;
						case ClipType.AUDIO:
						case ClipType.MASH:
						case ClipType.VIDEO:
							__trimInfo.data = __trimVideo(dif_time);
							break;
						default:
							__trimInfo.data = __trimImage(dif_time);
						
					}
				}
				catch(e:*)
				{
					RunClass.MovieMasher['msg'](this + '.__trimMove data', e);
				}
				try
				{
					if (__action == null)
					{
						__action = new ClipValuesAction(iclip, __trimInfo.data);
					}
					else
					{
						__action.values = __trimInfo.data;
					}
				}
				catch(e:*)
				{
					RunClass.MovieMasher['msg'](this + '.__trimMove values', e);
				}
				if (scrolling)
				{
					
					_drawClips();
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__trimMove', e);
			}
			
		}
		private function __trimUp():void
		{
			try
			{
				__action = null;
				__trimInfo = null;
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__trimUp', e);
			}

		}
		private function __trimVideo(dif_time : Number):Object
		{
			var ob:Object = new Object();
			try
			{
				if (__trimInfo.direction < 0)
				{
					ob.trimstartframe = new Value(__trimInfo.orig_data.trimstartframe + dif_time);
				}
				else
				{
					ob.trimendframe = new Value(__trimInfo.orig_data.trimendframe - dif_time);
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__trimvideo', e);
			}
			return ob;
		}
		private function __viewableClips():Array
		{
			var first : Number = 0;
			var last : Number = 0;
			var viewable_clips:Array = [];
			if (_mash != null)
			{
				
				first = pixels2Frame(_scroll.x, 'floor');
				last = pixels2Frame(_scroll.x + _viewSize.width, 'ceil');

				//RunClass.MovieMasher['msg'](this + '.__viewableClips ' + first + ' -> ' + last + ' ' + _viewSize.width);
				var highs:Object = new Object();
				highs.effect = 0;
				highs.audio = 0;
				highs.video = 0;
				var lows:Object = new Object();
				lows.effect = 0;
				lows.audio = 0;
				lows.video = 0;
				
				var invisible_space:Number = _scroll.y;

				var visible_space:Number = _height;
				var type : String;
				var typeheight : Number;
				var displayed : Boolean;
				var i : Number;
				var inc : Number;

				var types : Array = [ClipType.EFFECT, ClipType.VIDEO, ClipType.AUDIO];
				for (var j:int = 0; j < 3; j++)
				{
					displayed = false;
					type = types[j];
					typeheight = typeHeight(type);
					if ((type == types[1]) && __showVisualAudioTrack())
					{
						typeheight += typeHeight(ClipType.AUDIO);
					}
					i = ((type == types[0]) ? __tracks[type] - 1 : 0);
					inc = ((type == types[0]) ? -1 : 1);
					
					for (; ((i > -1) && (i < __tracks[type])); i += inc)
					{
						if (invisible_space > 0)
						{
							invisible_space -= typeheight;
							if (invisible_space <= 0)
							{
								visible_space += typeheight + invisible_space;
							}
						}
						if (invisible_space <= 0)
						{
							if (visible_space >= 0)
							{
								visible_space -= typeheight;
								if (i < _mash.getValue(type).number)
								{
									displayed = true;
									highs[type] = Math.max(highs[type], i + 1);
									lows[type] = Math.min((lows[type] ? lows[type] : i + 1), i + 1);
								}
							}
						}
					}
					if (displayed)
					{
						viewable_clips = viewable_clips.concat(_mash.clipsInTracks(first, last, type, (type == ClipType.VIDEO), lows[type], highs[type] - lows[type]));
					}
				}
			}
			return viewable_clips;
		}
		private function __vScrollReset():Boolean
		{
			var did_draw:Boolean = false;
			if (_mash)
			{
				did_draw = _setScrollDimension('height', __contentHeight + getValue('vscrollpadding').number);
			}
			return did_draw;
		}
		private static var __rollCursors:Array = ['trimleft', 'hover', 'trimright'];
		private static var __trackKeys : Array = [TagType.CLIP, ClipType.EFFECT, ClipType.VIDEO, ClipType.AUDIO];
		private var __action:ClipValuesAction;
		private var __clipboard : Array = new Array();
		private var __contentHeight : Number = 0;
		private var __dragOffset:Point;
		private var __drawClipsTimer:Timer;
		private var __enabledControls : Object;
		private var __enabledProperties : Object;
		private var __fps:uint = 0;
		private var __heights : Object;
		private var __iconMaskSprite : Sprite;// matte
		private var __iconSprite : Sprite;// holds track icons
		private var __previewWidth : Number = 0;
		private var __tracks : Object;
		private var __trimInfo : Object;
		private var __zoom:Number = 0;
		private var _mash:IMash;
	}
}

