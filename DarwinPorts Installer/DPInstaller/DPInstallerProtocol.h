/*
 *  DPInstallerProtocol.h
 *  DarwinPorts Installer
 *
 * Copyright (c) 2003 Apple Computer, Inc.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of Apple Computer, Inc. nor the names of its contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

/* mach port names */
#define DPInstallerMessagePort @"org.opendarwin.darwinports.installer.dpinstaller"
#define DPAppMessagePort @"org.opendarwin.darwinports.install.dpapp"

/* event priority names */
#define DPPriorityWarn @"warn"
#define DPPriorityInfo @"info"
#define DPPriorityError @"error"
#define DPPriorityExecutionState @"executionState"
#define DPPriorityExecutionPercent @"executionPercent"
#define DPPriorityDidFinish @"finished"

/* event dictionary keys */
#define DPEventPriorityKey @"priority"
#define DPEventDataKey @"data"

@protocol DPInstallerProtocol

- (oneway void) executeInstallWithUserID: (int) uid withGroupID: (int) gid withUserDirectory: (NSString *) userDirectory;
- (oneway void) terminate;

@end


@protocol DPDelegateProtocol

- (oneway void) postUIEvent: (in bycopy NSDictionary *) message;

@end