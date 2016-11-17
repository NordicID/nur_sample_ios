/*
 * NurAccessoryExtension.h
 *
 *  Created on: Oct 5, 2016
 *      Author: mikko
 */

#ifndef _NURACCESSORYEXTENSION_H_
#define _NURACCESSORYEXTENSION_H_ 1

#include "NurAPI.h"

#ifdef __cplusplus
extern "C" {
#endif

/** @defgroup ACCESSORYAPI NUR Accessory device extension API.
 *  API for NUR accessory devices, such as EXA51
 *  @{
 */

/** The notification number associated with accessory device events. First byte with notification NUR_NOTIFICATION_ACCESSORY is event type. */
static const int NUR_NOTIFICATION_ACCESSORY = 0x90;

/** Barcode read event. First byte with notification NUR_NOTIFICATION_ACCESSORY is event type. */
static const int NUR_ACC_EVENT_BARCODE = 0x1;

/** NUR_NOTIFICATION_IOCHANGE source is set to this when accessory device trigger is pressed/released. */
static const int NUR_ACC_TRIGGER_SOURCE = 100;

#pragma pack(push, 1)

/**
 * Nur accessory device (such as EXA51) configuration.
 * @sa NurAccGetConfig(), NurAccSetConfig()
 */
typedef struct __NUR_ACC_CONFIG {
	DWORD signature;				/**< Signature of config struct. Use value read (NurAccGetConfig) from device. */
	DWORD config;					/**< Device configuration flags. Currently NUR_ACC_CFG_ACD or NUR_ACC_CFG_WEARABLE */
	DWORD flags;					/**< Device operation flags. Currently used to enable HID modes. NUR_ACC_FL_HID_BARCODE and/or NUR_ACC_FL_HID_RFID */

	char device_name[32];			/**< NULL terminated string of device name. This used used as BLE visible name. */

    WORD hid_barcode_timeout;		/**< HID mode barcode scanner read timeout in milliseconds. */
    WORD hid_rfid_timeout;			/**< HID mode RFID read timeout in milliseconds. */
    WORD hid_rfid_maxtags;			/**< HID mode RFID read max tags. When max tags reached, reading will stop. */
} NUR_ACC_CONFIG;

/**
 * Nur accessory device (such as EXA51) battery information.
 * @sa NurAccGetBattInfo()
 */
typedef struct __NUR_ACC_BATT_INFO
{
	WORD flags;					/**< Battery flags. Currently 0 or NUR_ACC_BATT_FL_CHARGING */
	char percentage;			/**< Battery percentage level 0-100. -1 if unknown. */
	short volt_mV;				/**< Battery voltage level in mV. -1 if unknown. */
	short curr_mA;				/**< Current battery current draw in mA. */
	short cap_mA;				/**< Battery capacity in mAh. -1 if unknown. */
} NUR_ACC_BATT_INFO;

#pragma pack(pop)

/** NUR_ACC_BATT_INFO.flags value. If set device is currently charging. */
#define NUR_ACC_BATT_FL_CHARGING (1<<0)

/** NUR_ACC_CONFIG.flags value. HID-bit for the barcode scan. */
#define NUR_ACC_FL_HID_BARCODE 	(1<<0)
/** NUR_ACC_CONFIG.flags value. HID-bit for the RFID scan / inventory. */
#define NUR_ACC_FL_HID_RFID 	(1<<1)

/** NUR_ACC_CONFIG.config value. If set, device has ACD antenna. */
#define NUR_ACC_CFG_ACD 		(1<<0)
/** NUR_ACC_CONFIG.config value. If set, device has wearable antenna. */
#define NUR_ACC_CFG_WEARABLE 	(1<<1)

/**
 * Nur accessory device (such as EXA51) programmable LED operating mode.
 * @sa NurAccSetLedOpMode()
 */
enum NUR_ACC_LED_MODE {
	NUR_ACC_LED_UNSET = 0,	/**< Return device default mode. */
	NUR_ACC_LED_OFF,		/**< Programmable LED constantly off. */
	NUR_ACC_LED_ON,			/**< Programmable LED constantly on. */
	NUR_ACC_LED_BLINK		/**< Programmable LED constantly blinking. */
};

/** @fn int NurAccGetFwVersion(HANDLE hApi, TCHAR *fwVer, int fwVerSizeChars)
 * Get accessory device firmware version.
 *
 * @param	hApi			Handle to valid NurApi object instance.
 * @param	fwVer			Pointer to a buffer that receives firmware version string.
 * @param	fwVerSizeChars	The size of <i>fwVer</i> buffer in TCHARs.
 *
 * @return	Zero when succeeded, On error non-zero error code is returned.
 */
NUR_API
int NURAPICONV NurAccGetFwVersion(HANDLE hApi, TCHAR *fwVer, int fwVerSizeChars);

/** @fn int NurAccReadBarcodeAsync(HANDLE hApi, WORD timeoutInMs)
 * Start asynchronous barcode reading operation in device.
 * Result will be reported via notification callback, NUR_NOTIFICATION_ACCESSORY with first byte set to NUR_ACC_EVENT_BARCODE.
 *
 * If barcode reading succeeded, notification status is set to NUR_SUCCESS (0) and barcode result is stored in notification data starting from byte index 1.
 * If barcode reading is cancelled, notification status is set to NUR_ERROR_NOT_READY (13).
 * If barcode reader is not present, notification status is set to NUR_ERROR_HW_MISMATCH (8).
 *
 * NOTE: While barcode reading is active, it is not allowed to send any other command than NurAccCancelBarcode() to device.
 * NOTE2: Pressing device trigger will cancel barcode reading automatically.
 *
 * @param	hApi			Handle to valid NurApi object instance.
 * @param	timeoutInMs		Reading timeout in milliseconds. Range 500 - 20000
 *
 * @return	Zero when succeeded, On error non-zero error code is returned.
 * @sa NurAccCancelBarcode(), NUR_NOTIFICATION_ACCESSORY, NUR_ACC_EVENT_BARCODE
 */
NUR_API
int NURAPICONV NurAccReadBarcodeAsync(HANDLE hApi, WORD timeoutInMs);

/** @fn int NurAccCancelBarcode(HANDLE hApi)
 * Cancel asynchronous barcode reading operation in device.
 *
 * If barcode reading is in progress, NUR_NOTIFICATION_ACCESSORY notification status is set to NUR_ERROR_NOT_READY (13).
 *
 * NOTE: While barcode reading is active, it is not allowed to send any other command than NurAccCancelBarcode() to device.
 * NOTE2: Pressing device trigger will cancel barcode reading automatically.
 *
 * @param	hApi			Handle to valid NurApi object instance.
 *
 * @return	Zero when succeeded, On error non-zero error code is returned.
 * @sa NurAccReadBarcodeAsync(), NUR_NOTIFICATION_ACCESSORY, NUR_ACC_EVENT_BARCODE
 */
NUR_API
int NURAPICONV NurAccCancelBarcode(HANDLE hApi);

/** @fn int NurAccBeepAsync(HANDLE hApi, WORD timeoutInMs)
 * Generate beep sound in device.
 *
 * @param	hApi			Handle to valid NurApi object instance.
 * @param	timeoutInMs		Beep time in milliseconds. Range 1 - 5000
 *
 * @return	Zero when succeeded, On error non-zero error code is returned.
 */
NUR_API
int NURAPICONV NurAccBeepAsync(HANDLE hApi, WORD timeoutInMs);

/** @fn int NurAccSetLedOpMode(HANDLE hApi, BYTE mode)
 * Set accessory device LED operating mode.
 *
 * @param	hApi			Handle to valid NurApi object instance.
 * @param	mode			Mode, one the enum NUR_ACC_LED_MODE. NUR_ACC_LED_UNSET, NUR_ACC_LED_OFF, NUR_ACC_LED_ON, NUR_ACC_LED_BLINK
 *
 * @return	Zero when succeeded, On error non-zero error code is returned.
 * @sa enum NUR_ACC_LED_MODE
 */
NUR_API
int NURAPICONV NurAccSetLedOpMode(HANDLE hApi, BYTE mode);

/** @fn int NurAccRestart(HANDLE hApi)
 * Restart accessory device.
 *
 * @param	hApi			Handle to valid NurApi object instance.
 *
 * @return	Zero when succeeded, On error non-zero error code is returned.
 */
NUR_API
int NURAPICONV NurAccRestart(HANDLE hApi);

/** @fn int NurAccGetConfig(HANDLE hApi, NUR_ACC_CONFIG *cfg, DWORD cfgSize)
 * Get accessory device configuration.
 *
 * @param	hApi			Handle to valid NurApi object instance.
 * @param	cfg				Pointer to config.
 * @param	cfgSize			Size of 'cfg' struct in bytes.
 *
 * @return	Zero when succeeded, On error non-zero error code is returned.
 * @sa NurAccSetConfig(), NUR_ACC_CONFIG
 */
NUR_API
int NURAPICONV NurAccGetConfig(HANDLE hApi, NUR_ACC_CONFIG *cfg, DWORD cfgSize);

/** @fn int NurAccSetConfig(HANDLE hApi, NUR_ACC_CONFIG *cfg, DWORD cfgSize)
 * Set accessory device configuration.
 * NOTE: First get configuration with NurAccGetConfig() function and then change needed params.
 *
 * @param	hApi			Handle to valid NurApi object instance.
 * @param	cfg				Pointer to new config.
 * @param	cfgSize			Size of 'cfg' struct in bytes.
 *
 * @return	Zero when succeeded, On error non-zero error code is returned.
 * @sa NurAccGetConfig(), NUR_ACC_CONFIG
 */
NUR_API
int NURAPICONV NurAccSetConfig(HANDLE hApi, NUR_ACC_CONFIG *cfg, DWORD cfgSize);

/** @fn int NurAccGetBattInfo(HANDLE hApi, NUR_ACC_BATT_INFO *info, DWORD infoSize)
 * Get accessory device battery information.
 *
 * @param	hApi			Handle to valid NurApi object instance.
 * @param	info			Pointer to info struct.
 * @param	infoSize		Size of 'info' struct in bytes.
 *
 * @return	Zero when succeeded, On error non-zero error code is returned.
 * @sa NUR_ACC_BATT_INFO
 */
NUR_API
int NURAPICONV NurAccGetBattInfo(HANDLE hApi, NUR_ACC_BATT_INFO *info, DWORD infoSize);

/** @} */ // end of ACCESSORYAPI

#ifdef __cplusplus
};
#endif

#endif
