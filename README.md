# 📱 CONEXTAR // FRONTEND CORE APPLICATION TERMINAL

This directory contains the cross-platform frontend engine for **Conextar**, a high-performance utility platform designed around real-time socket states, premium tactile user interfaces, and synchronized low-latency WebRTC media streaming mesh grids.

The architecture is built completely on **Flutter** utilizing a decoupled, unidirectional data-flow system managed globally by **Riverpod 2.0**. This document serves as a high-level operational overview for management to understand the frontend technical deck without diving into the codebase.

---

## 🛠️ CORE TECHNICAL STACK BLOCK

| Layer                        | Technology                 | Architectural Purpose                                                                                                      |
| ---------------------------- | -------------------------- | -------------------------------------------------------------------------------------------------------------------------- |
| **Cross-Platform Engine**    | Flutter SDK (Dart)         | Compiles native ARM machine code for iOS and Android platforms from a unified code foundation.                             |
| **State Architecture**       | Riverpod 2.0 (`@riverpod`) | Provides compiled-time safe global state notification, reactive data caching, and automated dependency lifecycle disposal. |
| **Real-Time Mesh Data**      | Socket.io Client           | Maintains a persistent duplex TCP pipe with the Node.js cluster for instantaneous sync of user seat matrix placements.     |
| **Voice Streaming Pipeline** | LiveKit Client (WebRTC)    | Operates low-latency decentralized peer-to-peer audio transmission handling real-time VoIP protocols.                      |
| **System Audio Management**  | `audio_session`            | Commands underlying OS-level hardware priority loops to inject echo cancellation and switch physical audio output lines.   |
| **Hardware Permissions**     | `permission_handler`       | Bridges device security gates asynchronously to handle micro-level microphone access validation.                           |

---

## 🏗️ SYSTEM ARCHITECTURE & DATA FLOW

The application rejects local state dependencies inside presentation layouts. Instead, it enforces a strict **Unidirectional Architecture Pattern**:

```
[UI Layout / User Interaction] ──(Taps Sofa)──> [Global Riverpod Notifier]
                                                        │
                                                 (Socket Emitter)
                                                        │
                                                        ▼
[Visual Re-render] <──(Syncs New State)── [Local Network Socket Handler]

```

### 1. The Global Lounge State Machine (`LoungeSession`)

A global controller built on Riverpod code-generation components (`lounge_session_provider.g.dart`) acts as the central brain. It synchronizes two separate distributed networks simultaneously:

- **The Socket Pipeline:** Manages the visual mapping arrays. Whenever a user joins, sits down, or vacates a sofa slot, the socket server broadcasts a transaction. The frontend interceptor handles this and updates the local immutable data model (`LoungeSessionState`), triggering smooth screen re-renders.
- **The WebRTC Media Pipeline:** When the socket verifies a seat allocation (`listenToClaimSuccess`), it yields a secure JWT token. The provider catches this token, bypasses UI layers, configures the audio properties, and dials the LiveKit server node directly on port `7880`.

---

## 🎛️ VOICE PROCESSING & HARDWARE INTEGRATION

To match top-tier communication tools like WhatsApp, the app features an automated digital signal processing (DSP) hardware layer to eliminate acoustic feedback loop screeching when devices are positioned close together.

- **Acoustic Echo Cancellation (AEC):** Forces iOS (`AVAudioSessionMode.voiceChat`) and Android (`AndroidAudioUsage.voiceCommunication`) to trigger hardware-level sound cancellation grids. It filters out background bleed by digitally subtracting incoming voice packets from the microphone lines.
- **Discontinuous Transmission (DTX):** Integrated straight into WebRTC options. It halts bandwidth transmission spikes when a participant is silent, dropping network overhead completely during quiet phases.
- **Active Speaker Tracking:** The frontend hooks into LiveKit's native hardware audio volume evaluation loops (`ActiveSpeakersChangedEvent`). It maps volume shifts straight into state updates to drive immediate neon glow effects on the active speaker's sofa slot.

---

## 🎨 VISUAL SYSTEMS & INTERACTIVE GEOMETRY

The frontend implements a dark cybernetic HUD design language, heavily optimized for high-speed interactions.

### 📐 Circular Seat Array Geometry

The roundtable view maps user seats dynamically across a radial layout matrix. Using mathematical sine and cosine distributions ($x = r \cdot \cos(\theta)$, $y = r \cdot \sin(\theta)$), the application partitions space across an 8-slot vector ring. Every seat undergoes an iterative orientation adjustment (`angle + math.pi`) to ensure that all interactive assets face inward toward the central data hub.

### ⚡ Defensive Error Recovery Fallbacks

The system treats network stability carefully. If a user sits on a sofa, but their local Wi-Fi drops or the LiveKit server handshake times out, a **de-authorization loop** catches the exception. It automatically fires an asynchronous message to the socket server to vacate the slot, handles the hardware teardown, and shifts the participant back to the passive spectator list safely, ensuring the interface never freezes.

---

## 📂 FILE TERMINAL TREE OVERVIEW

```
lib/
├── components/               # Globally reused tactile UI components (Buttons, Fields)
├── constants/                # System theme wrappers, layout scales, and colors
├── models/                   # Immutable data objects (LoungeStateModel, UserModel, ApiResponse)
├── providers/                # Global Riverpod state providers and architecture notifiers
│   ├── current_user/         # Handles persistent authorization session profiles
│   └── lounge_session/       # Core WebRTC connection router and seat tracker
├── sockets/                  # Low-level real-time network transaction layers
│   ├── emitters/             # Outbound network packet triggers (claimSofa, leaveSofa)
│   └── handlers/             # Inbound event interceptors (listenToLoungeState)
└── views/                    # Presentation screens
    ├── auth/                 # Sign-in and OTP registration gates
    ├── roundtable/           # Main list dashboard view
    └── roundtable_explore/   # Interactive voice lounge view with radial sofa layout

```

# ============================

# BACKEND

# ============================

# 🌐 CONEXTAR — CORE BACKEND APPLICATION ENGINE

This repository houses the core full-stack backend application engine for the Conextar ecosystem. It acts as the central API gateway, managing secure client states, real-time message broadcasting, and synchronized WebRTC media streams for our mobile clients.

---

## 🛠️ System Architecture & Technology Stack

The backend is built with high performance, strict type safety, and a minimalist footprint in mind. It uses a containerized multi-engine layout deployed on **AWS cloud infrastructure**:

- **Runtime Environment:** Node.js (v20 Alpine Distribution for an optimized container size)
- **Language Layer:** TypeScript (Strict compliance mode)
- **Execution Runtime Engine:** `tsx` (TypeScript Execute Engine)
- **Core Framework:** Express.js (High-throughput REST routes)
- **Real-time Synchronization Engine:** Socket.io (Bi-directional persistent TCP connections)
- **VoIP Media Infrastructure:** LiveKit SFU (Selective Forwarding Unit) via WebRTC
- **Object-Relational Mapper:** Sequelize (Configured with automated data migrations)
- **Ecosystem Orchestration:** Docker Engine & Docker Compose

---

## ☁️ Cloud Infrastructure Deployment Map

The production environment runs inside a highly optimized resource boundary designed to maximize performance under a zero-cost infrastructure budget:

### 1. Compute Node (AWS EC2)

- **Instance Class:** `t3.micro` (Burst-capable processing node, 2 vCPUs, 1 GiB RAM)
- **Operating System:** Ubuntu Server 24.04 LTS (Noble Numbat)
- **Storage Allocation:** 25 GiB General Purpose SSD (`gp3`) configuration

### 2. Managed Database Layer (AWS RDS)

- **Database Engine:** PostgreSQL (v16+)
- **Security Protocol:** Hardened network parameters with mandatory SSL/TLS handshake requirements.

### 3. Open Network Inbound Routing (Security Groups Firewall)

The infrastructure layer exposes a carefully curated matrix of ingress endpoints to balance public accessibility and system isolation:

- `TCP : 22` — Secure SSH Administrative Console Access
- `TCP : 3000` — Public REST API and Socket.io Communication Channels
- `TCP : 7880` — LiveKit HTTP Signaling WebSockets Bridge
- `TCP : 7881` — LiveKit Internal Node Mesh Communication
- `UDP : 7882` — **High-Speed WebRTC Real-Time Voice Audio Stream Pipeline**

---

## 📊 Core Data Infrastructure Models (AWS RDS Database)

The relational schema maps out our social lounge and seating layout through strongly associated data relations:

### 1. `User` Schema

Tracks user registration, verification status, and authentication credentials.

- `id` (UUID, Primary Key)
- `email` (String, Unique, Indexed)
- `password` (Cryptographically Hashed)
- `isVerified` (Boolean flag for operational safety)
- _Associations:_ Has many `RoundtableParticipant` nodes.

### 2. `Roundtable` Schema (The Social Lounges)

Manages individual real-time voice discussion groups.

- `id` (UUID, Primary Key)
- `title` (String, Core display context)
- `roomName` (String, Unique pointer map for LiveKit media token bridges)
- `maxSeats` (Integer, Strict constraint parameter)
- `createdAt` / `updatedAt` (Timestamp fields for chronological lifecycle audit logs)
- _Associations:_ Has many active `RoundtableParticipant` records.

### 3. `RoundtableParticipant` Schema

The junction database map managing live seat allocations, speaker states, and participant tracking.

- `id` (UUID, Primary Key)
- `roundtableId` (Foreign Key matching `Roundtable.id`)
- `userId` (Foreign Key matching `User.id`)
- `joinedAt` (Timestamp audit tracker)

---

## 🔒 Security, Authorization & External APIs

The application enforces a multi-tier security layer across all routes:

- **JSON Web Tokens (JWT):** Multi-token architecture utilizing brief **Access Tokens** for routing authorization alongside persistent **Refresh Tokens** stored for secure session generation.
- **Transactional Email Delivery Pipeline:** Fully integrated with the **Brevo API Engine** via a secure tracking signature key line (`xkeysib`), firing automated onboarding and verification emails from verification targets (`no-reply@huzaifakhan.com`).
- **Network Security:** All external connections pass through the secure AWS Security Group layout, and standard websocket handshakes adjust to standard socket patterns during cross-network testing to bypass SSL encapsulation limits.

---

## 🚀 DevOps Execution Guide

To quickly inspect or recreate the live application lifecycle on the cloud terminal environment, use these deployment scripts:

### Turn On Server Architecture (Background Mode)

```bash
docker compose up -d --force-recreate

```

### Review Real-time System Performance Logs

```bash
docker compose logs -f api

```

### Inspect Container Processes and Port Maps

```bash
docker ps

```
