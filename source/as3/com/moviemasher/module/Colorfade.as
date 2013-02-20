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
	import flash.display.*;
	import com.moviemasher.utils.*;
	import com.moviemasher.interfaces.*;
	import com.moviemasher.type.*;
	import com.moviemasher.constant.*;
/**
* Implementation class for colorfade image module
*
* @see IModule
* @see Clip
* @see Mash
*/
	public class Colorfade extends Module
	{
		public function Colorfade()
		{
			_defaults['forecolor'] = 'FFFFFF';
			_defaults[ModuleProperty.BACKCOLOR] = '0';
			_defaults['fade'] = Fades.IN;
		}
		override public function get backColor():String
		{
			return RunClass.DrawUtility['hexFromColor'](__blendedColor());
		}
		private function __blendedColor():Number
		{
			var forecolor:Number = RunClass.DrawUtility['colorFromHex'](_getClipProperty('forecolor'));
			var backcolor:Number = RunClass.DrawUtility['colorFromHex'](_getClipProperty(ModuleProperty.BACKCOLOR));
			return RunClass.DrawUtility['blendColor'](_getFade() / 100, forecolor, backcolor);
			
		}
	}
}