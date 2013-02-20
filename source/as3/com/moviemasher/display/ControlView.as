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
	import flash.system.ApplicationDomain;
	import flash.display.*;
	import flash.events.*;
	import flash.ui.*;
	import flash.utils.*;
	import com.moviemasher.events.*;
	import com.moviemasher.type.*;
	import com.moviemasher.constant.*;
	import com.moviemasher.interfaces.*;
	import com.moviemasher.type.*;
	import com.moviemasher.constant.*;
	
	import com.moviemasher.control.*;
	
/**
* Class represents a control within a bar, optionally containing an {@link IControl}
*
* @see BarView
* @see IControl
*/
	public class ControlView extends View
	{
		public function ControlView(panel:PanelView, bar:BarView)
		{
			super();
			__panel = panel;
			__bar = bar;
			_defaults.align = 'center';
			_defaults.spacing = '0';
		
			__propertiesAffectingAppearance = new Object();
			
		}
		override public function callControls(method:String):void
		{
			try
			{
				if (hasOwnProperty(method) && (this[method] is Function)) 
				{
					//RunClass.MovieMasher['msg'](this + ' ControlView.callControls ' + method);
					this[method]();
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + ' ControlView.callControls ' + method, e);
			}
		}
		public function dimensionsFromBarSize(space:Number, vertical):Size
		{
			
			var wh:Size = new Size();
			var wORh:String = (vertical ? 'height' : 'width');
			var hORw:String = (vertical ? 'width' : 'height');
			var dimension:String;
			var n:Number;
			dimension = _valueTarget.getValue(hORw).string;
			if (dimension.indexOf('{') != -1) n = RunClass.ParseUtility['expression'](dimension, null, true);
			else n = Number(dimension);
			
			wh[hORw] = n;
			if ((! wh[hORw]) || (wh[hORw] > space)) wh[hORw] = space;
			
			
			dimension = _valueTarget.getValue(wORh).string;
			if (dimension.indexOf('{') != -1) n = RunClass.ParseUtility['expression'](dimension, null, true);
			else n = Number(dimension);
			
			wh[wORh] = n;
			if (! wh[wORh]) 
			{
				if ((__control != null) && __control.ratio) 
				{
					var defined_space : Number = __control.getValue(hORw).number;
					if (! defined_space) defined_space = space;
					wh[wORh] = Math.round(defined_space * __control.ratio);
				}
			}
			return wh;
		}
		override public function finalize():void
		{
			__finalized = true;
			if ((__control != null) && (_width > 0) && (_height > 0) )
			{
				__control.finalize();
			}
		}
		public function flexFactor(vertical:Boolean):int
		{
			var n:int = 0;
			var value:Value = null;
			
			value = _valueTarget.getValue(vertical ? 'height' : 'width');
			if ((! value.empty) && value.NaN && (value.string.indexOf('{') == -1))
			{
				n = value.string.length;
			}
		
			return n;
		}
		override public function getValue(property:String):Value
		{	
			var value:Value;
			switch (property)
			{
				case 'id':
				case 'bind':
				case 'hide':
				case 'select':
				case 'disable':
					if (__control != null) 
					{
						value = __control.getValue(property);
						break;
					} // otherwise fall through to default
				default:
					value = super.getValue(property);
			}
			return value;
		}
		public function initDispatchers():void
		{
		//	RunClass.MovieMasher['msg'](this + ' ControlView.initDispatchers');
			if (__control != null)
			{
				try
				{
					__control.initialize();
				}
				catch(e:*)
				{
					RunClass.MovieMasher['msg'](this + ' ControlView.initDispatchers', e);
				}
			}
		}
		override public function initListeners():void
		{
			//super.initListeners();
			
			var attribute_array:Array = ['bind','select','disable','hide'];
			_initListenersForProperties(attribute_array);
		}
		override public function invalidate(type:String = ''):void
		{
			super.invalidate(type);
			switch(type)
			{
				case 'show':
					__bar.invalidate('rect');
					break;
			}
		}
		public function makeConnections():void
		{
			if (__control != null) 
			{
				try
				{
					__control.makeConnections();
				}
				catch(e:*)
				{
					RunClass.MovieMasher['msg'](this + '.makeConnections', e);
				}
			}
		}
		override public function toString():String
		{
			var s:String = '[ControlView';
			var id_string:String;
			if (__control != null)
			{
				id_string = _valueTarget.getValue(CommonWords.ID).string;
				if (id_string.length) s += ' ID:' + id_string;
			}
			else s += ' no control';
			s += ']';
			return s;
		}
		override public function set visible(boolean:Boolean):void
		{
			if (visible != boolean)
			{
				super.visible = boolean;
			}
			if (__control != null) __control.hidden = ! boolean;
		}
		override public function get visible():Boolean
		{
			return super.visible;
		}
		override protected function _adjustVisibility(will_be_visible:Boolean):void
		{
			if (will_be_visible && (__control != null)) __adjustAppearance();
		}
		override protected function _changeEvent(event:ChangeEvent):void
		{
			try
			{
				if (__propertiesAffectingAppearance[event.property] != null)
				{
					__adjustAppearance();
				}
				if (__boundProperty == event.property) 
				{
					//__control will be valid if __boundProperty is non null
					__control.setValue(event.value, event.property);		
				}
				if (_propertiesAffectingVisibility[event.property] != null)
				{
					super._changeEvent(event);
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '._changeEvent', e); 
			}
		}
		override protected function _parseTag():void
		{
			if (! String(_tag.@vertical).length)
			{
				_tag.@vertical = (__bar.vertical ? '1' : '0');
			}
			try
			{	
				var symbol:String = getValue('symbol').string;
				if (symbol.length)
				{
					var loader:IAssetFetcher = RunClass.MovieMasher['assetFetcher'](symbol, 'swf');
					var c:Class = loader.classObject(symbol, 'control');
					if (c != null)
					{
						__control = new c() as IControl;
					}
					if (__control != null)
					{
						addChild(__control.displayObject);
						try
						{
							__control.tag = _tag;
						}
						catch(e:*)
						{
							RunClass.MovieMasher['msg'](this + ' __control.tag ', e);
						}
						if (__control.isLoading)
						{
							_loadingThings++;
							__control.addEventListener(Event.COMPLETE, _tagCompleted);
						}
					}
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + ' ControlView._parseTag', e);
			}
			super._parseTag();
		}
		override protected function _prepareListener(dispatcher:IValued, property:String, attribute:String):void
		{
			var listener:IPropertied = null;
			switch(attribute)
			{
				case 'bind':
					if (__control == null) RunClass.MovieMasher['msg']('Cannot bind control without a valid symbol: ' + _tag.toXMLString());
					else 
					{
						__boundProperty = property;						
						if ( ! (dispatcher is IPropertied) ) RunClass.MovieMasher['msg']('Bind target does not follow IPropertied interface: ' + _tag.toXMLString());
						else 
						{
							listener = dispatcher as IPropertied;
							listener.addEventBroadcaster(property, __control);
							__control.property = property;
							__control.listener = listener;
						}
					}
					break;
				case 'hide': break;
				default: __propertiesAffectingAppearance[property] = true;
			}
		}
		override protected function _resizeBox():void
		{
			// we just let control implementation apply box and shadow
			if (__control == null) super._resizeBox();
		}
		override protected function _resizeSelf():void
		{
			//RunClass.MovieMasher['msg'](this + '._resizeSelf ' + _width + 'x' + _height + ' ' + x + ',' + y);
			try
			{
				if ((__control != null) && (_width > 0) && (_height > 0)) 
				{
					var needs_init:Boolean = ((__control.metrics == null) || __control.metrics.isEmpty());
					__control.metrics = new Size(_width, _height);
					if (needs_init && __finalized) __control.finalize();
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '._resizeSelf', e);
			}
		}
		override protected function get _valueTarget():Object
		{
			return ((__control == null) ? this : __control);
		}
		private function __adjustAppearance():void
		{
			var should_be_disabled:Boolean = false;
			var should_be_selected:Boolean = false;
			try
			{
				should_be_disabled = _evaluateProperty('disable');
				if (! should_be_disabled)
				{
					should_be_selected = _evaluateProperty('select');
					__controlSelected = should_be_selected;
					__control.selected = __controlSelected;
				}
				__controlDisabled = should_be_disabled;
				__control.disabled = __controlDisabled;
				_resizeBox();
				
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__adjustAppearance', e);
			}			
		}
		private var __bar:BarView;
		private var __boundProperty:String;
		private var __control:IControl;
		private var __controlDisabled:Boolean = false;
		private var __controlSelected:Boolean = false;
		private var __finalized:Boolean;
		private var __panel:PanelView;
		private var __propertiesAffectingAppearance:Object;
		
	
		
	}
}