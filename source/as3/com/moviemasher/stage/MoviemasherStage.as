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
	import com.moviemasher.constant.*;
	import com.moviemasher.core.MovieMasher;
	import com.moviemasher.manager.*;
	import com.moviemasher.type.*;
	import com.moviemasher.utils.*;
	import flash.display.*;
	import flash.events.*;
	import flash.net.*;
	import flash.system.*;
	import com.adobe.crypto.*;
	
/**
* Implementation class for moviemasher SWF root object
*/
	public class MoviemasherStage extends MovieClip
	{
  		public function MoviemasherStage()
		{
			var mm:MovieMasher;
			var sm:StageManager;
			var lm:LoadManager;
			var cm:ConfigManager;

			RunClass.MovieMasher = MovieMasher;
			RunClass.MD5 = MD5;
			RunClass.URL = URL;
			RunClass.ParseUtility = ParseUtility;
			ManagerClass.StageManager = StageManager;
			ManagerClass.LoadManager = LoadManager;
			ManagerClass.ConfigManager = ConfigManager;
			
			mm = new MovieMasher();

			StageManager.sharedInstance = new StageManager();
			LoadManager.sharedInstance = new LoadManager();
			ConfigManager.sharedInstance = new ConfigManager();
			
			sm = StageManager.sharedInstance;
			lm = LoadManager.sharedInstance;
			
			cm = ConfigManager.sharedInstance;
			addChild(mm);
			addChild(sm);
			sm.setManagers(lm);
			cm.setManagers(lm, sm);
			mm.setManagers(lm, cm, sm);
		}
	}
}

