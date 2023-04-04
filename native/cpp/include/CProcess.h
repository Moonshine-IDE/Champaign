#ifndef CHAMPAIGN_PROCESS_H
#define CHAMPAIGN_PROCESS_H

namespace NS_Champaign_Process
{

    bool __isUserRoot();
    int __getFileResourceLimit();
    bool __setFileResourceLimit( int lmt );

}

#endif