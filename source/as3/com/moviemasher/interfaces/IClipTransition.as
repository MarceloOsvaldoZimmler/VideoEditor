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

package com.moviemasher.interfaces
{
	import com.moviemasher.type.*;
	import flash.display.*;
	import flash.geom.*;
	import com.moviemasher.constant.*;
/**
* Interface represents a {@link TransitionClip} within a {@link Mash}
* 
* @see IClipTransition
* @see IMash
*/
	public interface IClipTransition extends IClipEffect
	{
/**
* Array of filter objects to apply to the clip appearing after receiver
* 
* @see MaskedSprite
*/	
		function get transitionFilters():Array;	
/**
* Matrix object to apply to the clip appearing after receiver
* 
* @see MaskedSprite
*/	
		function get transitionMatrix():Matrix;
/**
* ColorTransform object to apply to the clip appearing after receiver
* 
* @see MaskedSprite
*/	
		function get transitionColorTransform():ColorTransform;
/**
* DisplayObject to mask the clip appearing after receiver
* 
* @see MaskedSprite
*/	
		function get transitionMask():DisplayObject;
	}
}
