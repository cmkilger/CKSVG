//
//  Document.m
//  SVGDrawer
//
//  Created by Cory Kilger on 12/9/14.
//  Copyright (c) 2014 Cory Kilger. All rights reserved.
//

#import "Document.h"
#import "SVGView.h"

@interface Document ()

@property (weak) IBOutlet NSScrollView *scroll;
@property (weak) IBOutlet NSSlider *slider;
@property (strong) SVGView *svg;

@end

@implementation Document

- (NSString *)windowNibName {
    return @"Document";
}

- (void)windowControllerDidLoadNib:(NSWindowController *) aController {
    [super windowControllerDidLoadNib:aController];
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
//	[[[aController window] contentView] addSubview:svg];
    [self.scroll setDocumentView:self.svg];
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError {
    if ( outError != NULL ) {
        *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
    }
    return nil;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError {
    self.svg = [[SVGView alloc] initWithData:data];
    if (!self.svg && outError != NULL) {
        *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
    }
    return YES;
}

- (IBAction)changeZoom:(id)sender {
    id slider = self.slider;
    if (sender == slider) {
        float value = [slider floatValue];
//		if (value > 1.0)
//			value = (value - 1.0) * 9.0 + 1.0;
        self.svg.scale = pow(10, value);
    }
}

@end
