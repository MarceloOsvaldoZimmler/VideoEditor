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
	import flash.events.*;
	import flash.geom.*;
	import flash.display.*;
	import flash.system.*;
	import com.moviemasher.type.*;
	import com.moviemasher.constant.*;
	import com.moviemasher.interfaces.*;	
	import com.moviemasher.events.*;
	import com.moviemasher.utils.*;
	import com.moviemasher.type.*;
	import com.moviemasher.constant.*;
/**
* Implementation class for composite effect module
*
* @see IModule
* @see Clip
* @see Mash
*/
	public class Composite extends ModuleTransition
	{
		public function Composite()
		{
			_defaults.blend = 'normal';
			_defaults.alpha = '100';
			_defaults.alphafade = '100';
			_defaultMatrix();
			_displayObjectContainer = new Sprite();
			addChild(_displayObjectContainer);
		}
		override public function buffer(range:TimeRange, mute:Boolean):void
		{
			try
			{
				super.buffer(range, mute);
							
				var composited_clip:IClip = __composited;
				if (composited_clip == null) composited_clip = composited;
				if (composited_clip != null)
				{
					var object:TimeRange = range.intersection(__composited.timeRange);
					if (object != null)
					{
						__composited.metrics = _size;
						__composited.buffer(object, mute);
					}
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.buffer', e);
			}
		}
		override public function buffered(range:TimeRange, mute:Boolean):Boolean
		{
			var is_buffered:Boolean = true;
			var object:TimeRange;
			var composited_clip:IClip = __composited;
			if (composited_clip == null) composited_clip = composited;
			if (composited_clip != null)
			{
				object = range.intersection(__composited.timeRange);
				if (object != null)
				{
					 is_buffered = __composited.buffered(object, mute);
				}
			}
			return is_buffered;
		}
		override public function set time(object:Time):void
		{
			super.time = object;

			try
			{
				

				if (__composited != null)
				{
					if (! _displayObjectContainer.contains(__composited.displayObject))
					{
						_displayObjectContainer.addChild(__composited.displayObject);
					}
					_setCompositedSize();
					var blend:String = _getClipProperty('blend');
					if (! blend.length) blend = RunClass.DrawUtility['blendModes'][0];
					blend = RunClass.DrawUtility['blendMode'](blend);
					__composited.displayObject.blendMode = blend;
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.time COMPOSITE ' + parent + ' ' + _displayObjectContainer, e);
			}
		}
		override public function get displayObject():DisplayObjectContainer
		{
			return this;
		}
		
		override public function getAudioDatum(position:uint, length:int, samples_per_frame:int):Vector.<AudioData>
		{
			var vector:Vector.<AudioData> = null;
			if (__composited != null)
			{
				var start_sample:int = int(__composited.startFrame) * samples_per_frame;
				var end_sample:int = start_sample + int(__composited.lengthFrame) * samples_per_frame;
				if ((position < end_sample) && ((position + length) >= start_sample))
				{
					vector = __composited.getAudioDatum(position, length, samples_per_frame);
				}
			}
			return vector;
		}
		override public function unbuffer(range:TimeRange):void
		{ 
			if (__composited != null)
			{
				var object:TimeRange = range.intersection(__composited.timeRange);
				if (object != null) __composited.unbuffer(object);
			}
			super.unbuffer(range);
		}
		override public function unload():void
		{
			__unloadCompositedModule();
			super.unload();
		}
		
		override protected function _changedSize():void
		{
			if (__composited != null)
			{
				__composited.metrics = _size;
			}
			
		}
		override protected function _clipDidChange(event:Event):void
		{
			super._clipDidChange(event);
			var getit:IClip = composited;
		}
		override protected function _clipPropertyDidChange(event:ChangeEvent):void
		{
			super._clipPropertyDidChange(event);
			switch (event.property)
			{
				case 'composites':
					var getit:IClip = composited;
					break;
			}
				
		}
		protected function get composited():IClip
		{
			try
			{
				var composites:Array = new Array();
				var iclip:IClip = null;
				var imedia:IMedia = null;
				var string:String;
				var object:Object = _getClipPropertyObject('composites');
				if (object != null) 
				{
					if (object is Array) composites = object as Array;
					else if (object is String) 
					{
						// it's a comma delimited list of media ids
						string = object as String;
						if (string.length) composites = string.split(',');
					}
					if (composites.length)
					{
						object = composites[0];
						if (object is String)
						{
							string = object as String;
							if (string.length)
							{
								imedia = RunClass.Media['fromMediaID'](string);
								if (imedia != null)
								{
									iclip = RunClass.Clip['fromMedia'](imedia);
									
									if (iclip != null) 
									{
										iclip.setValue(new Value(_getClipProperty(ClipProperty.LENGTHFRAME)), ClipProperty.LENGTHFRAME);
										iclip.track = -1;
									}
								}		
							}
						}
						else if (object is IClip)
						{
							iclip = object as IClip;
						}
					}
				}	
				if (__composited != iclip)
				{
					__unloadCompositedModule();
					__composited = iclip;
					if (__composited != null)
					{
						__composited.addEventListener(EventType.BUFFER, __clipBuffer);
					}
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.composited', e);
			}
			return __composited;
		}
		private function __compositedTime(object:Time = null):Time
		{
			if (object == null) object = _time;
			var result:Time = null;
			var range2:TimeRange = object.timeRange;
			if (__composited.timeRange.intersection(range2))
			{
				result = object;
			}
			return result;
		}
		private function __compositedFrame(number:Number = NaN):Number
		{
			if (isNaN(number)) number = _frame;
			var frames:Number = __composited.lengthFrame;
			if ((frames < (number - __composited.startFrame)) || ((number - __composited.startFrame) < 0))
			{
				number = NaN;//TODO: allow for looping ((number + frames) % frames);
			}
			return number;
		}
		protected function _defaultMatrix():void
		{
			_defaults.scale = '50,50';
			_defaults.shear = '50,50';
			_defaults.rotate = '0';
			_defaults.position = '50,50';
			_defaults.scalefade = '50,50';
			_defaults.shearfade = '50,50';
			_defaults.rotatefade = '0';
			_defaults.positionfade = '50,50';
			
		}
		final protected function _percentOfDimension(number:Number, dimension:String='height'):int
		{
			return Math.round((number * _size[dimension]) / 100.0);
		}
		final protected function _setCompositedFrame():Boolean
		{
			var did:Boolean = false;
			if (__composited != null)
			{
				try
				{
					var ct:Time = __compositedTime();
					if (ct == null) __composited.displayObject.visible = false;
					else
					{
						__composited.displayObject.visible = true;
						__composited.time = ct;
						did = true;
					}
				}
				catch(e:*)
				{
					RunClass.MovieMasher['msg'](this + '._setCompositedFrame', e);
				}
			}
			return did;
		}
		protected function _setCompositedSize():void
		{
			
			if (__composited != null)
			{
				try
				{
					__composited.metrics = _size;
					if (_setCompositedFrame())
					{
						_setDisplayObjectMatrix(__composited.displayObject);
					}
				}
				catch(e:*)
				{
					RunClass.MovieMasher['msg'](this + '._setCompositedSize', e);
				}
			}
		}
		protected function _setDisplayObjectMatrix(display_object:DisplayObject):void
		{
			try
			{
				var apply_values:Object = new Object();
				var default_values:Object = new Object();
				var key:String;
				var z:uint = __transformKeys.length;
				var s:String;
				var per:Number = _getFade();
				for (var i:uint = 0; i < z; i++)
				{
					key = __transformKeys[i];
					s = _getClipProperty(key);
					if ((s != null) && s.length)
					{
						// all double value keys
						if ((i < 3) && (s.indexOf(',') == -1)) s = s + ',' + s;
						
					
						apply_values[key] = s;
						if (per != 100)
						{
							s = _getClipProperty(key + 'fade');
							if ((s != null) && s.length)
							{
								if ((i < 3) && (s.indexOf(',') == -1)) s = s + ',' + s;
								default_values[key] = s;
							}
							else default_values[key] = apply_values[key];
						}
					}
					else RunClass.MovieMasher['msg'](this + '._setDisplayObjectMatrix no value for ' + key);
				}
				__applyTransform(per, display_object, apply_values, default_values);
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '._setDisplayObjectMatrix ' + display_object, e);
			}
		}
		private function __applyTransform(per:Number, display_object:DisplayObject, apply_values:Object, default_values:Object):void
		{
			try
			{
				var matrix:Matrix = new Matrix();
				var tmp_matrix:Matrix = new Matrix();
				if (per != 100)
				{
					apply_values = RunClass.PlotUtility['perValues'](per, apply_values, default_values, __transformKeys);
				}
				// scale
				apply_values.scale = apply_values.scale.split(',');
				tmp_matrix.a = parseFloat(apply_values.scale[0]) / 100;
				tmp_matrix.d = parseFloat(apply_values.scale[1]) / 100;
				matrix.concat(tmp_matrix);
	
				// shear
				tmp_matrix = new Matrix();
				apply_values.shear = apply_values.shear.split(',');
				tmp_matrix.b = ((50 - parseFloat(apply_values.shear[0]))/180) * Math.PI;
				tmp_matrix.c = ((50 - parseFloat(apply_values.shear[1]))/180) * Math.PI;
				matrix.concat(tmp_matrix);
	
				// rotation
				tmp_matrix = new Matrix();
				tmp_matrix.rotate((apply_values.rotate/180) * Math.PI);
				matrix.concat(tmp_matrix);
	
				// translation
				
				display_object.alpha = apply_values.alpha/100;
				display_object.transform.matrix = matrix;
			
				var total_size:Size = _size.copy();
				total_size.width += 2 * display_object.width;
				total_size.height += 2 * display_object.height;
				
				var pt:Point = RunClass.PlotUtility['plotPoint'](apply_values.position, total_size);
				
				pt.x -= total_size.width / 2;
				pt.y -= total_size.height / 2;
			
				display_object.x = pt.x;
				display_object.y = pt.y;
				
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__applyTransform ' + per + ' ' + display_object + ' ' + apply_values + ' ' + default_values, e);
			}
		}
		private function __clipBuffer(event:Event):void
		{
			dispatchEvent(new Event(EventType.BUFFER));
		}
		private function __unloadCompositedModule():void
		{
			try
			{
				if (__composited != null)
				{
					if ((__composited.displayObject != null) && _displayObjectContainer.contains(__composited.displayObject))
					{
						_displayObjectContainer.removeChild(__composited.displayObject);
					}
					__composited.removeEventListener(EventType.BUFFER, __clipBuffer);
					__composited.unload();
					__composited = null;
				}		
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__unloadCompositedModule', e);
			}
		}
		private static var __transformKeys:Array = [ModuleProperty.POSITION, 'scale', 'shear', 'rotate','alpha'];
		protected var __composited:IClip;
		protected var _displayObjectContainer:Sprite;
	}
}

