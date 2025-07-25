# 📖 Proof-of-Story – Decentralized Testimony Registry

> 🛡️ Protecting truth, history, and vulnerable voices through immutable blockchain testimony

## 🚀 Overview

Proof-of-Story is a decentralized platform that addresses the critical problem of story erasure and manipulation. Important personal testimonies, whistleblowing accounts, survivor stories, and oral history can now be permanently recorded, timestamped, and verified on the Stacks blockchain.

## ✨ Key Features

- 🔒 **Immutable Storage**: Stories are hashed and timestamped on-chain
- 👤 **Anonymous Protection**: Optional anonymization with permission-based access
- 🎯 **Truth Staking**: Community can stake tokens to validate or dispute testimonies
- 🔐 **Access Control**: Authors control who can view sensitive anonymous stories
- 📊 **Credibility Scoring**: Dynamic scoring based on community stakes

## 🎯 Use Cases

- 📰 **Journalism**: Protect whistleblower testimonies
- ⚖️ **Legal**: Preserve survivor accounts and witness testimonies
- 📚 **History**: Archive oral histories and cultural stories
- 🏛️ **Advocacy**: Document human rights violations
- 🗳️ **Civic Truth**: Combat misinformation with verifiable stories

## 🛠️ Smart Contract Functions

### 📝 Story Management

```clarity
(register-story content-hash is-anonymous access-price)
```
Register a new story with content hash, anonymity setting, and access price.

```clarity
(deactivate-story story-id)
```
Authors can deactivate their stories.

### 🔑 Access Control

```clarity
(grant-access story-id viewer)
```
Grant viewing permission for anonymous stories.

```clarity
(revoke-access story-id viewer)
```
Revoke viewing permission.

### 💰 Truth Token System

```clarity
(buy-truth-tokens amount)
```
Purchase truth tokens for staking.

```clarity
(stake-on-story story-id amount believe)
```
Stake tokens on story credibility (true = believe, false = dispute).

```clarity
(withdraw-stake story-id)
```
Withdraw your stake from a story.

### 📊 Information Queries

```clarity
(get-story story-id)
```
Get story details and metadata.

```clarity
(get-story-stats story-id)
```
Get staking statistics and credibility score.

```clarity
(can-view-story story-id viewer)
```
Check if a user can view a specific story.

## 🚀 Getting Started

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Node.js for testing

### Installation

1. Clone the repository:
```bash
git clone https://github.com/your-repo/proof-of-story.git
cd proof-of-story
```

2. Install dependencies:
```bash
npm install
```

3. Run tests:
```bash
npm test
```

4. Check contract syntax:
```bash
clarinet check
```

## 📋 Contract Details

### Data Structures

- **Stories**: Core testimony data with author, hash, timestamp, and settings
- **Permissions**: Access control for anonymous stories
- **Stakes**: Community validation stakes on stories
- **Balances**: User truth token balances

### Error Codes

- `u100`: Owner only operation
- `u101`: Resource not found
- `u102`: Unauthorized access
- `u103`: Resource already exists
- `u104`: Insufficient funds
- `u105`: Invalid amount
- `u106`: Already voted/staked

## 🔐 Security Features

- ✅ Owner-only administrative functions
- ✅ Authorization checks for story management
- ✅ Balance validation for staking
- ✅ Duplicate stake prevention
- ✅ Access control for anonymous stories

## 🌟 Impact

This platform enables:

- 🛡️ **Protection** of vulnerable voices and testimonies
- 📈 **Verification** through community-driven truth staking
- 🔒 **Immutability** preventing historical revision
- 🌐 **Accessibility** for global truth and justice movements

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Submit a pull request

## 📄 License

This project is open source and available under the [MIT License](LICENSE).

---

*Built with ❤️ for truth, justice, and the protection of important stories*
