import 'dart:math';

class TestQuestionsBank {
  static const _all = <Map<String, dynamic>>[
    {
      "question": "What is the purpose of an MCB (Miniature Circuit Breaker)?\n(MCB \u06a9\u0627 \u06a9\u06cc\u0627 \u0645\u0642\u0635\u062f \u06c1\u06d2\u061f)",
      "options": [
        "To protect from short circuit & overload\n(\u0634\u0627\u0631\u0679 \u0633\u0631\u06a9\u0679 \u0627\u0648\u0631 \u0627\u0648\u0648\u0631\u0644\u0648\u0688 \u0633\u06d2 \u0628\u0686\u0627\u0646\u0627)",
        "To increase voltage\n(\u0648\u0648\u0644\u0679\u06cc\u062c \u0628\u0691\u06be\u0627\u0646\u0627)",
        "To store electricity\n(\u0628\u062c\u0644\u06cc \u0645\u062d\u0641\u0648\u0638 \u06a9\u0631\u0646\u0627)",
        "To decrease temperature\n(\u062f\u0631\u062c\u06c1 \u062d\u0631\u0627\u0631\u062a \u06a9\u0645 \u06a9\u0631\u0646\u0627)"
      ],
      "correctIndex": 0,
      "category": "Electrician",
      "difficulty": "easy"
    },
    {
      "question": "Which wire is typically used for grounding/earthing?\n(\u0627\u0631\u062a\u06be\u0646\u06af \u06a9\u06d2 \u0644\u0626\u06d2 \u0639\u0627\u0645 \u0637\u0648\u0631 \u067e\u0631 \u06a9\u0648\u0646 \u0633\u06cc \u062a\u0627\u0631 \u0627\u0633\u062a\u0639\u0645\u0627\u0644 \u06c1\u0648\u062a\u06cc \u06c1\u06d2\u061f)",
      "options": [
        "Green/Yellow\n(\u0633\u0628\u0632/\u067e\u06cc\u0644\u06cc\u0627)",
        "Red\n(\u0633\u0631\u062e)",
        "Black\n(\u06a9\u0627\u0644\u06cc)",
        "Blue\n(\u0646\u06cc\u0644\u06cc)"
      ],
      "correctIndex": 0,
      "category": "Electrician",
      "difficulty": "easy"
    },
    {
      "question": "What does a multimeter measure?\n(\u0645\u0644\u0679\u06cc \u0645\u06cc\u0679\u0631 \u06a9\u06cc\u0627 \u0645\u0627\u067e\u062a\u0627 \u06c1\u06d2\u061f)",
      "options": [
        "Voltage, Current, and Resistance\n(\u0648\u0648\u0644\u0679\u06cc\u062c\u060c \u06a9\u0631\u0646\u0679\u060c \u0627\u0648\u0631 \u0645\u0632\u0627\u062d\u0645\u062a)",
        "Only Voltage\n(\u0635\u0631\u0641 \u0648\u0648\u0644\u0679\u06cc\u062c)",
        "Water pressure\n(\u067e\u0627\u0646\u06cc \u06a9\u0627 \u062f\u0628\u0627\u0624)",
        "Room temperature\n(\u06a9\u0645\u0631\u06d2 \u06a9\u0627 \u062f\u0631\u062c\u06c1 \u062d\u0631\u0627\u0631\u062a)"
      ],
      "correctIndex": 0,
      "category": "Electrician",
      "difficulty": "easy"
    },
    {
      "question": "What is the standard household voltage in Pakistan?\n(\u067e\u0627\u06a9\u0633\u062a\u0627\u0646 \u0645\u06cc\u06ba \u06af\u06be\u0631\u0648\u06ba \u06a9\u0627 \u0639\u0627\u0645 \u0648\u0648\u0644\u0679\u06cc\u062c \u06a9\u06cc\u0627 \u06c1\u06d2\u061f)",
      "options": [
        "220V - 240V",
        "110V - 120V",
        "12V",
        "440V"
      ],
      "correctIndex": 0,
      "category": "Electrician",
      "difficulty": "easy"
    },
    {
      "question": "Which material is the best conductor of electricity?\n(\u0628\u062c\u0644\u06cc \u06a9\u0627 \u0627\u0686\u06be\u0627 \u0645\u0648\u0635\u0644 \u06a9\u0648\u0646 \u0633\u0627 \u0645\u0648\u0627\u062f \u06c1\u06d2\u061f)",
      "options": [
        "Copper\n(\u062a\u0627\u0646\u0628\u0627)",
        "Wood\n(\u0644\u06a9\u0691\u06cc)",
        "Plastic\n(\u067e\u0644\u0627\u0633\u0679\u06a9)",
        "Rubber\n(\u0631\u0628\u0691)"
      ],
      "correctIndex": 0,
      "category": "Electrician",
      "difficulty": "easy"
    },
    {
      "question": "If a 2200W appliance operates on a 220V supply, what is the approximate current?\n(\u0627\u06af\u0631 2200W \u06a9\u0627 \u06c1\u06cc\u0679\u0631 220V \u067e\u0631 \u0686\u0644\u06d2 \u062a\u0648 \u06a9\u062a\u0646\u0627 \u06a9\u0631\u0646\u0679 \u0644\u06d2 \u06af\u0627\u061f)",
      "options": [
        "10 Amperes",
        "4.5 Amperes",
        "12.5 Amperes",
        "20 Amperes"
      ],
      "correctIndex": 0,
      "category": "Electrician",
      "difficulty": "hard"
    },
    {
      "question": "What happens if the neutral wire is disconnected in a 3-phase unbalanced system?\n(\u062a\u06be\u0631\u06cc \u0641\u06cc\u0632 \u0627\u0646 \u0628\u06cc\u0644\u0646\u0633\u0688 \u0633\u0633\u0679\u0645 \u0645\u06cc\u06ba \u0627\u06af\u0631 \u0646\u06cc\u0648\u0679\u0631\u0644 \u06a9\u0679 \u062c\u0627\u0626\u06d2 \u062a\u0648 \u06a9\u06cc\u0627 \u06c1\u0648\u06af\u0627\u061f)",
      "options": [
        "Voltage fluctuates heavily across phases\n(\u0641\u06cc\u0632\u0632 \u06a9\u06d2 \u062f\u0631\u0645\u06cc\u0627\u0646 \u0648\u0648\u0644\u0679\u06cc\u062c \u0627\u0648\u067e\u0631 \u0646\u06cc\u0686\u06d2 \u06c1\u0648 \u062c\u0627\u0626\u06d2 \u06af\u0627)",
        "Current becomes zero\n(\u06a9\u0631\u0646\u0679 \u0635\u0641\u0631 \u06c1\u0648 \u062c\u0627\u0626\u06d2 \u06af\u0627)",
        "All phases get exactly 220V\n(\u0633\u0628 \u0641\u06cc\u0632\u0632 \u06a9\u0648 220V \u0645\u0644\u06d2 \u06af\u0627)",
        "Short circuit occurs immediately\n(\u0641\u0648\u0631\u0627 \u0634\u0627\u0631\u0679 \u0633\u0631\u06a9\u0679 \u06c1\u0648 \u062c\u0627\u0626\u06d2 \u06af\u0627)"
      ],
      "correctIndex": 0,
      "category": "Electrician",
      "difficulty": "hard"
    },
    {
      "question": "Which type of motor is mostly used in standard ceiling fans?\n(\u0639\u0627\u0645 \u0686\u06be\u062a \u0648\u0627\u0644\u06d2 \u067e\u0646\u06a9\u06be\u0648\u06ba \u0645\u06cc\u06ba \u06a9\u0648\u0646 \u0633\u06cc \u0645\u0648\u0679\u0631 \u0627\u0633\u062a\u0639\u0645\u0627\u0644 \u06c1\u0648\u062a\u06cc \u06c1\u06d2\u061f)",
      "options": [
        "Single-phase induction motor\n(\u0633\u0646\u06af\u0644 \u0641\u06cc\u0632 \u0627\u0646\u0688\u06a9\u0634\u0646 \u0645\u0648\u0679\u0631)",
        "DC series motor\n(\u0688\u06cc \u0633\u06cc \u0633\u06cc\u0631\u06cc\u0632 \u0645\u0648\u0679\u0631)",
        "Synchronous motor\n(\u0633\u0646\u06a9\u0631\u0648\u0646\u0633 \u0645\u0648\u0679\u0631)",
        "Three-phase motor\n(\u062a\u06be\u0631\u06cc \u0641\u06cc\u0632 \u0645\u0648\u0679\u0631)"
      ],
      "correctIndex": 0,
      "category": "Electrician",
      "difficulty": "hard"
    },
    {
      "question": "What is the purpose of a capacitor in a single-phase AC motor?\n(\u0633\u0646\u06af\u0644 \u0641\u06cc\u0632 \u0645\u0648\u0679\u0631 \u0645\u06cc\u06ba \u06a9\u067e\u06cc\u0633\u06cc\u0679\u0631 \u06a9\u0627 \u06a9\u06cc\u0627 \u0645\u0642\u0635\u062f \u06c1\u06d2\u061f)",
      "options": [
        "To create a starting torque\n(\u0634\u0631\u0648\u0639 \u06a9\u0631\u0646\u06d2 \u06a9\u06cc \u0637\u0627\u0642\u062a \u067e\u06cc\u062f\u0627 \u06a9\u0631\u0646\u0627)",
        "To cool the motor\n(\u0645\u0648\u0679\u0631 \u06a9\u0648 \u0679\u06be\u0646\u0688\u0627 \u06a9\u0631\u0646\u0627)",
        "To limit current\n(\u06a9\u0631\u0646\u0679 \u06a9\u0645 \u06a9\u0631\u0646\u0627)",
        "To increase RPM infinitely\n(RPM \u0644\u0627\u0645\u062d\u062f\u0648\u062f \u0628\u0691\u06be\u0627\u0646\u0627)"
      ],
      "correctIndex": 0,
      "category": "Electrician",
      "difficulty": "hard"
    },
    {
      "question": "What causes a GFCI / Earth Leakage Circuit Breaker (ELCB) to trip?\n(ELCB \u0628\u0631\u06cc\u06a9\u0631 \u06a9\u06cc\u0648\u06ba \u0679\u0631\u067e \u06c1\u0648\u062a\u0627 \u06c1\u06d2\u061f)",
      "options": [
        "Current leaking to ground/earth\n(\u06a9\u0631\u0646\u0679 \u06a9\u0627 \u0632\u0645\u06cc\u0646 \u0645\u06cc\u06ba \u0644\u06cc\u06a9 \u06c1\u0648\u0646\u0627)",
        "Minor voltage drop\n(\u0645\u0639\u0645\u0648\u0644\u06cc \u0648\u0648\u0644\u0679\u06cc\u062c \u06af\u0631\u0646\u0627)",
        "High temperature\n(\u0632\u06cc\u0627\u062f\u06c1 \u06af\u0631\u0645\u06cc)",
        "Running a heavy load correctly\n(\u0628\u06be\u0627\u0631\u06cc \u0644\u0648\u0688 \u06a9\u0627 \u0635\u062d\u06cc\u062d \u0686\u0644\u0646\u0627)"
      ],
      "correctIndex": 0,
      "category": "Electrician",
      "difficulty": "hard"
    },
    {
      "question": "What is the primary purpose of PTFE (Teflon) tape?\n(\u0679\u06cc\u0641\u0644\u0648\u0646 \u0679\u06cc\u067e \u06a9\u0627 \u0628\u0646\u06cc\u0627\u062f\u06cc \u0645\u0642\u0635\u062f \u06a9\u06cc\u0627 \u06c1\u06d2\u061f)",
      "options": [
        "To seal threaded pipe joints\n(\u067e\u0627\u0626\u067e \u06a9\u06d2 \u062c\u0648\u0691\u0648\u06ba \u06a9\u0648 \u0633\u06cc\u0644 \u06a9\u0631\u0646\u0627)",
        "To stick pipes to walls\n(\u067e\u0627\u0626\u067e \u062f\u06cc\u0648\u0627\u0631\u0648\u06ba \u0633\u06d2 \u0686\u067e\u06a9\u0627\u0646\u0627)",
        "To measure pipe length\n(\u067e\u0627\u0626\u067e \u06a9\u06cc \u0644\u0645\u0628\u0627\u0626\u06cc \u0646\u0627\u067e\u0646\u0627)",
        "To insulate hot pipes\n(\u06af\u0631\u0645 \u067e\u0627\u0626\u067e\u0648\u06ba \u06a9\u0648 \u0627\u0646\u0633\u0648\u0644\u06cc\u0679 \u06a9\u0631\u0646\u0627)"
      ],
      "correctIndex": 0,
      "category": "Plumber",
      "difficulty": "easy"
    },
    {
      "question": "Which type of pipe is commonly used for both hot and cold water supply?\n(\u06af\u0631\u0645 \u0627\u0648\u0631 \u0679\u06be\u0646\u0688\u06d2 \u067e\u0627\u0646\u06cc \u06a9\u06d2 \u0644\u06cc\u06d2 \u0639\u0627\u0645 \u0637\u0648\u0631 \u067e\u0631 \u06a9\u0648\u0646 \u0633\u0627 \u067e\u0627\u0626\u067e \u0627\u0633\u062a\u0639\u0645\u0627\u0644 \u06c1\u0648\u062a\u0627 \u06c1\u06d2\u061f)",
      "options": [
        "PPRC / CPVC",
        "PVC",
        "Cast Iron\n(\u0644\u0648\u06c1\u06d2 \u06a9\u0627 \u067e\u0627\u0626\u067e)",
        "Rubber\n(\u0631\u0628\u0691 \u06a9\u0627 \u067e\u0627\u0626\u067e)"
      ],
      "correctIndex": 0,
      "category": "Plumber",
      "difficulty": "easy"
    },
    {
      "question": "What is the most common cause of low water pressure in a single basin tap?\n(\u06a9\u0633\u06cc \u0627\u06cc\u06a9 \u0646\u0644\u06a9\u06d2 \u0645\u06cc\u06ba \u067e\u0627\u0646\u06cc \u06a9\u0627 \u067e\u0631\u06cc\u0634\u0631 \u06a9\u0645 \u06c1\u0648\u0646\u06d2 \u06a9\u06cc \u0639\u0627\u0645 \u0648\u062c\u06c1 \u06a9\u06cc\u0627 \u06c1\u06d2\u061f)",
      "options": [
        "Blocked aerator / filter in the tap\n(\u0646\u0644\u06a9\u06d2 \u06a9\u0627 \u0641\u0644\u0679\u0631 \u0628\u0646\u062f \u06c1\u0648\u0646\u0627)",
        "Main motor failure\n(\u0628\u0691\u06cc \u0645\u0648\u0679\u0631 \u06a9\u0627 \u062e\u0631\u0627\u0628 \u06c1\u0648\u0646\u0627)",
        "Leaking roof tank\n(\u0686\u06be\u062a \u06a9\u06cc \u0679\u06cc\u0646\u06a9\u06cc \u0644\u06cc\u06a9 \u06c1\u0648\u0646\u0627)",
        "Wrong pipe color\n(\u067e\u0627\u0626\u067e \u06a9\u0627 \u0631\u0646\u06af \u063a\u0644\u0637 \u06c1\u0648\u0646\u0627)"
      ],
      "correctIndex": 0,
      "category": "Plumber",
      "difficulty": "easy"
    },
    {
      "question": "What prevents sewer gases (bad smell) from entering the bathroom?\n(\u0628\u0627\u062a\u06be \u0631\u0648\u0645 \u0645\u06cc\u06ba \u06af\u0679\u0631 \u06a9\u06cc \u0628\u062f\u0628\u0648 \u0622\u0646\u06d2 \u0633\u06d2 \u06a9\u0648\u0646 \u0633\u06cc \u0686\u06cc\u0632 \u0631\u0648\u06a9\u062a\u06cc \u06c1\u06d2\u061f)",
      "options": [
        "P-Trap (Water seal)\n(\u067e\u06cc \u0679\u0631\u06cc\u067e / \u0648\u0627\u0679\u0631 \u0633\u06cc\u0644)",
        "Ventilation fan\n(\u0627\u06cc\u06af\u0632\u0627\u0633\u0679 \u0641\u06cc\u0646)",
        "Room freshener\n(\u0631\u0648\u0645 \u0641\u0631\u06cc\u0634\u0646\u0631)",
        "Shower head\n(\u0634\u0627\u0648\u0631 \u06c1\u06cc\u0688)"
      ],
      "correctIndex": 0,
      "category": "Plumber",
      "difficulty": "easy"
    },
    {
      "question": "What tool is used to tighten large metal pipes?\n(\u0628\u0691\u06d2 \u0644\u0648\u06c1\u06d2 \u06a9\u06d2 \u067e\u0627\u0626\u067e\u0648\u06ba \u06a9\u0648 \u06a9\u0633 \u0679\u0648\u0644 \u0633\u06d2 \u0679\u0627\u0626\u0679 \u06a9\u06cc\u0627 \u062c\u0627\u062a\u0627 \u06c1\u06d2\u061f)",
      "options": [
        "Pipe Wrench\n(\u067e\u0627\u0626\u067e \u0631\u06cc\u0646\u0686)",
        "Screwdriver\n(\u067e\u06cc\u0686\u06a9\u0633)",
        "Hammer\n(\u06c1\u062a\u06be\u0648\u0691\u0627)",
        "Pliers\n(\u067e\u0644\u0627\u0633)"
      ],
      "correctIndex": 0,
      "category": "Plumber",
      "difficulty": "easy"
    },
    {
      "question": "How do you fix a 'water hammer' (banging sound) issue in pipes?\n(\u067e\u0627\u0626\u067e\u0648\u06ba \u0645\u06cc\u06ba \u067e\u0627\u0646\u06cc \u06a9\u06cc \u0632\u0648\u0631\u062f\u0627\u0631 \u0622\u0648\u0627\u0632 / \u0648\u0627\u0679\u0631 \u06c1\u06cc\u0645\u0631 \u06a9\u0648 \u06a9\u06cc\u0633\u06d2 \u0679\u06be\u06cc\u06a9 \u06a9\u06cc\u0627 \u062c\u0627\u062a\u0627 \u06c1\u06d2\u061f)",
      "options": [
        "Install a water hammer arrestor\n(\u0648\u0627\u0679\u0631 \u06c1\u06cc\u0645\u0631 \u0627\u0631\u06cc\u0633\u0679\u0631 \u0644\u06af\u0627\u0646\u0627)",
        "Increase the water pressure\n(\u067e\u0627\u0646\u06cc \u06a9\u0627 \u067e\u0631\u06cc\u0634\u0631 \u0628\u0691\u06be\u0627\u0646\u0627)",
        "Remove the P-Trap\n(\u067e\u06cc \u0679\u0631\u06cc\u067e \u06c1\u0679\u0627 \u062f\u06cc\u0646\u0627)",
        "Use thinner pipes\n(\u0628\u0627\u0631\u06cc\u06a9 \u067e\u0627\u0626\u067e \u0627\u0633\u062a\u0639\u0645\u0627\u0644 \u06a9\u0631\u0646\u0627)"
      ],
      "correctIndex": 0,
      "category": "Plumber",
      "difficulty": "hard"
    },
    {
      "question": "What is the standard slope required for a horizontal drainage pipe?\n(\u0688\u0631\u06cc\u0646\u06cc\u062c \u067e\u0627\u0626\u067e \u06a9\u06cc \u06a9\u0645 \u0627\u0632 \u06a9\u0645 \u0688\u06be\u0644\u0648\u0627\u0646 \u06a9\u062a\u0646\u06cc \u06c1\u0648\u0646\u06cc \u0686\u0627\u06c1\u06cc\u06d2\u061f)",
      "options": [
        "1/4 inch per foot (1-2%)\n(\u0627\u06cc\u06a9 \u0641\u0679 \u067e\u0631 \u0627\u06cc\u06a9 \u0686\u0648\u062a\u06be\u0627\u0626\u06cc \u0627\u0646\u0686)",
        "No slope needed\n(\u0628\u0627\u0644\u06a9\u0644 \u0633\u06cc\u062f\u06be\u0627)",
        "45 degrees\n(45 \u0688\u06af\u0631\u06cc \u0632\u0627\u0648\u06cc\u06c1)",
        "90 degrees straight down\n(\u0628\u0627\u0644\u06a9\u0644 \u0633\u06cc\u062f\u06be\u0627 \u0646\u06cc\u0686\u06d2)"
      ],
      "correctIndex": 0,
      "category": "Plumber",
      "difficulty": "hard"
    },
    {
      "question": "Why does a water heater's TPR (Temperature/Pressure Relief) valve leak continuously?\n(\u06af\u0632\u0631 \u06a9\u0627 \u0679\u06cc \u067e\u06cc \u0622\u0631 \u0648\u0627\u0644\u0648 \u06a9\u06cc\u0648\u06ba \u0644\u06cc\u06a9 \u06a9\u0631\u062a\u0627 \u06c1\u06d2\u061f)",
      "options": [
        "Tank pressure or temperature is dangerously high\n(\u0679\u06cc\u0646\u06a9\u06cc \u06a9\u0627 \u067e\u0631\u06cc\u0634\u0631 \u06cc\u0627 \u062f\u0631\u062c\u06c1 \u062d\u0631\u0627\u0631\u062a \u062e\u0637\u0631\u0646\u0627\u06a9 \u062d\u062f \u062a\u06a9 \u0632\u06cc\u0627\u062f\u06c1 \u06c1\u06d2)",
        "It is doing its normal daily wash cycle\n(\u06cc\u06c1 \u0639\u0627\u0645 \u0631\u0648\u0632\u0627\u0646\u06c1 \u06a9\u06cc \u0635\u0641\u0627\u0626\u06cc \u06c1\u06d2)",
        "The heater needs more gas\n(\u06af\u0632\u0631 \u06a9\u0648 \u0645\u0632\u06cc\u062f \u06af\u06cc\u0633 \u0686\u0627\u06c1\u06cc\u06d2)",
        "The hot water tap is closed\n(\u06af\u0631\u0645 \u067e\u0627\u0646\u06cc \u06a9\u0627 \u0646\u0644\u06a9\u0627 \u0628\u0646\u062f \u06c1\u06d2)"
      ],
      "correctIndex": 0,
      "category": "Plumber",
      "difficulty": "hard"
    },
    {
      "question": "How is equal water pressure maintained in a high-rise building?\n(\u0627\u0648\u0646\u0686\u06cc \u0639\u0645\u0627\u0631\u062a\u0648\u06ba \u0645\u06cc\u06ba \u067e\u0627\u0646\u06cc \u06a9\u0627 \u067e\u0631\u06cc\u0634\u0631 \u0628\u0631\u0627\u0628\u0631 \u06a9\u06cc\u0633\u06d2 \u0631\u06a9\u06be\u0627 \u062c\u0627\u062a\u0627 \u06c1\u06d2\u061f)",
      "options": [
        "Using Pressure Reducing Valves (PRV)\n(\u067e\u0631\u06cc\u0634\u0631 \u0631\u06cc\u0688\u06cc\u0648\u0633\u0646\u06af \u0648\u0627\u0644\u0648\u0632 \u06a9\u0627 \u0627\u0633\u062a\u0639\u0645\u0627\u0644)",
        "Using only one huge tank\n(\u0635\u0631\u0641 \u0627\u06cc\u06a9 \u0628\u06c1\u062a \u0628\u0691\u06cc \u0679\u06cc\u0646\u06a9\u06cc \u0644\u06af\u0627 \u06a9\u0631)",
        "Installing wider pipes on top floors\n(\u0627\u0648\u067e\u0631 \u06a9\u06cc \u0645\u0646\u0632\u0644\u0648\u06ba \u067e\u0631 \u0686\u0648\u0691\u06d2 \u067e\u0627\u0626\u067e \u0644\u06af\u0627 \u06a9\u0631)",
        "It maintains itself automatically\n(\u06cc\u06c1 \u062e\u0648\u062f\u06a9\u0627\u0631 \u0637\u0631\u06cc\u0642\u06d2 \u0633\u06d2 \u06c1\u0648\u062a\u0627 \u06c1\u06d2)"
      ],
      "correctIndex": 0,
      "category": "Plumber",
      "difficulty": "hard"
    },
    {
      "question": "What happens if the vent pipe on a drainage system is blocked?\n(\u0627\u06af\u0631 \u06af\u0679\u0631 \u06a9\u06cc \u0648\u06cc\u0646\u0679 \u067e\u0627\u0626\u067e \u0628\u0646\u062f \u06c1\u0648 \u062c\u0627\u0626\u06d2 \u062a\u0648 \u06a9\u06cc\u0627 \u06c1\u0648\u06af\u0627\u061f)",
      "options": [
        "Water traps get siphoned and smell enters the house\n(\u067e\u0627\u0646\u06cc \u06a9\u06be\u0646\u0686 \u062c\u0627\u062a\u0627 \u06c1\u06d2 \u0627\u0648\u0631 \u0628\u062f\u0628\u0648 \u06af\u06be\u0631 \u0645\u06cc\u06ba \u0622\u062a\u06cc \u06c1\u06d2)",
        "Water pressure increases\n(\u067e\u0627\u0646\u06cc \u06a9\u0627 \u067e\u0631\u06cc\u0634\u0631 \u0628\u0691\u06be \u062c\u0627\u062a\u0627 \u06c1\u06d2)",
        "Water gets purified\n(\u067e\u0627\u0646\u06cc \u0635\u0627\u0641 \u06c1\u0648 \u062c\u0627\u062a\u0627 \u06c1\u06d2)",
        "Nothing changes\n(\u06a9\u0686\u06be \u0646\u06c1\u06cc\u06ba \u06c1\u0648\u062a\u0627)"
      ],
      "correctIndex": 0,
      "category": "Plumber",
      "difficulty": "hard"
    },
    {
      "question": "Which refrigerant gas is most commonly used in modern inverter ACs?\n(\u062c\u062f\u06cc\u062f \u0627\u0646\u0648\u0631\u0679\u0631 \u0627\u06d2 \u0633\u06cc \u0645\u06cc\u06ba \u0633\u0628 \u0633\u06d2 \u0632\u06cc\u0627\u062f\u06c1 \u06a9\u0648\u0646 \u0633\u06cc \u06af\u06cc\u0633 \u0627\u0633\u062a\u0639\u0645\u0627\u0644 \u06c1\u0648\u062a\u06cc \u06c1\u06d2\u061f)",
      "options": [
        "R-410A / R-32",
        "R-12",
        "R-22",
        "Oxygen\n(\u0622\u06a9\u0633\u06cc\u062c\u0646)"
      ],
      "correctIndex": 0,
      "category": "AC & Refrigerator Mechanic",
      "difficulty": "easy"
    },
    {
      "question": "What is the main purpose of an AC's indoor air filter?\n(\u0627\u06d2 \u0633\u06cc \u06a9\u06d2 \u0627\u0646\u0688\u0648\u0631 \u0641\u0644\u0679\u0631 \u06a9\u0627 \u0627\u0635\u0644 \u0645\u0642\u0635\u062f \u06a9\u06cc\u0627 \u06c1\u06d2\u061f)",
      "options": [
        "To protect the cooling coil from dust\n(\u06a9\u0648\u0644\u0646\u06af \u06a9\u0648\u0627\u0626\u0644 \u06a9\u0648 \u0645\u0679\u06cc \u0633\u06d2 \u0628\u0686\u0627\u0646\u0627)",
        "To add a fresh smell\n(\u062e\u0648\u0634\u0628\u0648 \u062f\u06cc\u0646\u0627)",
        "To increase room humidity\n(\u06a9\u0645\u0631\u06d2 \u0645\u06cc\u06ba \u0646\u0645\u06cc \u0628\u0691\u06be\u0627\u0646\u0627)",
        "To cool the air directly\n(\u06c1\u0648\u0627 \u06a9\u0648 \u0628\u0631\u0627\u06c1 \u0631\u0627\u0633\u062a \u0679\u06be\u0646\u0688\u0627 \u06a9\u0631\u0646\u0627)"
      ],
      "correctIndex": 0,
      "category": "AC & Refrigerator Mechanic",
      "difficulty": "easy"
    },
    {
      "question": "Why does an indoor split AC unit drip water inside the room?\n(\u0633\u067e\u0644\u0679 \u0627\u06d2 \u0633\u06cc \u06a9\u0645\u0631\u06d2 \u06a9\u06d2 \u0627\u0646\u062f\u0631 \u067e\u0627\u0646\u06cc \u06a9\u06cc\u0648\u06ba \u0679\u067e\u06a9\u0627\u062a\u0627 \u06c1\u06d2\u061f)",
      "options": [
        "The drain pipe is blocked or disconnected\n(\u0688\u0631\u06cc\u0646 \u067e\u0627\u0626\u067e \u0628\u0646\u062f \u06c1\u06d2 \u06cc\u0627 \u0627\u062a\u0631\u0627 \u06c1\u0648\u0627 \u06c1\u06d2)",
        "The room is too hot\n(\u06a9\u0645\u0631\u06c1 \u0628\u06c1\u062a \u06af\u0631\u0645 \u06c1\u06d2)",
        "The fan is spinning too fast\n(\u067e\u0646\u06a9\u06be\u0627 \u0628\u06c1\u062a \u062a\u06cc\u0632 \u0686\u0644 \u0631\u06c1\u0627 \u06c1\u06d2)",
        "Gas is overcharged\n(\u06af\u06cc\u0633 \u0632\u06cc\u0627\u062f\u06c1 \u0628\u06be\u0631\u06cc \u06af\u0626\u06cc \u06c1\u06d2)"
      ],
      "correctIndex": 0,
      "category": "AC & Refrigerator Mechanic",
      "difficulty": "easy"
    },
    {
      "question": "What is the function of the compressor in a refrigerator?\n(\u0631\u06cc\u0641\u0631\u06cc\u062c\u0631\u06cc\u0679\u0631 \u0645\u06cc\u06ba \u06a9\u0645\u067e\u0631\u06cc\u0633\u0631 \u06a9\u0627 \u06a9\u06cc\u0627 \u06a9\u0627\u0645 \u06c1\u06d2\u061f)",
      "options": [
        "To circulate and compress the refrigerant gas\n(\u06af\u06cc\u0633 \u06a9\u0648 \u062f\u0628\u0627\u0646\u0627 \u0627\u0648\u0631 \u06af\u0631\u062f\u0634 \u062f\u06cc\u0646\u0627)",
        "To create ice cubes\n(\u0628\u0631\u0641 \u0628\u0646\u0627\u0646\u0627)",
        "To filter the water\n(\u067e\u0627\u0646\u06cc \u0641\u0644\u0679\u0631 \u06a9\u0631\u0646\u0627)",
        "To light the inside bulb\n(\u0627\u0646\u062f\u0631 \u06a9\u0627 \u0628\u0644\u0628 \u062c\u0644\u0627\u0646\u0627)"
      ],
      "correctIndex": 0,
      "category": "AC & Refrigerator Mechanic",
      "difficulty": "easy"
    },
    {
      "question": "What happens if you run an AC with open windows and doors?\n(\u0627\u06af\u0631 \u0622\u067e \u06a9\u06be\u0691\u06a9\u06cc\u0627\u06ba \u0627\u0648\u0631 \u062f\u0631\u0648\u0627\u0632\u06d2 \u06a9\u06be\u0644\u06d2 \u0631\u06a9\u06be \u06a9\u0631 \u0627\u06d2 \u0633\u06cc \u0686\u0644\u0627\u0626\u06cc\u06ba \u062a\u0648 \u06a9\u06cc\u0627 \u06c1\u0648\u06af\u0627\u061f)",
      "options": [
        "It consumes more power and cooling efficiency drops\n(\u0628\u062c\u0644\u06cc \u06a9\u0627 \u062e\u0631\u0686 \u0628\u0691\u06be\u06d2 \u06af\u0627 \u0627\u0648\u0631 \u06a9\u0648\u0644\u0646\u06af \u06a9\u0645 \u06c1\u0648 \u06af\u06cc)",
        "It cools the room faster\n(\u06a9\u0645\u0631\u06c1 \u062c\u0644\u062f\u06cc \u0679\u06be\u0646\u0688\u0627 \u06c1\u0648\u06af\u0627)",
        "The gas finishes quickly\n(\u06af\u06cc\u0633 \u062c\u0644\u062f\u06cc \u062e\u062a\u0645 \u06c1\u0648 \u062c\u0627\u0626\u06d2 \u06af\u06cc)",
        "The AC automatically turns off\n(\u0627\u06d2 \u0633\u06cc \u062e\u0648\u062f \u0628\u0646\u062f \u06c1\u0648 \u062c\u0627\u0626\u06d2 \u06af\u0627)"
      ],
      "correctIndex": 0,
      "category": "AC & Refrigerator Mechanic",
      "difficulty": "easy"
    },
    {
      "question": "What does ice formation on the thin (discharge) pipe of a split AC usually indicate?\n(\u0633\u067e\u0644\u0679 \u0627\u06d2 \u0633\u06cc \u06a9\u06d2 \u067e\u062a\u0644\u06d2 \u067e\u0627\u0626\u067e \u067e\u0631 \u0628\u0631\u0641 \u062c\u0645\u0646\u0627 \u06a9\u0633 \u0686\u06cc\u0632 \u06a9\u06cc \u0646\u0634\u0627\u0646\u06cc \u06c1\u06d2\u061f)",
      "options": [
        "Low refrigerant gas\n(\u06af\u06cc\u0633 \u06a9\u0627 \u06a9\u0645 \u06c1\u0648\u0646\u0627)",
        "Dirty indoor filter\n(\u0627\u0646\u0688\u0648\u0631 \u0641\u0644\u0679\u0631 \u06a9\u0627 \u06af\u0646\u062f\u0627 \u06c1\u0648\u0646\u0627)",
        "Defective remote control\n(\u062e\u0631\u0627\u0628 \u0631\u06cc\u0645\u0648\u0679 \u06a9\u0646\u0679\u0631\u0648\u0644)",
        "Normal operation\n(\u06cc\u06c1 \u0646\u0627\u0631\u0645\u0644 \u06c1\u06d2)"
      ],
      "correctIndex": 0,
      "category": "AC & Refrigerator Mechanic",
      "difficulty": "hard"
    },
    {
      "question": "What is a CRITICAL step before charging new gas into a completely empty AC system?\n(\u0628\u0627\u0644\u06a9\u0644 \u062e\u0627\u0644\u06cc \u0627\u06d2 \u0633\u06cc \u0633\u0633\u0679\u0645 \u0645\u06cc\u06ba \u06af\u06cc\u0633 \u0628\u06be\u0631\u0646\u06d2 \u0633\u06d2 \u067e\u06c1\u0644\u06d2 \u06a9\u06cc\u0627 \u06a9\u0631\u0646\u0627 \u0627\u0646\u062a\u06c1\u0627\u0626\u06cc \u0636\u0631\u0648\u0631\u06cc \u06c1\u06d2\u061f)",
      "options": [
        "Creating a deep vacuum in the system\n(\u0633\u0633\u0679\u0645 \u0645\u06cc\u06ba \u0648\u06cc\u06a9\u06cc\u0648\u0645 \u0628\u0646\u0627\u0646\u0627)",
        "Washing the compressor with water\n(\u06a9\u0645\u067e\u0631\u06cc\u0633\u0631 \u06a9\u0648 \u067e\u0627\u0646\u06cc \u0633\u06d2 \u062f\u06be\u0648\u0646\u0627)",
        "Turning on the heater\n(\u06c1\u06cc\u0679\u0631 \u0622\u0646 \u06a9\u0631\u0646\u0627)",
        "Bypassing the capacitor\n(\u06a9\u067e\u06cc\u0633\u06cc\u0679\u0631 \u06a9\u0648 \u0628\u0627\u0626\u06cc \u067e\u0627\u0633 \u06a9\u0631\u0646\u0627)"
      ],
      "correctIndex": 0,
      "category": "AC & Refrigerator Mechanic",
      "difficulty": "hard"
    },
    {
      "question": "In a no-frost refrigerator, what is the role of the defrost timer/sensor?\n(\u0646\u0648 \u0641\u0631\u0627\u0633\u0679 \u0631\u06cc\u0641\u0631\u06cc\u062c\u0631\u06cc\u0679\u0631 \u0645\u06cc\u06ba \u0688\u06cc\u0641\u0631\u0648\u0633\u0679 \u0679\u0627\u0626\u0645\u0631 \u06a9\u0627 \u06a9\u06cc\u0627 \u06a9\u0627\u0645 \u06c1\u06d2\u061f)",
      "options": [
        "To turn on the heater and melt excess ice on the coil\n(\u06c1\u06cc\u0679\u0631 \u0622\u0646 \u06a9\u0631 \u06a9\u06d2 \u06a9\u0648\u0627\u0626\u0644 \u06a9\u06cc \u0641\u0627\u0644\u062a\u0648 \u0628\u0631\u0641 \u067e\u06af\u06be\u0644\u0627\u0646\u0627)",
        "To monitor the room temperature\n(\u06a9\u0645\u0631\u06d2 \u06a9\u0627 \u062f\u0631\u062c\u06c1 \u062d\u0631\u0627\u0631\u062a \u0646\u0648\u0679 \u06a9\u0631\u0646\u0627)",
        "To speed up the compressor\n(\u06a9\u0645\u067e\u0631\u06cc\u0633\u0631 \u06a9\u06cc \u0631\u0641\u062a\u0627\u0631 \u0628\u0691\u06be\u0627\u0646\u0627)",
        "To control the interior light\n(\u0627\u0646\u062f\u0631 \u06a9\u06cc \u0644\u0627\u0626\u0679 \u06a9\u0646\u0679\u0631\u0648\u0644 \u06a9\u0631\u0646\u0627)"
      ],
      "correctIndex": 0,
      "category": "AC & Refrigerator Mechanic",
      "difficulty": "hard"
    },
    {
      "question": "What is a common cause of abnormally high discharge pressure in an AC unit?\n(\u0627\u06d2 \u0633\u06cc \u06a9\u06d2 \u0688\u0633\u0686\u0627\u0631\u062c \u067e\u0631\u06cc\u0634\u0631 \u06a9\u0627 \u0628\u06c1\u062a \u0632\u06cc\u0627\u062f\u06c1 \u0628\u0691\u06be \u062c\u0627\u0646\u0627 \u06a9\u0633 \u0648\u062c\u06c1 \u0633\u06d2 \u06c1\u0648\u062a\u0627 \u06c1\u06d2\u061f)",
      "options": [
        "Dirty outdoor condenser coil or fan failure\n(\u0622\u0624\u0679 \u0688\u0648\u0631 \u06a9\u0648\u0627\u0626\u0644 \u06a9\u0627 \u06af\u0646\u062f\u0627 \u06c1\u0648\u0646\u0627 \u06cc\u0627 \u067e\u0646\u06a9\u06be\u0627 \u062e\u0631\u0627\u0628 \u06c1\u0648\u0646\u0627)",
        "Clean indoor filter\n(\u0635\u0627\u0641 \u0627\u0646\u0688\u0648\u0631 \u0641\u0644\u0679\u0631)",
        "Low room temperature\n(\u06a9\u0645\u0631\u06d2 \u06a9\u0627 \u06a9\u0645 \u062f\u0631\u062c\u06c1 \u062d\u0631\u0627\u0631\u062a)",
        "Short power cable\n(\u0686\u06be\u0648\u0679\u06cc \u067e\u0627\u0648\u0631 \u06a9\u06cc\u0628\u0644)"
      ],
      "correctIndex": 0,
      "category": "AC & Refrigerator Mechanic",
      "difficulty": "hard"
    },
    {
      "question": "How do you accurately measure the exact gas charge required in an Inverter AC?\n(\u0627\u0646\u0648\u0631\u0679\u0631 \u0627\u06d2 \u0633\u06cc \u0645\u06cc\u06ba \u06af\u06cc\u0633 \u06a9\u06cc \u062f\u0631\u0633\u062a \u0645\u0642\u062f\u0627\u0631 \u06a9\u06cc\u0633\u06d2 \u0646\u0627\u067e\u06cc \u062c\u0627\u062a\u06cc \u06c1\u06d2\u061f)",
      "options": [
        "By charging according to the weight mentioned on the sticker\n(\u0633\u0679\u06cc\u06a9\u0631 \u067e\u0631 \u0644\u06a9\u06be\u06d2 \u0648\u0632\u0646 \u06a9\u06d2 \u0645\u0637\u0627\u0628\u0642 \u06af\u06cc\u0633 \u0688\u0627\u0644 \u06a9\u0631)",
        "By just feeling the cooling of the air\n(\u0635\u0631\u0641 \u06c1\u0648\u0627 \u06a9\u06cc \u06a9\u0648\u0644\u0646\u06af \u0645\u062d\u0633\u0648\u0633 \u06a9\u0631 \u06a9\u06d2)",
        "By looking at the pipe color\n(\u067e\u0627\u0626\u067e \u06a9\u0627 \u0631\u0646\u06af \u062f\u06cc\u06a9\u06be \u06a9\u0631)",
        "By filling it until the cylinder is empty\n(\u0633\u0644\u0646\u0688\u0631 \u062e\u0627\u0644\u06cc \u06c1\u0648\u0646\u06d2 \u062a\u06a9 \u0628\u06be\u0631\u062a\u06d2 \u0631\u06c1\u0646\u0627)"
      ],
      "correctIndex": 0,
      "category": "AC & Refrigerator Mechanic",
      "difficulty": "hard"
    }
  ];

  static List<Map<String, dynamic>> pickForCategory(String? category, {int count = 10}) {
    final filtered = _all.where((q) {
      if (category == null || category.isEmpty) return true;
      return q['category'] == category;
    }).toList();

    // Shuffle inside category
    filtered.shuffle(Random());
    
    // Always shuffle the options to randomize correct index!
    final result = <Map<String, dynamic>>[];
    for (final q in filtered.take(count)) {
      final oldOptions = List<String>.from(q['options'] as List);
      final oldCorrectAnswer = oldOptions[q['correctIndex'] as int];
      
      oldOptions.shuffle(Random());
      final newCorrectIndex = oldOptions.indexOf(oldCorrectAnswer);
      
      result.add({
        ...q,
        'options': oldOptions,
        'correctIndex': newCorrectIndex,
      });
    }

    return result;
  }
}
