node:
	@NODE_ENV=local npx hardhat node --hostname 0.0.0.0 --port 8545
deploy-sepolia:
	@NODE_ENV=development npx hardhat compile
	@NODE_ENV=development npx hardhat ignition wipe chain-11155111 LockModule#Loan
	@NODE_ENV=development npx hardhat ignition deploy ./ignition/modules/Loan.ts --network sepolia
deploy-local:
	@NODE_ENV=local npx hardhat compile
	@NODE_ENV=local npx hardhat ignition deploy ./ignition/modules/Loan.ts --network local
test-local:
	@NODE_ENV=local npx hardhat test --network local  ./test/Loan.ts

