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
package com.moviemasher.stage
{
	import com.moviemasher.action.*;
	import com.moviemasher.constant.*;
	import com.moviemasher.control.*;
	import com.moviemasher.display.*;
	import com.moviemasher.preview.*;
	import com.moviemasher.utils.*;
	import flash.display.*;
/**
* Implementation class for editor SWF root object
*/
	public class EditorStage extends MovieClip
	{
		function EditorStage()
		{ 
			RunClass.BrowserPreview = BrowserPreview;
			RunClass.DragUtility = DragUtility;
			RunClass.Action = Action;
		}
		private static  var __needsBrowser:Browser;
		private static  var __needsButtonPreview:ButtonPreview;
		private static  var __needsPanelPreview:PanelPreview;
		private static  var __needsField:Field;
		private static  var __needsIncrement:Increment;
		private static  var __needsPicker:Picker;
		private static  var __needsPlotter:Plotter;
		private static  var __needsRuler:Ruler;
		private static  var __needsScrollbar:Scrollbar;
		private static  var __needsTimeline:Timeline;
		private static  var __needsTrimmer:Trimmer;
	}
}