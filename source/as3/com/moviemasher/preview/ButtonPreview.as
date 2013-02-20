
package com.moviemasher.preview
{

	import com.moviemasher.constant.*;
	import com.moviemasher.interfaces.*;
	import com.moviemasher.type.*;
	import flash.display.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.utils.*;
/**
* Browser preview with configurable button with trigger
*
* @see Browser
* @see IBrowserPreview
*/
	public class ButtonPreview extends BrowserPreview implements IValued, IPreview
	{
		public function ButtonPreview()
		{
			// create container for elements
			super();
			_mouseSprite = new Sprite();
			addChild(_mouseSprite);
			_mouseSprite.addEventListener(MouseEvent.MOUSE_OVER, __mouseOver);
			_mouseSprite.addEventListener(MouseEvent.MOUSE_DOWN, __mouseDown);
			_mouseSprite.useHandCursor = false;
		}
		public function getValue(property:String):Value
		{
			//RunClass.MovieMasher['msg'](this + '.getValue ' + property);
			var value:Value = null;
			switch(property)
			{
				case 'tag':
					value = new Value(_mediaTag);
					break;
				default:
					value = _options.getValue(property);
			}
			return value;
		}
		override public function unload():void
		{
			try
			{
				var i,z:int;
				var display:DisplayObject;
				
				if (__overIcons != null)
				{
					z = __overIcons.length;
					for (i = 0; i < z; i++)
					{
						display = __overIcons[i];
						if ((display != null) && _mouseSprite.contains(display)) _mouseSprite.removeChild(display);
					}
					__overIcons = null;
				}
				if (__normalIcons != null)
				{
					z = __normalIcons.length;
					for (i = 0; i < z; i++)
					{
						display = __normalIcons[i];
						
						if ((display != null) && _mouseSprite.contains(display)) _mouseSprite.removeChild(display);
					}
					__normalIcons = null;
				}
				if (__requested != null)
				{
					__requested = null;
				}
				
				RunClass.MovieMasher['instance'].removeEventListener(MouseEvent.MOUSE_MOVE, __mouseMove);
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + ' ButtonPreview.unload', e);
			}
			super.unload();

		}
		override public function updateTooltip(tooltip:ITooltip):Boolean
		{
			var dont_delete:Boolean = false;
			var tip:String = '';
			if (__hovering == -1) tip = _options.getValue('tooltip').string;
			else tip = _options.tag.button[__hovering].@tooltip;
			dont_delete = (tip.length > 0);
			if (dont_delete) tooltip.text = tip;
			return dont_delete;
		}
		override protected function _optionsChanged():void
		{ 
			__loadButtons(null);
			super._optionsChanged();// calls _resize();
		}
		override protected function _resize() : void
		{
			super._resize();
			__sizeIcons();
		}
		private function __sizeIcons():void
		{
			if (__normalIcons != null)
			{
				var vertical:Boolean = _options.getValue('vertical').boolean;
				var align:String = _options.getValue('align').string;
				var valign:String = _options.getValue('valign').string;
				if (! align.length) align = 'center';
				if (! valign.length) valign = 'center';
				var widthORheight:String;
				var xORy:String;
				var spacing:Number = _options.getValue('spacing').number;
				var padding:Number = _options.getValue('padding').number;
				var i,z:int;
				var display,over_display:DisplayObject;
				var icons_size:Size;
				var found:int;
				var pt:Point;
				var size:Size;
				var wh:Number;
				widthORheight = (vertical ? 'height' : 'width');
				xORy = (vertical ? 'y' : 'x');
				z = __normalIcons.length;			
				icons_size = new Size(0,0);
				found = 0;
				for (i = 0; i < z; i++)
				{
					display = __normalIcons[i];
					over_display = __overIcons[i];
					if ((display != null) && (display.visible || ((over_display != null) && over_display.visible)))
					{
						found++;
						if (vertical)
						{
							icons_size.width = Math.max(icons_size.width, display.width);
							icons_size.height += display.height;
						}
						else
						{
							icons_size.width += display.width;
							icons_size.height = Math.max(icons_size.height, display.height);
						}
					}
				}
				if (found)
				{
					// add space between items
					icons_size[widthORheight] += (found - 1) * spacing;
					
					size = new Size(_options.getValue('width').number, _options.getValue('height').number);
					pt = new Point();
					
					switch (align)
					{
						case 'center':
							pt.x = Math.round((size.width - icons_size.width) / 2);
							break;
						case 'left':
							pt.x = padding;
							break;
						case 'right':
							pt.x = size.width - (icons_size.width + padding);
							break;
					}
					switch (valign)
					{
						case 'center':
							pt.y = Math.round((size.height - icons_size.height) / 2);
							break;
						case 'top':
							pt.y = padding;
							break;
						case 'bottom':
							pt.y = size.height - (icons_size.height + padding);
							break;
					}
					for (i = 0; i < z; i++)
					{
						display = __normalIcons[i];
						over_display = __overIcons[i];
						if ((display != null) && (display.visible || ((over_display != null) && over_display.visible)))
						{
							display.x = pt.x;
							display.y = pt.y;
							wh = display[widthORheight]
							display = __overIcons[i];
							if (display != null)
							{
								display.x = pt.x;
								display.y = pt.y;
							}
							pt[xORy] += wh + spacing;
						}
					}	
				}
			}
		}
		private function __adjustVisibility(over_preview:Boolean = true):Boolean
		{
			var needs_resize:Boolean = over_preview;
			try
			{
				if (__normalIcons != null)
				{
					var i,z:int;
					var display:DisplayObject;
					var over_display:DisplayObject;
					var hide:Boolean;
					var was_hidden:Boolean;
					z = __normalIcons.length;
					for (i = 0; i < z; i++)
					{	
						hide = __evaluateHide(__hides[i]);
						display = __normalIcons[i];
						if (display != null)
						{
							over_display = __overIcons[i];
							was_hidden = (display.visible || ( (over_display != null) && over_display.visible));
							display.visible = (! hide) && over_preview && ((__hovering != i) || (over_display == null));
							if (over_display != null)
							{
								over_display.visible = (! hide) && over_preview && (__hovering == i);
							}
							if (was_hidden != hide) needs_resize = true;
						}
					}
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__adjustVisibility ' + display + ' ' + __normalIcons, e);
			}
			return true;//needs_resize;
		}
		private function __loadButtons(event:Event):void
		{
			var list:XMLList;
			var i,z:int;
			var xml:XML;
			var url:String;
			var loader:IAssetFetcher;
			var icons_size:Size;
			var display:DisplayObject;
			var needs_resize:Boolean = false;
			try
			{
				list = _options.tag.button;
				z = list.length();
				if (__normalIcons == null)
				{
					__normalIcons = new Vector.<DisplayObject>(z, true);
					__overIcons = new Vector.<DisplayObject>(z, true);
					__requested = new Dictionary();
					__hides = new Vector.<String>(z, true);
				}
				for (i = 0; i < z; i++)
				{
					xml = list[i];
					__hides[i] = xml.@hide;

					if (__normalIcons[i] == null)
					{
						url = xml.@icon;
						if (url.length)
						{
							loader = RunClass.MovieMasher['assetFetcher'](url) as IAssetFetcher;
							if (loader.state != EventType.LOADING) 
							{
								icons_size = new Size(xml.@width, xml.@height);
								display = loader.displayObject(url, '', icons_size);
								if (display != null) 
								{
									_mouseSprite.addChild(display);
									display.visible = false;
									__normalIcons[i] = display;
								}
							}
							else if (__requested[loader] == null)
							{
								__requested[loader] = true;
								loader.addEventListener(Event.COMPLETE, __loadButtons, false, 0, true);
							}
						}
					}
					if (__overIcons[i] == null)
					{
						url = xml.@overicon;
						if (url.length)
						{
							loader = RunClass.MovieMasher['assetFetcher'](url) as IAssetFetcher;
							if (loader.state != EventType.LOADING) 
							{
								
								icons_size = new Size(xml.@width, xml.@height);
								display = loader.displayObject(url, '', icons_size);
								if (display != null) 
								{
									_mouseSprite.addChild(display);
									display.visible = false;
									__overIcons[i] = display;
								}
							}
							else if (__requested[loader] == null)
							{
								__requested[loader] = true;
								loader.addEventListener(Event.COMPLETE, __loadButtons, false, 0, true);	
							}
						}
					}
				}
				needs_resize = __adjustVisibility(_selected);
				if (event != null)
				{
					event.target.removeEventListener(EventType.LOADED, __loadButtons);
					needs_resize = true;
				}
				if (needs_resize) __sizeIcons();
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__loadButtons', e);
			}
		}
		private function __evaluateHide(string:String):Boolean
		{	
			var should:Boolean = false;
			if (string.length)
			{
				string = RunClass.ParseUtility['brackets'](string, this);
				if (string.length)
				{
				 	should = RunClass.ParseUtility['booleanExpressions'](string, this);
				 	//RunClass.MovieMasher['msg'](this + '.__evaluateHide ' + string + ' ' + should);
				}
			}
			return should;
		}
		private function __mouseDown(event:MouseEvent):void
		{
			RunClass.MovieMasher['instance'].stage.focus = null;
			try
			{
				if (! RunClass.MouseUtility['dragging']) 
				{
				
					var i,z:int;
					var over_icon:int = -1;
					var display, over_display:DisplayObject;
					z = __normalIcons.length;
					var result:String;
					for (i = 0; i < z; i++)
					{	
						display = __normalIcons[i];
						over_display = __overIcons[i];
						if ((display != null) && (display.visible || ((over_display != null) && over_display.visible)))
						{
							if (display.hitTestPoint(event.stageX, event.stageY, true))
							{
								over_icon = i;
								break;
							}
							
						}
					}
					var trigger:String = '';
					if (over_icon != -1)
					{
						trigger = _options.tag.button[over_icon].@trigger;
						if (trigger.length) trigger = RunClass.ParseUtility['brackets'](trigger);
						if (trigger.length)
						{
							result = RunClass.MovieMasher['evaluate'](trigger);
						//	RunClass.MovieMasher['msg'](this + '.__mouseDown ' + result + ' ' + trigger);
						}
					}
					if (! trigger.length) _container.downPreview(this, event);
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__mouseDown', e);
			}
		}	
		private function __mouseMove(event:MouseEvent):void
		{
			try
			{
				var over_preview:Boolean = true;
				//var hovering:int = -1;//__hovering;
				var i,z:int;
				var display:DisplayObject;
				var over_display:DisplayObject;
				var hide:Boolean;
				if (! RunClass.MouseUtility['dragging'])
				{ 
					
					if (__normalIcons != null)
					{
						over_preview = _mouseSprite.hitTestPoint(event.stageX, event.stageY, false);
						
						__hovering = -1;
						
						if (over_preview)
						{
							z = __normalIcons.length;
							for (i = 0; i < z; i++)
							{	
								//hide = __evaluateHide(__hides[i]);
								display = __normalIcons[i];
								over_display = __overIcons[i];
								if ((display != null) && (display.visible || ((over_display != null) && over_display.visible)))	
								{
									if (display.hitTestPoint(event.stageX, event.stageY, true))
									{
										__hovering = i;
										break;
									}
								}
							}
						}
					}
					if (over_preview) 
					{
						if (__hovering != -1) RunClass.MovieMasher['setCursor']();
						_container.overPreview(this, event);
					}
					else _container.outPreview(this, event);
					if (__adjustVisibility(over_preview)) __sizeIcons();
					
					if (! over_preview) RunClass.MovieMasher['instance'].removeEventListener(MouseEvent.MOUSE_MOVE, __mouseMove);
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__mouseMove ' + _mouseSprite + ' ' + _container, e);
				RunClass.MovieMasher['instance'].removeEventListener(MouseEvent.MOUSE_MOVE, __mouseMove);

			}
		}
		private function __mouseOver(event:MouseEvent):void
		{			
			try
			{
				if (! RunClass.MouseUtility['dragging']) 
				{
					RunClass.MovieMasher['instance'].addEventListener(MouseEvent.MOUSE_MOVE, __mouseMove);
					__mouseMove(event);
				}
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + '.__mouseOver', e);
			}
		}
		private var __requested:Dictionary;
		private var __normalIcons:Vector.<DisplayObject>;
		private var __hides:Vector.<String>;
		private var __overIcons:Vector.<DisplayObject>;
		private var __hovering:int = -1;
	}
}