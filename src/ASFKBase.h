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

#import <Foundation/Foundation.h>
#import "ASFKPrjConfig.h"

#define ASFK_VERSION @"0.2.2"
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

#ifdef __ASFK_DEBUG__
#define WASFKLog(...) NSLog(@"~WARNING~ %@", [NSString stringWithFormat:__VA_ARGS__])
#else
#define WASFKLog(...)
#endif

#ifdef __ASFK_DEBUG__
#define EASFKLog(...) NSLog(@"~ERROR~ %@", [NSString stringWithFormat:__VA_ARGS__])
#else
#define EASFKLog(...)
#endif

#ifdef __ASFK_DEBUG__
#define MASFKLog(...) NSLog(@"~MISUSE~ %@", [NSString stringWithFormat:__VA_ARGS__])
#else
#define MASFKLog(...)
#endif

#define kASFKGenKeySummary @"summary"
#define ASFK_STATS_KEY_TIME_SESSIONS @"totalSessionsTime"
#define ASFK_STATS_KEY_TIME_PROCS @"totalProcsTime"
#define ASFK_STATS_KEY_COUNT_SESSIONS @"totalSessionsCount"
#define ASFK_STATS_KEY_COUNT_PROCS @"totalProcsCount"

#define kASFKReturnCode @"asfk_ret_code"
#define ASFK_RC_SUCCESS @"asfk_ret_code_succ"
#define ASFK_RC_FAIL @"asfk_ret_code_fail"

#define kASFKReturnResult @"asfk_ret_result"
#define ASFK_RET_SUMRESULT @"asfk_ret_sumresult"
#define ASFK_RET_NEXT_TARGET @"asfk_ret_nextTarget"
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

#import <atomic>
#import <vector>

enum eASFKQDroppingPolicy{
    E_ASFK_Q_DP_TAIL=0,
    E_ASFK_Q_DP_HEAD,
    E_ASFK_Q_DP_REJECT,
    E_ASFK_Q_DP_ALGO
};

typedef id ( ^ASFKThreadpoolSummary)(void);

@interface ASFKGlobalQueue : NSObject
+(ASFKGlobalQueue *)sharedManager;
-(void) setSummary:(ASFKThreadpoolSummary)summary;

-(id) submitBlocks:(NSArray<dispatch_block_t>*)blarray summary:(id(^)(void))summary QoS:(long)qos blocking:(BOOL)blocking;

@end

@protocol ASFKRoutable
@required
-(BOOL) push:(id)item;
-(id) pull;
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
-(NSString*)getCurrentSessionId;
-(NSString*)getParentObjectId;
-(ASFKProgressRoutine) getProgressRoutine;
@end

@interface ASFKControlBlock : NSObject<ASFKControlStarter,ASFKControlCallback>{

    @protected std::atomic<NSUInteger> itsResPosition;
    @protected NSUInteger totalProcessors;
    @protected NSLock* itsLock;;
    @protected ASFKProgressRoutine itsProgressProc;
    @protected std::atomic<NSUInteger> indexSecondary;

    @public std::atomic< BOOL> flushed;
    @public std::atomic< BOOL> paused;
}
@property (readonly) ASFK_IDENTITY_TYPE sessionId;
@property (readonly) ASFK_IDENTITY_TYPE parentId;
-(id) initWithParent:(ASFK_IDENTITY_TYPE)parentId sessionId:(ASFK_IDENTITY_TYPE) sessionId andSubId:(ASFK_IDENTITY_TYPE)subid;
-(BOOL) cancellationRequested;
-(BOOL) isStopped;
-(BOOL) isPaused;
@end


typedef void(^ASFKDefaultBlockType)(void);

typedef id ( ^ASFKExecutableRoutine)(id<ASFKControlCallback> controlBlock, id data);

typedef id ( ^ASFKExecutableRoutineSummary)(id<ASFKControlCallback> controlBlock,NSDictionary* stats,id data);
typedef id ( ^ASFKCancellationRoutine)(id identity);

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

@protocol ASFKLinkable
@required

@end

@interface ASFKBase : NSObject<ASFKLinkable>{
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

#import "ASFKMBSecret.h"
#import "ASFKExpirationCondition.h"

@interface ASFKExecutionParams:NSObject{
@public ASFKProgressRoutine progressProc;
@public ASFKExecutableRoutineSummary SummaryRoutine;
@public NSArray<ASFKExecutableRoutine>* procs;
@public ASFKCancellationRoutine cancellationProc;
@public ASFKExpirationCondition* expCondition;
}
@end

#import "ASFKNonlinearFlow.h"
#import "ASFKLinearFlow.h"
@interface ASFKQueue : ASFKLinearFlow{
@protected NSLock* lock;
@protected NSMutableArray* q;
}
-(void) reset;
-(NSUInteger)count;
-(BOOL) isEmpty;
-(void) queueFromQueue:(ASFKQueue*)q;
@end

@interface ASFKThreadpoolQueue:ASFKQueue
-(void) queueFromArray:(NSArray*)array;
-(void) queueFromOrderedSet:(NSOrderedSet*)set;
-(void) queueFromUnorderedSet:(NSSet*)set;
-(void) queueFromQueue:(ASFKThreadpoolQueue*)queue;
-(void) queueFromItem:(id)item;
-(id)   pullAndOccupyWithId:(long)itsid empty:(BOOL&)empty;
-(void) unoccupyWithId:(long)itsid;
-(void) unoccupy;
@end

typedef enum enumASFKPipelineExecutionStatus{
    eASFK_ES_HAS_MORE=0,
    eASFK_ES_HAS_NONE,
    eASFK_ES_WAS_CANCELLED,
    eASFK_ES_SKIPPED_MAINT
} eASFKThreadpoolExecutionStatus;

@interface ASFKThreadpoolSession : ASFKBase{
    @public     ASFKControlBlock* cblk;
    @protected ASFKExecutableRoutineSummary passSummary;
    @protected ASFKExecutableRoutineSummary expirationSummary;
    @protected ASFKCancellationRoutine cancellationHandler;
    @protected NSMutableArray<ASFKExecutableRoutine>* procs;
    @protected ASFKExpirationCondition* excond;
    @public    std::atomic<BOOL> isStopped;
    @public    std::atomic<BOOL> paused;
}
@property  ASFK_IDENTITY_TYPE sessionId;

-(ASFKControlBlock*) getControlBlock;
-(id)initWithSessionId:(ASFK_IDENTITY_TYPE)sessionId andSubsessionId:(ASFK_IDENTITY_TYPE)subId;
-(void) flush;
-(void) cancel;
-(void) postDataItemsAsArray:(NSArray*)array;
-(void) postDataItemsAsOrderedSet:(NSOrderedSet*)set;
-(void) postDataItemsAsUnorderedSet:(NSSet*)set;
-(void) postDataItemsAsDictionary:(NSDictionary*)dict;
-(void) postDataItem:(id)dataItem;
-(void) addRoutinesFromArray:(NSArray<ASFKExecutableRoutine>*)procs;
-(void) replaceRoutinesWithArray:(NSArray<ASFKExecutableRoutine>*)procs;
-(void) setProgressRoutine:(ASFKProgressRoutine)progress;
-(void) setSummary:(ASFKExecutableRoutineSummary)sum;
-(void) setExpirationSummary:(ASFKExecutableRoutineSummary)sum;
-(eASFKThreadpoolExecutionStatus) select:(long)selector routineCancel:(ASFKCancellationRoutine)cancel;
-(void) setCancellationHandler:(ASFKCancellationRoutine)cru;
-(void) setExpirationCondition:(ASFKExpirationCondition*) trop;
-(BOOL) hasSessionSummary;

-(BOOL) isBusy;

-(long) procsCount;
-(long) itemsCount;

@end

#import "ASFKFilter.h"
#import "ASFKFilteringQueue.h"
#import "ASFKMailbox.h"
#import "ASFKPipelinePar.h"



