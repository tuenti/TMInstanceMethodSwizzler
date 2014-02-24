//
//  TMGenericTestObject.h
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

#import <Foundation/Foundation.h>

@interface TMGenericTestObject : NSObject

@property (nonatomic, assign) BOOL methodCalled;
@property (nonatomic, assign) NSArray *params;

- (void)voidMethodWithoutParams;

- (void)voidMethodWithOneObjectParam:(id)param;
- (void)voidMethodWithFirstObjectParam:(id)firstParam secondObjectParam:(id)secondParam thirdObjectParam:(id)thirdParam;
- (void)voidMethodWithIntegerParam:(NSInteger)integerParam floatParam:(CGFloat)floatParam timeIntervalParam:(NSTimeInterval)timeIntervalParam;
- (void)voidMethodWithRect:(CGRect)rectParam affineTransform:(CGAffineTransform)transform;

- (id)objectReturningMethodWithObject:(id)param;
- (NSInteger)integerReturningMethodWithInteger:(NSInteger)param;
- (CGRect)rectReturningMethodWithRect:(CGRect)param;

@end
