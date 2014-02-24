//
//  TMInstanceMethodSwizzler.h
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

/**
 * Defines the TMOriginalCalling type, which is used to state when the original instance method
 * implementation swizzled by swizzleSelector:fromObject:withBlock:callOriginal: will be called
 *
 * TMOriginalCallingNever: the original implementation won't be called
 * TMOriginalCallingBeforeBlock: the original implementation will be called before the swizzling block
 * TMOriginalCallingAfterBlock: the original implementation will be called after the swizzling block
 */
typedef NS_ENUM(NSUInteger, TMOriginalCalling)
{
	TMOriginalCallingNever = 1,
	TMOriginalCallingBeforeBlock,
	TMOriginalCallingAfterBlock,
};

/**
 * Defines the signature for the block accepted by the method
 * swizzleSelector:fromObject:withBlock:callOriginal:
 *
 * @param invocation The NSInvocation for the orignal method call
 * @discussion The invocation parameter can be used to know the arguments of the
 * original method call. If the block is called instead the original implementation
 * of the method (TMOriginalCallingNever) or after if (TMOriginalCallingAfterBlock),
 * you can use setReturnValue: on invocation to specify or modify the original return
 * value. If the block is called before the original implementation (TMOriginalCallingBeforeBlock)
 * this return value will be overwriten by the original implementation.
 *
 * @warning You should'nt call invoke: or any of its variants on the invocation parameter,
 * as the result is undetermined.
 */
typedef void(^TMSwizzlingBlock)(NSInvocation *invocation);

@interface TMInstanceMethodSwizzler : NSObject

/*!
 * @method swizzleSelector:fromObject:originalCallingTime:swizzlingBlock
 * @abstract Sets or modifies the implementation of a instance method.
 * @param selector The selector for which to set or modify an implementation.
 * @param object The object which implements selector. It's retained until undoSwizzlingForSelector:fromObject: is called
 * @param originalCallingTime Determines if, and when, the original implementation of the method should be called
 * @param swizzlingBlock A block holding the new implementation.
 */
- (void)swizzleSelector:(SEL)selector
			 fromObject:(id)object
	originalCallingTime:(TMOriginalCalling)originalCallingTime
		 swizzlingBlock:(TMSwizzlingBlock)swizzlingBlock;

/*!
 * @method swizzleSelector:fromObject:withBlock:
 * @abstract Sets the implementation of a instance method.
 * @param selector The selector for which to set an implementation.
 * @param object The object which implements selector. It's retained until undoSwizzlingForSelector:fromObject: is called
 * @param swizzlingBlock A block holding the new implementation
 */
- (void)swizzleSelector:(SEL)selector fromObject:(id)object withBlock:(TMSwizzlingBlock)swizzlingBlock;

/*!
 * @method undoSwizzlingForSelector:fromObject:
 * @abstract Returns a selector to its original implementation
 * @param selector The selector to return to its original implementation
 * @param object The object which implements selector
 */
- (void)undoSwizzlingForSelector:(SEL)selector fromObject:(id)object;

/*!
 * @method undoAllSwizzling
 * @abstract Undoes all methods swizzling for every object
 * @discussion It's not necessary to call this method before nilifying the object, as this is done automatically
 */
- (void)undoAllSwizzling;

@end

