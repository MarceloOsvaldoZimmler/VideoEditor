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
	import flash.utils.*;
	import flash.events.*;
	import com.moviemasher.type.*;
	import com.moviemasher.events.*;
	import com.moviemasher.constant.*;

/**
* Class allows conditional searching of paged tags from remote cgi
*
* @see Player
* @see Browser
*/
	public class RemoteSource extends Source
	{
		public function RemoteSource()
		{
			super();
			_termsKey = 'terms';
			
		}
		override public function getValue(property:String):Value
		{
			var value:Value = new Value('');
			try
			{
				switch(property)
				{
					case 'loading':
						value = new Value(_requesting ? 1 : 0);
						break;
					case 'count':
					case _countKey:
						value = new Value(_count);
						break;
					case 'index':
					case _indexKey:
						value = new Value(_index + _indexStart);
						break;
					default:
						value = super.getValue(property);
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.getValue ' + property, e);
			}
			return value;
		}
		override public function getItemAt(index:Number):*
		{
			var item = null;
			try
			{
				item = super.getItemAt(index);
				
				if (_active && _more && ((index + 1) == length))
				{
					_gettingLastItem();
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this, e);
			}
			return item;
		}		
		protected function _gettingLastItem():void
		{
			// asking for last item in items
			if (! _requesting)
			{
				_index += _count;
				__initRequest();
			}
		}
		override protected function _parseTag():void
		{
			if (_defaults[_countKey] == null) 
			{
				_defaults[_countKey] = '20';	
			}
			super._parseTag();
			
			var value:Number = super.getValue(_countKey).number;
			if (value > 0)
			{
				_count = value;
			}
		}
		override protected function _search():void
		{
			if (! _requesting)
			{
				__resetRequest();
			}
		}	
		
		protected function _loadItemsFromData(data:String):void
		{
			var list_xml:XML;
			var xml_list:XMLList;
			var tag:XML;
			var did_add:Boolean = false;
			var i,child_count:uint;
			var count:int = _count;
			try
			{
				list_xml = new XML(data);
				xml_list = list_xml.children();
				child_count = xml_list.length();
				
				for (i = 0; i < child_count; i++)
				{
					tag = xml_list[i];
					count --;
					if (_addResultIfUnique(tag, true))
					{
						did_add = true;
					}
				}
				_more = ! count;
				if (did_add) _itemsDidChange();
				//RunClass.MovieMasher['msg'](this + '._loadItemsFromData children ' + child_count + ' ' + did_add);
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '._loadItemsFromData', e);
				_more = false;
			}
		}
		protected function _makeRequest():void
		{
			try
			{
				var parsed:String = _parsedURL();
				if ((parsed != null) && parsed.length)
				{
					
					_loader = RunClass.MovieMasher['dataFetcher'](parsed);
					_loader.addEventListener(Event.COMPLETE, __urlLoad);
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '._makeRequest ', e);
			}

		}
		protected function _parsedURL():String
		{
			var url:String = getValue('url').string;
			try
			{
				// do a really exhaustive search for bracketed values
				if (url.indexOf('{') != -1) url = RunClass.ParseUtility['brackets'](url);
				if (url.indexOf('{') != -1) url = RunClass.ParseUtility['brackets'](url, RunClass.MovieMasher['getByID']('parameters'));
				if (url.indexOf('{') != -1) url = RunClass.ParseUtility['optionBrackets'](url);
				if (url.indexOf('{') != -1) url = RunClass.ParseUtility['brackets'](url, this);
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '._parsedURL ', e);
			}
			return url;
		}
		protected function _searchArgs(args:Object, ignore:Array = null):Object
		{
			var k:String;
			
			var result:Object = null;
			if (_count < 1) RunClass.MovieMasher['msg'](this + ' requires the ' + _countKey + ' attribute to be greater than zero');
			else
			{
			
				if (args == null) result = new Object();
				else result = args;
				
				if (result[_countKey] == null) result[_countKey] = String(_count); 
				if (result[_indexKey] == null) result[_indexKey] = String(_index + _indexStart);
				
				
				if (result[_termsKey] == null)
				{
					k = getValue(_termsKey).string;
					if (k.length) result[_termsKey] = k;
				}
				if (result[_sortKey] == null)
				{
					k = getValue(_sortKey).string;
					if (k.length) result[_sortKey] = k;
				}
				
				for (k in _attributes)
				{
					if (result[k] != null) continue;
					switch (k)
					{
						case 'terms':
						case _termsKey:
						case 'sort':
						case _sortKey:
						case 'index':
						case _indexKey:
						case 'count':
						case _countKey:
						case 'id':
						case 'symbol':
						case 'config':
						case 'url':
							break;
						default:
							if ((ignore == null) || (ignore.indexOf(k) == -1))
							{
								result[k] = getValue(k).string;
							}
					}
				}
			}
			return result;
		}
		
		final protected function _loadData(data:String):void
		{
			_stoppedLoading();
			
			// if parameters changed since we requested ignore result
			if (_searchInvalid) 
			{
				__resetRequest();
			}
			else if ((data != null) && data.length) _loadItemsFromData(data);			
		}
		final protected function _stoppedLoading():void
		{
			_requesting = false;
			_dispatchEvent('loading', new Value(0));
		}
		
		
		private function __initRequest():void
		{
			_requesting = true;
			_dispatchEvent('loading', new Value(1));
			if (__requestTimer == null)
			{
				__requestTimer = new Timer(250, 1);
				__requestTimer.addEventListener(TimerEvent.TIMER, __requestURLTimed);
				__requestTimer.start();
			}
				
		}
		private function __requestURLTimed(event:TimerEvent):void
		{
			try
			{
				if (__requestTimer != null)
				{
					__requestTimer.removeEventListener(TimerEvent.TIMER, __requestURLTimed);
					__requestTimer.stop();
					__requestTimer = null;
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__requestURLTimed __requestTimer', e);
			}
			try
			{
				_makeRequest();
				
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__requestURLTimed _makeRequest', e);
			}
		}
		private function __resetRequest():void
		{
			_searchInvalid = false;
			_index = 0;
			_more = true;
			items = new Array();
			__initRequest();
		}
		private function __urlLoad(event:Event):void
		{
			try
			{
				_loader.removeEventListener(Event.COMPLETE, __urlLoad);
				var data:String = _loader.data();
				_loadData(data);
				_loader = null;
				
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__urlLoad', e);
			}				
		}
		
		private var __requestTimer:Timer = null;
		protected var _count:int = -1;
		protected var _countKey:String = 'count';
		protected var _index:Number = -1;
		protected var _indexKey:String = 'index';
		protected var _indexStart:int = 0;
		protected var _loader:IDataFetcher;
		protected var _requesting:Boolean = false;
		protected var _more:Boolean = false;
		
	}
}

		