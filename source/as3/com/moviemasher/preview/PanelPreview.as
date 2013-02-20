
package com.moviemasher.preview
{

	import com.moviemasher.constant.*;
	import com.moviemasher.interfaces.*;
	import com.moviemasher.type.*;
	import com.moviemasher.display.*;
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
	public class PanelPreview extends BrowserPreview implements IValued
	{
		public function PanelPreview()
		{
			// create container for elements
			super();
			_mouseSprite = new Sprite();
			addChild(_mouseSprite);
			
			
			__panelsView = new RunClass.PanelsView() as IPanelsView;
			_mouseSprite.addChild(__panelsView.displayObject);
		}
		public function getValue(property:String):Value
		{
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
			/*
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
			}
			catch(e:*)
			{
				RunClass.MovieMasher['msg'](this + ' PanelPreview.unload', e);
			}
			*/
			super.unload();

		}
		override public function updateTooltip(tooltip:ITooltip):Boolean
		{
			
			var dont_delete:Boolean = false;
			var tip:String = '';
			var pt:Point = tooltip.point;
			var in_panels:Boolean = __panelsView.displayObject.hitTestPoint(pt.x, pt.y, true);
			
			//RunClass.MovieMasher['msg'](this + '.updateTooltip ' + pt + ' ' + in_panels);
			if (! in_panels)
			{
				tip = _options.getValue('tooltip').string;
			}
			else 
			{
				tip = '';//_options.tag.button[__hovering].@tooltip;
			//	dont_delete = true;
			}
			dont_delete = (tip.length > 0);
			if (dont_delete) tooltip.text = tip;
			return dont_delete;
		}

		override protected function _optionsChanged():void
		{ 
			var panels_tag:XML = <panels/>;
			var panel_tag:XML = <panel width='-0' height='-0' />;
			var options_tag:XML = _options.tag.copy();
			panel_tag.setChildren(options_tag.children());
			panels_tag.appendChild(panel_tag);
			__panelsView.tag = panels_tag;
			//RunClass.MovieMasher['msg'](this + '._optionsChanged ' + panels_tag.toXMLString());
			super._optionsChanged();// calls _resize();
		}

		override protected function _resize() : void
		{
			super._resize();
			var size:Size = new Size(_options.getValue('width').number, _options.getValue('height').number);
			
			__panelsView.metrics = size;
					
			
		}
		
		public function invalidate(type:String = ''):void
		{
			RunClass.MovieMasher['msg'](this + '.invalidate ' + type);
		}
		private var __requested:Dictionary;
		private var __normalIcons:Vector.<DisplayObject>;
		private var __overIcons:Vector.<DisplayObject>;
		private var __hovering:int = -1;
		private var __panelsView:IPanelsView;
	}
}