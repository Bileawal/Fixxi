const bcrypt = require('bcryptjs');
const User = require('../models/User');
const TestQuestion = require('../models/TestQuestion');

const questions = [
  {
    question: 'What is the first step when fixing a leaking pipe?',
    options: ['Paint the pipe', 'Shut off water supply', 'Replace entire house plumbing', 'Ignore it'],
    correctIndex: 1,
    category: 'Plumbing',
  },
  {
    question: 'Which tool is commonly used to cut wires safely?',
    options: ['Hammer', 'Wire stripper', 'Screwdriver only', 'Wrench'],
    correctIndex: 1,
    category: 'Electrical',
  },
  {
    question: 'A circuit breaker trips repeatedly. What should you check first?',
    options: ['Overload or short circuit', 'Paint color', 'Door hinges', 'Floor tiles'],
    correctIndex: 0,
    category: 'Electrical',
  },
  {
    question: 'Which wood joint is strongest for furniture frames?',
    options: ['Butt joint only', 'Mortise and tenon', 'Tape only', 'Glue without nails'],
    correctIndex: 1,
    category: 'Carpentry',
  },
  {
    question: 'Customer reports low water pressure in one tap only. Likely cause?',
    options: ['Clogged aerator or valve', 'Moon phase', 'Wall color', 'Roof material'],
    correctIndex: 0,
    category: 'Plumbing',
  },
  {
    question: 'Before working on electrical panel you must?',
    options: ['Wear insulated gloves and turn off power', 'Use wet hands', 'Stand in water', 'Skip safety'],
    correctIndex: 0,
    category: 'Electrical',
  },
  {
    question: 'Which measurement tool checks 90-degree corners in carpentry?',
    options: ['Spirit level / square', 'Thermometer', 'Barometer', 'Scale for weight only'],
    correctIndex: 0,
    category: 'Carpentry',
  },
  {
    question: 'PVC pipe joint should use?',
    options: ['PVC primer and cement', 'Super glue only', 'Tape only', 'No adhesive'],
    correctIndex: 0,
    category: 'Plumbing',
  },
  {
    question: 'Ground wire in electrical work is for?',
    options: ['Safety - fault current path', 'Decoration', 'Increasing voltage', 'Cooling'],
    correctIndex: 0,
    category: 'Electrical',
  },
  {
    question: 'Sanding wood before painting helps to?',
    options: ['Improve paint adhesion', 'Make wood heavier', 'Remove electricity', 'Stop leaks'],
    correctIndex: 0,
    category: 'Carpentry',
  },
];

async function ensureSeed() {
  const adminEmail = (process.env.ADMIN_EMAIL || 'bilawal22204@gmail.com').toLowerCase();
  const adminPass = process.env.ADMIN_PASSWORD || 'Bilawal1122';
  const hash = await bcrypt.hash(adminPass, 10);

  let admin = await User.findOne({ role: 'admin' });
  if (!admin) {
    admin = await User.create({
      name: 'Fixxi Admin',
      email: adminEmail,
      phone: '03000000000',
      password: hash,
      role: 'admin',
      address: 'Lahore',
      emailVerified: true,
    });
    console.log(`Admin created: ${adminEmail}`);
  } else {
    admin.email = adminEmail;
    admin.password = hash;
    await admin.save();
  }

  const count = await TestQuestion.countDocuments();
  if (count === 0) {
    await TestQuestion.insertMany(questions);
    console.log(`Seeded ${questions.length} test questions`);
  }
}

module.exports = ensureSeed;
