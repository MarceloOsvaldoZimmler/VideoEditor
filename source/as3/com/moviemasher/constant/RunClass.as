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
	public class RunClass
	{
/**
* {@link com.moviemasher.action.Action}
*/
		public static var Action:Class;
/**
* {@link com.moviemasher.core.Clip}
*/
		public static var Clip:Class;
/**
* {@link com.moviemasher.preview.BrowserPreview}
*/
		public static var BrowserPreview:Class;
/**
* {@link com.moviemasher.utils.DragUtility}
*/
		public static var DragUtility:Class;
/**
* {@link com.moviemasher.utils.DrawUtility}
*/
		public static var DrawUtility:Class;
/**
* {@link com.moviemasher.utils.FontUtility}
*/
		public static var FontUtility:Class;
/**
* {@link com.moviemasher.core.Mash}
*/
		public static var Mash:Class;
/**
* {@link com.adobe.crypto.MD5}
*/
		public static var MD5:Class;
/**
* {@link com.moviemasher.core.Media}
*/
		public static var Media:Class;
/**
* {@link com.moviemasher.module.Module}
*/
		public static var Module:Class;
/**
* {@link com.moviemasher.utils.MouseUtility}
*/
		public static var MouseUtility:Class;
/**
* {@link com.moviemasher.core.MovieMasher}
*/
		public static var MovieMasher:Class;
/**
* {@link com.moviemasher.display.PanelsView}
*/
		public static var PanelsView:Class;
/**
* {@link com.moviemasher.utils.ParseUtility}
*/
		public static var ParseUtility:Class;
/**
* {@link com.moviemasher.stage.PlayerStage}
*/
		public static var PlayerStage:Class;
/**
* {@link com.moviemasher.utils.PlotUtility}
*/
		public static var PlotUtility:Class;
/**
* {@link com.moviemasher.utils.StringUtility}
*/
		public static var StringUtility:Class;
/**
* {@link com.moviemasher.utils.TimeUtility}
*/
		public static var TimeUtility:Class;
/**
* {@link com.moviemasher.type.URL}
*/
		public static var URL:Class;
	}
}
