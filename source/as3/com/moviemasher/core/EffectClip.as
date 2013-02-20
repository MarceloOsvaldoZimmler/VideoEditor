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
	public class EffectClip extends Clip implements IClipEffect
	{
		public function EffectClip(type:String, media:IMedia, mash:IMash = null)
		{
			super(type, media, mash);
			
		}
		public function get clipMatrix():Matrix
		{
			var module_matrix:Matrix = null;
			var effect:IModuleEffect;
			if ((_module != null) && (_module is IModuleEffect))
			{
				effect = _module as IModuleEffect;
				module_matrix = effect.moduleMatrix;
			}
			return module_matrix;
		}
		public function get clipColorTransform():ColorTransform
		{
			// should only be called on effects!!
			var module_transform:ColorTransform = null;
			var effect:IModuleEffect;
			if ((_module != null) && (_module is IModuleEffect))
			{
				effect = _module as IModuleEffect;
				module_transform = effect.moduleColorTransform;
			}
			return module_transform;
		
		}
		public function get clipFilters():Array
		{
			// should only be called on effects!!
			var module_filters:Array = null;
			var effect:IModuleEffect;
			if ((_module != null) && (_module is IModuleEffect))
			{
				effect = _module as IModuleEffect;
				module_filters = effect.moduleFilters;
			}
			return module_filters;
		}	
	}
}
