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

package com.moviemasher.core
{
	import com.moviemasher.events.*;
	import com.moviemasher.display.*;
	import com.moviemasher.interfaces.*;
	import com.moviemasher.type.*;
	import com.moviemasher.constant.*;
	import com.moviemasher.utils.*;
	import flash.display.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.system.*;
	import flash.utils.*;

/**
* Implementation class represents an instance of a {@link IMedia} item, usually within a mash.
* 
* @see IClip
*/
	public class TransitionClip extends EffectClip implements IClipTransition
	{
		public function TransitionClip(type:String, media:IMedia, mash:IMash = null)
		{
			super(type, media, mash);
			
		}
		public function get transitionMatrix():Matrix
		{
			var module_matrix:Matrix = null;
			var effect:IModuleTransition;
			if ((_module != null) && (_module is IModuleTransition))
			{
				effect = _module as IModuleTransition;
				module_matrix = effect.transitionMatrix;
			}
			return module_matrix;
		}
		public function get transitionColorTransform():ColorTransform
		{
			var module_transform:ColorTransform = null;
			var effect:IModuleTransition;
			if ((_module != null) && (_module is IModuleTransition))
			{
				effect = _module as IModuleTransition;
				module_transform = effect.transitionColorTransform;
			}
			return module_transform;
		
		}
		public function get transitionFilters():Array
		{
			var module_filters:Array = null;
			var effect:IModuleTransition;
			if ((_module != null) && (_module is IModuleTransition))
			{
				effect = _module as IModuleTransition;
				module_filters = effect.transitionFilters;
			}
			return module_filters;
		}	
		public function get transitionMask():DisplayObject
		{
			var module_mask:DisplayObject = null;
			var effect:IModuleTransition;
			if ((_module != null) && (_module is IModuleTransition))
			{
				effect = _module as IModuleTransition;
				module_mask = effect.transitionMask;
			}
			return module_mask;
		}	
	}
}
