/*
 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU Affero General Public License as
 published by the Free Software Foundation, either version 3 of the
 License, or (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU Affero General Public License for more details.
 
 You should have received a copy of the GNU Affero General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
//  Created by Boris Vigman on 23/02/2019.
//  Copyright © 2019 Boris Vigman. All rights reserved.
//

//#import "ASFKBase.h"
#import "ASFKComposeBase.h"
/**
 @see ASFKBase
 @brief Composition with sequential flavor.
 The main purpose: guarantee sequential execution of number of blocks upon the given data item.
 For sequence of blocks next block will start strictly after the previous block ended execution.
 More formal description: being provided with set of functions F0...Fn, this object invokes them as Fn(Fn-1(...(F0(param))...).
  When more than 1 data item supplied then all items will be composed sequentially, i.e. Fn(Fn-1(...(F0(param1))...) follwed by Fn(Fn-1(...(F0(param_2))...) ... followed by  Fn(Fn-1(...(F0(param_m))...).
  When all executions ended the summary functions will be called
 */
@interface ASFKComposeSeq : ASFKComposeBase 

@end
