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
package com.moviemasher.preview
{
	import com.moviemasher.constant.*;
	import com.moviemasher.control.*;
	import com.moviemasher.events.*;
	import com.moviemasher.interfaces.*;
	import com.moviemasher.options.*;
	import com.moviemasher.type.*;
	import com.moviemasher.utils.*;
	import flash.display.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.text.*;
/**
* Implementation class for clip preview appearing in the timeline
*
* @see Timeline
* @see IPreview
* @see IClip
* @see IModule
*/
	public class TimelinePreview extends BrowserPreview
	{
		public function TimelinePreview()
		{
		}
		override public function get backBounds():Rectangle
		{
			return __backSprite.getBounds(this);
		}
		override public function toString():String
		{
			var s:String = '[TimelinePreview';
			if (clip) s += ' ' + clip;
			s += ']';
			return s;
		}
		override public function hitTestPoint(x:Number, y:Number, shapeFlag:Boolean = false):Boolean
		{
			var boolean:Boolean = false;
			try
			{
				boolean = _mouseSprite.hitTestPoint(x, y, shapeFlag);
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.hitTestPoint', e);
			}
			return boolean;
		}
		override public function unload():void
		{
			try
			{
				if (__waveformSprite != null)
				{
					/*__waveformBitmap.mask = null;
					__waveformSprite.removeChild(__waveformMask);
					__waveformSprite.removeChild(__waveformBitmap);
					*/
					removeChild(__waveformSprite);
				}
				
				removeChild(__backSprite);
				__backSprite = null;
				
				__waveformSprite = null;
				/*
				__waveformBitmap = null;
				__waveformMask = null;
				*/
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.unload', e);
			}
			super.unload();
		}
		override protected function _displaySize():Size
		{
			var contentheight:Number = __h - (2 * (_options.getValue(ControlProperty.PADDING).number + _options.getValue('border').number));	
			var size:Size = new Size(Math.round(contentheight * _options.getValue('ratio').number), contentheight);
			_iconWidth = size.width;
			_iconHeight = size.height;
			return size;			
		}
		override protected function _drawBack():void
		{
			var c:Object;
			var is_selected:Boolean = _selected;
			var backwidth:Number = __w - (_data['starttrans'] + _data['endtrans']);
			var audio_height:Number;
			var back_alpha:Number = _options.getValue('alpha').number;
			
			var points : Array;
			var border:Number = _options.getValue('border').number;
			var bordercolor:Number;
			var spacing:Number;
			
			try
			{
				__backSprite.graphics.clear();
				_mouseSprite.graphics.clear();
				_maskSprite.graphics.clear();				
				
				
				if (border > 0)
				{
					bordercolor = RunClass.DrawUtility['colorFromHex'](_options.getValue((is_selected ? 'over' : '') + 'bordercolor').string);
				}
				var curve:Number = _options.getValue('curve').number;
				
				points = RunClass.DrawUtility['points'](0, 0, backwidth, __h, curve);
				c = __backColor(is_selected,  _options.getValue(CommonWords.TYPE).string);
				if (border > 0)
				{
					
					RunClass.DrawUtility['setFill'](__backSprite.graphics, bordercolor, back_alpha);
					RunClass.DrawUtility['drawPoints'](__backSprite.graphics, points);
					points = RunClass.DrawUtility['points'](border, border, backwidth - (2 * border), __h - (2 * border), curve);
				}
				
			
				RunClass.DrawUtility['setFill'](_mouseSprite.graphics, 0, 0);
				if (c.colorDefined)
				{
					if (c.flatColor != null)
					{
						RunClass.DrawUtility['setFill'](__backSprite.graphics, c.flatColor, back_alpha);
					}
					else
					{
						RunClass.DrawUtility['setFillGrad'](__backSprite.graphics, c, back_alpha);
					}
					RunClass.DrawUtility['drawPoints'](__backSprite.graphics, points);
				}
				
				
				
				RunClass.DrawUtility['drawPoints'](_mouseSprite.graphics, points);
				audio_height = _options.getValue('audioheight').number;
				if (audio_height && _data[ClipProperty.HASAUDIO] && (! _options.getValue(CommonWords.TYPE).equals(ClipType.AUDIO)))
				{
					spacing = _options.getValue(ControlProperty.SPACING).number;
					points = RunClass.DrawUtility['points'](0, __h + spacing, backwidth, audio_height, curve);
					c = __backColor(is_selected, ClipType.AUDIO);
					RunClass.DrawUtility['setFill'](_mouseSprite.graphics, 0, 0);
					
					if (border > 0)
					{
						RunClass.DrawUtility['setFill'](__backSprite.graphics, bordercolor, back_alpha);
				
						RunClass.DrawUtility['drawPoints'](__backSprite.graphics, points);
						points = RunClass.DrawUtility['points'](border, __h + spacing + border, backwidth - (2 * border), audio_height - (2 * border), curve);
					
					}
					if (c.colorDefined)
					{
						if (c.flatColor != null)
						{
							RunClass.DrawUtility['setFill'](__backSprite.graphics, c.flatColor, back_alpha);
						}
						else
						{
							c.y = __h;
							c.height = audio_height;
							RunClass.DrawUtility['setFillGrad'](__backSprite.graphics, c, back_alpha);
						}
						RunClass.DrawUtility['drawPoints'](__backSprite.graphics, points);
					}
					RunClass.DrawUtility['drawPoints'](_mouseSprite.graphics, points);
				}
				/*
				if (__waveformMask != null)
				{
					__waveformMask.graphics.clear();
					if (backwidth >= 1)
					{
						var leftcrop:Number = _data['leftcrop'];
						var rightcrop:Number = _data['rightcrop'];
						var data_width:Number = _data['width'];
						var widthcrop:Number = data_width - (leftcrop + rightcrop);
				
						
						points = RunClass.DrawUtility['points'](0, 0, widthcrop, __h, curve);
						RunClass.DrawUtility['setFill'](__waveformMask.graphics, 0xFFFF00);
						RunClass.DrawUtility['drawPoints'](__waveformMask.graphics, points);
					}
				}
				*/
				backwidth -= (2 * border);
				if (backwidth >= 1)
				{
					
					points = RunClass.DrawUtility['points'](0, 0, backwidth, __h - (2 * border), curve);
					RunClass.DrawUtility['setFill'](_maskSprite.graphics, 0xFFFF00);
					RunClass.DrawUtility['drawPoints'](_maskSprite.graphics, points);
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '._drawBack', e);
			}	
		}
		override protected function _drawPreview() : Boolean 
		{
			var url:String;
			var called_resize:Boolean = true;
			try
			{
				if ((! _options.getValue(CommonWords.TYPE).equals(ClipType.AUDIO)) && _maskSprite.width)
				{
					called_resize = super._drawPreview();
				}
				if (_maskSprite.width && (! RunClass.MouseUtility['dragging']))
				{
					__drawWaveform();
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '._drawPreview', e);
			}
			return called_resize;
		}
		override protected function _initialize():void
		{
			super._initialize();
			if (__backSprite == null)
			{
				__backSprite = new Sprite();
				addChildAt(__backSprite, 0);
			}
			__createWaveform();
		}
		override protected function _resize() : void
		{ 
			y = _data['y'];
			x = _data['x'];
			__w = _data['width'];
			__h = _options.getValue( _options.getValue(CommonWords.TYPE).string + 'height').number;
			
			var starttrans:Number = _data['starttrans'];
			var border:Number = _options.getValue('border').number;
			
			__backSprite.x = _mouseSprite.x = starttrans;
			
			
			_maskSprite.x = starttrans + border;
			_maskSprite.y = _displayObjectContainer.y = border;
			_displayObjectContainer.x = Math.max(_maskSprite.x, _data['leftcrop']);
		
					
			var ratio:Number = _options.getValue('ratio').number;
				
			_iconHeight = __h - (2 * border);
			if (ratio)
			{
				_iconWidth = _iconHeight * ratio;
			}
			_drawBack();
			if (RunClass.MouseUtility['dragging']) 
			{
				__drawWaveform();
			}
			if (_maskSprite.width)
			{
				_labelField.text = _data[MediaProperty.LABEL];
				_resizeLabel();
				_drawPreview();
			}
			_labelField.x = _labelSprite.x = _displayObjectContainer.x;
			
		}
			
		private function __adjustWaveform()
		{
			try
			{
				if ((_data != null) && (_options != null) && (__waveformSprite != null) && (__waveformDisplayObject != null))
				{
					var spacing:Number = _options.getValue(ControlProperty.SPACING).number;
					var bm : BitmapData;
					var y_pos:Number = 0;
					var n:Number
					n = _options.getValue('effectheight').number;
					y_pos += n;
					if (n) y_pos += spacing;
					n = _options.getValue('videoheight').number;
					y_pos += n;
					if (n) y_pos += spacing;
					
					
					
					__waveformSprite.y = y_pos;
			
					var audioheight:Number = _options.getValue('audioheight').number;
					
					
					var leftcrop:Number = _data['leftcrop'];
					var rightcrop:Number = _data['rightcrop'];
					var data_width:Number = _data['width'];
					var widthcrop:Number = data_width - (leftcrop + rightcrop);
					var media_pixels:Number = _data['durationpixels'];
					if (! isNaN(media_pixels))
					{
						__waveformSprite.x = leftcrop;
						bm = new BitmapData(Math.min(2880, media_pixels), audioheight, true, 0x00FF0000);
						if (bm)
						{
							var matrix:Matrix = new Matrix();
							var translation:Number = 0;
							var item_start:int = _data[ClipProperty.STARTFRAME];
							var type:String =  _options.getValue(CommonWords.TYPE).string;
							matrix.scale(media_pixels / __waveWidth, audioheight / __waveHeight);
	
							// remove trimming
							if (_data[ClipProperty.TRIMSTART]) translation -= _data[ClipProperty.TRIMSTART];
							
							// remove cropping
							translation -= leftcrop;
							
							matrix.translate(translation, 0);
							var ct:ColorTransform = new ColorTransform();
							bm.draw(__waveformDisplayObject, matrix, ct, 'normal', null, true);
							
							__waveformSprite.graphics.clear();
							__waveformSprite.graphics.beginBitmapFill(bm);
							__waveformSprite.graphics.drawRect(0, 0, widthcrop, audioheight);
							__waveformSprite.graphics.endFill();
						}
					}
					else RunClass.MovieMasher['msg'](this + '.__adjustWaveform invalid durationpixels');
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__adjustWaveform ' + media_pixels + ' ' + audioheight, e);
			}
		}
		private function __backColor(selected : Boolean, type: String):Object
		{
			var ob:Object = new Object();
			try
			{
					
				var over:String = (selected ? 'over' : '');
				var color:String = _options.getValue(over + 'color').string;
				ob.colorDefined = (color.length > 0);
				if (ob.colorDefined)
				{
					var grad:Number = _options.getValue(over + 'grad').number;
					var color_number:Number = RunClass.DrawUtility['colorFromHex'](color);
					if (grad > 0)
					{
						ob = RunClass.DrawUtility['gradientFill'](__w, __h, color_number, grad, _options.getValue(over + 'angle').number);
						ob.colorDefined = true;
					}
					else 
					{
						ob.flatColor = color_number;
					}
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__backColor', e);
			}
			return ob;
		}
		private function __createWaveform():void
		{
			if (_options.getValue('audioheight').boolean && (__waveformSprite == null))
			{
				__waveformSprite = new Sprite();
				addChildAt(__waveformSprite, 1);
				__waveformSprite.blendMode = BlendMode[_options.getValue((_options.getValue(CommonWords.TYPE).equals(ClipType.AUDIO) ? '' : 'wave') + 'blend').string.toUpperCase()];
				/*
				__waveformBitmap = new Bitmap();
				__waveformSprite.addChild(__waveformBitmap);
				__waveformMask = new Sprite();
				__waveformSprite.addChild(__waveformMask);
				__waveformBitmap.mask = __waveformMask;
				*/
			}
		}
		private function __drawWaveform():Boolean
		{
			var had_a_prob:Boolean = false;
			try
			{
				if (__waveformSprite != null)
				{
					__waveformSprite.visible = _data[ClipProperty.HASAUDIO];
					if (__waveformSprite.visible)
					{
						if (! (__waveWidth && __waveHeight))
						{
							var value:Value = _options.getValue('wave');
							//RunClass.MovieMasher['msg'](this + '.__drawWaveform value = ' + value);
							if (value.object is DisplayObject) 
							{
								__waveformDisplayObject = value.object as DisplayObject;
								__waveWidth = __waveformDisplayObject.width;
								__waveHeight = __waveformDisplayObject.height;
								//RunClass.MovieMasher['msg']('GOT waveform object ' + __waveWidth + 'x' + __waveHeight);
								
							}
							else if (value.object is String) 
							{
								var wave:String = value.string;
								if (wave.length)
								{
									__waveLoader = RunClass.MovieMasher['assetFetcher'](wave);
									if (__waveLoader.state == EventType.LOADING)
									{
										__waveLoader.addEventListener(Event.COMPLETE, __waveformLoaded, false, 0, true);
									}
									else
									{
										__waveformLoaded(null);
									}
								}
							}
						}
						if (__waveWidth && __waveHeight) __adjustWaveform();
						else 
						{
							//__waveformSprite.visible = false;
							had_a_prob = true;
						}
					}
					
				}
			
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__drawWaveform', e);
			}
			return had_a_prob;
		}
		private function __waveformLoaded(event:Event):void
		{
			try
			{
				if ((__waveLoader != null) && (_options != null))
				{
					__waveformDisplayObject = __waveLoader.displayObject(_options.getValue('wave').string);
					if (__waveformDisplayObject != null)
					{
						__waveWidth = __waveformDisplayObject.width;
						__waveHeight = __waveformDisplayObject.height;
						__adjustWaveform();
					}
					
					if (event != null)
					{
						__waveLoader.removeEventListener(Event.COMPLETE, __waveformLoaded);
					}
					__waveLoader = null;
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__waveformLoaded ' + __waveLoader + ' ' + _options + ' ' + __waveformDisplayObject, e);
			}
			
		}
		private var __backSprite : Sprite; // background for whole clip (will be rounded edge if possible)
		private var __h : Number = 0;
		private var __w : Number = 0;
		private var __waveformSprite : Sprite; 
		private var __waveformDisplayObject:DisplayObject;
		private var __waveHeight : Number = 0;
		private var __waveLoader:IAssetFetcher;
		private var __waveWidth : Number = 0;
	}
}