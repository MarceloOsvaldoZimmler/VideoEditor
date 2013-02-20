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
* Static class contains String constants related to resource fetching.
*/
	public class EventType
	{
/** 
* A {@link View} object has been invalidated.
*/
		public static const INVALIDATED:String = 'invalidated';
/** 
* Resources have been at least partially fetched.
*/
		public static const BUFFER:String = 'buffer';
/** 
* An error occured while fetching resources.
*/
		public static const ERROR:String = 'error';
/** 
* Resources have been fully fetched.
*/
		public static const LOADED:String = 'loaded';
/** 
* Resources are still being fetched.
*/
		public static const LOADING:String = 'loading';
/** 
* Fetching of resources has caused playback to pause.
*/
		public static const PROPERTY_CHANGED:String = 'property_changed';
/** 
* Fullscreen state has changed.
*/
		public static const FULLSCREEN:String = 'fullscreen';
/** 
* Fullscreen is desired.
*/
		public static const BIGSCREEN:String = 'bigscreen';
/** 
* Normal screen is desired.
*/
		public static const SMALLSCREEN:String = 'smallscreen';
	}
}
