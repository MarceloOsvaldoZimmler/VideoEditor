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
	import com.adobe.utils.*;
	import com.adobe.xml.syndication.generic.*;
	import com.adobe.xml.syndication.*;
	


/**
* Class allows loading of Feed images.
*
* @see RemoteSource
*/
	public class FeedSource extends RemoteSource
	{
		public function FeedSource()
		{ 
			super();
			_defaults.count = '20';
			_defaults.sort = 'created';
		}
		
		override protected function _loadItemsFromData(data:String):void
		{
		
			//RunClass.MovieMasher['msg'](data);
			var feed:IFeed;
			var feed_items:Array;
			var tag:XML;
			var did_add:Boolean = false;
			var count:int = _count;
			var feed_xml:XML;
			var item:IItem;
			var icon:String;
			var id_hash:String;
			var done:Object = new Object();
			try
			{
				feed_xml = new XML(data);
				icon = __feedIcon(feed_xml);
				feed = FeedFactory.getFeedByString(data);
				if (feed != null)
				{
					feed_items = feed.items;
					if ((feed_items != null) && feed_items.length)
					{
						//loop through each item in the feed
						for each(item in feed_items)
						{
							id_hash = RunClass.MD5['hash'](item.id);
							if (done[id_hash] != null) continue;
							done[id_hash] = true;
							
							tag = __tagFromItem(item);
							if (tag != null) 
							{
								if (! String(tag.@icon).length) tag.@icon = icon;
								if (! String(tag.@id).length) tag.@id = id_hash;
								
								if (_addResultIfUnique(tag, true))
								{
									did_add = true;
								}
							}
						}
						if (did_add) _itemsDidChange();
					}
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '._loadItemsFromData ' + e)
			}
			// feed does not page
			_more = false;		
		}
		private function __feedIcon(feed_xml:XML):String
		{
			var icon:String = '';
			var xml_list:XMLList = feed_xml..ITUNES_NS::image;
			if (xml_list.length())
			{
				icon = xml_list[0].@href;
			}
			return icon;
		}
		private function __itemDuration(item:IItem):Number
		{
			var item_tag:XMLList;
			var a:Array
			var multiplier:int = 1;
			var seconds:Number = 0;
			var n:Number;
			var z,i:int;
			try
			{
				//this member was added to IItem, so as to get the underlying tag
				item_tag = item.xml;
				var duration:String = ParsingTools.nullCheck(item_tag.ITUNES_NS::duration);
				if ((duration != null) && duration.length)
				{
					a = duration.split(':');
					z = a.length;
					for (i = z - 1; i > -1; i--)
					{
						n = Number(a[i]);
						if (isNaN(n)) 
						{
							seconds = 0;
							break;
						}
						seconds += (n * multiplier);
						multiplier *= 60;
					}
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__itemDuration ' + e);
			}
			return seconds;		
		}
		private function __tagFromItem(item:IItem):XML
		{
			var tag:XML = null;
			var item_tag:XMLList;
			var media:com.adobe.xml.syndication.generic.Media;
			var type:String;
			var url:String;
			var seconds:Number;
			
			try
			{
				
				media = item.media;
				if (media != null)
				{
					type = media.type;
					url = media.url;
					if (type.length && url.length)
					{
						type = type.substr(0, type.indexOf('/'));
						tag = <media />;
						tag.@label = item.title;
						tag.@type = type;
						tag.@source = url;
						tag.@group = type;
						tag.@icon = __feedIcon(item.xml[0]);
						switch(type)
						{
							case 'image':
								tag.@url = url;
								break;
							case 'video':
								tag.@url = url;
								// intentional fallthrough to audio
							case 'audio':
								tag.@audio = url;
								seconds = __itemDuration(item);
								if (! seconds) return null;
								tag.@duration = seconds;
								break;
							
						}
					}
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__tagFromItem ' + e + ' ' + item );
			}	
			return tag;
		}
		
		public static const ITUNES_NS:Namespace = new Namespace('http://www.itunes.com/dtds/podcast-1.0.dtd');
	}
		
}