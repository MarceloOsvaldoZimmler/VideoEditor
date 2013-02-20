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
	import com.moviemasher.interfaces.*;
	import com.moviemasher.type.*;
	import flash.display.*;
	import flash.geom.*;
/**
* Sprite used to render a mash with effects and transitions.
*
*/
	public class MaskedSprite extends Sprite
	{
		public function MaskedSprite()
		{
			try
			{
				__canvasSprite = new Sprite();
				addChild(__canvasSprite);
		
				__filtersSprite = new Sprite();
				__backgroundShape = new Shape();
				__containerSprite = new Sprite();
				__contentSprite = new Sprite();
				__maskShape = new Shape();
				
				__canvasSprite.addChild(__filtersSprite);
				__filtersSprite.addChild(__containerSprite);
				__containerSprite.addChild(__backgroundShape);
				__containerSprite.addChild(__contentSprite);
				__canvasSprite.addChild(__maskShape);
				__filtersSprite.mask = __maskShape;
				__containers = new Vector.<Sprite>();
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.MaskedSprite', e);
			}		
		}
		public function addDisplay(content:DisplayObject, index:Number = NaN, name:String = null, container:DisplayObjectContainer = null):void
		{
			if (container == null) container = __contentSprite;
			try
			{
				if (content != null)
				{
					if (isNaN(index)) 
					{
						if (! container.contains(content)) container.addChild(content);
					}
					else 
					{
						if (container.contains(content)) container.setChildIndex(content, index);
						else container.addChildAt(content, index);
					}
					if ((name != null) && name.length)
					{
						content.name = name;
						//RunClass.MovieMasher['msg'](this + '.addDisplay ' + content);
					}
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.addDisplay', e);
			}
		
		}
		public function applyEffects(effects:Vector.<IClipEffect>, time:Time):void
		{
			try
			{
				var contained:DisplayObject = __contentSprite;
				var container:DisplayObjectContainer = __containerSprite;
				var sprite:DisplayObjectContainer;
				
				var clip_filters:Array;
				var clip_matrix:Matrix;
				var clip_transform:ColorTransform;
				var effect_clip:IClipEffect;
				var effects_count:uint = effects.length;
				var i:uint;
				if (effects_count)
				{
					for (i = 0; i < effects_count; i++)
					{
						effect_clip = effects[i];
						effect_clip.metrics = __metrics;
						effect_clip.time = time;
						
						sprite = new Sprite();
						sprite.addChild(contained);
						sprite.addChild(effect_clip.displayObject);
						container.addChild(sprite);
						__containers.push(sprite);
						clip_filters = effect_clip.clipFilters;
						clip_matrix = effect_clip.clipMatrix;
						clip_transform = effect_clip.clipColorTransform;
						if (clip_filters == null) clip_filters = new Array();
						if (clip_matrix == null) clip_matrix = new Matrix();
						if (clip_transform == null) clip_transform = new ColorTransform();
					
						sprite.filters = clip_filters;
						sprite.transform.matrix = clip_matrix;
						sprite.transform.colorTransform = clip_transform;
						
						contained = sprite;
						addDisplay(contained, NaN, null, container);
					}
				}
				else clearEffects();
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.applyEffects', e);
			}
		}
		public function clearEffects():void
		{
			applyMatrix(new Matrix());
			applyColorTransform(new ColorTransform());
			applyFilters(new Array());
		}
		public function applyMask(apply_mask:DisplayObject = null):void
		{
			if (__containerSprite.mask != apply_mask)
			{
				__containerSprite.mask = apply_mask;
				__containerSprite.cacheAsBitmap = (apply_mask != null);
				if (apply_mask != null) apply_mask.cacheAsBitmap = true;
			}
		}
		public function applyMatrix(matrix:Matrix = null):void
		{
			if (matrix == null) matrix = new Matrix();
			__containerSprite.transform.matrix = matrix;
		}
		public function applyColorTransform(colorTransform:ColorTransform = null):void
		{
			if (colorTransform == null) colorTransform = new ColorTransform();
			__containerSprite.transform.colorTransform = colorTransform;
		}
		public function applyFilters(filters:Array = null):void
		{
			if (filters == null) filters = new Array();
			__filtersSprite.filters = filters;
		}
		public function applyTransition(transition_clip:IClipTransition, time:Time):void
		{
			try
			{
				var clip_filters:Array;
				var clip_matrix:Matrix;
				var clip_transform:ColorTransform;
				clip_filters = new Array();
				clip_transform = new ColorTransform();
				clip_matrix = new Matrix();
				var clip_mask:DisplayObject;
				var transition_to:Sprite = __contentSprite.getChildByName('transition_to') as Sprite;
				var transition_from:Sprite = __contentSprite.getChildByName('transition_from') as Sprite;
				var sprite:Sprite;
				var masked_sprite:MaskedSprite;
				if (transition_clip.getValue('swap').boolean)
				{
					sprite = transition_to;
					transition_to = transition_from;
					transition_from = sprite;
					__contentSprite.setChildIndex(transition_from, 0);
				}
				transition_clip.metrics = __metrics;
			//	RunClass.MovieMasher['msg'](this + '.applyTransition ' + transition_clip + ' ' + time);
				transition_clip.time = time;
				if (transition_clip.displayObject != null)
				{
					addDisplay(transition_clip.displayObject);
				}
				clip_filters = transition_clip.transitionFilters;
				clip_matrix = transition_clip.transitionMatrix;
				clip_transform = transition_clip.transitionColorTransform;
				clip_mask = transition_clip.transitionMask;
				if (clip_filters == null) clip_filters = new Array();
				if (clip_matrix == null) clip_matrix = new Matrix();
				if (clip_transform == null) clip_transform = new ColorTransform();
				
				if (transition_to is MaskedSprite)
				{
					masked_sprite = transition_to as MaskedSprite;
					masked_sprite.applyMatrix(clip_matrix);
					masked_sprite.applyMask(clip_mask);
					masked_sprite.applyColorTransform(clip_transform);
					masked_sprite.applyFilters(clip_filters);
				}
				else
				{	
					transition_to.cacheAsBitmap = (clip_mask != null);
					if (clip_mask != null) clip_mask.cacheAsBitmap = true;
				
					transition_to.transform.matrix = clip_matrix;
					transition_to.mask = clip_mask;
					transition_to.transform.colorTransform = clip_transform;
					transition_to.filters = clip_filters;
				}
				if (transition_from != null)
				{
					clip_filters = transition_clip.clipFilters;
					clip_matrix = transition_clip.clipMatrix;
					clip_transform = transition_clip.clipColorTransform;
					if (clip_filters == null) clip_filters = new Array();
					if (clip_matrix == null) clip_matrix = new Matrix();
					if (clip_transform == null) clip_transform = new ColorTransform();
				
					if (transition_from is MaskedSprite)
					{
						masked_sprite = transition_from as MaskedSprite;
						masked_sprite.applyMatrix(clip_matrix);
						masked_sprite.applyColorTransform(clip_transform);
						masked_sprite.applyFilters(clip_filters);
					}
					else
					{
						transition_from.transform.matrix = clip_matrix;
						transition_from.transform.colorTransform = clip_transform;
						transition_from.filters = clip_filters;
					}
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.applyTransition ' + transition_to + ' ' + transition_from, e);
			}
		}
		public function removeContent():void
		{
			try
			{
				applyMask();
				clearEffects();
				var sprite:Sprite;
				for each(sprite in __containers)
				{
					__removeContent(sprite);
				}
				__containers.length = 0;
				if (! __containerSprite.contains(__contentSprite)) __containerSprite.addChild(__contentSprite);
				__removeContent(__contentSprite);
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.removeContent', e);
			}
		}
		public function unload():void
		{
			try
			{
				removeContent();
				__filtersSprite.mask = null;
				__containerSprite.removeChild(__contentSprite);
				__containerSprite.removeChild(__backgroundShape);
				__filtersSprite.removeChild(__containerSprite);
				__canvasSprite.removeChild(__filtersSprite);
				__canvasSprite.removeChild(__maskShape);
				__filtersSprite = null;			
				__backgroundShape = null;
				__maskShape = null;
				__containerSprite = null;
				__contentSprite = null;
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.unload', e);
			}
		}
		public function set background(string:String):void
		{
			try
			{
				if (__background != string)
				{
					__background = string;
					__resize();
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.background', e);
			}
		}
		public function get background():String
		{
			return (__background ? __background : '');
		}
		public function get displayObject():DisplayObjectContainer
		{
			return this;
		}
		public function set metrics(iMetrics:Size):void
		{
			try
			{
				if ((iMetrics != null) && (! iMetrics.isEmpty()) && (! iMetrics.equals(__metrics)))
				{
					__metrics = iMetrics;
					__resize();
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + 'MASKED.metrics ' + iMetrics, e);
			}
		}
		public function get metrics():Size
		{
			return __metrics;
		}
		private function __removeContent(container:DisplayObjectContainer):void
		{
			try
			{
				var z:Number;
				var i:uint;
				var child:DisplayObject;
				z = container.numChildren;
				for (i = 0; i < z; i++)
				{
					container.removeChildAt(0);
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__removeContent', e);
			}
		}
		private function __resize():void
		{
			try
			{
				if (__metrics != null)
				{
					
					__maskShape.graphics.clear();
					RunClass.DrawUtility['fillBox'](__maskShape.graphics, -__metrics.width/2, -__metrics.height/2, __metrics.width,  __metrics.height, 0xFF00FF);
				
		
					
					__backgroundShape.graphics.clear();
					if ((__background != null) && __background.length)
					{
						//RunClass.MovieMasher['msg'](this + '.__resize ' + __background);
						RunClass.DrawUtility['fillBox'](__backgroundShape.graphics, -__metrics.width/2, -__metrics.height/2, __metrics.width, __metrics.height, RunClass.DrawUtility['colorFromHex'](__background));
					}
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__resize', e);
			}
		}
		override public function toString():String
		{
			var string:String = '[Masked Sprite';
			if ((name != null) && name.length) string += ': ' + name;
			string += ']';
			return string;
		}
		private var __background:String = '';
		private var __backgroundShape:Shape;
		private var __canvasSprite:Sprite;
		private var __containers:Vector.<Sprite>;
		private var __containerSprite:Sprite;
		private var __contentSprite:Sprite;
		private var __filtersSprite:Sprite;
		private var __maskShape:Shape;
		private var __metrics:Size;
	}
}