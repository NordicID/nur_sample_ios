#ifndef _NURAPI_BOOTLOADER_H_
#define _NURAPI_BOOTLOADER_H_ 1

#ifdef __cplusplus 
extern "C" { 
#endif

/** @defgroup INTERNALAPI NUR Internal API
 *  Internal API for NUR module bootloader
 *  @{
 */

#define NUR_MAX_SERIAL_LENGTH		(16)
#define NUR_MAX_NAME_LENGTH			(16)
#define NUR_MAX_FCCID_LENGTH		(48)
#define NUR_MAX_HWVER_LENGTH		(8)

#define NUR_VARIANT_FLAG_NONE  		0
#define NUR_VARIANT_FLAG_USB_TABLE  (1<<0)
#define NUR_VARIANT_FLAG_ETH_TABLE	(1<<1)
#define NUR_VARIANT_FLAG_STIX		(1<<2)
#define _DO_NOT_USE_NUR_VARIANT_FLAG_ONEWATT_	(1<<3) // Removed
#define _DO_NOT_USE_NUR_VARIANT_FLAG_GRIDANT_	(1<<4) // Removed
#define NUR_VARIANT_FLAG_ONEWATT	(1<<5)
#define NUR_VARIANT_FLAG_BEAMANT	(1<<6)
#define NUR_VARIANT_FLAG_MULTIPORT	(1<<7)
#define NUR_VARIANT_BEAM_READER_EB  (1<<8)
#define NUR_VARIANT_BEAM_READER_EB2	(1<<9)
#define NUR_VARIANT_AR_LOWGAIN		(1<<10)
#define NUR_VARIANT_4PORT			(1<<11)
#define NUR_VARIANT_HAS_TEMPSENSOR  (1<<12)

#define NUR_MAX_SEND_SZ				((2*1024)-1)
#define NUR_MAX_RCV_SZ				((32*1024)-1)

#define CRYPTO_PERMISSION_LENGTH    32

struct NUR_SCANCHANNEL_INFO
{
	DWORD freq;
	int rssi;
	int rawiq;
};

struct NUR_REFLECTEDPOWER_INFO
{
	int iPart;
	int qPart;
	int div;
};

struct NUR_REFLECTEDPOWER_INFO_EX
{
	int iPart;
	int qPart;
	int div;
	DWORD freqKhz;
};

struct NUR_VARIANT_INFO
{
  	BOOL usbtablereader;
  	TCHAR serial[NUR_MAX_SERIAL_LENGTH];
  	TCHAR altSerial[NUR_MAX_SERIAL_LENGTH];
  	TCHAR name[NUR_MAX_NAME_LENGTH];
  	TCHAR fccId[NUR_MAX_FCCID_LENGTH];  
};

struct NUR_VARIANT_INFO2
{
  BOOL usbtablereader;
  TCHAR serial[NUR_MAX_SERIAL_LENGTH+1];		// + NULL
  TCHAR altSerial[NUR_MAX_SERIAL_LENGTH+1];		// + NULL
  TCHAR name[NUR_MAX_NAME_LENGTH+1];			// + NULL
  TCHAR fccId[NUR_MAX_FCCID_LENGTH+1];			// + NULL
  TCHAR hwVer[NUR_MAX_HWVER_LENGTH+1];			// + NULL
};

struct NUR_VARIANT_INFO3
{
  BOOL usbtablereader;
  TCHAR serial[NUR_MAX_SERIAL_LENGTH+1];		// + NULL
  TCHAR altSerial[NUR_MAX_SERIAL_LENGTH+1];		// + NULL
  TCHAR name[NUR_MAX_NAME_LENGTH+1];			// + NULL
  TCHAR fccId[NUR_MAX_FCCID_LENGTH+1];			// + NULL
  TCHAR hwVer[NUR_MAX_HWVER_LENGTH+1];			// + NULL
  BOOL ethtablereader;
};

struct NUR_VARIANT_INFO4
{
  BOOL usbtablereader;
  TCHAR serial[NUR_MAX_SERIAL_LENGTH+1];		// + NULL
  TCHAR altSerial[NUR_MAX_SERIAL_LENGTH+1];		// + NULL
  TCHAR name[NUR_MAX_NAME_LENGTH+1];			// + NULL
  TCHAR fccId[NUR_MAX_FCCID_LENGTH+1];			// + NULL
  TCHAR hwVer[NUR_MAX_HWVER_LENGTH+1];			// + NULL
  BOOL ethtablereader;
  BOOL onewattreader;
  BOOL beamreader;
};

struct NUR_VARIANT_INFO5
{
  BOOL usbtablereader;
  TCHAR serial[NUR_MAX_SERIAL_LENGTH+1];		// + NULL
  TCHAR altSerial[NUR_MAX_SERIAL_LENGTH+1];		// + NULL
  TCHAR name[NUR_MAX_NAME_LENGTH+1];			// + NULL
  TCHAR fccId[NUR_MAX_FCCID_LENGTH+1];			// + NULL
  TCHAR hwVer[NUR_MAX_HWVER_LENGTH+1];			// + NULL
  BOOL ethtablereader;
  BOOL onewattreader;
  BOOL beamreader;
  BOOL stixreader;
};

struct NUR_VARIANT_INFO6
{
  BOOL usbtablereader;
  TCHAR serial[NUR_MAX_SERIAL_LENGTH+1];		// + NULL
  TCHAR altSerial[NUR_MAX_SERIAL_LENGTH+1];		// + NULL
  TCHAR name[NUR_MAX_NAME_LENGTH+1];			// + NULL
  TCHAR fccId[NUR_MAX_FCCID_LENGTH+1];			// + NULL
  TCHAR hwVer[NUR_MAX_HWVER_LENGTH+1];			// + NULL
  BOOL ethtablereader;
  BOOL onewattreader;
  BOOL beamreader;
  BOOL stixreader;
  BOOL multiport;
};

struct NUR_VARIANT_INFO7
{
  BOOL usbtablereader;
  TCHAR serial[NUR_MAX_SERIAL_LENGTH+1];		// + NULL
  TCHAR altSerial[NUR_MAX_SERIAL_LENGTH+1];		// + NULL
  TCHAR name[NUR_MAX_NAME_LENGTH+1];			// + NULL
  TCHAR fccId[NUR_MAX_FCCID_LENGTH+1];			// + NULL
  TCHAR hwVer[NUR_MAX_HWVER_LENGTH+1];			// + NULL
  BOOL ethtablereader;
  BOOL onewattreader;
  BOOL beamreader;
  BOOL stixreader;
  BOOL multiport;
  BOOL extrabeam;
  BOOL extrabeam2;
};

/** Read page from NUR module
 * 
 * @param	hApi			Handle to valid NurApi object instance
 * @param	pageNum			Page number to read
 * @param	pageBuffer		Buffer to store data. This must be atleast 256 bytes long.
 * @param	pageAddr		Page address is stored here
 * 							
 * @return	Zero when succeeded, On error non-zero error code is returned.
 * @remarks This command is available only in bootloader
 */
NUR_API
int NURAPICONV NurApiPageRead(HANDLE hApi, WORD pageNum, BYTE *pageBuffer, DWORD *pageAddr);

/** Program new firmware to NUR module.
 * @sa NUR_NOTIFICATION_PRGPRGRESS in enum NUR_NOTIFICATION
 * 
 * @param	hApi			Handle to valid NurApi object instance
 * @param	buffer			Data to program
 * @param	bufferLen		Length of data in bytes
 * 							
 * @return	Zero when succeeded, On error non-zero error code is returned.
 * @remarks This command is available only in bootloader
 */
NUR_API
int NURAPICONV NurApiProgramApp(HANDLE hApi, BYTE *buffer, DWORD bufferLen);

NUR_API
int NURAPICONV NurApiProgramBootloader(HANDLE hApi, BYTE *buffer, DWORD bufferLen);

/** Write NUR module serial, name and variant flags.
 * @param	hApi	Handle to valid NurApi object instance
 * @return	Zero when succeeded, On error non-zero error code is returned.
 */
NUR_API
int NURAPICONV NurApiSetVariantInfo(HANDLE hApi, DWORD dwCode, struct NUR_VARIANT_INFO *vi);

/** Write NUR module serial, name and variant flags.
 * @param	hApi	Handle to valid NurApi object instance
 * @return	Zero when succeeded, On error non-zero error code is returned.
 */
NUR_API
int NURAPICONV NurApiSetVariantInfoEx(HANDLE hApi, DWORD dwCode, struct NUR_VARIANT_INFO7 *vi, DWORD viSize);

NUR_API
int NURAPICONV NurApiSaveFactoryDefaults(HANDLE hApi, DWORD dwCode);

/*
  Internal use
*/
NUR_API
int NURAPICONV NurApiSetFileFormat(HANDLE hApi, BYTE code, BYTE *clean, DWORD length);

NUR_API
int NURAPICONV NurApiGetRfSettings(HANDLE hApi, BYTE *buffer, DWORD bufferLen);
NUR_API
int NURAPICONV NurApiSetRfSettings(HANDLE hApi, BYTE *buffer, DWORD bufferLen);
NUR_API
int NURAPICONV NurApiScanChannels(HANDLE hApi, struct NUR_SCANCHANNEL_INFO *infoArray, DWORD *infoArrayLen);
NUR_API
int NURAPICONV NurApiGetReflectedPower(HANDLE hApi, struct NUR_REFLECTEDPOWER_INFO *info);

NUR_API
int NURAPICONV NurApiGetReflectedPowerFreq(HANDLE hApi, DWORD freq, struct NUR_REFLECTEDPOWER_INFO *info);

NUR_API
int NURAPICONV NurApiWriteReg(HANDLE hApi, BYTE reg, BYTE val);

NUR_API
int NURAPICONV NurApiReadReg(HANDLE hApi, BYTE reg, BYTE *val);

NUR_API
int NURAPICONV NurApiConfigBits(HANDLE hApi, DWORD code, DWORD *bits, BOOL set);

NUR_API
int NURAPICONV NurApiConfirmMCUArch(HANDLE hNurApi, DWORD requiredArch, DWORD *actualArch);

/** @} */ // end of INTERNALAPI

#ifdef __cplusplus 
}
#endif

#endif
