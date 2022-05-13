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
//
#ifndef __A_S_F_K_Mailbox_h__
#define __A_S_F_K_Mailbox_h__

#import <Foundation/Foundation.h>
#import "ASFKMBProperties.h"
#import "ASFKBase.h"
typedef NSIndexSet* (^clbkASFKMBFilter)(NSArray* collection);
typedef void(^ASFKMbMemPressureRoutine)(NSDate* timepoint, NSUInteger objectsCount);
typedef void(^ASFKMbLockConditionRoutine)(id cid, BOOL group, id msgId, id msg);
@interface ASFKMBCallbacksMaintenance:NSObject{
    @public ASFKMbMemPressureRoutine prMemPressure;
}
@end

#pragma mark - Mailbox
@interface ASFKMailbox : NSObject{
    @protected NSLock* lockDB;
    @protected NSLock* lockUsersDB;
    @protected NSLock* lockGroupsDB;
    @protected NSMutableDictionary* users;
    @protected NSMutableDictionary* groups;
}

+ (ASFKMailbox *)sharedManager ;
#pragma mark - Secret
/*!
 @brief sets master secret.
 @discussion some operations require secret to be provided as parameter. Master secret overrides private secret in creation/deletion of group/user, but does not override reading/popping operations. Nil secret means that no secret exists, therefore secret check is skipped.
 @param oldsec old master secret; may be nil.
 @param newsec new master secret; may be nil, in this case master secret will be effectively removed.
 @return YES for successful setting, NO otherwise.
 */
- (BOOL)setMasterSecret:(ASFKMasterSecret*)oldsec newSecret:(ASFKMasterSecret*)newsec;
/*!
 @brief sets private secret for a standalone mailbox.
 @discussion some operations require secret to be provided as parameter. Standalone mailbox operations require Private secret, which should not be shared.
 @param oldsec previous private secret; may be nil.
 @param newsec new private secret; may be nil, in this case private secret will be effectively removed.
 @param uid standalone user id.
 @return YES for successful setting, NO otherwise.
 */
- (BOOL)setPrivateSecret:(ASFKPrivateSecret*)oldsec withNew:(ASFKPrivateSecret*)newsec forMailbox:(id)uid;
/*!
 @brief sets group secret for a standalone mailbox.
 @discussion some operations require secret to be provided as parameter. Standalone mailbox operations require Private secret, which should not be shared.
 @param oldsec previous private secret; may be nil.
 @param newsec new private secret; may be nil, in this case private secret will be effectively removed.
 @param gid group id.
 @param priv private secret, associated with creator of this group. Needed to authorize this operation.
 @return YES for successful setting, NO otherwise.
 */
- (BOOL)setGroupSecret:(ASFKGroupSecret*)oldsec withNew:(ASFKGroupSecret*)newsec forGroup:(id)gid usingPrivateSecret:(ASFKPrivateSecret*)priv;
#pragma mark - Creation
/*!
 @brief creates new unique user
 @discussion if user with such ID exists, nothing is created; otherwise new group with same ID is created and the user added to it.
 @param uid desirable identifier of the new user; if nil, nothing is created; if user exists, nothing is created.
 @param secret secret; master or private secret associated with this user. Cannot be changed later. If nil, then ignored.
 @param props new user's properties.
 @return new user's ID, or nil if user could not be created.
  */
-(id) createMailbox:(id)uid withProperties:(ASFKMBContainerProperties*)props secret:(ASFKPrivateSecret*)secret;;
/*!
 @brief creates new unique group
 @discussion if group with such ID exists, nothing is created; otherwise new group with same id is created.
 @param gid desirable identifier of the new group; if nil, or such group already exists then nothing is created..
 @param secret secret; master or private secret associated with this user. Cannot be changed later. If nil, then ignored.
 @param props new group's properties.
 @return id of newly created group, nil if operation failed.
 */
-(id) createGroup:(id)gid withProperties:(ASFKMBContainerProperties*)props secret:(ASFKPrivateSecret*)secret;;
/*!
 @brief creates clone of existing group
 @discussion if group with such ID not exists, nothing is created; otherwise new group with new id is created.
 @param gid identifier of the existing group; if nil, or such group not exists then nothing is created.
 @param newid desirable identifier of clone group; if nil, or such group already exists then nothing is created.
 @param secret secret; private secret associated with this user. Cannot be changed later. If nil, then ignored, unless no secret was set before. The clone group will have the same secret as original one.
 @param props new group's properties; if nil, then default properties will be created.
 @return id of clone group, nil if operation failed.
 */
-(id) cloneGroup:(id)gid newId:(id)newid withProperties:(ASFKMBContainerProperties*)props secret:(ASFKPrivateSecret*)secret;;

/*!
 @brief adds user to the specific group; if group is private or member limit is exceeded, operation fails.
 @param uid user ID; if nil, registration fails.
 @param gid group ID; if nil, registration fails.
 @param props set of properties; if nil, then group's properties will be applied instead.
 @return YES for success, NO otherwise.
 */
-(BOOL) addUser:(id)uid toGroup:(id)gid withProperties:(ASFKMBGroupMemberProperties*)props secret:(ASFKPrivateSecret*)psecret;
#pragma mark - Configuring
/*!
 @brief set limits for number of members in group.
 @discussion if low value is 0, then there is no low limit. Same about high limit value.
 @param low if number of members is below this value, then message delivery will be avoided in this group.
 @param high if number of members is above this number then new members will not be added.
 @param gid group ID; if nil or not found, operation fails.
 @return YES for success, NO otherwise.
 */
-(BOOL) setMemberingLimitsLow:(NSUInteger)low high:(NSUInteger)high forGroup:(id)gid secret:(ASFKPrivateSecret*)secret;
/*!
 @brief set new properties for given user.
 @param props properties container; if nil, nothing is done, operation fails.
 @param uid user ID; if not found or invalid, operation fails.
 @param secret secret; master or private secret associated with this user. If this parameter does not match the stored secret, then operation fails.
 @return YES for success, NO otherwise.
 */
-(BOOL) setProperties:(ASFKMBContainerProperties*)props forMailbox:(id)uid secret:(ASFKPrivateSecret*)secret;
/*!
 @brief set new properties for given group.
 @param props properties container; if nil, nothing is done, operation fails.
 @param gid group ID; if nil or not found, operation fails.
 @param secret secret; master or private secret associated with this group. If this parameter does not match the stored secret, then operation fails.
 @return YES for success, NO otherwise.
 */
-(BOOL) setProperties:(ASFKMBContainerProperties*)props forGroup:(id)gid secret:(ASFKPrivateSecret*)secret;
#pragma mark + Configuring/Queues/Group
/*!
 @brief set limits for number of messages in group.
 @discussion if low value is 0, then there is no low limit. Same about high limit value.
 @param low this number shows minimal size of queue; when below, reading will return empty array.
 @param high this number shows maximal size of queue; when achieved, newly posted messages will be rejected.
 @param gid group ID; if nil or not found, operation fails.
 @return YES for success, NO otherwise.
 */
-(BOOL) setMsgQThresholdsLow:(NSUInteger)low high:(NSUInteger)high forGroup:(id)gid secret:(ASFKPrivateSecret*)secret;
-(BOOL) setMsgQDropPolicy:(eASFKQDroppingPolicy)policy forGroup:(id)gid secret:(ASFKPrivateSecret*)secret;
-(BOOL) setMsgQDroppingAlgorithmL1:(ASFKFilter*)dropAlg forGroup:(id)gid secret:(ASFKPrivateSecret*)secret;
-(BOOL) setMsgQDroppingAlgorithmL2:(clbkASFKMBFilter)dropAlg forGroup:(id)gid secret:(ASFKPrivateSecret*)secret;
#pragma mark + Configuring/Queues/Mailbox
/*!
 @brief set limits for number of messages delivered directly to user.
 @discussion if low value is 0, then there is no low limit. Same about high limit value.
 @param low this number shows minimal size of queue; when below, reading will return empty array.
 @param high this number shows maximal size of queue; when achieved, newly posted messages will be rejected.
 @param uid user ID; if nil or not found, operation fails.
 @return YES for success, NO otherwise.
 */
-(BOOL) setMsgQThresholdsLow:(NSUInteger)low high:(NSUInteger)high forMailbox:(id)uid secret:(ASFKPrivateSecret*)secret;
-(BOOL) setMsgQDropPolicy:(eASFKQDroppingPolicy)policy forMailbox:(id)uid secret:(ASFKPrivateSecret*)secret;
-(BOOL) setMsgQDroppingAlgorithmL1:(ASFKFilter*)dropAlg forMailbox:(id)uid secret:(ASFKPrivateSecret*)secret;
-(BOOL) setMsgQDroppingAlgorithmL2:(clbkASFKMBFilter)dropAlg forMailbox:(id)uid secret:(ASFKPrivateSecret*)secret;
#pragma mark - Configuring/Maintenance
/*!
 @brief executes number of steps for execution daemon.
 @param sampleSize number of samples to process.
 @param timepoint object representing some timepoint.
 @return number of performed sampleSize.
 */
-(NSUInteger) runDaemon:(size_t)sampleSize timepoint:(NSDate*)timepoint callbacks:(ASFKMBCallbacksMaintenance*)clbs;
-(NSUInteger) runDiscarding:(size_t)sampleSize timepoint:(NSDate*)tm;
-(NSUInteger) runDelivery:(size_t)sampleSize ;
-(NSUInteger) runDeferredRoutines:(size_t)sampleSize;
-(NSUInteger) runPeriodic:(size_t)sampleSize timepoint:(NSDate*)tm callbacks:(ASFKMBCallbacksMaintenance*)clbs;
#pragma mark - Discarding
/*!
 @brief removes specific user.
 @discussion if ID found, the group with the same ID will be removed too;  all messages delivered to this group will be discarded.
 @param uid user ID; if nil, deregistration fails.
 @param secret master or private secret is required; if no secret set then nil must be provided.
 @return YES for success, NO otherwise.
 */
-(BOOL) discardMailbox:(id)uid secret:(ASFKSecret*)secret;
/*!
 @brief removes specified group.
 @discussion if ID found, the user with the same ID will be removed too;  all messages delivered to this group will be discarded.
 @param gid group ID; if nil, deregistration fails.
 @param secret master or private secret is required; if no secret set then nil must be provided.
 @return YES for success, NO otherwise.
 */
-(BOOL) discardGroup:(id)gid secret:(ASFKSecret*)secret;
/*!
 @brief removes user from specified group.
 @discussion if user has same ID as group then both user and group will be removed; all messages delivered to this user will be discarded.
 @param uid user ID; if nil or not found, deregistration fails.
 @param gid group ID; if nil or not found, deregistration fails.
 @param secret private secret is required; if no secret set then nil must be provided.
 @return YES for success, NO otherwise.
 */
-(BOOL) discardUser:(id)uid fromGroup:(id)gid  secret:(ASFKPrivateSecret*)secret;
/*!
 @brief removes multiple users from specified group.
 @discussion specified users will not be associated anymore with given group.
 @param uids user IDs; if nil or empty, deregistration fails.
 @param gid group ID; if nil or not found, deregistration fails.
 @param secret master or private secret is required; if no secret set then nil must be provided.
 @return YES for success, NO otherwise.
 */
-(BOOL) discardUsers:(NSArray*)uids fromGroup:(id)gid secret:(ASFKPrivateSecret*)secret;
/*!
 @brief removes user from ALL groups.
 @discussion if user has same ID as group then nothing happens; otherwise user is removed, all messages delivered to it are discarded.
 @param uid user ID; if nil, deregistration fails; if user not found, deregistration fails.
 @param secret master or private secret is required; if no secret set then nil must be provided.
 @return YES for success, NO otherwise.
 */
-(BOOL) discardUserFromAllGroups:(id)uid secret:(ASFKMasterSecret*)secret;
/*!
 @brief removes ALL users from given group.
 @discussion if user has same ID as group then nothing happens; otherwise user is removed, all messages delivered to it are discarded.
 @param gid group ID; if nil, deregistration fails; if group not found, deregistration fails.
 @param secret master secret is required; if no secret set then nil must be provided.
 @return YES for success, NO otherwise.
 */
-(BOOL) discardAllUsersFromGroup:(id)gid secret:(ASFKPrivateSecret*)secret;
/*!
 @brief removes ALL groups
 @discussion all groups will be removed, all messages will be discarded.
 @param secret secret; master secret is required; if no secret set then nil must be provided.
 @return YES for success, NO otherwise.
 */
-(BOOL) discardAllGroupsWithSecret:(ASFKMasterSecret*)secret;
/*!
 @brief removes ALL existing users
 @discussion all users will be removed, all delivered messages will be discarded.
 @param secret secret; master secret is required; if no secret set then nil must be provided.
 @return YES for success, NO otherwise.
 */
-(BOOL) discardAllUsersWithSecret:(ASFKMasterSecret*)secret;
/*!
 @brief removes ALL messages from ALL groups
 @discussion all messages in all groups will be discarded.
 @param secret secret; master secret is required; if no secret set then nil must be provided.
 @return YES for success, NO otherwise.
 */
-(BOOL) discardAllMessagesWithSecret:(ASFKMasterSecret*)secret;
/*!
 @brief removes ALL messages from specified group
 @discussion all messages in specified group will be discarded.
 @param secret secret; private secret is required; if no secret set then nil must be provided.
 @return YES for success, NO otherwise.
 */
-(BOOL) discardAllMessagesFromGroup:(id)gid secret:(ASFKPrivateSecret*)secret;
/*!
 @brief removes ALL messages from specified user
 @discussion all messages delivered to specified user will be discarded.
 @param secret secret; private secret is required; if no secret set then nil must be provided.
 @return YES for success, NO otherwise.
 */
-(BOOL) discardAllMessagesFromMailbox:(id)uid secret:(ASFKPrivateSecret*)secret;
#pragma mark - Stats
/*!
 @brief counts ALL messages delivered to all users.
 @discussion counts only messages that are not discarded; counts only unique messages: message delivered to several groups or users counts as 1;
 @return Number of messages.
 */
-(NSUInteger) totalMessages;
/*!
 @brief counts ALL existing groups.
 @return Number of groups.
 */
-(NSUInteger) totalGroups;
/*!
 @brief counts ALL unique users.
 @discussion counts only unique users: user registered in several groups counts as 1;
 @return Number of users.
 */
-(NSUInteger) totalUsers;
/*!
 @brief counts ALL messages delivered to some group.
 @discussion counts only messages that are not discarded; counts only unique messages: message delivered to several users counts as 1;
 @param gid group ID; if nil or not found, returns 0.
 @return Number of messages in group; 0 if group not found.
 */
-(NSUInteger) totalMessagesInGroup:(id)gid;
/*!
 @brief counts ALL messages delivered to some user.
 @discussion counts only messages that are not discarded;
 @param uid user ID; if nil or not found, returns 0.
 @return Number of messages for this user; 0 if user not found.
 */
-(NSUInteger) totalMessagesForUser:(id)uid;
/*!
 @brief counts ALL users of some group.
 @param gid group ID; if nil or not found, returns 0.
 @return Number of users in this group; 0 if group not found.
 */
-(NSUInteger) totalUsersInGroup:(id)gid;
#pragma mark - Reading & Popping

/*!
 @brief reads specified number of earliest messages delivered to given mailbox.
 @discussion After reading messages are NOT deleted from the queue; fetched messages ordered earliest to latest. If messages arrives from blocking call - the corresponding message is read, calling thread is NOT released.
 @param skipAndTake range of retrieval; loc represents offset from beginning, number of messages to skip; length represents number of items to retrieve; if 0 then reading fails.
 @param uid user ID; if nil, read fails.
 @param secret private (associated with this group) secret is required; if no secret set then nil must be provided. If provided secret does not match the stored one, operation fails.
 @return array of available messages; size of array is less or equal to msgcount; if there is no message, returns empty array.
 */
-(NSArray*) readEarliestMsg:(NSRange)skipAndTake fromMailbox:(id)uid withSecret:(ASFKPrivateSecret*)secret;
/*!
 @brief reads specified number of latest messages delivered to given user.
 @discussion After reading messages are NOT deleted from the queue; fetched messages ordered earliest to latest.
 @param skipAndTake range of retrieval; loc represents offset from beginning, number of messages to skip; length represents number of items to retrieve; if length is 0 then reading fails.
 @param uid user ID; if nil, read fails.
 @param secret private (associated with this user) secret is required; if no secret set then nil must be provided. If provided secret does not match the stored one, operation fails.
 @return array of available messages; size of array is less or equal to msgcount; if there is no message, returns empty array.
 */
-(NSArray*) readLatestMsg:(NSRange)skipAndTake fromMailbox:(id)uid withSecret:(ASFKPrivateSecret*)secret;
/*!
 @brief reads specified number of earliest messages delivered to given user.
 @discussion After this action messages ARE deleted from the queue; requires secret: private if defined, nil if no secret was established upon creation of user.
 @param skipAndTake range of popping; loc represents offset from beginning, number of messages to skip; length represents number of items to pop; if length is 0 then pop fails.
 @param uid user ID; if nil or not found, pop fails.
 @param secret private (associated with this group) secret is required; if no secret set then nil must be provided. If private secret does not match the stored one, pop fails.
 @return array of available messages; size of array is less or equal to msgcount; if no secret set then nil must be provided.
 */
-(NSUInteger) popEarliestMsg:(NSRange)skipAndTake fromMailbox:(id)uid withSecret:(ASFKPrivateSecret*)secret;
/*!
 @brief pops specified number of earliest messages delivered to given user.
 @discussion After this action messages ARE deleted from the mailbox. requires secret: private if defined, nil if no secret was established upon creation of user.
 @param skipAndTake range of popping; loc represents offset from beginning, number of messages to skip; length represents number of items to pop; if length is 0 then pop fails.
 @param uid user ID; if nil, or not found, pop fails.
 @param secret private (associated with this group) secret is required; if no secret set then nil must be provided. If private secret does not match the stored one, operation fails.
 @return number of removed messages.
 */
-(NSUInteger) popLatestMsg:(NSRange)skipAndTake fromMailbox:(id)uid withSecret:(ASFKPrivateSecret*)secret;
/*!
 @brief reads specified number of earliest messages delivered to given user.
 @discussion After this action messages are NOT deleted from the queue.
 @param skipAndTake a range, where len represents number of messages, loc represents number of messages to skip; if len is 0, operation fails.
 @param gid group ID; if droup does not exist or ID is nil, reading fails .
 @param uid user ID; if user is not registered in this group, reading fails.
 @param secret private (associated with this group) or group secret is required; if no secret set then nil must be provided. If provided secret does not match the stored one, operation fails.
 @return array of available messages; size of array is less or equal to msgcount; if there is no message, returns empty array.
 */
-(NSArray*) readEarliestMsg:(NSRange)skipAndTake fromGroup:(id)gid forUser:(id)uid withSecret:(ASFKPrivateSecret*)secret;
/*!
 @brief reads specified number of latest messages delivered to given user.
 @discussion After this action messages are NOT deleted from the queue.
 @param skipAndTake a range, where len represents number of messages, loc represents number of messages to skip; if len is 0, reading fails.
 @param gid group ID; if droup does not exist or ID is nil, reading fails .
 @param uid user ID; if user is not registered in this group, reading fails.
 @param secret private (associated with this group) or group secret is required; if no secret set then nil must be provided. If provided secret does not match the stored one, operation fails.
 @return array of available messages; size of array is less or equal to msgcount; if there is no message, returns empty array.
 */
-(NSArray*) readLatestMsg:(NSRange)skipAndTake fromGroup:(id)gid forUser:(id)uid withSecret:(ASFKPrivateSecret*)secret;
/*!
 @brief reads specified number of latest messages delivered to given group.
 @discussion After reading messages ARE deleted from the queue; requires secret: private if private defined, nil if no secret was established upon creation of group. Only member added to this group, or its creator may pop.
 @param skipAndTake a range, where len represents number of messages, loc represents number of messages to skip; if len is 0, reading fails.
 @param gid group ID; if nil or not found, pop fails.
 @param secret private (associated with this group) or group secret is required; if no secret set then nil must be provided. If prided secret does not match the stored one, operation fails.
 */
-(void) popLatestMsg:(NSRange)skipAndTake  fromGroup:(id)gid forUser:(id)uid withSecret:(ASFKPrivateSecret*)secret;
/*!
 @brief reads specified number of earliest messages delivered to given group.
 @discussion After reading messages ARE deleted from the queue; requires secret: private if private defined, nil if no secret was established upon creation of group. Only member added to this group, or its creator may pop.
 @param skipAndTake a range, where len represents number of messages, loc represents number of messages to skip; if len is 0, reading fails.
 @param gid user ID; if nil or not found, pop fails.
 @param secret private (associated with this group) or group secret is required; if no secret set then nil must be provided. If prided secret does not match the stored one, operation fails.
 */
-(void) popEarliestMsg:(NSRange)skipAndTake fromGroup:(id)gid forUser:(id)uid withSecret:(ASFKPrivateSecret*)secret;

#pragma mark - Cast interface/Unicasting
/*!
 @brief delivers specified message asycnhronously to specific user.
 @discussion delivered message can be retracted if this is enabled in 'props' object; to enable, time interval needs to be specified.
 @param msg a message to be delivered; if nil, delivery fails.
 @param uid user ID; if nil, delivery fails.
 @param props properties of message; can be nil.
 @return message's ID for successful delivery, nil otherwise.
 */
-(id) cast:(id)msg forMailbox:(id)uid withProperties:(ASFKMBMsgProperties*)props secret:(ASFKMasterSecret*)secret;;
#pragma mark - Cast interface/Multicasting
/*!
 @brief delivers specified message asynchronously to ALL users registered in specific group.
 @discussion delivered message can be retracted if this is enabled in 'props' object; to enable, time interval needs to be specified.
 @param msg a message to be delivered; if nil, delivery fails.
 @param gid group ID; if nil, or not found, pop fails.
 @param props properties of message; can be nil;
 @return message's ID for successful delivery, nil otherwise.
 */
-(id) cast:(id)msg forGroup:(id)gid withProperties:(ASFKMBMsgProperties*)props secret:(ASFKSecret*)secret;;

/*!
 @brief delivers specified message to ALL users belonging to group 'g0'.
 @param msg the message; if nil, delivery fails.
 @param g0 group ID; if nil, delivery fails.
 @return message's ID for successful delivery, nil otherwise.
 */
-(id) multicast:(id)msg toMembersOfGroup:(id)g0 secret:(ASFKSecret*)secret;;
/*!
 @brief delivers specified message to ALL groups and ALL standalone mailboxes.
 @discussion broadcast message cannot be retracted.
 @param msg the message; if nil, delivery fails.
 @param props properties of message; can be nil.
 @return YES for successful delivery, NO otherwise.
 */
-(BOOL) broadcast:(id)msg withProperties:(ASFKMBMsgProperties*)props secret:(ASFKSecret*)secret;;
/*!
 @brief retracts delivered message from specific group.
 @discussion poster can retract posted message while it is available for retraction;the message is available for retraction until it has been popped or its lifetime has ended.
 @param msgId retractable message ID; if nil, action fails.
 @param gid group ID; if nil, action fails.
 */
@end
#endif /*#define __A_S_F_K_Mailbox_h__*/
