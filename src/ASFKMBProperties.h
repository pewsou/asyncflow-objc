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
//  Created by Boris Vigman on 16/05/2021.
//  Copyright © 2019-2022 Boris Vigman. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ASFKExpirationCondition.h"
#include <atomic>
//typedef enum e_ASFKMBPoppingPolicy{
//    e_ASFKMB_POP_OWNER_ONLY,
//    e_ASFKMB_POP_FIRST_POPPER
//} eASFKMBPoppingPolicy;
typedef void(^ASFKMbNRunOnContainerReadRoutine)(id cId,NSDate* tstamp, NSArray* data);
/*!
 @brief custom filter of incoming messages.
 @discussion custom Routine that filters accepted messages. User can review all accepted messages and select some subset to be removed. After this call ended, the selected messages will be removed from collection.
 @param cId group/mailbox ID.
 @param msgs ordered set of accepted messages.
 @param stop indication provided by user that filtering should be stopped.
 @param lock reference to synchronization primitive. Must be used when the collection as accessed.
 */
typedef BOOL(^ASFKMbContainerFilteringRoutine)(id cId,NSOrderedSet* msgs, BOOL* stop, id<ASFKLockable> lock);
typedef void(^ASFKMbNotifyOnContainerJoinRoutine)(id cId, id guestId);
typedef void(^ASFKMbNotifyOnContainerLeaveRoutine)(id cId, id guestId);
typedef void(^ASFKMbNotifyOnContainerDiscardRoutine)(id cId,NSDate* tstamp);

/*!
 @brief notification on incoming messages.
 @discussion custom Routine that notifies user about incoming message.
 @param cId group/user ID.
 @param newMsgCount up-to-date message count.
 */
typedef void(^ASFKMbNotifyOnNewMsgRoutine)(id cId, NSUInteger newMsgCount);
typedef void(^ASFKMbNotifyOnContainerPopRoutine)(id cId,NSArray* popped,NSUInteger left);
typedef void(^ASFKMbNotifyOnContainerReadRoutine)(id cId,NSArray* read,NSUInteger total);
typedef void(^ASFKMbMsgFeedbackProc)(id cId, NSDate* timepoint, id msg);
#pragma mark - Null Properties
@interface ASFKMBPropertiesNull:NSObject
@end
#pragma mark - Group Member Props
@interface ASFKMBGroupMemberProperties :NSObject
-(void) initFromProps:(ASFKMBGroupMemberProperties*)p;
/*!
 @brief Indication that user should be prevented from reading messages delivered to group. YES for confirmation. 
 @discussion Is ignored when applied to owner of group. Explicit setting of this property will have no effect.
 */
@property (nonatomic) BOOL isBlinded;
/*!
 @brief Indication that user should be prevented from delivering messages to group. YES for confirmation. 
 @discussion Is ignored when applied to owner of group. Explicit setting of this property will have no effect.
 */
@property (nonatomic) BOOL isMuted;

/*!
 @brief Date at which a Group Member will leave group automatically. Nil is ignored.
 */
//@property (nonatomic,readonly) NSDate* leaveOnDate;
/*!
 @brief Group membership duration, greater than zero. After this period member will automatically leave the group. Negative value ignored.
 */
@property (nonatomic,readonly) ASFKConditionTemporal* grpMemLeaveTimer;
/*!
 @brief set Group membership leaving date. Nil or date lesser than or equal to current time lead to invalidation of underlying properties.
 @param date leaving date to set.
 */
-(void) setPropLeaveOnDate:(NSDate *)date;
/*!
 @brief set Group membership duration, greater than zero. Negative/zero value leads to invalidation of underlying properties.
 @param seconds time interval to set.
 */
-(void) setPropLeaveAfterSeconds:(NSTimeInterval)seconds;
/*!
 @param date date to be tested against the 'leaveOnDate' property.
 @return YES if 'date' is before 'leaveOnDate' property; NO otherwise.
 */
-(BOOL) passedLeavingDate:(NSDate *)date;
@end
#pragma mark - Group/Container Props
@interface ASFKMBContainerProperties :NSObject
-(void) initFromProps:(ASFKMBContainerProperties*)p;
@property ASFKMbNRunOnContainerReadRoutine runOnReadProc;
/*!
 @brief Indication of whether addition of new members to a group is allowed. NO for permission.
 @discussion When applied to standalone mailbox, no effect expected.
 */
@property BOOL isPrivate;
/*!
 @brief Indication of whether this container permits blocking Read/Write operations. YES for permission.
 @discussion When applied to standalone mailbox, no effect expected.
 */
@property BOOL blockingReadwriteAllowed;
/*!
 @brief Indication of whether a standalone user can join another group. YES for permission.
 @discussion When applied to a group, no effect expected.
 */
@property BOOL isInvitable;
/*!
 @brief Indication that group container should not accept posts while is not populated; YES for confirmation. Is ignored for single user container.
 */
@property (nonatomic) BOOL noPostUnpopulatedGroup;
/*!
 @brief defines if user list of some group may be used for operations like group cloning, sendToMembers operation or set operations. YES for no sharing, NO otherwise.
 */
@property (nonatomic) BOOL noUserListSharing;
/*!
 @brief indication whether anonimous posting is allowed. YES for confirmation, NO otherwise.
 @discussion anonymous is any message that is accompanied with author ID set to nil. 
 */
@property (nonatomic) BOOL anonimousPostingAllowed;
@property (nonatomic) BOOL retractionAllowed;
/*!
 @brief Container Deletion Timer. If set, provides that the container will be deleted upon expiration.
 */
@property (nonatomic,readonly) ASFKConditionTemporal* containerDeleteTimer;
/*!
 @brief Container Kickout Timer. If set, provides that any user, except the owner will be removed from the container upon timer expiration.
 */
@property (nonatomic,readonly) ASFKConditionTemporal* containerKickoutTimer;
/*!
 @brief Container Drop Message Timer. If set, provides that messages older than established delay will be removed from the container.
 */
@property (nonatomic,readonly) ASFKConditionTemporal* containerDropMsgTimer;
@property ASFKMbContainerFilteringRoutine containerFilterProc;
@property ASFKMbNotifyOnContainerDiscardRoutine onDiscardProc;
@property ASFKMbNotifyOnNewMsgRoutine onNewMsgProc;
@property ASFKMbNotifyOnContainerPopRoutine onPopProc;
@property ASFKMbNotifyOnContainerReadRoutine onReadProc;
@property ASFKMbNotifyOnContainerJoinRoutine onJoinProc;
@property ASFKMbNotifyOnContainerLeaveRoutine onLeaveProc;
@property ASFKMbMsgFeedbackProc feedbackProc;

-(void) setPropMsgCustomCondition:(ASFKCondition*)msgCustomCond;
/*!
 @brief set User/Group deletion date. Nil or date lesser than or equal to current time lead to invalidation of underlying properties Nil means that deletion will not happen.
 @param date termination date to set.
 */
-(void) setPropDeleteOnDate:(NSDate *)date;
-(void) setPropDropMsgOnDate:(NSDate *)date;
-(void) setPropKickoutOnDate:(NSDate *)date;
/*!
 @brief User/Group lifetime, greater than zero. After this period it will be automatically destroyed. Negative value will invalidate underlying properties, deletion will not happen.
 @param seconds time left to termination.
 */
-(void) setPropDeleteAfterSeconds:(NSTimeInterval)seconds;
/*!
 @brief Group member's lifetime, greater than zero. After this period it will be automatically removed from group. Negative value will invalidate underlying properties, kickout will not happen.
 @param seconds time left to termination.
 */
-(void) setPropKickoutAfterSeconds:(NSTimeInterval)seconds;
/*!
 @brief Delivered message's lifetime, greater than zero. After this period it will be automatically destroyed. Negative value will invalidate underlying properties, kickout will not happen.
 @param seconds time left to termination.
 */
-(void) setPropDropMsgAfterSeconds:(NSTimeInterval)seconds;
/*!
 @param date date to be tested against the 'deleteOnDate' property.
 @return YES if 'date' is before 'deleteOnDate' property; NO otherwise.
 */
-(BOOL) passedDeletionDate:(NSDate *)date;
-(BOOL) passedKickoutDate:(NSDate *)date;
-(BOOL) passedDropMsgDate:(NSDate *)date;
@end
#pragma mark - Message Props
@interface ASFKMBMsgProperties:NSObject{
    /*!
     @brief maximum number of reading attempts. Decreases on each attempt. When value is zero, the message will not be available for reading, and deleted. By default set to positive maximum.
     */
    @public std::atomic<NSUInteger> maxAccessLimit;
}
-(void) initFromProps:(ASFKMBMsgProperties*)p;
@property BOOL blocking;
/*!
 @brief Date at which a Message will be destroyed automatically. Nil is ignored.
 @discussion if in container exists ASFKMBContainerProperties object and it defines deletion date for messages, then the earliest date will be picked.
 */
@property (nonatomic,readonly) ASFKConditionTemporal* msgDeletionTimer;
/*!
 @brief When applied to message, indicates that it may be retracted from Group/User before the specified date only. Nil date is ignored.
 */
@property (nonatomic,readonly) ASFKConditionTemporal* msgRetractionTimer;
/*!
 @brief When applied to message, indicates that it may be read from Group/User after the specified date only. Nil date is ignored.
 */
@property (nonatomic,readonly) ASFKConditionTemporal* msgReadabilityTimer;

/*!
 @brief user id of message poster. Nil is interpreted as anonimous posting.
 */
@property (nonatomic,readonly) id msgAuthorId;
/*!
 @brief unique id of message. Nil is ignored.
 */
@property (nonatomic,readonly) NSUUID* msgId;
/*!
 @param date date to be tested.
 @return YES if 'date' is earlier than setting of 'msgRetractionTimer' property; NO otherwise.
 */
-(BOOL) passedRetractionDate:(NSDate *)date;
/*!
 @param date date to be tested..
 @return YES if 'date' is earlier than setting of 'msgReadabilityTimer' property; NO otherwise.
 */
-(BOOL) passedReadingDate:(NSDate *)date;
/*!
 @param date date to be tested.
 @return YES if 'date' is earlier than setting of 'msgDeletionTimer' property; NO otherwise.
 */
-(BOOL) passedDeletionDate:(NSDate *)date;
/*!
 @brief set message deletion date. After this period it will be automatically destroyed. Nil value will invalidate underlying properties.
 @param date date when message must be terminated, if not read.
 */
-(void) setPropDeleteOnDate:(NSDate *)date;
/*!
 @brief set message termination date. Message can be read only before that date passed.
 @param seconds delay before message's termination.
 */
-(void) setPropDeleteAfterSeconds:(NSTimeInterval)seconds;
/*!
 @brief set message reading date. Message can be read only after that date passed.
 @param date date when message would be available for reading.
 */
-(void) setPropReadOnDate:(NSDate *)date;
/*!
 @brief set message reading delay. Message can be read only after that delay elapsed.
 @param seconds delay before the message would be available for reading.
 */
-(void) setPropReadAfterSeconds:(NSTimeInterval)seconds;
/*!
 @brief set time period, during which message may be retracted.
 @param msgRetractInSeconds time left to retraction, unless popped.
 */
-(void) setPropMsgRetractInSeconds:(NSTimeInterval)msgRetractInSeconds;
/*!
 @brief set date, until which the message could be retracted.
 @param msgRetractBeforeDate last date of retraction, unless deleted in other way.
 */
-(void) setPropMsgRetractBeforeDate:(NSDate *)msgRetractBeforeDate;
/*!
 @brief set maximum number of reading attempts.
 @param limit number of times the message can be accessed.
 */
-(void) setPropMsgMaxReadLimit:(NSUInteger)limit;
/*!
 @brief set message's identifier.
 @param msgId identifier.
 */
-(void) setPropMsgId:(NSUUID *)msgId;
/*!
 @brief set identifier of message's issuer.
 @param msgAuthorId issuer's identifier.
 */
-(void) setPropMsgAuthorId:(id)msgAuthorId;
@end

typedef void(^ASFKMbCallReleaseRoutine)();
