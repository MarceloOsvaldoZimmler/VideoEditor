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
package com.moviemasher.type
{
	import com.moviemasher.constant.*;
	import com.adobe.net.*;
	
/**
* Class representing a parsable URL that might contain an SWF frame or class reference
*/
	public class URL
	{
		public function URL(url_string:String = null, format_string:String = null)
		{
			var base:String;
			if (__uriBase == null)
			{
				base = ManagerClass.StageManager['sharedInstance'].getParameter('base');
				if (base.length) __uriBase = new URI(base);
			}
			__format = format_string;
			if ((url_string != null) && url_string.length)
			{
				url = url_string;
			}
		}
		public function toString():String
		{
			var s:String = '[URL';
			if ((__url != null) && __url.length)
			{
				s += ' ' + __url;
			}
			return s;
		}
		public function get protocol():String
		{
			if (__protocol == null)
			{
				__protocol = ((__uri == null) ? '' : __uri.scheme);
			}
			return __protocol;
		}
		public function get server():String
		{
			if (__server == null)
			{
				__server = ((__uri == null) ? '' : __uri.authority);
			}
			return __server;
		}
		public function get file():String
		{
			if (__file == null)
			{
				__file = ((__uri == null) ? '' : __uri.getFilename(true));
			}
			return __file;
		}
		public function get query():String
		{
			if (__query == null)
			{
				__query = ((__uri == null) ? '' : __uri.query);
			}
			return __query;
		}
		public function get format():String
		{
			if ((__format == null) || (! __format.length))
			{
				__format = extension;
			}
			return __format;
		}
		public function get extension():String
		{
			if (__extension == null)
			{
				__extension = ((__uri == null) ? '' : __uri.getExtension(true));
			}
			return __extension;
		}
		public function get anchor():String
		{
			if (__anchor == null)
			{
				// we should have trapped this in set url??
				//__anchor = __uri.fragment;
			}
			return __anchor;
		}
		public function get definition():String
		{
			if (__definition == null)
			{
				// we should have caught this in set url()??
				//__parseURL();
			}
			return __definition;
		}
		public function get isLoaderContent():Boolean
		{
			var is_media:Boolean = false;
			
			if ((! query.length) || (extension != format))
			{
				switch (format)
				{
					case 'swf':
					case 'jpg':
					case 'jpeg':
					case 'png':
					case 'gif':
						is_media = true;
						break;
				}
				
			}
			return is_media;			
		}
		public function set format(s:String):void		
		{
			__format = s;
		}
		public function set url(s:String):void		
		{
			if (__url != s)
			{
				
				__absoluteURL = null;
				__key = null;
				
				__protocol = null;
				__server = null;
				__path = null;
				__file = null;
				__extension = null;
				__query = null;
				__anchor = '';
				__definition = '';
				__port = null;

				__url = s;
				
				var at_pos:int;
				var slash_pos:int;
				var amp_pos:int = __url.lastIndexOf('&');
				if (amp_pos == -1)
				{
					at_pos = __url.lastIndexOf('@');
					slash_pos = __url.lastIndexOf('/');
					if ((at_pos != -1) && (slash_pos < at_pos)) // we have a class reference at the end
					{
						__definition = __url.substr(at_pos + 1);
						s = __url.substr(0, at_pos);
					}
					at_pos = __url.lastIndexOf('#');
					if (at_pos != -1) // we have a frame reference at the end
					{
						__anchor = __url.substr(at_pos + 1);
						s = __url.substr(0, at_pos);
					}
				}
				__uri = null;
				if (s.length)
				{
					__uri = new URI(s);
					if (__uriBase)
					{
						__uri.makeAbsoluteURI(__uriBase);
					}
				}
			}
		}
		public function get url():String
		{
			return __url;
		}
		public function get key():String
		{
			if (__key == null)
			{
				__key = 'K' + RunClass.MD5['hash'](absoluteURL + query);
			}
			return __key;
		}
		public function get absoluteURL():String
		{
			if (__absoluteURL == null)
			{
				__absoluteURL = ((__uri == null) ? __url : __uri.toString());
				
			}
			return __absoluteURL;
		}
		private var __uri:URI;
		private var __uriBase:URI;
		private var __parsed:Boolean;
		private var __key:String;
		private var __absoluteURL:String;
		private var __protocol:String;
		private var __server:String;
		private var __path:String;
		private var __file:String;
		private var __extension:String;
		private var __query:String;
		private var __anchor:String;
		private var __definition:String;
		private var __port:String;
		private var __format:String;
		private var __url:String;
	}
}