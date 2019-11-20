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
//  Copyright © 2019 Boris Vigman. All rights reserved.
//

#import <Foundation/Foundation.h>
#define ASFK_GEN_KEY_SUMMARY @"summary"
#define ASFK_STATS_KEY_TIME_SESSIONS @"totalSessionsTime"
#define ASFK_STATS_KEY_TIME_PROCS @"totalProcsTime"
#define ASFK_STATS_KEY_COUNT_SESSIONS @"totalSessionsCount"
#define ASFK_STATS_KEY_COUNT_PROCS @"totalProcsCount"

#define ASFK_RETVALUE_RC @"asfk_ret_rc"
#define ASFK_RETVALUE_RESULT @"asfk_ret_result"
#define ASFK_RETVALUE_SUMRESULT @"asfk_ret_sumresult"
#define ASFK_RETVALUE_MAIL @"asfk_ret_mail"
#define ASFK_RETVALUE_NEXT_TARGET @"asfk_ret_nextTarget"
#define ASFK_RETVALUE_SESSION_ID @"asfk_ret_sessionId"
#define ASFK_RETVALUE_DESCRIPTION @"asfk_ret_description"
#define ASFK_RETVALUE_STATS_TIMESTAMP_START @"asfk_ret_stats_tm0"
#define ASFK_RETVALUE_STATS_TIMESTAMP_END @"asfk_ret_stats_tm1"
#define ASFK_RETVALUE_STATS_TIME_PROCS_ELAPSED_SEC @"asfk_ret_stats_procs_tesec"
#define ASFK_RETVALUE_STATS_TIME_SESSION_ELAPSED_SEC @"asfk_ret_stats_session_tesec"
#define ASFK_VERSION @"0.1.0"

@interface ASFKGlobalQueue : NSObject
+ (id)sharedManager;
-(void) takeCpu;
-(void) releaseCpu;
-(void) releaseSubmittedWithIdentity:(id)identity;
-(void) submitBlocks:(NSArray<dispatch_block_t>*)blarray summary:(void(^)(void))summary notificationGroup:(dispatch_group_t)group;
-(id) submitBlocks:(NSArray<dispatch_block_t>*)blarray summary:(id(^)(void))summary waitingGroup:(dispatch_group_t)group;
-(id) submitBlocks:(NSArray<dispatch_block_t>*)blarray summary:(void(^)(void))summary withIdentity:(id)identity QoS:(long)qos blocking:(BOOL)blocking;
-(void) submitCriticalSection:(void(^)(void))cs blocking:(BOOL)blocking;
@end

@interface ASFKBlocksContainer : NSObject
+(NSString*) ASFKVersion;
-(BOOL) hasInternalBlocks;
-(void) storeInternalBlock:(dispatch_block_t) b withId:(id)itsid;
-(void) storeExternalBlock:(dispatch_block_t) b;
-(void) removeInternalBlockById:(id)itsid ;
-(NSUInteger) removeAllInternalBlocks;
@end
@protocol ASFKRoutable
@required
-(BOOL) push:(id)item;
-(id) pull;
@end
@protocol ASFKControlCaller
@required
-(void) cancel;
-(BOOL) cancellationRequestedByCallback;
-(void) reset;
@end
@protocol ASFKControlCallback
@required
-(void) stop;
-(BOOL) cancellationRequestedByCaller;
-(NSString*)getCurrentSessionId;
@end
@interface ASFKControlBlock : NSObject<ASFKControlCaller,ASFKControlCallback>
@property NSString* sessionId;

@property (readonly) ASFKBlocksContainer* blkContainer;

-(BOOL) cancellationRequested;
-(void) terminate;
@end
/*!
 @param data an object to be stored for later use; this is non-mandatory data that is provided by application while executing the block but it comes in addition to block's return value (existing or not).
 */
typedef id ( ^ASFKMailboxPostProcedure)(id data);

@interface ASFKExeContext:NSObject
@property (nonatomic) id pid;
@property (nonatomic) id sessionid;
@property (nonatomic) id currentKey;
@property (nonatomic) long long currentIndex ;
@property (nonatomic) long long sequenceNumber;
@property (nonatomic) ASFKMailboxPostProcedure post;
@end

typedef void(^ASFKDefaultBlockType)(void);

typedef id ( ^ASFKExecutableProcedure)(id<ASFKControlCallback> controlData,ASFKExeContext* context, id data);

/**
 @param controlData object controlling the execution
 @param index positive number of current iteration
 @param condParam parameter used for condition evaluation
 @param bodyParam parameter used for body execution
 @param lastResult object produced by previous iteration
 */
typedef id ( ^ASFKExecutableProcedureConditionalBody)(id<ASFKControlCallback> controlData,long long index, id condParam,id bodyParam, id lastResult);
/**
 @param controlData object controlling the execution.
 @param index positive number of current iteration.
 @param outStop variable that should be set to YES if the user want to terminate this loop execution.
 @param condParam parameter used for condition evaluation.
 @param bodyParam parameter used for body execution.
 @param lastResult object produced by previous iteration.
 */
typedef id ( ^ASFKExecutableProcedureConditionalBodyStoppable)(id<ASFKControlCallback> controlData,long long index, BOOL* outStop,id condParam,id bodyParam, id lastResult);
/**
 @param controlData object controlling the execution.
 @param condParam data needed to evaluate the condition.
 @param branchParam data needed to evaluate the branch.
 */
typedef id ( ^ASFKExecutableProcedureConditionalBranch)(id<ASFKControlCallback> controlData,id condParam, id branchParam);

/**
 @param controlData object controlling the execution
 @param param data needed to evaluate the condition
 @return result of evaluation
 */
typedef BOOL  ( ^ASFKExecutableProcedureConditional)(id<ASFKControlCallback> controlData,id param);
/**
 @param controlData object controlling the execution
 @param iteration positive number of current iteration
 @param param evaluation param
 @return result of evaluation
 */
typedef BOOL  ( ^ASFKExecutableProcedureLoopConditional)(id<ASFKControlCallback> controlData,long long iteration,id param);
/**
 A summary function which is called after all blocks ended their runs.
 @param controlData object controlling the execution
 @param stats dictionary contining statistics about terminated executions
 @param data input data which is usually collection of runs' results.
 @return arbitrary data object
 */
typedef id ( ^ASFKExecutableProcedureSummary)(id<ASFKControlCallback> controlData,NSDictionary* stats,id data);

@protocol ASFKLinkable
@required
-(id) runWithData:(id)data blocking:(BOOL)blk;
- (NSDictionary*)stepWithData:(id)data ;
-(BOOL) detachAllTargets;
-(BOOL) detachAllSources;
-(BOOL) attachTarget:(id<ASFKLinkable>)target withId:(id)identity blocking:(BOOL)blocking;
-(BOOL) detachTargetWithId:(id)identity;
-(BOOL) attachSource:(id<ASFKLinkable>)target withId:(id)identity withBlockingTarget:(BOOL)blocking;
-(BOOL) detachSourceWithId:(id)identity;
-(NSDictionary*) stepNonblockingWithData:(id)data;
-(NSDictionary*) stepBlockingWithData:(id)data;
@end

@interface ASFKBase : NSObject<ASFKLinkable>{
@protected NSLock* lkNonLocal;
@protected NSMutableDictionary* sessions;
@protected double totalProcs;
@protected double totalProcsTime;
@protected double totalSessions;
@protected double totalSessionsTime;
@protected NSMutableDictionary* priv_statistics;
@protected dispatch_semaphore_t semHighLevelCall;
}

@property (readonly) id itsIdentity;
@property (readonly) double totalTimeSeconds;
@property (readonly) long long totalServedRequestsCount;
@property (readonly) NSDictionary* sources;
@property (readonly) NSDictionary* targets;
@property long QosClass;
-(id)initWithId:(id)identity;
-(id)ASFKVersion;
-(NSDictionary*)getStatistics;
-(BOOL) deleteProcedures;
-(void) cancelAll;
-(void) cancelSession:(NSString*)sessionId;

-(BOOL) isBusy;

@end

@interface ASFKQueue : ASFKBase<ASFKLinkable,ASFKRoutable>{
@protected NSLock* lock;
@protected NSMutableArray* q;
}
-(void) reset;
-(long long )count;
-(BOOL) isEmpty;
@end

@interface ASFKInternalQueue:ASFKQueue
-(id)pullAndOccupyWithId:(long)itsid;
-(void)unoccupyWithId:(long)itsid;
-(void)unoccupy;
@end

@interface ASFKNonlinearFlow : ASFKBase<ASFKLinkable>
-(BOOL) attachTrueTarget:(id<ASFKLinkable>)target withId:(id)identity;

-(BOOL) attachFalseTarget:(id<ASFKLinkable>)target withId:(id)identity;

-(BOOL) detachTrueTargetWithId:(id)identity;
-(BOOL) detachFalseTargetWithId:(id)identity;
@end

@interface ASFKLinearFlow : ASFKBase<ASFKLinkable>{
@protected
    ASFKExecutableProcedureSummary _sumproc;
    NSMutableArray<ASFKExecutableProcedure> * _backprocs;
}
@property (readonly) NSArray<ASFKExecutableProcedure> *procs;

@property (readonly) ASFKExecutableProcedureSummary sumproc;

/**
 @brief Stores block which invokes Objective-C code; the block is added to internal collection. This operation may succeed only if no procedure is active at time of addition.
 @param proc block that processes a data.
 */
-(BOOL) addProcedure:(ASFKExecutableProcedure)proc;
/**
 @brief Stores array of procedures for later use; content of array is copied and added to internal collection.
 This operation may succeed only if no procedure is active at time of addition.
 @param procs new array of procedures.
 @return YES if operation succeeded; NO otherwise;
 */
-(BOOL) addProcedures:(NSArray<ASFKExecutableProcedure>*)procs;
/**
 @brief Replaces existing collection of procedures with new one. This operation may succeed only if no procedure is active at time of addition.
 @param procs new array of procedures. If aray is empty or nil, nothing happens.
 @return YES if operation succeeded; NO otherwise.
 */
-(BOOL) replaceProceduresFromArray:(NSArray<ASFKExecutableProcedure>*)procs;

/**
 @brief Stores summary block which invokes Objective-C code
 @param summary block that is alled after all procedures.
 */
-(BOOL) storeSummary:(ASFKExecutableProcedureSummary)summary;


/**
 @brief Performs blocking call with array of data and invokes stored Summary block.
 @param array array of data for processing.
 @return dictionary that includes result of execution followed by additional information.
 */
-(NSDictionary*) callArray:(NSArray*)array ;
/**
 @brief Performs blocking function call with array of data and invokes provided Summary block with result.
 @param array array of data for processing.
 @param summary block that receives result of application.
 @return dictionary that includes result of execution followed by additional information.
 */
-(NSDictionary*) callArray:(NSArray*)array withSummary:(ASFKExecutableProcedureSummary)summary;
/**
 @brief Performs blocking function call with on array of data and invokes provided Summary block with result.
 @param array array of data for processing.
 @param procs array of provided blocks.
 @return dictionary that includes result of execution followed by additional information.
 */
-(NSDictionary*) callArray:(NSArray*)array withProcedures:(NSArray<ASFKExecutableProcedure>*) procs;
/**
 @brief Performs blocking call with array of data and invokes provided Summary block with result.
 @param array array of data for processing.
 @param procs array of provided blocks.
 @param summary block that receives result after all blocks ended their executions.
 @return dictionary that includes result of execution followed by additional information.
 */
-(NSDictionary*) callArray:(NSArray*)array withProcedures:(NSArray<ASFKExecutableProcedure>*) procs withSummary:(ASFKExecutableProcedureSummary)summary;
/**
 @brief Performs blocking call with dictionary of data and invokes stored Summary block with result.
 @param dictionary dictionary of data.
 @return dictionary that includes result of execution followed by additional information.
 */
-(NSDictionary*) callDictionary:(NSDictionary*)dictionary;
/**
 @brief Applies user-provided procedures synchronously on dictionary of data and invokes stored Summary block with result.
 @param dictionary dictionary of data.
 @param procs user-provided array of procedures.
 @return dictionary that includes result of execution followed by additional information.
 */
-(NSDictionary*) callDictionary:(NSDictionary*)dictionary withProcedures:(NSArray<ASFKExecutableProcedure>*) procs;
/**
 @brief Applies stored procedures on dictionary synchronously of data and invokes user-provided Summary block with result.
 @param dictionary dictionary of data.
 @param summary block that receives result after all blocks ended their executions.
 @return dictionary that includes result of execution followed by additional information.
 */
-(NSDictionary*) callDictionary:(NSDictionary*)dictionary withSummary:(ASFKExecutableProcedureSummary)summary;
/**
 @brief Applies user-provided procedures synchronously on dictionary of data and invokes user-provided Summary block with result.
 @param dictionary dictionary of data.
 @param procs user-provided array of procedures.
 @param summary block that receives result after all blocks ended their executions.
 @return dictionary that includes result of execution followed by additional information.
 */
-(NSDictionary*) callDictionary:(NSDictionary*)dictionary withProcedures:(NSArray<ASFKExecutableProcedure>*) procs withSummary:(ASFKExecutableProcedureSummary)summary;
/*!
 @brief Performs blocking call with dictionary of data and invokes stored Summary block with result.
 @param uns unspecified piece of data.
 @return dictionary that includes result of execution followed by additional information.
 */
-(NSDictionary*) callUnspecified:(id)uns;
/*!
 @brief Performs non-blocking call with dictionary of data and invokes provided Summary block with result.
 @param uns unspecified piece of data.
 @param summary the sumamry block.
 @return dictionary that includes result of execution followed by additional information.
 */
-(NSDictionary*) callUnspecified:(id)uns withSummary:(ASFKExecutableProcedureSummary)summary;
/*!
 @brief Performs non-blocking call with dictionary of data and invokes provided Summary block with result.
 @param uns unspecified piece of data.
 @param procs the array of procedures.
 @return dictionary that includes result of execution followed by additional information.
 */
-(NSDictionary*) callUnspecified:(NSDictionary*)uns withProcedures:(NSArray<ASFKExecutableProcedure>*) procs;
/*!
 @brief Performs non-blocking call with dictionary of data and invokes provided Summary block with result.
 @param uns unspecified piece of data.
 @param procs the array of procedures.
 @param summary the summary block.
 @return dictionary that includes result of execution followed by additional information.
 */
-(NSDictionary*) callUnspecified:(id)uns withProcedures:(NSArray<ASFKExecutableProcedure>*) procs withSummary:(ASFKExecutableProcedureSummary)summary;

/*!
 @brief Performs non-blocking call with on array of data and invokes stored Summary block with result.
 @param array array of data for processing.
 @return dictionary that includes result of execution followed by additional information.
 */
-(NSDictionary*) castArray:(NSArray*)array ;
/*!
 @brief Performs non-blocking call with array of data and invokes provided Summary block with result.
 @param array array of data for processing.
 @param summary block that receives result of application.
 @return dictionary that includes result of execution followed by additional information.
 */
-(NSDictionary*) castArray:(NSArray*)array withSummary:(ASFKExecutableProcedureSummary)summary;
/*!
 @brief Performs non-blocking call with array of data and invokes provided Summary block with result.
 @param array array of data for processing.
 @param procs array of provided blocks.
 @return dictionary that includes result of execution followed by additional information.
 */
-(NSDictionary*) castArray:(NSArray*)array withProcedures:(NSArray<ASFKExecutableProcedure>*) procs;
/*!
 @brief Performs non-blocking call with array of data and invokes provided Summary block with result.
 @param array array of data for processing.
 @param procs array of provided blocks.
 @param summary block that receives result after all blocks ended their executions.
 @return dictionary that includes result of execution followed by additional information.
 */
-(NSDictionary*) castArray:(NSArray*)array withProcedures:(NSArray<ASFKExecutableProcedure>*) procs withSummary:(ASFKExecutableProcedureSummary)summary;
/*!
 @brief Performs non-blocking call with dictionary of data and invokes stored Summary block with result.
 @param dictionary dictionary of data.
 @return dictionary that includes result of execution followed by additional information.
 */
-(NSDictionary*) castDictionary:(NSDictionary*)dictionary;
/*!
 Applies user-provided asynchronously procedures on dictionary of data and invokes stored Summary block with result.
 @param dictionary dictionary of data.
 @param procs user-provided array of procedures.
 @return dictionary that includes result of execution followed by additional information.
 */
-(NSDictionary*) castDictionary:(NSDictionary*)dictionary withProcedures:(NSArray<ASFKExecutableProcedure>*) procs;
/*!
 @brief Performs non-blocking call with dictionary of data and invokes user-provided Summary block with result.
 @param dictionary dictionary of data.
 @param summary block that receives result after all blocks ended their executions.
 @return dictionary that includes result of execution followed by additional information.
 */
-(NSDictionary*) castDictionary:(NSDictionary*)dictionary withSummary:(ASFKExecutableProcedureSummary)summary;
/*!
 Performs non-blocking call with dictionary of data and invokes user-provided Summary block with result.
 @param dictionary dictionary of data.
 @param procs user-provided array of procedures.
 @param summary block that receives result after all blocks ended their executions.
 @return dictionary that includes result of execution followed by additional information.
 */
-(NSDictionary*) castDictionary:(NSDictionary*)dictionary withProcedures:(NSArray<ASFKExecutableProcedure>*) procs withSummary:(ASFKExecutableProcedureSummary)summary;
/*!
 @brief Performs non-blocking call with dictionary of data and invokes stored Summary block with result.
 @param uns unspecified piece of data.
 @return dictionary that includes result of execution followed by additional information.
 */
-(NSDictionary*) castUnspecified:(id)uns;
/*!
 @brief Performs non-blocking call with dictionary of data and invokes provided Summary block with result.
 @param uns unspecified piece of data.
 @param summary block that receives result after all blocks ended their executions.
 @return dictionary that includes result of execution followed by additional information.
 */
-(NSDictionary*) castUnspecified:(id)uns withSummary:(ASFKExecutableProcedureSummary)summary;
//-(NSDictionary*) castUnspecified:(NSDictionary*)uns withProcedures:(NSArray<ASFKExecutableProcedure>*) procs;

/*!
 @brief Performs non-blocking call with unspecified data (i.e. not Array or Dictionary) and invokes user-provided Summary block with result.
 @param uns unspecified data piece.
 @param procs user-provided array of procedures.
 @param summary block that receives result after all blocks ended their executions.
 @return dictionary that includes result of execution followed by additional information.
 */
-(NSDictionary*) castUnspecified:(id)uns withProcedures:(NSArray<ASFKExecutableProcedure>*) procs withSummary:(ASFKExecutableProcedureSummary)summary;
@end

/*!
 @see ASFKLinearFlow
 @brief This class provides pipelined execution's functionality. For N procedures it takes procedure P0 and applies it to item D0. Upon completion P0 is applied to D1 while P1 is concurrently applied to D0 and so on.
 */
@interface ASFKPipelinePar : ASFKLinearFlow
/*!
 @brief sets maximum number of concurrent threads. The number must be in range [1..[[NSProcessInfo processInfo] activeProcessorCount] ]. By default 1 is set.
 */
@property (readwrite) long threadsLimit;
/*!
 @brief Equals NO if is execution has ended; YES otherwise.
 */
-(BOOL) isActive;
/*!
 @brief restarts pipeline after the execution was canceled.
 */
-(void)restart;
/*!
 @brief flushes all queued items.
 */
-(void)flush;
/*!
 @brief sets new class of QoS (i.e. thread priority).
 @param newqos required class of Quality of Service . Allowed values are:QOS_CLASS_USER_INTERACTIVE, QOS_CLASS_UTILITY, QOS_CLASS_BACKGROUND. By default QOS_CLASS_BACKGROUND is set. The parameter will be in effect after restart.
 */
-(void) setQualityOfService:(long)newqos;
-(NSDictionary*) castArray:(NSArray *)array forSession:(id)sessionId;
-(BOOL) addProcedures:(NSArray<ASFKExecutableProcedure>*)procs forSession:(id)sessionId;
-(BOOL) replaceProceduresFromArray:(NSArray<ASFKExecutableProcedure>*)procs forSession:(id)sessionId;
@end
@interface ASFKPipelineSeq : ASFKLinearFlow

@end

/*!
 @see ASFKLinearFlow
 @brief Composition with sequential flavor.
 The main purpose: provide sequential execution of number of procedures upon the given data item(s).
 For sequence of procedures next procedure will start strictly after the previous procedure ended execution while using as input the result of previous procedure.
 More formal description: being provided with set of functions F0...Fn, this object invokes them as Fn(Fn-1(...(F0(param))...).
 When more than 1 data item supplied then all items will be composed sequentially, i.e. Fn(Fn-1(...(F0(param1))...) will be followed by Fn(Fn-1(...(F0(param_2))...) ... followed by  Fn(Fn-1(...(F0(param_m))...).
 When all executions ended the summary function will be called
 */
@interface ASFKComposeSeq : ASFKLinearFlow

@end

/*!
 @see ASFKBase
 @brief Composition with concurrent flavor.
 The main purpose: provide concurrent execution of number of procedures upon the given data item(s).
 For sequence of procedures next procedure will start strictly after the previous procedure ended execution while using as input the result of previous procedure.
 More formal description: being provided with set of functions F0...Fn, this object invokes them as Fn(Fn-1(...(F0(param))).
 When more than 1 data item supplied then all items will be composed concurrently, i.e. Fn(Fn-1(...(F0(param1))...) concurrently with Fn(Fn-1(...(F0(param_2))...) ... concurrently with Fn(Fn-1(...(F0(param_m))...).
 When all executions ended the summary function will be called
 */
@interface ASFKComposePar : ASFKLinearFlow

@end
/*!
 @name ASFKMapBase
 @see ASFKLinearFlow
 @brief maps a given data set to another data set.
 The main purpose: provide parallel mapping of of given data set into another.
 More formal description: being provided with function F and data set D0...Dn, this object invokes them as F(D0)->D`0 ... F(Dn)->D`n and the result is in D`n.
 The order of executions is undefined.
 When all executions ended then summary procedure is invoked.
 */
@interface ASFKMapPar :ASFKLinearFlow


@end

/*!
 @name ASFKMapSeq
 @see ASFKLinearFlow
 @brief maps a given daat set to another data set.
 The main purpose: provide sequential mapping of of given data set into another.
 More formal description: being provided with function F and data set D0...Dn, this object invokes them as F(D0)->D`0 ... F(Dn)->D`n and the result is in D`n.
 The order of executions is defined such that any next mapping takes place strictly after the prevoius mapping has ended.
 When all executions ended then summary procedure is invoked.
 */
@interface ASFKMapSeq : ASFKLinearFlow


@end
/*!
 @interface ASFKRacePar
 @brief Applies provided procedure to provided collection of parameters concurrently.
 The main purpose: provide concurrent execution of set of procedures.
 For each procedure order of start and termination is undefined.
 After the first N procedure are complete the execution will end, rest of procedures will be cancelled.
 */
@interface ASFKRacePar : ASFKLinearFlow
@property (readonly) NSDictionary* namedProcs;
/*!
 @brief initializer
 @param limit number showing how much concurrent procedures will be completed before the execution stops. Default 1. Rest of procedures will be cancelled and their results ignored. if zero, no procedure will be launched
 @param identity uinque identifier for this object; if nil then default value is generated.
 */
-(id)initWithLimit:(NSUInteger)limit identity:(id)identity;
/*!
 @brief stores provided procedure with unique identifier;
 @param proc procedure
 @param identity uinque identifier for this object; if nil then default value is generated.
 */
-(BOOL) addNamedProcedure:(ASFKExecutableProcedure) proc withId:(id)identity;
/*!
 @brief stores array of procedures; each procedures is saved with generated identifier which is integer nonnegative  number.
 @param procs collection of procedures
 */
-(BOOL) addNamedProceduresFromArray:(NSArray<ASFKExecutableProcedure>*)procs;
/*!
 @brief replaces stored array of procedures with new one; each new procedure is saved with generated identifier which is integer nonnegative  number.
 @param procs collection of procedures
 */
-(BOOL) replaceNamedProceduresFromArray:(NSArray<ASFKExecutableProcedure>*)procs;
/*!
 @brief adds procedures from dictionary with their keys.
 @param procs collection of procedures
 */
-(BOOL) addNamedProceduresFromDictionary:(NSDictionary<id,ASFKExecutableProcedure>*)procs ;
/*!
 @brief replaces procedures from dictionary with their keys.
 @param procs collection of procedures
 */
-(BOOL) replaceNamedProceduresFromDictionary:(NSDictionary<id,ASFKExecutableProcedure>*)procs ;
/*!
 Performs blocking function call on dictionary of data and invokes user-provided Summary block with result. It is important for caller to guarantee that number of data items is less than or equal to the number of procedures and each for each data item there is procedure with matching key.
 @param dictionary dictionary of data.
 @param procs user-provided dictionary of procedures.
 @param summary block that receives result after all blocks ended their executions.
 @return dictionary that includes result of execution followed by additional information.
 */
-(NSDictionary*) callDictionary:(NSDictionary*)dictionary withNamedProcedures:(NSDictionary*) procs withSummary:(ASFKExecutableProcedureSummary)summary;
/*!
 Performs blocking function call with stored procedures on dictionary of data and invokes stored Summary block with result. It is important for caller to guarantee that number of data items is less than or equal to the number of procedures and each for each data item there is procedure with matching key.
 @param dictionary dictionary of data.
 @return dictionary that includes result of execution followed by additional information.
 */
-(NSDictionary*) callDictionary:(NSDictionary*)dictionary;
/*!
 Performs blocking function call with provided procedures on dictionary of data and invokes stored Summary block with result. It is important for caller to guarantee that number of data items is less than or equal to the number of procedures and each for each data item there is procedure with matching key.
 @param dictionary dictionary of data.
 @param procs user-provided dictionary of procedures.
 @return dictionary that includes result of execution followed by additional information.
 */
-(NSDictionary*) callDictionary:(NSDictionary*)dictionary withProcedures:(NSArray<ASFKExecutableProcedure>*) procs;
/*!
 Performs blocking function call with stored procedures on dictionary of data and invokes provided Summary block with result. It is important for caller to guarantee that number of data items is less than or equal to the number of procedures and each for each data item there is procedure with matching key.
 @param dictionary dictionary of data.
 @param summary block that receives result after all blocks ended their executions.
 @return dictionary that includes result of execution followed by additional information.
 */
-(NSDictionary*) callDictionary:(NSDictionary*)dictionary withSummary:(ASFKExecutableProcedureSummary)summary;
/*!
 Performs blocking function call with stored procedures on dictionary of data and invokes stored Summary block with result. It is important for caller to guarantee that number of data items is less than or equal to the number of procedures and each for each data item there is procedure with matching key.
 @param dictionary dictionary of data.
 @param procs user-provided array of procedures. Array items are converted to dicitonary while consecutive nonnegative integer numbers serve as keys.
 @param summary block that receives result after all blocks ended their executions.
 @return dictionary that includes result of execution followed by additional information.
 */
-(NSDictionary*) callDictionary:(NSDictionary*)dictionary withProcedures:(NSArray<ASFKExecutableProcedure>*) procs withSummary:(ASFKExecutableProcedureSummary)summary;
/**
 Performs non-blocking function call on dictionary of data and invokes user-provided Summary block with result. It is important for caller to guarantee that number of data items is less than or equal to the number of procedures and each for each data item there is procedure with matching key.
 @param dictionary dictionary of data.
 @param procs user-provided dictionary of procedures.
 @param summary block that receives result after all blocks ended their executions.
 @return dictionary that includes result of execution followed by additional information.
 */
-(NSDictionary*) castDictionary:(NSDictionary*)dictionary withNamedProcedures:(NSDictionary*) procs withSummary:(ASFKExecutableProcedureSummary)summary;
@end
