#ifndef CProcess_h
#define CProcess_h

namespace NS_Champaign_Process
{

    bool __isUserRoot();
    int __getFileResourceLimit();
    bool __setFileResourceLimit( int lmt );

}

#endif