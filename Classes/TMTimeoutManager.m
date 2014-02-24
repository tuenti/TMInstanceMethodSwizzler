//
//  TMTimeoutManager.m
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

#import "TMTimeoutManager.h"

#import "TMInstanceMethodSwizzler.h"

static NSTimeInterval const kVoidTimeInterval = 0;

@interface TMTimeoutManager()

@property (nonatomic, strong) TMInstanceMethodSwizzler *instanceMethodSwizzler;

@end

@implementation TMTimeoutManager

- (id)init
{
	NSAssert(NO, @"Please use the designated initializer initWithInstanceMethodSwizzler:");
	return nil;
}

- (instancetype)initWithInstanceMethodSwizzler:(TMInstanceMethodSwizzler *)instanceMethodSwizzler
{
    if (self = [super init])
    {
		_instanceMethodSwizzler = instanceMethodSwizzler;
    }
    return self;
}

- (void)expectSelectorToBeCalled:(SEL)selector
					  withObject:(id)object
					 calledBlock:(TMTimeoutManagerCallbackBlock)calledBlock
{
	[self expectSelectorToBeCalled:selector
						withObject:object
					 beforeTimeout:kVoidTimeInterval
					   calledBlock:calledBlock
					  timeoutBlock:nil];
}

- (void)expectSelectorToBeCalled:(SEL)selector
					  withObject:(id)object
				   beforeTimeout:(NSTimeInterval)timeout
					timeoutBlock:(TMTimeoutManagerCallbackBlock)timeoutBlock
{
	[self expectSelectorToBeCalled:selector
						withObject:object
					 beforeTimeout:timeout
					   calledBlock:nil
					  timeoutBlock:timeoutBlock];
}

- (void)expectSelectorToBeCalled:(SEL)selector
					  withObject:(id)object
				   beforeTimeout:(NSTimeInterval)timeout
					 calledBlock:(void(^)(void))calledBlock
					timeoutBlock:(void(^)(void))timeoutBlock
{
	NSParameterAssert(selector);
	NSParameterAssert(object);
	NSAssert((timeout == kVoidTimeInterval) == (timeoutBlock == nil),
			 @"You must expecify both the timeout and the callback block");

	[self performBlockOnMainThread:^{
		void(^innerTimeoutBlock)(void) = ^{
			[self.instanceMethodSwizzler undoSwizzlingForSelector:selector fromObject:object];
			if (timeoutBlock) timeoutBlock();
		};

		[self.instanceMethodSwizzler swizzleSelector:selector
										  fromObject:object
								 originalCallingTime:TMOriginalCallingAfterBlock
									  swizzlingBlock:^(NSInvocation *invocation) {

										  [self performBlockOnMainThread:^{
											  [NSObject cancelPreviousPerformRequestsWithTarget:self
																					   selector:@selector(timeoutWithBlock:)
																						 object:innerTimeoutBlock];
											  [self.instanceMethodSwizzler undoSwizzlingForSelector:selector
																						 fromObject:object];

											  if (calledBlock) calledBlock();
										  }];

									  }];

		[self performSelector:@selector(timeoutWithBlock:)
				   withObject:innerTimeoutBlock
				   afterDelay:timeout];
	}];
}

- (void)timeoutWithBlock:(TMTimeoutManagerCallbackBlock)timeoutBlock
{
	timeoutBlock();
}

- (void)releaseExpectations
{
	[self performBlockOnMainThread:^{
		[NSObject cancelPreviousPerformRequestsWithTarget:self];
		[self.instanceMethodSwizzler undoAllSwizzling];
	}];
}

- (void)performBlockOnMainThread:(dispatch_block_t)block
{
	NSParameterAssert(block);
	if ([NSThread isMainThread])
	{
		block();
	}
	else
	{
		dispatch_sync(dispatch_get_main_queue(), block);
	}
}

@end
