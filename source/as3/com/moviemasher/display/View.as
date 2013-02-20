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
	import com.moviemasher.events.*;
	import com.moviemasher.interfaces.*;
	import com.moviemasher.options.*;
	import com.moviemasher.type.*;
	import flash.display.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.ui.*;
	import flash.utils.*;
	
/**
* Abstract base class represents visual containers with controls
*
* @see Control
* @see BarView
* @see ControlView
* @see PanelView
*/
	public class View extends PropertiedSprite
	{
		public function View()
		{
			_defaults.alpha = '100';
			_defaults.angle = '90';
			_defaults.border = '0';
			_defaults.bordercolor = '0';
			_defaults.color = '';
			_defaults.curve = '0';
			_defaults.grad = '0';
			_defaults.padding = '0';

			// create container for children
			_childrenSprite = new Sprite();
			addChild(_childrenSprite);
			_invalid = new Object();
			_propertiesAffectingVisibility = new Object();

		}
		public function callControls(method:String):void
		{
			if (_children != null)
			{
				var z:int = _children.length;
				for (var i:int = 0; i < z; i++)
				{
					_children[i].callControls(method);
				}
			}
		}
		public function finalize():void
		{
			super.visible = false;
			invalidate('show');
			if (_children != null)
			{
				var z:int = _children.length;
				for (var i:int = 0; i < z; i++)
				{
					_children[i].finalize();
				}
			}
		}
		public function initListeners():void
		{
			_initListenersForProperties(['hide']);
			if (_children != null)
			{
				var z:int = _children.length;
				for (var i:int = 0; i < z; i++)
				{
					_children[i].initListeners();
				}
			}
		}
		public function invalidate(type:String = ''):void
		{

			if (type.length && (_invalid[type] == null))
			{
				//RunClass.MovieMasher['msg'](this + '.invalidate ' + type);
				_invalid[type] = true;
			}
			_invalidated = true;
		}
		public function parentChangingVisiblity(boolean:Boolean):void
		{
			visible = boolean && __shouldBeVisible;
		}
		final public function setRect(rect:Rectangle):void
		{
			var is_invalid:Boolean = rect.isEmpty();
			if (_setRectInvalid != is_invalid)
			{
				_setRectInvalid = is_invalid;
				invalidate('show');
			}
			if (! _setRectInvalid)
			{
				_rect = rect;
			
			
				var size_is_same:Boolean = ((_width == _rect.width) && (_height == _rect.height));
				var position_is_same:Boolean = ((x == _rect.x) && (y == _rect.y))
				if ( ! (position_is_same && size_is_same) )
				{
					x = _rect.x;
					y = _rect.y;
					if (! size_is_same)
					{
						_width = _rect.width;
						_height = _rect.height;
						
					}
				}
				//if ((! size_is_same) || (_children != null)) 
				//RunClass.MovieMasher['msg'](this + '.setRect ' + _rect + ' position_is_same = ' + position_is_same + ' size_is_same = ' + size_is_same);
				__resize();
			}
		}
		override public function setValue(value:Value, property:String):Boolean
		{		
			if (_propertiesAffectingVisibility[property])
			{
				//RunClass.MovieMasher['msg'](this + '.setValue ' + property + ' ' + value.string);
				invalidate('show');
			}
			return super.setValue(value, property); 
		}
		final public function validate():void
		{
			try
			{
				//RunClass.MovieMasher['msg'](this + '.validate');
				if (_children != null)
				{
					var z:int = _children.length;
					for (var i:int = 0; i < z; i++)
					{
						_children[i].validate();
					}
				}
				_validateSelf();
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.validate', e);
			}
		}
		final public function validateVisibility():void
		{

			try
			{
				if (_children != null)
				{
					var z:int = _children.length;
					for (var i:int = 0; i < z; i++)
					{
						_children[i].validateVisibility();
					}
				}
				if (getValue('hide').empty)
				{
					if (visible != __hasVisibleChildren())
					{
						invalidate('show');
					}
				}
				_invalidated = false;
				if (_invalid.show)
				{
					delete _invalid.show;
					__adjustVisibility();
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.validateVisibility', e);
			}
		}
		public function get isLoading():Boolean
		{
			return Boolean(_loadingThings);
		}
		final public function get shouldBeVisible():Boolean
		{
			return __shouldBeVisible;
		}
		override public function set visible(boolean:Boolean):void
		{
			if (visible != boolean)
			{
				super.visible = boolean;
			}
			if (_children != null)
			{
				var view:View;
				var i,z:int;
				z = _children.length;
				if (z)
				{
					for (i = 0; i < z; i++)
					{
						view = _children[i];
						view.parentChangingVisiblity(boolean);
					}
				}
			}
		}
		protected function get _valueTarget():Object
		{
			return this;
		}
		protected function _adjustVisibility(will_be_visible:Boolean):void
		{
		}
		protected function _changeEvent(event:ChangeEvent):void
		{
			try
			{
				invalidate('show');
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '._changeEvent', e); 
			}
		}
		final protected function _evaluateProperty(property:String):Boolean
		{
			var should:Boolean = false;
			var value:Value;
			var and_search:Boolean;
			try
			{
				value = getValue(property);
				if (value.string.length)
				{
					should = RunClass.ParseUtility['booleanExpressions'](value.string);
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '._evaluateProperty ' + property, e);
			}

			return should;
		}
		final protected function _initListenersForProperties(attribute_array):void
		{
			
			var attribute:String;
			var expression:String;
			var s:String;
			var targets:Array;
			var z:int;
			var y:int;
			var i:int;
			var bits:Array;
			var dispatcher:IValued;
			var property:String;
			var target :String;
			var ob:Object;
			var dispatchers:Dictionary = new Dictionary();
			var listener:IPropertied = null;
			var attribute_value:Value;
			var did_set_property:Boolean = false;
			var attribute_index:int;
			
			y = attribute_array.length;
			
			for (attribute_index = 0; attribute_index < y; attribute_index++)
			{
				attribute = attribute_array[attribute_index];
				attribute_value = getValue(attribute);
		
				
						
				if (! attribute_value.empty)
				{
					
					s = attribute_value.string;
					if (s.indexOf('|') != -1)
					{
						attribute_value.delimiter = '|';
					}
					else if (s.indexOf('&') != -1)
					{
						attribute_value.delimiter = '&';
					}
					else attribute_value.delimiter = RunClass.MovieMasher['getOption']('parse', 'evaluate_delimiter');
					
					targets = attribute_value.array;
					
					z = targets.length;
				
					for (i = 0; i < z; i++)
					{
						expression = targets[i];
						bits = expression.split(/([\w\.]+)([><!]?[=]?)/g);
						expression = bits[1];
						
						bits = expression.split('.');
						property = bits.pop();
						target = bits.join('.');
						if (target.length)
						{
							dispatcher = RunClass.MovieMasher['getByID'](target) as IValued;
							
							
							if (dispatcher != null)
							{
								if (dispatchers[dispatcher] == null) dispatchers[dispatcher] = new Object();
								dispatchers[dispatcher][property] = dispatcher;
								if (attribute == 'hide') _propertiesAffectingVisibility[property] = true;
								_prepareListener(dispatcher, property, attribute);
							}
							else RunClass.MovieMasher['msg']("Target not found: " + target + ' in ' + attribute_value.string);
						}
						else RunClass.MovieMasher['msg']("No property target found: " + property + ' in ' + expression + ' delimiter: ' + attribute_value.delimiter + ' ' + RunClass.MovieMasher['getOption']('parse', 'evaluate_delimiter'));
					}
				}
			}
			var did:Dictionary = new Dictionary();
			for each (var object:Object in dispatchers)
			{
					
				for (property in object)
				{
					dispatcher = object[property];
					if (did[dispatcher] == null)
					{
						did[dispatcher] = new Object();
					}
					if (did[dispatcher][property] == null)
					{
						did[dispatcher][property] = true;
						
						
						dispatcher.addEventListener(property, _changeEvent);
						try
						{
							_changeEvent(new ChangeEvent(dispatcher.getValue(property), property));
						}
						catch(e:*)
						{
							RunClass.MovieMasher['msg'](this + '._initListenersForProperties ' + property + ' ' + dispatcher, e); 
						}
					}		
				}
			}
		}
		override protected function _parseTag():void
		{
			try
			{
				var id:String = getValue(CommonWords.ID).string;
				if (id.length)
				{
					RunClass.MovieMasher['setByID'](id, _valueTarget);
				}				
				
				var url:String = getValue('background').string;
				if (url.length)
				{
					var loader:IAssetFetcher = RunClass.MovieMasher['assetFetcher'](url);
					
					if (loader.state == EventType.LOADING)
					{
						_loadingThings++;
					
						loader.addEventListener(Event.COMPLETE, __backCompleted);
					}
				}
				if (! getValue('dontmask').boolean)
				{
					// create a mask for container of children
					__maskSprite = new Sprite();
					addChild(__maskSprite);
					_childrenSprite.mask = __maskSprite;
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + ' View._parseTag', e);
			}

		}
		protected function _prepareListener(listener:IValued, property:String, attribute:String):void
		{
			
		}
		protected function _resizeBox():void
		{
			try
			{
				
				var options:BoxOptions = new BoxOptions();
				for (var k:String in _defaults)
				{
					options.setValue(new Value(_defaults[k]), k);
				}
				options.tag = _tag;
				options.setValue(new Value(_width), 'width');
				options.setValue(new Value(_height), 'height');
				
				RunClass.DrawUtility['shadowBox'](options, this);
				
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '._resizeBox', e);
			}	
		}
		protected function _resizeView():void
		{
			try
			{
				_resizeBox();
				
				
				var border:Number = getValue('border').number;
				var padding:Number =  getValue(ControlProperty.PADDING).number;
				var url:String = getValue('background').string;
				if (url.length)
				{
					if (__background != null)
					{
						__background.mask = null;
						removeChild(__background);
						removeChild(__backgroundSprite);
						__backgroundSprite = null;
					}
					var loader:IAssetFetcher = RunClass.MovieMasher['assetFetcher'](url);
					
					__background = loader.displayObject(url, '', new Size(_width - (2 * border), _height - (2 * border)));
					if (__background != null)
					{
						
						addChildAt(__background, 0);
						__background.y = __background.x = border;
						// MASK
						// create a mask for container in container
						__backgroundSprite = new Sprite();
						addChild(__backgroundSprite);
						__background.mask = __backgroundSprite;
				
						__backgroundSprite.graphics.clear();
						RunClass.DrawUtility['setFill'](__backgroundSprite.graphics, 0x000000);
						RunClass.DrawUtility['drawPoints'](__backgroundSprite.graphics, RunClass.DrawUtility['points'](border, border, _width - (2 * border), _height - (2 * border), getValue('curve').number));
	
					}
				}		
				if (! getValue('dontmask').boolean)
				{
					
					// MASK
					__maskSprite.graphics.clear();
					RunClass.DrawUtility['setFill'](__maskSprite.graphics, 0x000000);
					RunClass.DrawUtility['drawPoints'](__maskSprite.graphics, RunClass.DrawUtility['points']((padding + border), (padding + border), _width - (2 * (padding + border)), _height - (2 * (padding + border)), getValue('curve').number));
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '._resizeView', e);
			}
		}		
		protected function _resizeSelf():void
		{ }
		protected function _tagCompleted(event:Event)
		{
			try
			{
				event.target.removeEventListener(Event.COMPLETE, _tagCompleted);
				__backCompleted(event);
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '._tagCompleted', e);
			}
		}
		protected function _validateSelf():void
		{
			try
			{
				if (visible && _invalid.rect) 
				{
					delete _invalid.rect;
					__resize();
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '._validateSelf', e);
			}
			
		}
		protected function _visibleChildren(should_be:Boolean = false):Vector.<View>
		{
			var vector:Vector.<View> = new Vector.<View>();
			var i,z:int;
			z = _children.length;
			for (i = 0; i < z; i++)
			{
				if (_children[i][(should_be ? 'shouldBeVisible' : 'visible')]) 
				{
					vector.push(_children[i]);
				}
			}
			return vector;
		
		}
		private function __adjustVisibility():void
		{
			
			try
			{
				__shouldBeVisible = __canBeVisible();
				var should_be_visible:Boolean = (! _setRectInvalid) && __shouldBeVisible;
				_adjustVisibility(should_be_visible);
										
				visible = should_be_visible;
				
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.adjustVisibility', e);
			}
		}
		protected function __backCompleted(event:Event)
		{
			try
			{
				//event.target.removeEventListener(Event.COMPLETE, __backCompleted);
				_loadingThings--;
				
				if (! _loadingThings) 
				{
					dispatchEvent(new Event(Event.COMPLETE));
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__backCompleted', e);
			}
		}
		private function __canBeVisible():Boolean
		{
			return (getValue('hide').empty ? __hasVisibleChildren(true) : ! _evaluateProperty('hide') );
		}
		private function __hasVisibleChildren(should_be:Boolean = false):Boolean
		{
			var found:Boolean = ((_children == null) || (! _children.length));
			var i,z:int;
			if (! found)
			{
				z = _children.length;
				for (i = 0; i < z; i++)
				{
					if (_children[i][(should_be ? 'shouldBeVisible' : 'visible')]) 
					{
						found = true;
						break;
					}
				}
			}
				
			return found;
		}
		private function __resize():void
		{
			try
			{
				_resizeSelf();
				_resizeView();
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__resize', e);
			}

		}
		private var __background:DisplayObject;
		private var __backgroundSprite:Sprite;
		private var __maskSprite:Sprite;
		private var __shouldBeVisible:Boolean = true;
		protected var _children:Vector.<View>;
		protected var _childrenSprite:Sprite;
		protected var _height:Number = 0;
		protected var _invalid:Object;
		protected var _invalidated:Boolean = false;
		protected var _loadingThings:Number = 0;
		protected var _rect:Rectangle;
		protected var _setRectInvalid:Boolean = false;
		protected var _width:Number = 0;
		protected var _propertiesAffectingVisibility:Object;
	}
}