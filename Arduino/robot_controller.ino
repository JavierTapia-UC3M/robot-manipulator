// ==========================================
//               CONFIGURATION
// ==========================================

#include <Servo.h>

// PD Constants
const float Kp = 3.0;
const float Kd = 0.3;

// Potentiometer Safety Limits
const int LOWER_LIMIT = 5;
const int UPPER_LIMIT = 1018;

// Processing Angle Limits
const int ANGLE_LOWER_LIMIT = 0;
const int ANGLE_UPPER_LIMIT = 180;

// Serial Comms Config
const byte numChars = 32;
char receivedChars[numChars];   // Array to store the incoming message
boolean newData = false;        // Flag to indicate a full message arrived
const int MAX_ARGS = 5;   // Maximum arguments you expect to handle

// Servos
const int wrist_pin = 3;
const int gripper_pin = 2;
// Servos initialization values
const int init_wrist_angle = 0;
const int init_gripper_angle= 10; 
const int closed_gripper_angle= 180;
Servo wrist;
Servo gripper;




// ==========================================
//            DATA STRUCTURES
// ==========================================

struct Motor {
  // Pin Connections
  const int enPin;
  const int in1Pin;
  const int in2Pin;
  const int potPin;
  
  // State Variables
  float setpoint;
  float input;
  float output;
  float prevError;
  unsigned long prevTimeMs; // Store time in ms for stability
};

struct ParsedPacket {
  char command[10];     // The command ID 
  float args[MAX_ARGS]; // The list of arguments
  int argCount;         // How many arguments were actually received
};

// Initialize Motors with their specific pins
// Format: {enPin, in1Pin, in2Pin, potPin, setpoint, input, output, prevError, prevTime}
Motor motor1 = {9,  8,  7,  A0, 0, 0, 0, 0, 0};
Motor motor2 = {10, 11, 12, A1, 0, 0, 0, 0, 0};
Motor motor3 = {6,  5,  4,  A2, 0, 0, 0, 0, 0};

// ==========================================
//               SETUP
// ==========================================

void setup() {
  
  initMotorPins(motor1);
  initMotorPins(motor2);
  initMotorPins(motor3);
  initServos(wrist_pin, gripper_pin);
  Serial.begin(9600);
}

// ==========================================
//                LOOP
// ==========================================

void loop() {
  unsigned long currentMillis = millis();

  // Check for incoming data (Does not block)
  recvWithStartEndMarkers();
  
  // If a full message arrived (<...>), parse it
  if (newData == true) {
    ParsedPacket message = parseData();
    newData = false; // Reset flag
    handleMessage(message);
  }

  // Run Control Loop for each motor
  runControlLoop(motor1);
  runControlLoop(motor2);
  runControlLoop(motor3);


  delay(20);
}






// ==========================================
//            HELPER FUNCTIONS
// ==========================================

// Sets the pinMode for a specific motor
void initMotorPins(Motor &m) {
  pinMode(m.enPin, OUTPUT);
  pinMode(m.in1Pin, OUTPUT);
  pinMode(m.in2Pin, OUTPUT);
  pinMode(m.potPin, INPUT);
  m.setpoint = analogRead(m.potPin); // Set inital goal their current position to avoid unwanted movement on startup
}

void initServos(int pinWrist, int pinGripper){
  pinMode(pinWrist, OUTPUT);
  pinMode(pinGripper, OUTPUT);
  wrist.attach(pinWrist);
  gripper.attach(pinGripper);
  wrist.write(init_wrist_angle);
  gripper.write(init_gripper_angle);
}

// Core logic: Reads pot, calculates PD, writes to motor
void runControlLoop(Motor &m) {
  // Calculate Time Delta (in seconds)
  float nowSec = millis() / 1000.0;
  float prevSec = m.prevTimeMs / 1000.0;
  float dt = nowSec - prevSec;
  
  if (dt <= 0) dt = 0.001; // Prevent division by zero (shouldn't be needed)

  // Read Potentiometer
  m.input = analogRead(m.potPin);

  // Calculate Error
  float error = m.setpoint - m.input;

  // Calculate Derivative
  float derivative = (error - m.prevError) / dt;

  // Calculate PD Output
  m.output = (Kp * error) + (Kd * derivative);

  // Drive Hardware (H-Bridge Logic)
  int pwmValue = constrain(abs(m.output), 0, 255);

  // Set rotation direction
  if (m.output < 0) {
    digitalWrite(m.in1Pin, LOW);
    digitalWrite(m.in2Pin, HIGH);
  } else {
    digitalWrite(m.in1Pin, HIGH);
    digitalWrite(m.in2Pin, LOW);
  }

  // Send to driver
  analogWrite(m.enPin, pwmValue);

  // Save State for next loop
  m.prevError = error;
  m.prevTimeMs = millis();
}



void recvWithStartEndMarkers() {
  static boolean recvInProgress = false;
  static byte ndx = 0;
  char startMarker = '<';
  char endMarker = '>';
  char rc;
  
  // While data is available in the buffer, read it
  while (Serial.available() > 0 && newData == false) {
    rc = Serial.read();
    if (recvInProgress == true) {
      if (rc != endMarker) {
        // Add char to buffer
        receivedChars[ndx] = rc;
        ndx++;
        if (ndx >= numChars) {
          ndx = numChars - 1; // Prevent buffer overflow
        }
      }
      else {
        // End marker received
        receivedChars[ndx] = '\0'; // Terminate the string
        recvInProgress = false;
        ndx = 0;
        newData = true; // Tell loop() we have a full message
      }
    }
    else if (rc == startMarker) {
      recvInProgress = true;
    }
  }
}

ParsedPacket parseData() {
  char * strtokIndx; 
  int argCount = 0;   
  ParsedPacket result; // Create the struct to  return  

  // Initialize the result structure
  result.argCount = 0;
  // Use memset to clear the args array to 0s for safety
  memset(result.args, 0, sizeof(result.args)); 

  // Get the Command
  strtokIndx = strtok(receivedChars, ",");      // Get first chunk
  
  // Safety check: if packet was empty (e.g. "<>")
  if (strtokIndx == NULL) return result; 
  
  // Copy the command string into the struct's field
  strncpy(result.command, strtokIndx, 9); // Use strncpy for safety
  result.command[9] = '\0'; // Ensure null termination

  // Iterate through Arguments
  argCount = 0; // Reset counter
  
  // Keep getting tokens until NULL (end of string)
  // AND make sure we don't overflow our array
  while ((strtokIndx = strtok(NULL, ",")) != NULL && argCount < MAX_ARGS) {
    result.args[result.argCount] = atof(strtokIndx); // Convert to float and store
    result.argCount++;
  }
  
  return result;
}

void handleMessage(ParsedPacket message) {

  if (strcmp(message.command, "S") == 0){
    // Mode to modify the setpoint of each motor individually
    // Args = joint to move (1-5), value to move to
    // Joints 1-3 are the motors, 4 is the servo and 5 is the gripper
    int joint_n = (int)message.args[0];
    float angle = message.args[1];

    if (joint_n == 1){
      motor1.setpoint = map(angle, ANGLE_LOWER_LIMIT, ANGLE_UPPER_LIMIT, LOWER_LIMIT, UPPER_LIMIT);
    }
    if (joint_n == 2){
      motor2.setpoint = map(angle, ANGLE_LOWER_LIMIT, ANGLE_UPPER_LIMIT, LOWER_LIMIT, UPPER_LIMIT);
    }
    if (joint_n == 3){
      motor3.setpoint = map(angle, ANGLE_LOWER_LIMIT, ANGLE_UPPER_LIMIT, LOWER_LIMIT, UPPER_LIMIT);
    }
    if (joint_n == 4){
      // Move servo to angle
      wrist.write((int)angle+init_wrist_angle);
    }
    if (joint_n == 5){
      // Close or open gripper
      if (angle == 1){
        // Close gripper
        gripper.write(closed_gripper_angle);
      }
      else{
        // Open gripper
        gripper.write(init_gripper_angle);
      }
    }
  }  
  if (strcmp(message.command, "P") == 0){
    // Mode to set and XYZ position
    // Args = x,y,z
    float x = message.args[0];
    float y = message.args[1];
    float z = message.args[2];
    // Send to IK
  }  

}
