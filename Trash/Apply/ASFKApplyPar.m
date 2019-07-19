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
//  Created by Boris Vigman on 23/02/2019.
//  Copyright © 2019 Boris Vigman. All rights reserved.
//

#import "ASFKApplyPar.h"
#import "ASFKControlBlock+Private.h"

@interface ASFKApplyPar ()
@property void* dataVoid;
@property id dataId;
@property dispatch_queue_t parQ;
@end
@implementation ASFKApplyPar
-(id) init{
    self=[super init];
    {
        NSString* rand=[[self generateRandomNumber]stringValue];
        self.parQ = dispatch_queue_create([[@"com.apply.par.Q1." stringByAppendingString:rand]cStringUsingEncoding:NSASCIIStringEncoding], DISPATCH_QUEUE_CONCURRENT);
        self.dataVoid=0;
        self.dataId=nil;
        
    }
    return self;
}

-(void) runProcedure:(ASFKExecutableProcedure)proc onData:(id)data withSummary:(ASFKExecutableProcedureSummary)summary{
    if(self.controlData.cancellationRequested==YES){
        return;
    }
    if(proc){
        dispatch_async(self.parQ, ^{
            id result=proc(self.controlData,data);
            if(summary){
                summary(self.controlData,result);
            }else{
                NSLog(@"ApplyPar: summary block was not invoked");
            }
        }) ;
    }
}
-(void) runProcedureC:(ASFKExecutableProcedureCStyle)proc onData:(void*)data withSummary:(ASFKExecutableProcedureSummaryCStyle)summary{
    if(self.controlData.cancellationRequested==YES){
        return;
    }
    if(proc){
        dispatch_async(self.parQ, ^{
            void* result=proc(self.controlData,data);
            if(summary){
                summary(self.controlData,result);
            }else{
                NSLog(@"ApplyPar: summary block was not invoked");
            }
        }) ;
    }
}

-(void) runProcedure:(ASFKExecutableProcedure)proc onArray:(NSArray*)data withSummary:(ASFKExecutableProcedureSummary)summary{
    if(self.controlData.cancellationRequested==YES){
        return;
    }
    for(id elem in data){
        self.eproc(self.controlData,elem);
    }
}
-(void) runProcedure:(ASFKExecutableProcedure)proc onDictionary:(NSDictionary*)data withSummary:(ASFKExecutableProcedureSummary)summary{
    if (data!=nil){
        for(id key in data){
            if(self.controlData.cancellationRequested==YES){
                return;
            }
            dispatch_async(self.parQ, ^{
                id result=proc(self.controlData,[data objectForKey:key]);
            });
            //[self.rpar runStoredBlocksWithParams:(__bridge void *)(item) withSummary: summary];
            //self.exec(self.controlData,);
        }
        dispatch_barrier_async(self.parQ, ^{
            if(summary){
                //summary(self.controlData,result);
            }else{
                NSLog(@"ApplyPar: summary block was not invoked");
            }
        });
    }else{
        NSLog(@"Sync Application failed, source array is nil");
    }
}

//-(void) applyToArray:(NSArray*)array withSummary:(ASFKExecutableBlockSummary)summary{
//    for(id key in dictionary){
//
//    }
//}
//-(void) applyToDictionary:(NSDictionary*)dictionary withSummary:(ASFKExecutableBlockSummary)summary{
//    if(dictionary&&summary){
//        for(id key in dictionary){
//            if(self.controlData.cancellationRequested==YES){
//                [self.rpar cancel];
//                break;
//            }
//            [self.rpar runStoredBlocksWithParams:(__bridge void *)([dictionary objectForKey:key]) withSummary:summary];
//            //self.exec(self.controlData,(__bridge void *)([dictionary objectForKey:key]));
//        }
//    }else{
//        NSLog(@"Sync Application failed, source dictionary is nil");
//    }
//}
//
//-(void) applyBlock:(ASFKExecutableProcedure)block toArray:(NSArray*)array withSummary:(ASFKExecutableBlockSummary)summary{
//    if(array&&summary&&block){
//        for (id item in array) {
//            if(self.controlData.cancellationRequested==YES){
//                [self.rpar cancel];
//                break;
//            }
//            [self.rpar runProcedure:block withParams:(__bridge void *)(item) withSummary: summary];
//            //self.exec(self.controlData,);
//        }
//    }else{
//        NSLog(@"Parallel Application failed, source array is nil");
//    }
//}
//-(void) applyBlock:(ASFKExecutableProcedure)proc toDictionary:(NSDictionary*)dictionary withSummary:(ASFKExecutableProcedureSummary)summary{
//    if(dictionary&&summary&&proc){
//        for(id key in dictionary){
//            if(self.controlData.cancellationRequested==YES){
//                [self.rpar cancel];
//                break;
//            }
//            [self.rpar runProcedure:block withParams:(__bridge void *)([dictionary objectForKey:key]) withSummary:summary];
//        }
//    }else{
//        NSLog(@"Parallel Application failed, source dictionary is nil");
//    }
//}


- (void)storeParamAsUnspecified:(id)data {
    
}

- (void)storeParamAsUnspecifiedCStyle:(void *)data {
    
}

@end
