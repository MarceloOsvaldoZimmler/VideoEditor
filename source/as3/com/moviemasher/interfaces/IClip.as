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
	import com.moviemasher.constant.*;
	import com.moviemasher.type.*;
	import flash.display.*;
	import flash.geom.*;
/**
* Interface represents a {@link Clip} within a {@link Mash}
* 
* @see IClip
* @see IMash
*/
	public interface IClip extends IValued, ISelectable, IBuffered
	{
/**
* Copies clip by instancing from tag.
* 
* @returns IClip copy of target
*/
	function clone():IClip;
/**
* Whether or not the clip should appear on the visual track.
* 
* @returns Boolean true if clip is {@link Video}, {@link Image} or {@link Transition} 
*/
		function appearsOnVisualTrack():Boolean;
/**
* Translates mash time to {@link Clip} time.
* 
* @param time Time object containing moment to translate
* @returns Time object in Media time without affecting input
*/
		function clipTime(time:Time):Time;


/**
* Allows access to the {@link IMedia} object of target.
* 
* @returns a pointer to the object.
*/
		function get media():IMedia;

/**
* Allows access to the {@link IMash} object of target.
* 
* @returns a pointer to the object.
*/
		function get mash():IMash;
		function set mash(object:IMash):void;
/**
* The media and font tags used by receiver and any clips nested within it.
* 
* @returns Object with unique keys and values containing a media or option XML object
* @see CGI
*/
		function referencedMedia(object:Object):void;

		function get owner():IClip;
		function set owner(clip:IClip):void;
		function get canTrim():Boolean;
		function get index():int;
		function set index(value:int):void;
		function get track():int;
		function set track(value:int):void;
		function get startPadFrame():Number;
		function set startPadFrame(value:Number):void;
		function get endPadFrame():Number;
		function set endPadFrame(value:Number):void;
		function get startFrame():Number;
		function set startFrame(value:Number):void;
		function get lengthFrame():Number;
		function get type():String;
		function get lengthTime():Time;
		function get paddedTimeRange():TimeRange;
		function get startTime():Time; 
		function get timeRange():TimeRange;
	}
}
