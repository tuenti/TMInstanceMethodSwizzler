//
//  TMTimeoutManagerTest.h
//
//  Copyright (c) 2014 Tuenti Technologies S.L. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import <XCTest/XCTest.h>

// Class under test
#import "TMTimeoutManager.h"

// Collaborators
#import "TMInstanceMethodSwizzler.h"
#import "TMGenericTestObject.h"

static NSTimeInterval const kNearTimeInterval = 0.001;
static NSTimeInterval const kPassedNearTimeInterval = 0.002;
static NSTimeInterval const kDistantTimeInterval = 3600;
static TMTimeoutManagerCallbackBlock const kEmptyCallbackBlock = ^{};

@interface TMTimeoutManagerTest : XCTestCase
@end

@implementation TMTimeoutManagerTest
{
	TMGenericTestObject *testObject;

    TMTimeoutManager *sut;
}

- (void)setUp
{
	testObject = [[TMGenericTestObject alloc] init];

	TMInstanceMethodSwizzler *instanceMethodSwizzler = [[TMInstanceMethodSwizzler alloc] init];
	sut = [[TMTimeoutManager alloc] initWithInstanceMethodSwizzler:instanceMethodSwizzler];
}

- (void)testAddingATimeoutToAMethod_doesntInterfereWithItsRegularImplementation
{
	// given
	[sut expectSelectorToBeCalled:@selector(voidMethodWithoutParams) withObject:testObject
					  calledBlock:kEmptyCallbackBlock];

	// when
	[testObject voidMethodWithoutParams];

	// then
    XCTAssertTrue(testObject.methodCalled, @"Regular implementation affected after adding timeout");
}

- (void)testCallingExpectedSelector_runsCalledBlock
{
	// given
	__block BOOL blockCalled = NO;
	[sut expectSelectorToBeCalled:@selector(voidMethodWithoutParams) withObject:testObject
					  calledBlock:^{
						  blockCalled = YES;
					  }];

	// when
	[testObject voidMethodWithoutParams];

	// then
    XCTAssertTrue(blockCalled, @"Block not called on method invocation");
}

- (void)testCallingExpectedSelectorOnWrongObject_doesntRunCalledBlock
{
	// given
	TMGenericTestObject *anotherObjectOfTheSameClass = [[TMGenericTestObject alloc] init];

	__block BOOL blockCalled = NO;
	[sut expectSelectorToBeCalled:@selector(voidMethodWithoutParams) withObject:testObject
					  calledBlock:^{
						  blockCalled = YES;
					  }];

	// when
	[anotherObjectOfTheSameClass voidMethodWithoutParams];

	// then
    XCTAssertFalse(blockCalled, @"Block called after invoking method on object not being observed");
}

- (void)testCallingWrongSelectorOnObject_doesntRunCalledBlock
{
	// given
	__block BOOL blockCalled = NO;
	[sut expectSelectorToBeCalled:@selector(voidMethodWithoutParams) withObject:testObject
					  calledBlock:^{
						  blockCalled = YES;
					  }];

	// when
	[testObject voidMethodWithOneObjectParam:@""];

	// then
    XCTAssertFalse(blockCalled, @"Block called after invoking selector not being observed");
}

- (void)testSettingTimeoutOnSelector_callingSelectorBeforeTimeout_runsCalledBlock
{
	// given
	__block BOOL blockCalled = NO;
	[sut expectSelectorToBeCalled:@selector(voidMethodWithoutParams) withObject:testObject
					beforeTimeout:kDistantTimeInterval
					  calledBlock:^{
						  blockCalled = YES;
					  } timeoutBlock:kEmptyCallbackBlock];
	// when
	[testObject voidMethodWithoutParams];

	// then
    XCTAssertTrue(blockCalled, @"Block not called when invoking selector before timeout");
}

- (void)testSettingTimeoutOnSelector_callingSelectorBeforeTimeout_doesntRunTimeoutBlock
{
	// given
	__block BOOL timeoutFired = NO;
	[sut expectSelectorToBeCalled:@selector(voidMethodWithoutParams) withObject:testObject
					beforeTimeout:kDistantTimeInterval
					  calledBlock:kEmptyCallbackBlock
					 timeoutBlock:^{
						  timeoutFired = YES;
					  }];
	// when
	[testObject voidMethodWithoutParams];

	// then
    XCTAssertFalse(timeoutFired, @"Timeout block called despite having invoked selector before maximum waiting time");
}

- (void)testSettingTimeoutOnSelector_callingSelectorAfterTimeout_doesntRunCalledBlock
{
	// given
	__block BOOL blockCalled = NO;
	[sut expectSelectorToBeCalled:@selector(voidMethodWithoutParams) withObject:testObject
					beforeTimeout:kNearTimeInterval
					  calledBlock:^{
						  blockCalled = YES;
					  } timeoutBlock:kEmptyCallbackBlock];
	// when
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:kPassedNearTimeInterval]];
	[testObject voidMethodWithoutParams];

	// then
    XCTAssertFalse(blockCalled, @"Block called despite having passed maximum waiting time");
}

- (void)testSettingTimeoutOnSelector_dontCallingSelectorBeforeTimeout_runsTimeoutBlock
{
	// given
	__block BOOL timeoutFired = NO;
	[sut expectSelectorToBeCalled:@selector(voidMethodWithoutParams) withObject:testObject
					beforeTimeout:kNearTimeInterval
					  calledBlock:kEmptyCallbackBlock
					 timeoutBlock:^{
						 timeoutFired = YES;
					 }];

	// when
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:kPassedNearTimeInterval]];

	// then
    XCTAssertTrue(timeoutFired, @"Timeout block not called despite having passed maximum waiting time");
}

@end
