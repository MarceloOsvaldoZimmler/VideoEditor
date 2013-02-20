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
	
	import com.moviemasher.type.*;
	import com.moviemasher.constant.*;
	import com.moviemasher.display.*;
	import com.moviemasher.events.*;
	import com.moviemasher.interfaces.*;
	import com.moviemasher.type.*;
	import com.moviemasher.constant.*;
	import flash.display.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.net.*;
	import flash.system.*;
	import flash.text.*;
	import flash.utils.*;
/**
* Implementation class for configuration manager
*
* @see StageManager
* @see MoviemasherStage
* @see MovieMasher
*/
	public class ConfigManager extends Sprite
	{
		
		public function ConfigManager()
		{ 
			__loaders = new Dictionary();
		}
		public function setOption(type:String, property:String, value:String):void
		{
			var xml:XML = getOptionXML(type, property);
			if (xml != null) xml.@[property] = value;
		}
		public function getOptionXML(type:String, having_attribute:String = null):XML
		{
			var option_xml:XML = null;
			switch (type)
			{
				case TagType.FONT:
				case 'server':
					break;
				default:
					var list:Array = searchTags(TagType.OPTION, type, CommonWords.TYPE);
					
					for each (option_xml in list)
					{
						if (! ( (having_attribute != null) && having_attribute.length))
						{
							break;
						}
						if (String(option_xml.@[having_attribute]).length)
						{
							break;
						}
						option_xml = null;
					}
					
					if (option_xml == null)
					{
						option_xml = <option />;
						option_xml.@type = type;
						if ( (having_attribute != null) && having_attribute.length)
						{
							option_xml.@[having_attribute] = '';
						}
						__optionTags.appendChild(option_xml);
					}
			}
			return option_xml;
		}
		public function loadConfiguration(url_string : String, container:XML = null):Boolean
		{
			var loading : Boolean = false;
			if (__loadManager != null)
			{
				var loader:IDataFetcher;
				if (url_string.length)
				{
					if (url_string.indexOf('{') > -1) url_string = RunClass.ParseUtility['optionBrackets'](url_string);
					loader = __loadManager.dataFetcher(url_string);
					__loaders[loader] = container;
					loader.addEventListener(Event.COMPLETE, __configDidLoad);
					__loading++;
					loading = true;
				}
			}
			return loading;
		}
		public function loaded():Number
		{
			return __loaded / __loading;
		}	
		public function parseConfig(parse_xml:XML, parent_xml:XML = null):void
		{
			if (! __startedConfiguration)
			{
				__startedConfiguration = true;
				__loadManager.preconfigure();
			}
			var xml_list:XMLList = parse_xml.children();
			var z:int = xml_list.length();
			var has_children:Boolean = Boolean(z);
			var option_xml:XML;
			var i:int;
			try
			{
				if (has_children)
				{
					xml_list = parse_xml..option;
					if (xml_list.length())
					{
						for each(option_xml in xml_list)
						{
							__parseOption(option_xml);
						}
						if (parent_xml == null) delete parse_xml.option; // does not delete ones in other tags
					}
				}
				if (has_children)
				{
					xml_list = parse_xml..control;
					__loadSymbols(xml_list);
					
					xml_list = parse_xml.source;
					__loadSymbols(xml_list);
					
					if (__moveTags(xml_list.copy(), __sourceTags))
					{
						delete parse_xml.source;
					}
					if ((parent_xml == null) || (parent_xml.name() != 'source'))
					{
						xml_list = parse_xml.media;
						if (__moveMediaTags(xml_list.copy(), searchTag(TagType.SOURCE, TagType.MEDIA)))
						{
							delete parse_xml.media;
						}
					}
					xml_list = parse_xml.mash;
					if (__moveTags(xml_list.copy(), searchTag(TagType.SOURCE, TagType.MASH)))
					{
						delete parse_xml.mash;
					}
				
					// search for nested, to support deprecated panels tag
					xml_list = parse_xml..panel;
					
					if (__moveTags(xml_list.copy(), __panelsTags))
					{
						// just delete top tier panel tags, leaving ones in panels
						delete parse_xml.panel;
						// look for panels and its potential config attribute
						xml_list = parse_xml.panels;
						if (xml_list.length())
						{
							option_xml = xml_list[0];
							if (String(option_xml.@config).length)
							{
								loadConfiguration(option_xml.@config, __panelsTags);
							}
							delete parse_xml.panels;
						}
					}
					
					xml_list = parse_xml.handler;
					
					if (__moveTags(xml_list.copy(), __handlerTags))
					{
						delete parse_xml.handler;
					}
				}
				__moveTags(parse_xml.children(), ((parent_xml == null) ? __otherTags : parent_xml));
				
				
				if (String(parse_xml.@config).length)
				{
					loadConfiguration(parse_xml.@config, parent_xml);
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg']('ConfigManager.parseConfig caught ' + e);
			}
		}
		public function searchTag(tag_name:String, attr_value:String = null, attr_name:String = CommonWords.ID, search:XML = null):XML
		{
			var item:XML = null;
			var tags:Array = searchTags(tag_name, attr_value, attr_name, search);
			if (tags.length)
			{
				item = tags[0];
			}
			if ((item == null) && (tag_name == TagType.SOURCE) && (attr_name == CommonWords.ID))
			{
				switch (attr_value)
				{
					case TagType.MEDIA:
					case TagType.MASH:
						item = new XML("<source id='" + attr_value + "' />");
						__sourceTags.appendChild(item);
						break;
				}
			}
			
			return item;
		}
		public function searchTags(tag_name:String, attr_value:String = null, attr_name:String = CommonWords.ID, search:XML = null):Array
		{
			var tags:Array = new Array();
			if (search == null)
			{
				switch(tag_name)
				{
					case TagType.PANEL:
						search = __panelsTags;
						break;
					case TagType.MEDIA:
						search = __sourceTags;
						break;
					case TagType.MASH:
					case TagType.CLIP:
						search = searchTag(TagType.SOURCE, TagType.MASH);
						break;
					case TagType.SOURCE:
						search = __sourceTags;
						break;
					case TagType.OPTION:
						search = __optionTags;
						break;
					case TagType.HANDLER:
						search = __handlerTags;
						break;
					default:
						//search = xml;
				}
			}
			if (search != null)
			{
				try
				{
					var xml_list:XMLList = search.descendants(tag_name);
					
					if ((xml_list != null) && xml_list.length())
					{
						for each (var descendant:XML in xml_list)
						{
							if ((attr_value == null) || (String(descendant.@[attr_name]) == attr_value))
							{
								tags.push(descendant);
							}
						}
					}
				}
				catch(e:*)
				{
					RunClass.MovieMasher['msg'](ConfigManager + '.searchTags', e);
				}
			}
			return tags;
		}
		public function setManagers(iLoadManager:LoadManager, iStageManager:StageManager):void
		{
			__loadManager = iLoadManager;	
		}
		public function source(urlOrID:String):ISource
		{
			//RunClass.MovieMasher['msg'](this + '.source ' + urlOrID);
			
			var isource:ISource = null;
			if (urlOrID.length)
			{
				var src_xml:XML;
				var is_url:Boolean;
				var local:Boolean = false;
				var media_tag:XML;
				var id:String = urlOrID;
				if (id.substr(0, 1) == '<')
				{
					// it's xml
					try
					{
					
						if (id.substr(0, 12) != '<moviemasher') id = '<moviemasher>' + id + '</moviemasher>';
						src_xml = new XML(id);
						isource = new SourceClass.LocalSource() as ISource;
						var media_tags:XMLList = src_xml.media;
						/*
						var mash_tags:XMLList = src_xml.mash;
						var mash_tag:XML = null;
						if (mash_tags.length()) 
						{
							mash_tag = mash_tags[0];
						
							for each(media_tag in media_tags)
							{
								mash_tag.appendChild(media_tag);
							}
						}
						//RunClass.MovieMasher['msg'](this + '.source XML ' + media_tags.length());
						*/
						if (media_tags.length())
						{
							var parse_xml:XML = <moviemasher/>;
						
							parse_xml.setChildren(media_tags);
						
							parseConfig(parse_xml);
							delete src_xml.media;
						}
						//RunClass.MovieMasher['msg'](this + '.source XML ' + src_xml.toXMLString());
						isource.tag = src_xml;
					}
					catch(e:*)
					{
						RunClass.MovieMasher['msg'](id);
					}
				}
				else
				{
					is_url = ((id.indexOf('/') + id.indexOf('.')) != -2);
					if (is_url) 
					{
						id = RunClass.MD5['hash'](id);
						isource = SourceClass.Source['getSourceByID'](id) as ISource;
					}
					if (isource == null)
					{
						if (is_url)
						{
							//RunClass.MovieMasher['msg'](this + '.source creating remote source ' + urlOrID);
							isource = new SourceClass.RemoteSource() as ISource;
							urlOrID = "<source id='" + id + "' url='" + urlOrID + "' />";
							src_xml = new XML(urlOrID);
							isource.tag = src_xml;
						}
						else 
						{
							isource = RunClass.MovieMasher['getByID'](id) as ISource;
							//RunClass.MovieMasher['msg'](this + '.source ' + urlOrID + ' found ' + isource);
						}
					}
					//else RunClass.MovieMasher['msg'](this + '.source found ' + urlOrID);
				}
			}
			else isource = new SourceClass.Source() as ISource;
			return isource;
		}
		public function fontTag(font:String, mash:* = null):XML
		{
			if (__fontIDs[font] == null)
			{
				var option_tags:Array = searchTags(TagType.OPTION, TagType.FONT, CommonWords.TYPE);
				
				var font_tag:XML = null;
				var mash_tag:XML = null;
				if (mash != null) 
				{
					if (mash is IMash) mash_tag = (mash as IMash).tag;
					else if (mash is XML) mash_tag = mash;
				}
				if (option_tags.length)
				{
					for each(font_tag in option_tags)
					{
						if (font_tag.@id == font)
						{
							break;
						}
						font_tag = null;
					}
					if ((font_tag == null) && (font == 'default'))
					{
						font_tag = option_tags[0];
					}
				}
				if ((font_tag == null) && (mash_tag != null))
				{
					
					option_tags = searchTags(TagType.OPTION, TagType.FONT, CommonWords.TYPE, mash_tag);
					if (option_tags.length)
					{
						for each(font_tag in option_tags)
						{
							if (font_tag.@id == font)
							{
								break;
							}
							font_tag = null;
						}
						if ((font_tag == null) && (font == 'default'))
						{
							font_tag = option_tags[0];
						}
					}
				}
				if (font_tag != null)
				{
					__fontIDs[font] = font_tag;
				}
			}
			return __fontIDs[font];
		}
		private function __configDidLoad(event:Event):void
		{
			
			
			var load_xml:XML;
			var loader:IDataFetcher;
			try
			{
				event.target.removeEventListener(Event.COMPLETE, __configDidLoad);
				loader = event.target as IDataFetcher;
				
				load_xml = loader.xmlObject();
				if (load_xml != null)
				{
					parseConfig(load_xml, __loaders[loader]);
				}
				delete __loaders[loader];
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg']('ConfigManager.__configDidLoad caught ' + e);
			}
			__somethingLoaded(loader);
		}
		private function __somethingLoaded(fetcher:IFetcher):void
		{
			__loaded++;
			if (__loading == __loaded)
			{
				__expandStyles(__panelsTags);
			}
			dispatchEvent(new Event(EventType.LOADING));
		}
		private function __expandStyles(xml:XML, styles:Array = null):void
		{
			try
			{
				var list:XMLList;
				var child:XML;
				var style:String;
				var style_refs:Array;
				var attribute:XML;
				var defined:Object = new Object();
				var i,z:int;
				var name:String;
				name = xml.name();
				if (name != 'option')
				{
					style = String(xml.@style);
					if (style.length)
					{
						if (styles == null) styles = searchTags(TagType.OPTION, 'style', 'type');
						z = styles.length;
						if (! z) RunClass.MovieMasher['msg']('Could not find any style tags');
						else
						{
							list = xml.@*;
							for each (attribute in list)
							{	
								name = attribute.name();
								defined[name] = true;
							}	
							style_refs = style.split(',');
							
							for each (style in style_refs)
							{
								for (i = 0; i < z; i++)
								{
									child = styles[i];
									if (child.@id == style) break;
									child = null;
								}
								if (child != null)
								{
									list = child.@*;
									for each (attribute in list)
									{	
										name = attribute.name();
										if (! defined[name]) // don't overwrite orignal tags
										{
											switch (name)
											{
												case 'style':
												case 'id':
												case 'type': break;
												default: 
													xml.@[name] = child.@[name];
											}
										}
									}
								}
								else RunClass.MovieMasher['msg']('Could not find option tag of type style with ID: ' + style);				
							}
						}
					}
					list = xml.children();
					for each (child in list)
					{
						__expandStyles(child, styles);
					}
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__expandStyles', e);
			}
		}
		private function __loadSymbols(xml_list:XMLList):void
		{
			var option_xml:XML;	
			for each(option_xml in xml_list)
			{
				__loadSymbol(option_xml.@symbol);
			}
		}
		private function __loadSymbol(url_string:String):void
		{
			if (url_string.length)
			{
				if (url_string.indexOf('{') > -1) url_string = RunClass.ParseUtility['optionBrackets'](url_string);
				var loader:IAssetFetcher = __loadManager.assetFetcher(url_string, '');
				if ((loader.state == EventType.LOADING) && (__loaders[loader] == null))
				{
					//RunClass.MovieMasher['msg'](this + '.__loadSymbol ' + url_string + ' ' + loader.key);
					__loaders[loader] = url_string;
					loader.addEventListener(Event.COMPLETE, __symbolLoaded);
					
					__loading++;
				
				}
			}
		}
		private function __moveMediaTags(xml_list:XMLList, move_to:XML):Boolean
		{
			var z:Number = xml_list.length();
			var i:Number;
			try
			{
				if (z)
				{
					for (i = 0; i < z; i++)
					{
						if (! searchTags(TagType.MEDIA, xml_list[i].@id, CommonWords.ID).length) move_to.appendChild(xml_list[i]);
					}
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__moveMediaTags', e);
			}
			return (z > 0);
		
		}
		private function __moveTags(xml_list:XMLList, move_to:XML):Boolean
		{
			var z:Number = xml_list.length();
			var config_list:XMLList;
			var i:Number;
			try
			{
				if (z)
				{
					config_list = xml_list..@config;
					z = config_list.length();
					for (i = 0; i < z; i++)
					{
						// parent of the attribute is the tag itself
						loadConfiguration(config_list[i], config_list[i].parent()); 
					}
					
					move_to.appendChild(xml_list);
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__moveTags', e);
			}
			return (z > 0);
				
		}
		
		private function __parseOption(parse_xml:XML):void
		{
			try
			{
			
				var option_type:String = String(parse_xml.@type);
				if (option_type.length)
				{
					var parent:XML;
					switch(option_type)
					{
						case 'server':
							__loadManager.addPolicy(parse_xml.@policy);
							// fallthrough to font
						case TagType.FONT:
							parent = parse_xml.parent();
							parse_xml = parse_xml.copy();
							__optionTags.appendChild(parse_xml);
							break;
						case 'style':
							__loadSymbol(parse_xml.@symbol);
							__optionTags.appendChild(parse_xml.copy());
							break;
						default:
							var option_xml:XML = getOptionXML(option_type);
							var name:String;
							var attr_list:XMLList = parse_xml.@*;
							for each(var attribute:XML in attr_list)
							{
								name = attribute.name();
								if (name != CommonWords.TYPE)
								{
									option_xml.@[name] = String(attribute);
								}
							}
					}
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__parseOption', e);
			}
		}
		private function __symbolLoaded(event:Event):void
		{
			try
			{
				var i_loader:IAssetFetcher = event.target as IAssetFetcher;
				//RunClass.MovieMasher['msg'](this + '.__symbolLoaded ' + i_loader.key);
				event.target.removeEventListener(Event.COMPLETE, __symbolLoaded);
				
				var loader:Loader = i_loader.loader();
				if (loader != null) RunClass.MovieMasher['instance'].addChild(loader);

				delete __loaders[i_loader];
				__somethingLoaded(i_loader);
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__symbolLoaded', e);
			}
		}
		private static var __fontIDs:Object = new Object();
		private var __handlerTags = <moviemasher id="handlers"><handler id='mp3' url='@MP3Handler' /></moviemasher>;
		private var __loaded:Number = 0;
		private var __loaders:Dictionary;
		private var __loading:Number = 0;
		private var __loadManager:LoadManager = null;
		private var __startedConfiguration:Boolean;
		private var __optionTags = <moviemasher id="options"><option type='parse' evaluate_delimiter=';' /><option type='mash' quantize='10' transitionseconds='1' frameseconds='2' imageseconds='1' themeseconds='3' effectseconds='4' /></moviemasher>; 
		private var __otherTags = <moviemasher id="others"/>;
		private var __panelsTags = <moviemasher id="panels"/>;
		private var __sourceTags = <moviemasher id="sources"/>;
		public static var sharedInstance:ConfigManager;  // access by MovieMasher
		
	}
}

