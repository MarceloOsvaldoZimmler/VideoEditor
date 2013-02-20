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
package com.moviemasher.manager
{
	import flash.events.*;
	import flash.net.*;
	import flash.system.*;
	import flash.text.*;
	import flash.utils.*;
	import com.moviemasher.type.*;
	import com.moviemasher.constant.*;
	import com.moviemasher.events.*;
	import com.moviemasher.utils.*;
	import com.moviemasher.manager.*;
	import com.moviemasher.type.*;
	import com.moviemasher.constant.*;
	import com.moviemasher.interfaces.*;
	
/**
* Implementation class for fetching text based server side resources and CGI responses.
*
* @see IDataFetcher
*/
	public class DataFetcher extends Fetcher implements IDataFetcher
	{
		public function DataFetcher(iURL:URL, postData:*, format:String, translate:Boolean)
		{
			super(iURL, translate);
			
			if (_state == EventType.LOADING)
			{
				__postData = postData;
				__postFormat = format;
				__loadLoader();
				
			}
		}
		private var __postData:*;
		private var __postFormat:String;
		
		override protected function _reload():Boolean
		{
			var did_reload:Boolean = super._reload();
			if (did_reload)
			{
				__loadLoader();
			}
			return did_reload;
		}
		private function __loadLoader():void
		{
			_state = EventType.LOADING;
			
			var url_string:String = __url.absoluteURL;
			url_string = _translatedURL(url_string);
			
			var request:URLRequest = new URLRequest(url_string);
			__loader = new URLLoader();
			__loader.dataFormat = __postFormat;
			if (__postData != null)
			{
				request.method = URLRequestMethod.POST;
				if (__postData is XML) 
				{
					request.contentType = 'text/xml';
					request.data = (__postData as XML).toXMLString() + "\n";
				}
				else if (__postData is String)
				{
					request.contentType = 'text/plain';
					request.data = String(__postData) + "\n";
				}
				else if (__postData is ByteArray)
				{
					request.contentType = 'application/octet-stream';
					request.data = (__postData as ByteArray);
				
				}
			}
			else
			{
				request.method = URLRequestMethod.GET;
			}
			_startListening(__loader);
			__loader.load(request);
		}

		public function xmlObject():XML
		{
			var xml_object:XML = null;
			var xml_str:String;
			try
			{
				
				xml_str = data();
				if (xml_str.length)
				{
					xml_object = new XML(xml_str);
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.xmlObject ' + xml_str, e);
			}
			return xml_object;	
		}
		public function data():*
		{
			var s:* = '';
			try
			{
				if (_state == EventType.LOADED)s = __loader.data;
				if (_state != EventType.LOADING) LoadManager.removeSession(this);
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this, e);
			}
			
			return s;
		}
		override public function toString():String
		{
			var s:String = '[DataFetcher';
			if (__url != null)
			{
				s += ' ' + __url.absoluteURL;
			}
			s += ']';
			return s;
		}
		private var __loader:URLLoader;
	}
}