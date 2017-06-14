#include <propeller.h>
#include "pwm-logger.h"

struct {
	unsigned stack[32];
	volatile pwm_par_t par;
	
} pwm0Par;

int main()
{

	pwm0Par.par.pin_start     = 0;
	pwm0Par.par.pins          = 4;
	pwm0Par.par.pin_out_start = 8;
	pwm0Par.par.passthrough   = 1;

	int MICROS = CLKFREQ / 1000000; // cycles per microsecond
	//int cog0_3 = coginit(1, cog_thread, &cog_p[0]); 
	
	extern unsigned int _load_start_pwm_cog[];
	
	// set the first 8 pins to input the rest to output
	DIRA = ~0x000000FF;
	OUTA = 0x0FF00;

	OUTA = 0x0;
#if defined(__PROPELLER_XMM__) || defined(__PROPELLER_XMMC__)
	load_cog_driver_xmm(_load_start_pwm_cog, 496, (uint32_t *)&pwm0Par.par);
#else
	int res = cognew(_load_start_pwm_cog, &pwm0Par.par);
#endif

	for(;;)
	{
		// TODO: handle i2c
		//cog_thread(&cog_p[0]);
	}

	return 0;
}
