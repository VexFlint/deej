#include "Arduino.h"
#include "hardware/adc.h"

const int NUM_SLIDERS = 3;
const uint ADC_PINS[NUM_SLIDERS] = {26, 27, 28};  // ADC pins for the sliders

const uint SWITCH_PIN = 22;  // Pin for the switch
bool switchState = false;
int lowCount = 0;  // Counter for consecutive LOW readings
const int DEBOUNCE_THRESHOLD = 20;  // Number of consecutive LOW readings to confirm a LOW state

int analogSliderValues[NUM_SLIDERS];
int sliderReadings[NUM_SLIDERS][10];  // Buffer for storing the last 10 readings for averaging
int readingIndex = 0;  // Index for the current reading in the buffer

void setup() { 
    Serial.begin(115200);
    adc_init();

    for (int i = 0; i < NUM_SLIDERS; i++) {
        adc_gpio_init(ADC_PINS[i]);
        for (int j = 0; j < 10; j++) {
            sliderReadings[i][j] = 0;  // Initialize the buffer
        }
    }

    pinMode(SWITCH_PIN, INPUT);
    pinMode(PICO_DEFAULT_LED_PIN, OUTPUT);
    digitalWrite(PICO_DEFAULT_LED_PIN, HIGH);  // Indicate the program is running
}

void loop() {
    readSwitchState();
    updateSliderValues();
    controlPotentiometerWithSwitch();
    sendSliderValues();
    delay(10);
}

void updateSliderValues() {
    for (int i = 0; i < NUM_SLIDERS; i++) {
        adc_select_input(i);
        int rawValue = adc_read();  // 12-bit value from ADC, 0 to 4095

        // Store the raw value in the buffer and calculate the average
        sliderReadings[i][readingIndex] = rawValue;
        int sum = 0;
        for (int j = 0; j < 10; j++) {
            sum += sliderReadings[i][j];
        }
        int average = sum / 10;

        // Map the average value to 0-1024 range
        int mappedValue = map(average, 0, 4095, 0, 1024);

        // Adjust the value based on the threshold conditions
        if (mappedValue <= 8) {
            analogSliderValues[i] = 0;
        } else if (mappedValue >= 1020) {
            analogSliderValues[i] = 1024;
        } else {
            analogSliderValues[i] = mappedValue;
        }
    }

    readingIndex = (readingIndex + 1) % 10;  // Move to the next index in the buffer
}

void readSwitchState() {
    bool currentSwitchState = digitalRead(SWITCH_PIN);
    
    if (currentSwitchState == HIGH) {
        switchState = true;
        lowCount = 0;
    } else {
        lowCount++;
        if (lowCount >= DEBOUNCE_THRESHOLD) {
            switchState = false;
            lowCount = 0;
        }
    }
}

void controlPotentiometerWithSwitch() {
    if (switchState) {
        // Turn off or set to 0 the potentiometer on port 26 (assuming this is the one you want to control)
        analogSliderValues[0] = 0;
    } else{
      analogSliderValues[512];
    }
}

void sendSliderValues() {
    String builtString = "";

    for (int i = 0; i < NUM_SLIDERS; i++) {
        builtString += String(analogSliderValues[i]) + "|";
    }
    builtString += String(switchState);

    Serial.println(builtString);
}

long map(long x, long in_min, long in_max, long out_min, long out_max) {
    return (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min;
}
