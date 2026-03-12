// server.js - Combined Firebase Auth & Chatbot Version

// 1. IMPORT DEPENDENCIES
const express = require('express');
const cors = require('cors');
const OpenAI = require('openai');
const admin = require('firebase-admin'); // Added for Firebase
require('dotenv').config();

// 2. INITIALIZE THE APP
const app = express();
const PORT = 4000;

// 3. APPLY MIDDLEWARE
// In section 3
app.use(cors({
    origin: ['https://statuesque-pavlova-67cd37.netlify.app',
        'http://localhost:3000'] // IMPORTANT: Use your actual Netlify URL here
}));
app.use(express.json());

// 4. INITIALIZE FIREBASE ADMIN SDK
const serviceAccount = require('./serviceAccountKey.json'); // Make sure this file is in your backend folder
admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
});
const auth = admin.auth();
const db = admin.firestore();

// 5. INITIALIZE OPENAI CLIENT FOR OPENROUTER
const openAI = new OpenAI({
    baseURL: "https://openrouter.ai/api/v1",
    apiKey: process.env.OPENROUTER_API_KEY,
    defaultHeaders: {
        "HTTP-Referer": process.env.SITE_URL || "http://localhost:3000",
        "X-Title": "Jal-Rakshak",
    },
});

// 6. DEFINE AUTHENTICATION ROUTES
// Route for user registration
app.post('/api/register', async (req, res) => {
    const { email, password, name } = req.body;
    try {
        const userRecord = await auth.createUser({ email, password, displayName: name });
        // Also save user info in your Firestore 'users' collection
        await db.collection('users').doc(userRecord.uid).set({
            email: userRecord.email,
            name: name,
            createdAt: new Date().toISOString(),
        });
        res.status(201).json({ message: 'User registered successfully!', uid: userRecord.uid });
    } catch (error) {
        res.status(400).json({ message: error.message });
    }
});

// Middleware to verify Firebase ID token sent from the client
const verifyToken = async (req, res, next) => {
    const idToken = req.headers.authorization?.split('Bearer ')[1];
    if (!idToken) {
        return res.status(401).send('Unauthorized: No token provided');
    }
    try {
        // req.user will contain the decoded token payload (uid, email, etc.)
        req.user = await auth.verifyIdToken(idToken);
        next();
    } catch (error) {
        return res.status(401).send('Unauthorized: Invalid token');
    }
};

// Route to handle creating a user record in Firestore after a social login
app.post('/api/handle-social-login', verifyToken, async (req, res) => {
    const { uid, email, name } = req.user;
    const userDocRef = db.collection('users').doc(uid);
    const doc = await userDocRef.get();
    if (!doc.exists) {
        await userDocRef.set({ email, name, createdAt: new Date().toISOString() });
    }
    res.status(200).json({ message: 'Social login handled.' });
});

// 7. DEFINE PROTECTED API ENDPOINT FOR THE CHATBOT
app.post('/api/chat', async (req, res) => {
    try {
        // Now that the route is protected, we know who is making the request
        console.log("Received request for public /api/chat route");
        const { message } = req.body;
        console.log("Message received:", message);
        console.log("Using API Key:", process.env.OPENROUTER_API_KEY ? "Present (Starts with " + process.env.OPENROUTER_API_KEY.substring(0, 5) + ")" : "Missing");

        const systemPrompt = `
You are 'Jal-Rakshak AI', a compassionate, reliable, and knowledgeable public health assistant...
// The rest of your detailed system prompt goes here
`;

        const completion = await openAI.chat.completions.create({
            model: "stepfun/step-3.5-flash:free",
            messages: [
                { role: "system", content: systemPrompt },
                { role: "user", content: message },
            ],
        });

        const aiReply = completion.choices[0].message.content;
        res.json({ reply: aiReply });

    } catch (error) {
        console.error("Error calling OpenRouter API for chat:", error);
        if (error.response) {
            console.error(error.response.status);
            console.error(error.response.data);
        } else {
            console.error(error.message);
        }
        res.status(500).json({ error: "Failed to get response from AI.", details: error.message });
    }
});

// 8. START THE SERVER
app.listen(PORT, '0.0.0.0', () => {
    console.log(`🚀 Server is running on http://0.0.0.0:${PORT}`);
});