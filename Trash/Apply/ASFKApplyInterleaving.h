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
//  Created by Boris Vigman on 29/05/2019.
//  Copyright © 2019 Boris Vigman. All rights reserved.
//

#import "ASFKBase.h"
//#import "ASFKApplicative.h"
/**
 @name ApplyInterleaving
 @see ASFKBase
 @brief Application of provided procedure to provided collection of parameters in parallel.
 The main purpose: provide parallel execution of specified function upon the given collection of data sets while promising to start next application strictly after the previous application has started.
 */
@interface ASFKApplyInterleaving : ASFKNonForkable
#pragma mark - Deferred Execution
-(void) storeParamAsUnspecified:(id)data;
-(void) storeParamAsUnspecifiedCStyle:(void*)data;
@end
