//
//  MyDocument.h
//  SVGDrawer
//
//  Created by Cory Kilger on 10/22/09.
//  Copyright 2009 Cory Kilger. All rights reserved.
//


#import <Cocoa/Cocoa.h>

@class SVGView;

@interface MyDocument : NSDocument {
	IBOutlet NSScrollView *scroll;
	IBOutlet NSSlider *slider;
	SVGView *svg;
}

- (void)changeZoom:(id)sender;

@end
