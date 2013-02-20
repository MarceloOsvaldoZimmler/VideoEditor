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

package com.adobe.xml.syndication.atom
{
	import com.adobe.utils.DateUtil;
	import com.adobe.xml.syndication.Namespaces;
	import com.adobe.xml.syndication.NewsFeedElement;
	import com.adobe.xml.syndication.ParsingTools;

	/**
	*	Class that represents a feed element within an Atom feed
	* 
	* 	@langversion ActionScript 3.0
	*	@playerversion Flash 8.5
	*	@tiptext
	* 
	* 	@see http://www.atomenabled.org/developers/syndication/atom-format-spec.php#rfc.section.4.1.1
	*/
	public class FeedData10
		extends NewsFeedElement
		implements IFeedData
	{
		private var atom:Namespace = Namespaces.ATOM_NS;
		
		/**
		*	Constructor for class.
		* 
		*	@param x An XML document that contains a feed element from within
		*	an Aton XML feed.
		*
		* 	@langversion ActionScript 3.0
		*	@playerversion Flash 8.5
		*	@tiptext
		*/			
		public function FeedData10(x:XMLList)
		{
			super(x);
		}

		/**
		*	The title element for the Feed.
		* 
		*
		* 	@langversion ActionScript 3.0
		*	@playerversion Flash 8.5
		*	@tiptext
		*/
		public function get title():Title
		{
			var title:Title = new Title();
			title.type = ParsingTools.nullCheck(this.x.atom::title.@type);
			title.value = ParsingTools.nullCheck(this.x.atom::title);
			return title;
		}

		/**
		*	The subtitle element for the Feed.
		* 
		*
		* 	@langversion ActionScript 3.0
		*	@playerversion Flash 8.5
		*	@tiptext
		*/
		public function get subtitle():SubTitle
		{
			var subtitle:SubTitle = new SubTitle();
			subtitle.type = ParsingTools.nullCheck(this.x.atom::subtitle.@type);
			subtitle.value = ParsingTools.nullCheck(this.x.atom::subtitle);
			return subtitle;
		}
		
		/**
		*	A date specifying when the Feed was last updated.
		* 
		*
		* 	@langversion ActionScript 3.0
		*	@playerversion Flash 8.5
		*	@tiptext
		*/		
		public function get updated():Date
		{
			return ParsingTools.dateCheck(this.x.atom::updated, DateUtil.parseW3CDTF);
		}

		/**
		*	The subtitle element for the Feed.
		* 
		*
		* 	@langversion ActionScript 3.0
		*	@playerversion Flash 8.5
		*	@tiptext
		*/
		public function get id():String
		{
			return ParsingTools.nullCheck(this.x.atom::id);
		}

		/**
		*	An Array of Author classes representing all of all of the authors for 
		*	the feed
		* 
		*
		* 	@langversion ActionScript 3.0
		*	@playerversion Flash 8.5
		*	@tiptext
		*/
		public function get authors():Array
		{
			var authors:Array = new Array();
			var i:XML;
			for each (i in this.x.atom::author)
			{
				var author:Author = new Author();
				author.name = ParsingTools.nullCheck(i.atom::["name"]);
				author.email = ParsingTools.nullCheck(i.atom::email);
				author.uri = ParsingTools.nullCheck(i.atom::uri);
				authors.push(author);
			}
			return authors;
		}

		/**
		*	An Array of Contributor classes representing all of all of the 
		*	contributors for the feed
		* 
		*
		* 	@langversion ActionScript 3.0
		*	@playerversion Flash 8.5
		*	@tiptext
		*/
		public function get contributors():Array
		{
			var contributors:Array = new Array();
			var i:XML;
			for each (i in this.x.atom::contributor)
			{
				var contributor:Contributor = new Contributor();
				contributor.name = ParsingTools.nullCheck(i.atom::["name"]);
				contributor.email = ParsingTools.nullCheck(i.atom::email);
				contributor.uri = ParsingTools.nullCheck(i.atom::uri);
				contributors.push(contributor);
			}
			return contributors;
		}

		/**
		*	An Array of Categories classes containing all of the categories
		*	associated with the feed
		* 
		*
		* 	@langversion ActionScript 3.0
		*	@playerversion Flash 8.5
		*	@tiptext
		*/
		public function get categories():Array
		{
			var categories:Array = new Array();
			var i:XML;
			for each (i in this.x.atom::category)
			{
				var category:Category = new Category();
				category.term = ParsingTools.nullCheck(i.@term);
				category.scheme = ParsingTools.nullCheck(i.@scheme);
				category.label = ParsingTools.nullCheck(i.@label);
				categories.push(category);
			}
			return categories;
		}

		/**
		*	Links associated with the feed.
		*
		*	This is the preferred URI for retrieving Atom Feed Documents 
		*	representing this Atom feed.
		* 
		*
		* 	@langversion ActionScript 3.0
		*	@playerversion Flash 8.5
		*	@tiptext
		*/
		public function get links():Array
		{
			var links:Array = new Array();
			var i:XML;
			for each (i in this.x.atom::link)
			{
				var link:Link = new Link();
				link.rel = ParsingTools.nullCheck(i.@rel);
				link.type = ParsingTools.nullCheck(i.@type);
				link.hreflang = ParsingTools.nullCheck(i.@hreflang);
				link.href = ParsingTools.nullCheck(i.@href);
				link.title = ParsingTools.nullCheck(i.@title);
				link.length = ParsingTools.nanCheck(i.@length);
				links.push(link);
			}
			return links;
		}

		/**
		*	A rights class that conveys information about the rights held in 
		*	and over the feed.
		* 
		*
		* 	@langversion ActionScript 3.0
		*	@playerversion Flash 8.5
		*	@tiptext
		*/
		public function get rights():Rights
		{
			var rights:Rights = new Rights();
			rights.type = ParsingTools.nullCheck(this.x.atom::rights.@type);
			rights.value = ParsingTools.nullCheck(this.x.atom::rights);
			return rights;
		}

		/**
		*	A Generator class that contains information about the agent used to
		*	generate the feed.
		* 
		*
		* 	@langversion ActionScript 3.0
		*	@playerversion Flash 8.5
		*	@tiptext
		*/
		public function get generator():Generator
		{
			var generator:Generator = new Generator();
			generator.uri = ParsingTools.nullCheck(this.x.atom::generator.@uri);
			generator.version = ParsingTools.nullCheck(this.x.atom::generator.@version);
			generator.value = ParsingTools.nullCheck(this.x.atom::generator);
			return generator;
		}

		/**
		*	An IRI reference [RFC3987] which identifies an image which provides 
		*	iconic visual identification for a feed.
		* 
		*
		* 	@langversion ActionScript 3.0
		*	@playerversion Flash 8.5
		*	@tiptext
		*/
		public function get icon():String
		{
			return ParsingTools.nullCheck(this.x.atom::icon);
		}

		/**
		*	An IRI reference [RFC3987] which identifies an image which provides
		*	visual identification for a feed.
		* 
		*
		* 	@langversion ActionScript 3.0
		*	@playerversion Flash 8.5
		*	@tiptext
		*/
		public function get logo():String
		{
			return ParsingTools.nullCheck(this.x.atom::logo);
		}
	}
}