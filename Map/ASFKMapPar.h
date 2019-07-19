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
#import "ASFKMapBase.h"
/**
 @name ASFKMapPar
 @see ASFKCombination
 @brief maps a given data set to another data set.
 The main purpose: provide parallel mapping of of given data set into another.
 More formal description: being provided with function F and data set D0...Dn, this object invokes them as F(D0)->D`0 ... F(Dn)->D`n and the result is in D`n.
 The order of executions is undefined.
 When all executions ended then summary procedure is invoked.
 */
@interface ASFKMapPar :ASFKMapBase


@end
