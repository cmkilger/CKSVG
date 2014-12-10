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
#import "SVGElementInternal.h"

@interface SVGPath ()

@property (strong) __attribute__((NSObject)) CGMutablePathRef path;

@end

@implementation SVGPath

- (instancetype)initWithAttributes:(NSDictionary *)attributeDict {
    self = [super init];
    if (self) {
        CGMutablePathRef path = SVGPathForPathData(attributeDict[@"d"]);
        self.path = path;
        CGPathRelease(path);
        
        // Use specified fill or inherit
        NSString *fillStr = attributeDict[@"fill"];
        if (fillStr && ![fillStr isEqualToString:@"inherit"])
            self.fill = SVGColorWithPaint(fillStr);
        else
            self.fill = self.parentContainer.fill;
        
        // Use specified stroke or inherit
        NSString *strokeStr = attributeDict[@"stroke"];
        if (strokeStr && ![strokeStr isEqualToString:@"inherit"])
            self.stroke = SVGColorWithPaint(strokeStr);
        else
            self.stroke = self.parentContainer.stroke;
        
        // Use specified stroke-width or inherit
        NSString *strokeWidthStr = attributeDict[@"stroke-width"];
        if (strokeWidthStr && ![strokeWidthStr isEqualToString:@"inherit"])
            self.strokeWidth = SVGFloatWithLength(strokeWidthStr);
        else
            self.strokeWidth = self.parentContainer.strokeWidth;
        
        // Use specified stroke-linejoin or inherit
        NSString *strokeLineJoinStr = attributeDict[@"stroke-linejoin"];
        if (strokeLineJoinStr && ![strokeLineJoinStr isEqualToString:@"inherit"])
            self.strokeLineJoin = SVGLineJoinWithLineJoin(strokeLineJoinStr);
        else
            self.strokeLineJoin = self.parentContainer.strokeLineJoin;
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect {
//	NSLog(@"Draw path");
    CGPathRef path = self.path;
	CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
	CGContextSetLineWidth(context, self.strokeWidth);
	CGContextSetLineJoin(context, self.strokeLineJoin);
	CGContextSetStrokeColorWithColor(context, self.stroke);
	CGContextSetFillColorWithColor(context, self.fill);
	CGContextAddPath(context, path);
	CGContextFillPath(context);
	CGContextAddPath(context, path);
	CGContextStrokePath(context);
}

@end
