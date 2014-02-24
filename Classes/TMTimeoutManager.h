//
//  TMTimeoutManager.h
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

@class TMInstanceMethodSwizzler;

/**
 * Defines the signature for the block accepted by all the expectSelector... methods
 * It's functionally equivalent to dispatch_block_t
 */
typedef void(^TMTimeoutManagerCallbackBlock)(void);

@interface TMTimeoutManager : NSObject

/*!
 * @method expectSelectorToBeCalled:withObject:calledBlock:
 * @abstract Runs the provided block when a selector is called on the target object
 * @param selector The selector expected to be called.
 * @param object The object which implements selector.
 * @param calledBlock The block which should be run when the selector is called
 */
- (void)expectSelectorToBeCalled:(SEL)selector
					  withObject:(id)object
					 calledBlock:(TMTimeoutManagerCallbackBlock)calledBlock;

/*!
 * @method expectSelectorToBeCalled:withObject:beforeTimeout:timeoutBlock:
 * @abstract Runs the provided block when a selector is not called on the target object before a maximum amount of time.
 * @param selector The selector expected to be called.
 * @param object The object which implements selector.
 * @param timeout The seconds to wait for the selector to be called
 * @param timeoutBlock The block which should be run if the selector is not called before timing out
 */
- (void)expectSelectorToBeCalled:(SEL)selector
					  withObject:(id)object
				   beforeTimeout:(NSTimeInterval)timeout
					timeoutBlock:(TMTimeoutManagerCallbackBlock)timeoutBlock;

/*!
 * @method expectSelectorToBeCalled:withObject:beforeTimeout:calledBlock:timeoutBlock:
 * @abstract Runs a block when a selector is called on the target object before a maximum amount of time or another one otherwise.
 * @param selector The selector expected to be called.
 * @param object The object which implements selector.
 * @param calledBlock The block which should be run when the selector is called
 * @param timeout The seconds to wait for the selector to be called
 * @param timeoutBlock The block which should be run if the selector is not called before timing out
 */
- (void)expectSelectorToBeCalled:(SEL)selector
					  withObject:(id)object
				   beforeTimeout:(NSTimeInterval)timeout
					 calledBlock:(TMTimeoutManagerCallbackBlock)calledBlock
					timeoutBlock:(TMTimeoutManagerCallbackBlock)timeoutBlock;

/*!
 * @method releaseExpectations
 * @abstract Stops watching for all the previously expected selectors to be called
 */
- (void)releaseExpectations;

#pragma mark - Dependency injection related code

/*!
 * @method initWithInstanceMethodSwizzler:
 * @abstract Designated initializer for this class
 * @param instanceMethodSwizzler The TMInstanceMethodSwizzler needed by the internal implementation of the class
 */
- (instancetype)initWithInstanceMethodSwizzler:(TMInstanceMethodSwizzler *)instanceMethodSwizzler;
- (instancetype)init __attribute__((unavailable("This component uses dependency injection, don't call init")));

// Dependency
@property (nonatomic, strong, readonly) TMInstanceMethodSwizzler *instanceMethodSwizzler;

@end
