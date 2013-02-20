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

package com.moviemasher.options
{
	
	import flash.text.*;
	import com.moviemasher.type.*;
	import com.moviemasher.constant.*;
	import com.moviemasher.interfaces.*;
	import com.moviemasher.type.*;
	import com.moviemasher.constant.*;
/**
* Implementation base class for preview options
*
* @see Browser
* @see IOptions
*/
	public class PreviewOptions extends BoxOptions
	{
		public function PreviewOptions()
		{
			super();
			try
			{
				// text properties that vary depending on selected and disabled 
				
				_defaults.textbackcolor = 'FFFFFF';
				_defaults.textcolor = '333333';
				_defaults.textbackalpha = '50';
				
				_multiples.over.push('textbackcolor');
				_multiples.over.push(TextProperty.TEXTCOLOR);
				_multiples.over.push('textbackalpha');
				
				// non varying text properties
				_defaults.label = '';
				_defaults.font = 'default';
				_defaults.textalign = 'left';
				_defaults.textvalign = 'bottom';
				_defaults.textsize = '12';
				_defaults.textheight = '20';
				_defaults.textoffset = '0';
				_defaults.preview = '';
				_defaults.type = '';
				
				
				// timeline options
				_defaults.waveblend = 'normal';
				_multiples.over.push('waveblend');
				
				_defaults.x = '';
				_defaults.y = '';
				_defaults.xcrop = '';
				_defaults.starttrans = '';
				_defaults.endtrans = '';
				_defaults.leftcrop = '';
				_defaults.rightcrop = '';
				_defaults.widthcrop = '';
				
				_defaults.wave = '';
				_defaults.effectheight = ''; // height of effect track, if any
				_defaults.videoheight = ''; // height of video track, if any
				_defaults.audioheight = ''; // height of audio track, if any
				_defaults.spacing = ''; // distance between backgrounds
				_defaults.notrim = ''; // whether or not to allow dragging of preview edges
				_defaults.nodrag = ''; // whether or not to allow dragging of preview itself

				_defaults.trimstartframe = '';
				_defaults.startframe = '';
				_defaults.duration = '';
				_defaults.loop = '';
				_defaults.loops = '';
				
				//_defaults.clip = '';
				//_defaults.timeline = '';
				
				
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg']('PreviewOptions', e);
			}
		}
		override public function copy():IOptions
		{
			var options:IOptions = new PreviewOptions();
			options.tag = _tag.copy();
			for (var k:String in _attributes)
			{
				options.setValue(getValue(k), k);
			}
			return options;
		}
	}
}