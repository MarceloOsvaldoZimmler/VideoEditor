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

package 
{
	import flash.display.*;
	import flash.events.*;
	import flash.net.*;

	public class Container extends MovieClip
	{
		public function Container()
		{
			// we ignore these options if specified in the HTML
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			
			// listen for resizing of browser window, so as to pass through to applet
			stage.addEventListener(Event.RESIZE, resizeStage);
			
			// load Movie Masher applet with request variables built from our HTML parameters
								
			var request:URLRequest = null;
			var variables:URLVariables = new URLVariables();
			var k:Object;
			for (k in loaderInfo.parameters)
			{
				// make sure we don't load any configuration, since we pass ours later
				if (k != 'config') variables[k] = loaderInfo.parameters[k];
			}
			if (variables.mm_path == null) variables.mm_path = '../../';
			request = new URLRequest(variables.mm_path + 'moviemasher/com/moviemasher/core/MovieMasher/stable.swf');
			request.data = variables;
			loader = new Loader();
			addChild(loader);
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, completeLoader);
			loader.load(request);
		
		}
		function completeLoader(e:Event):void
		{
			try
			{
				e.target.removeEventListener(Event.COMPLETE, completeLoader);
				
				// find the definition of MovieMasher class in applet
				var definition:String = 'com.moviemasher.core.MovieMasher';
				if (loader.contentLoaderInfo.applicationDomain.hasDefinition(definition))
				{
					moviemasher = loader.contentLoaderInfo.applicationDomain.getDefinition(definition) as Class;
				}
				
				// resize applet BEFORE loading our configuration
				resizeStage(null);
				
				// get the applet to parse our configuration
				if (moviemasher != null) 
				{
					moviemasher['parseConfig'](configuration);
				}
			}
			catch(e:*)
			{
				// ignoring errors because we have no means to display them
			}
		}
		function resizeStage(e:Event):void
		{
			try
			{
				if (moviemasher != null) 
				{
					moviemasher['setSize'](stage.stageWidth, stage.stageHeight);	
				}
			}
			catch(e:*)
			{
				
			}
		}
		public function save(object:* = null):*
		{
			if (moviemasher != null)
			{
				// object sent is string representation of mash XML
				moviemasher['msg'](object, 'debug'); // output as debug message
				
				// we can also retrieve the XML object itself
				object = moviemasher['getByID']('player.mash.xml');
				moviemasher['msg'](object.toXMLString(), 'debug'); // output as debug message
			}
			return '';
		}
		 // pointer to com.moviemasher.core.MovieMasher - to call static functions 
		var moviemasher:Class;
		
		// used to load in Movie Masher Applet
		var loader:Loader; 

		// the configuration we send to the applet once loaded
		var configuration:XML = <moviemasher>
	
			<!-- DEFAULT MASH -->
			<moviemasher config='media/xml/mash.xml' />
			
			<!-- PANEL INTERFACE LAYOUT -->
			<moviemasher config='media/xml/panel.xml' />
			
			<!-- DYNAMIC MEDIA SOURCES --> 
			<moviemasher config='media/xml/source.xml' />
			
			<!-- CUSTOM PANEL OVERLAY -->
			<panel z='1' width='58' height='{layout.barsize}' x='{moviemasher.width}-({layout.padding}+{layout.spacing}+{layout.panelwidth}+58)' y='{layout.padding}+{layout.spacing}+{video_height}+2*{layout.barsize}'>
				<bar style='bar' color=''>
					<control style='button' text='Save' trigger='parent.save={player.mash.xml}' disable='player.dirty=empty' />
				</bar>
			</panel>
		</moviemasher>;
	}
}
