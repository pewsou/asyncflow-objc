//
//  ComposePar.h
//
//  Created by Boris Vigman on 22/03/2019.
//  Copyright © 2019 Boris Vigman. All rights reserved.
//

//#import <Cocoa/Cocoa.h>
#import "ASFKBase.h"
/**
 @name ComposePar
 @see ASFKBase
 @brief Composition with parallel flavor.
 The main purpose: guarantee sequential execution of number of functions upon the given data set.
 For sequence of procedures the next block will be invoked strictly after the previous block has started.
 More formal description: being provided with set of functions F0...Fn, this object invokes them as Fn(Fn-1(...(F0(param))...).
 All blocks invoked upon the same data set. The aforementioned data set is processed by first
 */
@interface ASFKComposeInterleaving : ASFKBase
-(id)initWithNumberOfQueues:(long)num;
@end
