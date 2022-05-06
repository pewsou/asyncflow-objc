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
#ifndef ASFKLinearFlow_h
#define ASFKLinearFlow_h

@protocol ASFKSynchronous
@required
/**
 @brief Performs blocking call with array of data and invokes stored Summary block.
 @param array array of data for processing.
 @return dictionary that includes result of execution followed by additional information.
 */
-(NSDictionary*) callArray:(NSArray*)array session:(id)sessionId execParams:(ASFKExecutionParams*)params;

/**
 @brief Performs blocking call with dictionary of data and invokes stored Summary block with result.
 @param dictionary dictionary of data.
 @return dictionary that includes result of execution followed by additional information.
 */
-(NSDictionary*) callDictionary:(NSDictionary*)dictionary session:(id)sessionId exParam:(NSDictionary*)ex;
/**
 @brief Performs blocking call with ordered set of data and invokes stored Summary block with result.
 @param set ordered set of data.
 @return dictionary that includes result of execution followed by additional information.
 */
-(NSDictionary*) callOrderedSet:(NSOrderedSet*)set session:(id)sessionId exParam:(NSDictionary*)ex;

/**
 @brief Performs blocking call with unordered of data and invokes stored Summary block with result.
 @param set unordered set of data.
 @return dictionary that includes result of execution followed by additional information.
 */
-(NSDictionary*) callUnorderedSet:(NSSet*)set session:(id)sessionId exParam:(NSDictionary*)ex;
/*!
 @brief Performs blocking call with dictionary of data and invokes stored Summary block with result.
 @param uns unspecified piece of data.
 @return dictionary that includes result of execution followed by additional information.
 */
-(NSDictionary*) callObject:(id)uns session:(id)sessionId exParam:(NSDictionary*)ex;

@end
@protocol ASFKAsynchronous
@required
/*!
 @brief Performs non-blocking call with on array of data and invokes stored Summary block with result.
 @param array array of data for processing.
 @return dictionary that includes result of execution followed by additional information.
 */
-(NSDictionary*) castArray:(NSArray*)array session:(id)sessionId exParam:(ASFKExecutionParams*)ex;

/*!
 @brief Performs non-blocking call with dictionary of data and invokes stored Summary block with result.
 @param dictionary dictionary of data.
 @return dictionary that includes result of execution followed by additional information.
 */
-(NSDictionary*) castDictionary:(NSDictionary*)dictionary session:(id)sessionId exParam:(ASFKExecutionParams*)ex;

/*!
 @brief Performs non-blocking call with ordered set of data and invokes stored Summary block with result.
 @param set ordered set of data.
 @return dictionary that includes result of execution followed by additional information.
 */
-(NSDictionary*) castOrderedSet:(NSOrderedSet*)set session:(id)sessionId exParam:(ASFKExecutionParams*)ex;
/*!
 @brief Performs non-blocking call with unordered set of data and invokes stored Summary block with result.
 @param set unordered set of data.
 @return dictionary that includes result of execution followed by additional information.
 */
-(NSDictionary*) castUnorderedSet:(NSSet*)set session:(id)sessionId exParam:(ASFKExecutionParams*)ex;
/*!
 @brief Performs non-blocking call with dictionary of data and invokes stored Summary block with result.
 @param uns unspecified piece of data.
 @return dictionary that includes result of execution followed by additional information.
 */
-(NSDictionary*) castObject:(id)uns session:(id)sessionId exParam:(ASFKExecutionParams*)ex;
@end

@interface ASFKLinearFlow : ASFKBase<ASFKRoutable,ASFKLinkable,ASFKSynchronous,ASFKAsynchronous>{
@protected
    NSMutableArray<ASFKExecutableRoutine> * _backprocs;
    NSArray<ASFKExecutableRoutine> *lfProcs;
    ASFKCancellationRoutine cancelproc;
    ASFKExecutableRoutineSummary sumproc;
}
-(NSArray<ASFKExecutableRoutine> *) getRoutines;
-(NSUInteger) getRoutinesCount;
-(ASFKExecutableRoutineSummary) getSummaryRoutine;
-(ASFKCancellationRoutine) getCancellationHandler;

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
-(BOOL) setRoutinesFromArray:(NSArray<ASFKExecutableRoutine>*)procs;

/**
 @brief Stores summary block which invokes Objective-C code
 @param summary block that is called after all Routines.
 */
-(BOOL) setSummary:(ASFKExecutableRoutineSummary)summary;
/**
 @brief Stores block which invokes Objective-C code as a summary for cancelled session.
 @param ch block that is called in case of cancellation.
 */
-(BOOL) setCancellationHandler:(ASFKCancellationRoutine)ch;

@end
#endif /* ASFKLinearFlow_h */
