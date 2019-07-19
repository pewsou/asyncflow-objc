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

//
//  Created by Boris Vigman on 23/02/2019.
//  Copyright © 2019 Boris Vigman. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "ASFKBase.h"
/**
 @name ASFKApplyPar
 @see ASFKNonForkable
 @brief Application of provided block to provided collection of parameters in parallel.
 The main purpose: provide parallel execution of specified function upon the given collection of data sets.
 Formal description: being provided with set of functions F0...Fn and parameter P1, this object invokes them as F0(param), F1(param)...Fn(param).
 The order of invocations is undefined.
 When all executions ended then summary procedure is invoked.
 */
@interface ASFKApplyPar : ASFKNonForkable <ASFKApplicative>


@end
