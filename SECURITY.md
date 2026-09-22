# Security Policy — MyDrive Vault

MyDrive Vault is designed with a defense-in-depth architecture specifically to enable secure file sharing between an Admin and a Friend without exposing personal Google accounts or credentials.

---

## Security Architecture & Separation of Concerns

### 1. Zero Google Account Exposure to Friend
- **No Google Login on Friend's Devices**: The friend only logs into the MyDrive Vault website with application-level credentials.
- **No Client-Side Token Exposure**: Google OAuth client secrets, refresh tokens, access tokens, and API keys are **never** delivered to the client browser, localStorage, or cookies.
- **Server-to-Server API Calls**: Every Google Drive interaction is mediated through the backend API.

### 2. Encryption at Rest
- Sensitive tokens (`refresh_token` and `access_token`) are encrypted before being persisted using **AES-256-GCM** (Galois/Counter Mode).
- A unique 16-byte initialization vector (IV) and authentication tag are generated for every encrypted payload to prevent replay attacks and tampering.
- Cryptographic keys are derived from `ENCRYPTION_KEY` using scrypt with a unique salt.

### 3. Session Security
- User sessions utilize JSON Web Tokens (JWT) stored exclusively in **`HttpOnly` cookies** with `SameSite=Lax` (or `SameSite=Strict`).
- Javascript on the client cannot read the session cookie, eliminating XSS token theft risks.
- In production, cookies are marked `Secure`, requiring HTTPS transport.

### 4. Role-Based Access Control (RBAC) & IDOR Prevention
- Every file request (`download`, `stream`, `rename`, `delete`, `upload`, `share`) executes server-side validation against both:
  1. The authenticated user identity.
  2. The dynamic friend permissions configured by the Admin.
- The friend cannot bypass permissions by manipulating frontend variables, because the backend rejects unauthorized actions with HTTP 403 Forbidden.

### 5. Bit-for-bit Original Media Integrity
- Videos and files are passed directly through the stream proxy without transcoding, re-encoding, or compression.
- HTTP 206 Partial Content range requests allow efficient seeking without storing temporary video files on disk.

### 6. Sharing Security
- Files are **strictly private by default**.
- Generating a public access link requires explicit confirmation in the Share dialog, featuring clear warnings regarding public link accessibility.
- Links can be revoked back to private access at any time.

---

## Security Checklist for Deployment

1. Set `NODE_ENV=production`.
2. Generate strong, unique 32+ character keys for `SESSION_SECRET` and `ENCRYPTION_KEY`.
3. Serve the application over **HTTPS (TLS 1.3)**.
4. Keep the `.env` file and `data/` directory protected and excluded from public version control.
