//
//  DPInterp.m
//  DarwinPorts
//
/*
 Copyright (c) 2003 Apple Computer, Inc.
 All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:
 1. Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 2. Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in the
 documentation and/or other materials provided with the distribution.
 3. Neither the name of Apple Computer, Inc. nor the names of its contributors
 may be used to endorse or promote products derived from this software
 without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 */

#import "DPInterp.h"
#import "DPObject.h"

#import <objc/objc.h>

#define ALLOC_NTYPE(N, TYPE) ((TYPE*) malloc(N * sizeof(TYPE)))


@implementation DPInterp
/*
    A thin objective-c wrapper for the tcl interpreter - the intent is that this should be a generic TCL interpreter and should not have any specific knowledge of the ports system.
*/


/** Redirect Handler */

SEL makeSelector(NSString *name) {
    NSString *methodName = [name stringByAppendingString:@":"];
    return sel_getUid([methodName cString]);
}


//Tcl_CreateObjCommand(_interp, [command cString], DPCommandHandler, handler, NULL);
int DPCommandHandler(ClientData clientData, Tcl_Interp *interp, int argc, Tcl_Obj *CONST objv[]) 
{
    id handler = (id) clientData;
    NSMutableArray *array = [NSMutableArray array];
    int i=0;
    for (i=0; i<argc; ++i) {
        DPObject *object = [DPObject objectWithTclObj:objv[i]];
        [array addObject:object];
    }

    SEL selector = makeSelector([[array objectAtIndex:0] stringValue]);
    if (NULL == selector) return TCL_ERROR;
    
    DPObject *result = (DPObject *) [handler performSelector:selector withObject:array];
    if (nil != result)
        Tcl_SetResult(interp, (char*) [result cString], TCL_VOLATILE);

    return TCL_OK;
}


/** Initialization */

- (id) init 
{
    if (self = [super init])
    {
        _interp = Tcl_CreateInterp();
        Tcl_Init(_interp);
    }
    return self;
}


- (void) dealloc 
{
    Tcl_DeleteInterp(_interp);
    [super release];
}


- (BOOL) loadPackage: (NSString *)packageName version: (NSString *)packageVersion usingCommand: (NSString *)packageInit 
{
    char *name = (nil != packageName) ? strdup([packageName cString]) : NULL;
    char *version = (nil != packageVersion) ? strdup([packageVersion cString]) : NULL;

    Tcl_PkgRequire(_interp, name, version, 0);
    [self evaluateCommand: [DPObject objectWithString: packageInit]];

    if (name) free(name);
    if (version) free(version);

    return (TCL_OK == _status);
}


/** Variables */

- (DPObject *) setVariable:(DPObject*) variable toValue:(DPObject*) value 
{
    if (nil == variable || nil == value) return nil;

    Tcl_Obj *result = Tcl_ObjSetVar2(_interp, [variable tclObj], NULL, [value tclObj], 0);
    return (nil != result) ? [DPObject objectWithTclObj: result] : nil;
}


- (DPObject *) getVariable:(DPObject*) variable 
{
    if (nil == variable) return nil;
    Tcl_Obj *value = Tcl_ObjGetVar2(_interp, [variable tclObj], NULL, 0);
    if (nil == value) return nil;
    return [DPObject objectWithTclObj: value];
}

/** Evaluation */

- (DPObject *) evaluateCommand: (DPObject *)command 
{
    return [self evaluateCommand:command withObjects:nil :nil];
}

- (DPObject *) evaluateCommand: (DPObject *)command withObject: (DPObject *) arg 
{
    return [self evaluateCommand:command withObjects:arg :nil];
}

- (DPObject *) evaluateCommand: (DPObject *)command withObjects: (DPObject *)arg1 : (DPObject *)arg2 
{
    NSArray *array = [NSArray arrayWithObjects:command,arg1,arg2,nil];
    return [self evaluate:array];
}


- (DPObject *) evaluate: (NSArray*)args 
{
    const int count = [args count];
    Tcl_Obj **objv = ALLOC_NTYPE(count, Tcl_Obj*);
    NSEnumerator *enumerator = [args objectEnumerator];
    DPObject * object;
    int i=0;

    while (object = (DPObject *) [enumerator nextObject]) {
        if ([object isKindOfClass:[DPObject class]])
            objv[i++] = [object tclObj];
        else
            NSLog(@"evaluate: bad argument type %@", [object class]);
    }
    _status = TCL_ERROR;
    _status = Tcl_EvalObjv(_interp, i, objv, 0);
    DPObject *result = [DPObject objectWithTclObj: Tcl_GetObjResult(_interp)];
    if (TCL_OK != _status) 
    {
        NSLog(@"failed: %@\n args:\t%@", result, args);
    }
    else
    {
        NSLog(@"succeeded args:\t%@", args);
    }
    free(objv);
    return result;
}

- (BOOL) succeeded 
{
    return (TCL_OK == _status);
}


/** Notifications */


- (BOOL) redirectCommand: (DPObject *)command toObject: (id)handler
{
    SEL selector = makeSelector([command stringValue]);
    if (NULL == selector || ![handler respondsToSelector:selector])
        return NO;
    
    Tcl_CreateObjCommand(_interp, [command cString], DPCommandHandler, handler, NULL);
    return YES;
}



@end
