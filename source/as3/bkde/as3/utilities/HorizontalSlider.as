/* ***********************************************************************
The classes in the package
bkde.as3.* were created by

Barbara Kaskosz of the University of Rhode Island
(bkaskosz@math.uri.edu) and
Douglas E. Ensley of Shippensburg University
(DEEnsley@ship.edu).

Feel free to use and modify the classes in the package 
bkde.as3.* to create
your own Flash applications for educational purposes under the
following two conditions:

1) Please include a line acknowledging this work and the authors
with your application in a way that is visible in your compiled file
or on your html page. 

2) If you choose to modify the classes in the package 
bkde.as3.*, put them into a package different from
the original. In this case too, please acknowledge this work
in a way visible to the user.

If you wish to use the materials for commercial purposes, you need our
permission.

This work is supported in part by the National Science Foundation
under the grant DUE-0535327.

Last modified: June 30, 2007
************************************************************************ */

package bkde.as3.utilities {
	
    import flash.display.Sprite;
	
	import flash.display.Shape;
  
    import flash.events.MouseEvent;
	
	import flash.geom.Rectangle;
   
  public class HorizontalSlider extends Sprite {
	
	protected var nLength:Number;
	
	protected var shTrack:Shape;
	
	protected var spKnob:Sprite;
	
	protected var nKnobColor:Number;
	
	protected var nKnobOpacity:Number;
	
	protected var nKnobSize:Number;
	
	protected var nKnobRightLine:Number;
	
	protected var nKnobLeftLine:Number;
	
	protected var nTrackOutColor:Number;
	
	protected var nTrackInColor:Number;
	
	protected var sStyle:String;
	
	protected var rBounds:Rectangle;
	
	protected var isPressed_internal:Boolean;
	
	public function HorizontalSlider(len:Number,style:String){
		
		this.nLength=len;
		
		this.isPressed_internal=false;
		
		this.nKnobColor=0x666666;
		
		this.nKnobOpacity=1.0;
		
		this.nKnobSize=8;
		
		this.nKnobRightLine=0x000000;
	
	    this.nKnobLeftLine=0xFFFFFF;
	
	    this.nTrackOutColor=0x333333;
	
	    this.nTrackInColor=0xFFFFFF;
		
		this.sStyle=style;
		
		rBounds=new Rectangle(0,0,nLength,0);
		
		shTrack=new Shape();
		
		this.addChild(shTrack);
		
		spKnob=new Sprite();
		
		this.addChild(spKnob);
		
		drawSlider();
		
		activateSlider();
		
		setKnobPos(0);
		
		
	}
	
	public function getSliderLen():Number{
		
		return nLength;
		
	}
	
	
	protected function drawSlider():void {
		
		shTrack.graphics.clear();
		spKnob.graphics.clear();
		
		shTrack.graphics.lineStyle(0,nTrackOutColor);
		
		shTrack.graphics.moveTo(0,3);
		shTrack.graphics.lineTo(nLength,3);
		shTrack.graphics.moveTo(nLength,0);
		shTrack.graphics.lineTo(0,0);
		
		shTrack.graphics.lineStyle(0,nTrackInColor);
		shTrack.graphics.moveTo(1,1);
		shTrack.graphics.lineTo(nLength,1);
		
		shTrack.graphics.lineStyle(0,nTrackOutColor);
		shTrack.graphics.moveTo(0,3);
		shTrack.graphics.lineTo(0,-8);
		shTrack.graphics.moveTo(nLength/2,0);
		shTrack.graphics.lineTo(nLength/2,-8);
		shTrack.graphics.moveTo(nLength,4);
		shTrack.graphics.lineTo(nLength,-8);
		shTrack.graphics.moveTo(nLength/4,0);
		shTrack.graphics.lineTo(nLength/4,-5);
		shTrack.graphics.moveTo(3*nLength/4,0);
		shTrack.graphics.lineTo(3*nLength/4,-5);
		
		if(sStyle=="triangle"){
		
		spKnob.graphics.lineStyle(0,nKnobLeftLine);
		spKnob.graphics.beginFill(nKnobColor,nKnobOpacity);
		spKnob.graphics.moveTo(0,1);
		spKnob.graphics.lineTo(-nKnobSize,2*nKnobSize);
		spKnob.graphics.lineStyle(0,nKnobRightLine);
		spKnob.graphics.lineTo(nKnobSize,2*nKnobSize);
		spKnob.graphics.lineTo(0,1);
		spKnob.graphics.endFill();
		
		} else if(sStyle=="rectangle"){
		
		spKnob.graphics.lineStyle(0,nKnobLeftLine);
		spKnob.graphics.beginFill(nKnobColor,nKnobOpacity);
		spKnob.graphics.moveTo(-nKnobSize/2,nKnobSize);
		spKnob.graphics.lineTo(-nKnobSize/2,-nKnobSize);
		spKnob.graphics.lineTo(nKnobSize/2,-nKnobSize);
		spKnob.graphics.lineStyle(0,nKnobRightLine);
		spKnob.graphics.lineTo(nKnobSize/2,nKnobSize);
		spKnob.graphics.lineTo(-nKnobSize/2,nKnobSize);
		spKnob.graphics.endFill();
		
		} else {    }
		
		
		
	}
	
	protected function activateSlider(): void {
		
		spKnob.addEventListener(MouseEvent.MOUSE_DOWN,downKnob);
		
		spKnob.addEventListener(MouseEvent.MOUSE_UP,upKnob);
		
	}
	
	protected function downKnob(e:MouseEvent): void {
		
		spKnob.startDrag(false,rBounds);
		
		stage.addEventListener(MouseEvent.MOUSE_UP,upOutsideKnob);
		
		isPressed_internal=true;
		
		
		
	}
	
	protected function upOutsideKnob(e:MouseEvent): void {
		
		spKnob.stopDrag();
		
		stage.removeEventListener(MouseEvent.MOUSE_UP,upOutsideKnob);
		
		isPressed_internal=false;
		
	}
	
	protected function upKnob(e:MouseEvent): void {
		
		spKnob.stopDrag();
		
		isPressed_internal=false;
		
		
	}
	
	
	public function get isPressed():Boolean {
		
		
		return isPressed_internal;
		
	}
	
	
	
	public function setKnobPos(a:Number):void {
		
		spKnob.x=a;
		
	}
	
	
	
	public function getKnobPos():Number {
		
		return spKnob.x;
		
		
	}
	
	public function changeKnobSize(s:Number):void {
		
		nKnobSize=s;
		
		drawSlider();
		
	}
	
	public function changeKnobColor(colo:Number):void {
		
		nKnobColor=colo;
		
		drawSlider();
		
	}
	
	public function changeKnobOpacity(opac:Number):void {
		
		nKnobOpacity=opac;
		
		drawSlider();
		
	}
	
	public function changeKnobRightLine(colo:Number):void {
		
		nKnobRightLine=colo;
		
		drawSlider();
		
	}
	
	public function changeKnobLeftLine(colo:Number):void {
		
		nKnobLeftLine=colo;
		
		drawSlider();
		
	}
	
	public function changeTrackOutColor(colo:Number):void {
		
		nTrackOutColor=colo;
		
		drawSlider();
		
	}
	
	public function changeTrackInColor(colo:Number):void {
		
		nTrackInColor=colo;
		
		drawSlider();
		
	}
	
		
	
	public function destroy():void {
		
		spKnob.removeEventListener(MouseEvent.MOUSE_DOWN,downKnob);
		
		spKnob.removeEventListener(MouseEvent.MOUSE_UP,upKnob);
		
		stage.removeEventListener(MouseEvent.MOUSE_UP,upOutsideKnob);
		
		spKnob.graphics.clear();
		
		shTrack.graphics.clear();
		
		this.removeChild(spKnob);
		
		this.removeChild(shTrack);
		
		shTrack=null;
		
		spKnob=null;
		
		
	}
	
		
}

}