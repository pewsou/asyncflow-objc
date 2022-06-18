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
/*!
 @brief Sets maximum queue size.
 @discussion when the queue size reached this value any further enqueing operation will not increase it.
 @param size required maximum size.
 @return YES if the update left the limits in ascending order, NO otherwise.
 */
-(BOOL) setMaxQSize:(NSUInteger)size;
/*!
 @brief Sets minimum queue size.
 @discussion when the queue size reached this value any further enqueing operation will not decrease it.
 @param size required minimum size.
 @return YES if the update left the limits in ascending order, NO otherwise.
 */
-(BOOL) setMinQSize:(NSUInteger)size;
/*!
 @brief Sets dropping methods for this queue.
 @discussion when the queue's maximum size reached then on 'push' operation decision needs to be taken regarding fresh candidate. In order to keep the queue size unchanged some item(s) need to be discarded; alternatively new candidate may be rejected. This method sets specific dropping mode.
 */
-(void) setDroppingPolicy:(eASFKQDroppingPolicy)policy;
/*!
 @brief Sets dropping algorithm for this queue.
 @discussion when the queue's maximum size reached then on 'push' operation decision needs to be taken regarding fresh candidate. In order to keep the queue size unchanged some item(s) need to be discarded; alternatively new candidate may be rejected. this method sets specific dropping algorittm.
 @param dropAlg the custom dropping algorithm; may bi nil.
 */
-(void) setDroppingAlgorithmL1:(ASFKFilter*)dropAlg;
/*!
 @brief Pulls item from queue, while simulating the queue size.
 @discussion Sometimes it is necessary to pull item from queue while pretending that its size is differend from actual. 
 @param count number to be temporarily added to the queue size while deciding if item can be pulled.
 */
-(id)   pullWithCount:(NSInteger) count;
/*!
 @brief Filters queue with provided filtering object.
 @discussion Leaves in queue only items that do not match filtering criteria.
 @param filter the filtering object; may be nil.
 */
-(void) filterWith:(ASFKFilter*)filter;
/*!
 @brief Removes from queue given object.
 @discussion Removes from queue all objects equal to given object with respect to provided property; equality is defined by the block.
 @param obj object to remove; may not be nil.
 @param blk block that tests equality; must return YES to remove; may not be nil.
 @return YES for succesful removal; NO otherwise.
 */
-(BOOL) removeObjWithProperty:(id)obj andBlock:(BOOL (^)(id item,id sample, BOOL* stop)) blk;
@end
