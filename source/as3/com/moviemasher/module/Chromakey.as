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
	import com.moviemasher.interfaces.*;
	import com.moviemasher.events.*;
	import com.moviemasher.type.*;
	import com.moviemasher.constant.*;
	import com.moviemasher.utils.*;
	import com.quasimondo.geom.*;
	import flash.display.*;
	import flash.events.*;
	import flash.filters.*;
	import flash.geom.*;
/**
* Implementation class for chroma key composite effect module
* 
* Attributes supported by this module are 'forecolor', 'keyin', 'keyout', 'keygamma', 
* 'preblur', 'postblur', 'defringedarken', 'defringe', and 'defringeradius'.
* Refactored from Mario Klingemann's excellent example, freely available on his blog:
* http://www.quasimondo.com/archives/000615.php
* 
* @see IModule
* @see Clip
* @see Mash
*/
	public class Chromakey extends Composite
	{
		public function Chromakey()
		{ 
			super();
			
			_defaults.forecolor = '009966';
			_defaults.keyin = 30; // 0 to 256
			_defaults.keyout = 50; // 0 to 256
			_defaults.keygamma = 100; // 1 to 400
			_defaults.preblur = 10; // 0 to 100
			_defaults.postblur = 0; // 0 to 160
			_defaults.defringedarken = 0; // 0 or 1
			_defaults.defringe = 20; // 0 to 300
			_defaults.defringeradius = 200; // 0 to 1000
			
			__alphaArray = new Array();
			__nullArray = new Array();
			
			for (var i=0;i<256;i++){
				__nullArray[i] = 0x00000000;
			}
			__container = new Sprite();
			addChild(__container);
	
		}
		override public function unload():void
		{
			try
			{
				__removeBitmap();
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.unload', e);
			}
			super.unload();
		}
		override protected function _changedSize():void
		{
			try
			{
				if ((_size != null) && _size.width && _size.height)
				{
					__removeBitmap();
					__bitmap = new Bitmap();
					__container.addChild(__bitmap);
					//RunClass.MovieMasher['msg'](this + '._changedSize ');
					__maskBitmapData = new BitmapData( _size.width, _size.height, true, 0);
					__displayBitmapData = __maskBitmapData.clone();
					__defringeBitmapData = __maskBitmapData.clone();
					__originalBitmapData = new BitmapData(_size.width, _size.height,false,0);
					__transformBitmapData = __originalBitmapData.clone();
					__helperBitmapData = __originalBitmapData.clone();
					__bitmap.bitmapData = __displayBitmapData;				 
					__defringer = new Bitmap();
					__defringer.bitmapData = __defringeBitmapData;
					__defringer.blendMode = (Boolean(_getClipPropertyNumber('defringedarken')) ? 'add' : 'subtract');
					__container.addChild(__defringer);
					
					__bitmap.x = - Math.round(_size.width / 2);
					__bitmap.y = - Math.round(_size.height / 2);
					__defringer.x = - Math.round(_size.width / 2);
					__defringer.y = - Math.round(_size.height / 2);
					
					__changeKeyColor(RunClass.DrawUtility['colorFromHex'](_getClipProperty('forecolor')));
					//RunClass.MovieMasher['msg'](this + '._changedSize ' + __bitmap.x + ',' + __bitmap.y + ' ' + _size);
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '._changedSize', e);
			}
		}
		override protected function _clipPropertyDidChange(event:ChangeEvent):void
		{
			super._clipPropertyDidChange(event);
			try
			{
				switch (event.property)
				{
					case 'position':
					case 'scale':
					case 'composites':
						_changedSize();
						_initialize();
						var object:Object = _getClipPropertyObject(ClipProperty.MASH);
						if ((object != null) && (object is IMash))
						{
							var imash:IMash = object as IMash;
							imash.goTime(null);
						}
						break;
					case 'forecolor':
						__changeKeyColor(RunClass.DrawUtility['colorFromHex'](event.value.string));
						break;
					case 'defringedarken':
						__defringer.blendMode = (event.value.boolean ? "add" : "subtract");
						// intentional fallthrough to other defringers
					case 'defringe':
					case 'defringeradius':
						__updateDefringeGlow();
						break;
					case 'keyin':
					case 'keyout':
					case 'keygamma':
						__calculateAlphaTables();
						break;
					case 'preblur':
						__updatePreblurFilter();
						break;
					case 'postblur':
						__updatePostblurFilter();
						break;
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__changedClip', e);
			}
		}
		override protected function _initialize():void 
		{
			super._initialize();
			
			try
			{
				__calculateAlphaTables();
				__updatePreblurFilter();
				__updatePostblurFilter();
				__updateDefringeGlow();
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '._initialize', e);
			}
		}
		override protected function _setCompositedSize():void
		{ 
			try
			{
				if ((__composited != null) && (_size != null))
				{
					__composited.metrics = _size;
					
					if (__container.visible = _setCompositedFrame())
					{
						
						_displayObjectContainer.visible = true;
						
						//RunClass.MovieMasher['msg'](this + '._setCompositedSize ' + __composited.displayObject.x + ',' + __composited.displayObject.y);
						__composited.displayObject.x = _size.width / 2;
						__composited.displayObject.y = _size.height / 2;
						__render();					
						_displayObjectContainer.visible = false;
						__composited.displayObject.x = 0;
						__composited.displayObject.y = 0;
						
						if ((__bitmap != null) && (__defringer != null))
						{
							_setDisplayObjectMatrix(__container);
						}
					}
					/*
					RunClass.MovieMasher['msg'](this + '._changedSize ' + __bitmap.x + ',' + __bitmap.y);
					
					__defringer.x -= Math.round(_size.width / 2);
					__bitmap.x -= Math.round(_size.width / 2);
					__defringer.y -= Math.round(_size.height / 2);	
					 __bitmap.y -= Math.round(_size.height / 2);				
					
					*/
				
					//RunClass.MovieMasher['msg'](this + '._setCompositedSize ' + __defringer + ' ' + __bitmap);
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '._setCompositedSize', e);
			}
		}	
		private function __calculateAlphaTables():void
		{
			try
			{
				// this function creates the lookup table for the paletteMap filter
				// which makes the matte out of the color difference screen
				
				var alpha_in:Number  = Math.round( _getClipPropertyNumber('keyin') );
				var alpha_out:Number = Math.round( _getClipPropertyNumber('keyout') );
				var i:Number;
				
				for (i = 0; i < alpha_in;i++ )
				{
					__alphaArray[i] = 0;
				}
				
				var f:Number = 1 / ( alpha_out - alpha_in );
				var n:Number= f;
				
				var keygamma:Number = _getClipPropertyNumber('keygamma');
				for (i = alpha_in; i<alpha_out; i++ )
				{
					__alphaArray[i] =  Math.round(255 * Math.pow (n, 1.0 / ( keygamma / 100 )) )<<24  | 0xffffff;
					n+=f
				}
				for ( i =alpha_out; i < 256; i++ )
				{
					__alphaArray[i] = 0xffffffff;
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__calculateAlphaTables', e);
			}
		}		
		private function __changeKeyColor( c:Number):void
		{
			try
			{
				__transformBitmapData.fillRect( new Rectangle(0, 0, _size.width, _size.height), c );
				__updateDefringeGlow();
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__changeKeyColor', e);
			}
		}
		private function __createKey()
		{
			try
			{
				var preblur:Number = _getClipPropertyNumber('preblur');
				// Prebluring will reduce compression artifacts and smooth the edges
				var rect:Rectangle = new Rectangle(0, 0, _size.width, _size.height);
				
				if ( preblur > 0 )
				{
					__maskBitmapData.applyFilter( __originalBitmapData, rect, __zeroPoint, __preblurFilter );
				} 
				else 
				{
					__maskBitmapData.draw( __originalBitmapData );
				}
				
				// Subtracts the key color from the image
				__maskBitmapData.draw( __transformBitmapData, __zeroMatrix, null, "difference" );
				
				// this calculates the average color difference
				__colorMatrix.reset();
				__colorMatrix.average();
				__maskBitmapData.applyFilter( __maskBitmapData, rect, __zeroPoint, __colorMatrix.filter );
				
				// maps the accumulated difference from the blue channel to the alpha channel and creates the matte
				__maskBitmapData.paletteMap( __maskBitmapData, rect, __zeroPoint, __nullArray, __nullArray, __alphaArray, __nullArray );
				
				var postblur:Number = _getClipPropertyNumber('postblur');
				// blurs the matte edges
				if ( postblur > 0 )
				{
					__maskBitmapData.applyFilter( __maskBitmapData, rect, __zeroPoint, __postblurFilter );
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__createKey ' + __originalBitmapData + ' ' + __postblurFilter, e);
			}
		}
		private function __removeBitmap():void
		{
			try
			{
				if (__defringer != null)
				{
					__container.removeChild(__defringer);
					__defringer.bitmapData = null;
					__defringer = null;
				}
				if (__bitmap != null)
				{
					__container.removeChild(__bitmap);
					__bitmap.bitmapData = null;
					__bitmap = null;
				}
				if (__displayBitmapData != null)
				{
					__displayBitmapData.dispose();
					__displayBitmapData = null;
				}
				if (__maskBitmapData != null)
				{
					__maskBitmapData.dispose();
					__maskBitmapData = null;
				}
				if (__defringeBitmapData != null)
				{
					__defringeBitmapData.dispose();
					__defringeBitmapData = null;
				}
				if (__originalBitmapData != null)
				{
					__originalBitmapData.dispose();
					__originalBitmapData = null;
				}
				if (__transformBitmapData != null)
				{
					__transformBitmapData.dispose();
					__transformBitmapData = null;
				}
				if (__helperBitmapData != null)
				{
					__helperBitmapData.dispose();
					__helperBitmapData = null;
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__removeBitmap', e);
			}
		}
		private function __render():void
		{
			try
			{
				if (__composited != null)
				{
				
					if ((__originalBitmapData != null) && (__defringeBitmapData != null) && (_displayObjectContainer != null))
					{
						__originalBitmapData.draw(_displayObjectContainer);
						__createKey();
						// matte the graphic
						var rect:Rectangle = new Rectangle(0, 0, _size.width, _size.height);
						__displayBitmapData.copyPixels( __originalBitmapData, rect, __zeroPoint, __maskBitmapData, __zeroPoint, false );
						
						var defringe:Number = _getClipPropertyNumber('defringe');
						var defringeradius:Number = _getClipPropertyNumber('defringeradius');
						
						if ( defringe > 0 && defringeradius > 0 )
						{
							__defringeBitmapData.applyFilter( __maskBitmapData, rect, __zeroPoint, __defringeGlow);
						}
					}
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__render ' + __originalBitmapData + ' ' + __defringeBitmapData, e);
			}
		}
		private function __updateDefringeGlow():void
		{
			try
			{
				var defringeradius:Number = _getClipPropertyNumber('defringeradius');
				var defringe:Number = _getClipPropertyNumber('defringe');
				var darken:Boolean = Boolean(_getClipPropertyNumber('defringedarken'));
				var forecolor:String = _getClipProperty('forecolor');
				__defringeGlow = new GlowFilter( (darken  ? 0x000000 : 0xffffff) ^ RunClass.DrawUtility['colorFromHex'](forecolor), 1, defringeradius / 100, defringeradius / 100, defringe/100, 3, true, true );
				if (__defringer != null) __defringer.visible = ((defringe>0) && (defringeradius>0));
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__updateDefringeGlow ', e);
			}
		}
		private function __updatePreblurFilter():void
		{
			var preblur:Number = _getClipPropertyNumber('preblur');
			
			__preblurFilter = new BlurFilter( 1 + preblur / 10, 1 + preblur / 10 , 1 );
		}
		private function __updatePostblurFilter():void
		{
			try
			{
				var postblur:Number = _getClipPropertyNumber('postblur');
				__postblurFilter = new BlurFilter(1 + postblur / 10,1 + postblur / 10,1);
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__updatePostblurFilter', e);
			}
		}
		private var __container:Sprite;
		private var __alphaArray:Array;
		private var __bitmap:Bitmap; 
		private var __colorMatrix:ColorMatrix = new ColorMatrix();
		private var __defringeBitmapData:BitmapData;
		private var __defringeGlow:GlowFilter;
		private var __defringer:Bitmap;
		private var __displayBitmapData:BitmapData;
		private var __helperBitmapData:BitmapData;
		private var __maskBitmapData:BitmapData;
		private var __nullArray:Array;
		private var __originalBitmapData:BitmapData;
		private var __postblurFilter:BlurFilter;
		private var __preblurFilter:BlurFilter;
		private var __transformBitmapData:BitmapData;
		private var __zeroMatrix:Matrix = new Matrix();
		private var __zeroPoint:Point = new Point();
	}
}