//
//  EmptyView.m
//  GLEssentials-OSX
//
//  Created by Mac_kdy on 2019. 11. 27..
//  Copyright © 2019년 Dan Omachi. All rights reserved.
//

#import "EmptyView.h"

@implementation EmptyView

- (void)initCommon
{
    self.wantsLayer = YES;
    self.layer.backgroundColor = [NSColor whiteColor].CGColor;
}

- (instancetype)initWithFrame:(NSRect)frameRect
{
    if((self = [super initWithFrame:frameRect]))
    {
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
    if(self = [super initWithCoder:decoder])
    {
    }
    return self;
}


- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

@end
