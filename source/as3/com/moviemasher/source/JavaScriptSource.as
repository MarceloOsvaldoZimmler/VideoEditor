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
package com.moviemasher.source
{
	import com.moviemasher.interfaces.*;
	import com.moviemasher.type.*;
	import com.moviemasher.constant.*;
	import flash.external.*;
	import flash.system.*;
	import flash.net.*;

/**
* Class allows loading of Feed images.
*
* @see RemoteSource
*/
	public class JavaScriptSource extends RemoteSource
	{
		private static var __instanceCount:uint = 0;
		private var __instanceIndex:uint = 0;
		public function JavaScriptSource()
		{ 
			__instanceCount ++;
			__instanceIndex = __instanceCount;
			super();
			_defaults.count = '20';
			_defaults.sort = 'created';
		}
		private function __callback(data:String):String
		{
			try
			{
				_loadData(data);
				//RunClass.MovieMasher['msg'](this + '.__callback ' + length);
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg']('__callback', e);
			}
			return 'OK';
		}
		override protected function _activate():void
		{	
			var callback:String = getValue('callback').string;
			if (callback.length)
			{
				//RunClass.MovieMasher['msg'](this + '._activate ' + callback);
				Security.allowDomain('*');
				ExternalInterface.addCallback(callback, __callback);
			}
			super._activate();
		}
		override protected function _makeRequest():void	
		{
			//RunClass.MovieMasher['msg'](this + '._makeRequest');
			var parsed:String = _parsedURL();
			if ((parsed != null) && parsed.length)
			{
				navigateToURL(new URLRequest(parsed), '_self');
			}
		}	
		override public function toString():String
		{
			var string:String = super.toString();
			string += ' ' + __instanceIndex;
			return string;
		}
	}
		
}