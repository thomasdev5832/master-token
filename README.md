# MasterToken - An Advanced ERC-20 Token

**MasterToken**, an ERC-20 token built in Solidity with advanced features including minting, burning, off-chain approvals via EIP-712 (`permit`), supply cap, pausability, and allowance adjustments. This project leverages the Foundry framework for robustness and comprehensive testing.

## Overview

**MasterToken** is a customizable ERC-20 token with the following key features:

- **Controlled Minting**: Only the owner can mint tokens, respecting a maximum supply cap (`maxSupply`).
- **Burning**: Users can burn their own tokens or delegate burning via allowance.
- **Advanced Allowance**: Supports `increaseAllowance` and `decreaseAllowance`.
- **Permit (EIP-712)**: Enables gasless off-chain approvals.
- **Pausability**: The owner can pause transfers and other operations in emergencies.
- **Security**: Includes checks for zero addresses and relies on Solidity 0.8.x overflow/underflow protection.

This project is suitable for learning, experimentation, or as a foundation for production-grade tokens.

---

## Project Structure

```
master-token/
├── script/
│   └── MasterToken.s.sol       # Deployment script
├── src/
│   └── MasterToken.sol         # Main contract
├── test/
│   └── MasterToken.t.sol       # Unit tests
├── .gitignore                  # Git ignore file
├── foundry.toml                # Foundry configuration
└── README.md                   # This file
```

---

## Prerequisites

Before getting started, ensure you have:

- [Foundry](https://github.com/foundry-rs/foundry) installed (`forge` and `cast`).
- [Git](https://git-scm.com/) to clone the repository.
- [Solidity 0.8.19+](https://docs.soliditylang.org/) (compatible via Foundry).

---

## Installation

1. Clone the repository:

   ```bash
   git clone https://github.com/your-username/master-token.git
   cd master-token
   ```

2. Install Foundry dependencies:

   ```bash
   forge install
   ```

3. Compile the project:

   ```bash
   forge build
   ```

---

## Contract Features

- **ERC-20 Standard**: `transfer`, `approve`, `transferFrom`, `balanceOf`, `allowance`, `totalSupply`.
- **Minting**: `mint` function restricted to the owner, capped at `maxSupply` (10M tokens).
- **Burning**: `burn` (self) and `burnFrom` (via allowance).
- **Allowance**: `increaseAllowance` and `decreaseAllowance` for incremental adjustments.
- **Permit**: Off-chain approvals using EIP-712 signatures.
- **Access Control**: `onlyOwner` modifier for administrative functions.
- **Pausability**: `pause` and `unpause` functions for security.

---

## Usage

### Compilation

Compile the contract:

```bash
forge build
```

### ✅ Testing

Run the unit tests (29 tests covering all functionalities):

```bash
forge test -vvvv
```

The tests verify:

- Correct initialization (supply, name, symbol, etc.).
- Transfers, approvals, and delegated transfers.
- Minting, burning, and supply cap enforcement.
- `permit` functionality with signatures.
- Security (expected reverts, pausability).

### Deployment

Use the provided deployment script in `script/MasterToken.s.sol`:

```bash
forge script script/MasterToken.s.sol --rpc-url <YOUR_RPC_URL> --private-key <YOUR_PRIVATE_KEY> --broadcast
```

Replace `<YOUR_RPC_URL>` and `<YOUR_PRIVATE_KEY>` with appropriate values (Infura, Alchemy, etc.).

#### Local Deployment Example (Foundry's Anvil)

1. Start a local network:
   ```bash
   anvil
   ```
2. Deploy:
   ```bash
   forge script script/MasterToken.s.sol --fork-url http://localhost:8545 --broadcast
   ```

---

## Contract Details

### `MasterToken.sol`

- **Solidity Version**: 0.8.19
- **License**: MIT
- **Events**: `Transfer`, `Approval`, `OwnershipTransferred`, `Paused`, `Unpaused`
- **Public Variables**: `name`, `symbol`, `decimals`, `totalSupply`, `maxSupply`, `owner`, `paused`, etc.

---

## ⚒ Tests

- **Location**: `test/MasterToken.t.sol`
- **Coverage**: 100% of public functions and failure scenarios.

---

## Contributing

Contributions are welcome! Follow these steps:

1. Fork the repository.
2. Create a feature branch:
   ```bash
   git checkout -b feature/new-feature
   ```
3. Commit your changes:
   ```bash
   git commit -m "Add new feature"
   ```
4. Push to the remote repository:
   ```bash
   git push origin feature/new-feature
   ```
5. Open a Pull Request.

---

## License

This project is licensed under the [MIT License](LICENSE).

---

**Questions?** Feel free to reach out or open an issue!

