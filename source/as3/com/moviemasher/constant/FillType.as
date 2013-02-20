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

package com.moviemasher.constant
{
	
/** 
* Static class contains String constants for supported methods of resizing visuals 
* within dimensions having a different aspect ratio.
*/
	public class FillType
	{
/** 
* The visual is resized to fit the dimensions exactly, potentially stretching.
*/
		public static const STRETCH:String = 'stretch';
/** 
* The visual is resized as much as is needed to completely fill the dimensions, potentially cropping.
*/
		public static const CROP:String = 'crop';
/** 
* The visual is resized as much as is need to display all of it, potentially exposing 
* underlying visuals or background color.
*/
		public static const SCALE:String = 'scale';
	}
}
