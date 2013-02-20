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
	import com.moviemasher.type.*;
	import com.moviemasher.constant.*;
	import flash.utils.*;
/**
* Interface for widely used mash functionality.
* * 
* @see Mash
* @see IClip
*/
	public interface IMash extends IPlayer, IBuffered, ISelectable
	{
/**
* Searches mash for audio or effect clips within time and track range.
* 
* @param first int containing first frame
* @param last int containing last frame
* @param ignore Array of {@link IClip} objects to exclude
* @param track int containing first track number
* @param count int containing number of tracks to search
* @returns Array of {@link IClip} objects within ranges
* @see Mash
* @see Timeline
* @see Clip
*/
		function clipsInOuterTracks(first:Number, last:Number, ignore:Array = null, track:int = 0, count:int = 0, type:String = ''):Array;
/**
* Searches mash for all clips of a type within time and track range.
* 
* @param first int containing first frame
* @param last int containing last frame
* @param type String containing ClipType
* @param transitions Boolean true to exclude visual clips within transitions
* @param track int containing first track number
* @param count int containing number of tracks to search
* @returns Array of {@link IClip} objects within ranges
* @see Mash
* @see Timeline
* @see Clip
*/
		function clipsInTracks(first:Number, last:Number, type:String, transitions:Boolean = false, track:int = 0, count:int = 0):Array;		
/**
* Searches mash for best start time on an audio or effect track, avoiding collision.
* 
* @param first int containing first frame
* @param last int containing last frame
* @param type String containing ClipType.AUDIO or ClipType.EFFECT
* @param ignore Array of {@link IClip} objects to exclude
* @param track int containing first track number
* @param count int containing number of tracks to search
* @returns Number containing start time
*/
		function freeTime(first:Number, last:Number, type:String = '', ignore:Array = null, track:int = 0, count:int = 0):Number;
/**
* Searches mash for best track for audio or effect tracks within range, avoiding collision.
* 
* @param first int containing first frame
* @param last int containing last frame
* @param type String containing ClipType.AUDIO or ClipType.EFFECT
* @param count int containing number of tracks to search
* @returns Number containing track
*/
		function freeTrack(first:Number, last:Number, type:String, count:uint):uint;
/**
* Attempts to seek to a moment within the mash, buffering first if needed.
* 
* @returns Boolean true if buffering was not required and moment is now displayed
*/
		function goTime(time:Time = null):Boolean;
/**
* Alert receiver that changes where made to its content that could affect overall duration.
* 
* @param type String containing track type (audio, effect or video) that was changed
* @param dont_dirty Boolean indicating whether or not action causes mash to need a save
* @see MashAction
*/
		function invalidateLength(type:String, dont_dirty:Boolean = false):void;
/**
* The media and font tags used by clips within the receiver.
* 
* @returns Object with unique keys and values containing a media or option XML object
* @see CGI
*/
		function referencedMedia():Object;
/**
* Searches mash for all clips visible at a frame, ignoring track placement and audio clips
* 
* @param time Time describes the frame of interest
* @returns Vector of {@link IClip} objects within range
* @see Mash
* @see Decoder
*/
		function visibleClipsAtTime(time:Time):Vector.<IClip>;
/**
* Moment actually being displayed within displayObject
* 
* @returns Time object quantized to Player's fps
*/
		function get displayTime():Time;		
/**
* The last moment seeked, which may or may not be buffered yet.
* 
* @returns Time object that was last sent to goTime
*/
		function get goingTime():Time;		
/**
* Calculated during playback from the sound channel's position.
* 
* @returns Number containing current latency in seconds
* @see VoiceOver
*/
		function get latency():Number;
/**
* Set during playback as latency is updated.
* 
* @returns Number containing milliseconds as returned by Date.getTime
* @see VoiceOver
*/
		function get latencyUpdated():Number;		
/**
* Creates and returns object representing duration of entire mash.
* 
* @returns Time object with fps set to mash quantization
*/
		function get lengthTime():Time;
/**
* Calculated during playback as each block of audio data is passed to sound buffer.
* 
* @returns uint indicating buffered sample position within mash 
* @see VoiceOver
*/
		function get sample():uint;	
/**
* All the top tier IClip objects in the mash, arranged by track type.
* 
* @returns Object with audio, video and effect keys containing arrays of IClips
*/
		function get tracks():Object;
	}
}