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
	*	Class that represents an Entry element within an Atom feed
	* 
	* 	@langversion ActionScript 3.0
	*	@playerversion Flash 8.5
	*	@tiptext
	* 
	* 	@see http://www.atomenabled.org/developers/syndication/atom-format-spec.php#rfc.section.4.1.2
	*/
	public class Entry03
		extends NewsFeedElement
		implements IEntry
	{
		private var atom:Namespace = Namespaces.ATOM_03_NS;
		private var xhtml:Namespace = Namespaces.XHTML_NS;
		private var dc:Namespace = Namespaces.DC_NS;

		public function Entry03(x:XMLList)
		{
			super(x);
		}

		public function get title():String
		{
			return ParsingTools.nullCheck(this.x.atom::title);
		}

		public function get links():Array
		{	
			var links:Array = new Array();
			var i:XML;
			for each (i in this.x.atom::link)
			{
				var link:Link = new Link();
				link.rel = ParsingTools.nullCheck(i.@rel);
				link.type = ParsingTools.nullCheck(i.@type);
				link.href = ParsingTools.nullCheck(i.@href);
				links.push(link);
			}
			return links;
		}

		public function get published():Date
		{
			return ParsingTools.dateCheck(this.x.atom::modified, DateUtil.parseW3CDTF);
		}

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

		public function get content():Content
		{
			var content:Content;
			if (ParsingTools.nullCheck(this.x.atom::content) != null)
			{
				content = new Content();
				content.type = ParsingTools.nullCheck(this.x.atom::content.@mode);
				if (content.type == "xhtml")
				{
					content.value = ParsingTools.nullCheck(this.x.atom::content.xhtml::div);				
				}
				else
				{
					content.value = ParsingTools.nullCheck(this.x.atom::content);
				}
			}
			return content;
		}

		/**
		*	A Summary object that contains the optional summary of the entry.
		*
		* 	@langversion ActionScript 3.0
		*	@playerversion Flash 8.5
		*	@tiptext
		*/	
		public function get summary():Summary
		{
			var summary:Summary;
			if (ParsingTools.nullCheck(this.x.atom::summary) != null)
			{
				summary = new Summary();
				summary.type = ParsingTools.nullCheck(this.x.atom::summary.@type);
				if (summary.type == "xhtml")
				{
					summary.value = ParsingTools.nullCheck(this.x.atom::summary.xhtml::div);				
				}
				else
				{
					summary.value = ParsingTools.nullCheck(this.x.atom::summary);
				}
			}
			return summary;
		}

		public function get categories():Array
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
	}
}