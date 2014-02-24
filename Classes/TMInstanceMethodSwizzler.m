//
//  TMInstanceMethodSwizzler.m
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

#import "TMInstanceMethodSwizzler.h"

#import <objc/runtime.h>

#pragma mark - Swizzling assignment data object

@interface TMSwizzlingInformation : NSObject

@property (nonatomic, strong) id object;
@property (nonatomic, assign) SEL selector;
@property (nonatomic, copy) TMSwizzlingBlock swizzlingBlock;
@property (nonatomic, assign) TMOriginalCalling originalCallingTime;

@property (nonatomic, assign) BOOL currentlyRunning;
@property (nonatomic, assign) BOOL shouldBeUnswizzledAfterCallingOriginal;

@end

@implementation TMSwizzlingInformation

- (NSString *)description
{
	return [NSString stringWithFormat:@"object: %@; selector: %@; swizzlingBlock: %@; originalCallingTime: %d; currentlyRunning: %d; shouldBeUnswizzledAfterCallingOriginal: %d>",
			_object, NSStringFromSelector(_selector), _swizzlingBlock, _originalCallingTime, _currentlyRunning, _shouldBeUnswizzledAfterCallingOriginal];
}

@end

#pragma mark - TMInstanceMethodSwizzler class extension

static TMInstanceMethodSwizzler *sharedInstanceMethodSwizzler = nil;
static NSString *const kTMActionHolderClassName = @"TMActionHolder";
static NSUInteger const kFirstParamIndex = 2;

@interface TMInstanceMethodSwizzler ()

@property (nonatomic, strong) NSMutableArray *swizzlingInformationStorage;

@end

#pragma mark - TMInstanceMethodSwizzler implementation

@implementation TMInstanceMethodSwizzler

#pragma mark - Really strict singleton implementation

+ (TMInstanceMethodSwizzler *)sharedInstanceMethodSwizzler
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedInstanceMethodSwizzler = [[TMInstanceMethodSwizzler alloc] init];
	});

	return sharedInstanceMethodSwizzler;
}

+ (id)allocWithZone:(NSZone *)zone
{
	static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        if (!sharedInstanceMethodSwizzler)
		{
            sharedInstanceMethodSwizzler = [super allocWithZone:zone];
        }
    });

    return sharedInstanceMethodSwizzler;
}

- (id)init
{
	__block TMInstanceMethodSwizzler *selfObject;

    @synchronized(self)
	{
        selfObject = [super init];
    };

    self = selfObject;
    return self;
}

- (void)dealloc
{
	[self undoAllSwizzling];
}

#pragma mark - Public interface

- (void)swizzleSelector:(SEL)selector fromObject:(id)object withBlock:(TMSwizzlingBlock)swizzlingBlock
{
	[self swizzleSelector:selector fromObject:object originalCallingTime:TMOriginalCallingNever swizzlingBlock:swizzlingBlock];
}

- (void)swizzleSelector:(SEL)selector
			 fromObject:(id)object
	originalCallingTime:(TMOriginalCalling)originalCallingTime
		 swizzlingBlock:(TMSwizzlingBlock)swizzlingBlock
{
	NSParameterAssert(selector);
	NSParameterAssert(object);
	NSParameterAssert(swizzlingBlock);

	[self registerActionHolderClassForObject:object selector:selector];

	TMSwizzlingInformation *swizzlingInformation = [self swizzlingInformationWithObject:object
																			   selector:selector
																		 swizzlingBlock:swizzlingBlock
																	originalCallingTime:originalCallingTime];

	[self storeSwizzlingInformationReplacingExistingOne:swizzlingInformation];
	[self performSwizzlingWithInformation:swizzlingInformation];
}

- (void)undoSwizzlingForSelector:(SEL)selector fromObject:(id)object
{
	TMSwizzlingInformation *swizzlingInformation = [self swizzlingInformationForSelector:selector object:object];
	if (swizzlingInformation.currentlyRunning)
	{
		swizzlingInformation.shouldBeUnswizzledAfterCallingOriginal = YES;
		return;
	}

	[self perfomUnswizzlingWithInformation:swizzlingInformation];
}

- (void)undoAllSwizzling
{
	while ([self.swizzlingInformationStorage count] > 0)
	{
		[self perfomUnswizzlingWithInformation:[self.swizzlingInformationStorage firstObject]];
	}
}

#pragma mark - Action holder class

- (void)registerActionHolderClassForObject:(id)object selector:(SEL)selector
{
	NSString *className = [self actionHolderClassNameForObject:object selector:selector];
	Class class = NSClassFromString(className);

	if (!class)
	{
		class = [self registeredActionHolderClassWithName: className];
		[self addSelector:selector
				fromClass:[object class]
				  toClass:class];
	}
}

- (NSString *)actionHolderClassNameForObject:(id)object selector:(SEL)selector
{
	NSString *objectClassName = NSStringFromClass([object class]);
	NSString *methodName = NSStringFromSelector(selector);
	return [NSString stringWithFormat:@"%@_%@_%@", kTMActionHolderClassName, objectClassName, methodName];
}

- (Class)actionHolderClassForObject:(id)object selector:(SEL)selector
{
	NSString *actionHolderClassName = [self actionHolderClassNameForObject:object selector:selector];
	return NSClassFromString(actionHolderClassName);
}

- (Class)registeredActionHolderClassWithName:(NSString *)className
{
	const char *classNameAsCString = [className cStringUsingEncoding:NSASCIIStringEncoding];
	Class class = objc_allocateClassPair([NSObject class], classNameAsCString, 0);
	objc_registerClassPair(class);
	return class;
}

- (void)addSelector:(SEL)selector fromClass:(Class)sourceClass toClass:(Class)destinationClass
{
	Method instanceMethod = class_getInstanceMethod(sourceClass, selector);
    const char *methodTypeEncoding = method_getTypeEncoding(instanceMethod);
	IMP originalMethodImplementation = class_getMethodImplementation(sourceClass, selector);

	class_addMethod(destinationClass, selector, originalMethodImplementation, methodTypeEncoding);
}

- (void)unregisterActionHolderClassForObject:(id)object selector:(SEL)selector
{
	Class actionHolderClass = [self actionHolderClassForObject:object selector:selector];
	objc_disposeClassPair(actionHolderClass);
}

#pragma mark - Action selector implementation

// This will replace the implementation of the method swizzled
static void *actionSelectorImplementation(id self, SEL _cmd, ...)
{
	NSMethodSignature *methodSignature = [self methodSignatureForSelector:_cmd];

	NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:methodSignature];
	invocation.selector = _cmd;
	invocation.target = self;

	va_list arguments;
	va_start(arguments, _cmd);
	char* args = (char*)arguments;
	NSUInteger argumentCount = [methodSignature numberOfArguments];
	for (NSUInteger index = kFirstParamIndex; index < argumentCount; index++)
	{
		const char *argumentType = [methodSignature getArgumentTypeAtIndex:index];
		NSUInteger argumentSize, argumentAlignment;
		NSGetSizeAndAlignment(argumentType, &argumentSize, &argumentAlignment);
		NSUInteger mod = (NSUInteger)args % argumentAlignment;
		if (mod != 0)  args += (argumentAlignment - mod);

		[invocation setArgument:args atIndex:index];

		args += argumentSize;
	}
	va_end(arguments);

	[sharedInstanceMethodSwizzler handleInvocation:invocation];

	void *returnValue = nil;
	if (methodSignature.methodReturnLength) [invocation getReturnValue:&returnValue];
	return returnValue;
}

- (void)handleInvocation:(NSInvocation *)invocation
{
	TMSwizzlingInformation *swizzlingInformation = [self swizzlingInformationForSelector:invocation.selector
																				  object:invocation.target];

	swizzlingInformation.currentlyRunning = (swizzlingInformation != nil);

	switch (swizzlingInformation.originalCallingTime) {
		case TMOriginalCallingNever:
			swizzlingInformation.swizzlingBlock(invocation);
			break;

		case TMOriginalCallingBeforeBlock:
			[self performActionHolderClassSelectorForInvocation:invocation
									   withSwizzlingInformation:swizzlingInformation];
			swizzlingInformation.swizzlingBlock(invocation);
			break;

		case TMOriginalCallingAfterBlock:
			swizzlingInformation.swizzlingBlock(invocation);

			[self performActionHolderClassSelectorForInvocation:invocation
									   withSwizzlingInformation:swizzlingInformation];
			break;

		default:
			// We will arrive here if swizzlingInformation is nil, which means this is an
			// object whose method hasn't been swizzled, but belonging to a class which has.
			// We use any of the swizzled objects to get the original implementation
			[self performActionHolderClassSelectorForInvocation:invocation
									   withSwizzlingInformation:[self anyStoredSwizzlingMatchingInvocation:invocation]];
			break;
	}

	swizzlingInformation.currentlyRunning = NO;
}

- (TMSwizzlingInformation *)swizzlingInformationForSelector:(SEL)selector object:(id)object
{
	NSPredicate *filteringPredicate = [NSPredicate predicateWithBlock:^BOOL(TMSwizzlingInformation *swizzlingInformation, NSDictionary *bindings) {
		return (swizzlingInformation.object == object && sel_isEqual(swizzlingInformation.selector, selector));
	}];

	NSArray *swizzlingInformations = [self.swizzlingInformationStorage filteredArrayUsingPredicate:filteringPredicate];
	NSAssert([swizzlingInformations count] <= 1, @"We should just have a swizzling for the same selector in an object");

	return [swizzlingInformations firstObject];
}

- (void)performActionHolderClassSelectorForInvocation:(NSInvocation *)invocation
							 withSwizzlingInformation:(TMSwizzlingInformation *)swizzlingInformation
{
	/*
	 Here we undo the swizzling so we can call the original implementation. Then, we do the swizzling again.
	 There is an easier and better way to do the same, and allows us to drop the synchronized block, which is
	 selecting the implementation the NSInvocation will call:

	 Class actionHolderClass = [self actionHolderClassForObject:invocation.target selector:invocation.selector];
	 IMP originalMethodImplementation = class_getMethodImplementation(actionHolderClass, invocation.selector);
	 [invocation invokeUsingIMP:originalMethodImplementation];
	 
	 Unfortunately, invokeUsingIMP is a private API of NSInvocation :-( we can still call it, but Apple will probably
	 kill us or something worse. For the adventurous, this is a way that will probably bypass Apple checkings:

	 #import <objc/message.h>
	 ...
	 objc_msgSend(invocation, sel_registerName("invokeUsingIMP:"), originalMethodImplementation);

	 */

	@synchronized(self)
	{
		[self undoSwizzlingWithInformation:swizzlingInformation];
		[invocation invoke];
		[self performSwizzlingWithInformation:swizzlingInformation];

		if (swizzlingInformation.shouldBeUnswizzledAfterCallingOriginal)
		{
			[self undoSwizzlingWithInformation:swizzlingInformation];
		}
	}
}

- (TMSwizzlingInformation *)anyStoredSwizzlingMatchingInvocation:(NSInvocation *)invocation
{
	TMSwizzlingInformation *swizzlingInformation = [[TMSwizzlingInformation alloc] init];
	swizzlingInformation.object = invocation.target;
	swizzlingInformation.selector = invocation.selector;
	return [[self storedSwizzlingsSimilarTo:swizzlingInformation] firstObject];
}

#pragma mark - Swizzling assignment generation and storage management

- (NSMutableArray *)swizzlingInformationStorage
{
	if (!_swizzlingInformationStorage)
	{
		_swizzlingInformationStorage = [NSMutableArray array];
	}
	return _swizzlingInformationStorage;
}

- (TMSwizzlingInformation *)swizzlingInformationWithObject:(id)object
												  selector:(SEL)selector
											swizzlingBlock:(TMSwizzlingBlock)swizzlingBlock
									   originalCallingTime:(TMOriginalCalling)originalCallingTime;
{
	TMSwizzlingInformation *swizzlingInformation = [[TMSwizzlingInformation alloc] init];
	swizzlingInformation.object = object;
	swizzlingInformation.selector = selector;
	swizzlingInformation.swizzlingBlock = swizzlingBlock;
	swizzlingInformation.originalCallingTime = originalCallingTime;

	return swizzlingInformation;
}

- (void)storeSwizzlingInformationReplacingExistingOne:(TMSwizzlingInformation *)swizzlingInformation
{
	TMSwizzlingInformation *storedSwizzlingInformation = [self swizzlingInformationForSelector:swizzlingInformation.selector
																						object:swizzlingInformation.object];

	if (storedSwizzlingInformation)
	{
		[self updateSwizzlingInformation:storedSwizzlingInformation withSwizzlingInformation:swizzlingInformation];
	}
	else
	{
		[self storeSwizzlingInformation:swizzlingInformation];
	}
}

- (void)updateSwizzlingInformation:(TMSwizzlingInformation *)originalSwizzlingInformation
		  withSwizzlingInformation:(TMSwizzlingInformation *)replacingSwizzlingInformation
{
	originalSwizzlingInformation.swizzlingBlock = replacingSwizzlingInformation.swizzlingBlock;
}

- (void)storeSwizzlingInformation:(TMSwizzlingInformation *)swizzlingInformation
{
	[self.swizzlingInformationStorage addObject:swizzlingInformation];
}

#pragma mark - Selector swizzling

- (void)performSwizzlingWithInformation:(TMSwizzlingInformation *)swizzlingInformation
{
	[self setUpImplementationForSelector:swizzlingInformation.selector
							   fromClass:[swizzlingInformation.object class]
					  withImplementation:(IMP)actionSelectorImplementation];
}

- (void)perfomUnswizzlingWithInformation:(TMSwizzlingInformation *)swizzlingInformation
{
	if (![self.swizzlingInformationStorage containsObject:swizzlingInformation]) return;

	if ([[self storedSwizzlingsSimilarTo:swizzlingInformation] count] == 0)
	{
		[self undoSwizzlingWithInformation:swizzlingInformation];
		[self unregisterActionHolderClassForSwizzling:swizzlingInformation];
	}

	[self.swizzlingInformationStorage removeObject:swizzlingInformation];
}

- (NSArray *)storedSwizzlingsSimilarTo:(TMSwizzlingInformation *)swizzlingInformationToCompare
{
	NSPredicate *filteringPredicate = [NSPredicate predicateWithBlock:^BOOL(TMSwizzlingInformation *swizzlingInformation, NSDictionary *bindings) {
		return ([swizzlingInformation.object class] == [swizzlingInformationToCompare.object class]
				&& sel_isEqual(swizzlingInformation.selector, swizzlingInformationToCompare.selector)
				&& swizzlingInformation.object != swizzlingInformationToCompare.object);
	}];

	NSArray *swizzlingInformations = [self.swizzlingInformationStorage filteredArrayUsingPredicate:filteringPredicate];
	return swizzlingInformations;
}

- (void)unregisterActionHolderClassForSwizzling:(TMSwizzlingInformation *)swizzlingInformation
{
	[self unregisterActionHolderClassForObject:swizzlingInformation.object selector:swizzlingInformation.selector];
}

- (void)undoSwizzlingWithInformation:(TMSwizzlingInformation *)swizzlingInformation
{
	Class actionHolderClass = [self actionHolderClassForObject:swizzlingInformation.object selector:swizzlingInformation.selector];
	[self setUpImplementationForSelector:swizzlingInformation.selector
							   fromClass:[swizzlingInformation.object class]
							withSelector:swizzlingInformation.selector
							   fromClass:actionHolderClass];
}

- (void)setUpImplementationForSelector:(SEL)originalSelector fromClass:(Class)originalClass withSelector:(SEL)replacingSelector fromClass:(Class)replacingClass
{
	IMP replacingImplementation = class_getMethodImplementation(replacingClass, replacingSelector);

	[self setUpImplementationForSelector:originalSelector
							   fromClass:originalClass
					  withImplementation:replacingImplementation];
}

- (void)setUpImplementationForSelector:(SEL)originalSelector fromClass:(Class)originalClass withImplementation:(IMP)replacingImplementation
{
	Method method = class_getInstanceMethod(originalClass, originalSelector);
	method_setImplementation(method, replacingImplementation);
}

@end
