# 🎓 LearnCred – Decentralized Education Credentialing Platform

LearnCred is a Web3 education platform built on the Stacks blockchain using Clarity smart contracts. It solves real-world problems in education such as credential fraud, lack of incentives, and centralized gatekeeping by providing transparent, tamper-proof, and community-governed learning experiences.

## 🚀 Features

- ✅ **Verifiable on-chain credentials** (soulbound NFTs)
- 🎁 **Token rewards** for course completion
- 🔎 **Transparent learner portfolios**
- 🗳️ **DAO-based course curation and governance**
- 🤝 **Decentralized tutor marketplace**
- 📊 **Reputation scoring system for students & educators**

---

## 📦 Smart Contracts Overview

| Contract                | Description |
|------------------------|-------------|
| `credential-nft.clar`   | Issues non-transferable (soulbound) NFTs for completed courses. |
| `course-registry.clar`  | Educators can register course metadata, cost, and syllabus hash. |
| `enrollment.clar`       | Students enroll, progress is tracked, and fees are managed. |
| `reward-pool.clar`      | Distributes $LEARN tokens to students upon verified completion. |
| `learn-token.clar`      | ERC-20-like fungible token for rewards and governance. |
| `staking.clar`          | Token staking for visibility, yield, and content boosting. |
| `reputation.clar`       | Tracks and updates reputation scores for all users. |
| `governance-dao.clar`   | DAO voting system using $LEARN tokens. |
| `peer-review.clar`      | Students rate courses and educators after completion. |
| `tutor-marketplace.clar`| Peer-to-peer tutoring system with escrow and ratings. *(optional)* |

---

## 🛠️ Getting Started

### Prerequisites
- Node.js & Clarinet installed
- Hiro Wallet (for testnet deployment)
- [Clarinet](https://github.com/hirosystems/clarinet) for smart contract development/testing

### Clone the Project

```bash
git clone https://github.com/your-username/learncred.git
cd learncred
