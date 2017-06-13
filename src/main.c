#include <propeller.h>
#define CHANNEL_COUNT 24
#define BIT(feild, pos) ((feild >> pos) & 0x01)

typedef struct {
	int pin_start;
	int pins;
	int pin_out_start;
	int passthrough;
} cog_params_t;

volatile int pulse_widths[CHANNEL_COUNT];

void cog_thread(void* params)
{
	cog_params_t p = *(cog_params_t*)params;

	int last_state = 0; // bit field of all input pin states 
	int starts[p.pins]; // cycle count at the rising edge of a pulse for each pin

	for(;;)
	{
		int state = INA; // current input pin states
		for(int i = p.pins; i--;)
		{
			int bit = BIT(state, i); // state of bit i

			// was low, but gone high. this is the start of a pulse
			if(!BIT(last_state, i) && bit)
			{
				// remember the cycle count when the pulse started
				starts[i] = CNT;

				if(p.passthrough)
				{
					OUTA |= 1 << (i + p.pin_out_start);	
				}
			}

			// was high, but gone low. this is the end of a pulse
			if(BIT(last_state, i) && !bit)
			{
				// calculate the pulse width in cycles
				pulse_widths[i + p.pin_start] = CNT - starts[i];

				if(p.passthrough)
				{
					OUTA &= ~(1 << (i + p.pin_out_start));	
				}
			}
		}

		last_state = state;
	}
}

int main()
{
	int stack[32];

	cog_params_t cog_p[] = {
		{
			.pin_start     = 0,
			.pins          = 4,
			.pin_out_start = 8,
			.passthrough   = 1,
		},
		{
			.pin_start     = 4,
			.pins          = 4,
			.pin_out_start = 12,
			.passthrough   = 1,
		}

	};

	int MICROS = CLKFREQ / 1000000; // cycles per microsecond
	int cog0_3 = coginit(1, cog_thread, &cog_p[0]); 

	// set the first 8 pins to input the rest to output
	DIRA = ~0x000000FF;
	

	//for(;;)
	if(cog0_3 == -1)
	{
		// TODO: handle i2c
		cog_thread(&cog_p[0]);
	}

	return 0;
}
