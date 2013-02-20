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

package com.adobe.xml.syndication.rss
{
	import com.adobe.utils.DateUtil;
	import com.adobe.xml.syndication.Namespaces;
	import com.adobe.xml.syndication.NewsFeedElement;
	import com.adobe.xml.syndication.ParsingTools;

	/**
	 * Class that represents an RSS 1.0 item.
	 * 
	 * @langversion ActionScript 3.0
	 * @playerversion Flash 8.5
	 * @tiptext
	 * 
	 * @see http://web.resource.org/rss/1.0/spec#s5.5
	 */	
	public class Item10
		extends NewsFeedElement
			implements IItem
	{
		private var rdf:Namespace = Namespaces.RDF_NS;
		private var rss:Namespace = Namespaces.RSS_NS;
		private var dc:Namespace = Namespaces.DC_NS;

		/**
		 * Create a new Item10 instance.
		 * 
		 * @param x The XML with which to construct the item.
		 *
		 * @langversion ActionScript 3.0
		 * @playerversion Flash 8.5
		 * @tiptext
		 */
		public function Item10(x:XMLList)
		{
			super(x);
		}

		/**
		 * The URL of the item element's rdf:about attribute must be unique
		 * with respect to any other rdf:about attributes in the RSS document,
		 * and is a URI which identifies the item. The URL should be identical
		 * to the value of the <link>  sub-element of the <item> element, if
		 * possible.
		 * 
		 * @langversion ActionScript 3.0
		 * @playerversion Flash 8.5
		 * @tiptext
		 */
		public function get about():String
		{
			return ParsingTools.nullCheck(this.x.@rdf::about);
		}

		/**
		 * The item's title.
		 * 
		 * @langversion ActionScript 3.0
		 * @playerversion Flash 8.5
		 * @tiptext
		 */
		public function get title():String
		{
			return ParsingTools.nullCheck(this.x.rss::title);
		}

		/**
		 * The item's URL.
		 * 
		 * @langversion ActionScript 3.0
		 * @playerversion Flash 8.5
		 * @tiptext
		 */
		public function get link():String
		{
			return ParsingTools.nullCheck(this.x.rss::link);
		}

		/**
		 * A brief description/abstract of the item.
		 * 
		 * @langversion ActionScript 3.0
		 * @playerversion Flash 8.5
		 * @tiptext
		 */
		public function get description():String
		{
			return ParsingTools.nullCheck(this.x.rss::description);
		}

		/**
		 * The name and, optionally, email address of the creator of the feed.
		 * 
		 * @langversion ActionScript 3.0
		 * @playerversion Flash 8.5
		 * @tiptext
		 */
		public function get creators():Array
		{
			if (ParsingTools.nullCheck(this.x.dc::creator) == null) return null;
			var creators:Array = new Array();
			var i:XML;
			for each (i in this.x.dc::creator)
			{
				creators.push(i);
			}
			return creators;
		}

		/**
		 * The organization publishing this item.
		 * 
		 * @langversion ActionScript 3.0
		 * @playerversion Flash 8.5
		 * @tiptext
		 */
		public function get publisher():String
		{
			return ParsingTools.nullCheck(this.x.dc::publisher);
		}

		/**
		 * The subject of the item.
		 * 
		 * @langversion ActionScript 3.0
		 * @playerversion Flash 8.5
		 * @tiptext
		 */
		public function get subjects():Array
		{
			if (ParsingTools.nullCheck(this.x.dc::subject) == null) return null;
			var subjects:Array = new Array();
			var i:XML;
			for each (i in this.x.dc::subject)
			{
				subjects.push(i);
			}
			return subjects;
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
			return ParsingTools.dateCheck(this.x.dc::date, DateUtil.parseW3CDTF);
		}

		/**
		 * Who ownes the rights to the content in this item.
		 * 
		 * @langversion ActionScript 3.0
		 * @playerversion Flash 8.5
		 * @tiptext
		 */
		public function get rights():String
		{
			return ParsingTools.nullCheck(this.x.dc::rights);
		}
	}
}