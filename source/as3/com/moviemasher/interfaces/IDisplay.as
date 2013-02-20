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
	import flash.display.*;
	import flash.events.*;
	import com.moviemasher.type.*;
	import com.moviemasher.constant.*;
	
/**
* Interface for all display objects
*
* @see IControl
*/
	public interface IDisplay extends IEventDispatcher
	{
/**
* Retrieve DisplayObject pointer for receiver
*
* @see IControl
*/
		function get displayObject():DisplayObjectContainer;
		
	}
}