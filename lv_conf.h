#ifndef LV_CONF_H
#define LV_CONF_H

#define LV_COLOR_DEPTH 16
#define LV_COLOR_16_SWAP 1

#define LV_MEM_SIZE (48U * 1024U)

#define LV_TICK_CUSTOM 1
#define LV_TICK_CUSTOM_INCLUDE "mp_hal.h"
#define LV_TICK_CUSTOM_SYS_TIME_EXPR (mp_hal_ticks_ms())

#define LV_USE_LOG 0
#define LV_USE_ASSERT_NULL 0
#define LV_USE_ASSERT_MALLOC 0
#define LV_USE_ASSERT_STYLE 0
#define LV_USE_ASSERT_MEM_INTEGRITY 0
#define LV_USE_ASSERT_OBJ 0

#define LV_HOR_RES_MAX 320
#define LV_VER_RES_MAX 240

#define LV_USE_GPU_STM32_DMA2D 0
#define LV_USE_GPU_NXP_PXP 0
#define LV_USE_GPU_NXP_VG_LITE 0

#endif /*LV_CONF_H*/
