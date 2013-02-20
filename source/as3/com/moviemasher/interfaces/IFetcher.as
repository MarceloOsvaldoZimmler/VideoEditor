/*
* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/.
* 
* Software distributed under the License is distributed on an
* "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express
* or implied. See the License for the specific language
* governing rights and limitations under the License.
* 
* The Original Code is 'Movie Masher'. The Initial Developer
* of the Original Code is Doug Anarino. Portions created by
* Doug Anarino are Copyright (C) 2007-2012 Movie Masher, Inc.
* All Rights Reserved.
*/

package com.moviemasher.interfaces
{
	import flash.events.*;
/**
* Base Interface for fetching of all server side resources.
* One of the sub interfaces must be used in order to do more than load or monitor the fetch.
*
* @see LoadManager
*/
	public interface IFetcher extends IEventDispatcher
	{
/** Retrieves the amount of data that has been fetched or -1 if fetching has not begun.
* @returns Number of bytes currently fetched.
*/
		function get bytesLoaded():Number;
/** Retrieves the total amount of data or -1 if fetching has not begun or the total is not yet known.
* @returns Number of bytes total.
*/
		function get bytesTotal():Number;
/** Retrieves a parsed version of url suitable for use as an Object property name.
* @returns String that is a unique identifier for url.
*/
		function get key():String;
/** Retrieves the current fetch state of server side resource.
* @returns String equal to either {@link EventType.LOADING} or {@link EventType.LOADED}.
*/
		function get state():String;
/** Sets the location of the server side resource.
* @param string String optionally containing location, # or @ symbol, class name or frame label
*/
		function set url(string:String):void;
		
/** Sets the number of times failed requests are retried.
* @param number uint number of tries
*/
		function set retries(number:int):void;
	}
}