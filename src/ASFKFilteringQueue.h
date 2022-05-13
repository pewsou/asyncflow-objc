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
//  Copyright © 2019-2022 Boris Vigman. All rights reserved.
//
#import "ASFKBase.h"

@interface ASFKFilteringQueue : ASFKQueue
typedef NSIndexSet* (^clbkASFKFQFilter)(NSArray* collection, NSRange range);
-(void) setMaxQSize:(NSUInteger)size;
-(void) setMinQSize:(NSUInteger)size;
-(void) setDroppingPolicy:(eASFKQDroppingPolicy)policy;
-(void) setDroppingAlgorithmL1:(ASFKFilter*)dropAlg;
-(void) filterWith:(ASFKFilter*)filter;
//-(BOOL) prependWithFilter:(ASFKFilter*)filter;
//-(BOOL) appendWithFilter:(ASFKFilter*)filter;
-(BOOL) removeObjWithId:(id)obj andBlock:(BOOL (^)(id item,id sample, BOOL* stop)) blk;
@end