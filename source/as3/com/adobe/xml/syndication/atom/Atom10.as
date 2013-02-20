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
	import com.adobe.xml.syndication.NewsParser;
	import com.adobe.xml.syndication.ParsingTools;
	
	/**
	*	Class that represents an Atom 1.0 XML document.
	* 
	* 	@langversion ActionScript 3.0
	*	@playerversion Flash 8.5
	*	@tiptext
	* 
	* 	@see http://www.atomenabled.org/developers/syndication/atom-format-spec.php
	*/	
	public class Atom10
		extends NewsParser
		implements IAtom
	{
		private var atom:Namespace = Namespaces.ATOM_NS;
		private var _feedData:FeedData10;
		private var _entries:Array;

		/**
		*	Constructor for class.
		* 
		* 	@langversion ActionScript 3.0
		*	@playerversion Flash 8.5
		*	@tiptext
		*/	
		public function Atom10()
		{
			super();
		}

		/**
		*	The FeedData object associated with the feed. 
		*
		*	This contains metadata and other data associated with the feed.
		* 
		* 	@langversion ActionScript 3.0
		*	@playerversion Flash 8.5
		*	@tiptext
		*/	
		public function get feedData():IFeedData
		{
			if (this._feedData == null)
			{
				this._feedData = new FeedData10(XMLList(this.x));
			}
			return this._feedData;
		}

		/**
		*	An Array of Entry classes that represent all of the entry elements within
		*	the feed.
		* 
		* 	@langversion ActionScript 3.0
		*	@playerversion Flash 8.5
		*	@tiptext
		*/	
		public function get entries():Array
		{
			if (ParsingTools.nullCheck(this.x.atom::entry) == null)
			{
				return null;
			}

			if (this._entries == null)
			{
				this._entries = new Array();
				var i:XML;
				for each (i in this.x.atom::entry)
				{
					this._entries.push(new Entry10(XMLList(i)));
				}
			}
			return this._entries;
		}
	}
}