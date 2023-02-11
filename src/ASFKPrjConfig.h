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
//  Created by Boris Vigman on 05/04/2019.
//  Copyright © 2019-2023 Boris Vigman. All rights reserved.

#ifndef ASFKPrjConfig_h
#define ASFKPrjConfig_h

#define __ASFK_DEBUG__ 1
#define __ASFK_WARNING__ 1
#define __ASFK_ERROR__ 1
#define __ASFK_MISUSE__ 1

#define __ASFK_VERBOSE_PRINTING__ 1

#define ASFK_PRIVSYM_TP_LOAD_FACTOR 1
#define ASFK_PRIVSYM_TP_SESSIONS_LIMIT 1000
#define ASFK_PRIVSYM_TP_ITEMS_PER_SESSION_LIMIT 1000
#define ASFK_PRIVSYM_TP_PROCS_PER_SESSION_LIMIT 1000
#define ASFK_PRIVSYM_QOS_CLASS QOS_CLASS_BACKGROUND

/*!
 @brief Upper limit for messages per group or standalone mailbox.
 */
#define ASFK_PRIVSYM_MLBX_MSG_PER_CONT_LIMIT 1000000

/*!
@brief Upper limit for sum of all groups, mailboxes, posted messages.
@discussion Upper limit for sum of all groups, mailboxes, posted messages. Deleted, but not yet physically removed messages, groups and mailboxes included too.
*/
#define ASFK_PRIVSYM_MBLX_TOTAL_OBJ_LIMIT 100000

/*!
 @brief Maximum number of all posted messages in the system
 */
#define ASFK_PRIVSYM_MBLX_BRCAST_MSG_LIMIT 1000

/*!
 @brief Maximum number of recipients of multicast messages
 */
#define ASFK_PRIVSYM_MBLX_MULTICAST_RECV_LIMIT 100

/*!
 @brief Maximum number of standalone mailboxes in system
 */
#define ASFK_PRIVSYM_MLBX_MAX_MLBX_LIMIT 10000

/*!
 @brief Maximum number of groups in system
 */
#define ASFK_PRIVSYM_MLBX_MAX_GRPS_LIMIT 10000

#define ASFK_PRIVSYM_MSG_RELEASE_SAMPLE_SIZE 10000
#define ASFK_PRIVSYM_OBJ_RELEASE_SAMPLE_SIZE 10000

#define ASFK_CALC_ELAPSED_TIME(starttime, endtime) (endtime-starttime)/double(1e9)

#define ASFK_RC_DESCR_DONE @"OK"
#define ASFK_RC_DESCR_FAILURE @"Fail"
#define ASFK_RC_DESCR_CANCELED @"Canceled"
#define ASFK_RC_DESCR_DEFERRED @"Deferred"
#define ASFK_RC_DESCR_IMPROPER @"Improper"

#define ASFK_STR_UP_LIMITS_REACHED_SES @"Maximal number of sessions reached"
#define ASFK_STR_UP_LIMITS_REACHED_DATA @"Maximal number of data items per session reached"
#define ASFK_STR_INVALID_PARAM @"some of input parameters are invalid"
#define ASFK_STR_MISCONFIG_OP @"Operation not allowed due to inappropriate configuration"
#define ASFK_STR_UNSUPPORTED_OP @"Unsupported operation for this class"
#define ASFK_STR_WRONG_METHOD_CALL @"Method should not be called"
#define ASFK_STR_VER_UNAVAIL_OP @"Functionality unavailable in this version"
#define ASFK_STR_TOO_MANY_MSG_NOTIF @"Too many messages posted; operation canceled"
#define ASFK_STR_TOO_MANY_MLBX_NOTIF @"Too many mailboxes exist; operation canceled"
#define ASFK_STR_TOO_MANY_GRPS_NOTIF @"Too many group exist; operation canceled"
#define ASFK_STR_Q_LLIMIT_VIOLATION @"Queue's lower limit violated"
#define ASFK_STR_Q_ULIMIT_VIOLATION @"Queue's upper limit violated"
#define ASFK_STR_SEC_CHECK_FAIL @"Security check failed"
#endif
/* ASFKPrjConfig_h */
