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
	import com.adobe.xml.syndication.Namespaces;
	import com.adobe.xml.syndication.NewsFeedElement;
	import com.adobe.xml.syndication.ParsingTools;

	/**
	 * Class that represents an RSS 1.0 image.
	 *
	 * An image to be associated with an HTML rendering of the channel. This
	 * image should be of a format supported by the majority of Web browsers.
	 * While the later 0.91 specification allowed for a width of 1-144 and
	 * height of 1-400, convention (and the 0.9 specification) dictate 88x31.
	 * 
	 * @langversion ActionScript 3.0
	 * @playerversion Flash 8.5
	 * @tiptext
	 * 
	 * @see http://web.resource.org/rss/1.0/spec#s5.4
	 */	
	public class Image10
		extends NewsFeedElement
			implements IImage
	{
		private var rss:Namespace = Namespaces.RSS_NS;
		private var rdf:Namespace = Namespaces.RDF_NS;

		/**
		 * Create a new Image10 instance.
		 * 
		 * @param x The XML with which to construct the image.
		 *
		 * @langversion ActionScript 3.0
		 * @playerversion Flash 8.5
		 * @tiptext
		 */
		public function Image10(x:XMLList)
		{
			super(x);
		}

		/**
		 * URL to the image. If present, must also be present in channel
		 * element.
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
		 * The alternative text ("alt" attribute) associated with the channel's
		 * image tag when rendered as HTML.
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
		 * The URL to which an HTML rendering of the channel image will link.
		 * This, as with the channel's title link, is commonly the parent site's home or news page.
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
		 * The URL of the image to used in the "src" attribute of the channel's
		 * image tag when rendered as HTML.
		 * 
		 * @langversion ActionScript 3.0
		 * @playerversion Flash 8.5
		 * @tiptext
		 */
		public function get url():String
		{
			return ParsingTools.nullCheck(this.x.rss::url);
		}
	}
}