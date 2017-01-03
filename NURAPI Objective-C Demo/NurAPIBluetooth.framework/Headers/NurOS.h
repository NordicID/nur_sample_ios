#ifndef NUROS_H_
#define NUROS_H_

#ifdef __linux__
	#include "NurOs_Linux.h"
#elif  defined(__ios__)
	#include "NurOs_iOS.h"
#elif defined(__APPLE__)
	#include "NurOs_macOS.h"
#else
	#include "NurOs_Win32.h"
#endif

#endif /* NUROS_H_ */
