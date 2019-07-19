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
#import "ASFKControlBlock.h"

#define MAXIMAL_SYNC_QUEUES 4
@interface ASFKControlBlock : NSObject
@property BOOL shouldStop;
-(void) enter;
-(void) leave;
-(void) requestCancellation;
-(BOOL) cancellationRequested;
-(BOOL) isBusy;

@end
typedef void(^ASFKDefaultBlockType)(void);
typedef void* ( ^ASFKExecutableProcedureCStyle)(ASFKControlBlock* controlData,void* data);
typedef id ( ^ASFKExecutableProcedure)(ASFKControlBlock* controlData,id key, long long index, id data);
typedef BOOL  ( ^ASFKExecutableProcedureConditionalCStyle)(ASFKControlBlock* controlData,void* data);
typedef BOOL  ( ^ASFKExecutableProcedureConditional)(ASFKControlBlock* controlData,id data);

typedef NSArray* ( ^ASFKExecutableProcedureWithArray)(ASFKControlBlock* controlData,NSArray* array);

typedef NSDictionary* ( ^ASFKExecutableProcedureWithDictionary)(ASFKControlBlock* controlData,NSDictionary* dict);

typedef void* ( ^ASFKExecutableProcedureSummaryCStyle)(ASFKControlBlock* controlData,void* data);
typedef id ( ^ASFKExecutableProcedureSummary)(ASFKControlBlock* controlData,id data);

@interface ASFKBase : NSObject
@property (readonly) ASFKControlBlock* controlData;

-(NSString*) generateIdentity;
-(NSString*) generateRandomString;
-(NSNumber*) generateRandomNumber;

-(BOOL) restart;
-(BOOL) deleteProcedures;
-(void) cancel;
-(BOOL) isBusy;

@end

@protocol ASFKApplicative <NSObject>
@required
-(void) storeParamAsUnspecified:(id)data;
-(void) storeParamAsUnspecifiedCStyle:(void*)data;
@end

@protocol ASFKComposable
@required
-(void) execWithParam:(id)param;
-(void) execWithParamCStyle:(void*)param;
@end

@interface ASFKForkable : ASFKBase<ASFKComposable>

@end

@interface ASFKNonForkable : ASFKBase<ASFKComposable>
@property (readonly) NSMutableArray<ASFKExecutableProcedure> *procs;
@property (readonly) NSMutableArray *cprocs;
@property (readonly) ASFKExecutableProcedureSummary sumproc;
@property (readonly) ASFKExecutableProcedureSummaryCStyle csumcproc;
@property (atomic,readwrite) BOOL enabledCStyle;
@property (atomic,readwrite) BOOL enabledNonBlockingExecution;

/**
 Stores block which invokes Objective-C code
 @param proc block that processes a data.
 */
-(void) storeProcedure:(ASFKExecutableProcedure)proc;
/**
 Stores block which invokes C function(s)
 @param proc block that processes a data.
 */
-(void) storeProcedureC:(ASFKExecutableProcedureCStyle)proc;
-(void) storeSummary:(ASFKExecutableProcedureSummary)summary;
-(void) storeSummaryC:(ASFKExecutableProcedureSummaryCStyle)summary;

-(void) storeProcedures:(NSArray<ASFKExecutableProcedure>*)procs;
-(void) storeProceduresC:(NSArray*)cprocs;

/**
Applies stored procedures on array of data and invokes stored Summary block with result.
 @param array array of data for processing.
 @return array of input of data
 */
-(NSArray*) runOnArray:(NSArray*)array ;
/**
 Applies stored procedures on array of data and invokes provided Summary block with result.
 @param array array of data for processing.
 @param summary block that receives result of application.
 @return array of input data
 */
-(NSArray*) runOnArray:(NSArray*)array withSummary:(ASFKExecutableProcedureSummary)summary;
/**
 Applies stored procedures on array of data and invokes provided Summary block with result.
 @param array array of data for processing.
 @param procs array of provided blocks.
 @return array of data
 */
-(NSArray*) runOnArray:(NSArray*)array withProcedures:(NSArray<ASFKExecutableProcedure>*) procs;
/**
 Applies stored procedures on array of data and invokes provided Summary block with result.
 @param array array of data for processing.
 @param procs array of provided blocks.
 @param summary block that receives result after all blocks ended their executions.
 @return array of data
 */
-(NSArray*) runOnArray:(NSArray*)array withProcedures:(NSArray<ASFKExecutableProcedure>*) procs withSummary:(ASFKExecutableProcedureSummary)summary;
/**
 Applies stored procedures on dictionary of data and invokes stored Summary block with result.
 @param dictionary dictionary of data.
 @return dictionary of data
 */
-(NSDictionary*) runOnDictionary:(NSDictionary*)dictionary;
-(NSDictionary*) runOnDictionary:(NSDictionary*)dictionary withProcedures:(NSArray<ASFKExecutableProcedure>*) procs;
-(NSDictionary*) runOnDictionary:(NSDictionary*)dictionary withSummary:(ASFKExecutableProcedureSummary)summary;
-(NSDictionary*) runOnDictionary:(NSDictionary*)dictionary withProcedures:(NSArray<ASFKExecutableProcedure>*) procs withSummary:(ASFKExecutableProcedureSummary)summary;

-(id) runOnUnspecified:(id)uns;
-(id) runOnUnspecified:(id)uns withSummary:(ASFKExecutableProcedureSummary)summary;
-(id) runOnUnspecified:(NSDictionary*)uns withProcedures:(NSArray<ASFKExecutableProcedure>*) procs;
-(id) runOnUnspecified:(id)uns withProcedures:(NSArray<ASFKExecutableProcedure>*) procs withSummary:(ASFKExecutableProcedureSummary)summary;

-(void*) runOnUnspecifiedC:(void*)uns withSummary:(ASFKExecutableProcedureSummaryCStyle)summary;

@end
