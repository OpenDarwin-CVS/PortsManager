/*
 * PMStatusView.m
 * PortsManager
 *
 * Copyright (c) 2002-2003, Apple Computer, Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of Apple Computer, Inc. ("Apple") nor the names of
 *    its contributors may be used to endorse or promote products derived
 *    from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE AND ITS CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL APPLE OR ITS CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PMStatusView.h"
#import "PMStatusItemView.h"

@implementation PMStatusView

#define STRIPE_RED   (237.0 / 255.0)
#define STRIPE_GREEN (243.0 / 255.0)
#define STRIPE_BLUE  (254.0 / 255.0)

+ (NSColor *)stripeColor
{

    static NSColor *_stripeColor = nil;
    if (_stripeColor == nil) {
        _stripeColor = [[NSColor colorWithCalibratedRed:STRIPE_RED
                                                  green:STRIPE_GREEN
                                                   blue:STRIPE_BLUE
                                                  alpha:1.0] retain];
    }
    return _stripeColor;
}


- (void) adjustSubviews
{
    NSEnumerator *subviewEnm = [[self subviews] objectEnumerator];
    PMStatusItemView *subview;

    float ypos = [self bounds].size.height;
    while (subview = [subviewEnm nextObject])
    {
        NSRect subviewFrame = [subview frame];
        ypos -= subviewFrame.size.height;
        subviewFrame.origin.y = ypos;
        subviewFrame.size.width = [self bounds].size.width;
        [subview setFrame: subviewFrame];
    }
}


- (PMStatusItemView *) createNewStatusItemView
{
    [NSBundle loadNibNamed: @"StatusItemView" owner: self];
    [self addSubview: _newStatusItemView];
    [self adjustSubviews];
    [self setNeedsDisplay: YES];
    return _newStatusItemView;
}


- (void) removeAllStatusItemViews
{
    NSEnumerator *subviewEnm = [[self subviews] objectEnumerator];
    PMStatusItemView *subview;
    while (subview = [subviewEnm nextObject])
    {
        [subview removeFromSuperview];
    }
}


- (BOOL) isOpaque
{
    return YES;
}


- (void) setFrame: (NSRect)aRect
{
    [super setFrame: aRect];
    [self adjustSubviews];
}


- (void) drawRect: (NSRect)aRect
{
    int i;
    [self lockFocus];
    float ypos = [self frame].size.height, height = 40;
    for (i = 0; i < [[self subviews] count]; i++)
    {
        PMStatusItemView *subview = [[self subviews] objectAtIndex: i];
        NSColor *color = ((i%2) ? [NSColor whiteColor] : [[self class] stripeColor]);
        [color set];        
        NSRectFill([subview frame]);
        ypos = [subview frame].origin.y;
        height = MAX(height, [subview frame].size.height);
    }
    while (ypos >= 0)
    {
        ypos -= height;
        NSColor *color = ((i++%2) ? [NSColor whiteColor] : [[self class] stripeColor]);
        [color set];        
        NSRectFill(NSMakeRect(0, ypos, [self bounds].size.width, height));
    }
    [self unlockFocus];
}


@end
