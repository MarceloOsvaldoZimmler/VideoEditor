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
package com.moviemasher.module
{
	import com.moviemasher.type.*;
	import com.moviemasher.constant.*;
	import com.moviemasher.utils.*;;
	import com.moviemasher.type.*;
	import com.moviemasher.constant.*;
	import com.moviemasher.interfaces.*;
	import flash.display.*;
	import flash.net.*;
	import flash.events.*;
/**
* Implementation class for picturebox composite effect module
*
* @see IModule
* @see Clip
* @see Mash
*/
	public class Picturebox extends Composite
	{
		public function Picturebox()
		{
			_defaults.href = '';
			_defaults.alpha = '100';
			_defaults.alphafade = '0';
			_defaults.backalpha = '0';
			_defaults.backcolor = 'FFFFFF';
			
			_defaults.scale = '50,50';
			_defaults.position = '50,50';
			__back_mc = new Sprite();
			addChildAt(__back_mc, 0);
			__mask_mc = new Sprite();
			addChild(__mask_mc);
			_displayObjectContainer.mask = __mask_mc;
		}
		override protected function _setCompositedSize():void
		{
				
			try
			{
				if (__composited != null)
				{
					var cur_size:Size = metrics;
					
					var position:Array = _getClipProperty(ModuleProperty.POSITION).split(',');
					var scale:Array = _getClipProperty(ModuleProperty.SCALE).split(',');
					scale[0] = Number(scale[0]);
					scale[1] = Math.abs(Number(scale[1]));
					scale[0] = (scale[0] * cur_size.width) /100;
					scale[1] = (scale[1] * cur_size.height) /100;
					_backWidth = scale[0];
					_backHeight = scale[1];
				
					__composited.metrics = new Size(scale[0], scale[1]);
				
					_setCompositedFrame();
				
					position[0] = Number(position[0]);
					position[1] = Math.abs(Number(position[1]) + (_getClipPropertyNumber('verticalinvert') ? 0 : -100));
					var backcolor:String = _getClipProperty(ModuleProperty.BACKCOLOR);
					var backalpha:Number = _getClipPropertyNumber('backalpha');
					var has_back:Boolean = (backalpha && ((backcolor != null) && backcolor.length));
					var minORmax:String = (has_back ? 'max' : 'min');
					var w:Number = Math[minORmax](_displayObjectContainer.width, _backWidth);
					var h:Number = Math[minORmax](_displayObjectContainer.height, _backHeight);
					position[0] = ((position[0] * (cur_size.width - w)) /100) - (cur_size.width / 2);
					position[1] = ((position[1] * (cur_size.height - h)) /100) - (cur_size.height / 2);
					
				
					__mask_mc.x = __back_mc.x = position[0];
					__mask_mc.y = __back_mc.y = position[1];
					__composited.displayObject.x = Math.round((w / 2) + position[0]) + (has_back ? Math.round((_backWidth - w) / 2) : 0);
					__composited.displayObject.y = Math.round((h / 2) + position[1]) + (has_back ? Math.round((_backHeight - h) / 2) : 0);
				
					var can_be_clicked:Boolean = Boolean(_getClipProperty('href').length);
					if (_clickable != can_be_clicked)
					{
						_clickable = can_be_clicked;
						__mask_mc.buttonMode = _clickable;
						__mask_mc[(_clickable ? 'add' : 'remove') + 'EventListener'](MouseEvent.CLICK, _clicked);
					}
					
					_backSize();
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '._setCompositedSize', e);
			}
		}
		
		protected var _backWidth:Number;
		protected var _backHeight:Number;
		protected var __back_mc:Sprite;
		protected var __mask_mc:Sprite;
		protected var _clickable:Boolean = false;
		protected function _backSize():void
		{
			try
			{
				var per:Number = _getFade() / 100;
				var per_alpha : Number = _getClipPropertyNumber('alpha');
				if (per != 1) 
				{
					per_alpha = RunClass.PlotUtility['perValue'](per, per_alpha, _getClipPropertyNumber('alphafade'));
				}
				else per_alpha /= 100;
				
				
				_displayObjectContainer.alpha = per_alpha;
				__back_mc.graphics.clear();
				var backcolor:String = _getClipProperty(ModuleProperty.BACKCOLOR);
				if ((backcolor != null) && backcolor.length)
				{
					var backalpha:Number = _getClipPropertyNumber('backalpha');
					if (backalpha)
					{
						backalpha *= per_alpha;
						RunClass.DrawUtility['fill'](__back_mc.graphics, _backWidth, _backHeight, RunClass.DrawUtility['colorFromHex'](backcolor), backalpha);
					}
				}
				__mask_mc.graphics.clear();
				
				RunClass.DrawUtility['fill'](__mask_mc.graphics, _backWidth, _backHeight, 0x00000);
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this, e);
			}

		}
		protected function _clicked(event:MouseEvent):void
		{
			var href:String = _getClipProperty('href');
			if (href.length) navigateToURL(new URLRequest(href));
		}
	}
}

