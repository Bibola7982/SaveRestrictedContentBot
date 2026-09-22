# MyDrive Vault 🛡️

**MyDrive Vault** is a private, production-ready Google Drive-powered cloud file and media manager created for private pair-use (an **Admin/Owner** and a **Friend/Member**).

The website itself is the **only** interface your friend uses. Your personal Google / Gmail account, OAuth tokens, and Google Drive sessions are **never logged into, transferred, or exposed on your friend's phone or machine**.

---

## 🏗️ Architecture & Security Model

```
Friend Device (Phone / Laptop)
      ↓ (No Google credentials or OAuth tokens on device)
MyDrive Vault Frontend (React + Tailwind CSS)
      ↓ (HttpOnly Session Cookie + CSRF protection)
MyDrive Vault Backend (Node.js / Express API)
      ↓ (Encrypted Tokens at rest via AES-256-GCM)
Google Drive API v3 (Official API via OAuth 2.0)
      ↓
Admin's Private Google Drive Storage
```

### Key Highlights
- **100% Google Account Isolation**: The friend logs in with application-level credentials configured by the Admin. Tokens and Google credentials remain exclusively server-side.
- **Original Video Quality (Mandatory)**: Videos are **never** compressed, re-encoded, resized, or transcoded. A 2 GB video uploaded to Google Drive remains the exact original 2 GB file.
- **HTTP 206 Range Streaming**: Full video seeking and playback support through native Range request streaming.
- **Dynamic Google Account Connection Manager**: Connect, disconnect, or switch between multiple Google accounts directly from the Admin settings UI without touching source code or redeploying.
- **Resumable Chunked Uploads**: Direct streaming pipe to Google Drive Resumable Upload protocol without storing massive files on the web server disk.
- **Automated Vault Directory Structure**: Automatically creates and maintains:
  ```
  MyDrive Vault/
  ├── Videos/
  ├── Scripts/
  ├── Documents/
  ├── Images/
  ├── Shared/
  └── Other/
  ```

---

## 🚀 Quick Start (Local Setup)

### Prerequisites
- Node.js (v18+ or v20+ recommended)
- npm (v9+)
- A Google Cloud Platform (GCP) account (Free Tier)

### 1. Clone & Install Dependencies
```bash
# In the project directory:
npm install
```

### 2. Configure Environment Variables
Copy `.env.example` to `.env`:
```bash
cp .env.example .env
```

Open `.env` and configure:
```env
PORT=5000
NODE_ENV=development
CLIENT_URL=http://localhost:3000

# Security Secrets (Generate secure random 32-character strings)
SESSION_SECRET=your_super_secret_session_jwt_key_min_32_characters_here
ENCRYPTION_KEY=your_aes_256_encryption_key_for_storing_google_tokens_here

# Google OAuth 2.0 Credentials (From GCP Console)
GOOGLE_CLIENT_ID=your_google_client_id.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=your_google_client_secret
GOOGLE_REDIRECT_URI=http://localhost:5000/api/accounts/callback

# Default Application Accounts
DEFAULT_ADMIN_USER=admin
DEFAULT_ADMIN_PASSWORD=VaultAdmin2026!
DEFAULT_FRIEND_USER=friend
DEFAULT_FRIEND_PASSWORD=VaultFriend2026!
```

---

## 🔑 Google Cloud Setup Walkthrough

### Step 1: Create a Project
1. Go to the [Google Cloud Console](https://console.cloud.google.com/).
2. Click the project dropdown at the top and select **New Project**.
3. Name it `MyDrive Vault` and click **Create**.

### Step 2: Enable the Google Drive API
1. In the sidebar, navigate to **APIs & Services > Library**.
2. Search for **Google Drive API**.
3. Click on it and click **Enable**.

### Step 3: Configure the OAuth Consent Screen
1. Navigate to **APIs & Services > OAuth consent screen**.
2. Choose **External** user type and click **Create**.
3. Fill in:
   - **App name**: `MyDrive Vault`
   - **User support email**: Your Gmail address
   - **Developer contact information**: Your email
4. Click **Save and Continue**.
5. Under **Scopes**, click **Add or Remove Scopes** and add:
   - `.../auth/drive` (Full access to Drive files created or opened by the app)
   - `.../auth/userinfo.email`
   - `.../auth/userinfo.profile`
6. Under **Test users**, add your Gmail address (and any other Google accounts you intend to connect).
7. Save and finish.

### Step 4: Create OAuth 2.0 Client Credentials
1. Navigate to **APIs & Services > Credentials**.
2. Click **+ CREATE CREDENTIALS** > **OAuth client ID**.
3. Select Application type: **Web application**.
4. Name: `MyDrive Vault Web Client`.
5. Under **Authorized JavaScript origins**:
   - `http://localhost:3000`
   - `http://localhost:5000`
   - (Add your production domain when deploying)
6. Under **Authorized redirect URIs**:
   - `http://localhost:5000/api/accounts/callback`
   - (Add `https://your-api-domain.com/api/accounts/callback` when deploying)
7. Click **Create**.
8. Copy the **Client ID** and **Client Secret** into your `.env` file.

---

## 💻 Running the Application

### Development Mode (Both Client and Server)
```bash
npm run dev
```
- Frontend: `http://localhost:3000`
- Backend API: `http://localhost:5000`

### Production Build & Launch
```bash
npm run build
npm start
```
The Express server will serve both the backend API and the built static React client from `http://localhost:5000`.

---

## 👥 Managing Users & Permissions

### Application Users
| Role | Default Username | Default Password | Permissions |
|------|------------------|------------------|-------------|
| **Admin** | `admin` | `VaultAdmin2026!` | Connect/disconnect Google accounts, switch active Drive, manage Friend permissions, full file management |
| **Friend** | `friend` | `VaultFriend2026!` | Restricted strictly to permissions toggled on by Admin (upload, download, preview, rename, move, delete, share) |

### Connecting Google Accounts
1. Log in to the website as **Admin**.
2. Go to **Settings > Google Drive Accounts Manager**.
3. Click **Connect Google Account**.
4. Sign into your Google account and grant Drive access.
5. You will be redirected back to the Vault with a success notification.
6. The app will automatically initialize the `MyDrive Vault/` folder hierarchy on your Drive.
7. You can connect multiple Google accounts and switch the active storage account anytime with one click!

---

## ☁️ Deployment (Cloudflare & Serverless / Node)

### Option A: Cloudflare Pages (Frontend) + Cloudflare Worker / Serverless Backend
1. **Frontend**:
   - Connect your GitHub repository to **Cloudflare Pages**.
   - Build command: `npm run build --workspace=client`
   - Build output directory: `client/dist`
2. **Backend**:
   - Can be deployed as a Docker container, Node VPS, Render, Railway, or Fly.io instance.
   - Point your Cloudflare Pages `/api/*` route to your backend URL.

### Option B: Unified Node Container (Docker / VPS / Render)
A unified Node container serves both API and static files with zero CORS complexity:
```dockerfile
FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
COPY server/package*.json ./server/
COPY client/package*.json ./client/
RUN npm install
COPY . .
RUN npm run build
EXPOSE 5000
CMD ["npm", "start"]
```

---

## ⚠️ Free-Tier & Google Drive Limitations
1. **Google Drive Storage**: Free personal Google accounts receive 15 GB of shared storage across Drive, Gmail, and Google Photos.
2. **OAuth Test Mode**: In "Testing" mode, refresh tokens expire after 7 days unless the app status is set to "In Production" (or re-authorized). For personal use with your friend, adding both accounts under **Test Users** in GCP Console provides seamless long-term access.
3. **Upload Rate Limits**: Google Drive limits individual file uploads to 5 TB/day, which is far beyond typical personal limits. Resumable chunking prevents browser memory bottlenecks on large 2 GB+ videos.

---

## 🛠️ Troubleshooting
- **OAuth Error: redirect_uri_mismatch**: Ensure the redirect URI in your GCP Console matches `GOOGLE_REDIRECT_URI` in your `.env` exactly (including port and protocol).
- **Video preview not playing**: Certain browser engines cannot decode legacy AVI or proprietary container codecs natively. MyDrive Vault provides an instant "Download Original" button for these files rather than altering the original file quality.
