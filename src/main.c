#include "simpletools.h"
#define CHANNEL_COUNT 24
#define BIT(feild, pos) ((feild >> pos) & 0x01)

typedef struct {
	int pin_start;
	int pins;
} cog_params_t;

volatile int pulse_widths[CHANNEL_COUNT];

void cog_thread(void* params)
{
	cog_params_t p = *(cog_params_t*)params;

	int last_state = 0;
	int starts[p.pins];

	for(;;)
	{
		int state = INA;
		for(int i = p.pins; i--;)
		{
			int bit = BIT(state, i);

			// was low, but gone high. this is the start of a pulse
			if(!BIT(last_state, i) && bit)
			{
				starts[i] = CNT;		
			}

			// was high, but gone low. this is the end of a pulse
			if(BIT(last_state, i) && !bit)
			{
				pulse_widths[i + p.pin_start] = CNT - starts[i];
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
			.pin_start = 0,
			.pins      = 4,
		}
	};

	int MICROS = CLKFREQ / 1000000;
	int cog0_3 = cogstart(cog_thread, &cog_p[0], stack, 32); 

	// set the first 12 pins to input
	DIRA &= ~0xFFF;

	for(;;)
	{

	}

	return 0;
}
