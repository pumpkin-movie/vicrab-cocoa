//
//  VicrabCrashLogger_Tests.m
//
//  Created by Karl Stenerud on 2013-01-26.
//
//  Copyright (c) 2012 Karl Stenerud. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall remain in place
// in this source code.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//


#import <XCTest/XCTest.h>
#import "XCTestCase+VicrabCrash.h"

#import "VicrabCrashLogger.h"


@interface VicrabCrashLogger_Tests : XCTestCase

@property(nonatomic, readwrite, retain) NSString* tempDir;

@end


@implementation VicrabCrashLogger_Tests

@synthesize tempDir = _tempDir;

- (void) setUp
{
    [super setUp];
    self.tempDir = [self createTempPath];
}

- (void) tearDown
{
    [self removePath:self.tempDir];
}

- (void) testLogError
{
    VicrabCrashLOG_ERROR(@"TEST");
}

- (void) testLogErrorNull
{
    NSString* str = nil;
    VicrabCrashLOG_ERROR(str);
}

- (void) testLogAlways
{
    VicrabCrashLOG_ALWAYS(@"TEST");
}

- (void) testLogAlwaysNull
{
    NSString* str = nil;
    VicrabCrashLOG_ALWAYS(str);
}

- (void) testLogBasicError
{
    VicrabCrashLOGBASIC_ERROR(@"TEST");
}

- (void) testLogBasicErrorNull
{
    NSString* str = nil;
    VicrabCrashLOGBASIC_ERROR(str);
}

- (void) testLogBasicAlways
{
    VicrabCrashLOGBASIC_ALWAYS(@"TEST");
}

- (void) testLogBasicAlwaysNull
{
    NSString* str = nil;
    VicrabCrashLOGBASIC_ALWAYS(str);
}

- (void) testSetLogFilename
{
    NSString* expected = @"TEST";
    NSString* logFileName = [self.tempDir stringByAppendingPathComponent:@"log.txt"];
    vicrabcrashlog_setLogFilename([logFileName UTF8String], true);
    VicrabCrashLOGBASIC_ALWAYS(expected);
    vicrabcrashlog_setLogFilename(nil, true);

    NSError* error = nil;
    NSString* result = [NSString stringWithContentsOfFile:logFileName encoding:NSUTF8StringEncoding error:&error];
    XCTAssertNil(error, @"");
    result = [[result componentsSeparatedByString:@"\x0a"] objectAtIndex:0];
    XCTAssertEqualObjects(result, expected, @"");

    VicrabCrashLOGBASIC_ALWAYS(@"blah blah");
    result = [NSString stringWithContentsOfFile:logFileName encoding:NSUTF8StringEncoding error:&error];
    result = [[result componentsSeparatedByString:@"\x0a"] objectAtIndex:0];
    XCTAssertNil(error, @"");
    XCTAssertEqualObjects(result, expected, @"");
}

@end
