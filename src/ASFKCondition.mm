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
//  Created by Boris Vigman on 23/02/2019.
//  Copyright © 2019-2021 Boris Vigman. All rights reserved.
//

#import "ASFKBase.h"
@interface ASFKCondition()
@property ASFKExecutableProcedureConditionalBranch thenP;
@property ASFKExecutableProcedureConditionalBranch elseP;
@property ASFKExecutableProcedureConditional condition;
@property dispatch_queue_t exQ;
@end
@implementation ASFKCondition
-(id)init{
    self=[super init];
    if(self){
        self.thenP = nil;
        self.elseP = nil;
        self.condition = nil;
        NSString* rand=[[self generateRandomNumber]stringValue];
        self.exQ = dispatch_queue_create([[@"com.condition.1." stringByAppendingString:rand]cStringUsingEncoding:NSASCIIStringEncoding], DISPATCH_QUEUE_SERIAL);
        rand=nil;
    }
    return self;
}
#pragma mark - Deferred evaluation
-(ASFKExecutableProcedureConditional) storeCondition:(ASFKExecutableProcedureConditional)condProc{
    ASFKExecutableProcedureConditional last=self.condition;
    if(condProc){
        self.condition = condProc;
    }else{
        ASFKLog(@"WARNING: invalid condition, not set");
    }
    return last;
}
-(ASFKExecutableProcedureConditionalBranch) storeThenBranch:(ASFKExecutableProcedureConditionalBranch)thenproc{
    ASFKExecutableProcedureConditionalBranch last=self.thenP;
    if(thenproc){
        self.thenP = thenproc;
    }else{
        ASFKLog(@"WARNING: invalid THEN branch, not set");
    }
    return last;
}
-(ASFKExecutableProcedureConditionalBranch) storeElseBranch:(ASFKExecutableProcedureConditionalBranch)elseproc{
    ASFKExecutableProcedureConditionalBranch last=self.elseP;
    if(elseproc){
        self.elseP = elseproc;
    }else{
        ASFKLog(@"WARNING: invalid ELSE branch, not set");
    }
    return last;
}
#pragma mark - Immediate evaluation
-(BOOL) evaluateConditionWithParam:(id)param withSummary:(ASFKExecutableProcedureSummary)summary{
    return [self evaluateCondition:self.condition withParam:param withSummary:summary];
}
-(BOOL) evaluateCondition:(ASFKExecutableProcedureConditional)cond withParam:(id)param withSummary:(ASFKExecutableProcedureSummary)summary{
    if(self.enabledNonBlockingExecution){
        dispatch_async(self.exQ, ^{
            summary(self.sharedCtrlBlock,[NSNumber numberWithBool: cond(self.sharedCtrlBlock,param)]);
        });
        return YES;
    }else{
        return cond(self.sharedCtrlBlock, param);
    }
}

-(void)ifExists:(ASFKExecutableProcedureConditional)condProc withParam:(id)param thenDo:(ASFKExecutableProcedureConditionalBranch)thenProc thenParam:(id)thenParam elseDo:(ASFKExecutableProcedureConditionalBranch)elseProc elseParam:(id)elseParam{
    if(condProc&&thenProc&&elseProc){
        if(condProc(self.sharedCtrlBlock, param)){
            thenProc(self.sharedCtrlBlock,param,thenParam);
        }else{
            elseProc(self.sharedCtrlBlock,param,elseParam);
        }
    }else{
        ASFKLog(@"WARNING: Condition OR one of branches not set");
    }
}
-(void)ifExistsWithParam:(id)param thenParam:(id)thenParam elseParam:(id)elseParam{
    [self ifExists:self.condition withParam:param thenDo:self.thenP thenParam:thenParam elseDo:self.elseP elseParam:elseParam];
}
/*
-(void)pickBranchWithParam:(id)param thenParam:(id)thenParam elseParam:(id)elseParam{
    [self ifExists:self.condition withParam:param thenDo:self.thenP thenParam:thenParam elseDo:self.elseP elseParam:elseParam];
}
 */
-(void)ifExists:(ASFKExecutableProcedureConditional)condProc withParam:(id)param thenParam:(id)thenParam elseParam:(id)elseParam{
    [self ifExists:condProc withParam:param thenDo:self.thenP thenParam:thenParam elseDo:self.elseP elseParam:elseParam];
}
@end
