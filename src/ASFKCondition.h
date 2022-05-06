//
//  ASFKCondition.h
//  Async
//
//  Created by bv on 19/12/2020.
//  Copyright © 2020 bv. All rights reserved.
//

#ifndef ASFKCondition_h
#define ASFKCondition_h
/*!
 @brief ---------------------
 @discussion The main purpose: provide concurrent execution of set of functions.
 For each function order of start and termination is undefined.
 After first N applications are complete the execution will end.
 */
@interface ASFKCondition : ASFKNonlinearFlow
#pragma mark - Deferred evaluation
-(ASFKExecutableProcedureConditional) storeCondition:(ASFKExecutableProcedureConditional)condProc;
-(ASFKExecutableProcedureConditionalBranch) storeThenBranch:(ASFKExecutableProcedureConditionalBranch)thenproc;
-(ASFKExecutableProcedureConditionalBranch) storeElseBranch:(ASFKExecutableProcedureConditionalBranch)elseproc;
-(BOOL) callEvaluateConditionWithParam:(id)param withSummary:(ASFKExecutableProcedureSummary)summary;
-(BOOL) castEvaluateConditionWithParam:(id)param withSummary:(ASFKExecutableProcedureSummary)summary;
-(BOOL) callEvaluateCondition:(ASFKExecutableProcedureConditional)cond withParam:(id)param withSummary:(ASFKExecutableProcedureSummary)summary;
-(BOOL) castEvaluateCondition:(ASFKExecutableProcedureConditional)cond withParam:(id)param withSummary:(ASFKExecutableProcedureSummary)summary;
#pragma mark - Immediate evaluation
-(void)callIfExists:(ASFKExecutableProcedureConditional)condProc withParam:(id)param thenDo:(ASFKExecutableProcedureConditionalBranch)thenProc thenParam:(id)thenParam elseDo:(ASFKExecutableProcedureConditionalBranch)elseProc elseParam:(id)elseParam;
-(void)castIfExists:(ASFKExecutableProcedureConditional)condProc withParam:(id)param thenDo:(ASFKExecutableProcedureConditionalBranch)thenProc thenParam:(id)thenParam elseDo:(ASFKExecutableProcedureConditionalBranch)elseProc elseParam:(id)elseParam;
-(void)callIfExistsWithParam:(id)param thenParam:(id)thenParam elseParam:(id)elseParam;
-(void)castIfExistsWithParam:(id)param thenParam:(id)thenParam elseParam:(id)elseParam;
-(void)callIfExists:(ASFKExecutableProcedureConditional)condProc withParam:(id)param thenParam:(id)thenParam elseParam:(id)elseParam;
-(void)castIfExists:(ASFKExecutableProcedureConditional)condProc withParam:(id)param thenParam:(id)thenParam elseParam:(id)elseParam;
@end

#endif /* ASFKCondition_h */
