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
	import com.adobe.xml.syndication.NewsParser;
	import com.adobe.xml.syndication.ParsingTools;

	/**
	 * Class for parsing RSS 1.0 feeds. Note: the RSS20 class can be used
	 * to parse RSS versions 0.91, 0.92, and 2.0. It cannot be used to parse
	 * RSS 1.0. Use the RSS10 class instead.
	 * 
	 * @langversion ActionScript 3.0
	 * @playerversion Flash 8.5
	 * @tiptext
	 * 
	 * @see http://web.resource.org/rss/1.0/
	 */	
	public class RSS20
		extends NewsParser
			implements IRSS
	{
		private var _channel:Channel20;
		private var _image:Image20;
		private var _items:Array;

		/**
		 * Create a new RSS20 instance.
		 *
		 * @langversion ActionScript 3.0
		 * @playerversion Flash 8.5
		 * @tiptext
		 */
		public function RSS20()
		{
			super();
		}

		/**
		 * The Channel20 object associated with this feed.
		 * 
		 * @langversion ActionScript 3.0
		 * @playerversion Flash 8.5
		 * @tiptext
		 */
		public function get channel():IChannel
		{
			if (this._channel == null)
			{
				this._channel = new Channel20(this.x.channel);
			}
			return this._channel;
		}

		/**
		 * The Image20 object associated with this feed.
		 * 
		 * @langversion ActionScript 3.0
		 * @playerversion Flash 8.5
		 * @tiptext
		 */
		public function get image():IImage
		{
			if (ParsingTools.nullCheck(this.x.channel.image) == null)
			{
				return null;
			}

			if (this._image == null)
			{
				this._image = new Image20(this.x.channel.image);
			}

			return this._image;
		}

		/**
		 * An array of Item20 objects associated with this feed.
		 * 
		 * @langversion ActionScript 3.0
		 * @playerversion Flash 8.5
		 * @tiptext
		 */
		public function get items():Array
		{
			if (ParsingTools.nullCheck(this.x.channel.item) == null)
			{
				return null;
			}

			if (this._items == null)
			{
				this._items = new Array();
				var i:XML;
				for each (i in this.x.channel.item)
				{
					this._items.push(new Item20(XMLList(i)));
				}
			}
			return this._items;
		}
	}
}