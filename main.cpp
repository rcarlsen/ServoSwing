#include "WProgram.h"
#include "SoftwareSerial.h"
#include "Servo.h"

// prototype methods
// NOP

// variables
int ledPin = 13; // LED connected to digital pin 13
Servo phoneservo;  // servo
int pos = 0;       // servo position variable
int offset = 0; // initial angle
int sweep = 40; // arc width angle

enum stateFlags {
	HomeState = 0,
	PausedState,
	ActiveState
};

int state = ActiveState;

void setup() 
{ 
	Serial.begin(9600);	// opens serial port, sets data rate to 9600 bps
	
	pinMode(ledPin, OUTPUT);      // sets the digital pin as output
	Serial.println("--------------------------");
	Serial.println(" iPhone running simulator");
	Serial.println("--------------------------");
	Serial.println("");
	Serial.println("Spacebar     Toggle running");
    Serial.println("s            Pause");
    Serial.println("]            Rotate left");
    Serial.println("[            Rotate right");
    Serial.println(";            Decrease sweep");
    Serial.println("\            Increase sweep");
	Serial.println("");
  	Serial.println("--------------------------");

	phoneservo.attach(9);  // laser servo PWM control - Arduino pin 9
} 

void loop() 
{ 
	// read the serial in for control:
	if(Serial.available() > 0){
		int in = Serial.read();
		switch (in) {
			case ' ':
				//spacebar, toggle pause
				Serial.println("Toggle activity");
				if(state == ActiveState) {
					state = PausedState;
				}
				else if(state == PausedState || state == HomeState) {
					state = ActiveState;
				}
				break;
			case 's':
			case 'S':
				Serial.println("Pausing");
				// hard stop
				state = PausedState;
				break;
				
			case ']':
				// rotate left
				if (offset <= 90) {
					offset++;
				}
				
				Serial.print("Rotation: ");
				Serial.println(offset);
				break;
			
			case '[':
				// rotate right
				Serial.print("Rotation: ");
				Serial.println(offset);
				
				if(offset > 1){
					offset--;
				}
				break;
	
			case '\'':
				// increase sweep
				if (sweep <= 180) {
					sweep++;
				}
				
				Serial.print("Sweep: ");
				Serial.println(sweep);
				break;
				
			case ';':
				// decrease sweep
				if(sweep > 1){
					sweep--;
				}
				Serial.print("Sweep: ");
				Serial.println(sweep);
				break;
				
			default:
				// echo
				Serial.println("Command not recognized.");
				break;
		}
		Serial.flush();
	}
	
	switch (state) {
		case HomeState:
			pos = 1;
			phoneservo.write(pos);
			state = PausedState;
			break;
		case ActiveState:
			for(pos = 0; pos < sweep; pos +=1)   // sweep from 0 to 120 degrees in steps of 1
			{
				phoneservo.write(pos + offset);           // sweep start position 
				delay(3);                            // delay for sweep
			} 
			for(pos = sweep; pos>=0; pos-=1)     // sweep from 120 to 0 degrees in steps of 1
			{                                
				phoneservo.write(pos + offset);           // sweep end position 
				delay(3);                            // delay for sweep
			} 
			break;
		case PausedState:
			// maintain position
			phoneservo.write(offset);
			break;
		default:
			break;
	}

} 


int main(void)
{
	init();

	setup();
    
	for (;;)
		loop();
        
	return 0;
}

