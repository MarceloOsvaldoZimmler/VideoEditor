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
	import flash.display.*;
	import com.moviemasher.type.*;
	import com.moviemasher.constant.*;

/**
* Interface for all objects that buffer and unbuffer.
*
* @see IClip
* @see IMash
* @see IModule
* @see Time
* @see TimeRange
*/
	public interface IBuffered extends IMetrics
	{
/**
* Preload receiver's assets for every moment within range.
* 
* @param range TimeRange to buffer
* @param mute Boolean indicating whether or not to include audio
*/
		function buffer(range:TimeRange, mute:Boolean):void;
/**
* Ask receiver if its time can be set to every moment within range.
* 
*
* @param range TimeRange to check
* @param mute Boolean indicating whether or not to include audio
* @returns Boolean true if range is buffered
*/
		function buffered(range:TimeRange, mute:Boolean):Boolean;
		
/**
* Retrieve receiver's audio data for a sample range.
* @param position uint sample offset from start
* @param length int samples to return
* @param samples_per_frame uint based on mash quantization
* @returns Vector.<AudioData> with sample and volume information
* @see AudioData
*/
		function getAudioDatum(position:uint, length:int, samples_per_frame:int):Vector.<AudioData>;
/**
* Tell receiver a range is no longer needing to be buffered.
* 
* If receiver has retained external assets used exclusively within range it 
* should release them during this call
*  
* @param range TimeRange to unbuffer
* @see LoadManager
*/
		function unbuffer(range:TimeRange):void;
/**
* Tell receiver to completely unbuffer all assets.
* 
*/
		function unload():void;
/**
* Retrieve receiver's background color, or null.
*  
* @returns String containing six character hex color
*/
		function get backColor():String;
/**
* Tell receiver to display a previously buffered moment.
*  
* @param object Time in Player quantization to display
* @see IPlayer
*/
		function set time(object:Time):void;

	}
}