//
//  TMGenericTestObject.m
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

#import "TMGenericTestObject.h"

// This class is intended to use in tests, so we use ivars to speed up things

@implementation TMGenericTestObject

- (void)voidMethodWithoutParams
{
	_methodCalled = YES;
}

- (void)voidMethodWithOneObjectParam:(id)param
{
	_methodCalled = YES;
	_params = @[param];
}

- (void)voidMethodWithFirstObjectParam:(id)firstParam secondObjectParam:(id)secondParam thirdObjectParam:(id)thirdParam
{
	_methodCalled = YES;
	_params = @[firstParam, secondParam, thirdParam];
}

- (void)voidMethodWithIntegerParam:(NSInteger)integerParam floatParam:(CGFloat)floatParam timeIntervalParam:(NSTimeInterval)timeIntervalParam
{
	_methodCalled = YES;
	_params = @[@(integerParam), @(floatParam), @(timeIntervalParam)];
}

- (void)voidMethodWithRect:(CGRect)rectParam affineTransform:(CGAffineTransform)transform
{
	_methodCalled = YES;
	_params = @[[NSValue valueWithCGRect:rectParam],[NSValue valueWithCGAffineTransform:transform]];
}

- (id)objectReturningMethodWithObject:(id)param
{
	_methodCalled = YES;
	_params = @[param];
	return param;
}

- (NSInteger)integerReturningMethodWithInteger:(NSInteger)param
{
	_methodCalled = YES;
	_params = @[@(param)];
	return param;
}

- (CGRect)rectReturningMethodWithRect:(CGRect)param
{
	_methodCalled = YES;
	_params = @[[NSValue valueWithCGRect:param]];
	return param;
}

@end