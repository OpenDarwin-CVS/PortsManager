/*
 * PMStatusItemView.m
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


#import "PMStatusItemView.h"


@implementation PMStatusItemView

- (BOOL) isOpaque
{
    return NO;
}


- (void) setName: (NSString *)name
{
    [_itemNameTextField setStringValue: name];
}


- (void) setStatus: (NSString *)name 
{
    [_itemStatusTextField setStringValue: name];
}


- (void) showProgressIndicator
{
    if (progressIndicatorHidden)
    {
        NSRect frame =[_itemNameTextField frame];
        frame.origin.y += 10;
        [_itemNameTextField setFrame: frame];
        frame =[_itemStatusTextField frame];
        frame.origin.y -= 10;
        [_itemStatusTextField setFrame: frame];
        [_itemProgressIndicator startAnimation: self]; 
        progressIndicatorHidden = YES;
    }
}


- (void) hideProgressIndicator
{
    if (!progressIndicatorHidden)
    {
        NSRect frame =[_itemNameTextField frame];
        frame.origin.y -= 10;
        [_itemNameTextField setFrame: frame];
        frame =[_itemStatusTextField frame];
        frame.origin.y += 10;
        [_itemStatusTextField setFrame: frame];
        [_itemProgressIndicator stopAnimation: self]; 
        progressIndicatorHidden = YES;
    }
}


- (void) setProgressIndeterminate: (BOOL)flag
{
    [_itemProgressIndicator setIndeterminate: flag];
    [_itemProgressIndicator startAnimation: self]; 
}

- (void) setProgress: (float)progress
{
    [_itemProgressIndicator setDoubleValue: progress];
}


- (void) setAction: (SEL)selector
{
    [_itemButton setAction: selector];
}


- (void) setTarget: (id)target
{
    [_itemButton setTarget: target];
}


@end
