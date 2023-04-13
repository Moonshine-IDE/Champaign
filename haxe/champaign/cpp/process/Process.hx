/*
 *  Copyright (C) 2016-present Prominic.NET, Inc.
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the Server Side Public License, version 1,
 *  as published by MongoDB, Inc.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 *  Server Side Public License for more details.
 *
 *  You should have received a copy of the Server Side Public License
 *  along with this program. If not, see
 *
 *  http://www.mongodb.com/licensing/server-side-public-license
 *
 *  As a special exception, the copyright holders give permission to link the
 *  code of portions of this program with the OpenSSL library under certain
 *  conditions as described in each individual source file and distribute
 *  linked combinations including the program with the OpenSSL library. You
 *  must comply with the Server Side Public License in all respects for
 *  all of the code used other than as permitted herein. If you modify file(s)
 *  with this exception, you may extend this exception to your version of the
 *  file(s), but you are not obligated to do so. If you do not wish to do so,
 *  delete this exception statement from your version. If you delete this
 *  exception statement from all source files in the program, then also delete
 *  it in the license file.
 */

package champaign.cpp.process;

import champaign.cpp.externs.NativeProcess;

#if !cpp
#error "Process is not supported on this target (no C++ support)"
#end

/**
 * Functions related to currently running or manually spawned processes
 */
class Process {

    /**
     * Checks if the current user that has spawned this process has root/admin privileges
     * @return Bool
     */
    static public function isUserRoot():Bool {

        return NativeProcess.__isUserRoot();

    }

    /**
     * Returns the current file resource limit on supported operating systems.
     * @return UInt
     */
    static public function getFileResourceLimit():UInt {

        return NativeProcess.__getFileResourceLimit();

    }

    /**
     * Sets the File Handle Resource Limit for the given process on supported operating
     * systems.(sub-processes are not affected). On certain systems and environments the
     * default file handle limit is ~256, which might be too low in specific cases. Use
     * this function only if there's a certain need to have a large number of file handles
     * simultaneously. If you set this value too low, your application might crash.
     * **Note: Sockets are also using file handles**.
     * @param limit The number of allowed file handles
     * @return Returns *true* if the operation was successful, *false* otherwise
     */
    static public function setFileResourceLimit( limit:UInt ):Bool {

        if ( limit < 1 ) limit = 1;
        return NativeProcess.__setFileResourceLimit( limit );

    }
    
}