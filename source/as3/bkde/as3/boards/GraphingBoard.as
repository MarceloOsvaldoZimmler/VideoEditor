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

Last modified: July 23, 2007
************************************************************************ */

package bkde.as3.boards {
	
    import flash.display.*;
  
    import flash.events.*;
   
    import flash.text.*;

  public class GraphingBoard extends Sprite {
	
	protected var nXSize:Number;
	
	protected var nYSize:Number;
	
	protected var nMaxNumGraphs:int;
	
	protected var spGraphsHolder:Sprite;
	
	protected var aGraphs:Array;
	
	protected var spBoard:Sprite;
	
	protected var shBorder:Shape;
	
	protected var shAxes:Shape;
	
	protected var shCross:Shape;
	
	protected var shArrow:Shape;
	
	protected var spMask:Sprite;
	
	protected var nAxesColor:Number;
	
	protected var nAxesThick:Number;
	
	protected var nBackColor:Number;
	
	protected var nBorderColor:Number;
	
	protected var nBorderThick:Number;
	
	protected var sHorVarName:String;
	
	protected var sVerVarName:String;
	
	protected var nXmin:Number;
	
	protected var nXmax:Number;
	
	protected var nYmin:Number;
	
	protected var nYmax:Number;
	
	protected var bIsRangeSet:Boolean;
	
	protected var bIsCoordsOn:Boolean;
	
	protected var bIsUserDrawEnabled:Boolean;
	
	protected var bIsTraceOn:Boolean;
	
	protected var bUserDraw:Boolean;
	
	protected var nUserColor:Number;
	
	protected var nUserThick:Number;
	
	protected var shUser:Shape;
	
	protected var nCrossSize:Number;
	
	protected var nCrossColor:Number;
	
	protected var nCrossThick:Number;
	
	protected var nArrowSize:Number;
	
	protected var nArrowColor:Number;
	
	protected var sTraceStyle:String;
	
	protected var CoordsBox:TextField;
	
	public var ErrorBox:TextField;
		
	
	public function GraphingBoard(w:Number,h:Number){
		
		this.nXSize=w;
		
		this.nYSize=h;
		
		this.nAxesColor=0x000000;
		
		this.nAxesThick=0;
		
		this.nBackColor=0xFFFFFF;
		
		this.nBorderColor=0x000000;
		
		this.nBorderThick=1;
		
		this.nCrossColor=0x000000;
		
		this.nCrossThick=1;
		
		this.nCrossSize=6;
		
		this.nArrowColor=0x000000;
		
		this.nArrowSize=10;
		
		this.bIsRangeSet=false;
		
		spBoard=new Sprite();
		
		this.addChild(spBoard);
		
		spMask=new Sprite();
		
		this.addChild(spMask);
		
		shBorder=new Shape();
		
		this.addChild(shBorder);
		
		drawBoard();
		
		drawMask();
		
		spBoard.mask=spMask;
		
		shAxes=new Shape();
		
		spBoard.addChild(shAxes);
		
		spGraphsHolder=new Sprite();
		
		spBoard.addChild(spGraphsHolder);
		
		shCross=new Shape();
		
		spBoard.addChild(shCross);
		
		shArrow=new Shape();
		
		spBoard.addChild(shArrow);
		
		shUser=new Shape();
		
		spBoard.addChild(shUser);
		
		setMaxNumGraphs(5);
		
		ErrorBox=new TextField();
		
		this.addChild(ErrorBox);
		
		setUpErrorBox();
		
		setErrorBoxFormat(0xFFFFFF,0xFFFFFF,0x000000,12);
		
		setErrorBoxSizeAndPos(nXSize-20,nYSize/3,10,10);
		
		CoordsBox=new TextField();
		
		this.addChild(CoordsBox);
		
		setUpCoordsBox();
		
		setCoordsBoxFormat(0xFFFFFF,0xFFFFFF,0x000000,12);
			
		setCoordsBoxSizeAndPos(60,40,20,Math.max(nYSize-50,0));
		
		setUpListeners();
		
		enableCoordsDisp("x","y");
		
		enableUserDraw(0x0000CC,1);
		
		enableTrace();
		
		setTraceStyle("cross");
		
	}
	
	public function setTraceStyle(s:String):void {
		
		if(bIsTraceOn){
			
			if(s=="cross"){
				
				drawCross();
		
		        crossVisible(false);
				
				sTraceStyle="cross"
				
			} else if(s=="arrow"){
				
				drawArrow();
		
		        arrowVisible(false);
				
				sTraceStyle="arrow"
				
			} else { }
			
			
		}
		
	}
	
	
	public function enableTrace():void {
		
		bIsTraceOn=true;
		
	}
	
	public function disableTrace():void {
		
		bIsTraceOn=false;
		
	}
	
	public function getArrowSize():Number {
		
		return nArrowSize;
		
	}
	
	
	public function arrowVisible(b:Boolean):void {
		
		shArrow.visible=b;
		
	}
	
	
	
	public function setArrowColor(colo:Number):void {
		
		nArrowColor=colo;
		
		drawArrow();
		
	}
	
	public function setArrowSize(s:Number):void {
		
		nArrowSize=s;
		
		drawArrow();
		
	}
	
	
	
	
	public function setArrowPos(a:Number,b:Number,c:Number):void {
		
		shArrow.x=a;
		
		shArrow.y=b;
		
		shArrow.rotation=c;
		
	}
	
	protected function drawArrow():void {
		
	    shArrow.graphics.clear();
		shArrow.graphics.beginFill(nArrowColor);
		shArrow.graphics.moveTo(0,0);
		shArrow.graphics.lineTo(-nArrowSize/2,nArrowSize);
		shArrow.graphics.lineTo(nArrowSize/2,nArrowSize);
		shArrow.graphics.lineTo(0,0);
		shArrow.graphics.endFill();
		
		shArrow.x=0;
		shArrow.y=0;
		
	}
	
	
	public function getCrossSize():Number {
		
		return nCrossSize;
		
	}
	
	public function crossVisible(b:Boolean):void {
		
		shCross.visible=b;
		
	}
	
	
	
	public function setCrossColor(colo:Number):void {
		
		nCrossColor=colo;
		
		drawCross();
		
	}
	
	public function setCrossSizeAndThick(s:Number,t:Number):void {
		
		nCrossSize=s;
		
		nCrossThick=t;
		
		drawCross();
		
	}
	
	
	public function setCrossPos(a:Number,b:Number):void {
		
		shCross.x=a;
		
		shCross.y=b;
		
	}
	
	protected function drawCross():void {
		
		shCross.graphics.clear();
		
		shCross.graphics.lineStyle(nCrossThick,nCrossColor);
		
		shCross.graphics.moveTo(0,-nCrossSize);
		shCross.graphics.lineTo(0,nCrossSize);
		shCross.graphics.moveTo(-nCrossSize,0);
		shCross.graphics.lineTo(nCrossSize,0);
		
		
	}
	
	
	public function enableUserDraw(colo:Number,thick:Number):void {
		
		bIsUserDrawEnabled=true;
		
		nUserColor=colo;
		
		nUserThick=thick;
		
		bUserDraw=false;
		
	}
	
	public function disableUserDraw():void {
		
		bIsUserDrawEnabled=false;
		
		bUserDraw=false;
		
	}
	
	
	public function enableCoordsDisp(h:String,v:String):void {
		
		sHorVarName=h;
		
		sVerVarName=v;
		
		bIsCoordsOn=true;
		
	}
	
	public function disableCoordsDisp():void {
		
		bIsCoordsOn=false;
		
	}
	
	protected function setUpListeners():void {
		
		spBoard.addEventListener(MouseEvent.ROLL_OVER,boardOver);
		
		spBoard.addEventListener(MouseEvent.ROLL_OUT,boardOut);
		
		spBoard.addEventListener(MouseEvent.MOUSE_MOVE,boardMove);
		
		spBoard.addEventListener(MouseEvent.MOUSE_DOWN,boardDown);
		
		spBoard.addEventListener(MouseEvent.MOUSE_UP,boardUp);
		
		
	}
	
	
	protected function boardOver(e:MouseEvent):void {
		
		if(bIsCoordsOn && bIsRangeSet){
			
			CoordsBox.visible=true;
			
			
		} 
				
	}
	
	protected function boardOut(e:MouseEvent):void {
			
			CoordsBox.visible=false;
			
			bUserDraw=false;
			
	}
	
	protected function boardDown(e:MouseEvent):void {
			
			if(bIsUserDrawEnabled){
			
			bUserDraw=true;
			
			shUser.graphics.lineStyle(nUserThick,nUserColor);
			
			shUser.graphics.moveTo(spBoard.mouseX,spBoard.mouseY);
			
			} else { bUserDraw=false; }
			
	}
	
	protected function boardUp(e:MouseEvent):void {
			
			bUserDraw=false;
			
	}
	
	protected function boardMove(e:MouseEvent):void {
		
		var dispx:String="";
		
		var dispy:String="";
			
		if(bIsRangeSet && bIsCoordsOn){
					
			  dispx=String(Math.round(xtoFun(spBoard.mouseX)*100)/100);
			  
			  dispy=String(Math.round(ytoFun(spBoard.mouseY)*100)/100);
			  
			  CoordsBox.visible=true;
			  
			  CoordsBox.text=sHorVarName+"="+dispx+"\n"+sVerVarName+"="+dispy;	
			
		}
		
		if(bIsUserDrawEnabled){
			
			if(bUserDraw){
				
				shUser.graphics.lineTo(spBoard.mouseX,spBoard.mouseY);
				
			}
			
			
		}
		
		
	}
	
	
	protected function setUpCoordsBox():void {
		
		CoordsBox.type=TextFieldType.DYNAMIC;
		
		CoordsBox.wordWrap=true;
		
		CoordsBox.border=true;
		
		CoordsBox.background=true;
		
		CoordsBox.text="";
		
		CoordsBox.visible=false;
		
		CoordsBox.mouseEnabled=false;
		
		
	}
	
	public function setCoordsBoxSizeAndPos(w:Number,h:Number,a:Number,b:Number): void {
		
				
		CoordsBox.width=w;
		
		CoordsBox.height=h;
		
		CoordsBox.x=a;
		
		CoordsBox.y=b;
		
	}
	
	public function setCoordsBoxFormat(colo1:Number,colo2:Number,colo3:Number,s:Number): void {
		
		var coordsFormat:TextFormat=new TextFormat();

        coordsFormat.color=colo3;

        coordsFormat.size=s;

        coordsFormat.font="Arial";

        CoordsBox.defaultTextFormat=coordsFormat;
		
		CoordsBox.backgroundColor=colo1;
			
		CoordsBox.borderColor=colo2;
		
	}
	
	
	
	protected function setUpErrorBox():void {
		
		ErrorBox.type=TextFieldType.DYNAMIC;
		
		ErrorBox.wordWrap=true;
		
		ErrorBox.border=true;
		
		ErrorBox.background=true;
		
		ErrorBox.text="";
		
		ErrorBox.visible=false;
		
		ErrorBox.mouseEnabled=false;
		
		
	}
	
	public function setErrorBoxSizeAndPos(w:Number,h:Number,a:Number,b:Number): void {
		
				
		ErrorBox.width=w;
		
		ErrorBox.height=h;
		
		ErrorBox.x=a;
		
		ErrorBox.y=b;
		
	}
	
	
	
	public function setErrorBoxFormat(colo1:Number,colo2:Number,colo3:Number,s:Number): void {
		
		var errorFormat:TextFormat=new TextFormat();

        errorFormat.color=colo3;

        errorFormat.size=s;

        errorFormat.font="Arial";

        ErrorBox.defaultTextFormat=errorFormat;
		
		ErrorBox.backgroundColor=colo1;
			
		ErrorBox.borderColor=colo2;
		
	}
	
	
  public function setMaxNumGraphs(a:int):void {
	  
	  var i:int;
	  
	  aGraphs=[];
	  
	  nMaxNumGraphs=a;
	  
	  for(i=0;i<nMaxNumGraphs;i++){
		  
		 aGraphs[i]=new Shape();
		 
		 spGraphsHolder.addChild(aGraphs[i]);
		  
	  }
	  
	   
   }
   
   
    public function getMaxNumGraphs():int {
	  
	  
	  return nMaxNumGraphs;
	  	 
	   
   }
   
   public function drawGraph(num:int,thick:Number,aVals:Array,colo:Number): Array {
		
		var i:int;
		
		var valLen:Number=aVals.length;
		
		var pixVals:Array=[];
		
		var aArrowVals:Array=[];
		
		var ang:Number=0;
		
		var diff:Array=[0,-1];
		
		if(!bIsRangeSet){
			
			return [];
		}
		
		if(num<1 || num>nMaxNumGraphs){
			
			return [];
			
		}
		
		for(i=0;i<valLen;i++){
			
			pixVals[i]=[xtoPix(aVals[i][0]),ytoPix(aVals[i][1])];
			
		}
			
		aGraphs[num-1].graphics.clear();
			
		aGraphs[num-1].graphics.lineStyle(thick,colo);
		
		for(i=0;i<valLen-1;i++){
			
			if(isDrawable(pixVals[i][1]) && isDrawable(pixVals[i+1][1]) && isDrawable(pixVals[i][0]) && isDrawable(pixVals[i+1][0])){
		
		aGraphs[num-1].graphics.moveTo(pixVals[i][0],pixVals[i][1]);
		
	    aGraphs[num-1].graphics.lineTo(pixVals[i+1][0],pixVals[i+1][1]);
		
		   }
		
		}
		
		if(bIsTraceOn && sTraceStyle=="arrow"){
				
				for(i=0;i<valLen;i++){
			
			if(isDrawable(pixVals[i][0]) && isDrawable(pixVals[i][1])){
				
				if(i!=valLen-1){
				
				diff=[pixVals[i+1][0]-pixVals[i][0],pixVals[i+1][1]-pixVals[i][1]];
				
				               } else {diff=[0,0];}
							   
							   
				if(diff[0]==0 && diff[1]==0){
					
					ang+=0;
					
				} else {
				
				ang=calcAngle(diff);
				
				}
				 
			    aArrowVals[i]=pixVals[i].concat(ang);
			
		       } else {aArrowVals[i]=[nXSize+nArrowSize,nYSize+nArrowSize,0];}
			
		}
			
			}
			
		if(!bIsTraceOn){
			
			return [];
		}
				
		if(sTraceStyle=="cross"){
			
		return pixVals;
		
		} else if(sTraceStyle=="arrow"){
			
		return aArrowVals;
		
		} else {return [];}
		
			
	}
	
	
	protected function calcAngle(v:Array):Number {
		
		var v1=v[0];
		
		var v2=v[1];
		
		var val:Number;
		
		var vlen:Number=Math.sqrt(Math.pow(v1,2)+Math.pow(v2,2));
		
		if(vlen==0){
			
			return val;
			
		} else if (v1>=0){
					
			val=Math.acos(-v2/vlen)*180/Math.PI;
			
			return val;
						
		} else if(v1<0){
			
			val=-Math.acos(-v2/vlen)*180/Math.PI;
			
			return val;
			
		} else {return val;}
				
	}
	
	
	protected function eraseGraphs():void {
		
		var i:int;
		
		for(i=0; i<nMaxNumGraphs; i++){
				
			aGraphs[i].graphics.clear();
			
		}
			
		shAxes.graphics.clear();
		
	}
	
	public function eraseUserDraw():void {
		
		shUser.graphics.clear();
		
	}
	
	
	public function cleanBoard():void {
		
		 eraseGraphs();
		
		 bIsRangeSet=false;
		
		 ErrorBox.visible=false;
		
	}
	
	
	
	
  protected function drawMask():void {
	
	spMask.graphics.lineStyle(1,0x000000);
	
	spMask.graphics.beginFill(0xFFFFFF);
	
	spMask.graphics.moveTo(0,0);
	
	spMask.graphics.lineTo(nXSize+1,1);
	
	spMask.graphics.lineTo(nXSize+1,nYSize+1);
	
	spMask.graphics.lineTo(0,nYSize+1);
	
	spMask.graphics.lineTo(0,0);
	
	spMask.graphics.endFill();
		
}



  protected function drawBoard():void {
	
	spBoard.graphics.beginFill(nBackColor);
	
	spBoard.graphics.moveTo(0,0);
	
	spBoard.graphics.lineTo(nXSize,0);
	
	spBoard.graphics.lineTo(nXSize,nYSize);
	
	spBoard.graphics.lineTo(0,nYSize);
	
	spBoard.graphics.lineTo(0,0);
	
	spBoard.graphics.endFill();
	
	drawBorder();
	
		
}

   protected function drawBorder():void {
	   
	   shBorder.graphics.lineStyle(nBorderThick,nBorderColor);
	   
	   shBorder.graphics.moveTo(0,0);
	
	   shBorder.graphics.lineTo(nXSize,0);
	
	   shBorder.graphics.lineTo(nXSize,nYSize);
	
	   shBorder.graphics.lineTo(0,nYSize);
	
	   shBorder.graphics.lineTo(0,0);
	   
   }

  
	public function changeBorderColorAndThick(colo:Number,t:Number): void {
		
		nBorderColor=colo;
		
		nBorderThick=t;
		
		drawBoard();
		
	}
	
	public function changeBackColor(colo:Number): void {
		
		nBackColor=colo;
		
		drawBoard();
		
	}
	
	public function setAxesColorAndThick(colo:Number,t:Number): void {
		
		nAxesColor=colo;
		
		nAxesThick=t;
		
		
	}
	

	
	public function getBoardWidth():Number {
		
		return nXSize;
		
	}
	
	public function getBoardHeight():Number {
		
		return nYSize;
		
	}
	
	
	public function setVarsRanges(a:Number,b:Number,c:Number,d:Number): void {
		
		
		if(isLegal(a) && isLegal(b) && isLegal(c) && isLegal(d)){
			
			if(a<b && c<d){
		
		          nXmin=a;
		
		          nXmax=b;
		
		          nYmin=c;
		
		          nYmax=d;
		
		          bIsRangeSet=true;
		
		     }
		
		}
	
		
	}
	
	public function isDrawable(a:*):Boolean {
		
		
		if((typeof a)!="number" || isNaN(a) || !isFinite(a)){
			
			return false; } 
			
			
		if(Math.abs(a)>=5000){
			
			return false;
		}
		
		
		return true;
		
	}
	
	
	public function isLegal(a:*):Boolean {
		
		
		if((typeof a)!="number" || isNaN(a) || !isFinite(a)){
			
			return false; } 
			
		return true;
		
	}
	
	
	public function getVarsRanges(): Array {
		
		if(bIsRangeSet){
		
		return [nXmin,nXmax,nYmin,nYmax];
		
		} else {
			
			return [];
		}
		
	}
	
	
	public function drawAxes(): void {
		
		var yzero:Number;
		var xzero:Number;
		
		if(bIsRangeSet){
		
		shAxes.graphics.clear();
		shAxes.graphics.lineStyle(nAxesThick,nAxesColor);
		yzero=ytoPix(0);		
	    xzero=xtoPix(0);
	    shAxes.graphics.moveTo(0, yzero);
	    shAxes.graphics.lineTo(nXSize,yzero);
	    shAxes.graphics.moveTo(xzero,0);
	    shAxes.graphics.lineTo(xzero,nYSize);
		
		}
	           		
	}
	
	public function xtoPix(a:Number): Number {
		
		var xconv:Number;
		
		if(bIsRangeSet){
		
		xconv=nXSize/(nXmax-nXmin);
		
		return (a-nXmin)*xconv;
		
		} else {
			
			return NaN;
			
		}
		
		
	}
	
	public function ytoPix(a:Number): Number {
		
		var yconv:Number;
		
		if(bIsRangeSet){
		
		  yconv=nYSize/(nYmax-nYmin);
		
		return nYmax*yconv-a*yconv;
		
		} else {
			
			return NaN;
			
		}
		
	}
	
	public function xtoFun(a:Number): Number {
		
		var xconv:Number;
		
		if(bIsRangeSet){
		
		   xconv=nXSize/(nXmax-nXmin);
		
		return a/xconv+nXmin;
		
		} else {
			
			return NaN;
			
		}
		
		
		
	}
	
	public function ytoFun(a:Number): Number {
		
		var yconv:Number;
		
		if(bIsRangeSet){
		
		   yconv=nYSize/(nYmax-nYmin);
		
		return nYmax-a/yconv;	
		
		} else {
			
			return NaN;
			
		}
		
	}
	
	
		
	public function destroy():void {
		
		var i:int;
		
		var countBoard:int=spBoard.numChildren;
		
		var countHolder:int=spGraphsHolder.numChildren;
		
		var countMain:int=this.numChildren;
			
		spBoard.removeEventListener(MouseEvent.ROLL_OVER,boardOver);
		
		spBoard.removeEventListener(MouseEvent.ROLL_OUT,boardOut);
		
		spBoard.removeEventListener(MouseEvent.MOUSE_MOVE,boardMove);
		
		spBoard.removeEventListener(MouseEvent.MOUSE_DOWN,boardDown);
		
		spBoard.removeEventListener(MouseEvent.MOUSE_UP,boardUp);
		
		spBoard.mask=null;
		
		shAxes.graphics.clear();
		
		shBorder.graphics.clear();
		
		shCross.graphics.clear();
		
		shArrow.graphics.clear();
		
		shUser.graphics.clear();
		
		spBoard.graphics.clear();
		
		spMask.graphics.clear();
		
		for(i=0;i<nMaxNumGraphs;i++){
			
			aGraphs[i].graphics.clear();
			
		}
		
		for(i=0;i<countHolder;i++){
			
			spGraphsHolder.removeChildAt(0);
			
		}
		
		for(i=0;i<countBoard;i++){
			
			spBoard.removeChildAt(0);
			
		}
		
		for(i=0;i<countMain;i++){
			
			this.removeChildAt(0);
			
		}
		
		spMask=null;
		
		spBoard=null;
		
		spGraphsHolder=null;
		
		ErrorBox=null;
		
		spMask=null;
		
		shBorder=null;
		
		CoordsBox=null;
		
	}
		
	
}

}

