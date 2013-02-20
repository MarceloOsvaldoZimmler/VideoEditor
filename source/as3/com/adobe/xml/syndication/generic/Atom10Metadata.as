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
	import com.adobe.xml.syndication.atom.FeedData10;
	import com.adobe.xml.syndication.atom.Link;

	/**
	 * Class that abstracts out the specific characteristics of an Atom feed
	 * into generic metadata. In this case, metadata refers to any data not
	 * contained in an entry (in other words, data about the feed itself).
	 * You create an instance using a FeedData object, then you can access it
	 * in a generic way.
	 * 
	 * @langversion ActionScript 3.0
	 * @playerversion Flash 8.5
	 * @tiptext
	 */	
	public class Atom10Metadata
		implements IMetadata
	{
		private var feedData:FeedData10;

		/**
		 * Create a new Atom10Item instance.
		 *
		 * @param feedData An Atom FeedData object.
		 * 
		 * @langversion ActionScript 3.0
		 * @playerversion Flash 8.5
		 * @tiptext
		 */
		public function Atom10Metadata(feedData:FeedData10)
		{
			this.feedData = feedData;
		}

		/**
		 * This feed's title.
		 *
		 * @langversion ActionScript 3.0
		 * @playerversion Flash 8.5
		 * @tiptext
		 */
		public function get title():String
		{
			return this.feedData.title.value;
		}

		/**
		 * An array of authors.
		 *
		 * @langversion ActionScript 3.0
		 * @playerversion Flash 8.5
		 * @tiptext
		 */
		public function get authors():Array
		{
			if (this.feedData.authors == null || this.feedData.authors.length == 0)
			{
				return null;
			}

			var authors:Array = new Array();
			var author:com.adobe.xml.syndication.atom.Author;
			for each (author in this.feedData.authors)
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
		 * This feed's link.
		 *
		 * @langversion ActionScript 3.0
		 * @playerversion Flash 8.5
		 * @tiptext
		 */
		public function get link():String
		{
			for each (var link:Link in this.feedData.links)
			{
				if (link.rel == "alternate")
				{
					return link.href;
				}
			}
			return null;
		}

		/**
		 * Who ownes the rights to this feed.
		 *
		 * @langversion ActionScript 3.0
		 * @playerversion Flash 8.5
		 * @tiptext
		 */
		public function get rights():String
		{
			return this.feedData.rights.value;
		}

		/**
		 * An image associated with this feed.
		 *
		 * @langversion ActionScript 3.0
		 * @playerversion Flash 8.5
		 * @tiptext
		 */
		public function get image():Image
		{
			var image:Image = new Image;
			image.url = this.feedData.logo;
			return image;
		}

		/**
		 * The date this feed was last published.
		 *
		 * @langversion ActionScript 3.0
		 * @playerversion Flash 8.5
		 * @tiptext
		 */
		public function get date():Date
		{
			return this.feedData.updated;
		}

		/**
		 * A description of this feed.
		 *
		 * @langversion ActionScript 3.0
		 * @playerversion Flash 8.5
		 * @tiptext
		 */
		public function get description():String
		{
			return this.feedData.subtitle.value;
		}
	}
}