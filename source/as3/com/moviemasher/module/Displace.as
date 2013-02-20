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
	import com.moviemasher.interfaces.*;
	import com.moviemasher.type.*;
	import com.moviemasher.constant.*;
	import com.moviemasher.utils.*;
	import flash.display.*;
	import flash.filters.*;
	import flash.geom.*;
/**
* Implementation class for displace composite effect module
*
* @see IModule
* @see Clip
* @see Mash
*/
	public class Displace extends Composite
	{
		public function Displace()
		{ 
			super();
			_defaults.scale = '5,5';		
			_defaults.channelx = 'red';
			_defaults.channely = 'red';
			_defaults.mode = 'wrap';
			
			__greyFilter = new ColorMatrixFilter([
				.3,	0.59,	0.11,	0,	0,
        		.3,	0.59,	0.11,	0,	0,
        		.3,	0.59,	0.11,	0,	0,
        		0,	0.0,	0.0,	1,	0
        	]);
        	__bottomGrad = new Object();
			__bottomGrad.alphas = new Array();
			__bottomGrad.alphas.push(0);
			__bottomGrad.alphas.push(255);
			__bottomGrad.ratios = __bottomGrad.alphas.concat();
			__bottomGrad.colors = new Array();
			__bottomGrad.colors.push(0x808080);
			__bottomGrad.colors.push(0x808080);
			
			
  		}
		override public function get displayObject():DisplayObjectContainer
		{
			return null;
		}
 		override public function unload():void
 		{
 			if (__bitmapData != null)
 			{
 				__bitmapData.dispose();
 				__bitmapData = null;
 			}
 			if (__borderShape != null)
			{
				if (__borderShape.parent != null)
				{
					__borderShape.parent.removeChild(__borderShape);
					__borderShape = null;
				}
 			}
  			
			super.unload();
 		}
		override protected function _setCompositedSize():void
		{ 
			var new_filters:Array = new Array();
			
			if (__composited != null)
			{
				var scale:Array = RunClass.PlotUtility['string2Plot'](_getClipProperty(ModuleProperty.SCALE));
				scale[0] = Math.round((scale[0] * _size.width) / 100.0);
				scale[1] = Math.round((scale[1] * _size.height) / 100.0);
				
				if (__bitmapData != null)
				{
 					__bitmapData.dispose();
 					__bitmapData = null;
				}
				if (__borderShape == null)
				{
					__borderShape = new Shape();
					__borderShape.x = - _size.width / 2;
					__borderShape.y = - _size.height / 2;
				}
				
				__borderShape.graphics.clear();
				
				__bottomGrad.angle = 90;
				RunClass.DrawUtility['fillBoxGrad'](__borderShape.graphics, 0, _size.height - scale[1], _size.width, scale[1], __bottomGrad);
				__bottomGrad.angle = 270;
				RunClass.DrawUtility['fillBoxGrad'](__borderShape.graphics, 0, 0, _size.width, scale[1], __bottomGrad);
				
				if (! _displayObjectContainer.contains(__borderShape)) _displayObjectContainer.addChild(__borderShape);

				__bottomGrad.angle = 0;
				RunClass.DrawUtility['fillBoxGrad'](__borderShape.graphics, _size.width - scale[0], 0, scale[0], _size.height, __bottomGrad);
				__bottomGrad.angle = 180;
				RunClass.DrawUtility['fillBoxGrad'](__borderShape.graphics, 0, 0, scale[0], _size.height, __bottomGrad);
				
				var backcolor:String = __composited.backColor;//__module.getValue(ModuleProperty.BACKCOLOR).string;
				//RunClass.MovieMasher['msg'](this + '._setCompositedSize ' + backcolor);
				if (! backcolor.length) backcolor = '808080';
				var color:Number = RunClass.DrawUtility['colorFromHex'](backcolor, 'FF');
				
				__bitmapData = new BitmapData(_size.width, _size.height, false, color);
			
				__composited.metrics = _size;
				
				_setCompositedFrame();
				
				var m:Matrix = new Matrix();
				m.translate(_size.width / 2, _size.height / 2);
				_displayObjectContainer.visible = true;
				// TODO: should filters be applied to my container instead???
				__composited.displayObject.filters = [__greyFilter];
				__bitmapData.draw(_displayObjectContainer, m);
			
				_displayObjectContainer.visible = false;
				__composited.displayObject.filters = [];
				
				 if (_displayObjectContainer.contains(__borderShape)) _displayObjectContainer.removeChild(__borderShape);
				
				
				var mode:String = _getClipProperty('mode').toUpperCase();
				mode = DisplacementMapFilterMode[mode];
				
				var channelx:String = _getClipProperty('channelx').toUpperCase();
				var channely:String = _getClipProperty('channely').toUpperCase();
				var channelx_int:int = BitmapDataChannel[channelx];
				var channely_int:int = BitmapDataChannel[channely];
				
				
				/*
				if (__bitmap == null)
				{
					__bitmap = new Bitmap();
				}
				if (! contains(__bitmap)) addChild(__bitmap);
				__bitmap.bitmapData = __bitmapData;
				__bitmap.x = -_size.width / 2;
				__bitmap.y = -_size.height / 2;
				*/
				new_filters.push(new DisplacementMapFilter(__bitmapData, null, channelx_int, channely_int, scale[0], scale[1], mode));
			}
			
			_moduleFilters = new_filters;

		}
		private var __bitmap:Bitmap;
		private var __bottomGrad:Object;
		private var __borderShape:Shape;
		private var __bitmapData:BitmapData;
		private var __greyFilter:ColorMatrixFilter;
	}
}