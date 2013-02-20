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
	import flash.geom.Matrix;
	import flash.filters.*;
	import flash.display.*;
	import flash.geom.*;
/**
* Implementation class for convolution effect module
*
* @see IModule
* @see Clip
* @see Mash
*/
	public class Convolution extends ModuleEffect
	{
		public function Convolution()
		{
			_defaults.matrix = '0,0,0,0,0,0,0,0,0';
			_defaults.bias = 0;
			_defaults.divisor = 0;

		}
		
		override public function set time(object:Time):void
		{
			super.time = object;
			var matrix:String = _getClipProperty('matrix');
			var divisor:Number = _getClipPropertyNumber('divisor');
			var bias:Number = _getClipPropertyNumber('bias');
			var a:Array = matrix.split(',');
			var z:uint = a.length;
			var matrix_dim:Number = Math.sqrt(z);
			var i:uint;
			for (i = 0; i < z; i++)
			{
				a[i] = Number(a[i]);
			}
			if (! bias)
			{
				bias = 0;
			}
			if (! divisor)
			{
				z = a.length;
				for (i = 0; i < z; i++)
				{
					divisor += a[i];
				}
			}
			_moduleFilters = [new ConvolutionFilter(matrix_dim, matrix_dim, a, divisor, bias)];
		}
	}
}
//"blur_1",0,8,0,8,-19,8,0,8,0
//"blur_2",8,0,8,0,-21,0,8,0,8
//"borders",10,10,10,10,10,-10,-10,-10,-10
//"carve_a",10,0,0,0,6,0,0,0,-10
//"carve_b",10,0,0,0,6,0,0,0,-10
//"carve_b_inv",10,10,-10,40,5,-40,10,-10,-10
//"cleanup",1,-1,-1,1,10,-1,1,1,1
//"emboss_L",10,10,0,10,0,-10,0,-10,-10
//"emboss_R",0,10,10,-10,10,10,-10,-10,-10
//"clouds",2,7,2,7,-33,7,2,7,2
//"chrome_1",10,0,-10,20,1,-20,10,0,-10
//"outline",10,10,10,10,-70,10,10,10,10
//"splotch_a",10,10,-10,40,0,-40,10,-10,-10
//"splotch_b",-10,10,-10,10,10,10,-10,10,-10
//"hi_pass_a",-10,-10,-10,-10,90,-10,-10,-10,-10
//"hi_pass_b",10,10,10,-10,60,10,-10,-10,-10
//"lo_pass_a",1,1,1,1,2,1,1,1,1
//"lo_pass_b",1,1,10,1,2,1,1,1,1
//"edge_line",0,-10,0,-10,40,-10,0,-10,0
//"edge_normal_a",10,10,10,-10,-5,10,-10,-10,-10
//"edge_normal_b",10,10,10,-10,0,10,-10,-10,-10
//"mistery",-10,-10,-10,-10,80,-10,-10,-10,-10
//"funky",10,0,0,0,-15,0,10,0,-10
//"ghost_blur",16,0,16,0,-55,0,16,0,16

/*
LINE DETECTION
Detection of one pixel wide lines can accomplished with the following filters: 
Horizontal Edge
-1 -1 -1
2 2 2
-1 -1 -1
Vertical Edge
-1 2 -1
-1 2 -1 
-1 2 -1
Left Diagonal Edge
2 -1 -1
-1 2 -1
-1 -1 2
Right Diagonal Edge
-1 -1 2
-1 2 -1
2 -1 -1

GRADIENT DETECTION
Changes in value over 3 pixels can be detected using kernels called Gradient Masks or Prewitt Masks. The direction of the change from darker to lighter is described by one of the points of the compass. The 3x3 kernels are as follows: 
Embossing North
-1 -2 -1
0 0 0
1 2 1
Embossing West
-1 0 1
-2 0 2
-1 0 1
Embossing East
1 0 -1
2 0 -2
1 0 -1
Embossing South
1 2 1
0 0 0
-1 -2 -1
Embossing NorhtEast
0 -1 -2
1 0 -1
2 1 0

SMOOTHING AND BLURRING
Smoothing and blurring operations are low-pass spatial filters. They reduce or eliminate high-frequency aspects of an image. 
Arithmetic Mean
The arithmetic mean simply takes an average of the pixels in the kernel. Each
element in the filter is equal to 1 divided by the total number of elements in
the filter. Thus the 3x3 arithmetic mean filter is: 
1/9 1/9 1/9
1/9 1/9 1/9
1/9 1/9 1/9
Basic Smooth 3x3 (not normalized)
1 2 1
2 4 2
1 2 1
Basic Smooth 5x5 (not normalized) 
1 1 1 1 1
1 4 4 4 1
1 4 12 4 1
1 4 4 4 1
1 1 1 1 1

HIGH-PASS FILTERS
A high-pass filter enhances the high-frequency parts of an image. This type of filter is used to sharpen images. 
Basic High-Pass Filter: 3x3 
-1 -1 -1
-1 9 -1
-1 -1 -1
Basic High-Pass Filter: 5x5 
0 -1 -1 -1 0
-1 2 -4 2 -1
-1 -4 13 -4 -1
-1 2 -4 2 -1
0 -1 -1 -1 0

LAPLACIAN FILTER
The Laplacian is used to enhance discontinuities. 
The 3x3 kernel is: 
0 -1 0
-1 4 -1
0 -1 0
The 5x5 kernel is: 
1 1 1 1 1
1 1 1 1 1
1 1 24 1 1
1 1 1 1 1
1 1 1 1 1

SOBEL FILTER
The Sobel filter consists of two kernels which detect horizontal and vertical changes in an image. If both are applied to an image, the results can by used to compute the magnitude and direction of the edges in the image. 
Horizontal Sobel
-1 -2 -1
0 0 0
1 2 1 
Vertical Sobel
-1 0 -1
-2 0 2
-1 0 1


Example: Sample Convolution
These are a Sample Convolution filter values
1 1 1
1 1 1
1 1 1 
Notice that here the sum of the matrix is 9: there are nine cells with values of 1, and adding together those nine 1's gives us a sum of 9. This sum is greater than 1 by a factor of 9, and we can compensate for that by making use of the FACTOR. By specifying a FACTOR of 9, we divide the sum of 9 by 9, which gives us a result of 1. And 1 is just what we need if we want the brightness of the original image to be maintained in the filtered image.
To compensate for a sum that deviates from 1, we must use a FACTOR equal to that sum to maintain the image brightness of the original image. 
This will work whether the sum (and corresponding FACTOR) is a positive value or a negative value. We can also use the FACTOR to help adjust the brightness of filtered image, by using a value that only partially compensates for the sum's deviation from 1.
To compensate for a sum that deviates from 1, use a FACTOR equal to that sum to maintain the image brightness of the original image. 

WHERE IS "FACTOR" AND "OFFSET" IN ZBRUSH ?!?!?! I don't know.

The Sample Convolution filter also shows us how in general to get a blurring filter:
For a Convolution filter, use a positive center value and surround it with a symmetrical pattern of other positive values. 
Lessen the effect of a filter by increasing the value in the center cell.

Example: Sharpen 
With the blur filters, we add to the matrix positive peripheral cell values around a positive central value. For a sharpening filter, we also use a positive central value, but this time surround the central cell with negative values.
For a Sharpen filter, use a positive center value and surround it with a symmetrical pattern of negative values. 
-1 -1 -1
-1 9 -1
-1 -1 -1
Remember that in general we maintain the overall brightness of original image by using values in the matrix that sum to 1.

Example: Edge
For edge filters, the central value is what's negative, with positive surrounding values.
For an edge filter, use a negative center value and surround it with a symmetrical pattern of positive values. 
1 1 1
1 -7 1
1 1 1
We can lessen the effect of a filter by increasing the value in the center cell.

Example: Embossing
For an Embossing filter, use a positive center value and surround it in a symmetrical pattern of negative values on one side and positive values on the other. 
1 1 -1
1 1 -1
1 -1 -1
Again, we can lessen the effect of a filter by increasing the value in the center cell (but we must compensate to mantain brightness).
1 1 -1
1 3 -1
1 -1 -1
We can adjust the direction of the embossing by repositioning the positive and negative cells that surround the center cell. For example the following values emboos to top: 
1 1 1
0 1 0
-1 -1 -1 

LINE DETECTION
Detection of one pixel wide lines can accomplished with the following filters; 
Horizontal Edge
-1 -1 -1
2 2 2
-1 -1 -1
Vertical Edge
-1 2 -1
-1 2 -1 
-1 2 -1
Left Diagonal Edge
2 -1 -1
-1 2 -1
-1 -1 2
Right Diagonal Edge
-1 -1 2
-1 2 -1
2 -1 -1

POINT DETECTION
The Point detecters detect discontinuities in the image... (non smooth areas) 
-1 2 -1
-1 2 -1
-1 2 -1

GRADIENT DETECTION
Changes in value over 3 pixels can be detected using kernels called Gradient Masks or Prewitt Masks. these filters enhance the edges in various directions. The direction of the change from darker to lighter is described by the following matrixone of the points of the compass. The 3x3 kernels are as follows: 
Embossing North
-1 -2 -1
0 0 0
1 2 1
Embossing West
-1 0 1
-2 0 2
-1 0 1
Embossing East
1 0 -1
2 0 -2
1 0 -1
Embossing South
1 2 1
0 0 0
-1 -2 -1
Embossing NorhtEast
0 -1 -2
1 0 -1
2 1 0
Embossing NorhtWest
-2 -1 0
-1 0 1
0 1 2
Embossing SudEst
2 1 0
1 0 -1
0 -1 -2 
Embossing SudWest
0 1 2
-1 0 1
-2 -1 0 

SMOOTHING AND BLURRING
Smoothing and blurring operations are low-pass spatial filters. They reduce or eliminate high-frequency aspects of an image. 
Arithmetic Mean
The arithmetic mean simply takes an average of the pixels in the kernel. Each element in the filter is equal to 1 divided by the total number of elements in the filter. Thus the 3x3 arithmetic mean filter is: 
1/9 1/9 1/9
1/9 1/9 1/9
1/9 1/9 1/9
Basic Smooth 3x3 (Convolution) (not normalized)
1 2 1
2 4 2
1 2 1
Basic Smooth 5x5 (not normalized) 
1 1 1 1 1
1 4 4 4 1
1 4 12 4 1
1 4 4 4 1
1 1 1 1 1

HIGH-PASS FILTERS
A high-pass filter enhances the high-frequency parts of an image. This type of filter is used to sharpen images. 
Basic High-Pass Filter (Sharpen) 3x3 
-1 -1 -1
-1 9 -1
-1 -1 -1
Basic High-Pass Filter: 5x5 
0 -1 -1 -1 0
-1 2 -4 2 -1
-1 -4 13 -4 -1
-1 2 -4 2 -1
0 -1 -1 -1 0

LAPLACIAN FILTER
The Laplacian is used to enhance discontinuities (changes in the image). 
The 3x3 kernel is: 
0 -1 0
-1 4 -1
0 -1 0
The 5x5 kernel is: 
1 1 1 1 1
1 1 1 1 1
1 1 24 1 1
1 1 1 1 1
1 1 1 1 1

SOBEL FILTER
The Sobel filter consists of two kernels which detect horizontal and vertical changes in an image. If both are applied to an image, the results can by used to compute the magnitude and direction of the edges in the image. 
Horizontal Sobel
-1 -2 -1
0 0 0
1 2 1 
Vertical Sobel
-1 0 -1
-2 0 2
-1 0 1


Edge Detection - Heavy 
1 -2 1
-2 4 -2
1 -2 1

Edge Detection - Medium 
-1 -1 -1
-1 8 -1
-1 -1 -1

Edge Detection - Light 
0 1 0
1 4 1
0 1 0 

Emboss Filter
-1 0 0
0 0 0 
0 0 1

Enhance Detail
0 -1 0
-1 10 -1
0 -1 0 

Enhance Edges
-1 -1 -1
-1 9 -1
-1 -1 -1

Enhance focus 
-1 0 -1
0 7 0
-1 0 -1

Reduce jaggies 
0 0 -1 0 0 
0 0 3 0 0
-1 3 7 3 -1
0 0 3 0 0
0 0 -1 0 0 

Soften Filter - Heavy
11 11 11 
11 11 11 
11 11 11

Soften Filter - Medium
10 10 10 
10 20 10 
10 10 10 

Soften Filter - Light
6 12 6 
12 25 12 
6 12 6 

Convolution - Light
1 2 1
2 2 2
1 2 1 

1 1 1
1 -8 1
1 1 1




blurFilter = [[0,1,2,1,0],[1,2,4,2,1],[2,4,8,4,2],[1,2,4,2,1],[0,1,2,1,0]]
blurDiv = 48
cutoutFilter = [[-4,-3,-2,0,0],[-3,-2,-1,0,0],[-2,-1,18,1,2],[0,0,1,2,3],[0,0,2,3,4]]
embossFilter = [[4,3,2,0,0],[3,2,1,0,0],[2,1,18,-1,-2],[0,0,-1,-2,-3],[0,0,-2,-3,-4]]
cutDiv = 18
edgeFilter = [[0,0,0,0,0],[0,0,-1,0,0],[0,-1,5,-1,0],[0,0,-1,0,0],[0,0,0,0,0]]
edgeDiv = 1

SD 0.6:
  0, 1, 0
  1, 4, 1
  0, 1, 0
Divide by 8

SD 0.7:
  0, 0, 1, 0, 0
  0, 8, 21, 8, 0
  1, 21, 59, 21, 1
  0, 8, 21, 8, 0
  0, 0, 1, 0, 0
Divide by 179

SD 0.8:
  0, 0, 1, 0, 0
  0, 5, 10, 5, 0
  1, 10, 23, 10, 1
  0, 5, 10, 5, 0
  0, 0, 1, 0, 0
Divide by 87

SD 0.9:
  0, 1, 1, 1, 0
  1, 3, 6, 3, 1
  1, 6, 12, 6, 1
  1, 3, 6, 3, 1
  0, 1, 1, 1, 0
Divide by 60

SD 1.0:
  0, 0, 1, 1, 1, 0, 0
  0, 2, 7, 12, 7, 2, 0
  1, 7, 33, 55, 33, 7, 1
  1, 12, 55, 90, 55, 12, 1
  1, 7, 33, 55, 33, 7, 1
  0, 2, 7, 12, 7, 2, 0
  0, 0, 1, 1, 1, 0, 0
Divide by 566

SD 1.5:
  0, 0, 0, 1, 1, 1, 0, 0, 0
  0, 1, 2, 4, 5, 4, 2, 1, 0
  0, 2, 6, 12, 14, 12, 6, 2, 0
  1, 4, 12, 22, 28, 22, 12, 4, 1
  1, 5, 14, 28, 35, 28, 14, 5, 1
  1, 4, 12, 22, 28, 22, 12, 4, 1
  0, 2, 6, 12, 14, 12, 6, 2, 0
  0, 1, 2, 4, 5, 4, 2, 1, 0
  0, 0, 0, 1, 1, 1, 0, 0, 0
Divide by 495
Which of these blurs, and what degree of extrapolation, is best depends on the nature of the image, and your personal preferences. For much of my web work, I like SD=0.7, and final=2*original minus blur. That could be expressed as a single matrix:
  0, 0, -1, 0, 0
  0, -8, -21, -8, 0
  -1, -21, 299, -21, -1
  0, -8, -21, -8, 0
  0, 0, -1, 0, 0
Divide by 179
*/