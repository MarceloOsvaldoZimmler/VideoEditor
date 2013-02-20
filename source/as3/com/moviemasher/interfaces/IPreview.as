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
	import com.moviemasher.constant.*;
	import flash.geom.*;
	
/**
* Interface for {@link Media} and {@link Clip} previews
*
* @see Browser
* @see Timeline
*/
	public interface IPreview extends IDisplay
	{
		//READ
		function get backBounds():Rectangle;
		function get size():Size;
		
		// WRITE
		function set selected(value:Boolean):void;
		
		//  ACCESSORS READ+WRITE
		function get clip():IClip;
		function set clip(iclip:IClip):void;
		function get container():IPreviewContainer;
		function set container(previewContainer:IPreviewContainer):void;
		function get options():IOptions
		function set options(iOptions:IOptions):void;
		function set data(object:Object):void;
		function get data():Object;
		function set mediaTag(xml:XML):void;
		function get mediaTag():XML;
		// METHODS
		function unload():void;
		function updateTooltip(tooltip:ITooltip):Boolean;
	}
}