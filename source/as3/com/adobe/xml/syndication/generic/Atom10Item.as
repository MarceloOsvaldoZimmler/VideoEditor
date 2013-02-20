/*
	Copyright (c) 2008, Adobe Systems Incorporated
	All rights reserved.

	Redistribution and use in source and binary forms, with or without 
	modification, are permitted provided that the following conditions are
	met:

    * Redistributions of source code must retain the above copyright notice, 
    	this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
		notice, this list of conditions and the following disclaimer in the 
    	documentation and/or other materials provided with the distribution.
    * Neither the name of Adobe Systems Incorporated nor the names of its 
    	contributors may be used to endorse or promote products derived from 
    	this software without specific prior written permission.

	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
	IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
	THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
	PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR 
	CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
	EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
	PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
	PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
	LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
	NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
	SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

package com.adobe.xml.syndication.generic
{

	import com.adobe.xml.syndication.atom.Author;
	import com.adobe.xml.syndication.atom.Entry10;
	import com.adobe.xml.syndication.atom.Link;
	import com.adobe.xml.syndication.atom.Category;

	/**
	 * Class that abstracts out the specific characteristics of an Atom entry
	 * into a generic Item. You create an instance using an Entry object,
	 * then you can access it in a generic way.
	 * 
	 * @langversion ActionScript 3.0
	 * @playerversion Flash 8.5
	 * @tiptext
	 */	
	public class Atom10Item
		implements IItem
	{
		private var entry:Entry10;

		/**
		 * Create a new Atom10Item instance.
		 *
		 * @param entry An Entry object that you want abstracted.
		 * 
		 * @langversion ActionScript 3.0
		 * @playerversion Flash 8.5
		 * @tiptext
		 */
		public function Atom10Item(entry:Entry10)
		{
			this.entry = entry;
		}

		/**
 		 * This item's title.
		 * 
		 * @langversion ActionScript 3.0
		 * @playerversion Flash 8.5
		 * @tiptext
		 */
		public function get title():String
		{
			return this.entry.title;
		}

		/**
 		 * This item's link.
		 * 
		 * @langversion ActionScript 3.0
		 * @playerversion Flash 8.5
		 * @tiptext
		 */
		public function get link():String
		{
			for each (var link:Link in this.entry.links)
			{
				if (link.rel == null || link.rel == "alternate")
				{
					return link.href;
				}
			}
			return null;
		}

		/**
 		 * This item's unique ID.
		 * 
		 * @langversion ActionScript 3.0
		 * @playerversion Flash 8.5
		 * @tiptext
		 */
		public function get id():String
		{
			return this.entry.id;
		}

		/**
 		 * The date this item was published.
		 * 
		 * @langversion ActionScript 3.0
		 * @playerversion Flash 8.5
		 * @tiptext
		 */
		public function get date():Date
		{
			return this.entry.published;
		}

		/**
 		 * One or more authors of this item.
		 * 
		 * @langversion ActionScript 3.0
		 * @playerversion Flash 8.5
		 * @tiptext
		 */
		public function get authors():Array
		{
			if (this.entry.authors == null || this.entry.authors.length == 0)
			{
				return null;
			}

			var authors:Array = new Array();
			var author:com.adobe.xml.syndication.atom.Author;
			for each (author in this.entry.authors)
			{
				var newAuthor:com.adobe.xml.syndication.generic.Author = new com.adobe.xml.syndication.generic.Author();
				newAuthor.name = author.name;
				newAuthor.url = author.uri;
				newAuthor.email = author.email;
				authors.push(newAuthor);
			}
			return authors;
		}

		/**
 		 * One or more categories.
		 * 
		 * @langversion ActionScript 3.0
		 * @playerversion Flash 8.5
		 * @tiptext
		 */
		public function get topics():Array
		{
			if (this.entry.categories == null || this.entry.categories.length == 0)
			{
				return null;
			}

			var topics:Array = new Array();
			for each (var category:Category in this.entry.categories)
			{
				if (category.label != null)
				{
					topics.push(category.label);
				}
				else if (category.term != null)
				{
					topics.push(category.term);
				}
			}
			if (topics.length == 0) return null;
			return topics;
		}

		/**
 		 * An excerpt or description of this item.
		 * 
		 * @langversion ActionScript 3.0
		 * @playerversion Flash 8.5
		 * @tiptext
		 */
		public function get excerpt():Excerpt
		{
			var excerpt:Excerpt = new Excerpt;
			if (this.entry.summary != null)
			{
				excerpt.type = this.entry.summary.type;
				excerpt.value = this.entry.summary.value;
			}
			return excerpt;
		}

		public function get content():String
		{
			if (this.entry.content == null) return null;
			return this.entry.content.value;
		}

		/**
 		 * Any media associated with this item.
		 * 
		 * @langversion ActionScript 3.0
		 * @playerversion Flash 8.5
		 * @tiptext
		 */
		public function get media():Media
		{
			for each (var link:Link in this.entry.links)
			{
				if (link.rel == "enclosure")
				{
					var media:Media = new Media();
					media.type = link.type;
					media.length = link.length;
					media.url = link.href;
					return media;
				}
			}
			return null;
		}
		
		public function get xml():XMLList
		{
			return entry.xml;
		}
	}
}