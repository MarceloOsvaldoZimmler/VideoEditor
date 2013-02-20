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

package com.adobe.xml.syndication
{
	/**
	 * Class that contains static members of all the namesapces required for
	 * parsing RSS and Atom feeds.
	 * 
	 * @langversion ActionScript 3.0
	 * @playerversion Flash 8.5
	 * @tiptext
	 */	
	public class Namespaces
	{
		public static var RDF_NS:Namespace = new Namespace("http://www.w3.org/1999/02/22-rdf-syntax-ns#");
		public static var DC_NS:Namespace = new Namespace("http://purl.org/dc/elements/1.1/");
		public static var SY_NS:Namespace = new Namespace("http://purl.org/rss/1.0/modules/syndication/");
		public static var CO_NS:Namespace = new Namespace("http://purl.org/rss/1.0/modules/company/");
		public static var TI_NS:Namespace = new Namespace("http://purl.org/rss/1.0/modules/textinput/");
		public static var RSS_NS:Namespace = new Namespace("http://purl.org/rss/1.0/");
		public static var ATOM_NS:Namespace = new Namespace("http://www.w3.org/2005/Atom");
		public static var ATOM_03_NS:Namespace = new Namespace("http://purl.org/atom/ns#");
		public static var XHTML_NS:Namespace = new Namespace("http://www.w3.org/1999/xhtml");
		public static var CONTENT:Namespace = new Namespace("http://purl.org/rss/1.0/modules/content/");
	}
}