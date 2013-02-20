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
* Static class contains Class constants for many runtime classes. Use these references to avoid
* having to compile in the classes themselves, if you're sure they will be available at runtime. 
* The constants here are set as SWFs are loaded and some may never be set, depending on the 
* supplied configuration. 
* @see MoviemasherStage
* @see PlayerStage
* @see EditorStage
*/
	public class SourceClass
	{

/**
* {@link com.moviemasher.source.LocalSource}
*/
		public static var LocalSource:Class;

/**
* {@link com.moviemasher.utils.RemoteSource}
*/
		public static var RemoteSource:Class;
/**
* {@link com.moviemasher.source.Source}
*/
		public static var Source:Class;
	}
}
