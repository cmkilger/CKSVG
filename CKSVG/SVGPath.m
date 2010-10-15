/*	Created by Cory Kilger on 10/22/09.
 *	
 *	Copyright (c) 2010, Cory Kilger.
 *	All rights reserved.
 *	
 *	Redistribution and use in source and binary forms, with or without
 *	modification, are permitted provided that the following conditions are met:
 *	
 *	 * Redistributions of source code must retain the above copyright
 *	   notice, this list of conditions and the following disclaimer.
 *	 * Redistributions in binary form must reproduce the above copyright
 *	   notice, this list of conditions and the following disclaimer in the
 *	   documentation and/or other materials provided with the distribution.
 *	 * Neither the name of the <organization> nor the
 *	   names of its contributors may be used to endorse or promote products
 *	   derived from this software without specific prior written permission.
 *	
 *	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 *	ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 *	WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 *	DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY
 *	DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 *	(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 *	LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 *	ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 *	(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *	SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "SVGPath.h"
#import "SVG.h"

@implementation SVGPath

- (id)initWithAttributes:(NSDictionary *)attributeDict {
	if (![super init])
		return nil;
	
	path = SVGPathForPathData([attributeDict objectForKey:@"d"]);
	
	// Use specified fill or inherit
	NSString *fillStr = [attributeDict objectForKey:@"fill"];
	if (fillStr && ![fillStr isEqualToString:@"inherit"])
		fill = SVGColorWithPaint(fillStr);
	else
		fill = self.parentContainer.fill;
	CGColorRetain(fill);
	
	// Use specified stroke or inherit
	NSString *strokeStr = [attributeDict objectForKey:@"stroke"];
	if (strokeStr && ![strokeStr isEqualToString:@"inherit"])
		stroke = SVGColorWithPaint(strokeStr);
	else
		stroke = self.parentContainer.stroke;
	CGColorRetain(stroke);
	
	// Use specified stroke-width or inherit
	NSString *strokeWidthStr = [attributeDict objectForKey:@"stroke-width"];
	if (strokeWidthStr && ![strokeWidthStr isEqualToString:@"inherit"])
		strokeWidth = SVGFloatWithLength(strokeWidthStr);
	else
		strokeWidth = self.parentContainer.strokeWidth;
	
	// Use specified stroke-linejoin or inherit
	NSString *strokeLineJoinStr = [attributeDict objectForKey:@"stroke-linejoin"];
	if (strokeLineJoinStr && ![strokeLineJoinStr isEqualToString:@"inherit"])
		strokeLineJoin = SVGLineJoinWithLineJoin(strokeLineJoinStr);
	else
		strokeLineJoin = self.parentContainer.strokeLineJoin;
	
	return self;
}

- (void)drawRect:(NSRect)dirtyRect {
//	NSLog(@"Draw path");
	CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
	CGContextSetLineWidth(context, strokeWidth);
	CGContextSetLineJoin(context, strokeLineJoin);
	CGContextSetStrokeColorWithColor(context, stroke);
	CGContextSetFillColorWithColor(context, fill);
	CGContextAddPath(context, path);
	CGContextFillPath(context);
	CGContextAddPath(context, path);
	CGContextStrokePath(context);
}

- (void)dealloc {
	CGPathRelease(path);
	CGColorRelease(fill);
	CGColorRelease(stroke);
	[super dealloc];
}

@end
