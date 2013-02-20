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
//	import flash.events.*;
	import flash.net.*;
	import com.moviemasher.type.*;
	import com.moviemasher.constant.*;
/**
* Interface for playback handlers
*
* @see Handler
* @see AssetFetcher
*/
	public interface IHandler extends IDisplay
	{
		function get metrics():Size;
		function getAudioDatum(position:uint, length:int, samples_per_frame:int):Vector.<AudioData>;
		function buffer(range:Object):void;
		function buffered(range:Object):Boolean;
		function unload():void;
		function get bytesLoaded():Number;
		function get bytesTotal():Number;
		function get duration():Number;
		function set duration(iNumber:Number):void;
		function get active():Boolean;
		function set active(iBoolean:Boolean):void;
		function set visual(iBoolean:Boolean):void;
		function set loops(iNumber:Number):void;
		

	}
}