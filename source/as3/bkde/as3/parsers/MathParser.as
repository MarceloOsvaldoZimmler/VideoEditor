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

Preliminary version.(The class works but it needs to be polished to comply
with best programming practices in ActionScript 3.0)

Last modified: June 30, 2007
************************************************************************ */

package bkde.as3.parsers {

import bkde.as3.parsers.CompiledObject;

 public class MathParser {

  private  var f1Array:Array=["sin","cos","tan","ln","sqrt", "abs", "acos","asin", "atan" ,"ceil", "floor", "round"];
  private  var f2Array:Array=["max","min","plus","minus","mul","div","pow"];
    
  private var iserror:Number;
  private var errorMes:String;	
	
	
  private var tokenvalue:String;
  private var tokentype:String;
  private var tokenlength:Number;

  private var nums:String="0123456789.";
  private var lets:String="abcdefghijklmnopqrstuwvxzy";
  private var opers:String="^*+-/(),";
	
  private var aVarNames:Array;
  
  public function MathParser(varArray:Array){
		
		if(varArray.length==0){
			
			this.aVarNames=[];
			
			} else {
				
		      this.aVarNames=setVars(varArray);
		
			}
		
		this.iserror=0;
	
	    this.errorMes="";
		
	}
	
private function setVars(v:Array):Array {
	
	var tranNames:Array=[];
	
	var i:Number;
	
	for(i=0; i<v.length;i++){
			
			if((typeof v[i])!="string"){
				
				trace("All variables must be entered as strings into MathParser constructor. Don't forget quotation marks.");
			}
						
				
			tranNames[i]=v[i].toLowerCase();			
			
		}
			
		
		return tranNames;
		
}
	

public function doCompile(inputstring:String):CompiledObject {
	
	var coCompObj:CompiledObject=new CompiledObject();
	
	var stepString:String;
	
	var conString:String;
	
	var fstack:Array=[];
	
	iserror=0;
	
	errorMes="";
	
	stepString=whiteSpaces(inputstring);
	
	if(stepString==""){
		
		coCompObj.PolishArray=[];
		
		coCompObj.errorMes="";
		
		coCompObj.errorStatus=0;
		
		return coCompObj;
		
	}
	
	checkLegal(stepString);
	
	if(iserror==1){
		
		coCompObj.PolishArray=[];
		
		coCompObj.errorMes=errorMes;
		
		coCompObj.errorStatus=1;
		
		return coCompObj;
		
		}
	
	checkPars(stepString);
	
	if(iserror==1){
		
		coCompObj.PolishArray=[];
		
		coCompObj.errorMes=errorMes;
		
		coCompObj.errorStatus=1;
		
		return coCompObj;
				
		}
	
	checkToks(stepString);
	
	if(iserror==1){
		
		coCompObj.PolishArray=[];
		
		coCompObj.errorMes=errorMes;
		
		coCompObj.errorStatus=1;
		
		return coCompObj;
		
		
		}
	
	conString=conOper(conOper(conOper(conOper(conUnary(conCaret(stepString)),"/"),"*"),"-"),"+");
    
	if(iserror==1){
		
		coCompObj.PolishArray=[];
		
		coCompObj.errorMes=errorMes;
		
		coCompObj.errorStatus=1;
		
		return coCompObj;
		
		}
	
	fstack=makeStack(conString);
	
	if(iserror==1){
		
		coCompObj.PolishArray=[];
		
		coCompObj.errorMes=errorMes;
		
		coCompObj.errorStatus=1;
		
		return coCompObj;
			
		}
	
	else {
		
		coCompObj.PolishArray=fstack;
		
		coCompObj.errorMes="";
		
		coCompObj.errorStatus=0;
		
		return coCompObj;		
		
		}
	
}



private function istokf1(chars:String):Boolean {
	
	var i:Number;
	
	for(i=0; i< f1Array.length; i++){
		
	  if(chars == f1Array[i]){return true;}
	  
	}
	
	return false;
}


private function isVar(chars:String):Boolean {
	
	var i:Number;
	
	for(i=0; i< aVarNames.length; i++){
		
	  if(chars == aVarNames[i]){return true;}
	  
	}
	
	return false;
}


private function istokf2(chars:String):Boolean {
	
	var i:Number;
	
	for(i=0; i< f2Array.length; i++){
		
	  if(chars == f2Array[i]){return true;}
	  
	}
	
	return false;
}


private function isLet(char:String):Boolean {
	
	return lets.indexOf(char) >= 0 ;
	
}


private function isOper(char:String):Boolean {
	
	return opers.indexOf(char) >= 0 ;
	
}

private function isNum(char:String):Boolean {
	
	return nums.indexOf(char) >= 0 ;
	
}

private function setToken(curtype:String,curvalue:String,curlength:Number):void {
	
	tokentype=curtype;
	
	tokenvalue=curvalue;
	
	tokenlength=curlength;
}



private function nextToken(inputstring:String,pos:Number):Boolean {
	
  var char, t, inilen, cpos, cstring;
  
  cstring=inputstring;
  
  cpos=pos;
  
  inilen=inputstring.length;
 
  if(cpos >= inilen || cpos<0){return false; }
  
   else {
	   
        char=cstring.charAt(cpos);
		
		if(isLet(char)){
			
		  t=char;
		 
		  do{
			 cpos+=1;
			 
			 if(cpos >= inilen) break;
			 
			 char=cstring.charAt(cpos);
			 
			 if(!isLet(char)) break;
						
			 t+=char;
			 
		     }while(1);
	
		  if(istokf1(t)){setToken("f1",t, t.length); return true; }
		  
		  else if(istokf2(t)){setToken("f2",t, t.length); return true;}
									  
	      else { setToken("v",t,t.length); return true;}
			 
		   		
		              }
					  
		 if(isNum(char)){
			
		  t=char;
		 
		  do{
			 cpos+=1;
			 
			 if(cpos >= inilen) break;
			 
			 char=cstring.charAt(cpos);
			 
			 if(!isNum(char)) break;
						
			 t+=char;
			 
		     }while(1);
		
									  
	      setToken("n",t,t.length); return true;
			 		   		
		              }
		 
		  if(isOper(char)){ 
		    
			   setToken("oper",char,1); return true;
		  }
		  
		  
		  return false;
  	
         }
	
}



function checkToks(inputstring:String):void {
	
	var pstring, pinilen, ppos, fpos, bpos, fchar, 
	bchar, counter, matchpar, iscomma, comcounter;
		
	pstring=inputstring;
	
	ppos=0;
	
	counter=0;
	
	comcounter=0;
		
	pinilen=pstring.length;
	
	if(pstring.indexOf("---")>=0){
		
		callError("No need for so many minuses.");
							 
		return;
		
	} 
	
	while(ppos < pinilen && counter<pinilen*2){
		
	if(nextToken(pstring,ppos)){
		
		     fpos=ppos+tokenlength;
			 
			 fchar=pstring.charAt(fpos);
			 
			 bpos=(ppos-1);
			 
			 bchar=pstring.charAt(bpos);
	
	       if(tokentype=="f1"){
			 
			 if(!(fchar=="(")){
						   
				callError("'(' expected at position " + fpos +".");
							 
				return;						   
			    }
				
			 if(ppos > 0 && !(isOper(bchar))){
									 
					callError("Operator expected at position " + bpos +".");
							 
				    return;
					
					}
					
			 if(ppos > 0 && bchar==")"){
									 
					callError("Operator expected at position " + bpos +".");
							 
				    return;
					
					}
			
		   }
		   
		   if(tokentype=="f2"){
			   
			   if(!(tokenvalue=="max") && !(tokenvalue=="min")){
				 
				callError("Unknown functions at position " + fpos +".");
							 
				return;
				   
			   }
			   
			   if(!(fchar=="(")){
						   
				callError("'(' expected at position " + fpos +".");
							 
				return;
				
			    } else {
					
					matchpar=1; iscomma=0; comcounter=0;
					
					while(matchpar>0 && comcounter<pinilen){
						
					   comcounter+=1;
					   
					   if(pstring.charAt(fpos+comcounter)=="("){matchpar+=1;}
				   
				       if(pstring.charAt(fpos+comcounter)==")"){matchpar+=-1;}
					   
					   if(pstring.charAt(fpos+comcounter)==","){iscomma+=1;}
						
					}
					
					if(iscomma==0){
						
				    callError("Two arguments expected for function at position " + ppos +".");
							 
				    return;
												
					}
										
				}
			 
			 if(ppos > 0 && !(isOper(bchar))){
									 
					callError("Operator expected at position " + bpos +".");
							 
				    return;
					
					}
					
			if(ppos > 0 && bchar==")"){
									 
					callError("Operator expected at position " + bpos +".");
							 
				    return;
					
					}
						
		   }
		   
		   if(tokentype=="v"){
			
			if(!(isVar(tokenvalue) || tokenvalue=="pi" || tokenvalue=="e")){
				
				callError("Unknown entries at position " + ppos +".");
							 
				return;
				
			}
			
			if(ppos > 0 && !(isOper(bchar))){
									 
					callError("Operator expected at position " + bpos +".");
							 
				    return;
					
					}
					
			if(ppos > 0 && bchar==")"){
									 
					callError("Operator expected at position " + bpos +".");
							 
				    return;
					
					}
					
			if(fpos < pinilen && !(isOper(fchar))){
									 
					callError("Operator expected at position " + fpos +".");
							 
				    return;
					
					}
					
			if(fpos < pinilen && fchar=="("){
									 
					callError("Operator expected at position " + fpos +".");
							 
				    return;
					
					}
			
		   }
		   
		   if(tokentype=="n"){
			   
			   if(ppos > 0 && !(isOper(bchar))){
									 
					callError("Operator expected at position " + bpos +".");
							 
				    return;
					
					}
					
			if(ppos > 0 && bchar==")"){
									 
					callError("Operator expected at position " + bpos +".");
							 
				    return;
					
					}
					
			if(fpos < pinilen && !(isOper(fchar))){
									 
					callError("Operator expected at position " + fpos +".");
							 
				    return;
					
					}
					
			if(fpos < pinilen && fchar=="("){
									 
					callError("Operator expected at position " + fpos +".");
							 
				    return;
					
					}
			
		      }
			  
		if(tokenvalue=="("){
						 
			       if(fpos < pinilen && ("^*,)+/").indexOf(fchar)>=0){
									 
					callError("Entries expected at position " + fpos +".");
							 
				    return;
					
					}
					
										
				}
				
	    if(tokenvalue==")"){
				  
				   if(fpos < pinilen && ("^*+-,/)").indexOf(fchar)==-1){
									 
					callError("Entries expected at position " + fpos +".");
							 
				    return;
					
					}
					
					if(bpos >=0 && ("^*+-,/(").indexOf(bchar)>=0){
									 
					callError("Entries expected at position" + fpos +".");
							 
				    return;
					
					}
				
				
				 }
				 
		if(tokenvalue==","){
			
			       if(ppos==0 || ppos==pinilen-1){
					   
					callError("Stray comma at position " + ppos +".");
							 
				    return;
					   
					   
				   }
				  
				   if(fpos < pinilen && ("^*+,/)").indexOf(fchar)>=0){
									 
					callError("Entries expected at position " + fpos +".");
							 
				    return;
					
					}
					
					if(bpos >=0 && ("^*+-,/(").indexOf(bchar)>=0){
									 
					callError("Entries expected at position " + fpos +".");
							 
				    return;
					
					}
				
				
				 }
				 
		  if(("^/*-+").indexOf(tokenvalue)>=0){
			  
			 if(("+*^/),").indexOf(fchar)>=0){
				 
				 callError("Entries expected at position " + fpos +".");
							 
				 return;
			 
			 }
			 
			 if(("+*^/(,").indexOf(bchar)>=0 && !(tokenvalue=="-")){
				 
				 callError("Entries expected at position " + fpos +".");
							 
				 return;
			 
			 }
			 
			 
			  
		  }
		
						 
	
	}
	
	else {callError("Unknown characters at position ." + ppos);}
	
	ppos+=tokenlength;
	
	counter+=1;

    }
	
}

	


private function conOper(inputstring:String, char:String):String {

  var transtring, inilen, mco, curpos, leftoper, rightoper,leftmove,rightmove;

  inilen=inputstring.length;
  
  transtring=inputstring;
  
  if(transtring.indexOf(char)==-1){
		
        return transtring;}
		
   else if(transtring.indexOf(char)==0 && !(char=="-")){
		
		callError("Error at the first " + char);
		
        return "";}
		
   else if(transtring.charAt(transtring.length-1)==char){
		
		callError("Error at the last " + char + ".");
				
        return "";}
				
   else{mco=0;
			
   while(transtring.indexOf(char)>0 && mco<inilen*6){
	   
	   mco+=1;
   
	   curpos=transtring.indexOf(char);
	 
	   leftmove=goLeft(transtring,curpos);
	   
	   if(iserror==1){
		   
		   callError("Error at  " + char + "  number " + mco + ".");
		   
		   return ""; } 
		   
		else { leftoper=transtring.substring(leftmove+1,curpos); }
		
		rightmove=goRight(transtring,curpos);
	   
	   if(iserror==1){
		   
		   callError("Error at  " + char + "  number " + mco + ".");
		   
		   return ""; } 
		   
		else { rightoper=transtring.substring(curpos+1, rightmove); }
		
		if(char=="*"){
		
	   transtring=transtring.substring(0,leftmove+1)
	           +"mul("+ leftoper+ "," + rightoper + ")" + 
	   transtring.substring(rightmove,transtring.length+1);
		}
		
		if(char=="/"){
		
	   transtring=transtring.substring(0,leftmove+1)
	           +"div("+ leftoper+ "," + rightoper + ")" + 
	   transtring.substring(rightmove,transtring.length+1);
		}
		
		if(char=="-"){
		
	   transtring=transtring.substring(0,leftmove+1)
	           +"minus("+ leftoper + "," + rightoper + ")" + 
	   transtring.substring(rightmove,transtring.length+1);
		}
		
		if(char=="+"){
		
	   transtring=transtring.substring(0,leftmove+1)
	           +"plus("+ leftoper + "," + rightoper + ")" + 
	   transtring.substring(rightmove,transtring.length+1);
		}
	   
	   if(transtring.length>inilen*7){
		 
		 callError("Oooops!");
		 
		 return "";}
}
		
	return transtring;
   }
		
}


private function conUnary(inputstring:String):String {
		
  var transtring, inilen, mco, curpos, i, j;
     
  inilen=inputstring.length;
  
  transtring=inputstring;
  
  if(transtring.indexOf("-")==-1){
	    
        return transtring;}
		
  if(transtring.charAt(transtring.length-1)=="-"){
	  
	  callError("Error at the last minus.");
	  
	  return "";}

  for(i=0; i<transtring.length; i++){
	   
	   if(transtring.charAt(i)=="-" && unaryId(transtring.charAt(i-1)))
	    {    
		   j=goRight(transtring, i);
		   
		   if(iserror==1){
		   
		   callError("Error at position " + i);
		   
		   return ""; }
		   
		   transtring=transtring.substring(0,i)+"minus(0,"+transtring.substring(i+1,j) + ")" + transtring.substring(j,transtring.length);
				
		}
		
		if(transtring.length > 9*inilen){
			
			callError("Ooops!");
			
			return "";}
	  
  }

 
  return transtring;
	
}

private function unaryId(char:String):Boolean { 

    if("+-,(/*^".indexOf(char)>-1){return true;} 
					
	 else {return false;}
}


private function goRight(inputstring:String, pos:Number):Number {
	
	var rightchar, rightcounter, matchpar;
	
	rightchar=inputstring.charAt(pos+1);
	
	rightcounter=pos+1;
	
if(rightchar=="-"){
	   
	    rightcounter+=1; 
	   
        if(rightcounter>=inputstring.length){
	    
		iserror=1;
		
		return rightcounter;}
		
		else{
			
	    rightchar=inputstring.charAt(rightcounter);}
  }
  

if(nums.indexOf(rightchar)>-1){ 

while(nums.indexOf(inputstring.charAt(rightcounter))>-1 
		&& rightcounter<inputstring.length)
		   { 
		     rightcounter+=1;
		   }
		   
		  }
		  
else if(lets.indexOf(rightchar)>-1){
   
  while(lets.indexOf(inputstring.charAt(rightcounter))>-1 
		   && rightcounter<inputstring.length)
		   {
			  rightcounter+=1;		   
		   }
	
		   
     if(inputstring.charAt(rightcounter)=="("){
							
	  matchpar=1;
		
      while(matchpar>0 && rightcounter<inputstring.length)
		   {  
			  rightcounter+=1;
			  
		  if(inputstring.charAt(rightcounter)=="("){matchpar+=1;}
												
		  if(inputstring.charAt(rightcounter)==")"){matchpar+=-1;} 
		   }
		  		
		}
				
	if(matchpar>0){
		
			iserror=1;
			
			return rightcounter;
			
			}
			
		  }
		  
		  
 else if(rightchar=="("){
			
	  matchpar=1;
			
      while(matchpar>0 && rightcounter<inputstring.length)
		   {  
		      rightcounter+=1;
		   
			  if(inputstring.charAt(rightcounter)=="("){matchpar+=1;}
													
		      if(inputstring.charAt(rightcounter)==")"){matchpar+=-1;}
			  
		   }
		   rightcounter+=1;
		   
		   
		   if(matchpar>0){
		    
			iserror=1;
			
			return rightcounter;}
		  }
		  
 else { 
			iserror=1;
			  
			return rightcounter;}
			  
return rightcounter;
	
}



private function goLeft(inputstring:String,pos:Number):Number {
	
	var leftchar, leftcounter, matchpar;
	
	leftchar=inputstring.charAt(pos-1);
	
	leftcounter=pos-1;
	
if(nums.indexOf(leftchar)>-1){
		   
     while(nums.indexOf(inputstring.charAt(leftcounter))>-1 && leftcounter>=0)
		   { 		   		     
		   leftcounter+=-1; 
		   }
		   
     }
		  
else if(lets.indexOf(leftchar)>-1){
		   
     while(lets.indexOf(inputstring.charAt(leftcounter))>-1 && leftcounter>=0)
		   { 		   		     
		   leftcounter+=-1; 
		   }
	      
		  }
   

else if(leftchar==")"){
	  
	  matchpar=1;
  
     if(leftcounter==0){
						 iserror=1;
						 
						 return leftcounter;}
						 
						 
       while(matchpar>0 && leftcounter>0)
		   {
		   leftcounter+=-1;
		   
		   if(inputstring.charAt(leftcounter)==")"){matchpar+=1;}
		   
		   if(inputstring.charAt(leftcounter)=="("){matchpar+=-1;}		   
		   }
		   leftcounter+=-1;
		   
	  if(matchpar>0){
	 
	        iserror=1;
			
			return leftcounter;
			}
		   
      if(leftcounter>=0 && nums.indexOf(inputstring.charAt(leftcounter))>-1){
	
					iserror=1;
					
					return leftcounter;}
						 
      if(leftcounter==0 && !(inputstring.charAt(leftcounter)=="-")
							&& !(inputstring.charAt(leftcounter)=="(")){
	
	                iserror=1;
	  
	                return leftcounter;}
	
     if(leftcounter>0 && lets.indexOf(inputstring.charAt(leftcounter))>-1){
		   
     while(lets.indexOf(inputstring.charAt(leftcounter))>-1 && leftcounter>=0)
		   { 		   
		   leftcounter+=-1; 		   
		   }
 
		  }
		    			
		}		  


 else {
		
		iserror=1;
		
		return leftcounter;
		
		}
		
		
return leftcounter;
		
	
}


private function conCaret(inputstring:String):String {

var transtring, inilen, mco, curpos, leftmove,
rightmove, base, expon;

  inilen=inputstring.length;
  
  transtring=inputstring;
  
  if(transtring.indexOf("^")==-1){
		
        return transtring;}
		
   else if(transtring.indexOf("^")==0){
		
		callError("Error at the first ^.");
		
        return "";}
		
   else if(transtring.charAt(transtring.length-1)=="^"){
		
		callError("Error at the last ^.");
				
        return "";}
				
   else{mco=0;
			
   while(transtring.indexOf("^")>0 && mco<inilen*6){
	   
	   mco+=1;
   
	   curpos=transtring.lastIndexOf("^");
	 
	   leftmove=goLeft(transtring,curpos);
	   
	   if(iserror==1){
		   
		   callError("Error at ^ number " + mco + " from the end.");
		   
		   return ""; } 
		   
		else { base=transtring.substring(leftmove+1,curpos); }
		
		rightmove=goRight(transtring,curpos);
	   
	   if(iserror==1){
		   
		   callError("Error at ^ number " + mco + " from the end.");
		   
		   return ""; } 
		   
		else { expon=transtring.substring(curpos+1, rightmove); }
		
	   transtring=transtring.substring(0,leftmove+1)
	           +"pow("+ base+ "," + expon + ")" + 
	   transtring.substring(rightmove,transtring.length+1);
	   
	   if(transtring.length>inilen*7){
		 
		 callError("Oooops!");
	
		 return "";}
}
		
	return transtring;
   }
		
}


private function whiteSpaces(inputstring:String):String {

   var curpos, transtring, inilen, counter=0;
   
   inilen=inputstring.length;
   
   transtring=inputstring.toLowerCase();
   
   while(transtring.indexOf(" ")>-1 && counter < inilen+1){
	   
	 curpos=transtring.indexOf(" ");
	 
	 transtring=transtring.substring(0,curpos) + 
	 transtring.substring(curpos+1,transtring.length);
	   
	 counter+=1;
	
   }

   return transtring;
		
}


private function checkLegal(inputstring:String):Boolean {
	
	  var i, legal, curchar;

      if(inputstring==""){
	   
	  callError("Empty input.");
	   
	  return false;}
	   
      for(i=0; i<inputstring.length; i++){
	
      curchar=inputstring.charAt(i);
	
      legal=nums.indexOf(curchar)+lets.indexOf(curchar)+opers.indexOf(curchar);

      if(legal==-3){
	   
	      callError("Unknown characters.");
	 
	      return false;}
	 
   }
      return true;	
}


private function checkPars(inputstring:String):Boolean {
	
	var i, j, matchpar, left=0, right=0, counter=0;
	
	for(i=0; i<inputstring.length; i++){
		
		if(inputstring.charAt(i)=="("){left+=1;}
									
		if(inputstring.charAt(i)==")"){right+=1;}
	}
		
		if(!(left==right)){
			
			callError("Mismatched parenthesis.");
			
			return false;}
			
	for(j=0; j<inputstring.length; j++){
			
		if(inputstring.charAt(j)=="("){
									
	    matchpar=1; counter=0;
			
        while(matchpar>0 && counter<inputstring.length)
		   {  
		      counter+=1;
			  
			  if(inputstring.charAt(j+counter)=="("){matchpar+=1;}
													
		      if(inputstring.charAt(j+counter)==")"){matchpar+=-1;}
			  
		   }
		  
		   if(matchpar>0){
			   
			j+=1;
		    
			callError("Mismatched parenthesis at position number " + j); 
			
			return false;
			
			}
			
		  }
					
		}
		
		
		for(j=0; j<inputstring.length; j++){
			
		if(inputstring.charAt(j)==")"){
					
	    matchpar=1; counter=0;
			
        while(matchpar>0 && counter<inputstring.length)
		   {  
		      counter+=1;
			  
			  if(inputstring.charAt(j-counter)==")"){matchpar+=1;}
													
		      if(inputstring.charAt(j-counter)=="("){matchpar+=-1;}
			  
		   }
		   
	
		   if(matchpar>0){
			   
			j+=1;
		    
			callError("Mismatched parenthesis at position number " + j); 
			
			return false;
			
			}
			
		  }
					
		}
			
		return true;
}



private function makeStack(inputstring:String):Array {
	
	var mstring, minilen, mpos, mstack, checkStack, 
	checkExpr, counter, checkResult;
		
	mstring=inputstring;
	
	mpos=0;
	
	mstack=[];
	
	checkStack=[];
	
	minilen=mstring.length;
	
	checkExpr=[];
	
	checkResult=[];
	
	counter=0;
	

while(mpos < minilen && counter<minilen*2){
		
	if(nextToken(mstring,mpos)){
	
	       if(tokentype=="f1"){
			
			 mstack.push(this[tokenvalue]);
			 
			 mstack.push("f1");
			 
			checkStack.push(this["sin"]);
	
			checkStack.push("f1");
			
		   }
		   
		   if(tokentype=="f2"){
			
			 mstack.push(this[tokenvalue]);
			 
			 mstack.push("f2");
			 
			checkStack.push(this["plus"]);
			 
			checkStack.push("f2");
			
		   }
		   
		   if(tokentype=="v"){
			
			 mstack.push(tokenvalue);
			 
			 mstack.push("v");
			 
			 checkStack.push("x");
			 
			 checkStack.push("v");
			
		   }
		   
		   if(tokentype=="n"){
			
			 mstack.push(Number(tokenvalue));
			 
			 mstack.push("n");
			 
			checkStack.push(Number(tokenvalue));
			 
			checkStack.push("n");
			
		   }
	
	}
	
	else {callError("Unknown characters."); return [];}
	
	mpos+=tokenlength;
	
	counter+=1;

}


mstack.reverse();

checkExpr=checkStack.reverse();

checkEval(checkExpr);

if(iserror==1){return [];}

return(mstack);
	
}


private function callError(mess:String):void {
      
	  errorMes="Syntax error. " + mess;
	  
	  iserror=1;
	
}


private function checkEval(compiledExpression:Array):void {


	var entrytype="";

	var operands=[];
	
	var arg1, arg2;

	for( var i = 0; i < compiledExpression.length; i++){

		entrytype = compiledExpression[i++];

		if(entrytype == "n"){
			
			operands.push(compiledExpression[i]);
	
		} else if( entrytype == "v"){
			
			operands.push(1);
					
		}  else if( entrytype == "f1"){
			
			if(operands.length<1){callError("Check number of arguments in your functions."); return;}

			operands.push(compiledExpression[i](operands.pop()))
		
		} else if( entrytype == "f2"){
			
			if(operands.length<2){callError("Check number of arguments in your functions."); return;}
					
			arg1=operands.pop(); arg2=operands.pop();
			
			operands.push(compiledExpression[i](arg1,arg2));				

		} else {

		 callError("Can't evaluate."); return;

		}

		
	}
     
	
	if(!(operands.length==1)){
	
	callError(""); 
	
	return;
}

if(isNaN(operands[0])){

	callError(""); 
	
	return;
}
	
}





private function sin(a){
	
	return Math.sin(a);
	
}

private function cos(a){
	
	return Math.cos(a);
	
}


private function tan(a){
	
	return Math.tan(a);
	
}


private function ln(a){
	
	return Math.log(a);
	
}


private function sqrt(a){
	
	return Math.sqrt(a);
	
}


private function abs(a){
	
	return Math.abs(a);
	
}


private function asin(a){
	
	return Math.asin(a);
	
}

private function acos(a){
	
	return Math.acos(a);
	
}


private function atan(a){
	
	return Math.atan(a);
	
}



private function floor(a){
	
	return Math.floor(a);
	
}



private function ceil(a){
	
	return Math.ceil(a);
	
}

private function round(a){
	
	return Math.round(a);
	
}


private function max(a,b){
	
	return Math.max(a,b);
	
}


private function min(a,b){
	
	return Math.min(a,b);
	
}


private function plus(a,b){

	return a + b;

}




private function minus(a,b){

	return a - b;

}



private function mul(a,b){

	return a * b;

}


private function div(a,b){

	return a / b;

}



private function  pow(a, b) {

   
    if (a<0 && b==Math.floor(b)){

        if((b % 2)==0){return Math.pow(-a, b);}

        else {return -Math.pow (-a, b);}

    }
	
	 if (a==0 && b>0){return 0;}
	 
	 if(isNaN(a) && b==0){
		 
		return NaN;
		
	 }

    return Math.pow (a, b);

}



public function doEval(compiledExpression:Array,aVarVals:Array): Number {

	var entrytype:String="";

	var operands:Array=[];
	
	var i:Number;
	
	var j:Number;
	
	var arg0;
	
	var arg1;
	
	var arg2;
	
	if(aVarVals.length!=aVarNames.length){
		
		return NaN; 
		
	}
	
	for(j = 0; j < aVarVals.length; j++){
		
		if((typeof aVarVals[j])!="number"){
			
			return NaN;
			
		}
		
	}

	for(i = 0; i < compiledExpression.length; i++){

		entrytype = compiledExpression[i++];

		if(entrytype == "n"){
			
			operands.push(compiledExpression[i]);

		} else if( entrytype == "v"){
						
			if(compiledExpression[i]=="e"){
				
				operands.push(Math.E);
				
			} else if(compiledExpression[i]=="pi"){
				
				operands.push(Math.PI);
				
				}
				
		  else {
		
		for(j=0; j<aVarNames.length; j++){
			
			if(compiledExpression[i]==aVarNames[j]){
				
				operands.push(aVarVals[j]);
				
			}
			
		}
		
	}
			
			
		}  else if( entrytype == "f1"){
			
	
			arg0=operands.pop();
			
			
			if(compiledExpression[i]==sin){
				
				operands.push(Math.sin(arg0));
				
				
			} 
			
			else if(compiledExpression[i]==cos){
				
				operands.push(Math.cos(arg0));
				
				
			} 
			
			else if(compiledExpression[i]==tan){
				
				operands.push(Math.tan(arg0));
				
				
			}
			
			else if(compiledExpression[i]==asin){
				
				operands.push(Math.asin(arg0));
				
				
			}
			
			else if(compiledExpression[i]==acos){
				
				operands.push(Math.acos(arg0));
				
				
			}
			
			else if(compiledExpression[i]==atan){
				
				operands.push(Math.atan(arg0));
				
				
			}
			
			else if(compiledExpression[i]==ln){
				
				operands.push(Math.log(arg0));
							
			}
			
			else if(compiledExpression[i]==sqrt){
				
				operands.push(Math.sqrt(arg0));
				
				
			}
			
			else if(compiledExpression[i]==abs){
				
				operands.push(Math.abs(arg0));
				
				
			}
			
			else if(compiledExpression[i]==ceil){
				
				operands.push(Math.ceil(arg0));
				
				
			}
			
			else if(compiledExpression[i]==floor){
				
				operands.push(Math.floor(arg0));
				
				
			}
			
			else if(compiledExpression[i]==round){
				
				operands.push(Math.round(arg0));
				
				
			}
			
			else {
					
			operands.push(compiledExpression[i](arg0));
			
			}
			

		} else if(entrytype == "f2"){
			
			arg1=operands.pop(); arg2=operands.pop();
			
			
			if(compiledExpression[i]==mul){
				
				operands.push(arg1*arg2);
				
				
			} 
			
			else if(compiledExpression[i]==plus){
				
				operands.push(arg1+arg2);
				
				
			} 
			
			else if(compiledExpression[i]==minus){
				
				operands.push(arg1-arg2);
				
				
			}
			
			else if(compiledExpression[i]==div){
				
				operands.push(arg1/arg2);
				
				
			}
			
			else if(compiledExpression[i]==pow){
				
				operands.push(Math.pow(arg1,arg2));
				
				
			}
			
			else if(compiledExpression[i]==min){
				
				operands.push(Math.min(arg1,arg2));
				
				
			}
			
			else if(compiledExpression[i]==max){
				
				operands.push(Math.max(arg1,arg2));
							
			}
			
			else {
			
			operands.push(compiledExpression[i](arg1,arg2));	
			
			}
			

		} else {

			return NaN;

		}
		
	}
	
	return operands[0]

}

}

}
