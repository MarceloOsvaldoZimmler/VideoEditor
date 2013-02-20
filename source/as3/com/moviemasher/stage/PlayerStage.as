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

package com.moviemasher.stage
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
	public class PlayerStage extends PropertiedMovieClip
	{
		function PlayerStage()
		{
			SourceClass.LocalSource = LocalSource;
			SourceClass.Source = Source;
			SourceClass.RemoteSource = RemoteSource;
			RunClass.Mash = Mash;
			RunClass.Clip = Clip;
			RunClass.Media = Media;
			RunClass.Module = Module;
			RunClass.DrawUtility = DrawUtility;
			RunClass.MouseUtility = MouseUtility;
			RunClass.PlotUtility = PlotUtility;
			RunClass.StringUtility = StringUtility;
			RunClass.TimeUtility = TimeUtility;
			RunClass.FontUtility = FontUtility;
			RunClass.PlayerStage = PlayerStage;
			RunClass.PanelsView = PanelsView;
			
			instance = this;

			__players = new Vector.<IPlayer>();
			
			_defaults.id = ReservedID.MOVIEMASHER;
			RunClass.MovieMasher['setByID'](ReservedID.MOVIEMASHER, this);
			
			
			if (! RunClass.MovieMasher['loaded'])
			{
				RunClass.MovieMasher['instance'].addEventListener(EventType.LOADED, __moviemasherLoaded);
			}
			else
			{
				__moviemasherLoaded(null);
			}
		}
		public static function addSource(xml:XML):ISource
		{
			var isource:ISource;
			var c:Class;
			var symbol:String;
			var loader:IAssetFetcher;
			var id:String;
			id = String(xml.@id);
			if (id.length)
			{
				symbol= String(xml.@symbol);
				if (! symbol.length)
				{
					symbol = String(xml.@url);
					symbol = '@' + (symbol.length ? 'Remote' : 'Local') + 'Source';
				}
				loader = RunClass.MovieMasher['assetFetcher'](symbol, 'swf');
				if (loader != null)
				{
					if (loader.state != EventType.LOADING)
					{
						c = loader.classObject(symbol, 'source');
					}
				}
				if (c != null)
				{
					isource = new c();
					if (isource != null)
					{
						isource.tag = xml;
						RunClass.MovieMasher['setByID'](id, isource);
					}
				}		
			}
			return isource;
		}
		override public function getValue(property:String):Value
		{
			var value:Value = null;
			switch (property)
			{
				case 'random':
					value = new Value(IDUtility.generate());
					break;
				case 'playing':
					value = new Value((__playingClip == null) ? 0 : 1);
					break;
				case 'loaded':
					value = new Value(__panelsView.panelsLoaded);
					break;
				case 'width':
				case 'height':
					value = new Value(RunClass.MovieMasher['instance'][property]);
					break;
				default:
					value = super.getValue(property);
			}
			return value;
		}
		override public function setValue(value:Value, property:String):Boolean
		{
			// since I am global object 'moviemasher' property changes should be dispatched
			var result:Boolean = super.setValue(value, property);
			_dispatchEvent(property, value);
			return result;
		}
		public function registerPlayer(player:IPlayer):void
		{
			var index:int = __players.indexOf(player);
			//RunClass.MovieMasher['msg'](this + '.registerPlayer ' + player + ' ' + index);
			if (index == -1)
			{
				__players.push(player);
			}
		}
		public function deregisterPlayer(player:IPlayer):void
		{
			var index:int = __players.indexOf(player);
		//	RunClass.MovieMasher['msg'](this + '.deregisterPlayer ' + player + ' ' + index);
			if (index > -1) 
			{
				__players.splice(index, 1);
			}
			player.paused = true;
		}
		public function startPlaying(clip:IPlayer):void
		{
			stopPlaying();
			__playingClip = clip;
			if (RunClass.BrowserPreview != null) RunClass.BrowserPreview['animatePreviews'](false); 
		}
		public function stopPlaying():void
		{
			if (__playingClip != null)
			{
				__playingClip.paused = true;
			}
			__playingClip = null;
			if (RunClass.BrowserPreview != null) RunClass.BrowserPreview['animatePreviews'](true); 
		}
		private function __setSize(iSize:Size):void
		{
			try
			{	
				if (! iSize.isEmpty())
				{
					__w = iSize.width;
					__h = iSize.height;
					__panelsView.metrics = new Size(__w, __h);
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__setSize', e);
			}
		}
		private function __loadingPanels(evemt:Event)
		{
			//RunClass.MovieMasher['msg'](this + '.__loadingPanels');
			dispatchEvent(new Event(EventType.LOADING));
			RunClass.MovieMasher['instance'].addEventListener(Event.RESIZE, __moviemasherResize);
			__moviemasherResize(null);
		}
		private function __initializeTimer(event:TimerEvent):void
		{
			try
			{
				event.target.removeEventListener(TimerEvent.TIMER, __initializeTimer);
				var array:Array;
				var xml_list:XMLList;
				var xml:XML;
				var i:int;
				var z:int;
				
				array = RunClass.MovieMasher['searchTags']('source');
				
				for each (xml in array)
				{
					addSource(xml);
				}
	
	
				array = RunClass.MovieMasher['searchTags']('panel');
				z = array.length;
				//RunClass.MovieMasher['msg'](this + '.__initializeTimer ' + z + ' panel tags');
				if (z)
				{
					__panelsView = new PanelsView();
					addChild(__panelsView);
					__panelsView.addEventListener(EventType.BIGSCREEN, __bigscreen);
					__panelsView.addEventListener(EventType.SMALLSCREEN, __smallscreen);
					__panelsView.addEventListener(EventType.LOADING, __loadingPanels);
					
					__panelsView.tag = array[0].parent();
					RunClass.MovieMasher['instance'].stage.addEventListener(KeyboardEvent.KEY_UP, __keyUp);
					RunClass.MovieMasher['instance'].stage.focus = RunClass.MovieMasher['instance'].stage;

				}
				
			}
			catch (e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__initializeTimer ' + __panelsView, e);
			}
		}
		private function __moviemasherLoaded(event:Event):void
		{
			try
			{
				//RunClass.MovieMasher['msg'](this + '.__moviemasherLoaded');
				if (event != null) event.target.removeEventListener(EventType.LOADED, __moviemasherLoaded);
				
				var timer:Timer = new Timer(100, 1);
				timer.addEventListener(TimerEvent.TIMER, __initializeTimer);
				timer.start();
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__moviemasherLoaded', e);
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
		private function __keyUp(event:KeyboardEvent):void
		{
			if (event.keyCode == 32) // spacebar
			{
				var field:TextField = null;
				if (RunClass.MovieMasher['instance'].stage.focus != null)
				{
					if (RunClass.MovieMasher['instance'].stage.focus is TextField)
					{
						field = RunClass.MovieMasher['instance'].stage.focus as TextField;
						if (field.name != ReservedID.MOVIEMASHER) field = null;
					}
				}
				if (field == null) 
				{
					RunClass.MovieMasher['instance'].stage.focus = RunClass.MovieMasher['instance'].stage;
					var player:IPlayer = null;
					if (__players.length) player = __players[__players.length - 1];
					if (player != null)
					{
					//	RunClass.MovieMasher['msg'](this + '.__keyUp ' + player + ' ' + player.paused);
						player.paused = ! player.paused;
					}
				}
				//else RunClass.MovieMasher['msg'](this + '.__keyUp ' + (RunClass.MovieMasher['instance'].stage.focus as TextField).caretIndex);
							
			}
		}
		private function __moviemasherResize(event:Event):void
		{
			try
			{
				var mm_size:Size = new Size(RunClass.MovieMasher['instance'].width, RunClass.MovieMasher['instance'].height);
				__setSize(mm_size);
			
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__moviemasherResize', e);
			}
		}
		
		
		private function __bigscreen(event:Event):void
		{
			instance.stage.displayState = StageDisplayState.FULL_SCREEN;
		}
		private function __smallscreen(event:Event):void
		{
			instance.stage.displayState = StageDisplayState.NORMAL;
		}
		
		private static var __needsAVFrame:Class = AVFrame;
		private static var __needsAVImage:Class = AVImage;
		private static var __needsJavaScriptSource:Class = JavaScriptSource;
		private static var __needsAVMash:Class = AVMash;
		private static var __needsCGI:Class = CGI;
		private static var __needsIcon:Class = Icon;
		private static var __needsMP3:Class = MP3Handler;
		private static var __needsPlayer:Class = Player;
		private static var __needsSlider:Class = Slider;
		private static var __needsText:Class = Text;
		private static var __needsToggle:Class = Toggle;
		private static var __needsTooltip:Tooltip;
		private static var __panelsView:PanelsView;
		private var __h:Number = 0;
		private var __initPanelsTimer:Timer;
		private var __players:Vector.<IPlayer>;
		private var __playingClip:IPlayer;
		private var __w:Number = 0;
		public static var instance:PlayerStage;

	}
}

