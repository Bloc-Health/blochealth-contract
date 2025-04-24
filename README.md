# 🏥 BlocHealth - Cairo Smart Contract

**BlocHealth** is a decentralized medical records management system built on Starknet using Cairo. It enables hospitals to securely manage patient records, appointments, and emergency contacts on-chain, while maintaining privacy and access control.

---

## 📚 Overview

This Cairo smart contract provides functionalities for:

- Registering hospitals and patients
- Storing patient medical records (medications, history, etc.)
- Managing doctor appointments
- Storing emergency contacts
- Publishing/unpublishing records
- Fetching records with permission-based access

---

## 🧱 Tech Stack

- Cairo 1.0
- Starknet (SN Foundry or Scarb)
- CLI tools (`snforge`, `scarb`, `starkli`)

---

## 🚀 Features

- 🧑‍⚕️ Hospital and Patient Registration
- 🧾 Store & Fetch Medical Records
- 🗓️ Appointment Scheduling
- 🆘 Emergency Contact Storage
- 🔐 Published/Unpublished Record Control
- ✅ Zeroable Defaults for Struct Fields
- 📥 Whitelisted Access for Hospital Staff


---

## 🛠️ Installation

### 1. Install Cairo & Scarb

```bash
curl -L https://install.cairo-lang.org | bash
source ~/.bashrc
cargo install --locked scarb
```

### 2. Clone the Repository

```bash
git clone https://github.com/Bloc-Health/blochealth-contract.git
cd blochealth-contract
```

### 3. Build the Contract

```bash
scarb build
```

---

## 🧪 Running Tests

Make sure you have `snforge` installed:

```bash
snforge test
```

---

## 📤 Deploying to Starknet Testnet

```bash
starkli deploy ./target/dev/blochealth.contract.json --network sepolia
```

You’ll need to fund your test wallet using [Starknet Faucet](https://faucet.goerli.starknet.io/).

---

## 📘 Usage

Basic workflow:

1. Register a hospital
2. Add a new patient
3. Store or update medical info
4. Publish or unpublish records
5. Retrieve records via view functions

---

## 📄 License

MIT License