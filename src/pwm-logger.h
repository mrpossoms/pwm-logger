#ifndef _PWM_LOGGER
#define _PWM_LOGGER

#define CHANNEL_COUNT 24
#define BIT(feild, pos) ((feild >> pos) & 0x01)

typedef struct {
	int pin_start;
	int pins;
	int pin_out_start;
	int passthrough;
} pwm_par_t;

#endif
