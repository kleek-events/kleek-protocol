# Kleek Smart Contracts 📜

This project was started as part of [WalletConnect hackathon](https://walletconnect.com/blog/build-the-new-internet-hackathon) in partnership with Coinbase, Safe, Magic and 1Inch.  

🏆 It [won the 2nd place](https://devfolio.co/projects/kleek-67d7) in the Coinbase Integration category.

## About Kleek

Kleek is a blockchain-based event management platform that revolutionizes the way events are organized and attended. By utilizing smart contracts, Kleek creates a more reliable and engaging event experience for both organizers and participants.

### Problem 🤔

Traditional event management faces several challenges:
- High rates of no-shows and last-minute cancellations
- Lack of incentives for attendee commitment
- Inefficient and often manual processes for managing deposits and refunds
- Limited transparency in attendance verification

### Solution 💡

Kleek's smart contract system addresses these issues by:
- Implementing an automated deposit mechanism
- Creating financial incentives for attendance
- Streamlining the process of attendance verification and refund distribution
- Providing a transparent and immutable record of event transactions

## Technologies Used 🛠️

Our smart contracts are developed using cutting-edge blockchain technologies:

- **Solidity** 💎: The primary programming language for Ethereum smart contracts
- **Foundry** 🔧: Powerful toolkit for Ethereum application development, used for testing
- **Hardhat** 🏗️: Development environment for compiling, deploying, testing, and debugging Ethereum software
- **OpenZeppelin Upgradeable Contracts** 🛡️: Library for secure smart contract development, using the UUPS proxy pattern for upgradeability

## Smart Contract Architecture 🏛️

The Kleek platform consists of the following main contracts:

1. **KleekCore.sol**: The core contract managing event creation, registration, and overall platform logic.
2. **ShareDeposit.sol**: Handles deposit distribution for events where funds are shared among attendees.
3. **TransferDeposit.sol**: Manages deposits for events where funds are transferred to a specific recipient.
4. **IConditionModule.sol**: Interface for condition modules, allowing for flexible event rule implementation.

## Getting Started 🚀

(Include instructions for setting up the development environment, compiling contracts, running tests, and deployment)

## Testing 🧪

(Provide information on how to run the test suite using Foundry)

## Deployment 🚀

(Include instructions on how to deploy the contracts using Hardhat)

## Security 🔒

(Mention any security measures, audits, or best practices followed in the development of these contracts)

## Contributing 🤝

(Include guidelines for contributing to the project, if applicable)

## License 📄

(Specify the license under which the project is released)

## Contact 📧

(Provide contact information or links to project maintainers)
