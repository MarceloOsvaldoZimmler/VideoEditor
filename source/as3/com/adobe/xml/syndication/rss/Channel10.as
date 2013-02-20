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
	 * Class that represents an RSS 1.0 Channel element.
	 * 
	 * @langversion ActionScript 3.0
	 * @playerversion Flash 8.5
	 * @tiptext
	 * 
	 * @see http://web.resource.org/rss/1.0/spec#s5.3
	 * @see http://web.resource.org/rss/1.0/modules/dc/
	 * @see http://web.resource.org/rss/1.0/modules/syndication/
	 */	
	public class Channel10
		extends NewsFeedElement
			implements IChannel
	{
		public static const UPDATE_PERIOD_HOURLY:String = "hourly";
		public static const UPDATE_PERIOD_WEEKLY:String = "weekly";
		public static const UPDATE_PERIOD_MONTHLY:String = "monthly";
		public static const UPDATE_PERIOD_YEARLY:String = "yearly";

		private var rss:Namespace = Namespaces.RSS_NS;
		private var rdf:Namespace = Namespaces.RDF_NS;
		private var dc:Namespace = Namespaces.DC_NS;
		private var sy:Namespace = Namespaces.SY_NS;

		/**
		 * Create a new Channel10 instance.
		 * 
		 * @param x The XML with which to construct the channel.
		 *
		 * @langversion ActionScript 3.0
		 * @playerversion Flash 8.5
		 * @tiptext
		 */
		public function Channel10(x:XMLList)
		{
			super(x);
		}

		/**
		 * The URL of the channel element's rdf:about attribute must be unique
		 * with respect to any other rdf:about attributes in the RSS document
		 * and is a URI which identifies the channel. Most commonly, this is
		 * either the URL of the homepage being described or a URL where the
		 * RSS file can be found.
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
		 * A descriptive title for the channel.
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
		 * The URL to which an HTML rendering of the channel title will link,
		 * commonly the parent site's home or news page.
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
		 * A brief description of the channel's content, function, source, etc.
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
		 * The organization publishing this feed.
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
		 * The language the feed is in.
		 * 
		 * @langversion ActionScript 3.0
		 * @playerversion Flash 8.5
		 * @tiptext
		 */
		public function get language():String
		{
			return ParsingTools.nullCheck(this.x.dc::language);
		}

		/**
		 * The name and, optionally, email address of the creator of the feed.
		 * 
		 * @langversion ActionScript 3.0
		 * @playerversion Flash 8.5
		 * @tiptext
		 */
		public function get creator():String
		{
			return ParsingTools.nullCheck(this.x.dc::creator);
		}

		/**
		 * The date and time the feed was last updated.
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
		 * Who ownes the rights to the content in the feed.
		 * 
		 * @langversion ActionScript 3.0
		 * @playerversion Flash 8.5
		 * @tiptext
		 */
		public function get rights():String
		{
			return ParsingTools.nullCheck(this.x.dc::rights);
		}

		/**
		 * Describes the period over which the channel format is updated.
		 * Acceptable values are: hourly, daily, weekly, monthly, yearly.
		 * If omitted, daily is assumed.
		 * 
		 * @langversion ActionScript 3.0
		 * @playerversion Flash 8.5
		 * @tiptext
		 */
		public function get updatePeriod():String
		{
			return ParsingTools.nullCheck(this.x.sy::updatePeriod);
		}

		/**
		 * Used to describe the frequency of updates in relation to the update
		 * period. A positive integer indicates how many times in that period
		 * the channel is updated. For example, an updatePeriod of daily, and
		 * an updateFrequency of 2 indicates the channel format is updated
		 * twice daily. If omitted a value of 1 is assumed.
		 * 
		 * @langversion ActionScript 3.0
		 * @playerversion Flash 8.5
		 * @tiptext
		 */
		public function get updateFrequency():String
		{
			return ParsingTools.nullCheck(this.x.sy::updateFrequency);
		}

		/**
		 * Defines a base date to be used in concert with updatePeriod and
		 * updateFrequency to calculate the publishing schedule. The date
		 * format takes the form: yyyy-mm-ddThh:mm
		 * 
		 * @langversion ActionScript 3.0
		 * @playerversion Flash 8.5
		 * @tiptext
		 */
		public function get updateBase():Date
		{
			return ParsingTools.dateCheck(this.x.sy::updateBase, DateUtil.parseW3CDTF);
		}

		/**
		 * Establishes an RDF association between the optional image element
		 * and this particular RSS channel. 
		 * 
		 * @langversion ActionScript 3.0
		 * @playerversion Flash 8.5
		 * @tiptext
		 *
		 * @see http://web.resource.org/rss/1.0/spec#s5.3.4
		 */
		public function get image():String
		{
			return ParsingTools.nullCheck(this.x.rss::image.@rdf::resource);
		}
	}
}