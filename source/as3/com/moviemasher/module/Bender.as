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
	import com.moviemasher.interfaces.*;
	import com.moviemasher.type.*;
	import com.moviemasher.constant.*;
	import com.moviemasher.events.*;
	import com.moviemasher.utils.*;
	
	import flash.geom.*;
	import flash.filters.*;
	import flash.display.*;
	import flash.display.Shader;
	import flash.net.*;
	import flash.events.*;
	import flash.utils.*;
	
/**
* Implementation class for convolution effect module
*
* @see IModule
* @see Clip
* @see Mash
*/
	public class Bender extends ModuleTransition
	{
		private static var __shaders:Dictionary = new Dictionary();
		
		public function Bender()
		{
				
			_defaults.source = '';
			_defaults.fade = Fades.IN;
			__positions =  new Array();
			__scales =  new Array();
		}
		
		override public function buffer(range:TimeRange, mute:Boolean):void
		{
			var shader_url:String = '';
			
			try
			{
				shader_url = __shaderURL();
				var loader:IDataFetcher;
				if (shader_url.length)
				{
					if (__shaders[shader_url] == null)
					{
						
						loader = RunClass.MovieMasher['dataFetcher'](shader_url, null, URLLoaderDataFormat.BINARY);
						
						loader.addEventListener(Event.COMPLETE, __completeLoader);
					
						__shaders[shader_url] = loader;
						__shaders[loader] = shader_url;
					}
					else if (__shaders[shader_url] is IDataFetcher)
					{
						loader = __shaders[shader_url];
						loader.addEventListener(Event.COMPLETE, __completeLoader);
						
					}
				}
				else RunClass.MovieMasher['msg'](this + '.buffer (Bender) no shader ');
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.buffer (Bender) ' + shader_url + ' ' + e);
			}
		}
		
		override public function buffered(range:TimeRange, mute:Boolean):Boolean
		{
		//	RunClass.MovieMasher['msg'](this + '.buffered');
			var is_buffered:Boolean = true;
			var shader_url:String = __shaderURL();
			if (shader_url.length)
			{
				is_buffered = false;
				if (__shaders[shader_url] != null)
				{
					if (! (__shaders[shader_url] is IDataFetcher))
					{
						is_buffered = true;
					}
				}
			}
			else RunClass.MovieMasher['msg'](this + '.buffered (Bender) no shader ');
			return is_buffered;
		}
			
		private function __completeLoader(event:Event):void
		{
			try
			{
				var loader:IDataFetcher = event.target as IDataFetcher;
				var shader_url:String = __shaders[loader];
				
				var shader:Shader = new Shader();
				shader.byteCode = loader.data();
				
				var filter:ShaderFilter = new ShaderFilter(shader);
				__shaders[shader_url] = filter;
				__shaders[filter] = shader;
				loader.removeEventListener(Event.COMPLETE, __completeLoader);
				delete __shaders[loader];
				dispatchEvent(new Event(EventType.BUFFER));
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__completeLoader ' + e);
			}
		}
		protected function __progressLoader(event:ProgressEvent):void
		{
		}
		private function __shaderURL():String
		{
			var shader_url:String = _getClipProperty('source');
			if (shader_url.length)
			{
				var url:Object = new RunClass.URL(shader_url);
				shader_url = url.absoluteURL;
			}
			return shader_url;
		}
		private function __parameterValue(parameter:ShaderParameter):Array
		{
			var index:int = parameter.index;
			var type:String = parameter.type;
			
			var per:Number = _getFade() / 100.00;
				
			var a:Array = null;
			var a_fade:Array = null;
			var value:String = _getClipProperty('parameter' + index);
			if ((value == null) || (! value.length))
			{
				value = _getClipProperty(parameter.name);
			}
			var value_fade:String = _getClipProperty('parameter' + index + 'fade');
			if ((value_fade == null) || (! value_fade.length))
			{
				value_fade = _getClipProperty(parameter.name + 'fade');
			}
			var i:uint;
			var z:uint;
			var n:Number;
			var faded:Number;
			var c:String = type.substr(0, 1);
			if ((value != null) && value.length)
			{
				a = value.split(',');
				if ((value_fade != null) && value_fade.length)
				{
					a_fade = value_fade.split(',');
				}
				z = a.length;
				for (i = 0; i < z; i++)
				{
					switch(c)
					{
						case 'i':
							a[i] = parseInt(a[i]);
							break;
						case 'b':
							a[i] = Boolean(parseInt(a[i]));
							break;
						default:
							a[i] = parseFloat(a[i]);
							break;
					}
					if ((a_fade != null) && (i < a_fade.length))
					{
						faded = RunClass.PlotUtility['perValue'](per * 100, parseFloat(a_fade[i]), parseFloat(a[i]));
						a[i] = faded;
						switch(c)
						{
							case 'i':
								a[i] = parseInt(a[i]);
								break;
							case 'b':
								a[i] = Boolean(parseInt(a[i]));
								break;
						}
					}
				}
				
			}
			return a;
		}
					
    	private function __updateShader(shader:Shader):void
		{
			var shaderData:ShaderData = shader.data; 
			var shaderParameter:ShaderParameter;
			var parameterValue:Array;
			
			
			var parameters:Array = new Array();
			var shader_parameters:Array = new Array();
			var scales:Array;
			var positions:Array;
			var scaler:Number;
			for (var prop:String in shaderData) 
			{ 
				// might be ShaderInput or meta
				if (shaderData[prop] is ShaderParameter) 
				{ 
					shaderParameter = shaderData[prop] as ShaderParameter;
					parameterValue = __parameterValue(shaderParameter);
					
					if (parameterValue != null)
					{
						parameters[shaderParameter.index] = parameterValue;
						shader_parameters[shaderParameter.index] = shaderParameter;
						if (__scales.indexOf(shaderParameter.index) != -1)
						{
							scales = parameterValue;
						}
						else if (__positions.indexOf(shaderParameter.index) != -1)
						{
							positions = parameterValue;
						}
					}
				} 
			}
			
			if (scales != null)
			{
				scales[0] = (scales[0] * _size.width) /100;
				if (scales.length > 1) 
				{
					scales[1] = (scales[1] * _size.height) /100;
				}
			}
			if (positions != null)
			{ 
				scaler = 0;
				if (! __ignorescale)
				{
					scaler = ((scales == null) ? 0 : scales[0]);
				}
				positions[0] = ((positions[0] * (_size.width - scaler)) /100);
				
				if (positions.length > 1)
				{
					positions[1] = Math.abs(Number(positions[1]) + (_getClipPropertyNumber('verticalinvert') ? 0 : -100));
					if (! __ignorescale)
					{
						scaler = ((scales == null) ? 0 : scales[((scales.length == 1) ? 0 : 1)]);
					}
					positions[1] = ((positions[1] * (_size.height - scaler)) /100);
					
				}
			}
			var z:uint = parameters.length;
			var i:uint;
			for (i = 0; i < z; i++)
			{
				parameterValue = parameters[i];
			
				if (parameterValue != null)
				{
					shaderParameter = shader_parameters[i];
					shaderParameter.value = parameterValue;
				}
				//else RunClass.MovieMasher['msg'](this + ' ' + i + ' is null');
			}
		}
		override public function set time(object:Time):void
		{	
			super.time = object;
			try
			{
				
				var type:String = _getClipProperty('type');
				var a:Array = new Array();
				var shader_url:String = __shaderURL();
				if (shader_url.length)
				{
					
					if ((__shaders[shader_url] != null) && (__shaders[shader_url] is ShaderFilter)) 
					{
						var filter:ShaderFilter = __shaders[shader_url];
						__updateShader(__shaders[filter]);
						a.push(filter);
					}
				}
				if (type == ClipType.TRANSITION) _transitionFilters = a;
				else _moduleFilters = a;
				
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.time (Bender) ', e);
			}
		}
		override protected function _initialize():void
		{
			super._initialize();
			
			var position:String = _getMediaProperty('positions');
			var scale:String = _getMediaProperty('scales');
			var z:uint;
			var i:uint;
			
			if ((position != null) && position.length)
			{
				__positions = position.split(',');
			}
			if ((scale != null) && scale.length)
			{
				__scales = scale.split(',');
			}
			z = __positions.length;
			if (z)
			{
				for (i = 0; i < z; i++)
				{
					__positions[i] = parseInt(__positions[i]);
				}
			}
			z = __scales.length;
			if (z)
			{
				__ignorescale = (_getMediaProperty('ignorescale') == "1");
				for (i = 0; i < z; i++)
				{
					__scales[i] = parseInt(__scales[i]);
				}
			}
		}
		private var __positions:Array;
		private var __scales:Array;
		private var __ignorescale:Boolean = true;
	}
	
}
