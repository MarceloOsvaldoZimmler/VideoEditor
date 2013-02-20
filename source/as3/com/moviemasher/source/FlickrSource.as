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
	import com.moviemasher.utils.*;
	
/**
* Class allows loading of Flickr content.
*
* @see RemoteSource
*/
	public class FlickrSource extends RemoteSource
	{
		public function FlickrSource()
		{ 
			super();
			_countKey = 'per_page';
			_termsKey = 'text';
			_indexKey = 'page';
			_defaults.url = 'http://api.flickr.com/services/rest/?';
			_defaults.api_key = '';
			_defaults.method = 'flickr.photos.getRecent';
		}
		override protected function _parsedURL():String
		{
			var bracketed:Array;
			var parsed:String = '';
			var api_key:String = getValue('api_key').string;
			var method:String;
			if (_terms.length) method = 'flickr.photos.search';
			else method = getValue('method').string;
			var args:Object;
			var pairs:Array
			var k:String;
			var url:String;
			
			url = getValue('url').string;
			
			if (! url.length) RunClass.MovieMasher['msg'](this + ' requires the url attribute');
			else if (! api_key.length) RunClass.MovieMasher['msg'](this + ' requires the api_key attribute');
			else if (! method.length) RunClass.MovieMasher['msg'](this + ' requires the method attribute');
			else
			{
				args = new Object();
				args.method = method;
				args.api_key = api_key;
				
				// Flickr wants to know the page number rather than the start index
				args[_indexKey] = String(Math.floor((_index + _count) / _count));
				
				bracketed = RunClass.ParseUtility['bracketed'](url);
				args = _searchArgs(args, bracketed);
				if (args != null)
				{
					pairs = new Array();
					for (k in args)
					{
						pairs.push(k + '=' + args[k]);
					}
					parsed += super._parsedURL();
					parsed += pairs.join('&');
				}
			}
			return parsed;
		}

		override protected function _loadItemsFromData(data:String):void
		{
			var list_xml:XML;
			var xml_list:XMLList;
			var tag:XML;
			var did_add:Boolean = false;
			var count:int = _count;
			try
			{
				list_xml = new XML(data);
				
				xml_list = list_xml.err;
				if (xml_list.length())
				{
					RunClass.MovieMasher['msg'](this + ' ' + xml_list[0].@code + ' ' + xml_list[0].@msg);
				}
				else
				{
					xml_list = list_xml.photos.photo;
					for each (tag in xml_list)
					{
						count--;
						tag = __tagFromTag(tag);
						if (tag != null)
						{
							if (_addResultIfUnique(tag, true))
							{
								did_add = true;
							}
						}
					}
				}
				_more = ! count;
				if (did_add) _itemsDidChange();
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this, e);
				_more = false;
			}
		}
		private function __tagFromTag(video:XML):XML
		{
			var tag:XML = null;
			if ((video != null) && String(video.@id).length)
			{
				tag = <media/>;
				tag.@label = String(video.@title);		
				tag.@id = RunClass.MD5['hash'](String(video.@id));
				tag.@type = 'image';
				tag.@url = 'http://farm' + String(video.@farm) + '.static.flickr.com/' + video.@server + '/' + video.@id + '_' + video.@secret + '.jpg';
				tag.@icon = 'http://farm' + String(video.@farm) + '.static.flickr.com/' + video.@server + '/' + video.@id + '_' + video.@secret + '_t.jpg'
				
		
			}
			return tag;
		}
		
	}
	
}
			/*	
				photo.id = p.@id.toString();
				photo.farmId = parseInt(p.@farm);
				photo.ownerId = p.@owner.toString();
				photo.secret = p.@secret.toString();
				photo.server = parseInt( p.@server );
				photo.ownerName = p.@username.toString();
				photo.title = p.@title.toString();
			http://farm{farm-id}.static.flickr.com/{server-id}/{id}_{secret}.jpg
	or
http://farm{farm-id}.static.flickr.com/{server-id}/{id}_{secret}_[mstb].jpg
	or
http://farm{farm-id}.static.flickr.com/{server-id}/{id}_{o-secret}_o.(jpg|gif|png)
Size Suffixes

The letter suffixes are as follows:

s	small square 75x75
t	thumbnail, 100 on longest side
m	small, 240 on longest side
-	medium, 500 on longest side
b	large, 1024 on longest side (only exists for very large original images)
o	original image, either a jpg, gif or png, depending on source format
*/					
