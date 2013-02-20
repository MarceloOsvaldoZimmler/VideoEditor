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
	import com.moviemasher.control.*;
	import com.moviemasher.core.*;
	import com.moviemasher.display.*
	import com.moviemasher.events.*;
	import com.moviemasher.handler.*;
	import com.moviemasher.interfaces.*;
	import com.moviemasher.module.*;
	import com.moviemasher.source.*;
	import com.moviemasher.type.*;
	import com.moviemasher.utils.*;
	import flash.display.*;
	import flash.events.*;
	import flash.text.*;
	import flash.geom.*;
	import flash.media.*;
	import flash.net.*;
	import flash.system.*;
	import flash.utils.*;

/**
* Implementation class for player SWF root object
*/
	public class PanelsView extends PropertiedSprite implements IPanelsView
	{
		function PanelsView()
		{	
			__invalidPanels = new Dictionary();
			__panelsSprite = new Sprite();
			addChild(__panelsSprite);
			
			__panels = new Vector.<PanelView>();
			RunClass.MovieMasher['instance'].stage.addEventListener(FullScreenEvent.FULL_SCREEN, __moviemasherFullscreen);
		}
		/*
		override public function getValue(property:String):Value
		{
			var value:Value = null;
			switch (property)
			{
				case 'loaded':
					value = new Value((__loading ? (__loaded / __loading) : 1));
					break;
				default:
					value = super.getValue(property);
					
			}
			return value;
		}	
		*/	
		public function get panelsLoaded():Number
		{
			return (__loading ? (__loaded / __loading) : 1);
		}
		public function set metrics(iSize:Size):void
		{
			try
			{
				if (iSize != null)
				{
					__w = iSize.width;
					__h = iSize.height;
					
					var rect:Object;
					var panel:PanelView;
					var z:Number = __panels.length;
					var empty:Boolean;
					var rects:Vector.<Object> = new Vector.<Object>();
					var flexible_rects:Vector.<Rectangle>;
					
					var i:Number;
					if (__fullscreenPanel != null) flexible_rects = new Vector.<Rectangle>(z, true);
					
					for (i = 0; i < z; i++)
					{
						panel = __panels[i];
						if (__fullscreenPanel != null)
						{
							flexible_rects[i] = ((__fullscreenPanel == panel) ? new Rectangle(0, 0, __w, __h) : new Rectangle(0,0,0,0));
						}
						else
						{
							rect = new Object();
							rect.x = panel.getValue('x').string;
							rect.y = panel.getValue('y').string;
							rect.width = panel.getValue('width').string;
							rect.height = panel.getValue('height').string;
							rects.push(rect);
						}
					}
					if (__fullscreenPanel == null) flexible_rects =  __flexibleRects(rects, new Size(__w, __h));
					for (i = 0; i < z; i++)
					{
						panel = __panels[i];
						panel.setPanelRect(flexible_rects[i]);
					}
				}

			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.metrics', e);
			}
		}
		public function get metrics():Size
		{
			return new Size(__w, __h);
		}
		public function get displayObject():DisplayObjectContainer
		{
			return this;
		}
		public function sortByZ(a:XML, b:XML):Number
		{
			var a_track:Number = Number(a.@z);
			var b_track:Number = Number(b.@z);
			
			if (a_track < b_track)
			{
				return -1;
			}
			if (a_track > b_track)
			{
				return 1;
			}
			return 0;
		}
		override protected function _parseTag():void
		{
			try
			{
				var array:Array = new Array;
				var xml_list:XMLList;
				var xml:XML;
				var i:int;
				var z:int;
				
				xml_list = _tag.panel;
				
				z = xml_list.length();
				//RunClass.MovieMasher['msg'](this + '._parseTag ' + z + ' panel tags');

				if (z)
				{
					
					var panel:PanelView;
					try
					{
						for (i = 0; i < z; i++)
						{
							xml = xml_list[i];
							if (! String(xml.@z).length)
							{
								xml.@z = '-' + String(z - i);
							}
							array.push(xml);
						}
						array.sort(sortByZ);
						for (i = 0; i < z; i++)
						{
							xml = array[i];
							panel = new PanelView();
							__invalidPanels[panel] = true;
							panel.addEventListener(EventType.INVALIDATED, __panelInvalidated);
							panel.addEventListener(EventType.FULLSCREEN, __panelFullscreen);
							__panelsSprite.addChild(panel);
							__panels.push(panel);
							try
							{
								panel.tag = xml;
							}
							catch(e:*)
							{
								RunClass.MovieMasher['msg'](this + '._parseTag panel.tag = ' + xml, e);
							}
							if (panel.isLoading)
							{
								panel.addEventListener(Event.COMPLETE, __panelComplete);
								__loading++;
							}
						}
					}
					catch (e:*)
					{
						RunClass.MovieMasher['msg'](this + '._parseTag', e);
					}
												
					if (__loading == __loaded)
					{
						__initPanels();
					}
					
				}
			}
			catch (e:*)
			{
				RunClass.MovieMasher['msg'](this + '._parseTag', e);
			}
		}
		private function __panelFullscreen(event:Event):void
		{
			
			var panel:PanelView = event.target as PanelView;
			var full:Boolean = panel.getValue(EventType.FULLSCREEN).boolean;
			var was_full:Boolean = (__fullscreenPanel != null);
			if (full)
			{
				if (__fullscreenPanel != null) __fullscreenPanel.setValue(new Value(0), EventType.FULLSCREEN);
				__fullscreenPanel = panel;
			}
			else __fullscreenPanel = null;
			
			
			if (full != was_full)
			{
				dispatchEvent(new Event(full ? EventType.BIGSCREEN : EventType.SMALLSCREEN));
			}
			__resetSize();
		}
		private function __resetSize():void
		{
			var size:Size = new Size(__w, __h);
			try
			{
				__w = 0;
				__h = 0;
				metrics = size;
			}
			catch (e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__resetSize ' + size, e);
			}
			
		}
		private function __panelInvalidated(event:Event):void
		{
			__invalidPanels[event.target] = true;
			
			if (__laterInterval == null)
			{
				__laterInterval = new Timer(20, 1);
				__laterInterval.addEventListener(TimerEvent.TIMER, __panelInvalidatedTimed);
				__laterInterval.start();
			}
			
		}
		private function __panelInvalidatedTimed(event:TimerEvent):void
		{	
			var k:*;
			var panel:PanelView;
			var array:Vector.<PanelView>;
			try
			{
				if (__laterInterval != null)
				{
					__laterInterval.stop();
					__laterInterval.removeEventListener(TimerEvent.TIMER, __panelInvalidatedTimed);
					__laterInterval = null;
				}
				array = new Vector.<PanelView>();
				for (k in __invalidPanels)
				{
					panel = k as PanelView;
					array.push(panel);
					delete __invalidPanels[k];
				}
				
				for each (panel in array)
				{
					panel.validateVisibility();
				}
				for each (panel in array)
				{
					panel.validate();
				}
				if (__laterInterval != null) __panelInvalidatedTimed(null);
				//RunClass.MovieMasher['msg'](this + '.__panelInvalidatedTimed ' + __laterInterval);
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__panelInvalidatedTimed ' + __w + 'x' + __h, e);
			}
		}
		private function __panelComplete(event:Event):void
		{
			__loaded++;
			try
			{
				event.target.removeEventListener(Event.COMPLETE, __panelComplete);
				if (__loading == __loaded)
				{
					// will dispatch final loading event after timer
					__initPanels();
					
				}
				else
				{
					//dispatchEvent(new Event(EventType.LOADING));
				}
			}
			catch (e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__panelComplete', e);
			}
		}
		private function __initPanels():void
		{
			//RunClass.MovieMasher['msg'](this + '.__initPanels');
			__initPanelsTimer = new Timer(100, 1);
			__initPanelsTimer.addEventListener(TimerEvent.TIMER, __initPanelsTimed);
			__initPanelsTimer.start();
		}
		private function __initPanelsTimed(event:TimerEvent):void
		{
			try
			{
				__initPanelsTimer.removeEventListener(TimerEvent.TIMER, __initPanelsTimed);
				__initPanelsTimer.stop();
				__initPanelsTimer = null;
				
				
				var panel:PanelView;
				var z:int = __panels.length;
				var i:int;
				//RunClass.MovieMasher['msg'](this + '.initDispatchers');
				for (i = 0; i < z; i++)
				{
					panel = __panels[i];
					try
					{
						panel.callControls('initDispatchers');
					}
					catch(e:*)
					{
						RunClass.MovieMasher['msg'](this + '.initDispatchers ' + i, e);
					}
				}
				//RunClass.MovieMasher['msg'](this + '.initListeners');
				try
				{
					for (i = 0; i < z; i++)
					{
						panel = __panels[i];
						panel.initListeners();
					}
				}
				catch(e:*)
				{
					RunClass.MovieMasher['msg'](this + '.initListeners', e);
				}
				//RunClass.MovieMasher['msg'](this + '.makeConnections');
				try
				{
					for (i = 0; i < z; i++)
					{
						panel = __panels[i];
						panel.callControls('makeConnections');
					}
				}
				catch(e:*)
				{
					RunClass.MovieMasher['msg'](this + '.makeConnections', e);
				}
				
				try
				{
					__resetSize();
					__panelInvalidatedTimed(null);
				}
				catch(e:*)
				{
					RunClass.MovieMasher['msg'](this + '.__initPanelsTimed __resetSize', e);
				}
				//RunClass.MovieMasher['msg'](this + '.finalize');
				try
				{
					for (i = 0; i < z; i++)
					{
						panel = __panels[i];
						panel.finalize();
					}
				}
				catch(e:*)
				{
					RunClass.MovieMasher['msg'](this + '.finalize', e);
				}
				//RunClass.MovieMasher['msg'](this + '.__initPanelsTimed dispatchEvent');
				try
				{
					dispatchEvent(new Event(EventType.LOADING));
				}
				catch(e:*)
				{
					RunClass.MovieMasher['msg'](this + '.__initPanelsTimed dispatchEvent', e);
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__initPanelsTimed', e);
			}
		}
		private function __flexibleRects(a:Vector.<Object>, size:Size):Vector.<Rectangle>
		{
			var rectangles:Vector.<Rectangle> = new Vector.<Rectangle>();
			var i,j,z:int;
			var r:Rectangle;
			var ob:Object;
			var n:int;
			var keys:Array = ['x','width','y','height'];
			var key:String;
			var widthORheight:String;
			z = a.length;
			var s:String;
			try
			{
				for (i = 0; i < z; i++)
				{
					ob = a[i];
					r = new Rectangle();
					for (j = 0; j < 4; j++)
					{
						widthORheight = (j < 2 ? 'width':'height');
						key = keys[j];
						s = ob[key];
						s = s.replace( /^([\s|\t|\n]+)?(.*)([\s|\t|\n]+)?$/gm, "$2" ); // trim white space
						if (s.substr(0,1) == '-')
						{
							s = size[widthORheight] + s;
						}
						n = RunClass.ParseUtility['expression'](s, null, true); // MovieMasher.objects and option tags
						if (isNaN(n)) 
						{
							n = 0;
							RunClass.MovieMasher['msg']('Could not compile expression: ' + keys[j] + ' => ' + s);
						}
						r[key] = n;
					}
					rectangles.push(r);
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__flexibleRects', e);
			}
			return rectangles;
		}
		private function __moviemasherFullscreen(event:FullScreenEvent)
		{
			try
			{
				var panel:PanelView = __fullscreenPanel;
				if (! event.fullScreen)
				{
					if (panel != null)
					{
						panel.setValue(new Value(0), EventType.FULLSCREEN);
						__fullscreenPanel = null;
					}
				}
			}
			catch (e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__moviemasherFullscreen', e);
			
			}
		}		
		private var __panelsSprite:Sprite;
		private var __laterInterval : Timer;
		private var __initPanelsTimer:Timer;
		private var __h:Number = 0;
		private var __loaded:Number = 0;
		private var __loading:Number = 0;
		private var __panels:Vector.<PanelView>;
		private var __w:Number = 0;
		private var __invalidPanels:Dictionary;
		private var __fullscreenPanel:PanelView;
	}
}

