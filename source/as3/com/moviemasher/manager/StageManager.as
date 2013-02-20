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
package com.moviemasher.manager
{
	import flash.display.*;
	import flash.geom.*;
	import flash.text.*;
	import flash.ui.*;
	import flash.events.*;
	import flash.net.*;
	import flash.system.*;
	import flash.utils.*;
	import com.moviemasher.type.*;
	import com.moviemasher.constant.*;
	import com.moviemasher.display.*;
	import com.moviemasher.utils.*;
	import com.moviemasher.events.*;
	import com.moviemasher.type.*;
	import com.moviemasher.constant.*;
	import com.moviemasher.interfaces.*;
/**
* Implementation class for stage manager
*
* @see MoviemasherStage
* @see MovieMasher
*/
	public class StageManager extends Sprite
	{
		public function StageManager()
		{
			__tooltipContainer = new Sprite();
			__cursorContainer = new Sprite();
			__cursorContainer.mouseEnabled = false;
			__cursorContainer.mouseChildren = false;
			__tooltipContainer.mouseEnabled = false;
			__tooltipContainer.mouseChildren = false;
			__parameters = new Object();
			__parameters.config = '';
			__parameters.base = '';
			__parameters.policy = '';
			__parameters.debug = '';
			__parameters.appletbase = '';
			
		}
		
		public function setManagers(iLoadManager:LoadManager = null):void
		{
			__loadManager = iLoadManager;
			var tf:TextFormat;
			var url:String;
			var policy:String;
			var k:*;
			RunClass.MovieMasher['setByID']('parameters', __parameters);
			if (RunClass.MovieMasher['instance'].loaderInfo != null) 
			{
				for (k in loaderInfo.parameters)
				{
					__parameters[k] = loaderInfo.parameters[k];
				}
			}
			if (__parameters.base.length && (__parameters.base.substr(-1) != '/')) 
			{
				__parameters.base += '/';
			}
			if (__parameters.debug == '0') __parameters.debug = '';
			
			// we interpret it as a url if it contains a slash
			__debugging = (__parameters.debug.length && (__parameters.debug.substr(0, 4) != 'http'));
			__msg_mc = new TextField();
			__msg_mc.wordWrap = true;
			__msg_mc.multiline = true;
						
			tf = __msg_mc.getTextFormat();
			tf.font = '_typewriter';
			__msg_mc.defaultTextFormat = tf;
			parent.addChildAt(__msg_mc, 0);
			if (stage != null)
			{
				// override these parameters if set in the HTML
				stage.align = StageAlign.TOP_LEFT;
				stage.scaleMode = StageScaleMode.NO_SCALE;
				stage.showDefaultContextMenu = false;
				stage.addEventListener(Event.RESIZE, __resizedStage);
				stage.stageFocusRect = false;
				__resizedStage(null);
			}
			else 
			{
				__size.width = 640;
				__size.height = 480;
				__resize();
			}
			if (RunClass.MovieMasher['instance'].loaderInfo != null) 
			{
				url = RunClass.MovieMasher['instance'].loaderInfo.url;
				if (url != null)
				{
					url = url.substr(0, - ("core/MovieMasher/stable.swf".length));
					__parameters.appletbase = url;
				}
			}
			policy = getParameter('policy');
			if (policy.length) __loadManager.addPolicy(policy);
		}
		public function getParameter(property:String):String
		{
			var s:String = '';
			if (__parameters[property] != null)
			{
				s = __parameters[property];
			}
			return s;
		}
		public function setParameter(property:String, value:String):void
		{
			__parameters[property] = value;
			if (property == 'debug') __debugging = (__parameters.debug.length && (__parameters.debug != '0') && (__parameters.debug.substr(0, 4) != 'http'));
		}
		public function msg(s:*, type:* = null):void
		{
			
			if (type == null) type = 'debug';
			else if (type is Error)
			{
				s = s + ' ';
				if (type.getStackTrace()) s += type.getStackTrace();
				else s += type;
				type = EventType.ERROR;
			}
			//trace(String(s));
			if (__debugging)
			{
				__msg_mc.text =__msg_mc.text + "\n"  + type.toUpperCase() + ': ' + String(s);
				
			}
			else if (__parameters.debug.length)
			{
				// it's a url, post error to it
				var url:String = __parameters.debug;//'http://127.0.0.1:5701/problem/index.php';//
				
				if (url.indexOf('?') == -1) url += '?';
				else url += '&';
				url += 'r=' + IDUtility.generate();
				
				__loadManager.dataFetcher(url, type.toUpperCase() + ': ' + String(s));
			}
		}
		public function get tooltipOwner():IControl
		{
			return __tooltipOwner;
		}
		public function setTooltip(tooltip:ITooltip, owner:IControl):void
		{
			//msg('MovieMasher.setTooltip ' + tooltip + ' ' + owner);
			if (tooltip == null) owner = null;
			
			if (__tooltip != null)
			{
				__tooltipContainer.removeChild(__tooltip.displayObject);
			}
			
			__tooltip = tooltip;
			__tooltipOwner = owner;
			if (__tooltip != null)
			{
				__tooltipContainer.addChildAt(__tooltip.displayObject, 0);
				stage.addEventListener(MouseEvent.MOUSE_MOVE, __mouseMoveTooltip);
				RunClass.MovieMasher['instance'].addChild(__tooltipContainer);
			
				__mouseMoveTooltip(null);
			}
		}
		public function setCursor(bm : DisplayObject = null, offset:Point = null):void
		{
			
			if (__cursor != bm)
			{
				if (__cursor != null)
				{
					__cursorContainer.removeChild(__cursor);
				}
				__cursor = bm;
				if (__cursor != null)
				{
					__cursorContainer.addChild(__cursor);
					__cursor.x = - ((__cursor.width / 2) - offset.x)
					__cursor.y = - ((__cursor.height / 2) - offset.y)
					__mouseMoveCursor(null);
				}
				var mouse_should_be_hidden:Boolean = (__cursor != null);
				if (__mouseHidden != mouse_should_be_hidden)
				{
					__mouseHidden = mouse_should_be_hidden;
					if (__mouseHidden) 
					{
						RunClass.MovieMasher['instance'].addChild(__cursorContainer);
						stage.addEventListener(MouseEvent.MOUSE_MOVE, __mouseMoveCursor);
						Mouse.hide();
					}
					else 
					{
						RunClass.MovieMasher['instance'].removeChild(__cursorContainer);
						stage.removeEventListener(MouseEvent.MOUSE_MOVE, __mouseMoveCursor);
						Mouse.cursor = MouseCursor.AUTO;
						Mouse.show();						
					}
				}
			}
			
		}
		public function get size():Size
		{
			return __size;
		}
		public function set size(s:Size):void
		{
			__size = s;
			__resize();
		}
		private function __resize():void
		{
			__msg_mc.width = __size.width;
			__msg_mc.height = __size.height;
			dispatchEvent(new Event(Event.RESIZE));
		}
		private function __resizedStage(event:Event):void
		{
			try
			{
				__size = new Size(stage.stageWidth, stage.stageHeight);
				__resize();
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this, e);
			}

		}
		private function __mouseMoveCursor(event:MouseEvent):void
		{
			try
			{
				__cursorContainer.x = RunClass.MovieMasher['instance'].mouseX;
				__cursorContainer.y = RunClass.MovieMasher['instance'].mouseY;
				if (event != null)
				{
					event.updateAfterEvent();
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this, e);
			}
		}
		private function __mouseMoveTooltip(event:MouseEvent):void
		{
			try
			{
				var x_pos:Number = ((event == null) ? stage.mouseX : event.stageX);
				var y_pos:Number = ((event == null) ? stage.mouseY : event.stageY);
				__tooltipContainer.x = x_pos;
				__tooltipContainer.y = y_pos;
				
				var dont_delete:Boolean = false;
				if (__tooltip != null)
				{
					dont_delete = __tooltipOwner.displayObject.hitTestPoint(x_pos, y_pos);
					if (dont_delete)
					{
						__tooltip.point = new Point(x_pos, y_pos);
						dont_delete = __tooltipOwner.updateTooltip(__tooltip);
					}
					
					if (! dont_delete)
					{
						__tooltipContainer.removeChild(__tooltip.displayObject);
						stage.removeEventListener(MouseEvent.MOUSE_MOVE, __mouseMoveTooltip);
						RunClass.MovieMasher['instance'].removeChild(__tooltipContainer);
						__tooltip = null;
						__tooltipOwner = null;
					}
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__mouseMoveTooltip ' + __tooltip + ' ' + __tooltipOwner, e);
			}
		}
		public static var sharedInstance:StageManager; // access by MovieMasher
		private var __cursor : DisplayObject;
		private var __mouseHidden:Boolean = false;
		private var __cursorContainer : Sprite;
		private var __debugging:Boolean;
		private var __loadManager:LoadManager;
		private var __msg_mc:TextField;
		private var __parameters:Object;
		private var __size:Size = new Size();
		private var __tooltip:ITooltip;
		private var __tooltipContainer : Sprite;
		private var __tooltipOwner:IControl;
	}
}

