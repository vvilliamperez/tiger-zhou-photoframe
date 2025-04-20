const express = require('express');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const { exec } = require('child_process');
require('dotenv').config();

const app = express();
const port = 80;

// Create uploads directory if it doesn't exist
const uploadDir = path.join(__dirname, 'uploads');
if (!fs.existsSync(uploadDir)) {
    fs.mkdirSync(uploadDir);
}

// Configure multer for file uploads
const storage = multer.diskStorage({
    destination: function (req, file, cb) {
        cb(null, uploadDir);
    },
    filename: function (req, file, cb) {
        cb(null, Date.now() + path.extname(file.originalname));
    }
});

const upload = multer({ storage: storage });

// Serve static files from the public directory
app.use(express.static(path.join(__dirname, 'public')));

// Function to execute ADB commands
async function syncToFrame() {
    const frameIP = process.env.FRAME_IP;
    if (!frameIP) {
        throw new Error('FRAME_IP not set in .env');
    }

    return new Promise((resolve, reject) => {
        // Connect to ADB device
        exec(`adb connect ${frameIP}`, (error, stdout, stderr) => {
            if (error) {
                reject(new Error(`ADB connection failed: ${error.message}`));
                return;
            }

            // Push photos to device
            exec(`adb push "${uploadDir}/" "/storage/emulated/0/Pictures/"`, (error, stdout, stderr) => {
                if (error) {
                    reject(new Error(`Sync failed: ${error.message}`));
                    return;
                }

                // Trigger media scanner
                exec('adb shell am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d "file:///storage/emulated/0/Pictures/"', (error, stdout, stderr) => {
                    if (error) {
                        reject(new Error(`Media scan failed: ${error.message}`));
                        return;
                    }
                    resolve();
                });
            });
        });
    });
}

// Handle file upload
app.post('/upload', upload.single('photo'), async (req, res) => {
    if (!req.file) {
        return res.status(400).json({ error: 'No file uploaded' });
    }

    // Return success response immediately
    res.json({ 
        success: true, 
        message: 'File uploaded successfully',
        filename: req.file.filename
    });

    // Handle ADB sync in the background
    syncToFrame()
        .then(() => {
            console.log(`Successfully synced file ${req.file.filename} to frame`);
        })
        .catch(error => {
            console.error('Background sync error:', error);
        });
});

// Start the server
app.listen(port, () => {
    console.log(`Server running at http://localhost:${port}`);
}); 