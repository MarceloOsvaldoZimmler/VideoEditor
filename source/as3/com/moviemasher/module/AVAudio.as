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
	import com.moviemasher.events.*;
	import com.moviemasher.interfaces.*;
	import com.moviemasher.type.*;
	import com.moviemasher.constant.*;
	import flash.display.*;
	import flash.events.*;

/**
* Implementation class for audio module
*
* @see IModule
* @see IClip
*/
	public class AVAudio extends Module
	{
		public function AVAudio()
		{
		}
		override public function unload():void
		{
			if (__audioFetcher != null)
			{
				__audioFetcher.releaseAudio(_audio);
				__audioFetcher = null;
			}
			if (_audio != null)
			{
				// _audio.unload(); leave this for fetcher to handle!
				_audio = null;
			}
			super.unload();
		}
		override public function buffer(range:TimeRange, mute:Boolean):void
		{
			try
			{
				if (! mute) 
				{
					super.buffer(range, mute);
					var quantize:Number = _getQuantize();
					_bufferAudio(range);
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this, e);
			}
		}
		override public function buffered(range:TimeRange, mute:Boolean):Boolean
		{
			super.buffered(range, mute);
			var is_buffered:Boolean = _mute;// || (first == last));
			try
			{
				if (! is_buffered)
				{
					var quantize:Number = _getQuantize();
					if (audio != null)
					{
						_audio.loops = _getClipPropertyNumber('loops') + 1;
						is_buffered = _audio.buffered(range);
					}	
					else is_buffered = (__audioFetcher == null);
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this, e);
			}
			return is_buffered;
		}
		override public function getAudioDatum(position:uint, length:int, samples_per_frame:int):Vector.<AudioData>
		{
			var vector:Vector.<AudioData> = null;
			if (_audio != null)
			{
				vector = _audio.getAudioDatum(position, length, samples_per_frame);
				
			}
			return vector;
		}
		public function get audio():IHandler
		{
			var url:String;
			try
			{
				if (_audio == null)
				{
					url = _getAudioURL();
					if (url.length)
					{
						var media_duration:Number = _getMediaPropertyNumber(MediaProperty.DURATION);
						if (! media_duration)
						{
							RunClass.MovieMasher['msg'](this + '.audio with no media duration ' + media.tag.toXMLString());
						}
						else
						{
							if (__audioFetcher == null)
							{
								__audioFetcher = RunClass.MovieMasher['assetFetcher'](url);
								__audioFetcher.addEventListener(Event.COMPLETE, __fetcherComplete);
								__audioFetcher.retain();
							}
							_audio = __audioFetcher.handlerObject(url);
							if (_audio != null)
							{
								_audio.addEventListener(EventType.BUFFER, _audioBuffer);
								_audio.duration = media_duration;
								//RunClass.MovieMasher['msg'](this + '.audio setting duration = ' + media_duration + ' ?= ' + _audio.duration);
								_audio.visual = _visual;
							}
						}
					}
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.audio', e);
			}
			return _audio;
		}
		protected function _bufferAudio(time_range:Object):void
		{
			try
			{
				if (! _mute)
				{
					if (audio != null)
					{
						_audio.buffer(time_range);
					}
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this, e);
			}
		}
		protected function _getAudioURL():String
		{
			var url:String = _getMediaProperty(MediaProperty.AUDIO);
			if (url == null) 
			{
				url = '';
			}
			return url;
		}
		protected function _audioBuffer(event:Event):void
		{
			try
			{
				dispatchEvent(new Event(EventType.BUFFER));
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this, e);
			}
		}
		
		private function __scaleInfo(orig_w:uint, orig_h:uint, target_w:uint, target_h:uint, fill:String)
		{
		// crop             Crop the input video to width:height:x:y.
		// scale            Scale the input video to width:height size and/or convert the image format.
		// pad              Pad input image to width:height[:x:y[:color]] (default x and y: 0, default color: black).
			var result:Object = new Object();
			var orig_target_w:uint = target_w;
			var orig_target_h:uint = target_h;
			var h_locked,simple_scale,fill_is_scale, is_tall:Boolean;
			var ratio,ratio_w,ratio_h:Number;
			var dims,orig_dims, target_dims,offsets:Array;
			var min_max:String;
			var index, other_index:uint;
			dims = new Array(target_w, target_h);
			target_dims = new Array(target_w, target_h);
			orig_dims = new Array(orig_w, orig_h);
			
			if (! ( (orig_h == target_h) && (orig_w == target_w) ) )
			{
				simple_scale = true; // see if only scale filter can be used
				switch (fill)
				{
					case '':
					case 'stretch': break;
					default:
					{
						ratio_w = Number(orig_w) / Number(target_w); 
						ratio_h = Number(orig_h) / Number(target_h); 
						simple_scale = (ratio_w == ratio_h);
					}
				}
				if (! simple_scale) 
				{
					fill_is_scale = (fill == 'scale');
					min_max = (fill_is_scale ? 'max' : 'min');
					ratio = Math[min_max](ratio_h, ratio_w);
					is_tall = (ratio_h > ratio_w);
					h_locked = ((fill_is_scale && is_tall) || ((! fill_is_scale) && (! is_tall)));
					simple_scale = ( ! ( (h_locked && (target_h == orig_h)) || ((! h_locked) && (target_w == orig_w)) ) ) ;
					index = (h_locked ? 0 : 1);
					other_index = (h_locked ? 1 : 0);
					dims[index] = int(Math.ceil(Number(orig_dims[index]) / ratio));


					offsets = new Array(target_w, target_h, 0, 0);
					offsets[index + 2] = int(Math.abs(Math.floor(Number(int(target_dims[index]) - dims[index]) / 2.0)));		
					result[fill_is_scale ? 'pad' : 'crop'] = offsets;
				}
				if (simple_scale) result['scale'] = dims;
			}
			return result;
		}
		

		protected function _sizeContainedDisplay(display:DisplayObject, container:Sprite):void
		{
			if ((display != null) && (_size != null))
			{
				var fill:String = _getClipProperty(MediaProperty.FILL);
				
				var target_w:int = _size.width;
				var target_h:int = _size.height;
				var orig_w:Number = display.width;
				var orig_h:Number = display.height;
				var scale_info:Object = __scaleInfo(orig_w, orig_h, target_w, target_h, fill);
				/*	
				if (scale_info.scale != null) RunClass.MovieMasher['msg'](this + '._sizeContainedDisplay ' + orig_w + 'x' + orig_h + ' - ' + target_w + 'x' + target_h + ' = scale ' + scale_info.scale.join(', '));
				if (scale_info.crop != null) RunClass.MovieMasher['msg'](this + '._sizeContainedDisplay ' + orig_w + 'x' + orig_h + ' - ' + target_w + 'x' + target_h + ' = crop ' + scale_info.crop.join(', '));
				if (scale_info.pad != null) RunClass.MovieMasher['msg'](this + '._sizeContainedDisplay ' + orig_w + 'x' + orig_h + ' - ' + target_w + 'x' + target_h + ' = pad ' + scale_info.pad.join(', '));
*/
				if (scale_info.scale == null) scale_info.scale = new Array(orig_w, orig_h);
				
				
				container.width = scale_info.scale[0];
				container.height = scale_info.scale[1];
				var x_pos,y_pos:int;
				x_pos = 0;
				y_pos = 0;
				if (scale_info.crop != null) 
				{
					if (scale_info.crop[2]) x_pos = - scale_info.crop[2];
					if (scale_info.crop[3]) y_pos = - scale_info.crop[3];
				}
				else if (scale_info.pad != null) 
				{
					if (scale_info.pad[2]) x_pos = scale_info.pad[2];
					if (scale_info.pad[3]) y_pos = scale_info.pad[3];
				}
				container.x = x_pos - Math.round(target_w / 2);
				container.y = y_pos - Math.round(target_h / 2);
				/*
				
				
				var is_tall, fill_is_scale, h_locked:Boolean;
				var multiplier:Number;
				var ratio_w, ratio_h:Number;
				var scaled_w, scaled_h:int;
				
				if (fill.length && (fill != FillType.STRETCH))
				{
					ratio_w = Number(target_w) / orig_w;
					ratio_h = Number(target_h) / orig_h;
					is_tall = (ratio_w > ratio_h);
					fill_is_scale = (fill == FillType.SCALE);
					h_locked = ((fill_is_scale && is_tall) || ((! fill_is_scale) && (! is_tall)));
					
					if (h_locked) 
					{
						container.height = target_h;
						container.scaleX = container.scaleY;
					}
					else
					{
						container.width = target_w;
						container.scaleY = container.scaleX;
					}
					container.x = - Math.round(container.width / 2);
					container.y = - Math.round(container.height / 2);
				}
				else // stretch it to fill
				{
					container.width = target_w;
					container.height = target_h;
					container.x = - Math.round(target_w / 2);
					container.y = - Math.round(target_h / 2);
				}
				//RunClass.MovieMasher['msg'](this + '._sizeContainedDisplay ' + container.x + ',' + container.y + ' ' + scaled_w + 'x' + scaled_h + ' ' + multiplier);
				*/
			}
		}

		private function __fetcherComplete(event:Event):void
		{
			try
			{
				__audioFetcher.removeEventListener(Event.COMPLETE, __fetcherComplete);
				dispatchEvent(new Event(EventType.BUFFER));
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this, e);
			}
		}
		protected var _audio:IHandler = null;
		protected var _startTime:Number;
		protected var _visual:Boolean = false;
		private var __audioFetcher:IAssetFetcher;
	}
}