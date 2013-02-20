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
/** 
* Interface for fetching text based server side resources and CGI responses. A call to either 
* function in this interface will purge the fetch if it has loaded, so it's up to the caller to 
* store the returned value somehow. Purged fetches should not be reused - create a new one instead. 
*
* @see LoadManager
*/
	public interface IDataFetcher extends IFetcher
	{
/** 
* Retrieves the server response as a String object if loaded. 
* @returns some representation of response or empty string if not yet loaded.
*/
		function data():*;
/** 
* Retrieves the server response as an XML object if loaded.
* @returns XML representation of response string or null if not yet loaded.
*/
		function xmlObject():XML;
	}
}