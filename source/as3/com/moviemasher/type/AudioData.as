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

package com.moviemasher.type
{
	import com.moviemasher.constant.*;
	import flash.utils.*;
/**
* Class representing audio samples and volume
*/
	public class AudioData
	{
		
		public function AudioData()
		{
			byteArray = new ByteArray();
			//byteArray.length = 8 * Sampling.BLOCK_SIZE; // two four byte floats per sample
		}
		public var byteArray:ByteArray;
		public var volume:Number = 1;
		
	}
}