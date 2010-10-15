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


@implementation SVGView

@synthesize elements;
@synthesize scale;

- (id)initWithData:(NSData *)data {
	if (![self init])
		return nil;
	
	scale = 1.0;
	
	elements = [[NSMutableArray alloc] init];
	
	NSXMLParser *xml = [[NSXMLParser alloc] initWithData:data];
	[xml setDelegate:self];
	[xml parse];
	[xml release];
	
	return self;
}

- (void)drawRect:(NSRect)dirtyRect {
//	NSLog(@"Draw view");
	CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
	CGContextSetFillColorWithColor(context, CGColorGetConstantColor(kCGColorWhite));
	CGContextFillRect(context, dirtyRect);
	CGContextScaleCTM(context, 1.0, -1.0);
	CGContextTranslateCTM(context, 0.0, -[self frame].size.height);
	CGContextScaleCTM(context, scale, scale);
	for (SVGElement *element in elements)
		[element drawRect:dirtyRect];
}

- (id)initWithAttributes:(NSDictionary *)attributeDict {
	return nil;
}

- (void)dealloc {
	[elements release];
	[containerStack release];
	[super dealloc];
}

- (void)setScale:(CGFloat)newScale {
	scale = newScale;
	[self setFrame:CGRectMake(normalFrame.origin.x*scale, normalFrame.origin.y*scale, normalFrame.size.width*scale, normalFrame.size.height*scale)];
}

- (void)configureWithAttributes:(NSDictionary *)attributeDict {
	NSLog(@"%@", attributeDict);
	
	if ([attributeDict objectForKey:@"viewBox"]) {
		int count = 4;
		float floats[] = {0,0,0,0}; // To appease the Clang gods
		int index = 0;
		NSScanner *scanner = [NSScanner scannerWithString:[attributeDict objectForKey:@"viewBox"]];
		while (![scanner isAtEnd]) {
			if (index < count) {
				if (![scanner scanFloat:&floats[index]])
					[scanner setScanLocation:[scanner scanLocation]+1];
				else ++index;
			}
			else break;
		}
		normalFrame = CGRectMake(floats[0], floats[1], floats[2], floats[3]);
	}
	else {
		normalFrame = CGRectMake(0, 0, [[attributeDict objectForKey:@"width"] floatValue], [[attributeDict objectForKey:@"height"] floatValue]);
	}
	
	self.scale = 1.0;
	
	
//	NSLog(@"%f,%f,%f,%f", floats[0], floats[1], floats[2], floats[3]);
}

#pragma mark NSXMLParserDelegate

- (void)parser:(NSXMLParser *)parser didEndMappingPrefix:(NSString *)prefix {
	//NSLog(@"parser:%@ didEndMappingPrefix:%@", parser, prefix);
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI
 qualifiedName:(NSString *)qualifiedName attributes:(NSDictionary *)attributeDict {
	//NSLog(@"parser:%@ didStartElement:%@ namespaceURI:%@ qualifiedName:%@ attributes:%@", parser, elementName, namespaceURI, qualifiedName, attributeDict);
	if ([elementName isEqualToString:@"svg"]) {
		[containerStack addObject:self];
		[self configureWithAttributes:attributeDict];
		return;
	}
	if ([elementName isEqualToString:@"g"]) {
		SVGElement<SVGContainer> *container = [containerStack lastObject];
		SVGGroup *group = [[SVGGroup alloc] initWithAttributes:attributeDict];
		group.parentContainer = container;
		[container.elements addObject:group];
		[containerStack addObject:group];
		[group release];
		//NSLog(@"Add %@ to the %@", group, container);
		return;
	}
	if ([elementName isEqualToString:@"path"]) {
		SVGElement<SVGContainer> *container = [containerStack lastObject];
		SVGPath *path = [[SVGPath alloc] initWithAttributes:attributeDict];
		path.parentContainer = container;
		[container.elements addObject:path];
		[path release];
		//NSLog(@"Add %@ to the %@", path, container);
		return;
	}
	
//	NSLog(@"Unknown element: %@", elementName);
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
	//NSLog(@"parser:%@ didEndElement:%@ namespaceURI:%@ qualifiedName:%@", parser, elementName, namespaceURI, qName);
	if ([elementName isEqualToString:@"svg"]) {
		if ([containerStack lastObject] == self) {
			//NSLog(@"Stack's successfully cleaned");
			[containerStack removeLastObject];
		}
		else {
			//NSLog(@"Stack's DIRTY!");
		}
		return;
	}
	if ([elementName isEqualToString:@"g"]) {
		[containerStack removeLastObject];
		return;
	}
}

- (void)parser:(NSXMLParser *)parser didStartMappingPrefix:(NSString *)prefix toURI:(NSString *)namespaceURI {
	//NSLog(@"parser:%@ didStartMappingPrefix:%@ toURI:%@", parser, prefix, namespaceURI);
}

- (void)parser:(NSXMLParser *)parser foundAttributeDeclarationWithName:(NSString *)attributeName forElement:(NSString *)elementName type:(NSString *)type defaultValue:(NSString *)defaultValue {
	//NSLog(@"parser:%@ foundAttributeDeclarationWithName:%@ forElement:%@ type:%@ defaultValue:%@", parser, attributeName, elementName, type, defaultValue);
}

- (void)parser:(NSXMLParser *)parser foundCDATA:(NSData *)CDATABlock {
	//NSLog(@"parser:%@ foundCDATA:%@", parser, CDATABlock);
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
	//NSLog(@"parser:%@ foundCharacters:%@", parser, string);
}

- (void)parser:(NSXMLParser *)parser foundComment:(NSString *)comment {
	//NSLog(@"parser:%@ foundComment:%@", parser, comment);
}

- (void)parser:(NSXMLParser *)parser foundElementDeclarationWithName:(NSString *)elementName model:(NSString *)model {
	//NSLog(@"parser:%@ foundElementDeclarationWithName:%@ model:%@", parser, elementName, model);
}

- (void)parser:(NSXMLParser *)parser foundExternalEntityDeclarationWithName:(NSString *)entityName publicID:(NSString *)publicID systemID:(NSString *)systemID {
	//NSLog(@"parser:%@ foundExternalEntityDeclarationWithName:%@ publicID:%@ systemID:%@", parser, entityName, publicID, systemID);
}

- (void)parser:(NSXMLParser *)parser foundIgnorableWhitespace:(NSString *)whitespaceString {
	//NSLog(@"parser:%@ foundIgnorableWhitespace:%@", parser, whitespaceString);
}

- (void)parser:(NSXMLParser *)parser foundInternalEntityDeclarationWithName:(NSString *)name value:(NSString *)value {
	//NSLog(@"parser:%@ foundInternalEntityDeclarationWithName:%@ value:%@", parser, name, value);
}

- (void)parser:(NSXMLParser *)parser foundNotationDeclarationWithName:(NSString *)name publicID:(NSString *)publicID systemID:(NSString *)systemID {
	//NSLog(@"parser:%@ foundNotationDeclarationWithName:%@ publicID:%@ systemID:%@", parser, name, publicID, systemID);
}

- (void)parser:(NSXMLParser *)parser foundProcessingInstructionWithTarget:(NSString *)target data:(NSString *)data {
	//NSLog(@"parser:%@ foundProcessingInstructionWithTarget:%@ data:%@", parser, target, data);
}

- (void)parser:(NSXMLParser *)parser foundUnparsedEntityDeclarationWithName:(NSString *)name publicID:(NSString *)publicID systemID:(NSString *)systemID notationName:(NSString *)notationName {
	//NSLog(@"parser:%@ foundUnparsedEntityDeclarationWithName:%@ publicID:%@ systemID:%@ notationName:%@", parser, name, publicID, systemID, notationName);
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
	//NSLog(@"parser:%@ parseErrorOccurred:\"%@\"", parser, [parseError localizedDescription]);
}

- (NSData *)parser:(NSXMLParser *)parser resolveExternalEntityName:(NSString *)entityName systemID:(NSString *)systemID {
	//NSLog(@"parser:%@ resolveExternalEntityName:%@ systemID:%@", parser, entityName, systemID);
	return nil;
}

- (void)parser:(NSXMLParser *)parser validationErrorOccurred:(NSError *)validError {
	//NSLog(@"parser:%@ validationErrorOccurred:\"%@\"", parser, [validError localizedDescription]);
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
	//NSLog(@"parserDidEndDocument:%@", parser);
	[containerStack release];
	containerStack = nil;
}

- (void)parserDidStartDocument:(NSXMLParser *)parser {
	//NSLog(@"parserDidStartDocument:%@", parser);
	containerStack = [[NSMutableArray alloc] init];
}

@end
