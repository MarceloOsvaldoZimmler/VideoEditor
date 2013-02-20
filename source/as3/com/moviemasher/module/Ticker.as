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
package com.moviemasher.module
{
	import com.moviemasher.type.*;
	import com.moviemasher.constant.*;
/**
* Implementation class for ticker text effect module
*
* @see IModule
* @see Clip
* @see Mash
*/
	public class Ticker extends Caption
	{
		public function Ticker()
		{
			_defaults.textsize = '14';
			_defaults.multiline = '0';
			_defaults.wordwrap = '0';
		}
		override protected function _setTextSize():void
		{
			super._setTextSize();
			var padding:Number = Math.round((_getClipPropertyNumber(ModuleProperty.PADDING) * _size.height)/100);
			var total_distance = _size.width + _textField.textWidth;
			_textField.x = (_size.width/2 - Math.round(total_distance  * _clipCompleted()));
			_textField.y = Math.round((_size.height/2 - (_textField.textHeight + padding)));
		}
	}
}

