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
//  Created by Boris Vigman on 15/02/2019.
//  Copyright © 2019-2023 Boris Vigman. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ASFKPrjConfig.h"

#define ASFK_VERSION @"0.4.1"
#define ASFK_IDENTITY_TYPE id

#ifdef __ASFK_VERBOSE_PRINTING__
#define ASFKLog(...) NSLog(@"~INFO~ %s %@",__PRETTY_FUNCTION__, [NSString stringWithFormat:__VA_ARGS__])
#else
#define ASFKLog(...)
#endif

#ifdef __ASFK_DEBUG__
#define DASFKLog(...) NSLog(@"~DEBUG~ %@", [NSString stringWithFormat:__VA_ARGS__])
#else
#define DASFKLog(...)
#endif

#ifdef __ASFK_WARNING__
#define WASFKLog(...) NSLog(@"~WARNING~ %@", [NSString stringWithFormat:__VA_ARGS__])
#else
#define WASFKLog(...)
#endif

#ifdef __ASFK_ERROR__
#define EASFKLog(...) NSLog(@"~ERROR~ %@", [NSString stringWithFormat:__VA_ARGS__])
#else
#define EASFKLog(...)
#endif

#ifdef __ASFK_MISUSE__
#define MASFKLog(...) NSLog(@"~MISUSE~ %@", [NSString stringWithFormat:__VA_ARGS__])
#else
#define MASFKLog(...)
#endif

#import <atomic>
#import <vector>

@interface ASFKReturnInfo : NSObject{
@public double totalSessionTime;
    @public double totalProcsTime;
    @public double returnStatsProcsElapsedSec;
    @public double returnStatsSessionElapsedSec;
    @public std::uint64_t totalProcsCount;
    @public std::uint64_t totalSessionsCount;
    @public NSString* returnCodeDescription;
    @public id returnResult;
    @public id returnSessionId;
    @public BOOL returnCodeSuccessful;
}

@end
#define kASFKGenKeySummary @"summary"
#define ASFK_STATS_KEY_TIME_SESSIONS @"totalSessionsTime"
#define ASFK_STATS_KEY_TIME_PROCS @"totalProcsTime"
#define ASFK_STATS_KEY_COUNT_SESSIONS @"totalSessionsCount"
#define ASFK_STATS_KEY_COUNT_PROCS @"totalProcsCount"

#define kASFKReturnCode @"asfk_ret_code"
#define ASFK_RC_SUCCESS @"asfk_ret_code_succ"
#define ASFK_RC_FAIL @"asfk_ret_code_fail"


#define ASFK_RET_SUMRESULT @"asfk_ret_sumresult"
#define ASFK_RET_NEXT_TARGET @"asfk_ret_nextTarget"

#define kASFKReturnResult @"asfk_ret_result"
#define kASFKReturnSessionId @"asfk_ret_sessionId"
#define kASFKReturnDescription @"asfk_ret_description"
#define kASFKReturnStatsTimeProcsElapsedSec @"asfk_ret_stats_procs_tesec"
#define kASFKReturnStatsTimeSessionElapsedSec @"asfk_ret_stats_session_tesec"

#define kASFKProgressRoutine @"progress_proc"
#define kASFKCancelRoutine @"cancel_proc"
#define kASFKSummaryRoutine @"summary_proc"
#define kASFKRoutinesArray @"procs_array"
#define kASFKSessionIdentity @"session_id"
#define kASFKExpirationCondition @"exp_cond"

/*!
 @brief modes of dropping
 */
enum eASFKQDroppingPolicy{
    /*!
     @brief drop the newest item
     */
    E_ASFK_Q_DP_TAIL=0,
    /*!
     @brief drop the oldest item
     */
    E_ASFK_Q_DP_HEAD,
    /*!
     @brief don't drop, reject new candidate
     */
    E_ASFK_Q_DP_REJECT,
    /*!
     @brief select item for dropping using some algorithm
     */
    E_ASFK_Q_DP_ALGO
};
#pragma mark - Auxilliary
typedef id ( ^ASFKThreadpoolSummary)(void);

@interface ASFKGlobalQueue : NSObject
+(ASFKGlobalQueue *)singleInstance;
-(void) setSummary:(ASFKThreadpoolSummary)summary;

-(id) submitBlocks:(NSArray<dispatch_block_t>*)blarray summary:(id(^)(void))summary QoS:(long)qos blocking:(BOOL)blocking;

@end

@protocol ASFKLockable
@required
-(void) begin;
-(void) commit;
@end
@protocol ASFKControlStarter
@required
/*!
 @brief cancels associated session on its starter's side. Execution of all blocks associated with this session will be canceled too.
 */
-(void) cancel;
/*!
 @brief checks if associated session is canceled from within specific block executed by specific session.
 @return YES for cancelling by callback; NO otherwise.
 */
-(BOOL) cancellationRequestedByCallback;
/*!
 @brief requests or calls off flush for associated session.
 */
-(void) flushRequested:(BOOL)flush;
/*!
 @brief checks if this session is canceled from within specific block executed by specific session.
 @return YES if flush attempt was issued; NO otherwise.
 */
-(BOOL) flushRequested;
-(void) setPaused:(BOOL) yesno;
-(BOOL) isPaused;
-(void) reset;
@end

typedef id ( ^ASFKProgressRoutine)(NSUInteger stage,NSUInteger accomplished ,NSUInteger outOf,id exData);

@protocol ASFKControlCallback
@required
/*!
  @brief orders associated session to cancel. All blocks running within this session will be canceled too.
 */
-(void) stop;
/*!
 @brief checks if this session is canceled by session starter.
 @return YES for cancelling by starter; NO otherwise.
 */
-(BOOL) cancellationRequestedByStarter;
-(id)getCurrentSessionId;
-(id)getParentObjectId;
-(ASFKProgressRoutine) getProgressRoutine;
@end

@interface ASFKControlBlock : NSObject<ASFKControlStarter,ASFKControlCallback>{
    @protected std::atomic<NSUInteger> itsResPosition;
    @protected NSUInteger totalProcessors;
    @protected NSLock* itsLock;;
    @protected ASFKProgressRoutine itsProgressProc;
    @protected std::atomic<NSUInteger> indexSecondary;

    @public std::atomic< BOOL> flushed;
    @protected std::atomic< BOOL> paused;
}
@property (readonly) ASFK_IDENTITY_TYPE sessionId;
@property (readonly) ASFK_IDENTITY_TYPE parentId;
-(id) initWithParent:(ASFK_IDENTITY_TYPE)parentId sessionId:(ASFK_IDENTITY_TYPE) sessionId andSubId:(ASFK_IDENTITY_TYPE)subid;
-(BOOL) cancellationRequested;
-(BOOL) isStopped;
-(BOOL) isPaused;
@end


typedef void(^ASFKDefaultBlockType)(void);

typedef id ( ^ASFKExecutableRoutine)(id<ASFKControlCallback> controlBlock, id data, NSInteger dataIndex);

typedef id ( ^ASFKExecutableRoutineSummary)(id<ASFKControlCallback> controlBlock,NSDictionary* stats,id data);
typedef id ( ^ASFKExpirationRoutine)(id<ASFKControlCallback> controlBlock,NSDictionary* stats,id data);
typedef id ( ^ASFKCancellationRoutine)(id identity);
typedef id ( ^ASFKOnPauseNotification)(id identity, BOOL paused);

/**
 @param controlBlock object controlling the execution
 @param index positive number of current iteration
 @param condParam parameter used for condition evaluation
 @param bodyParam parameter used for body execution
 @param lastResult object produced by previous iteration
 */
typedef id ( ^ASFKExecutableRoutineConditionalBody)(id<ASFKControlCallback> controlBlock,long long index, id condParam,id bodyParam, id lastResult);
/**
 @param controlBlock object controlling the execution.
 @param index positive number of current iteration.
 @param outStop variable that should be set to YES if the user want to terminate this loop execution.
 @param condParam parameter used for condition evaluation.
 @param bodyParam parameter used for body execution.
 @param lastResult object produced by previous iteration.
 */
typedef id ( ^ASFKExecutableRoutineConditionalBodyStoppable)(id<ASFKControlCallback> controlBlock,long long index, BOOL* outStop,id condParam,id bodyParam, id lastResult);
/**
 @param controlBlock object controlling the execution.
 @param condParam data needed to evaluate the condition.
 @param branchParam data needed to evaluate the branch.
 */
typedef id ( ^ASFKExecutableRoutineConditionalBranch)(id<ASFKControlCallback> controlBlock,id condParam, id branchParam);

/**
 @param controlBlock object controlling the execution
 @param param data needed to evaluate the condition
 @return result of evaluation
 */
typedef BOOL ( ^ASFKExecutableRoutineConditional)(id<ASFKControlCallback> controlBlock,id param);
/**
 @param controlBlock object controlling the execution
 @param iteration positive number of current iteration
 @param param evaluation param
 @return result of evaluation
 */
typedef BOOL  ( ^ASFKExecutableRoutineLoopConditional)(id<ASFKControlCallback> controlBlock,long long iteration,id param);


#pragma mark - Base
@interface ASFKBase : NSObject{
    @protected NSLock* lkNonLocal;
    @protected NSMutableDictionary* ctrlblocks;
    @protected double totalProcs;
    @protected double totalProcsTime;
    @protected double totalSessions;
    @protected double totalSessionsTime;
    @protected ASFKProgressRoutine progressProc;
    @protected NSMutableDictionary* priv_statistics;
}
@property (readonly) NSString* itsName;
@property (readonly) double totalTimeSeconds;
@property (readonly) long long totalServedRequestsCount;
@property (readonly) NSDictionary* sources;
@property (readonly) NSDictionary* targets;

+(NSString*) ASFKVersion;
-(id)initWithName:(NSString*)name;
-(id)ASFKVersion;
-(NSDictionary*)getStatistics;
-(ASFKProgressRoutine) getProgressRoutine;
-(BOOL) setProgressRoutine:(ASFKProgressRoutine)progress;
/*!
 @brief Cancel all sessions initiated by given instance.
 */
-(void) cancelAll;
/*!
 @brief Cancel specific session with given ID.
 */
-(void) cancelSession:(ASFK_IDENTITY_TYPE)sessionId;
/*!
 @brief Equals NO there is no active session; YES otherwise.
 */
-(BOOL) isBusy;
/*!
 @brief Equals NO if session with given identity is not performing a work OR such session does not exist; YES otherwise.
 */
-(BOOL) isBusySession:(ASFK_IDENTITY_TYPE)sessionId;
/*!
 @brief returns number of busy sessions associated with this object
 */
-(NSUInteger) controlBlocks;
@end


#pragma mark - Conditional Predicates
@interface ASFKCondition :NSObject{
@protected NSLock* lock;
}
-(BOOL) isConditionMet:(id) data;
-(BOOL) isConditionMetForDoubleValues:(std::vector<double>&)values data:(id)data;
-(BOOL) isConditionMetForBoolValues:(std::vector<BOOL>&)values data:(id)data;
-(BOOL) isConditionMetForULonglongValues:(std::vector<std::uint64_t>&)values data:(id)data;
-(BOOL) isConditionMetForLonglongValues:(std::vector<std::int64_t>&)values data:(id)data;
-(BOOL) isConditionMetAfterDateValue:(NSDate*)aDate data:(id)data;
-(BOOL) isConditionMetForObject:(id)data;
-(BOOL) isConditionMetForDoubleValue:(double)value data:(id)data;
-(BOOL) isConditionMetForBoolValue:(BOOL)value data:(id)data;
-(BOOL) isConditionMetForULonglongValue:(std::uint64_t)value data:(id)data;
-(BOOL) isConditionMetForLonglongValue:(std::int64_t)value data:(id)data;

-(std::vector<std::uint64_t>&) getULLVector;
-(std::vector<std::int64_t>&) getLLVector;
-(std::vector<double>&) getDoubleVector;
-(std::vector<BOOL>&) getBoolVector;
-(NSArray<NSDate*>*) getDateVector;
-(NSArray*) getDataVector;
@end

@interface ASFKConditionNone :ASFKCondition
-(BOOL) isConditionMetForULonglongValues:(std::vector<std::uint64_t>&)values data:(id)data;
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

@interface ASFKExpirationCondition : ASFKCondition
-(BOOL) setULonglongArg:(NSUInteger)arg;
-(BOOL) setLonglongArg:(NSInteger)arg;
-(BOOL) setBoolArg:(BOOL)arg;
-(BOOL) setDoubleArg:(double)arg;
-(BOOL) setObjArg:(id)arg;
-(BOOL) setDateArg:(NSDate*)arg;
-(BOOL) setULonglongArgs:(std::vector<std::uint64_t>&)args;
-(BOOL) setLonglongArgs:(std::vector<std::int64_t>&)arg;
-(BOOL) setBoolArgs:(std::vector<BOOL>&)arg;
-(BOOL) setDoubleArgs:(std::vector<double>&)arg;
-(BOOL) setObjArgs:(NSArray*)arg;
-(BOOL) setDateArgs:(NSArray<NSDate*>*)arg;
-(BOOL) setSampleLongLong:(std::int64_t) val;
@end

@interface ASFKExpirationConditionNone :ASFKExpirationCondition
-(id) initWithBatchSize:(NSInteger)size;
@end
@interface ASFKExpirationConditionOnTimer : ASFKExpirationCondition
@property (nonatomic,readonly) ASFKConditionTemporal* expirationTimer;
-(id) initWithSeconds:(NSTimeInterval)sec;
-(id) initWithDate:(NSDate*)aDate;
-(id) initWithTemporalCondition:(ASFKConditionTemporal*)cond;
@end

@interface ASFKExpirationOnBatchEnd :ASFKExpirationCondition
-(id) initWithBatchSize:(std::int64_t)size skip:(std::int64_t)skip;
@end

@interface ASFKConditionCallRelease : ASFKCondition{
@private std::vector<BOOL> releaseArgBool;
@private std::vector<double> releaseArgDouble;
@private std::vector<std::int64_t> releaseArgLongLong;
@private std::vector<std::uint64_t> releaseArgULongLong;
}

@property id releaseArgObject;
@property NSDate* releaseArgDate;

@end

typedef void  (^ASFKPreBlockingRoutine)();
/**
 @brief defines modes of blocking call.
*/
typedef enum enumASFK_BLOCKING_CALL_MODE{
    /**
     @brief ASFK_BC_NO_BLOCK stands for no blocking allowed - calls on session in this mode will be rejected.
     */
    ASFK_BC_NO_BLOCK,
    /**
     @brief ASFK_BC_CONTINUOUS stands for continuous mode - once processing of blocked batch started, first element of the next batch will be fetched for processing immediately after the last element of previous batch. I.e. processing of the next batch will not wait until the previous batch has been fully processed.
     */
    ASFK_BC_CONTINUOUS,
    /**
     @brief ASFK_BC_EXCLUSIVE means that processing of the next batch will start only after the previous batch was fully processed.
     */
    ASFK_BC_EXCLUSIVE
} eASFKBlockingCallMode;
#pragma mark - Secrets
@class ASFKSecret;
/*
 Secrets are objects used to authorize operations; When API call invoked and secret is provided, it is tested against some other stored secret; if both secrets match, the operation is allowed.
 Secrets are organized by types and roles. There are 3 types: Master, Private and Group. Master secret is single, global and can affect all mailboxes. Private/Group may affect only specific mailbox; Private secret should be created and used by mailbox owners only, while Group secret may be used by owner and group members.
 Each secret may play different roles, while some roles are disabled for different secret types.
 
 Available Roles:                                              Private Group Master Floating
 1. Creation of group mailbox                                     x
 by cloning or set operation
 2. Reading                                                       x      x
 3. Popping                                                       x      x
 4. Discarding of mailboxes and groups                            x            x
 5. Unicast                                                       x      x     x
 6. Multicast                                                     x      x     x
 7. Broadcast                                                     x      x     x       x
 8. Moderation - blinding/muting of members                       x      x
 9. Security - changing secrets for Mailbox, Group, Global        x            x
 10. Issuer - retraction/hiding of posted messages                x      x
 11. Config - update of mailbox operational parameters            x
 12. Hosting - addition/removal of members to/from Group mailbox  x      x
 
 Secrets lifetime and configuration:
 All secrets have unlimited lifetime by default, which however can be configured to be temporary: for limited time period, limited number of use attempts or custom lifetime shortening criteria. When lifetime is ended the secret is invalidated forever. Manual invalidation is available too.
 Any secret may be configured to have different properties. Any property may be configured only once.
 */

typedef BOOL(^ASFKSecretComparisonProc)(id secret1,id secret2);
/*!
 @brief Declaration of generic secret entity.
 @discussion secrets are associated with containers and tested each time the container is accessed using high-level API.
 */
@interface ASFKSecret :NSObject{
@private
    id _secretModerator;
    id _secretUnicaster;
    id _secretMulticaster;
    id _secretBroadcaster;
    id _secretPopper;
    id _secretReader;
    id _secretDiscarder;
    id _secretCreator;
    id _secretSecurity;
    id _secretConfigurer;
    id _secretHost;
    id _secretIssuer;
}
@property (readonly) ASFKConditionTemporal* timerExpiration;
#pragma mark - Unicast
-(BOOL) matchesUnicasterSecret:(ASFKSecret*)secret;
-(BOOL) setUnicasterSecretOnce:(id)secret;
-(BOOL) setUnicasterSecretComparisonProcOnce:(ASFKSecretComparisonProc)cmpproc;
-(void) invalidateUnicasterSecret;
-(BOOL) validSecretUnicaster;
#pragma mark - Multicast
-(BOOL) matchesMulticasterSecret:(ASFKSecret*)secret;
-(BOOL) setMulticasterSecretOnce:(id)secret;
-(BOOL) setMulticasterSecretComparisonProcOnce:(ASFKSecretComparisonProc)cmpproc;
-(void) invalidateMulticasterSecret;
-(BOOL) validSecretMulticaster;
#pragma mark - Broadcast
-(BOOL) matchesBroadcasterSecret:(ASFKSecret*)secret;
-(BOOL) setBroadcasterSecretOnce:(id)secret;
-(BOOL) setBroadcasterSecretComparisonProcOnce:(ASFKSecretComparisonProc)cmpproc;
-(void) invalidateBroadcasterSecret;
-(BOOL) validSecretBroadcaster;
#pragma mark - Reader
-(BOOL) matchesReaderSecret:(ASFKSecret*)secret;
-(BOOL) setReaderSecretOnce:(id)secret;
-(BOOL) setReaderSecretComparisonProcOnce:(ASFKSecretComparisonProc)cmpproc;
-(void) invalidateReaderSecret;
-(BOOL) validSecretReader;
#pragma mark - Popper
-(BOOL) matchesPopperSecret:(ASFKSecret*)secret;
-(BOOL) setPopperSecretOnce:(id)secret;
-(BOOL) setPopperSecretComparisonProcOnce:(ASFKSecretComparisonProc)cmpproc;
-(void) invalidatePopperSecret;
-(BOOL) validSecretPopper;
#pragma mark - Discarder
-(BOOL) matchesDiscarderSecret:(ASFKSecret*)secret;
-(BOOL) setDiscarderSecretOnce:(id)secret;
-(BOOL) setDiscarderSecretComparisonProcOnce:(ASFKSecretComparisonProc)cmpproc;
-(void) invalidateDiscarderSecret;
-(BOOL) validSecretDiscarder;
#pragma mark - Creator
-(BOOL) matchesCreatorSecret:(ASFKSecret*)secret;
-(BOOL) setCreatorSecretOnce:(id)secret;
-(BOOL) setCreatorSecretComparisonProcOnce:(ASFKSecretComparisonProc)cmpproc;
-(void) invalidateCreatorSecret;
-(BOOL) validSecretCreator;
#pragma mark - Moderator
-(BOOL) matchesModeratorSecret:(ASFKSecret*)secret;
-(BOOL) setModeratorSecretOnce:(id)secret;
-(BOOL) setModeratorSecretComparisonProcOnce:(ASFKSecretComparisonProc)cmpproc;
-(void) invalidateModeratorSecret;
-(BOOL) validSecretModerator;
#pragma mark - Host
-(BOOL) matchesHostSecret:(ASFKSecret*)secret;
-(BOOL) setHostSecretOnce:(id)secret;
-(BOOL) setHostSecretComparisonProcOnce:(ASFKSecretComparisonProc)cmpproc;
-(void) invalidateHostSecret;
-(BOOL) validSecretHost;
#pragma mark - Issuer
-(BOOL) matchesIssuerSecret:(ASFKSecret*)secret;
-(BOOL) setIssuerSecretOnce:(id)secret;
-(BOOL) setIssuerSecretComparisonProcOnce:(ASFKSecretComparisonProc)cmpproc;
-(void) invalidateIssuerSecret;
-(BOOL) validSecretIssuer;
#pragma mark - Config
-(BOOL) matchesConfigSecret:(ASFKSecret*)secret;
-(BOOL) setConfigSecretOnce:(id)secret;
-(BOOL) setConfigSecretComparisonProcOnce:(ASFKSecretComparisonProc)cmpproc;
-(void) invalidateConfigSecret;
-(BOOL) validSecretConfig;
#pragma mark - Security
-(BOOL) matchesSecuritySecret:(ASFKSecret*)secret;
-(BOOL) setSecuritySecretOnce:(id)secret;
-(BOOL) setSecuritySecretComparisonProcOnce:(ASFKSecretComparisonProc)cmpproc;
-(void) invalidateSecuritySecret;
-(BOOL) validSecretSecurity;
#pragma mark - Common
/*!
 @brief Irreversibly invalidates all associated roles.
 */
-(void) invalidateAll;
/*!
 @brief Sets expiration date. This can be done once.
 */
-(BOOL) setExpirationDateOnce:(NSDate*)aDate;
/*!
 @brief Sets delay in seconds before irreversible expiration. This can be done once.
 @return YES if successful; NO otherwise.
 */
-(BOOL) setExpirationDelayOnce:(NSTimeInterval) sec;
/*!
 @brief Tests passing of expiration deadline.
 @return YES if passed; NO otherwise.
 */
-(BOOL) passedExpirationDeadline:(NSDate*)deadline;
/*!
 @brief Sets maximum usage count before irreversible expiration. This can be done once.
 @return YES if successful; NO otherwise.
 */
-(BOOL) setMaxUsageCountOnce:(NSInteger)maxCount;
/*!
 @brief Tests passing of maximum usage count.
 @return YES if passed; NO otherwise.
 */
-(BOOL) passedMaxUsageCount;
/*!
 @brief Tests availability of roles
 @return YES if all roles are available; NO if at least one is unavailable.
 */
-(BOOL) validAll;
/*!
 @brief Tests availability of roles
 @return YES if any role is available; NO if none is unavailable.
 */
-(BOOL) validAny;
/*!
 @brief Tests availability of roles specific for given class.
 @return YES if all class-specific roles are available; NO if at least one specific role is unavailable.
 */
-(BOOL) validCharacteristic;
@end
/*!
 @brief Declaration of master secret entity.
 @discussion If applied to container having private secret - the private secret is overriden if master secret is valid and non-nil. Roles available for master key: purging of maibox, deletion of mailbox, messages and users; setting of master secret; unicast, broadcast and multicast. Master secret may not be used for moderation, reading.
 */
@interface ASFKMasterSecret :ASFKSecret

@end
/*!
 @brief Declaration of private secret entity.
 @discussion only container's owner, having private secret may use it. Roles available for private secret: purging of mailbox; creation of private mailbox; reading and popping; moderation - muting, blinding and so on; unicast, broadcast and multicast.
 */
@interface ASFKPrivateSecret :ASFKSecret

@end
/*!
 @brief Declaration of group secret entity.
 @discussion only group owner and group members may use it. Roles available for group secret: purging of mailbox; reading and popping; moderation - muting, blinding and so on.
 */
@interface ASFKGroupSecret :ASFKPrivateSecret

@end
/*!
 @brief Declaration of floating secret entity.
 @discussion any actor may use it. Roles available for floating secret: broadcast.
 */
@interface ASFKFloatingSecret :ASFKSecret

@end
#pragma mark - Config Sets
@interface ASFKConfigParams:NSObject
{
    @public ASFKReturnInfo* retInfo;
}
-(void) setupReturnInfo;
@end

@interface ASFKExecutionParams:ASFKConfigParams{
    @public ASFKProgressRoutine progressProc;
    @public ASFKExecutableRoutineSummary summaryRoutine;
    @public NSArray<ASFKExecutableRoutine>* procs;
    @public ASFKCancellationRoutine cancellationProc;
    @public ASFKExpirationCondition* expCondition;
    @public ASFKOnPauseNotification onPauseProc;
    @public ASFKPreBlockingRoutine preBlock;
}
@end

@interface ASFKSessionConfigParams:ASFKConfigParams{
    @public ASFKProgressRoutine progressProc;
    @public ASFKExecutableRoutineSummary summaryRoutine;
    @public NSArray<ASFKExecutableRoutine>* procs;
    @public ASFKCancellationRoutine cancellationProc;
    @public ASFKExpirationCondition* expCondition;
    @public ASFKOnPauseNotification onPauseProc;
    @public eASFKBlockingCallMode blockCallMode;
}
@end

@protocol ASFKSynchronous
@end
@protocol ASFKAsynchronous
@end
#pragma mark - Flow
@interface ASFKLinearFlow : ASFKBase<ASFKSynchronous,ASFKAsynchronous>{
    
}
/*!
 @brief Performs non-blocking call with on array of data and invokes stored Summary block with result.
 @param array array of data for processing.
 @return dictionary that includes result of execution followed by additional information.
 */
-(BOOL) castArray:(NSArray*)array exParams:(ASFKExecutionParams*)ex;
-(BOOL) castArray:(NSArray*)array groupBy:(NSUInteger) grpSize exParams:(ASFKExecutionParams*)ex;
-(BOOL) castArray:(NSArray*)array splitTo:(NSUInteger) numOfChunks exParams:(ASFKExecutionParams*)ex;

/*!
 @brief Performs non-blocking call with dictionary of data and invokes stored Summary block with result.
 @param dictionary dictionary of data.
 @return dictionary that includes result of execution followed by additional information.
 */
-(BOOL) castDictionary:(NSDictionary*)dictionary exParams:(ASFKExecutionParams*)ex;

/*!
 @brief Performs non-blocking call with ordered set of data and invokes stored Summary block with result.
 @param set ordered set of data.
 @return dictionary that includes result of execution followed by additional information.
 */
-(BOOL) castOrderedSet:(NSOrderedSet*)set exParams:(ASFKExecutionParams*)ex;
/*!
 @brief Performs non-blocking call with unordered set of data and invokes stored Summary block with result.
 @param set unordered set of data.
 @return dictionary that includes result of execution followed by additional information.
 */
-(BOOL) castUnorderedSet:(NSSet*)set exParams:(ASFKExecutionParams*)ex;
/*!
 @brief Performs non-blocking call with dictionary of data and invokes stored Summary block with result.
 @param uns unspecified piece of data.
 @return dictionary that includes result of execution followed by additional information.
 */
-(BOOL) castObject:(id)uns exParams:(ASFKExecutionParams*)ex;
/**
 @brief Performs blocking call with array of data and invokes stored Summary block. The method will return only after processing of data has ended.
 @param array array of data for processing.
 @return dictionary that includes result of execution followed by additional information.
 */
-(BOOL) callArray:(NSArray*)array exParams:(ASFKExecutionParams*)params;
-(BOOL) callArray:(NSArray*)array groupBy:(NSUInteger) grpSize exParams:(ASFKExecutionParams*)ex;
-(BOOL) callArray:(NSArray*)array splitTo:(NSUInteger) numOfChunks exParams:(ASFKExecutionParams*)ex;
/**
 @brief Performs blocking call with dictionary of data and invokes stored Summary block with result. The method will return only after processing of data has ended.
 @param dictionary dictionary of data.
 @return dictionary that includes result of execution followed by additional information.
 */
-(BOOL) callDictionary:(NSDictionary*)dictionary exParams:(ASFKExecutionParams*)ex;
/**
 @brief Performs blocking call with ordered set of data and invokes stored Summary block with result. The method will return only after processing of data has ended.
 @param set ordered set of data.
 @return dictionary that includes result of execution followed by additional information.
 */
-(BOOL) callOrderedSet:(NSOrderedSet*)set exParams:(ASFKExecutionParams*)ex;

/**
 @brief Performs blocking call with unordered of data and invokes stored Summary block with result. The method will return only after processing of data has ended.
 @param set unordered set of data.
 @return dictionary that includes result of execution followed by additional information.
 */
-(BOOL) callUnorderedSet:(NSSet*)set exParams:(ASFKExecutionParams*)ex;
/*!
 @brief Performs blocking call with dictionary of data and invokes stored Summary block with result. The method will return only after processing of data has ended.
 @param uns unspecified piece of data.
 @return dictionary that includes result of execution followed by additional information.
 */
-(BOOL) callObject:(id)uns exParams:(ASFKExecutionParams*)ex;

-(id) pull;

@end
#pragma mark - Sessional Flow
@interface ASFKSessionalFlow : ASFKBase<ASFKSynchronous,ASFKAsynchronous>{
@protected NSMutableArray<ASFKExecutableRoutine> * _backprocs;
@protected NSArray<ASFKExecutableRoutine> *lfProcs;
@protected ASFKExecutableRoutineSummary sumProc;
@protected ASFKOnPauseNotification onPauseProc;
@protected ASFKCancellationRoutine cancellationHandler;
@protected dispatch_semaphore_t semHighLevelCall;
}
-(NSArray<ASFKExecutableRoutine> *) getRoutines;
-(std::uint64_t) getRoutinesCount;
-(std::uint64_t) getDataItemsCount;
-(ASFKExecutableRoutineSummary) getSummaryRoutine;
-(ASFKCancellationRoutine) getCancellationHandler;
/*!
 @brief Performs non-blocking call with on array of data and invokes stored Summary block with result.
 @param array array of data for processing.
 @return dictionary that includes result of execution followed by additional information.
 */
-(NSDictionary*) castArray:(NSArray*)array session:(id)sessionId exParams:(ASFKExecutionParams*)ex;

/*!
 @brief Performs non-blocking call with dictionary of data and invokes stored Summary block with result.
 @param dictionary dictionary of data.
 @return dictionary that includes result of execution followed by additional information.
 */
-(NSDictionary*) castDictionary:(NSDictionary*)dictionary session:(id)sessionId exParams:(ASFKExecutionParams*)ex;

/*!
 @brief Performs non-blocking call with ordered set of data and invokes stored Summary block with result.
 @param set ordered set of data.
 @return dictionary that includes result of execution followed by additional information.
 */
-(NSDictionary*) castOrderedSet:(NSOrderedSet*)set session:(id)sessionId exParams:(ASFKExecutionParams*)ex;
/*!
 @brief Performs non-blocking call with unordered set of data and invokes stored Summary block with result.
 @param set unordered set of data.
 @return dictionary that includes result of execution followed by additional information.
 */
-(NSDictionary*) castUnorderedSet:(NSSet*)set session:(id)sessionId exParams:(ASFKExecutionParams*)ex;
/*!
 @brief Performs non-blocking call with dictionary of data and invokes stored Summary block with result.
 @param uns unspecified piece of data.
 @return dictionary that includes result of execution followed by additional information.
 */
-(NSDictionary*) castObject:(id)uns session:(id)sessionId exParams:(ASFKExecutionParams*)ex;
/**
 @brief Performs blocking call with array of data and invokes stored Summary block. The method will return only after processing of data has ended.
 @param array array of data for processing.
 @return dictionary that includes result of execution followed by additional information.
 */
-(NSDictionary*) callArray:(NSArray*)array session:(id)sessionId exParams:(ASFKExecutionParams*)params;

/**
 @brief Performs blocking call with dictionary of data and invokes stored Summary block with result. The method will return only after processing of data has ended.
 @param dictionary dictionary of data.
 @return dictionary that includes result of execution followed by additional information.
 */
-(NSDictionary*) callDictionary:(NSDictionary*)dictionary session:(id)sessionId exParams:(NSDictionary*)ex;
/**
 @brief Performs blocking call with ordered set of data and invokes stored Summary block with result. The method will return only after processing of data has ended.
 @param set ordered set of data.
 @return dictionary that includes result of execution followed by additional information.
 */
-(NSDictionary*) callOrderedSet:(NSOrderedSet*)set session:(id)sessionId exParams:(NSDictionary*)ex;

/**
 @brief Performs blocking call with unordered of data and invokes stored Summary block with result. The method will return only after processing of data has ended.
 @param set unordered set of data.
 @return dictionary that includes result of execution followed by additional information.
 */
-(NSDictionary*) callUnorderedSet:(NSSet*)set session:(id)sessionId exParams:(NSDictionary*)ex;
/*!
 @brief Performs blocking call with dictionary of data and invokes stored Summary block with result. The method will return only after processing of data has ended.
 @param uns unspecified piece of data.
 @return dictionary that includes result of execution followed by additional information.
 */
-(NSDictionary*) callObject:(id)uns session:(id)sessionId exParams:(NSDictionary*)ex;

/*!
 @brief Equals NO if sender is updating stored Routines; YES otherwise.
 */
-(BOOL) isReady;

/**
 @brief Appends block which invokes Objective-C code; the block is added to internal collection. This operation may succeed only if no Routine is active at time of addition.
 @param proc block that processes a data.
 */
-(BOOL) addRoutine:(ASFKExecutableRoutine)proc;

/**
 @brief Stores array of Routines for later use; content of array is copied and added to internal collection.
 This operation may succeed only if no Routine is active at time of addition.
 @param procs new array of Routines.
 @return YES if operation succeeded; NO otherwise;
 */
-(BOOL) addRoutines:(NSArray<ASFKExecutableRoutine>*)procs;

/**
 @brief Replaces existing collection of Routines with new one. This operation may succeed only if no Routine is active at time of addition.
 @param procs new array of Routines. If aray is empty or nil, nothing happens.
 @return YES if operation succeeded; NO otherwise.
 */
-(BOOL) replaceRoutinesFromArray:(NSArray<ASFKExecutableRoutine>*)procs;
/**
 @brief Stores summary block which invokes Objective-C code
 @param summary block that is called after all Routines.
 */
-(BOOL) setSummary:(ASFKExecutableRoutineSummary)summary;
-(BOOL) setOnPauseNotification:(ASFKOnPauseNotification)notification;
/**
 @brief Stores block which invokes Objective-C code as a summary for cancelled session.
 @param ch block that is called in case of cancellation.
 */
-(BOOL) setCancellationHandler:(ASFKCancellationRoutine)ch;

@end
#pragma mark - Queues
@interface ASFKQueue : ASFKLinearFlow{
@protected NSLock* lock;
@protected NSMutableArray* q;
@protected std::atomic <BOOL> blocking;
@protected std::atomic <BOOL> paused;
@protected std::atomic<NSUInteger> maxQSize;
@protected std::atomic<NSUInteger> minQSize;
}
-(id) initWithName:(NSString*) name blocking:(BOOL)blk;
/*!
 @brief deletes all accumulated data and resetes configuration.
 @discussion removes queue contents and resets configuration data to defaults.
 */
-(void) reset;
/*!
 @brief deletes all accumulated data.
 @discussion removes queue contents only.
 */
-(void) purge;
/*!
 @brief Sets maximum queue size.
 @discussion when the queue size reaches this value any further enqueing operation will not increase it.
 @param size required maximum size.
 @return YES if the update was successful, NO otherwise.
 */
-(BOOL) setMaxQSize:(NSUInteger)size;
/*!
 @brief Sets minimum queue size.
 @discussion when the queue size reaches this value any further enqueing operation will not decrease it.
 @param size required minimum size.
 @return YES if the update was successul, NO otherwise.
 */
-(BOOL) setMinQSize:(NSUInteger)size;
#pragma mark - replacing contents
/*!
 @brief replaces contents of receiver by contents of another queue.
 */
-(void) queueFromQueue:(ASFKQueue*)q;
/*!
 @brief replaces contents of receiver by contents of an array.
 */
-(void) queueFromArray:(NSArray*)array;
/*!
 @brief replaces contents of receiver by contents of ordered set.
 */
-(void) queueFromOrderedSet:(NSOrderedSet*)set;
/*!
 @brief replaces contents of receiver by contents of unordered set.
 */
-(void) queueFromUnorderedSet:(NSSet*)set;
/*!
 @brief replaces values of receiver by contents of a dictionary. Keys are ignored.
 */
-(void) queueFromDictionary:(NSDictionary*)dict;
#pragma mark - prepending
/*!
 @brief puts contents of another queue at head of receiver's queue. Not available in blocking mode.
 */
-(BOOL) prependFromQueue:(ASFKQueue*)q;
/*!
 @brief puts contents of array at head of receiver's queue. Not available in blocking mode.
 */
-(BOOL) prependFromArray:(NSArray*)array;
/*!
 @brief puts contents of ordered set at head of receiver's queue. Not available in blocking mode.
 */
-(BOOL) prependFromOrderedSet:(NSOrderedSet*)set;
/*!
 @brief puts contents of unordered set at head of receiver's queue. Not available in blocking mode.
 */
-(BOOL) prependFromUnorderedSet:(NSSet*)set;
/*!
 @brief puts values of a dictionary at head of receiver's queue. Keys are ignored
 */
-(BOOL) prependFromDictionary:(NSDictionary*)dict;
#pragma mark - Non-Blocking interface
-(BOOL) castQueue:(ASFKQueue* _Nullable)q exParams:(ASFKExecutionParams* _Nullable)ex;
/*!
 @brief adds items of array to the queue; returns immediately.
 @param array the source array.
 @param ex optional extra parameters.
 @return YES for success; NO for fail.
 */
-(BOOL) castArray:(NSArray* _Nullable)array exParams:(ASFKExecutionParams* _Nullable)ex;
/*!
 @brief adds items of ordered set to the queue; returns immediately.
 @param set the source set.
 @param ex optional extra parameters.
 @return YES for success; NO for fail.
 */
-(BOOL) castOrderedSet:(NSOrderedSet* _Nullable)set exParams:(ASFKExecutionParams* _Nullable)ex;
/*!
 @brief adds items of unordered set to the queue; returns immediately.
 @param set the source set.
 @param ex optional extra parameters.
 @return YES for success; NO for fail.
 */
-(BOOL) castUnorderedSet:(NSSet* _Nullable)set exParams:(ASFKExecutionParams* _Nullable)ex;
/*!
 @brief adds items of dictionary to the queue, keys ignored; returns immediately.
 @param dict the source array.
 @param ex optional extra parameters.
 @return YES for success; NO for fail.
 */
-(BOOL) castDictionary:(NSDictionary* _Nullable)dict exParams:(ASFKExecutionParams* _Nullable)ex;
/*!
 @brief adds single item to the queue; returns immediately.
 @param obj the object.
 @param ex optional extra parameters.
 @return YES for success; NO for fail.
 */
-(BOOL) castObject:(id _Nullable)obj exParams:(ASFKExecutionParams* _Nullable)ex;
/*!
 @brief retrieves item from the queue. In blocking mode if the queue is empty, waits for at least one item.
 */
-(id _Nullable ) pull;
#pragma mark - Blocking interface

-(BOOL) callQueue:(ASFKQueue*_Nullable)q exParams:(ASFKExecutionParams*_Nullable) ex;
/*!
 @brief adds items of array to the queue; in blocking mode returns when the item consumed; otherwise acts same as 'cast'.
 @param array the source array.
 @param ex optional extra parameters.
 @return YES for success; NO for fail.
 */
-(BOOL) callArray:(NSArray* _Nullable) array exParams:(ASFKExecutionParams* _Nullable) ex;
/*!
 @brief adds items of ordered set to the queue; in blocking mode returns when the item consumed; otherwise acts same as 'cast' counterpart.
 @param set the source set.
 @param ex optional extra parameters.
 @return YES for success; NO for fail.
 */
-(BOOL) callOrderedSet:(NSOrderedSet* _Nullable)set exParams:(ASFKExecutionParams* _Nullable) ex;
/*!
 @brief adds items of unordered set to the queue; in blocking mode returns when the item consumed; otherwise acts same as 'cast' counterpart.
 @param set the source set.
 @param ex optional extra parameters.
 @return YES for success; NO for fail.
 */
-(BOOL) callUnorderedSet:(NSSet* _Nullable)set exParams:(ASFKExecutionParams* _Nullable) ex;
/*!
 @brief adds items of dictionary to the queue, keys ignored; in blocking mode returns when the item consumed; otherwise acts same as 'cast' counterpart.
 @param dict the source array.
 @param ex optional extra parameters.
 @return YES for success; NO for fail.
 */
-(BOOL) callDictionary:(NSDictionary* _Nullable)dict exParams:(ASFKExecutionParams* _Nullable) ex;
/*!
 @brief adds single item to the queue; in blocking mode returns when the item consumed; otherwise acts same as 'cast' counterpart.
 @param obj the object.
 @param ex optional extra parameters.
 @return YES for success; NO for fail.
 */
-(BOOL) callObject:(id _Nullable)obj exParams:(ASFKExecutionParams* _Nullable) ex;
#pragma mark - querying
-(NSUInteger)count;
-(BOOL) isEmpty;
-(BOOL) isBlocking;
/*!
 @brief pauses reading from queue. When paused, the queue will return nil on any reading attempt.
 */
-(void) pause;

/*!
 @brief resumes reading from queue.
 */
-(void) resume;

@end

@interface ASFKPriv_EndingTerm : NSObject
+ (ASFKPriv_EndingTerm * _Nonnull)singleInstance ;
@end

/*!
 @class ASFKBatchingQueue
 @brief provides queueing functionality for batches.
 @discussion any call enqueues exactly one object (batch) which in turn can contain single object or collection. Each dequeuing call returns exactly one object from the earliest batch until it is exgausted; after that next batch is tapped. Main reason for such behavior: blocking calls. If blocking mode is disabled then calls do the same as casts. Otherwise, call will block until all of its batch is consumed.
 */
@interface ASFKBatchingQueue : ASFKQueue
{
//@protected std::atomic<BOOL> paused;
@protected std::atomic<std::uint64_t> batchLimitUpper;
@protected std::atomic<std::uint64_t> batchLimitLower;
@protected std::atomic<NSUInteger> netCount;
}
-(BOOL) setUpperBatchLimit:(std::uint64_t)limit;
-(BOOL) setLowerBatchLimit:(std::uint64_t)limit;
#pragma mark - casting with accumulation
-(NSUInteger) candidateCount;
/*!
 @brief adds array to cumulative batch. The batch will not be added to queue until it is finalized.
 @discussion if resulting batch size exceeds the established upper bound, the operation will fail.
 @param array the array.
 @return YES for success, NO otherwise.
 */
-(BOOL) castArrayToBatch:(NSArray*_Nullable) array;
/*!
 @brief adds unordered set to cumulative batch. The batch will not be added to queue until it is finalized.
 @discussion if resulting batch size exceeds the established upper bound, the operation will fail.
 @param set the set.
 @return YES for success, NO otherwise.
 */
-(BOOL) castUnorderedSetToBatch:(NSSet*_Nullable) set ;
/*!
 @brief adds ordered set to cumulative batch. The batch will not be added to queue until it is finalized.
 @discussion if resulting batch size exceeds the established upper bound, the operation will fail.
 @param set the set.
 @return YES for success, NO otherwise.
 */
-(BOOL) castOrderedSetToBatch:(NSOrderedSet*_Nullable) set ;
/*!
 @brief adds dictionary to cumulative batch. The batch will not be added to queue until it is finalized. Only values are stored, keys are ignored.
 @discussion if resulting batch size exceeds the established upper bound, the operation will fail.
 @param dict the dictionary.
 @return YES for success, NO otherwise.
 */
-(BOOL) castDictionaryToBatch:(NSDictionary*_Nullable) dict ;
/*!
 @brief adds single object to cumulative batch. The batch will not be added to queue until it is finalized.
 @discussion if resulting batch size exceeds the established upper bound, the operation will fail.
 @param obj the dictionary.
 @return YES for success, NO otherwise.
 */
-(BOOL) castObjectToBatch:(id _Nullable ) obj;
/*!
 @brief finalizes cumulative batch. The batch will be added to queue and new cumulative batch will be created.
 @param force if NO, then cumulative batch size will be examined against minimum size and, if less than the minumum or greater than maximum - operation will fail. Otherwise the batch will be appended to queue disregarding the size.
 @return YES for success, NO otherwise.
 */
-(BOOL) commitBatch:(BOOL) force;
/*!
 @brief resets cumulative batch. The batch will be cleared form all accumulated objects.
 @return YES for success, NO otherwise.
 */
-(BOOL) resetBatch;

#pragma mark - update from another queue
-(void) queueFromBatchingQueue:(ASFKBatchingQueue* _Nullable)otherq;
/*!
 @brief pauses reading from queue for batches. After invocation, reading method calls will return all items belonging to batch. When entire batch is read, next reading calls will return nil, until 'resume' method invoked.
 */
-(void) pause;

/*!
 @brief resumes reading from queue for batches.
 */
-(void) resume;

/*!
 @brief returns number of batches in queue.
 */
-(NSUInteger) batchCount;

-(NSArray* _Nullable ) pullBatchAsArray;
@end

@interface ASFKFilter : ASFKLinearFlow
/*!
 @brief Tests given object with some custom criteria.
 @param object object to test.
 @return YES if test passes; NO otherwise.
 */
-(BOOL) testCriteriaMatch:(id)object;
/*!
 @brief Tests array of objects.
 @param objects objects to test.
 @param writeOut indication of whether to save passing objects or non-passing. YES for passing, NO otherwise.
 @param array array of filtered objects.
 @return YES if at least one test passes; NO otherwise.
 */
-(BOOL) filterCandidatesInArray:(NSArray*)objects passing:(BOOL)writeOut saveToArray:(NSMutableArray*)array;
/*!
 @brief Tests array of objects.
 @param objects objects to test.
 @param writeOut indication of whether to save passing objects or non-passing. YES for passing, NO otherwise.
 @param iset index set of filtered objects.
 @return YES if at least one test passes; NO otherwise.
 */
-(BOOL) filterCandidatesInArray:(NSArray*)objects passing:(BOOL)writeOut saveToIndexSet:(NSMutableIndexSet*)iset;
/*!
 @brief Tests array of objects.
 @param objects objects to test.
 @param writeOut indication of whether to save passing objects or non-passing. YES for passing, NO otherwise.
 @param range range of indexes of filtered objects.
 @return YES if at least one test passes; NO otherwise.
 */
-(BOOL) filterCandidatesInArray:(NSArray*)objects passing:(BOOL)writeOut saveToRange:(NSRange&)range;
/*!
 @brief Tests unordered set of objects.
 @param objects objects to test.
 @param writeOut indication of whether to save passing objects or non-passing. YES for passing, NO otherwise.
 @param array array of filtered objects.
 @return YES if at least one test passes; NO otherwise.
 */
-(BOOL) filterCandidatesInSet:(NSSet*)objects passing:(BOOL)writeOut saveToArray:(NSMutableArray*)array;
/*!
 @brief Tests unordered set of objects.
 @param objects ordered set of objects to test.
 @param writeOut indication of whether to save passing objects or non-passing. YES for passing, NO otherwise.
 @param iset index set of filtered objects.
 @return YES if at least one test passes; NO otherwise.
 */
-(BOOL) filterCandidatesInOrderedSet:(NSOrderedSet*)objects passing:(BOOL)writeOut saveToIndexSet:(NSMutableIndexSet*)iset;
/*!
 @brief Tests unordered set of objects.
 @param objects ordered set of objects to test.
 @param writeOut indication of whether to save passing objects or non-passing. YES for passing, NO otherwise.
 @param range range of indexes of filtered objects.
 @return YES if at least one test passes; NO otherwise.
 */
-(BOOL) filterCandidatesInOrderedSet:(NSOrderedSet*)objects passing:(BOOL)writeOut saveToRange:(NSRange&)range;
/*!
 @brief Tests dictionary of objects.
 @param objects ordered set of objects to test.
 @param writeOut indication of whether to save passing objects or non-passing. YES for passing, NO otherwise.
 @param keys array of keys of filtered objects. If nil, then not used.
 @param values array of values of filtered objects. If nil, then not used.
 @return YES if at least one test passes; NO otherwise.
 */
-(BOOL) filterCandidatesInDictionary:(NSDictionary*)objects passing:(BOOL)writeOut saveToKeys:(NSMutableArray*)keys values:(NSMutableArray*)values;
@end

@interface ASFKFilteringQueue : ASFKQueue
typedef NSIndexSet* (^clbkASFKFQFilter)(NSArray* collection, NSRange range);

/*!
 @brief Sets dropping methods for this queue.
 @discussion when the queue's maximum size reached then on 'push' operation decision needs to be taken regarding fresh candidate. In order to keep the queue size unchanged some item(s) need to be discarded; alternatively new candidate may be rejected. This method sets specific dropping mode.
 */
-(void) setDroppingPolicy:(eASFKQDroppingPolicy)policy;
/*!
 @brief Sets dropping algorithm for this queue.
 @discussion queue items may need to be dropped not only by exceeding the limits, but by some user-defined algorithm.
 @param dropAlg the custom dropping algorithm; may bi nil.
 */
-(void) setDroppingAlgorithm:(ASFKFilter*_Nullable)dropAlg;
/*!
 @brief Pulls item from queue, while simulating the queue size.
 @discussion Sometimes it is necessary to pull item from queue while pretending that its size is different from the actual.
 @param count number to be temporarily added to the queue size while deciding if item can be pulled.
 */
-(id _Nullable ) pullWithCount:(NSInteger) count;
/*!
 @brief Filters queue with provided filtering object.
 @discussion Leaves in queue only items that do not match filtering criteria.
 @param filter the filtering object; may be nil.
 */
-(void) filterWith:(ASFKFilter*_Nullable)filter;
/*!
 @brief Removes from queue given object.
 @discussion Removes from queue all objects equal to given object with respect to provided property; equality is defined by the block.
 @param obj object to remove; may not be nil.
 @param blk block that tests equality; must return YES to remove; may not be nil.
 @return YES for succesful removal; NO otherwise.
 */
-(BOOL) removeObjWithProperty:(id)obj andBlock:(BOOL (^)(id item,id sample, BOOL* stop)) blk;
@end


#pragma mark - private interfaces

@interface ASFKPriv_WrapBQ:NSObject{
@public NSCondition* writecond;;
@public std::atomic<BOOL> wcPred;
@public NSMutableArray* many;
}
@end
/*!
 @brief ASFKBatchingQueue2
 @discussion internal use. Main purpose: providing 'call' methods without unblocking thread waiting to read.
 */
@interface ASFKBatchingQueue2 : ASFKBatchingQueue
{
@protected NSMutableArray<ASFKPriv_WrapBQ*>* deferred;
}
-(id _Nullable ) initWithName:(NSString*_Nullable) name blocking:(BOOL)blk;
-(id _Nullable) pullAndBatchStatus:(NSInteger&)itemsLeft endBatch:(BOOL&)endBatch term:(ASFKPriv_EndingTerm** _Nonnull)term;
-(void) queueFromBatchingQueue:(ASFKBatchingQueue* _Nullable)otherq;
-(void) releaseFirst;
-(void) releaseAll;
@end
/*!
 @brief ASFKBatchingQueue3
 @discussion internal use. Main purpose: providing 'call' methods without unblocking thread waiting to read.
 */
@interface ASFKBatchingQueue3 : ASFKBatchingQueue2
{}
@end

@interface ASFKThreadpoolQueue:ASFKQueue{
@protected NSInteger occupant;;
}
-(void) queueFromThreadpoolQueue:(ASFKThreadpoolQueue*)queue;
//-(void) queueFromItem:(id)item;
-(id)   pullAndOccupyWithId:(long)itsid empty:(BOOL&)empty index:(NSInteger&)itemIndex term:(ASFKPriv_EndingTerm**)term;
-(BOOL) castObject:(id _Nullable )item exParams:(ASFKExecutionParams*_Nullable)ex index:(NSInteger)index;
-(void) unoccupyWithId:(long)itsid;
-(void) unoccupy;
@end

@interface ASFKThreadpoolQueueHyb : ASFKThreadpoolQueue{
    @public id itsSig;
}
-(id)   initWithBlkMode:(eASFKBlockingCallMode) blockingMode;
-(void) _releaseBlocked;
-(void) _releaseBlockedAll;
@end

typedef enum enumASFKPipelineExecutionStatus{
    eASFK_ES_HAS_MORE=0,
    eASFK_ES_HAS_NONE,
    eASFK_ES_WAS_CANCELLED,
    eASFK_ES_SKIPPED_MAINT
} eASFKThreadpoolExecutionStatus;

typedef id ( ^ASFKThreadpoolSessionCancelProc)(id sessionId);

#pragma mark - Threadpool session(s)
@interface ASFKThreadpoolSession : ASFKBase{
    
    @public    ASFKControlBlock* cblk;
    @protected ASFKExecutableRoutineSummary passSummary;
    @protected ASFKExpirationRoutine expirationSummary;
    @protected ASFKCancellationRoutine cancellationHandler; 
    @protected NSMutableArray<ASFKExecutableRoutine>* procs;
    @protected ASFKExpirationCondition* excond;
    @public    ASFKOnPauseNotification onPauseNotification;
    @public    ASFKThreadpoolSessionCancelProc cancellationProc;
    @public    std::atomic<BOOL> isStopped;
    @public    std::atomic<BOOL> paused;
    @public    std::atomic<eASFKBlockingCallMode> callMode;
    
}
@property  ASFK_IDENTITY_TYPE sessionId;

-(ASFKControlBlock*) getControlBlock;
-(id)   initWithSessionId:(ASFK_IDENTITY_TYPE)sessionId andSubsessionId:(ASFK_IDENTITY_TYPE)subId blkMode:(eASFKBlockingCallMode)blkMode;
-(void) flush;
-(void) cancel;
-(BOOL) postDataItemsAsArray:(NSArray*_Nullable)array blocking:(BOOL)blk;
-(BOOL) postDataItemsAsOrderedSet:(NSOrderedSet*_Nullable)set blocking:(BOOL)blk;
-(BOOL) postDataItemsAsUnorderedSet:(NSSet*_Nullable)set blocking:(BOOL)blk;
-(BOOL) postDataItemsAsDictionary:(NSDictionary*_Nullable)dict blocking:(BOOL)blk;
-(BOOL) postDataItem:(id _Nullable )dataItem blocking:(BOOL)blk;
-(void) replaceRoutinesWithArray:(NSArray<ASFKExecutableRoutine>*_Nullable)procs;
-(void) setProgressRoutine:(ASFKProgressRoutine _Nullable )progress;
-(void) setSummary:(ASFKExecutableRoutineSummary _Nullable )sum;
-(void) setExpirationSummary:(ASFKExecutableRoutineSummary _Nullable )sum;
-(eASFKThreadpoolExecutionStatus) select:(long)selector routineCancel:(ASFKCancellationRoutine)cancel;
-(void) setCancellationHandler:(ASFKCancellationRoutine _Nullable )cru;
-(void) setExpirationCondition:(ASFKExpirationCondition* _Nullable) trop;
-(BOOL) hasSessionSummary;
-(BOOL) isBusy;
-(std::uint64_t) getRoutinesCount;
-(std::uint64_t) getDataItemsCount;
-(void) _invokeCancellationHandler:(ASFKCancellationRoutine) cru identity:(id)identity;
@end
#pragma mark - Global threadpool
@interface ASFKGlobalThreadpool : NSObject
+(ASFKGlobalThreadpool *)singleInstance ;

-(std::uint64_t) runningSessionsCount;
-(std::uint64_t) pausedSessionsCount;
-(std::uint64_t) itemsCountForSession:(ASFK_IDENTITY_TYPE)sessionId;
-(std::uint64_t) totalSessionsCount;

-(BOOL) postDataAsArray:(NSArray*)data forSession:(ASFK_IDENTITY_TYPE)sessionId blocking:(BOOL)blk;
-(BOOL) postDataAsOrderedSet:(NSOrderedSet*)set forSession:(ASFK_IDENTITY_TYPE)sessionId blocking:(BOOL)blk;
-(BOOL) postDataAsUnorderedSet:(NSSet*)data forSession:(ASFK_IDENTITY_TYPE)sessionId blocking:(BOOL)blk;
-(BOOL) postDataAsDictionary:(NSDictionary*)data forSession:(ASFK_IDENTITY_TYPE)sessionId blocking:(BOOL)blk;
-(BOOL) addSession:(ASFKThreadpoolSession*)aseq withId:(ASFK_IDENTITY_TYPE)identity;

-(ASFKThreadpoolSession*) getThreadpoolSessionWithId:(ASFK_IDENTITY_TYPE)identity;
-(NSArray*) getThreadpoolSessionsList;
-(void) cancelSession:(ASFK_IDENTITY_TYPE)sessionId;
-(void) cancelAll;
-(BOOL) isBusySession:(ASFK_IDENTITY_TYPE)sessionId;

-(BOOL) isPausedSession:(ASFK_IDENTITY_TYPE)sessionId;

-(void) flushSession:(ASFK_IDENTITY_TYPE)sessionId;
-(void) flushAll;
-(void) pauseSession:(ASFK_IDENTITY_TYPE)sessionId;
-(void) pauseAll;
-(void) resumeSession:(ASFK_IDENTITY_TYPE)sessionId;
-(void) resumeAll;

@end
#pragma mark - Container callbacks
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
/*!
 @brief notification on popped messages(s).
 @discussion custom Routine that notifies user about popping message(s).
 @param cId group/user ID.
 @param popped array of popped messages.
 @param remaining count of remaining messages.
 */
typedef void(^ASFKMbNotifyOnContainerPopRoutine)(id cId,NSArray* popped,NSUInteger remaining);
/*!
 @brief notification on read messages(s).
 @discussion custom Routine that notifies user about popping message(s).
 @param cId group/user ID.
 @param read array of popped messages.
 @param remaining count of remaining messages.
 */
typedef void(^ASFKMbNotifyOnContainerReadRoutine)(id cId,NSArray* read,NSUInteger remaining);

#pragma mark - Properties
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

#pragma mark - Mailboxes
#import "ASFKMailbox.h"
#pragma mark - Pipelines
//#import "ASFKPipelinePar.h"
@interface ASFKPipelineSession : ASFKThreadpoolSession
@end
/*!
 @see ASFKLinearFlow
 @brief This class provides pipelined execution's functionality. For N Routines it takes Routine P0 and applies it to item D0. Upon completion P0 is applied to D1 while P1 is concurrently applied to D0 and so on.
 */
@interface ASFKPipelinePar : ASFKSessionalFlow
-(std::uint64_t) itemsCountForSession:(_Null_unspecified id)sessionId;
-(std::uint64_t) totalSessionsCount;

-(BOOL) isPausedSession:(_Null_unspecified ASFK_IDENTITY_TYPE)sessionId;


/*!
 @brief Equals YES if session with given identity exists AND is still processing data batch ; NO otherwise.
 */
-(BOOL) isBusySession:(_Null_unspecified ASFK_IDENTITY_TYPE)sessionId;

-(std::uint64_t) getRunningSessionsCount;
-(std::uint64_t) getPausedSessionsCount;

/*!
 @brief Cancels ALL sessions created by this instance.
 */
-(void)cancelAll;
/*!
 @brief Cancels session with given id.
 */
-(void)cancelSession:(_Null_unspecified ASFK_IDENTITY_TYPE)sessionId;
/*!
 @brief flushes all queued items for all sessions created by this instance.
 */
-(void)flushAll;
/*!
 @brief flushes all queued items for given session ID.
 */
-(void)flushSession:(_Null_unspecified ASFK_IDENTITY_TYPE)sessionId;

/*!
 @brief flushes all queued items for all sessions created by this instance.
 */
-(void)pauseAll;
/*!
 @brief flushes all queued items for given session ID.
 */
-(void)pauseSession:(_Null_unspecified ASFK_IDENTITY_TYPE)sessionId;

/*!
 @brief flushes all queued items for all sessions created by this instance.
 */
-(void)resumeAll;
/*!
 @brief flushes all queued items for given session ID.
 */
-(void)resumeSession:(_Null_unspecified ASFK_IDENTITY_TYPE)sessionId;

/*!
 @brief sets new class of QoS (i.e. thread priority).
 @param newqos required class of Quality of Service . Allowed values are:QOS_CLASS_USER_INTERACTIVE, QOS_CLASS_UTILITY, QOS_CLASS_BACKGROUND. By default QOS_CLASS_BACKGROUND is set. The parameter will be in effect after restart.
 */
-(void) setQualityOfService:(long)newqos;

/*!
 @brief returns list of session ID's for all sessions created by this instance.
 @return Array of session ID's.
 */
-(NSArray* _Null_unspecified) getSessions;
/*!
 @brief creates new non-expiring session associated with this instance.
 @param exparams collection of session properties. May be nil; in that case default parameters will be adopted.
 @param sid optional name of session. If nil, then random value will be assigned.
 @return Dictionary of return values.
 */
-(NSDictionary* _Nonnull) createSession:(ASFKSessionConfigParams*_Nullable) exparams sessionId:(id _Nullable ) sid;

@end

