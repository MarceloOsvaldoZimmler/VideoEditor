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
	
/**
* Interface for incrementor implementations
* 
* @see Ruler
* @see Increment
*/
	public interface IIncrement extends IMetrics, IValued
	{
/**
* Sets time to display for marker (write-only)
* 
* @param n Number object containing new time
*/
		function set time(n:Number):void;
/**
* Sets {@link Ruler} that owns receiver for text formatting (write-only)
* 
* @param n Number object containing new time
*/
		function set owner(object:IValued):void;
	}
}