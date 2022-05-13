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

//  Copyright © 2019-2022 Boris Vigman. All rights reserved.

#ifndef ASFKExpirationCondition_h
#define ASFKExpirationCondition_h
#import <Foundation/Foundation.h>
#include <vector>
@interface ASFKCondition :NSObject
-(BOOL) isConditionMetForDoubleValues:(std::vector<double>&)values data:(id)data;
-(BOOL) isConditionMetForBoolValues:(std::vector<BOOL>&)values data:(id)data;
-(BOOL) isConditionMetForULonglongValues:(std::vector<unsigned long long>&)values data:(id)data;
-(BOOL) isConditionMetForLonglongValues:(std::vector<long long>&)values data:(id)data;
-(BOOL) isConditionMetAfterDateValue:(NSDate*)aDate data:(id)data;
-(BOOL) isConditionMetForObject:(id)data;
@end

@interface ASFKConditionNone :ASFKCondition
-(BOOL) isConditionMetForLonglongValues:(std::vector<long long>&)values data:(id)data;
@end

@interface ASFKConditionOnBatchEnd:ASFKCondition
-(BOOL) isConditionMetForLonglongValues:(std::vector<long long>&)values data:(id)data;
@end

@interface ASFKConditionTemporal : ASFKCondition
@property (readonly,nonatomic) NSDate* itsDeadline;
@property (readonly,nonatomic) NSTimeInterval itsDelay;
-(id) initWithSeconds:(NSTimeInterval)sec;
-(id) initWithDate:(NSDate*)aDate;
-(void) setDelay:(NSTimeInterval) seconds;
-(void) setDueDate:(NSDate*) aDate;
-(void) setFromTemporalCondition:(ASFKConditionTemporal*)cond;
-(void) delayToDeadline;
-(void) deadlineToDelay;
/*!
 @brief tests ordering between receiver and other object adn sets the receiver to have earliest deadline/delay.
 @param cond object to be tested against. If nil  - none is done.
 @return receiver.
 */
-(ASFKConditionTemporal*) testAndSetEarliest:(ASFKConditionTemporal*)cond;
/*!
 @brief tests ordering between receiver and other object adn sets the receiver to have latest deadline/delay.
 @param cond object to be tested against. If nil  - none is done.
 @return receiver.
 */
-(ASFKConditionTemporal*) testAndSetLatest:(ASFKConditionTemporal*)cond;
/*!
 @brief Compares the receiver with other object and returns object with latest deadline or delay.
 @param cond object to be tested against. If nil  - receiver will be returned.
 @return obejct with latest deadline (delay). If deadline and delay not set for both - returns self.
 */
-(ASFKConditionTemporal*) chooseLatest:(ASFKConditionTemporal*)cond;
/*!
 @brief Compares the receiver with other object and returns object with earliest deadline or delay.
 @param cond object to be tested against. If nil  - receiver will be returned.
 @return obejct with latest deadline (delay). If deadline and delay not set for both - returns self.
 */
-(ASFKConditionTemporal*) chooseEarliest:(ASFKConditionTemporal*)cond;

@end
#pragma mark - Expiration conditions
@interface ASFKExpirationCondition : ASFKCondition

@end

@interface ASFKExpirationConditionNone :ASFKExpirationCondition

@end
@interface ASFKExpirationOnBatchEnd :ASFKExpirationCondition
-(id) initWithBatchSize:(unsigned long long) bsize;
@end

@interface ASFKConditionCallRelease : ASFKCondition{
@private std::vector<BOOL> releaseArgBool;
    @private std::vector<double> releaseArgDouble;
    @private std::vector<long long> releaseArgLongLong;
    @private std::vector<unsigned long long> releaseArgULongLong;
}

@property id releaseArgObject;
@property NSDate* releaseArgDate;

@end
#endif /* ASFKExpirationCondition_h */
