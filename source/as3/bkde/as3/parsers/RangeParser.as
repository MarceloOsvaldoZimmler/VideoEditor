/* ***********************************************************************
The classes in the package
bkde.as3.* were created by

Barbara Kaskosz of the University of Rhode Island
(bkaskosz@math.uri.edu) and
Douglas E. Ensley of Shippensburg University
(deensl@ship.edu).

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

Last modified: May 15, 2007
************************************************************************ */

package bkde.as3.parsers {

import bkde.as3.parsers.RangeObject;

import bkde.as3.parsers.MathParser;

public class RangeParser {
		
	public function RangeParser(){
		
		
		
	}
	
	
	public function parseRangeFour(a:String,b:String,c:String,d:String):RangeObject {
		
		var strArray:Array;
		
		var i:int;
		
		var roRange:RangeObject=new RangeObject();
		
		var mpParser:MathParser=new MathParser([]);
		
		var compOb:CompiledObject;
		
		strArray=[a,b,c,d];
		
		for(i=0;i<4;i++){
			
			
			if(strArray[i].length==0){
			
			roRange.errorStatus=1;
			roRange.errorMes="Check your variables ranges.";
			roRange.Values=[];
			return roRange;
						
		}
			
			strArray[i]=strArray[i].toLowerCase();
			
			if(strArray[i].indexOf("pi")==-1){
				
				strArray[i]=Number(strArray[i]);
						
		if(isNotLegal(strArray[i])){
			
			roRange.errorStatus=1;
			roRange.errorMes="Check your variables ranges.";
			roRange.Values=[];
			return roRange;
						
		} else {
			
			roRange.Values[i]=strArray[i];
						
		}
			
			} else {
				
			 compOb=mpParser.doCompile(strArray[i]);
			 
			 if(compOb.errorStatus==1){
				 
		    roRange.errorStatus=1;
			roRange.errorMes="Check your variables ranges.";
			roRange.Values=[];
			return roRange;
				 
				 
			 } else {
				 				 
				roRange.Values[i]=mpParser.doEval(compOb.PolishArray,[]);
				
				if(isNotLegal(roRange.Values[i])){
											 
					roRange.errorStatus=1;
			        roRange.errorMes="Check your variables ranges.";
			        roRange.Values=[];
			        return roRange;
											 											 
											 }
				 
			 }
							
				
			}
			
		}
		
		
		if(roRange.Values[0]>=roRange.Values[1] || roRange.Values[2]>=roRange.Values[3]){
			
			roRange.errorStatus=1;
			roRange.errorMes="Check your variables ranges.";
			roRange.Values=[];
			return roRange;
			
			
		} else {
			
			roRange.errorStatus=0;
			roRange.errorMes="";
			return roRange;
			
		}
		
		
	}
	
	
	public function parseRangeTwo(a:String,b:String):RangeObject {
		
		var strArray:Array;
		
		var i:int;
		
		var roRange:RangeObject=new RangeObject();
		
		var mpParser:MathParser=new MathParser([]);
		
		var compOb:CompiledObject;
		
		strArray=[a,b];
		
		for(i=0;i<2;i++){
			
			if(strArray[i].length==0){
			
			roRange.errorStatus=1;
			roRange.errorMes="Check your variables ranges.";
			roRange.Values=[];
			return roRange;
						
		}
			
			strArray[i]=strArray[i].toLowerCase();
			
			if(strArray[i].indexOf("pi")==-1){
				
				strArray[i]=Number(strArray[i]);
						
		if(isNotLegal(strArray[i])){
			
			roRange.errorStatus=1;
			roRange.errorMes="Check your variables ranges.";
			roRange.Values=[];
			return roRange;
						
		} else {
			
			roRange.Values[i]=strArray[i];
						
		}
			
			} else {
				
			 compOb=mpParser.doCompile(strArray[i]);
			 
			 if(compOb.errorStatus==1){
				 
		    roRange.errorStatus=1;
			roRange.errorMes="Check your variables ranges.";
			roRange.Values=[];
			return roRange;
				 
				 
			 } else {
				 				 
				roRange.Values[i]=mpParser.doEval(compOb.PolishArray,[]);
				
				if(isNotLegal(roRange.Values[i])){
											 
					roRange.errorStatus=1;
			        roRange.errorMes="Check your variables ranges.";
			        roRange.Values=[];
			        return roRange;
											 											 
											 }
				 
			 }
							
				
			}
			
		}
		
		
		if(roRange.Values[0]>=roRange.Values[1]){
			
			roRange.errorStatus=1;
			roRange.errorMes="Check your variables ranges.";
			roRange.Values=[];
			return roRange;
			
			
		} else {
			
			roRange.errorStatus=0;
			roRange.errorMes="";
			return roRange;
			
		}
		
		
	}
	
		
	
	protected function isNotLegal(n:*):Boolean {
		
		if((typeof n)!="number" || isNaN(n) || !isFinite(n)){
			
			return true; } 
			
			else {return false;}
		
	}
	
	
	
}

}