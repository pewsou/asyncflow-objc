//
//  ASFKNonForkable+Private.h
//  Async
//
//  Created by Boris Vigman on 14/04/2019.
//  Copyright © 2019 Boris Vigman. All rights reserved.
//

#import "ASFKBase.h"

@interface ASFKBase (Private)
-(void) setStoredProcedures:(NSMutableArray*)procedures andEnds:(NSMutableArray*)ends;
@end
