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
	import flash.text.*;
	import flash.display.*;
	import com.moviemasher.type.*;
	import com.moviemasher.constant.*;
/**
* Interface for fetching of all server side resources except XML.
* An instance of a class following this interface is returned by the MovieMasher.assetFetcher method.
* 
* @see LoadManager
* @see MovieMasher
*/
	public interface IAssetFetcher extends IFetcher
	{
/**
* Gets a Class object from the fetched SWF asset. 
* If the url parameter is supplied it will overwrite the value supplied during instancing. If the class 
* name within the url isn't fully qualified then it will be assumed to be under com.moviemasher, 
* within the package specified by the type parameter. The location portion of the url parameter can be
* ommitted to get a class already fetched into the current application domain.
* @param url String containing SWF location and @ symbol followed by class name.
* @param type String containing package name, which must be specified if class name isn't fully qualified.
* @returns Class object or null if not found.
*/
		function classObject(url:String='', type:String=''):Class;
/**
* Gets a DisplayObject object from the fetched SWF asset, optionally scaled to certain dimensions.
* If parameters are supplied they will overwrite those supplied during instancing.
* If a class name within the url isn't fully qualified then it will be assumed to be under the 
* com.moviemasher.display package.
* @param url String containing SWF location and either a # or @ symbol, followed by either a frame label.
* in the main timeline of the SWF or the class name of a library item inheriting from DisplayObject.
* @returns DisplayObject object or null if not found.
*/
		function displayObject(url:String, format:String = '', size:Size = null):DisplayObject;
/**
* Gets a Font object from the fetched SWF asset. 
* If the url parameter is supplied it will overwrite the value supplied during instancing. If the class 
* name within the url isn't fully qualified then it will be assumed to be under the 
* com.moviemasher.font package. 
* @param url String containing SWF location and @ symbol followed by class name of font.
* @returns Font object or null if not found.
*/
		function fontObject(url:String = ''):Font;
/**
* Gets an IHandler object for the fetched audio or video asset, to facilitate loading and playback.
* If parameters are supplied they will overwrite those supplied during instancing.
* @param url String containing asset location.
* @param format String containing file extension.
* @returns {@link IHandler} implementation for specified asset or null on error.
*/
		function handlerObject(url:String = '', format:String = ''):IHandler;

/*
* Please do not call this function.
* Called internally to manage loading.
*/
		function loader():Loader;
/**
* Decrements the internal retain count, potentially making audio/video asset available for purging.
* This method should be called for all audio and video files when they are no longer needed.
* @param handler IHandler object that was returned by handlerObject method.
*/
		function releaseAudio(handler:IHandler):void;
/**
* Decrements the internal retain count, potentially making graphic asset available for purging.
* This method should be called for all graphic files when they are no longer needed, except those residing in SWF files. 
* @param display DisplayObject object that was returned by displayObject method.
*/
		function releaseDisplay(display:DisplayObject):void;

/**
* Increments the internal retain count, assuring asset will not be available for purging.
* This method should be for all assets except those residing in SWF files.
*/
		function retain():void;

/*
* Please do not call this function.
* Called from LoadManager during purging.
*/
		function unload():Boolean;
	}
}