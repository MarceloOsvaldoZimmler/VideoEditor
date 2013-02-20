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
	import flash.text.*;
	import com.moviemasher.type.*;
	import com.moviemasher.constant.*;
	
/**
* Implementation class for textbox title effect module
*
* @see IModule
* @see Clip
* @see Mash
*/
	public class Textbox extends Caption
	{
		public function Textbox()
		{
			_defaults.scale = '100,100';
			_defaults.position = '0,0';
			_textField.autoSize = TextFieldAutoSize.NONE;
			
		}
		override protected function _setTextSize():void
		{
			var invertor:Number = (_getClipPropertyNumber('verticalinvert') ? 0 : -100);
			var padding:Number = Math.round((_getClipPropertyNumber(ModuleProperty.PADDING) * _size.height)/100);
			var padx2 = 2 * padding;
			var position:Array = _getClipProperty(ModuleProperty.POSITION).split(',');
			var scale:Array = _getClipProperty(ModuleProperty.SCALE).split(',');
			scale[0] = Number(scale[0]);
			scale[1] = Math.abs(Number(scale[1]));// + invertor
			scale[0] = (scale[0] * _size.width) /100;
			scale[1] = (scale[1] * _size.height) /100;
			
			position[0] = Number(position[0]);
			position[1] = Math.abs(Number(position[1]) + invertor);
			
			position[0] = (position[0] * (_size.width - scale[0])) /100;
			position[1] = (position[1] * (_size.height - scale[1])) /100;
			
			
			_back_mc.x = Math.round(position[0] - (_size.width / 2));
			_back_mc.y = Math.round(position[1] - (_size.height / 2));
			
			_backWidth = scale[0];
			_backHeight = scale[1];
			_textField.visible = ((_backWidth > padx2) && (_backHeight > padx2));
			if (_textField.visible)
			{
				_textField.x = _back_mc.x + padding;
				_textField.y = _back_mc.y + padding;
				_textField.width = _backWidth - padx2;
				_textField.height = _backHeight - padx2;
			}
			_backSize();
		}
	}
}

