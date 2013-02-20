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
	import com.adobe.xml.syndication.atom.Entry03;
	import com.adobe.xml.syndication.atom.Link;
	import com.adobe.xml.syndication.atom.Category;

	public class Atom03Item
		implements IItem
	{
		private var entry:Entry03;

		public function Atom03Item(entry:Entry03)
		{
			this.entry = entry;
		}

		public function get title():String
		{
			return this.entry.title;
		}

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

		public function get id():String
		{
			return null;
		}

		public function get date():Date
		{
			return this.entry.published;
		}

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

		public function get topics():Array
		{
			if (this.entry.categories == null || this.entry.categories.length == 0)
			{
				return null;
			}

			return this.entry.categories;
		}

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

		public function get media():Media
		{
			return null;
		}
		
		public function get xml():XMLList
		{
			return entry.xml;
		}
	}
}