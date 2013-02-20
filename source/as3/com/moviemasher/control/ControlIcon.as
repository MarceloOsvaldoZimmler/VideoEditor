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
	import com.moviemasher.display.*;
	import com.moviemasher.events.*;
	import com.moviemasher.interfaces.*;
	import com.moviemasher.type.*;
	import com.moviemasher.constant.*;
	import com.moviemasher.utils.*;
	import flash.display.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.utils.*;
/**
* Abstract base class represents a simple button control
*/
	public class ControlIcon extends Control
	{
		public function ControlIcon()
		{
			_defaults.angle = '90';
			_defaults.border = '0';
			_defaults.bordercolor = '000000';
			_defaults.grad = '0';
			_ratioKey = 'icon';
		}
		override protected function _createChildren():void
		{
			try
			{
				_displayObjectLoad('icon');
				_displayObjectLoad('overicon');
				_displayObjectLoad('disicon');
				super._createChildren();
				addEventListener(MouseEvent.MOUSE_DOWN, __mouseDown);
				_createTooltip();
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this, e);
			}
		}
		override public function resize():void
		{
			
			_sizeIcons();
			super.resize();
		}
		public function select():void
		{
			_release();
		}
		override public function setValue(value:Value, property:String):Boolean
		{
			var tf:Boolean = false;
			
			if (property == 'click')
			{
				if (! _disabled)
				{
					tf = true;
					select();
				}
			}
			else tf = super.setValue(value, property);
			return tf;
		}
		override protected function _update():void
		{
			var mc:DisplayObject;
			mc = _displayedObjects['disicon'];
			if ((mc != null) && (mc.visible != _disabled))
			{
				mc.visible = _disabled;
				if (mc is MovieClip) (mc as MovieClip).gotoAndPlay(1);
			}
			var tf:Boolean = false;
			if (! _disabled)
			{
				tf = hitTestPoint(RunClass.MovieMasher['instance'].mouseX, RunClass.MovieMasher['instance'].mouseY);
				if (_selected) tf = ! tf;
			}
			_roll(tf);
		}
		protected function _sizeIcons():Boolean
		{
			var did_size:Boolean = false;

			var i_size:Size = null;
			if (getValue(MediaProperty.FILL).equals(FillType.STRETCH)) 
			{
				i_size = new Size(_width, _height);
			}
			if (_displayObjectSize('icon', i_size)) did_size = true;
			if (_displayObjectSize('overicon', i_size)) did_size = true;
			if (_displayObjectSize('disicon', i_size)) did_size = true;
			return did_size;
		}
		override protected function _mouseOut():void
		{			
			try
			{
				_roll(_selected);
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '._mouseOut (ControlIcon)', e);
			}
		}
		override protected function _mouseOver(event:MouseEvent):void // only sent when enabled
		{ 
			try
			{
				_roll(! _selected); 
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this, e);
			}
		}
		protected function __mouseDown(event:MouseEvent)
		{
			try
			{
				RunClass.MovieMasher['instance'].stage.focus = null;
				if (! _disabled)
				{
					_rollTimerCancel();
					RunClass.MouseUtility['drag'](this, event, __mouseDrag, __mouseUp);
					_press(event);
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this, e);
			}
		}
		protected function _press(event:MouseEvent):void
		{}
		protected function _roll(tf : Boolean, prefix : String = ''):void
		{
			try
			{
				var state:String = '';
				
				var overicon:DisplayObject = _displayedObjects[prefix + 'overicon'];
				var icon:DisplayObject = _displayedObjects[prefix + 'icon'];
				if (_disabled)
				{
					state = 'dis';
					if (icon != null) icon.visible = false;
					if (overicon != null) overicon.visible = false;
				}
				else
				{
					if (tf) state = 'over';
					
					if (overicon == null) tf = false;
					else if (overicon.visible != tf)
					{
						overicon.visible = tf;			
						if (tf && (overicon is MovieClip)) (overicon as MovieClip).gotoAndPlay(1);
					}
					if ((icon != null) && (icon.visible == tf))
					{
						icon.visible = ! tf;
						if (icon is MovieClip) (icon as MovieClip).gotoAndPlay(1);
					}
					
				}
				_drawBox(state);
				
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this, e);
			}
		}
		private function __mouseDrag():void
		{
			try
			{
				
				_mouseDrag();
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this, e);
			}
		}
		private function __mouseUp():void
		{
			try
			{
				if (! hitTestPoint(RunClass.MovieMasher['instance'].mouseX, RunClass.MovieMasher['instance'].mouseY))
				{
					_mouseOut();
					dispatchPropertyChange();
				}
				else 
				{
					_roll(! _selected);
					_release();
				}
				
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this, e);
			}
		}
	}
}