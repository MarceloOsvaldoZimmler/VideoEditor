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
	import com.moviemasher.constant.*;
	import com.moviemasher.display.*;
	import com.moviemasher.events.*;
	import com.moviemasher.interfaces.*;
	import com.moviemasher.options.*;
	import com.moviemasher.type.*;
	import com.moviemasher.utils.*;
	import flash.display.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.utils.*;

/**
* Abstract base class for all controls
*/
	public class Control extends PropertiedSprite implements IControl
	{
		public function Control()
		{
			__loaders = new Dictionary();
			_defaults = new Object();
			_defaults.curve = '0';
			_displayedObjects = new Object();
			__displayObjectCache = new Dictionary();
		}
		protected function _createChildren():void
		{ }
		public function dispatchPropertyChange(is_ing : Boolean = false):void
		{
			try
			{
				if (_property.length)
				{
					var change_event:ChangeEvent = new ChangeEvent(getValue(_property), _property);
					change_event.done = ! is_ing;
					dispatchEvent(change_event);
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.dispatchPropertyChange', e);
			}

		}
		public function initialize():void
		{
			try
			{
				if ((! flexible) && _ratioKey.length)
				{
					var path:String = getValue(_ratioKey).string;
					if (path.length)
					{
						var loader:IAssetFetcher = RunClass.MovieMasher['assetFetcher'](path) as IAssetFetcher;
						var display_object:DisplayObject = loader.displayObject(path);
						
						if (display_object != null)
						{
							__ratio = display_object.width / display_object.height;
						}
					}
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.initialize', e);
			}
		}
		public function makeConnections():void
		{
		
		}		
		public function finalize():void
		{
			
		}
		public function resize():void
		{ _update(); }
		override public function setValue(value:Value, property:String):Boolean
		{
			super.setValue(value, property);
			_update();
			return false;
		}
		override public function toString():String
		{
			var s:String = '[Control';
			var id_string:String = getValue('id').string;
			if (id_string.length) s += ' ' + id_string;
			s += ']';
			return s;
		}
		public function updateTooltip(tooltip:ITooltip):Boolean
		{
			var dont_delete:Boolean = false;
			var tip:String;
			try
			{
				tip = getValue('tooltip').string;
				dont_delete = Boolean(tip.length);
				if (dont_delete)
				{
					tip = RunClass.ParseUtility['brackets'](tip);
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
		override public function get height():Number
		{
			return _height;
		}
		override public function get width():Number
		{
			return _width;
		}
		final public function get disabled():Boolean
		{
			return _disabled;
		}
		final public function set disabled(boolean:Boolean):void
		{			
			if (_disabled != boolean)
			{
				_disabled = boolean;
				_update();
			}
		}
		final public function get displayObject():DisplayObjectContainer
		{
			return this;
		}
		final public function get flexible():Number
		{
			var n:int = 0;
			var value:Value = getValue(getValue('vertical').boolean ? 'height' : 'width');
			
			if ((! value.empty) && value.NaN && (value.string.indexOf('{') == -1))
			{
				n = value.string.length;
			}
			return n;


		}
		final public function set hidden(boolean:Boolean):void
		{
			if (_hidden != boolean)
			{
				_hidden = boolean;
				_adjustVisibility();
			}
		}
		public function get isLoading():Boolean
		{
			return Boolean(_loadingThings);
		}
		public function set listener(object:IPropertied):void
		{	
			
		}

		public function set metrics(iMetrics:Size):void
		{
			_width = iMetrics.width;
			_height = iMetrics.height;
			_resizing = true;
			resize();
			_resizing = false;
		}
		public function get metrics():Size
		{
			return new Size(_width, _height);
		}
		public function set property(iProperty:String):void
		{
			_property = iProperty;
		}
		public function get property():String
		{
			return _property;
		}
		public function get ratio():Number
		{
			return __ratio;
		}
		final public function get selected():Boolean
		{
			return _selected;
		}
		final public function set selected(boolean:Boolean):void
		{
			if (getValue('id').equals('video_btn')) RunClass.MovieMasher['msg'](this + '.selected ' + boolean + ' ' + _selected);
			if (_selected != boolean)
			{
				_selected = boolean;
				_update();
			}
		}
		protected function _adjustVisibility():void
		{ }
		override final protected function _parseTag():void
		{
			try
			{
				if (_allowFlexibility)
				{
					var wORh:String = (getValue('vertical').boolean ? 'height' : 'width');
					if (! getValue(wORh).string.length)
					{
						_defaults[wORh] = '*';
					}
				}
				_createChildren();
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '._parseTag', e);
			}		

		}
		protected function _createTooltip() : void
		{
			addEventListener(MouseEvent.MOUSE_OVER, __mouseOver);
			useHandCursor = false;
			
			if (! getValue('tooltip').empty)
			{
				var url:String;
				url = getValue('tooltipsymbol').string;
				if (! url.length)
				{
					url = RunClass.MovieMasher['getOption']('tooltip', 'symbol');
				}
				if (url.length)
				{
					_displayObjectLoad(url, true);
					url = RunClass.MovieMasher['getOption']('tooltip', TextProperty.FONT);
					if (url.length)
					{	
						var font_tag:XML = RunClass.MovieMasher['fontTag'](url);
						if (font_tag != null)
						{
							_displayObjectLoad(font_tag.@url, true);
						}
					}
				}
			}
		}
		final protected function _drawBox(state:String = ''):void
		{
			try
			{
				
				var mode:String;
				mode = getValue(state + 'mode').string;
				if ((! mode.length) && state.length) mode = getValue('mode').string;
				if (! mode.length) mode = 'normal';
				blendMode = BlendMode[mode.toUpperCase()];
				
				
				var options:BoxOptions = new BoxOptions();
				for (var k:String in _defaults)
				{
					options.setValue(new Value(_defaults[k]), k);
				}
				options.tag = _tag;
				options.setValue(new Value(_width), 'width');
				options.setValue(new Value(_height), 'height');
								
				//if (state.length) RunClass.MovieMasher['msg'](this + '._resizeBox ' + state + ' ' + mode + ' ' + _width+'x'+_height);

				
				RunClass.DrawUtility['shadowBox'](options, this, state);
				
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '._resizeBox', e);
			}	
		}


		protected function _displayObjectLoad(property:String, is_url:Boolean = false):Boolean
		{
			var is_loading:Boolean = false;
			var url:String = property;
			if (! is_url)
			{ 
				url = getValue(property).string;
				if (property == TextProperty.FONT)
				{
					var font_tag:XML = RunClass.MovieMasher['fontTag'](url);
					if (font_tag != null)
					{
						url = font_tag.@url;
					}
				}
			}
			if (url.length)
			{
				var loader:IAssetFetcher = RunClass.MovieMasher['assetFetcher'](url) as IAssetFetcher;
				if (loader.state == EventType.LOADING)
				{
					if (__loaders[loader] == null)
					{
						__loaders[loader] = true;
						loader.addEventListener(Event.COMPLETE, __didLoad);
						_loadingThings++;
				
						is_loading = true;
					}
				}
				
			}
			return is_loading;
		}
		protected function _displayObjectSize(property:String, size:Size = null, container:DisplayObjectContainer = null):DisplayObject
		{
			if (container == null) container = this;

			var display_object:DisplayObject = null;
			var url:String;
			var vertical:Boolean;
			var loader:IAssetFetcher;
			vertical = getValue('vertical').boolean;
			size = ((size == null) ? new Size() : size.copy());
			if ((! size.width) && vertical)
			{
				size.width = getValue('width').number;
				if (! size.width) size.width = _width;
			}
			if ((! size.height) && (! vertical))
			{
				size.height = getValue('height').number;
				if (! size.height) size.height = _height;
			}
					
			display_object = _displayedObjects[property];
			if ((display_object == null) || (! size.equals(__displayObjectCache[display_object])))
			{
				
				url = getValue(property).string;
				if (url.length)
				{
					if (display_object != null) 
					{
						container.removeChild(_displayedObjects[property]);
						delete __displayObjectCache[display_object];
					}
					loader = RunClass.MovieMasher['assetFetcher'](url) as IAssetFetcher;
				
					display_object = loader.displayObject(url, '', size);
					if (display_object != null)
					{
						__displayObjectCache[display_object] = size;
						_displayedObjects[property] = display_object;
						display_object.name = property;
					}
				}
			}
			if (display_object != null) 
			{
				if (container.contains(display_object))
				{
					container.setChildIndex(display_object, container.numChildren - 1);
				}
				else
				{
					container.addChild(display_object);
				}
			}
			return display_object;
		
		}
		
		protected function _mouseDrag():void
		{ }
		protected function _mouseHover(event:MouseEvent):void
		{ }
		protected function _mouseOut():void
		{}	
		protected function _mouseOver(event:MouseEvent):void
		{}
		protected function _release() : void
		{ }
		protected function _update() : void
		{ }
		private function __didLoad(event:Event):void
		{
			try
			{
				_loadingThings--;
				
				if (! _loadingThings)
				{
					__loaders = null;
					dispatchEvent(new Event(Event.COMPLETE));
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__didLoad', e);
			}
		}
		private function __mouseHover(event:MouseEvent) : void
		{
			try
			{		
				_mouseHover(event);
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__mouseHover', e);
			}
		}
		private function __mouseOut(event:MouseEvent) : void
		{
			try
			{
				removeEventListener(MouseEvent.MOUSE_MOVE, __mouseHover);
				removeEventListener(MouseEvent.MOUSE_OUT, __mouseOut);
				_rollTimerCancel();
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__mouseOut _rollTimerCancel', e);
			}
			try
			{	
				_mouseOut();
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__mouseOut ', e);
			}
		}
		private function __mouseOver(event:MouseEvent) : void
		{
			try
			{
				if ( ! (RunClass.MouseUtility['dragging'] || _disabled || _hidden))
				{
					addEventListener(MouseEvent.MOUSE_MOVE, __mouseHover);
					addEventListener(MouseEvent.MOUSE_OUT, __mouseOut);
					__rollTooltip(event);
					_mouseOver(event);
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this, e);
			}
		}
		protected function _rollTimerCancel():void
		{
			try
			{
				if (__rollTimer != null)
				{
					__rollTimer.stop();
					__rollTimer.removeEventListener(TimerEvent.TIMER, __rollTimed);
					__rollTimer = null;
				}
				RunClass.MovieMasher['setTooltip'](null, this);
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this, e);
			}
			
		}
		protected function _rollTooltip():void
		{
			if (hitTestPoint(RunClass.MovieMasher['instance'].mouseX, RunClass.MovieMasher['instance'].mouseY))
			{
				var i_tooltip:ITooltip = _displayedObjects.tooltipsymbol;
				var c:Class;
				
				if (i_tooltip == null)
				{
					var url:String;
					url = getValue('tooltipsymbol').string;
					if (! url.length)
					{
						url = RunClass.MovieMasher['getOption']('tooltip', 'symbol');
					}
					if (url.length)
					{
						var loader:IAssetFetcher = RunClass.MovieMasher['assetFetcher'](url, 'swf');
						c = loader.classObject(url);
						if (c != null)
						{
							i_tooltip = new c();
							if (i_tooltip != null)
							{
								_displayedObjects.tooltipsymbol = i_tooltip;
								i_tooltip.tag = RunClass.MovieMasher['getOptionXML']('tooltip', 'symbol');
								//i_tooltip.text = getValue('tooltip').string;
							}
						}
					}
				}
				if (i_tooltip != null)
				{
					RunClass.MovieMasher['setTooltip'](i_tooltip, this);
					i_tooltip.displayObject.addEventListener(Event.REMOVED, __tooltipRemoved);
				}
				
			}
		
		}
		private function __rollTimed(event:TimerEvent):void
		{
			try
			{
				_rollTimerCancel();
				
				_rollTooltip();
				
				
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this, e);
			}
		}
		private function __rollTooltip(event:MouseEvent) : void
		{
			try
			{
				if (! getValue('tooltip').empty)
				{
					if ((__lastTooled != null) && ((((new Date()).getTime()) - __lastTooled.getTime()) < 1000))
					{
						__rollTimed(null);
					}
					else if (__rollTimer == null)
					{
						__rollTimer = new Timer(1000, 1);
						__rollTimer.addEventListener(TimerEvent.TIMER, __rollTimed);
						__rollTimer.start();
					}
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this, e);
			}
		
		}
		private function __tooltipRemoved(event:Event):void
		{
			try
			{
				event.target.removeEventListener(Event.REMOVED, __tooltipRemoved);
				__lastTooled = new Date();
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this, e);
			}
		}
		private static var __lastTooled:Date;
		private var __displayObjectCache:Dictionary;
		private var __loaders:Dictionary;
		private var __ratio:Number = 0;
		private var __rollTimer:Timer;
		protected var _allowFlexibility:Boolean = false;
		protected var _disabled : Boolean = false;
		protected var _displayedObjects:Object;
		protected var _height:Number = 0;
		protected var _hidden:Boolean = true;
		protected var _loadingThings:uint = 0;
		protected var _property:String = '';
		protected var _ratioKey:String = '';
		protected var _resizing : Boolean = false;
		protected var _selected : Boolean = false;
		protected var _value:String = '';
		protected var _width:Number = 0;
	}
}