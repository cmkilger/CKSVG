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

#import "SVG.h"

#pragma mark Attributes

CGColorRef SVGColorWithPaint(NSString *paint) {
	if (!paint)
		return NULL;
		
	if ([paint isEqualToString:@"none"])
		return CGColorGetConstantColor(kCGColorClear);
	
	if ([paint isEqualToString:@"currentColor"])
		return NULL;
	
	if ([paint hasPrefix:@"#"]) {
		NSInteger length = ([paint length] < 7) ? 1 : 2;
		unsigned colors[3];
		for (int i = 0; i < 3; i++) {
			NSScanner *scanner = [NSScanner scannerWithString:[paint substringWithRange:NSMakeRange(i * length + 1, length)]];
			[scanner scanHexInt:&colors[i]];
		}
		return CGColorCreateGenericRGB(colors[0]/255.0, colors[1]/255.0, colors[2]/255.0, 1.0);
	}
	
	if ([paint hasPrefix:@"rgb("]) {
		NSString *valuesStr = [paint substringFromIndex:4];
		valuesStr = [valuesStr substringToIndex:[valuesStr length]-1];
		NSArray *values = [valuesStr componentsSeparatedByString:@","];
		CGFloat colors[3];
		for (int i = 0; i < 3; i++) {
			NSString *colorStr = [values objectAtIndex:i];
			if ([[colorStr substringFromIndex:[colorStr length]-1] isEqualToString:@"%"]) {
				colorStr = [colorStr substringToIndex:[colorStr length]-1];
				colors[i] = (CGFloat)[colorStr floatValue]/100.0;
			}
			else {
				colors[i] = (CGFloat)[colorStr floatValue]/255.0;
			}
		}
		NSLog(@"Color is %f, %f, %f", colors[0], colors[1], colors[2]);
		return CGColorCreateGenericRGB(colors[0], colors[1], colors[2], 1.0);
	}
	
	NSLog(@"ERROR: Unable to determine color \"%@\".  Inheriting from parent.", paint);
	return NULL;
}

// FIXME: needs implementation
CGFloat SVGFloatWithLength(NSString *length) {
	return [length floatValue];
}

CGLineJoin SVGLineJoinWithLineJoin(NSString *lineJoin) {
	if ([lineJoin isEqualToString:@"miter"])
		return kCGLineJoinMiter;
	if ([lineJoin isEqualToString:@"round"])
		return kCGLineJoinRound;
	if ([lineJoin isEqualToString:@"bevel"])
		return kCGLineJoinBevel;
	return NSNotFound;
}


#pragma mark -
#pragma mark Arcs

typedef struct __svgArc {
	CGPoint center;
	CGFloat startAngle;
	CGFloat endAngle;
	BOOL clockwise;
} SVGArc;

SVGArc SVGArcMake(CGPoint center, CGFloat startAngle, CGFloat endAngle, BOOL clockwise) {
	SVGArc arc = {center, startAngle, endAngle, clockwise};
	return arc;
}

CGFloat minimizeAngle(CGFloat angle) {
	while (angle > M_PI)
		angle -= 2 * M_PI;
	while (angle <= -M_PI)
		angle += 2 * M_PI;
	return angle;
}

CGFloat pointDistance(CGPoint point1, CGPoint point2) {
	CGFloat a = point1.x - point2.x;
	CGFloat b = point1.y - point2.y;
	return sqrt(a*a+b*b);
}

CGFloat pointAngle(CGPoint point1, CGPoint point2) {
	CGFloat a = point2.x - point1.x;
	CGFloat b = point2.y - point1.y;
	if (a == 0) {
		if (b > 0)
			return M_PI/2;
		else if (b < 0)
			return -M_PI/2;
		else
			return 0;
	}
	if (a < 0)
		return minimizeAngle(M_PI + atan(b/a));
	return minimizeAngle(atan(b/a));
}

void SVGPathAddArc(CGMutablePathRef path, CGFloat xRadius, CGFloat yRadius, CGFloat rotation, BOOL largeArc, BOOL sweep, CGPoint endPoint) {
	
	CGPoint startPoint = CGPathGetCurrentPoint(path);
	
	NSLog(@"Start: %f, %f", startPoint.x, startPoint.y);
	NSLog(@"xR: %f, yR: %f, Rot: %f, Start: (%f,%f), End: (%f,%f)", xRadius, yRadius, rotation, startPoint.x, startPoint.y, endPoint.x, endPoint.y);
	
	double minRadius = pointDistance(startPoint, endPoint) / 2 + .001;
	
	NSLog(@"Minimum Radius: %f", minRadius);
	
	if (xRadius < yRadius) {
		if (xRadius < minRadius) {
			yRadius = minRadius * yRadius / xRadius;
			xRadius = minRadius;
		}
	}
	else {
		if (yRadius < minRadius) {
			xRadius = minRadius * xRadius / yRadius;
			yRadius = minRadius;
		}
	}
	
//	NSLog(@"xRadius: %f", xRadius);
//	NSLog(@"yRadius: %f", yRadius);
	
	rotation = rotation * M_PI/180;
	CGAffineTransform transform = CGAffineTransformMakeRotation(-rotation);
	transform = CGAffineTransformConcat(transform, CGAffineTransformMakeScale(1.0, xRadius/yRadius));
	
	startPoint = CGPointApplyAffineTransform(startPoint, transform);
	endPoint = CGPointApplyAffineTransform(endPoint, transform);
	
//	NSLog(@"Start: (%f,%f)", startPoint.x, startPoint.y);
//	NSLog(@"End: (%f,%f)", endPoint.x, endPoint.y);
	
	// Determine possible center points
	CGFloat a = startPoint.x;
	CGFloat b = startPoint.y;
	CGFloat c = endPoint.x;
	CGFloat d = endPoint.y;
	CGFloat r = xRadius;
	
//	NSLog(@"a = %f; b = %f; c = %f; d = %f; r = %f;", a, b, c, d, r);
	
	double aSquared = a*a;
	double aCubed = aSquared*a;
	double aFourth = aCubed*a;
	
	double bSquared = b*b;
	double bCubed = bSquared*b;
	double bFourth = bCubed*b;
	
	double cSquared = c*c;
	double cCubed = cSquared*c;
	double cFourth = cCubed*c;
	
	double dSquared = d*d;
	double dCubed = dSquared*d;
	double dFourth = dCubed*d;
	
	double rSquared = r*r;
	
	double hLeft = 4 * aCubed - 4 * c * aSquared + 4 * a * bSquared - 4 * a * cSquared + 4 * a * dSquared - 8 * b * d * a + 4 * cCubed + 4 * c * dSquared + 4 * bSquared * c - 8 * b * c * d;
	
	double hRight1 = -4 * aCubed + 4 * c * aSquared - 4 * a * bSquared + 4 * a * cSquared - 4 * a * dSquared + 8 * b * d * a - 4 * cCubed - 4 * c * dSquared - 4 * c * bSquared + 8 * b * c * d;
	double hRight2 = 4 * aSquared - 8 * c * a + 4 * bSquared + 4 * cSquared + 4 * dSquared - 8 * b * d;
	double hRight3 = aFourth + 2 * bSquared * aSquared - 2 * cSquared * aSquared + 2 * dSquared * aSquared - 4 * b * d * aSquared + bFourth + cFourth + dFourth -4 * b * dCubed + 2 * bSquared * cSquared;
	double hRight4 = 6 * bSquared * dSquared + 2 * cSquared * dSquared - 4 * bSquared * rSquared - 4 * dSquared * rSquared + 8 * b * d * rSquared - 4 * d * bCubed - 4 * b * d * cSquared;
	double hRight = hRight1 * hRight1 - 4 * hRight2 * (hRight3 + hRight4);
	
	double hDenominator =  2 * ( 4 * aSquared - 8 * c * a + 4 * bSquared + 4 * cSquared + 4 * dSquared - 8 * b * d );
	
	NSLog(@"Left: %f", hLeft);
	NSLog(@"Right: %f", hRight);
	NSLog(@"Denominator: %f", hDenominator);
	
	double h1 = (hLeft + sqrt(hRight)) / hDenominator;
	double h2 = (hLeft - sqrt(hRight)) / hDenominator;
	
	double k1 = b + sqrt( rSquared - aSquared + 2 * h1 * a - h1 * h1 );
	double k2 = b - sqrt( rSquared - aSquared + 2 * h1 * a - h1 * h1 );
	
	double k3 = b + sqrt( rSquared - aSquared + 2 * h2 * a - h2 * h2 );
	double k4 = b - sqrt( rSquared - aSquared + 2 * h2 * a - h2 * h2 );
	
	CGPoint potentials[4];
	potentials[0] = CGPointMake(h1, k1);
	potentials[1] = CGPointMake(h1, k2);
	potentials[2] = CGPointMake(h2, k3);
	potentials[3] = CGPointMake(h2, k4);
	
	BOOL isValid[4];
	isValid[0] = fabs((a-h1) * (a-h1) + (b-k1) * (b-k1) - rSquared) < 0.1 && fabs((c-h1) * (c-h1) + (d-k1) * (d-k1) - rSquared) < 0.1;
	isValid[1] = fabs((a-h1) * (a-h1) + (b-k2) * (b-k2) - rSquared) < 0.1 && fabs((c-h1) * (c-h1) + (d-k2) * (d-k2) - rSquared) < 0.1;
	isValid[2] = fabs((a-h2) * (a-h2) + (b-k3) * (b-k3) - rSquared) < 0.1 && fabs((c-h2) * (c-h2) + (d-k3) * (d-k3) - rSquared) < 0.1;
	isValid[3] = fabs((a-h2) * (a-h2) + (b-k4) * (b-k4) - rSquared) < 0.1 && fabs((c-h2) * (c-h2) + (d-k4) * (d-k4) - rSquared) < 0.1;
	
	NSLog(@"Potential Center 1: (%f,%f) %d", potentials[0].x, potentials[0].y, isValid[0]);
	NSLog(@"Potential Center 2: (%f,%f) %d", potentials[1].x, potentials[1].y, isValid[1]);
	NSLog(@"Potential Center 3: (%f,%f) %d", potentials[2].x, potentials[2].y, isValid[2]);
	NSLog(@"Potential Center 4: (%f,%f) %d", potentials[3].x, potentials[3].y, isValid[3]);
	
	CGPoint center[2];
	int index = 0;
	
	for (int i = 0; i < 4; i++) {
		if (isValid[i])
			center[index++] = potentials[i];
		if (index > 1)
			break;
	}
	
	NSLog(@"Center 1: (%f,%f)", center[0].x, center[0].y);
	NSLog(@"Center 2: (%f,%f)", center[1].x, center[1].y);

	
	// Angles
	CGFloat angles[4];
	angles[0] = pointAngle(center[0], startPoint);
	angles[1] = pointAngle(center[0], endPoint);
	angles[2] = pointAngle(center[1], startPoint);
	angles[3] = pointAngle(center[1], endPoint);
	
	// Arcs
	SVGArc arcs[4];
	arcs[0] = SVGArcMake(center[0], angles[0], angles[1], NO);
	arcs[1] = SVGArcMake(center[0], angles[0], angles[1], YES);
	arcs[2] = SVGArcMake(center[1], angles[2], angles[3], NO);
	arcs[3] = SVGArcMake(center[1], angles[2], angles[3], YES);
	
	SVGArc largeArcs[2];
	SVGArc smallArcs[2];
	
	CGFloat difference;
	if (arcs[0].endAngle < arcs[0].startAngle) 
		arcs[0].endAngle += M_PI * 2;
	difference = arcs[0].endAngle - arcs[0].startAngle;
	
	arcs[0].startAngle = minimizeAngle(arcs[0].startAngle);
	arcs[0].endAngle = minimizeAngle(arcs[0].endAngle);
	
	if (difference > M_PI) {
		largeArcs[0] = arcs[0];
		smallArcs[0] = arcs[1];
		smallArcs[1] = arcs[2];
		largeArcs[1] = arcs[3];
	}
	else {
		smallArcs[0] = arcs[0];
		largeArcs[0] = arcs[1];
		largeArcs[1] = arcs[2];
		smallArcs[1] = arcs[3];
	}
	
	SVGArc arc;
	
	if (largeArc) {
		if (!sweep) {
			if (largeArcs[0].clockwise)
				arc = largeArcs[0];
			else
				arc = largeArcs[1];
		}
		else  {
			if (!largeArcs[0].clockwise)
				arc = largeArcs[0];
			else
				arc = largeArcs[1];
		}
	}
	else {
		if (!sweep) {
			if (smallArcs[0].clockwise)
				arc = smallArcs[0];
			else
				arc = smallArcs[1];
		}
		else {
			if (!smallArcs[0].clockwise)
				arc = smallArcs[0];
			else
				arc = smallArcs[1];
		}
	}
	
	CGAffineTransform inverse = CGAffineTransformInvert(transform);
	
//	arc.center = CGPointApplyAffineTransform(arc.center, inverse);
	
	NSLog(@"Arc: (%.2f,%.2f) %f, %f, %d", arc.center.x, arc.center.y, arc.startAngle, arc.endAngle, arc.clockwise);
	
	CGPathAddArc(path, &inverse, arc.center.x, arc.center.y, r, arc.startAngle, arc.endAngle, arc.clockwise);
}


#pragma mark -
#pragma mark Paths

CGPoint *cSmooth;
CGPoint *qSmooth;

CGPoint * reflectionOfPoint(CGFloat p1x, CGFloat p1y, CGFloat p2x, CGFloat p2y) {
	CGFloat newX = p2x-p1x+p2x;
	CGFloat newY = p2y-p1y+p2y;
	CGPoint *point = malloc(sizeof(CGPoint));
	point->x = newX;
	point->y = newY;
	return point;
}

void CGPointRelease(CGPoint *point) {
	if (point)
		free(point);
}

void executeCommandOnMutablePath(CGMutablePathRef path, NSString *command) {
	
	// moveto
	if ([command characterAtIndex:0] == 'M' || [command characterAtIndex:0] == 'm') {
		int coordCount = 2;
		float coords[coordCount];
		int index = 0;
		NSScanner *scanner = [NSScanner scannerWithString:command];
		while (![scanner isAtEnd]) {			
			if (![scanner scanFloat:&coords[index]])
				[scanner setScanLocation:[scanner scanLocation]+1];
			else {
				if (index == coordCount-1) {
					if ([command characterAtIndex:0] == 'm') {
						CGPoint current = CGPathGetCurrentPoint(path);
						coords[0] += current.x;
						coords[1] += current.y;
					}
					NSLog(@"Move: %f,%f", coords[0], coords[1]);
					CGPathMoveToPoint(path, NULL, coords[0], coords[1]);
					CGPointRelease(cSmooth);
					CGPointRelease(qSmooth);
					cSmooth = NULL;
					qSmooth = NULL;
				}
				index = (index+1)%coordCount;
			}
		}
		return;
	}
	
	// closepath
	if ([command characterAtIndex:0] == 'Z' || [command characterAtIndex:0] == 'z') {
		CGPathCloseSubpath(path);
		CGPointRelease(cSmooth);
		CGPointRelease(qSmooth);
		cSmooth = NULL;
		qSmooth = NULL;
		return;
	}
	
	// lineto
	if ([command characterAtIndex:0] == 'L' || [command characterAtIndex:0] == 'l') {
		int coordCount = 2;
		float coords[coordCount];
		int index = 0;
		NSScanner *scanner = [NSScanner scannerWithString:command];
		while (![scanner isAtEnd]) {
			if (![scanner scanFloat:&coords[index]])
				[scanner setScanLocation:[scanner scanLocation]+1];
			else {
				if (index == coordCount-1) {
					if ([command characterAtIndex:0] == 'l') {
						CGPoint current = CGPathGetCurrentPoint(path);
						coords[0] += current.x;
						coords[1] += current.y;
					}
					CGPathAddLineToPoint(path, NULL, coords[0], coords[1]);
					CGPointRelease(cSmooth);
					CGPointRelease(qSmooth);
					cSmooth = NULL;
					qSmooth = NULL;
				}
				index = (index+1)%coordCount;
			}
		}
		return;
	}
	
	// horizontal lineto
	if ([command characterAtIndex:0] == 'H' || [command characterAtIndex:0] == 'h') {
		float coordX;
		NSScanner *scanner = [NSScanner scannerWithString:command];
		while (![scanner isAtEnd]) {
			if (![scanner scanFloat:&coordX])
				[scanner setScanLocation:[scanner scanLocation]+1];
			else {
				CGPoint current = CGPathGetCurrentPoint(path);
				if ([command characterAtIndex:0] == 'h')
					coordX += current.x;
				CGPathAddLineToPoint(path, NULL, coordX, current.y);
				CGPointRelease(cSmooth);
				CGPointRelease(qSmooth);
				cSmooth = NULL;
				qSmooth = NULL;
			}
		}
		return;
	}
	
	// vertical lineto
	if ([command characterAtIndex:0] == 'V' || [command characterAtIndex:0] == 'v') {
		float coordY;
		NSScanner *scanner = [NSScanner scannerWithString:command];
		while (![scanner isAtEnd]) {
			if (![scanner scanFloat:&coordY])
				[scanner setScanLocation:[scanner scanLocation]+1];
			else {
				CGPoint current = CGPathGetCurrentPoint(path);
				if ([command characterAtIndex:0] == 'v')
					coordY += current.y;
				CGPathAddLineToPoint(path, NULL, current.x, coordY);
				CGPointRelease(cSmooth);
				CGPointRelease(qSmooth);
				cSmooth = NULL;
				qSmooth = NULL;
			}
		}
		return;
	}
	
	// curveto
	if ([command characterAtIndex:0] == 'C' || [command characterAtIndex:0] == 'c') {
		
		int coordCount = 6;
		float coords[coordCount];
		int index = 0;
		NSScanner *scanner = [NSScanner scannerWithString:command];
		while (![scanner isAtEnd]) {			
			if (![scanner scanFloat:&coords[index]])
				[scanner setScanLocation:[scanner scanLocation]+1];
			else {
				if (index == coordCount-1) {
					if ([command characterAtIndex:0] == 'c') {
						CGPoint current = CGPathGetCurrentPoint(path);
						coords[0] += current.x;
						coords[1] += current.y;
						coords[2] += current.x;
						coords[3] += current.y;
						coords[4] += current.x;
						coords[5] += current.y;
					}
					CGPathAddCurveToPoint(path, NULL, coords[0], coords[1], coords[2], coords[3], coords[4], coords[5]);
					CGPointRelease(cSmooth);
					CGPointRelease(qSmooth);
					cSmooth = reflectionOfPoint(coords[2], coords[3], coords[4], coords[5]);
					qSmooth = NULL;
				}
				index = (index+1)%coordCount;
			}
		}
		return;
	}
	
	// shorthand/smooth curveto
	if ([command characterAtIndex:0] == 'S' || [command characterAtIndex:0] == 's') {
		
		int coordCount = 4;
		float coords[coordCount];
		int index = 0;
		NSScanner *scanner = [NSScanner scannerWithString:command];
		while (![scanner isAtEnd]) {			
			if (![scanner scanFloat:&coords[index]])
				[scanner setScanLocation:[scanner scanLocation]+1];
			else {
				if (index == coordCount-1) {
					if ([command characterAtIndex:0] == 's') {
						CGPoint current = CGPathGetCurrentPoint(path);
						coords[0] += current.x;
						coords[1] += current.y;
						coords[2] += current.x;
						coords[3] += current.y;
					}
					CGPathAddCurveToPoint(path, NULL, cSmooth->x, cSmooth->y, coords[0], coords[1], coords[2], coords[3]);
					CGPointRelease(cSmooth);
					CGPointRelease(qSmooth);
					cSmooth = reflectionOfPoint(coords[0], coords[1], coords[2], coords[3]);
					qSmooth = NULL;
				}
				index = (index+1)%coordCount;
			}
		}
		return;
	}
	
	// quadratic Bézier curveto
	
	// shorthand/smooth quadratic Bézier curveto
	
	// elliptical arc
	if ([command characterAtIndex:0] == 'A' || [command characterAtIndex:0] == 'a') {
		
		int coordCount = 7;
		float coords[coordCount];
		int index = 0;
		NSScanner *scanner = [NSScanner scannerWithString:command];
		while (![scanner isAtEnd]) {			
			if (![scanner scanFloat:&coords[index]])
				[scanner setScanLocation:[scanner scanLocation]+1];
			else {
				if (index == coordCount-1) {
					if ([command characterAtIndex:0] == 'a') {
						CGPoint current = CGPathGetCurrentPoint(path);
						coords[5] += current.x;
						coords[6] += current.y;
					}
					SVGPathAddArc(path, coords[0], coords[1], coords[2], coords[3], coords[4], CGPointMake(coords[5], coords[6]));
				}
				index = (index+1)%coordCount;
			}
		}
		return;
	}
	
	// unknown
//	NSLog(@"unknown command: %@", command);
}

CGMutablePathRef SVGPathForPathData(NSString *pathData) {
//	NSLog(@"pathData = %@", pathData);
	CGMutablePathRef path = CGPathCreateMutable();
	CGPathMoveToPoint(path, NULL, 0, 0);
	
	while (YES) {
		NSCharacterSet *characters = [NSCharacterSet characterSetWithCharactersInString:@"MmZzLlHhVvCcSsQqTtAa"];
		NSUInteger index = [pathData rangeOfCharacterFromSet:characters].location; 
		if (index == NSNotFound)
			break;
		pathData = [pathData substringFromIndex:index];
		index = [pathData rangeOfCharacterFromSet:characters options:0 range:NSMakeRange(1, [pathData length]-1)].location;
		if (index == NSNotFound)
			index = [pathData length];
		
		
		NSString *command = [pathData substringToIndex:index];
		executeCommandOnMutablePath(path, command);
		
		
		if (index >= [pathData length])
			break;
		pathData = [pathData substringFromIndex:index];
	}
	
//	CGPathMoveToPoint(path, NULL, 0, 0);
//	CGPathAddLineToPoint(path, NULL, rand()%1000, rand()%1000);
	return path;
}

