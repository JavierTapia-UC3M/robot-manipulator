import controlP5.*; // Import the ControlP5 library
import processing.serial.*; // Import the serial communication lib to interact with arduino 
Serial myPort;

ControlP5 cp5; // Create a ControlP5 object

// Add font for text
PFont titleFont, textFont; 

// --- Global state variable ---
// 0 = Home Page
// 1 = XYZ Page
// 2 = Manual Page
// 3 = Check Motors Page
int appState = 0;

// --- Global variables for all GUI elements ---
Button xyzNavButton, manualNavButton, checkNavButton; 
Textfield xInput, yInput, zInput; 
Button sendXYZButton, homeButtonXYZ;
Slider m1Slider, m2Slider, m3Slider, m4Slider; 
Button gripperButton, homeButtonManual;
Button startPathButton, homeButtonCheck; 

boolean isGripperOpen = true; // State for the gripper toggle



void setup() {
  size(1200, 800);
  String portName = Serial.list()[7];
  println(portName);
  
  myPort = new Serial(this, portName, 9600);
  surface.setTitle("Robotic Manipulator Control");
  
  cp5 = new ControlP5(this);
  
  // Create both fonts
  titleFont = createFont("Arial", 40, true); 
  textFont = createFont("Arial", 18, true); // Font for buttons, labels, etc.
  
  //  Set the font for all cp5 elements
  cp5.setFont(textFont, 18);
  
  // Set the hover/active color for all elements
  cp5.setColorActive(color(120, 120, 150)); // Lighter blue-grey for hover

  // --- 1. Home Page Controls (State 0) ---
  xyzNavButton = cp5.addButton("goToXYZ")
    .setLabel("Set XYZ Position")
    .setPosition(400, 300)
    .setSize(400, 70);
    
  manualNavButton = cp5.addButton("goToManual")
    .setLabel("Manual Control")
    .setPosition(400, 390)
    .setSize(400, 70);
    

  // --- 2. XYZ Page Controls (State 1) ---
  xInput = cp5.addTextfield("x_input")
    .setLabel("X Position (mm)")
    .setPosition(450, 250)
    .setSize(300, 45);
    
  yInput = cp5.addTextfield("y_input")
    .setLabel("Y Position (mm)")
    .setPosition(450, 320)
    .setSize(300, 45);
    
  zInput = cp5.addTextfield("z_input")
    .setLabel("Z Position (mm)")
    .setPosition(450, 390)
    .setSize(300, 45);
    
  sendXYZButton = cp5.addButton("sendXYZ")
    .setLabel("Go to Position")
    .setPosition(450, 470)
    .setSize(300, 60);
    
  homeButtonXYZ = cp5.addButton("goHomeXYZ") 
    .setLabel("<- Home")
    .setPosition(40, 40)
    .setSize(150, 50);

  // --- 3. Manual Page Controls (State 2) ---
  m1Slider = cp5.addSlider("motor1")
    .setLabel("Motor 1 (Base)")
    .setRange(0, 180)
    .setValue(90)
    .setPosition(200, 200)
    .setSize(800, 35);
    
  m2Slider = cp5.addSlider("motor2")
    .setLabel("Motor 2 (Shoulder)")
    .setRange(0, 180)
    .setValue(90)
    .setPosition(200, 290)
    .setSize(800, 35);
    
  m3Slider = cp5.addSlider("motor3")
    .setLabel("Motor 3 (Elbow)")
    .setRange(0, 180)
    .setValue(90)
    .setPosition(200, 380)
    .setSize(800, 35);

  m4Slider = cp5.addSlider("motor4")
    .setLabel("Motor 4 (Wrist)")
    .setRange(0, 180)
    .setValue(90)
    .setPosition(200, 470)
    .setSize(800, 35);
    
  gripperButton = cp5.addButton("toggleGripper")
    .setLabel("Close Gripper")
    .setPosition(475, 560)
    .setSize(250, 60);

  homeButtonManual = cp5.addButton("goHomeManual") 
    .setLabel("<- Home")
    .setPosition(40, 40)
    .setSize(150, 50);
    
  // --- Set initial visibility ---
  setGUIVisibility(0); // Show Home page
}

void draw() {
  background(30, 30, 50); // Dark blue background
  
  // Draw titles and other non-control elements based on state
  switch(appState) {
    case 0:
      drawHomePage();
      break;
    case 1:
      drawPageTitle("XYZ Position Control");
      break;
    case 2:
      drawPageTitle("Manual Motor Control");
      break;
  }
}

// --- Page Drawing Functions ---

void drawHomePage() {
  // Title
  textFont(titleFont);
  fill(200, 200, 255);
  textAlign(CENTER, CENTER);
  text("Robotic Manipulator Control", width/2, 130);

}

void drawPageTitle(String title) {
  textFont(titleFont);
  fill(220);
  textAlign(CENTER, CENTER);
  text(title, width/2, 100);
}


// --- GUI Visibility Management ---

void setGUIVisibility(int newState) {
  appState = newState;
  
  xyzNavButton.hide();
  manualNavButton.hide();
  
  xInput.hide();
  yInput.hide();
  zInput.hide();
  sendXYZButton.hide();
  homeButtonXYZ.hide();
  
  m1Slider.hide();
  m2Slider.hide();
  m3Slider.hide();
  m4Slider.hide();
  gripperButton.hide();
  homeButtonManual.hide();
  
  
  switch(appState) {
    case 0: // Home
      xyzNavButton.show();
      manualNavButton.show();
      break;
    case 1: // XYZ
      xInput.show();
      yInput.show();
      zInput.show();
      sendXYZButton.show();
      homeButtonXYZ.show();
      break;
    case 2: // Manual
      m1Slider.show();
      m2Slider.show();
      m3Slider.show();
      m4Slider.show();
      gripperButton.show();
      homeButtonManual.show();
      break;
}
}

// --- ControlP5 Callback Functions ---

// --- Navigation Callbacks ---
void goToXYZ() {
  setGUIVisibility(1);
}

void goToManual() {
  setGUIVisibility(2);
}

void goToCheck() {
  setGUIVisibility(3);
}

// Callbacks for the unique home buttons
void goHomeXYZ() {
  goHome();
}
void goHomeManual() {
  goHome();
}
void goHomeCheck() {
  goHome();
}

// Main function for returning home
void goHome() {
  setGUIVisibility(0);
}

// Helper function to send commands easily
void sendCommand(String cmd, float... args) {
  
  String packet = "<" + cmd;
  
  // Iterate through the list of arguments provided
  for (int i = 0; i < args.length; i++) {
    packet += "," + args[i];
  }
  
  packet += ">";
  
  myPort.write(packet);
  println("Sent: " + packet);
}

// --- XYZ Page Callbacks ---
void sendXYZ() {
  try {
    // Attempt to convert the text to numbers
    float x = float(xInput.getText());
    float y = float(yInput.getText());
    float z = float(zInput.getText());

    // Check if the conversion failed (Processing returns NaN if it fails)
    if (Float.isNaN(x) || Float.isNaN(y) || Float.isNaN(z)) {
      println("ERROR: Please enter valid numbers only!");
      return; // Stop here, don't send anything
    }

    // If we get here, the numbers are valid
    println("--- SENDING XYZ ---");
    println("X: " + x + " Y: " + y + " Z: " + z);
    
    sendCommand("P", x, y, z);
    
  } catch (Exception e) {
    println("Error parsing input.");
  }
}



// --- Manual Page Callbacks ---
// Sliders
void motor1(int val) {
  println("Motor 1 (Base) set to: " + val);
  sendCommand("S",1,val);
  
}
void motor2(int val) {
  println("Motor 2 (Shoulder) set to: " + val);
  sendCommand("S",2,val);
}
void motor3(int val) {
  println("Motor 3 (Elbow) set to: " + val);
  sendCommand("S",3,val);
}
void motor4(int val) {
  println("Motor 4 (Wrist) set to: " + val);
  sendCommand("S",4,val);
}

// Gripper Button
void toggleGripper() {
  isGripperOpen = !isGripperOpen; // Toggle the state
  
  if (isGripperOpen) {
    gripperButton.setLabel("Close Gripper");
    println("GRIPPER: Open");
    sendCommand("S",5,0);
  } else {
    gripperButton.setLabel("Open Gripper");
    println("GRIPPER: Closed");
    sendCommand("S",5,1);
  }
}
