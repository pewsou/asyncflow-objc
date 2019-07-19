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

#import "ASFKApplySeq.h"

@interface ASFKApplySeq()
//@property ComposePar* cpar;

@property ASFKControlBlock* controlData;
@end

@implementation ASFKApplySeq
//-(id) initWithProcedure:(ASFKExecutableProcedure)proc {
//    self=[super init];
//    {
//        ASFKExecutableProcedure e=block;
//        if(block){}
//        else{
//            e=^void *(ASFKControlBlock *controlData, void *data) {
//                NSLog(@"EMPTY BLOCK APPLIED");
//                return data;
//            };
//        }
////        ASFKExecutableBlockEnd end=endBlock;
////        if(endBlock){
////
////        }else{
////            end=^void *(ASFKControlBlock *controlData, void *data) {
////                NSLog(@"EMPTY END BLOCK APPLIED");
////                return data;
////            };
////        }
//
//        self.cpar=[[ComposePar alloc]initWithNumberOfQueues:0];
//        [self.cpar storeProcedure:e];
//    }
//    return self;
//}
//-(id)init{
//    return [self init:^void *(ASFKControlBlock *controlData, void *data) {
//            NSLog(@"EMPTY BLOCK APPLIED");
//            return data;
//    } endBlock:^void *(ASFKControlBlock *controlData, void *data) {
//            NSLog(@"EMPTY END BLOCK APPLIED");
//            return data;
//        }];
//}

//-(void) applyToArray:(NSArray*)array withSummary:(ASFKExecutableBlockSummary)summary{
//    if(array&&summary){
//        for (id item in array) {
//            if(self.controlData.cancellationRequested==YES){
//                [self.cpar cancel];
//                break;
//            }
//            [self.cpar runStoredBlocksWithParams:(__bridge void *)(item) withSummary: summary];
//            //self.exec(self.controlData,);
//        }
//    }else{
//        NSLog(@"Sync Application failed, source array is nil");
//    }
//}
//-(void) applyToDictionary:(NSDictionary*)dictionary withSummary:(ASFKExecutableBlockSummary)summary{
//    if(dictionary&&summary){
//        for(id key in dictionary){
//            if(self.controlData.cancellationRequested==YES){
//                [self.cpar cancel];
//                break;
//            }
//            [self.cpar runStoredBlocksWithParams:(__bridge void *)([dictionary objectForKey:key]) withSummary:summary];
//            //self.exec(self.controlData,(__bridge void *)([dictionary objectForKey:key]));
//        }
//    }else{
//        NSLog(@"Sync Application failed, source dictionary is nil");
//    }
//}

//-(void) applyBlock:(ASFKExecutableProcedure)block toArray:(NSArray*)array withSummary:(ASFKExecutableBlockSummary)summary{
//    if(array&&summary&&block){
//        for (id item in array) {
//            if(self.controlData.cancellationRequested==YES){
//                [self.cpar cancel];
//                break;
//            }
//            [self.cpar runProcedure:block withParams:(__bridge void *)(item) withSummary: summary];
//            //self.exec(self.controlData,);
//        }
//    }else{
//        NSLog(@"Sync Application failed, source array is nil");
//    }
//}
//-(void) applyBlock:(ASFKExecutableProcedure)block toDictionary:(NSDictionary*)dictionary withSummary:(ASFKExecutableBlockSummary)summary{
//    if(dictionary&&summary&&block){
//        for(id key in dictionary){
//            if(self.controlData.cancellationRequested==YES){
//                [self.cpar cancel];
//                break;
//            }
//            [self.cpar runProcedure:block withParams:(__bridge void *)([dictionary objectForKey:key]) withSummary:summary];
//            //[self.cpar runStoredBlocksWithParams:) withSummary:summary];
//            //self.exec(self.controlData,(__bridge void *)([dictionary objectForKey:key]));
//        }
//    }else{
//        NSLog(@"Sync Application failed, source dictionary is nil");
//    }
//}
//
//-(void) applyToUnspecified:(void*)uns{
//
//}
@end
