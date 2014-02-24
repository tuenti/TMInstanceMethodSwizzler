//
//  TMInstanceMethodSwizzlerTest.h
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
#import <CoreGraphics/CoreGraphics.h>

// Class under test
#import "TMInstanceMethodSwizzler.h"

// Collaborators
#import "TMGenericTestObject.h"

@interface TMInstanceMethodSwizzlerTest : XCTestCase
@end

static const TMSwizzlingBlock kEmptySwizzlingBlock = ^(NSInvocation *invocation){};

@implementation TMInstanceMethodSwizzlerTest
{
	TMGenericTestObject *defaultTestObject;
	TMGenericTestObject *anotherTestObject;

    TMInstanceMethodSwizzler *sut;
}

- (void)setUp
{
	defaultTestObject = [[TMGenericTestObject alloc] init];
	anotherTestObject = [[TMGenericTestObject alloc] init];

    sut = [[TMInstanceMethodSwizzler alloc] init];
}

- (void)tearDown
{
	[sut undoAllSwizzling];
}

#pragma mark - Tests cases

- (void)testCallingSwizzledMethod_callsBlock
{
	// given
	__block BOOL blockCalled = NO;
	[sut swizzleSelector:@selector(voidMethodWithoutParams) fromObject:defaultTestObject withBlock:^(NSInvocation *invocation){
		blockCalled = YES;
	}];

	// when
	[defaultTestObject voidMethodWithoutParams];

	// then
    XCTAssertTrue(blockCalled, @"Swizzling block not called");
}

- (void)testCallingUnswizzledMethod_doesNotCallBlock
{
	// given
	__block BOOL blockCalled = NO;
	[sut swizzleSelector:@selector(voidMethodWithoutParams) fromObject:defaultTestObject withBlock:^(NSInvocation *invocation){
		blockCalled = YES;
	}];

	// when
	[sut undoSwizzlingForSelector:@selector(voidMethodWithoutParams) fromObject:defaultTestObject];
	[defaultTestObject voidMethodWithoutParams];

	// then
    XCTAssertFalse(blockCalled, @"Swizzling block called");
}

- (void)testSwizzlingAMethod_doesNotChangeObjectClass
{
	// when
	[sut swizzleSelector:@selector(voidMethodWithoutParams) fromObject:defaultTestObject withBlock:kEmptySwizzlingBlock];

	// then
	BOOL classRemainsIntact = ([defaultTestObject class] == [TMGenericTestObject class]);
    XCTAssertTrue(classRemainsIntact, @"Object's class has changed");
}

- (void)testSwizzlingAMethod_doesNotAffectOtherObjectsOfSameClass
{
	// given
	[sut swizzleSelector:@selector(voidMethodWithoutParams) fromObject:defaultTestObject withBlock:kEmptySwizzlingBlock];

	// when
	[anotherTestObject voidMethodWithoutParams];

	// then
	BOOL otherMethodImplementationRemainsIntact = anotherTestObject.methodCalled;
    XCTAssertTrue(otherMethodImplementationRemainsIntact, @"Object's method implementation has changed");
}

- (void)testSwizzlingAMethod_callingIt_doesNotAffectOtherObjectsOfSameClass
{
	// given
	[sut swizzleSelector:@selector(voidMethodWithoutParams) fromObject:defaultTestObject originalCallingTime:TMOriginalCallingBeforeBlock swizzlingBlock:kEmptySwizzlingBlock];

	// when
	[defaultTestObject voidMethodWithoutParams];

	// then
	BOOL otherMethodIsAffected = anotherTestObject.methodCalled;
    XCTAssertFalse(otherMethodIsAffected, @"Object method has been affected after swizzling same method on another object");
}

- (void)testSwizzlingSameMethodInTwoObjects_doesNotProduceCollisions
{
	__block BOOL firstBlockCalled = NO;
	[sut swizzleSelector:@selector(voidMethodWithoutParams) fromObject:defaultTestObject originalCallingTime:TMOriginalCallingBeforeBlock
		  swizzlingBlock:^(NSInvocation *invocation){
			  firstBlockCalled = YES;
		  }];

	__block BOOL secondBlockCalled = NO;
	[sut swizzleSelector:@selector(voidMethodWithoutParams) fromObject:anotherTestObject originalCallingTime:TMOriginalCallingBeforeBlock
		  swizzlingBlock:^(NSInvocation *invocation){
			  secondBlockCalled = YES;
		  }];

	// when
	[defaultTestObject voidMethodWithoutParams];
	[anotherTestObject voidMethodWithoutParams];

	// then
	BOOL bothMethodsCalled = (defaultTestObject.methodCalled && anotherTestObject.methodCalled);
	BOOL bothBlocksCalled = (firstBlockCalled && secondBlockCalled);
	BOOL collisionsOccurred = !(bothMethodsCalled && bothBlocksCalled);

    XCTAssertFalse(collisionsOccurred, @"There are collisions between different objects implementations for same method");
}

- (void)testSwizzlingSameMethodInTwoObjects_thenUnswizzlingOne_doesNotProduceCollisions
{
	// Given
	__block BOOL firstBlockCalled = NO;
	[sut swizzleSelector:@selector(voidMethodWithoutParams) fromObject:defaultTestObject originalCallingTime:TMOriginalCallingBeforeBlock
		  swizzlingBlock:^(NSInvocation *invocation){
			  firstBlockCalled = YES;
		  }];

	__block BOOL secondBlockCalled = NO;
	[sut swizzleSelector:@selector(voidMethodWithoutParams) fromObject:anotherTestObject originalCallingTime:TMOriginalCallingBeforeBlock
		  swizzlingBlock:^(NSInvocation *invocation){
			  secondBlockCalled = YES;
		  }];

	// when
	[sut undoSwizzlingForSelector:@selector(voidMethodWithoutParams) fromObject:defaultTestObject];
	[defaultTestObject voidMethodWithoutParams];
	[anotherTestObject voidMethodWithoutParams];

	// then
	BOOL bothMethodsCalled = (defaultTestObject.methodCalled && anotherTestObject.methodCalled);
	BOOL firstBlockNotCalledButSecondCalled = (!firstBlockCalled && secondBlockCalled);
	BOOL collisionsOccurred = !(bothMethodsCalled && firstBlockNotCalledButSecondCalled);

    XCTAssertFalse(collisionsOccurred, @"Unswizzling failed");
}

- (void)testSwizzlingAMethodTwice_keepsSecondSwizzlingBlock
{
	// Given
	__block BOOL firstBlockCalled = NO;
	[sut swizzleSelector:@selector(voidMethodWithoutParams) fromObject:defaultTestObject originalCallingTime:TMOriginalCallingNever
		  swizzlingBlock:^(NSInvocation *invocation){
			  firstBlockCalled = YES;
		  }];

	__block BOOL secondBlockCalled = NO;
	[sut swizzleSelector:@selector(voidMethodWithoutParams) fromObject:defaultTestObject originalCallingTime:TMOriginalCallingNever
		  swizzlingBlock:^(NSInvocation *invocation){
			  secondBlockCalled = YES;
		  }];

	// when
	[defaultTestObject voidMethodWithoutParams];

	// then
	BOOL firstBlockNotCalledButSecondCalled = (!firstBlockCalled && secondBlockCalled);
    XCTAssertTrue(firstBlockNotCalledButSecondCalled, @"Swizzling a method twice doesn't keep second swizzling block");
}

- (void)testSwizzlingAMethodWithOneObjectParam_keepsParam
{
	NSString *expectedParam = @"expectedParam";

	// Given
	__block NSString *caughtParam;
	[sut swizzleSelector:@selector(voidMethodWithOneObjectParam:) fromObject:defaultTestObject originalCallingTime:TMOriginalCallingAfterBlock
		  swizzlingBlock:^(NSInvocation *invocation){
			  [invocation getArgument:&caughtParam atIndex:2];
		  }];

	// when
	[defaultTestObject voidMethodWithOneObjectParam:expectedParam];

	// then
    XCTAssertTrue([caughtParam isEqual:expectedParam], @"Unexpected parameter passed to method");
    XCTAssertTrue([[defaultTestObject.params firstObject] isEqual:expectedParam], @"Unexpected object parameter passed to method");
}

- (void)testSwizzlingAMethodWithObjectParams_keepsParams
{
	NSString *expectedFirstParam = @"firstParam";
	NSString *expectedSecondParam = @"secondParam";
	NSString *expectedThirdParam = @"thirdParam";

	// Given
	__block NSString *firstCaughtParam;
	__block NSString *secondCaughtParam;
	__block NSString *thirdCaughtParam;
	[sut swizzleSelector:@selector(voidMethodWithFirstObjectParam:secondObjectParam:thirdObjectParam:)
			  fromObject:defaultTestObject
	 originalCallingTime:TMOriginalCallingAfterBlock
		  swizzlingBlock:^(NSInvocation *invocation){
			  [invocation getArgument:&firstCaughtParam atIndex:2];
			  [invocation getArgument:&secondCaughtParam atIndex:3];
			  [invocation getArgument:&thirdCaughtParam atIndex:4];
		  }];

	// when
	[defaultTestObject voidMethodWithFirstObjectParam:expectedFirstParam
									secondObjectParam:expectedSecondParam
									 thirdObjectParam:expectedThirdParam];

	// then
    XCTAssertTrue([firstCaughtParam isEqual:expectedFirstParam], @"Unexpected first object parameter passed to method");
    XCTAssertTrue([secondCaughtParam isEqual:expectedSecondParam], @"Unexpected second object parameter passed to method");
    XCTAssertTrue([thirdCaughtParam isEqual:expectedThirdParam], @"Unexpected third object parameter passed to method");

    BOOL caughtParamsAreCorrect = [defaultTestObject.params isEqual:@[firstCaughtParam, secondCaughtParam, expectedThirdParam]];
    XCTAssertTrue(caughtParamsAreCorrect, @"Unexpected parameters passed to method");
}

- (void)testSwizzlingAMethodWithScalarParams_keepsParams
{
	NSInteger expectedIntegerParam = NSIntegerMax;
	CGFloat expectedFloatParam = CGFLOAT_MAX;
	NSTimeInterval expectedTimeIntervalParam = [NSDate timeIntervalSinceReferenceDate];

	// Given
	__block NSInteger integerParam;
	__block CGFloat floatParam;
	__block NSTimeInterval timeIntervalParam;

	[sut swizzleSelector:@selector(voidMethodWithIntegerParam:floatParam:timeIntervalParam:)
			  fromObject:defaultTestObject
	 originalCallingTime:TMOriginalCallingAfterBlock
		  swizzlingBlock:^(NSInvocation *invocation){
			  [invocation getArgument:&integerParam atIndex:2];
			  [invocation getArgument:&floatParam atIndex:3];
			  [invocation getArgument:&timeIntervalParam atIndex:4];
		  }];

	// when
	[defaultTestObject voidMethodWithIntegerParam:expectedIntegerParam
									   floatParam:expectedFloatParam
								timeIntervalParam:expectedTimeIntervalParam];

	// then
    XCTAssertTrue(integerParam == expectedIntegerParam, @"Unexpected parameter passed to method, expecting NSInteger");
    XCTAssertTrue(floatParam == expectedFloatParam, @"Unexpected parameter passed to method, expecting CGFloat");
    XCTAssertTrue(timeIntervalParam == expectedTimeIntervalParam, @"Unexpected parameter passed to method, expecting NSTimeInterval");

    BOOL caughtParamsAreCorrect = [defaultTestObject.params isEqual:@[@(expectedIntegerParam), @(expectedFloatParam), @(expectedTimeIntervalParam)]];
    XCTAssertTrue(caughtParamsAreCorrect, @"Unexpected parameters passed to method");
}

- (void)testSwizzlingAMethodWithStructParams_keepsParams
{
	CGRect expectedRect = CGRectInfinite;
	CGAffineTransform expectedAffineTransform = CGAffineTransformIdentity;

	// Given
	__block CGRect caughtRect;
	__block CGAffineTransform caughtAffineTransform;
	[sut swizzleSelector:@selector(voidMethodWithRect:affineTransform:)
			  fromObject:defaultTestObject
	 originalCallingTime:TMOriginalCallingAfterBlock
		  swizzlingBlock:^(NSInvocation *invocation){
			  [invocation getArgument:&caughtRect atIndex:2];
			  [invocation getArgument:&caughtAffineTransform atIndex:3];
		  }];

	// when
	[defaultTestObject voidMethodWithRect:expectedRect affineTransform:expectedAffineTransform];

	// then
	BOOL caughtRectIsEqualToExpectedRect = CGRectEqualToRect(caughtRect, expectedRect);
    XCTAssertTrue(caughtRectIsEqualToExpectedRect, @"Unexpected parameter passed to method, expecting CGRect");

	BOOL caughtAffineTransformIsEqualToExpectedAffineTransform = CGAffineTransformEqualToTransform(caughtAffineTransform, expectedAffineTransform);
    XCTAssertTrue(caughtAffineTransformIsEqualToExpectedAffineTransform, @"Unexpected parameter passed to method, expecting CGAffineTransform");

    BOOL caughtParamsAreCorrect = [defaultTestObject.params isEqual:@[[NSValue valueWithCGRect:caughtRect],
                                                                      [NSValue valueWithCGAffineTransform:caughtAffineTransform]]];
    XCTAssertTrue(caughtParamsAreCorrect, @"Unexpected parameters passed to method");
}

- (void)testSwizzlingAMethodReturningObject_keepsReturnedObject
{
	NSString *expectedObject = @"expectedParam";

	// Given
	[sut swizzleSelector:@selector(objectReturningMethodWithObject:)
			  fromObject:defaultTestObject
	 originalCallingTime:TMOriginalCallingAfterBlock
		  swizzlingBlock:kEmptySwizzlingBlock];

	// when
	NSString *returnedObject = [defaultTestObject objectReturningMethodWithObject:expectedObject];

	// then
    XCTAssertTrue([returnedObject isEqual:expectedObject], @"Unexpected returned object");
}

- (void)testSwizzlingAMethodReturningScalar_keepsReturnedScalar
{
	NSInteger expectedInteger = NSIntegerMax;

	// Given
	[sut swizzleSelector:@selector(integerReturningMethodWithInteger:)
			  fromObject:defaultTestObject
	 originalCallingTime:TMOriginalCallingAfterBlock
		  swizzlingBlock:kEmptySwizzlingBlock];

	// when
	NSInteger returnedInteger = [defaultTestObject integerReturningMethodWithInteger:expectedInteger];

	// then
    XCTAssertTrue(returnedInteger == expectedInteger, @"Unexpected returned NSInteger value");
}

- (void)testSwizzlingAMethodReturningStruct_keepsReturnedStruct
{
	CGRect expectedRect = CGRectInfinite;

	// Given
	[sut swizzleSelector:@selector(integerReturningMethodWithInteger:)
			  fromObject:defaultTestObject
	 originalCallingTime:TMOriginalCallingAfterBlock
		  swizzlingBlock:kEmptySwizzlingBlock];

	// when
	CGRect returnedRect = [defaultTestObject rectReturningMethodWithRect:expectedRect];

    // then
	BOOL returnedRectIsEqualToExpectedRect = CGRectEqualToRect(returnedRect, expectedRect);
    XCTAssertTrue(returnedRectIsEqualToExpectedRect, @"Unexpected returned CGRect value");
}

- (void)testSwizzlingAMethodAndUnswizzlingItInTheSwizzlingBlockAndCallingOriginalAfter_callingTheMethod_keepsOriginalImplementation
{
	// given
	__block NSUInteger callCounter = 0;
	TMSwizzlingBlock swizzlingBlock = ^(NSInvocation *invocation){
		callCounter++;
		[sut undoSwizzlingForSelector:@selector(voidMethodWithoutParams) fromObject:defaultTestObject];
	};

	[sut swizzleSelector:@selector(voidMethodWithoutParams) fromObject:defaultTestObject originalCallingTime:TMOriginalCallingAfterBlock
		  swizzlingBlock:swizzlingBlock];

	// when
	[defaultTestObject voidMethodWithoutParams];

	defaultTestObject.methodCalled = NO;
	[defaultTestObject voidMethodWithoutParams];

	// then
    XCTAssertTrue(callCounter == 1, @"Method called wrong number of times: %d (expecting 1)", callCounter);
    XCTAssertTrue(defaultTestObject.methodCalled, @"Method not called");
}

@end
