import express from "express";
import axios from "axios";
import cors from "cors";
import dotenv from "dotenv";

// Load environment variables from ../Server/.env
dotenv.config({ path: "../Server/.env" });

const app = express();
const port = process.env.PORT || 5000; // Port for our backend server

app.use(cors()); // Enable CORS for all routes
app.use(express.json()); // Middleware to parse JSON bodies

// Create a single endpoint to handle note uploads
app.post("/uploadNote", async (req, res) => {
  const { note } = req.body;

  if (!note) {
    return res.status(400).json({ error: "Note content is required" });
  }

  try {
    const pinataData = {
      pinataContent: {
        note: note,
        timestamp: new Date().toISOString(),
      },
      pinataMetadata: {
        name: `ShiftHandoverNote_${Date.now()}`,
      },
    };

    const response = await axios.post(
      "https://api.pinata.cloud/pinning/pinJSONToIPFS",
      pinataData,
      {
        headers: {
          Authorization: `Bearer ${process.env.PINATA_JWT_SECRET}`,
        },
      }
    );

    console.log("Successfully uploaded to Pinata:", response.data);
    // Send the IPFS hash back to the frontend
    res.status(200).json({ ipfsHash: response.data.IpfsHash });
  } catch (error) {
    console.error("Error uploading to Pinata:", error);
    res.status(500).json({ error: "Failed to upload note to IPFS" });
  }
});

app.listen(port, () => {
  console.log(`IPFS Uploader server listening at http://localhost:${port}`);
});
